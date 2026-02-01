FROM nginx:alpine

# Install dependencies: openconnect, bash, and procps (for ps/kill)
RUN apk add --no-cache openconnect bash procps apache2-utils openssl

# Create your directory structure
RUN mkdir -p /root/tonjiak/vcf9/offlinedepot/vpn

# Set up the VPN UP script
RUN echo "#!/bin/bash" > /root/tonjiak/vcf9/offlinedepot/vpn/vpn.up.sh && \
    echo "set -x" >> /root/tonjiak/vcf9/offlinedepot/vpn/vpn.up.sh && \
    echo "openconnect -u 'ty036880@broadcom.net' --protocol=gp portal.vpn.broadcom.com -b" >> /root/tonjiak/vcf9/offlinedepot/vpn/vpn.up.sh

# Set up the VPN DOWN script
RUN echo "#!/bin/bash" > /root/tonjiak/vcf9/offlinedepot/vpn/vpn.down.sh && \
    echo "set -x" >> /root/tonjiak/vcf9/offlinedepot/vpn/vpn.down.sh && \
    echo "ps aux | grep -v -e defunct -e grep | grep openconnect | awk '{print \$2}' | xargs kill -9" >> /root/tonjiak/vcf9/offlinedepot/vpn/vpn.down.sh

RUN chmod +x /root/tonjiak/vcf9/offlinedepot/vpn/vpn.up.sh && \
    chmod +x /root/tonjiak/vcf9/offlinedepot/vpn/vpn.down.sh

# Note: hipreport.sh is omitted because Alpine's openconnect 
# usually handles GP differently, but you can add it if needed.
