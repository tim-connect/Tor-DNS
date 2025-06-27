#!/bin/bash

# Intended for use with a cronjob: */3 * * * * /services/dns/custom-tor/cron_restart.sh >> /var/log/restart_tor_dns_proxy.log 2>&1
# make sure this file is executable with chmod +x cron_restart.sh
# after much frustration with reliability, this is the simplest way to make sure the container is reasonably available

CONTAINER_NAME="tor-dns-proxy"
CONTAINER_ID=$(docker ps -qf "name=${CONTAINER_NAME}")

if [ -n "$CONTAINER_ID" ]; then
    HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_ID")

    if [ "$HEALTH_STATUS" = "unhealthy" ]; then
        echo "[WARNING] Container $CONTAINER_NAME is unhealthy. Restarting... (ID: $CONTAINER_ID)"
        docker restart "$CONTAINER_ID"
    else
        echo "[INFO] Container $CONTAINER_NAME is healthy. No action needed. (ID: $CONTAINER_ID)"
    fi
else
    echo "[ERROR] Container $CONTAINER_NAME not found or not running."
fi
