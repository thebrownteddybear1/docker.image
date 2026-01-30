#!/bin/bash
# Create required directories (just in case)
mkdir -p /run/sshd /var/run/sshd 2>/dev/null || true

# Clone the public repository
if [ ! -d "/root/tonjiak" ]; then
    echo "Cloning public repository..."
    git clone https://github.com/thebrownteddybear1/tonjiak.git /root/tonjiak
fi

# Keep container running
echo "Container is running..."
tail -f /dev/null