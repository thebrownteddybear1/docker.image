# FROM python:3.12-slim-bullseye
#FROM python:3.10-slim-bullseye
FROM python:latest

# Set non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# Copy your application files
COPY 50-cloud-init.yaml /root/
COPY path/kubectl /usr/local/bin/
COPY path/kubectl-vsphere /usr/local/bin/
#COPY ansible.cfg /root/
COPY VMware-ovftool-5.0.0-24781994-lin.x86_64.zip /root
COPY vcenter.install.scripts /root/vcenter.install.scripts

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
    python3-pip \
    locales \
    bash \
    && rm -rf /var/lib/apt/lists/*
 #   git clone https://x-access-token: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@github.com/thebrownteddybear1/tonjiak.git

# Generate locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen en_US.UTF-8

# Set locale environment variables
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# 重要：创建 python 符号链接
RUN ln -sf /usr/bin/python3 /usr/bin/python

# 更简单的 Ansible 安装方式（使用 pip）
RUN pip install --upgrade pip && \
    pip install ansible && \
    pip install requests && \
    pip install pyvmomi && \
    pip install pyvim

# 安装 Ansible collections
# community.vmware 可以从 Galaxy 安装
# vmware.ansible_for_nsxt 需要从 GitHub 安装
RUN ansible-galaxy collection install community.vmware && \
    ansible-galaxy collection install git+https://github.com/vmware/ansible-for-nsxt.git && \
    ansible-galaxy collection install git+https://github.com/vmware/ansible-for-nsxt.git,v3.2.0 && \
    ansible-galaxy collection install community.general && \
    ansible-galaxy collection install ansible.posix && \
    ansible-galaxy collection install vmware.vmware && \
    ansible-galaxy collection install vmware.vmware_rest


# Install Carvel tools
RUN echo "install carvel" && \
    wget -O install.sh https://carvel.dev/install.sh && \
    chmod +x install.sh && \
    bash ./install.sh

# SSH Setup
RUN mkdir -p /var/run/sshd && \
    echo 'root:VMware1!VMware1!' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh

# Extract OVF tool
RUN cd /root && \
    unzip VMware-ovftool-5.0.0-24781994-lin.x86_64.zip && \
    chmod +x /root/ovftool/ovftool

# Add OVF tool to PATH
ENV PATH=$PATH:/root/ovftool

# Set a working directory
WORKDIR /root

# 移除硬编码的 TOKEN（安全风险）
# 改用更安全的方式
# 注意：这里注释掉，你可以在构建时传递参数
# ARG GIT_TOKEN
# ENV GIT_TOKEN=${GIT_TOKEN}

# Configure git
RUN git config --global user.email "thebrownteddybear@gmail.com" && \
    git config --global user.name "Container User"

# Expose SSH port
EXPOSE 22

# Create a startup script
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'set -e' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# 设置 Python 环境' >> /start.sh && \
    echo 'export ANSIBLE_PYTHON_INTERPRETER=/usr/bin/python' >> /start.sh && \
    echo 'export PATH=$PATH:/root/ovftool' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# 启动 SSH 服务' >> /start.sh && \
    echo '/usr/sbin/sshd -D &' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'echo "Container is running..."' >> /start.sh && \
    echo 'echo "Python path: $(which python)"' >> /start.sh && \
    echo 'echo "Python version: $(python --version)"' >> /start.sh && \
    echo 'echo "Ansible version: $(ansible --version | head -1)"' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# 列出已安装的 collections' >> /start.sh && \
    echo 'echo "Installed Ansible Collections:"' >> /start.sh && \
    echo 'ansible-galaxy collection list' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# 保持容器运行' >> /start.sh && \
    echo 'tail -f /dev/null' >> /start.sh && \
    chmod +x /start.sh

ENTRYPOINT ["/start.sh"]

# 创建默认的 ansible.cfg 如果不存在
RUN echo "[defaults]" > /root/ansible.cfg && \
    echo "interpreter_python = /usr/bin/python" >> /root/ansible.cfg && \
    echo "host_key_checking = False" >> /root/ansible.cfg && \
    echo "" >> /root/ansible.cfg && \
    echo "[connection]" >> /root/ansible.cfg && \
    echo "pipelining = True" >> /root/ansible.cfg; 
ENV CLONE="git clone https://x-access-token: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@github.com/thebrownteddybear1/tonjiak.git"
RUN cd /root; git clone https://x-access-token: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@github.com/thebrownteddybear1/tonjiak.git && \
    cp /root/ansible.cfg /root/tonjiak/
# 验证安装
RUN echo "验证安装..." && \
    python --version && \
    ansible --version && \
    ansible-galaxy collection list | grep -E "(vmware|community)" && \
    ansible-galaxy collection install community.vmware --upgrade
