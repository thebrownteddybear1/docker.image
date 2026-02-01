FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install Nginx, OpenConnect, and networking tools
RUN apt-get update && apt-get install -y nginx apache2-utils openconnect curl procps openssl && rm -rf /var/lib/apt/lists/*

# Create simplified directory structure
RUN mkdir -p /root/offlinedepot/vpn /depot

# Layer: VPN UP script
RUN echo "#!/bin/bash\nset -x\nopenconnect -u 'ty036880@broadcom.net' --protocol=gp --csd-wrapper /usr/libexec/openconnect/hipreport.sh portal.vpn.broadcom.com -b" > /root/offlinedepot/vpn/vpn.up.sh

# Layer: VPN DOWN script
RUN echo "#!/bin/bash\nset -x\nps aux | grep -v -e defunct -e grep | grep openconnect | awk '{print \$2}' | xargs kill -9" > /root/offlinedepot/vpn/vpn.down.sh

RUN chmod +x /root/offlinedepot/vpn/vpn.up.sh /root/offlinedepot/vpn/vpn.down.sh

# Link logs to Docker output
RUN ln -sf /dev/stdout /var/log/nginx/access.log && ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]