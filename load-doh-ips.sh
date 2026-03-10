#!/bin/sh

# Keeps an iptables DoH IP chain up to date by fetching the hagezi DoH
# IP list and building a new iptables FORWARD chain from its contents.
# Then it adds the new chain to FORWARD and removes the old chain,
# ensuring continuous filtering.
#
# Streams and processes data line by line — never loads the full list
# into memory or stores it on disk.

url="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/ips/doh.txt"
chain="DOH_BLOCK"
chain_new="${chain}_NEW"

logger -t DOH_SCRIPT "Running DOH script"

# Ensure the new chain is there and/or empty
iptables -N "$chain_new" || iptables -F "$chain_new"

logger -t DOH_SCRIPT "Add all DOH IPs"
curl -sL "$url" | while read -r ip; do
    case "$ip" in
        ''|\#*) continue ;;
    esac
    iptables -A "$chain_new" -d "$ip" -p tcp --dport 443 -j REJECT
    iptables -A "$chain_new" -d "$ip" -p udp --dport 443 -j REJECT
done

logger -t DOH_SCRIPT "Swap chains and clean up old"
# Update FORWARD to use the new chain instead of the old one
iptables -I FORWARD 2 -m comment --comment "Block DoH providers" -j "$chain_new"
iptables -D FORWARD -j "$chain" -m comment --comment "Block DoH providers" 2>/dev/null
iptables -F "$chain" 2>/dev/null
iptables -X "$chain" 2>/dev/null
iptables -E "$chain_new" "$chain"
