#!/bin/sh

# Keeps an iptables DoH ipset up to date by fetching the hagezi DoH
# IP list and building a new ipset from its contents. Then it swaps
# the new set for the old one and cleans up the old one. This should
# be the right way to update an ipset that's used by an iptables rule.
#
# Using ipset rather than just adding to an iptables chain because
# 1. ipset filtering should be much faster than a chain
# 2. adding ips to an ipset is waaaay faster than adding them to a chain
#
# Streams and processes data line by line — never loads the full list
# into memory or stores it on disk.

[ -f /tmp/.rc_custom ] && source /tmp/.rc_custom

# Notify healthchecks.io of script start if the secret(-ish) URL is configured in the env.
[ -z "$HC_URL" ] || curl "$HC_URL/start" >/dev/null

url="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/ips/doh.txt"
set_name="doh-block"
set_name_new="${set_name}-new"

logger -t DOH_SCRIPT "Running DOH script"

# Ensure the new chain is there and/or empty
ipset create "$set_name_new" hash:ip || ipset flush "$set_name_new"

logger -t DOH_SCRIPT "Add all DOH IPs"
curl -sL "$url" | while read -r ip; do
    case "$ip" in
        ''|\#*) continue ;;
    esac
    ipset add "$set_name_new" "$ip"
done

logger -t DOH_SCRIPT "Swap sets and clean up old"
ipset swap "$set_name_new" "$set_name" || ipset rename "$set_name_new" "$set_name"
# Insert at position 3 because latest dd-wrt has a SECURITY rule followed by the related,established rule
iptables -C FORWARD -m set --match-set "$set_name" dst -j REJECT -m comment --comment "Block DoH providers" ||
  iptables -I FORWARD 3 -m set --match-set "$set_name" dst -j REJECT -m comment --comment "Block DoH providers"
ipset destroy "$set_name_new"

# Notify helathchecks.io of success
[ -z "$HC_URL" ] || curl "$HC_URL" >/dev/null
