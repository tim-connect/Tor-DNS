#!/bin/sh

set -e

ip addr add 127.0.0.2/32 dev lo

tor &
sleep 20

# Start socat to forward localhost:443 to the hidden resolver via Tor
socat TCP4-LISTEN:443,bind=127.0.0.1,reuseaddr,fork SOCKS4A:127.0.0.1:dns4torpnlfs2ifuz2s2yf3fc7rdmsbhm6rw75euj35pac6ap25zgqad.onion:443,socksport=9050 &
sleep 2

#backup public resolver
socat TCP4-LISTEN:443,bind=127.0.0.2,reuseaddr,fork SOCKS4A:127.0.0.1:1.1.1.1:443,socksport=9050 &
sleep 2

cat << EOF >> /etc/hosts
127.0.0.1 dns4torpnlfs2ifuz2s2yf3fc7rdmsbhm6rw75euj35pac6ap25zgqad.onion
127.0.0.2 one.one.one.one
EOF

# Start cloudflared DoH proxy, pointing to the local socat tunnel
cloudflared proxy-dns --metrics 0.0.0.0:9100 --address 0.0.0.0 --max-upstream-conns 250 --upstream "https://dns4torpnlfs2ifuz2s2yf3fc7rdmsbhm6rw75euj35pac6ap25zgqad.onion/dns-query" &
sleep 2

# HTTPS backup to clearnet
exec cloudflared proxy-dns --metrics 0.0.0.0:9200 --address 0.0.0.0 --port 6053 --max-upstream-conns 250 --upstream "https://one.one.one.one/dns-query"
