#!/bin/bash

echo "66.249.68.39 openblog.com" >> /etc/hosts

iptables -t nat -A OUTPUT -d 66.249.68.39 -j DNAT --to-destination 127.0.0.1

# Start mock-api service
cd /opt/mock-api
sh restart.sh

# Execute the CMD passed from Dockerfile
exec "$@"