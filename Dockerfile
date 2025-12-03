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
    ansible \
    ssh \
    sudo \
    bash-completion \
    vim \
    sshpass \
    openssl \
    tcpdump \
    wget \
    ca-certificates \
    perl \
    netplan.io \
    frr \
    dnsmasq \
    curl \
    gzip \
    zip \
    software-properties-common \
    python3 \
    python3-pip \
    python3-pyvmomi\
    && rm -rf /var/lib/apt/lists/*
#install for the ansible community.vmware  module
#RUN pip3 install PyVmomi --break-system-packages;\
RUN ansible-galaxy collection install community.vmware

# Install Carvel tools
RUN wget -O install.sh https://carvel.dev/install.sh && \
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
# Copy your application files
COPY path /root/path
COPY 50-cloud-init.yaml /root/
RUN cp /root/path/kubectl /usr/local/bin && \
    cp /root/path/kubectl-vsphere /usr/local/bin

# Set a working directory
WORKDIR /root

# *** HARCODED TOKEN ***
ENV TOKEN=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
RUN   git config --global user.email "thebrownteddybear@gmail.com" &&\ 
  git config --global user.name "teddy"
# Configure Git and clone repository
RUN git config --global credential.helper store

# Copy ansible.cfg
COPY ansible.cfg /root/

# Expose SSH port
EXPOSE 22

# Create a startup script
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'mkdir -p /var/run/sshd' >> /start.sh && \
    echo '/usr/sbin/sshd -D &' >> /start.sh && \
    echo 'echo "SSH server started on port 22"' >> /start.sh && \
    echo 'echo "Connect using: ssh root@localhost -p 2222"' >> /start.sh && \
    echo 'echo "Password:VMware1!VMware1!"' >> /start.sh && \
    echo 'echo ""' >> /start.sh && \
    echo 'echo "Repository cloned to /root/tonjiak"' >> /start.sh && \
    echo 'ls -la /root/tonjiak/' >> /start.sh && \
    echo export token=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  &&\
    echo  export git clone https://x-access-token:$token@github.com/thebrownteddybear1/tonjiak.git &&\
    echo 'tail -f /dev/null' >> /start.sh && \
    chmod +x /start.sh

ENTRYPOINT ["/start.sh"]
CMD [/bin/sh, -c , tail -f /dev/null]
#comments to myself
ENV comments="gh auth login \n\
…or create a new repository on the command line\n\
echo \"# tonjiak\" >> README.md \n\
\n\
\n\
git init \n\
git clone https://x-access-token:$TOKEN@github.com/thebrownteddybear1/tonjiak.git \n\
#this will create tonjiak dir \n\
just add everything, git add . or git add somefile or dir \n\
#git commit -m message\n\
#git push origin main \n\
\n\
\n\
\n\
git add README.md \n\
git commit -m \"first commit\" \n\
git branch -M main \n\
git remote add origin git@github.com:thebrownteddybear1/tonjiak.git \n\
git clone https://x-access-token:$TOKEN@github.com/thebrownteddybear1/tonjiak.git \n\
git push -u origin main \n\
TOKEN=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 \n\
echo tonjiak: This command prints the text string # tonjiak to the standard output. The hash symbol (#) in Markdown formatting means this text will render as a large heading. \n\
>> README.md: This is the redirection operator. It appends the output of the echo command to a file named README.md.\n\
Result: A new file named README.md is created (if it doesn't exist), and the line # tonjiak is written inside it. This provides initial content for the repository.\n\
2. git init\n\
git init: This command turns the current directory into a new Git repository.\n\
Result: Git creates a hidden .git subdirectory inside your current folder. This folder contains all the necessary files and data structures that Git needs to start tracking changes in your project.\n\
3. git add README.md\n\
git add README.md: This command stages the new README.md file.\n\
Result: The file is moved from the working directory to the staging area (or index). This area is a temporary holding space where you prepare changes before permanently recording them in the repository with a commit. Git is now aware of the file and ready to track it.\n\
4. git commit -m irst commit\n\
git commit: This command permanently records the staged changes into the repository's history.\n\
-m first commit: The -m flag stands for message. The text in quotes provides a descriptive message for the commit, explaining what changes were included.\n\
Result: A new, permanent snapshot (commit) of your project at this point in time is created in your local repository history.\n\
5. git branch -M main\n\
git branch: This command manages branches.\n\
-M main: This flag (short for --move --force) renames your current branch to main. Historically, the default branch name was master, but main is now the common convention, especially on GitHub.\n\
Result: Your active branch is renamed to main.\n\
6. git remote add origin git@github.com:thebrownteddybear1/tonjiak.git\n\
git remote add: This command adds a new remote connection (a link to another repository) to your local config.\n\
origin: This is the shorthand nickname given to the remote repository you are linking to. The name origin is a standard convention.\n\
git@github.com:...: This is the URL (using SSH protocol) of the specific GitHub repository you created online.\n\
Result: Your local repository now knows where the GitHub repository lives and can communicate with it.\n\
7. git push -u origin main\n\
git push: This command uploads your local commits to the remote repository (origin).\n\
-u: This flag (short for --set-upstream) is used here for the first push. It tells Git to link your local main branch to the remote origin/main branch. This means that subsequent pushes and pulls only require you to type simple commands like git push or git pull.\n\
origin main: Specifies exactly which remote (origin) and which local branch (main) you want to push.\n\
Result: Your local work is synchronized with the GitHub repository, making your code visible online.\n\
"
