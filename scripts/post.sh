#!/bin/bash

echo "Running post configuration..."

sysctl --system
update-ca-certificates

systemctl enable qemu-guest-agent
systemctl start qemu-guest-agent

echo "Post configuration completed"
