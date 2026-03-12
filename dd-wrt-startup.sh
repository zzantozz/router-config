#!/bin/sh

logger -t STARTUP_SCRIPT "Begin startup script"

[ -f /tmp/.rc_custom ] && source /tmp/.rc_custom

# Take care of well-known DNS ports
iptables -t nat -I PREROUTING -i br0 -p udp --dport 53 -j REDIRECT --to-ports 53 -m comment --comment "Keep all DNS local"
iptables -t nat -I PREROUTING -i br0 -p tcp --dport 53 -j REDIRECT --to-ports 53 -m comment --comment "Keep all DNS local"
# Insert these after the "accept related,established" rule
iptables -I FORWARD 2 -p tcp --dport 853 -j REJECT -m comment --comment "Block DNS over TLS"
iptables -I FORWARD 2 -p udp --dport 853 -j REJECT -m comment --comment "Block DNS over TLS"

logger -t STARTUP_SCRIPT "Backgrounding startup"

# Now block known DNS over HTTP addresses. Background because this takes a while.
(
url="https://raw.githubusercontent.com/zzantozz/router-config/refs/heads/master/load-doh-ips.sh"
expected_sha="870ee1158424c78e82e02604061c8b92289af896"

logger -t STARTUP_SCRIPT "Waiting for github"
until ping -c1 github.com > /dev/null 2>&1; do sleep 2; done

logger -t STARTUP_SCRIPT "Downloading necessary script"
curl -sLo /tmp/load-doh-ips.sh "$url"

check="$(sha1sum /tmp/load-doh-ips.sh)"
[ "$check" = '870ee1158424c78e82e02604061c8b92289af896  /tmp/load-doh-ips.sh' ] || {
    logger -t STARTUP_SCRIPT "Checksum verification failed"
    rm -f /tmp/load-doh-ips.sh
    exit 1
}

logger -t STARTUP_SCRIPT "Running downloaded script"
sh /tmp/load-doh-ips.sh

logger -t STARTUP_SCRIPT "Adding script to future cron"
# Also run this periodically for this session.
echo '0 5 * * * root sh /tmp/load-doh-ips.sh' >> /tmp/cron.d/cron_jobs
) &
