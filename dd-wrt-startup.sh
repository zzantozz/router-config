#!/bin/sh

logger -t STARTUP_SCRIPT "Backgrounding startup"

(
url="https://raw.githubusercontent.com/zzantozz/router-config/refs/heads/master/load-doh-ips.sh"
expected_sha="ec78f775cb77cccbe364dd0d7e5ac4dab59aea04"

logger -t STARTUP_SCRIPT "Waiting for github"
until ping -c1 github.com > /dev/null 2>&1; do sleep 2; done

logger -t STARTUP_SCRIPT "Downloading necessary script"
curl -sLo /tmp/load-doh-ips.sh "$url"

echo "$expected_sha  /tmp/load-doh-ips.sh" | sha1sum - || {
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
