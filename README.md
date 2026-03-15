# Router config

This starts off as a really simple place to store some DD-WRT config stuff. I needed a place to store a script
that the router can download, and github works nicely.

All it is right now is a simple script to read in a list of DNS-over-HTTP IP addresses from another github repo
and load those IPs into an iptables chain to prevent any DoH use.

The other script is just the custom script that sets a few rules and gets the first script up and running.

## Goal

The goal here is a safe home network using CleanBrowsing DNS, where no device can decide to use some other DNS
server. That means firewall rules to redirect and block stuff as necessary.

## Steps

This is a not-necessarily-complete list of steps to get the router set up completely. I'm writing it after the
fact and might miss something.

- I started with a factory reset, so everything was in a clean state.

- Set static DNS to CleanBrowsing DNS IPs

- Check "Ignore WAN DNS" on the Basic Setup page, or else it includes the upstream DNS

- Check "Forced DNS Redirection" and "Forced DNS Redirection DoT" under DHCP settings, or else set up iptables rules manually:

    ```
    # Take care of well-known DNS ports
    iptables -t nat -I PREROUTING -i br0 -p udp --dport 53 -j REDIRECT --to-ports 53 -m comment --comment "Keep all DNS local"
    iptables -t nat -I PREROUTING -i br0 -p tcp --dport 53 -j REDIRECT --to-ports 53 -m comment --comment "Keep all DNS local"
    # Insert these after the "accept related,established" rule
    iptables -I FORWARD 2 -p tcp --dport 853 -j REJECT -m comment --comment "Block DNS over TLS"
    iptables -I FORWARD 2 -p udp --dport 853 -j REJECT -m comment --comment "Block DNS over TLS"
    ```

- Check that IPv6 is disabled (was by default I think)

- Copy the contents of the "firewall" script into the textbox in Administration > Commands, and "Save Firewall". This makes
  it run anytime the firewall is restarted, which is fairly often, like at least every time you do a "Save & Apply".

- Get the healthchecks.io URL and save it as an env var in the custom script like

    ```
    HC_URL="<url here>"
    ```

- Enable cron in Administration > Management, or the periodic update won't run

- For debugging, turn on syslog in Services > Services
