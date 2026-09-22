#!/bin/bash
set -e

echo "Stopping Docker proxy for Certbot standalone challenge..."
docker stop proxy
