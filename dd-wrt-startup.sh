url="https://raw.githubusercontent.com/zzantozz/router-config/refs/heads/master/load-doh-ips.sh"
expected_sha="ec78f775cb77cccbe364dd0d7e5ac4dab59aea04"

until ping -c1 github.com > /dev/null 2>&1; do sleep 2; done

wget -q -O /tmp/load-doh-ips.sh "$url"

echo "$expected_sha  /tmp/load-doh-ips.sh" | sha1sum -c - || {
    echo "Checksum verification failed" >&2
    rm -f /tmp/load-doh-ips.sh
    exit 1
}

sh /tmp/load-doh-ips.sh

# Also run this periodically for this session.
echo '0 * * * * root sh /tmp/load-doh-ips.sh' >> /tmp/cron.d/cron_jobs
