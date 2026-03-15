#!/bin/sh

logger -t FIREWALL_SCRIPT "Setting up firewall"
[ -f /tmp/.rc_custom ] && source /tmp/.rc_custom

# Make sure the LAN iface has both of these until I complete the transition to .8
ip addr add 192.168.1.8/24 dev br0 || true
ip addr add 192.168.1.254/24 dev br0 || true

logger -t FIREWALL_SCRIPT "Backgrounding DoH setup"

# Now block known DNS over HTTP addresses. Background because this takes a while.
(
url="https://raw.githubusercontent.com/zzantozz/router-config/refs/heads/master/load-doh-ips.sh"
expected_sha="89608a2f77a1b9b743e351eec45012c4f34c8161"

logger -t FIREWALL_SCRIPT "Waiting for github"
until ping -c1 github.com > /dev/null 2>&1; do sleep 2; done

logger -t FIREWALL_SCRIPT "Downloading script to load DoH IPs"
curl -sLo /tmp/load-doh-ips.sh "$url"

check="$(sha1sum /tmp/load-doh-ips.sh)"
[ "$check" = "$expected_sha  /tmp/load-doh-ips.sh" ] || {
    logger -t STARTUP_SCRIPT "Checksum verification failed"
    rm -f /tmp/load-doh-ips.sh
    exit 1
}

logger -t FIREWALL_SCRIPT "Running downloaded script"
sh /tmp/load-doh-ips.sh

# Also run this periodically for this session.
cat /tmp/cron.d/cron_jobs 2>&1 | grep '/tmp/load-doh-ips.sh' || {
  logger -t FIREWALL_SCRIPT "Adding script to future cron"
  echo '0 5 * * * root sh /tmp/load-doh-ips.sh' >> /tmp/cron.d/cron_jobs
}
) &
