FROM ubuntu:latest  

# Set non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# 1. Update apt and install all required packages
RUN apt-get update && apt-get install -y \
    apt-transport-https ca-certificates curl gnupg lsb-release \
    tree nano openssh-server iproute2 iputils-ping net-tools \
    git gh ssh sudo bash-completion vim sshpass openssl \
    tcpdump wget perl netplan.io gzip zip unzip \
    software-properties-common python3 python3-pip \
    python3-requests python3-aiohttp bash ansible \
    nginx apache2-utils openconnect jq gettext-base dnsutils \
    && rm -rf /var/lib/apt/lists/*

#### SECTION: DEPOT & NGINX CONFIGURATION ####

RUN mkdir -p /depot && echo "Depot-EMEA" > /depot/index.html

RUN htpasswd -bc /etc/nginx/.htpasswd depot_user "VMware1!" && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt \
    -subj "/C=BG/ST=Sof/L=/O=BRCM/OU=VCF/CN=depot.corp.internal/emailAddress=myemail@brcm.com"

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

#### SECTION: VCF DOWNLOAD TOOL IN /ROOT/DOWNLOADTOOL ####

RUN mkdir -p /root/downloadtool

# Copy the compressed file
#################################################################
#################################################################
# in the container, 
# login to vpn using /root/tonjia/vcf9/offlinedepot/4vpn
# go to /root/downloadtool
# run the pwsh --file DownloadToken.ps1 to the token
# replace the token inside edit.me.add.token.downloadtool.sh and run it
#################################################################
#################################################################
COPY vcf-download-tool-9.0.2.0.25151284.tar.gz /root/downloadtool/

# Extraction and Configuration Update (Fixed Syntax)
RUN cd /root/downloadtool && \
    gunzip vcf-download-tool-*.tar.gz && \
    tar -xvf vcf-download-tool-*.tar && \
    find /root/downloadtool -name "application-prod*.properties" -exec \
    sed -i 's/lcm.depot.adapter.host=dl.broadcom.com/lcm.depot.adapter.host=dl-pstg.broadcom.com/g' {} +

COPY edit.me.add.token.downloadtool.sh /root/downloadtool/edit.me.add.token.downloadtool.sh
RUN sed -i 's/\r$//' /root/downloadtool/edit.me.add.token.downloadtool.sh && \
    chmod +x /root/downloadtool/edit.me.add.token.downloadtool.sh
#### SECTION: POWERSHELL & BROADCOM TOKEN SCRIPT ####

RUN wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb && \
    apt-get update && apt-get install -y powershell

RUN mkdir -p /root/.config/powershell/ && \
    printf '$env:DepotTier="Staging"\n\
$env:StagingClientId="7SxxUEoYtKYpRerCi6U0d3QWMFSa485UkbvorpRlO46h4fde"\n\
$env:StagingClientSecret="PuW6Esb1qYRqcN92RAwzpqvRPteeIy5UNuR1ywE4oy09b4LQ4ijN4nHmY8TJbQaG"\n\
$env:StagingUserEmail="svc.config-infra@broadcom.com"\n' > /root/.config/powershell/Microsoft.PowerShell_profile.ps1

COPY DownloadToken.ps1 /root/downloadtool/DownloadToken.ps1
RUN chmod +x /root/downloadtool/DownloadToken.ps1


#### SECTION: INSTALL POWERCLI MODULES ####
RUN pwsh -Command 'Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted; \
    Install-Module -Name VMware.PowerCLI -Confirm:$false -Force; \
    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -ParticipateInCEIP $false -Confirm:$false'

    
#### SECTION: FINAL TOOLS & REPO CLONE ####

RUN git config --global user.email "thebrownteddybear@gmail.com" && \
    git config --global user.name "teddy"

# Combine these and remove the previous separate RUN lines for these repos
RUN git clone https://github.com/thebrownteddybear1/tonjiak.git /root/tonjiak && \
    git clone https://github.com/papivot/bash-wcpcli9-multi-az.git /root/bash-wcpcli9-multi-az

# Ensure these paths/files exist in your local build context
COPY path/kubectl /usr/local/bin/
COPY path/kubectl-vsphere /usr/local/bin/
COPY VMware-ovftool-*.zip /root/
COPY k8 /root/k8
COPY ovftool /root/ovftool


RUN echo "alias ls='ls --color=auto'\nalias ll='ls -alF'\nalias la='ls -A'\nalias l='ls -CF'\nunset LANG LC_ALL\nsource /usr/share/bash-completion/bash_completion\nsource <(kubectl completion bash)" >> /root/.bashrc

# Startup Script
RUN printf '#!/bin/bash\nmkdir -p /var/run/sshd\nservice nginx start\n/usr/sbin/sshd -D &\necho "VCF Manager Ready."\ntail -f /dev/null\n' > /usr/local/bin/start.sh && \
    chmod +x /usr/local/bin/start.sh


#### SECTION: VCF CLI INSTALLATION ####
# Download, extract, rename to vcfcli, and make executable
RUN curl -L https://packages.broadcom.com/artifactory/vcf-distro/vcf-cli/linux/amd64/v9.0.0/vcf-cli.tar.gz -o /tmp/vcf-cli.tar.gz && \
    tar -xzvf /tmp/vcf-cli.tar.gz -C /tmp && \
    mv /tmp/vcf-cli-linux_amd64 /usr/local/bin/vcfcli && \
    chmod +x /usr/local/bin/vcfcli && \
    rm /tmp/vcf-cli.tar.gz
    
WORKDIR /root
EXPOSE 22 80 443
ENTRYPOINT ["/usr/local/bin/start.sh"]