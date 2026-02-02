FROM ubuntu:latest  

# Set non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# 1. Update apt and install all required packages
RUN apt-get update && apt-get install -y \
    apt-transport-https ca-certificates curl gnupg lsb-release \
    tree nano openssh-server iproute2 iputils-ping net-tools \
    git gh ssh sudo bash-completion vim sshpass openssl \
    tcpdump wget perl netplan.io frr dnsmasq gzip zip unzip \
    software-properties-common python3 python3-pip \
    python3-requests python3-aiohttp bash ansible \
    nginx apache2-utils openconnect \
    && rm -rf /var/lib/apt/lists/*

#### SECTION: DEPOT & NGINX CONFIGURATION ####

# Create depot root
RUN mkdir -p /depot && echo "Depot-EMEA" > /depot/index.html

# Setup Nginx Password and SSL Certificate
RUN htpasswd -bc /etc/nginx/.htpasswd depot_user "VMware1!" && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt \
    -subj "/C=BG/ST=Sof/L=/O=BRCM/OU=VCF/CN=depot.corp.internal/emailAddress=myemail@brcm.com"

# Inject the specific Nginx server block
RUN printf 'server {\n\
        listen 80 default_server;\n\
        listen [::]:80 default_server;\n\
        listen 443 ssl;\n\
        ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;\n\
        ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;\n\
        ssl_protocols TLSv1.2 TLSv1.3;\n\
        ssl_ciphers HIGH:!aNULL:!MD5;\n\
        root /depot;\n\
        index index.html index.htm index.nginx-debian.html;\n\
        server_name depot.vcf-gcp.broadcom.net;\n\
        location / {\n\
                autoindex on;\n\
                auth_basic "Restricted Content";\n\
                auth_basic_user_file /etc/nginx/.htpasswd;\n\
                try_files $uri $uri/ =404;\n\
        }\n\
}\n' > /etc/nginx/sites-available/default

#### SECTION: VCF DOWNLOAD TOOL & CONFIG UPDATES ####

# Copy the tarball (Ensure this file is in your build directory)
COPY vcf-download-tool-9.0.2.0.25151284.tar /depot/

# Extract and run SED replacements for staging
RUN mkdir -p /depot/vcf-download-tool && \
    mv /depot/vcf-download-tool-9.0.2.0.25151284.tar /depot/vcf-download-tool/ && \
    cd /depot/vcf-download-tool/ && \
    tar -zxvf vcf-download-tool-9.0.2.0.25151284.tar && \
    sed -i 's/lcm.depot.adapter.host=dl.broadcom.com/lcm.depot.adapter.host=dl-pstg.broadcom.com/g' \
    /depot/vcf-download-tool/conf/application-prod.properties \
    /depot/vcf-download-tool/conf/application-prodv.properties

#### SECTION: POWERSHELL & BROADCOM TOKEN SCRIPT ####

# Install PowerShell
RUN wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb && \
    apt-get update && apt-get install -y powershell

# Create PowerShell Profile with Staging Credentials
RUN mkdir -p /root/.config/powershell/ && \
    printf '$env:DepotTier="Staging"\n\
$env:StagingClientId="7SxxUEoYtKYpRerCi6U0d3QWMFSa485UkbvorpRlO46h4fde"\n\
$env:StagingClientSecret="PuW6Esb1qYRqcN92RAwzpqvRPteeIy5UNuR1ywE4oy09b4LQ4ijN4nHmY8TJbQaG"\n\
$env:StagingUserEmail="svc.config-infra@broadcom.com"\n' > /root/.config/powershell/Microsoft.PowerShell_profile.ps1

# Create the DownloadToken.ps1 script (simplified version for the container)
COPY DownloadToken.ps1 /depot/vcf-download-tool/DownloadToken.ps1
RUN chmod +x /depot/vcf-download-tool/DownloadToken.ps1

#### SECTION: FINAL TOOLS & ENVIRONMENT ####

# Ansible Collections
RUN mkdir -p /usr/share/ansible/collections && \
    ansible-galaxy collection install vmware.vmware_rest community.vmware -p /usr/share/ansible/collections
ENV ANSIBLE_COLLECTIONS_PATH=/usr/share/ansible/collections

# Kubernetes Tools & OVF (Ensure these exist in your local path/)
COPY path/kubectl /usr/local/bin/
COPY path/kubectl-vsphere /usr/local/bin/
COPY VMware-ovftool-5.0.0-24781994-lin.x86_64.zip /root/
COPY k8 /root/k8
COPY ovftool /root/ovftool

# Git Configuration
RUN git config --global user.email "thebrownteddybear@gmail.com" && \ 
    git config --global user.name "teddy" && \
    git config --global credential.helper store

# Clone Repository
RUN git clone https://x-access-token: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@github.com/thebrownteddybear1/tonjiak.git /root/tonjiak

# K9s Installation
RUN wget https://github.com/derailed/k9s/releases/download/v0.50.18/k9s_Linux_amd64.tar.gz && \
    tar xvf k9s_Linux_amd64.tar.gz && cp k9s /usr/local/bin

# Broadcom VPN Scripts
RUN mkdir -p /root/tonjiak/vcf9/offlinedepot/vpn && \
    printf "#!/bin/bash\nset -x\nopenconnect -u 'ty036880@broadcom.net' --protocol=gp --csd-wrapper /usr/libexec/openconnect/hipreport.sh portal.vpn.broadcom.com -b" > /root/tonjiak/vcf9/offlinedepot/vpn/vpn.up.sh && \
    printf "#!/bin/bash\nset -x\nps aux | grep -v -e defunct -e grep | grep openconnect | awk '{print \$2}' | xargs kill -9" > /root/tonjiak/vcf9/offlinedepot/vpn/vpn.down.sh && \
    chmod +x /root/tonjiak/vcf9/offlinedepot/vpn/vpn.up.sh /root/tonjiak/vcf9/offlinedepot/vpn/vpn.down.sh

# Bash Customization
RUN echo "alias ls='ls --color=auto'\nalias ll='ls -alF'\nalias la='ls -A'\nalias l='ls -CF'\nunset LANG LC_ALL\nsource /usr/share/bash-completion/bash_completion\nsource <(kubectl completion bash)" >> /root/.bashrc

# Startup Script
RUN printf '#!/bin/bash\nmkdir -p /var/run/sshd\nservice nginx start\n/usr/sbin/sshd -D &\necho "VCF Manager Ready. Nginx and SSH started."\ntail -f /dev/null\n' > /usr/local/bin/start.sh && \
    chmod +x /usr/local/bin/start.sh

WORKDIR /root
EXPOSE 22 80 443
ENTRYPOINT ["/usr/local/bin/start.sh"]