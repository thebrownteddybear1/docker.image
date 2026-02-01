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
    nginx \
    apache2-utils \
    openconnect \
    && rm -rf /var/lib/apt/lists/*

#### GEMINI - Depot & Nginx Configuration ####

# 1. Create directory and initial validation file
RUN mkdir -p /depot && echo "Depot-EMEA" > /depot/index.html

# 2. Setup Password and SSL Certificate
RUN htpasswd -bc /etc/nginx/.htpasswd depot_user "VMware1!" && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt \
    -subj "/C=BG/ST=Sof/L=/O=BRCM/OU=VCF/CN=depot.corp.internal/emailAddress=myemail@brcm.com"

# 3. Inject Nginx Config exactly as requested
RUN printf 'server {\n\
        listen 80 default_server;\n\
        listen [::]:80 default_server;\n\n\
        # SSL configuration\n\
        listen 443 ssl;\n\
        ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;\n\
        ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;\n\
        ssl_protocols TLSv1.2 TLSv1.3;\n\
        ssl_ciphers HIGH:!aNULL:!MD5;\n\n\
        root /depot;\n\n\
        index index.html index.htm index.nginx-debian.html;\n\n\
        server_name depot.vcf-gcp.broadcom.net;\n\n\
        location / {\n\
                autoindex on;\n\
                auth_basic "Restricted Content";\n\
                auth_basic_user_file /etc/nginx/.htpasswd;\n\
                try_files $uri $uri/ =404;\n\
        }\n\
}\n' > /etc/nginx/sites-available/default

RUN service nginx reload && \
echo "Depot-EMEA" >> /depot/index.html
#### END GEMINI ####

# ===== ANSIBLE COLLECTIONS =====
RUN mkdir -p /usr/share/ansible/collections && \
    ansible-galaxy collection install vmware.vmware_rest community.vmware -p /usr/share/ansible/collections
ENV ANSIBLE_COLLECTIONS_PATH=/usr/share/ansible/collections

# File Transfers
COPY path/kubectl /usr/local/bin/
COPY path/kubectl-vsphere /usr/local/bin/
COPY VMware-ovftool-5.0.0-24781994-lin.x86_64.zip /root
COPY k8 /root/k8
COPY ovftool /root/ovftool

# Enable color support for ls in bash
RUN echo "alias ls='ls --color=auto'" >> /root/.bashrc && \
    echo "alias ll='ls -alF'" >> /root/.bashrc && \
    echo "alias la='ls -A'" >> /root/.bashrc && \
    echo "alias l='ls -CF'" >> /root/.bashrc

# Unset locale variables to suppress warnings
RUN echo "unset LANG LC_ALL" >> /root/.bashrc

# Set a working directory
WORKDIR /root

# SSH Setup
RUN mkdir -p /var/run/sshd && \
    echo 'root:VMware1!VMware1!' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh

# Git configuration
RUN git config --global user.email "thebrownteddybear@gmail.com" && \ 
    git config --global user.name "teddy" && \
    git config --global credential.helper store

# Clone the repository during build
RUN git clone https://x-access-token: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@github.com/thebrownteddybear1/tonjiak.git /root/tonjiak

# Install PowerShell
RUN wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y powershell && \
    echo "source /usr/share/bash-completion/bash_completion" >> /root/.bashrc && \
    echo 'source <(kubectl completion bash)' >> /root/.bashrc

# Install k9s
RUN wget https://github.com/derailed/k9s/releases/download/v0.50.18/k9s_Linux_amd64.tar.gz && \
    tar xvf k9s_Linux_amd64.tar.gz && \
    cp k9s /usr/local/bin

# Broadcom VPN setup
RUN mkdir -p /root/tonjiak/vcf9/offlinedepot/vpn && \
    printf "#!/bin/bash\nset -x\nopenconnect -u 'ty036880@broadcom.net' --protocol=gp --csd-wrapper /usr/libexec/openconnect/hipreport.sh portal.vpn.broadcom.com -b" > /root/tonjiak/vcf9/offlinedepot/vpn/vpn.up.sh && \
    printf "#!/bin/bash\nset -x\nps aux | grep -v -e defunct -e grep | grep openconnect | awk '{print \$2}' | xargs kill -9" > /root/tonjiak/vcf9/offlinedepot/vpn/vpn.down.sh && \
    chmod +x /root/tonjiak/vcf9/offlinedepot/vpn/vpn.up.sh /root/tonjiak/vcf9/offlinedepot/vpn/vpn.down.sh

# Create the final startup script
RUN echo '#!/bin/bash' > /usr/local/bin/start.sh && \
    echo 'mkdir -p /var/run/sshd' >> /usr/local/bin/start.sh && \
    echo 'service nginx start' >> /usr/local/bin/start.sh && \
    echo '/usr/sbin/sshd -D &' >> /usr/local/bin/start.sh && \
    echo 'echo "SSH and Nginx Depot starting..."' >> /usr/local/bin/start.sh && \
    echo 'tail -f /dev/null' >> /usr/local/bin/start.sh

RUN chmod +x /usr/local/bin/start.sh

# Expose ports
EXPOSE 22 80 443

ENTRYPOINT ["/usr/local/bin/start.sh"]