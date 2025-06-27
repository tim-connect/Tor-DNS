# Tor-Routed Dual-Upstream DNS-over-HTTPS Proxy
A fault tolerant DoHoT (DNS over HTTPS over Tor) docker container

---

This project sets up a Dockerized DNS proxy that routes **all DNS queries through Tor**, using **Cloudflare's .onion DoH endpoint** as the primary upstream and a **clearnet fallback** via Tor SOCKS. This enables **private, leak-resistant, encrypted DNS resolution**, even in hostile networks.

---

## What This Stack Includes

- **Dual upstreams**:
  - `dnscrypt-proxy`
       → **Cloudflare’s hidden DoH resolver** (`.onion`)
       → **Clearnet Cloudflare DoH** via Tor SOCKS as fallback
- **Full Tor routing** via a local Tor daemon
- **Healthchecks**: Ensures both upstreams are live before marking container healthy
- **Custom loopback routing** (`127.0.0.2`) to isolate upstreams inside the container
- **Prometheus metrics** endpoints per upstream: `9100` (hidden) and `9200` (clearnet fallback)
- Built with Alpine Linux for minimal image size

---

## Services

### `tor-dns-proxy`

This container provides encrypted DNS-over-HTTPS via Tor using [dnscrypt-proxy](https://github.com/DNSCrypt/dnscrypt-proxy/tree/master).

- **Primary DoH**: `.onion` DoH endpoint (Cloudflare)
- **Backup DoH**: Clearnet DoH via Tor SOCKS proxy
- **Ports Exposed (internally only)**:
  - `53/udp` – DNS
  - `9100` – Metrics for primary
  - `9200` – Metrics for backup 
- **External access is easily configurable, see docker-compose.yaml for details**
---

## Health Checks

Docker health checks validate DNS resolution through both upstreams every 15 seconds:

```sh
dig @127.0.0.1 -p 53 cloudflare.com A +short
```

A cronjob script is also provided, this was the easiest way to make the container have high reliability, usually it runs for days without issue, but this makes it possible to simply forget about.

## Caveats

This setup is not suitable for all services. While a good upstream for services that can cache responses like AdGuard, Unbound or dnsmasq, it can be an issue for services that may rely on IPs that change often such as DDNS if it accesses the torproxy through a cache.
