FROM ubuntu:latest

# Set non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# Update apt and install initial packages
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    tree \
    nano \
    openssh-server \
    iproute2 \
    iputils-ping \
    net-tools \
    git \
    gh \
    ssh \
    sudo \
    bash-completion \
    vim \
    sshpass \
    openssl \
    tcpdump \
    wget \
    perl \
    netplan.io \
    frr \
    dnsmasq \
    gzip \
    zip \
    unzip \
    software-properties-common \
    python3 \
    python3-pip \
    python3-requests \
    python3-aiohttp \
    bash \
    ansible \
    && rm -rf /var/lib/apt/lists/*

#### GEMINI - Fixed Layer
# 1. Added apt-get update here to find nginx
# 2. Used htpasswd -b to provide password non-interactively
# 3. Fixed sudo/openssl logic
RUN apt-get update && apt-get install -y nginx apache2-utils && \
    mkdir -p /depot && \
    htpasswd -bc /etc/nginx/.htpasswd depot_user "VMware1!" && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt \
    -subj "/C=BG/ST=Sof/L=/O=BRCM/OU=VCF/CN=depot.corp.internal/emailAddress=myemail@brcm.com" && \
    rm -rf /var/lib/apt/lists/*

# ===== THE PROPER WAY: SYSTEM-MANAGED ANSIBLE & COLLECTIONS =====
RUN mkdir -p /usr/share/ansible/collections && \
    ansible-galaxy collection install vmware.vmware_rest community.vmware -p /usr/share/ansible/collections

ENV ANSIBLE_COLLECTIONS_PATH=/usr/share/ansible/collections
# ==========================================================

# ... [Rest of your COPY commands and configuration] ...

# Create the startup script (Ensure Nginx starts)
RUN echo '#!/bin/bash' > /usr/local/bin/start.sh && \
    echo 'service nginx start' >> /usr/local/bin/start.sh && \
    echo '/usr/sbin/sshd -D &' >> /usr/local/bin/start.sh && \
    echo 'tail -f /dev/null' >> /usr/local/bin/start.sh

RUN chmod +x /usr/local/bin/start.sh

EXPOSE 22 80 443

ENTRYPOINT ["/usr/local/bin/start.sh"]