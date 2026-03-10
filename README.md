# Router config

This starts off as a really simple place to store some DD-WRT config stuff. I needed a place to store a script
that the router can download at startup, and github works nicely.

All it is right now is a simple script to read in a list of DNS-over-HTTP IP addresses from another github repo
and load those IPs into an iptables chain to prevent any DoH use.

The other script is just the startup script that I'm adding to the router's NVRAM to get the script up and
running.
