#!/bin/sh
set -e

# Add loopback alias
ip addr add 127.0.0.2/32 dev lo

# Start Tor for onion resolution
tor --SocksPort 9050 --DataDirectory /tmp/tor-onion \
  > >(sed 's/^/\x1b[42m[onion]\x1b[0m /') \
  2> >(sed 's/^/\x1b[42m[onion ERR]\x1b[0m /' >&2) &

sleep 2

# Start Tor for clearnet resolution
tor --SocksPort 9051 --DataDirectory /tmp/tor-clearnet \
  > >(sed 's/^/\x1b[41m[clearnet]\x1b[0m /') \
  2> >(sed 's/^/\x1b[41m[clearnet ERR]\x1b[0m /' >&2) &

sleep 45

# Start socat for .onion DNS resolution
socat TCP4-LISTEN:443,bind=127.0.0.1,reuseaddr,fork \
  SOCKS5:127.0.0.1:dns4torpnlfs2ifuz2s2yf3fc7rdmsbhm6rw75euj35pac6ap25zgqad.onion:443,socksport=9050 \
  > >(sed 's/^/\x1b[44m[onion]\x1b[0m /') \
  2> >(sed 's/^/\x1b[44m[onion ERR]\x1b[0m /' >&2) &

sleep 2

# Start backup resolver through clearnet Tor proxy
socat TCP4-LISTEN:443,bind=127.0.0.2,reuseaddr,fork \
  SOCKS5:127.0.0.1:1.1.1.1:443,socksport=9051 \
  > >(sed 's/^/\x1b[45m[clearnet]\x1b[0m /') \
  2> >(sed 's/^/\x1b[45m[clearnet ERR]\x1b[0m /' >&2) &

sleep 2

# Host overrides
cat << EOF >> /etc/hosts
127.0.0.1 dns4torpnlfs2ifuz2s2yf3fc7rdmsbhm6rw75euj35pac6ap25zgqad.onion
127.0.0.2 one.one.one.one
EOF

sleep 2

dnscrypt-proxy -config dnscrypt-proxy.toml
