#!/bin/bash
set -e

echo "Synchronizing renewed certificates to Docker proxy..."
cp -a /etc/letsencrypt/. /docker/proxy/letsencrypt/
