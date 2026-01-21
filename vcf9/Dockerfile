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

# ===== THE PROPER WAY: SYSTEM-MANAGED ANSIBLE & COLLECTIONS =====
# 1. We installed python3-requests and python3-aiohttp via apt above.
# 2. Install collections to a global path that Ansible checks by default.
RUN mkdir -p /usr/share/ansible/collections && \
    ansible-galaxy collection install vmware.vmware_rest community.vmware -p /usr/share/ansible/collections

# Ensure Ansible environment is aware of the collection path
ENV ANSIBLE_COLLECTIONS_PATH=/usr/share/ansible/collections
# ==========================================================

COPY path/kubectl /usr/local/bin/
COPY path/kubectl-vsphere /usr/local/bin/
COPY VMware-ovftool-5.0.0-24781994-lin.x86_64.zip /root
COPY k8 /root/k8

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

# Copy your application files
COPY ovftool /root/ovftool
COPY ansible.cfg /root/

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
    apt-get install -y powershell
RUN echo "source /usr/share/bash-completion/bash_completion" >> /root/.bashrc && \
    echo 'source <(kubectl completion bash)' >> /root/.bashrc

#install k9s
RUN wget https://github.com/derailed/k9s/releases/download/v0.50.18/k9s_Linux_amd64.tar.gz && \
    tar xvf k9s_Linux_amd64.tar.gz && \
    cp k9s /usr/local/bin

# Create the startup script
RUN echo '#!/bin/bash' > /usr/local/bin/start.sh && \
    echo 'mkdir -p /var/run/sshd' >> /usr/local/bin/start.sh && \
    echo '/usr/sbin/sshd -D &' >> /usr/local/bin/start.sh && \
    echo 'echo "SSH server starting..."' >> /usr/local/bin/start.sh && \
    echo 'cd /root/tonjiak/vcf9/offlinedepot/' >> /usr/local/bin/start.sh && \
    echo 'chmod +x tls.cert.key.sh' >> /usr/local/bin/start.sh && \
    echo './tls.cert.key.sh' >> /usr/local/bin/start.sh && \
    echo 'echo "Webserver script executed."' >> /usr/local/bin/start.sh && \
    echo 'tail -f /dev/null' >> /usr/local/bin/start.sh

# broadcom vpn setup
RUN apt install -y openconnect && \
    mkdir -p /root/tonjiak/vcf9/offlinedepot/vpn && \
    cd /root/tonjiak/vcf9/offlinedepot/vpn/ && \
    echo "#!/bin/bash" > vpn.up.sh  && \
    echo "set -x"  >> vpn.up.sh  && \
    echo "openconnect -u 'ty036880@broadcom.net' \
     --protocol=gp --csd-wrapper /usr/libexec/openconnect/hipreport.sh \ 
     portal.vpn.broadcom.com -b" >> vpn.up.sh  && \
    echo "#!/bin/bash" > vpn.down.sh  && \
    echo "set -x"  >> vpn.down.sh  && \
    echo "ps aux | grep -v -e defunct -e grep | grep openconnect | awk '{print \$2}' | xargs kill -9" >> vpn.down.sh && \
    chmod +x vpn.up.sh  && \
    chmod +x vpn.down.sh

# Explicitly set permissions
RUN chmod +x /usr/local/bin/start.sh

# Expose ports
EXPOSE 22
EXPOSE 443

ENTRYPOINT ["/usr/local/bin/start.sh"]
