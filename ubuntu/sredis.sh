#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

USER_ID="${USER_ID:-ubuntu}"
USER_HOME="/home/${USER_ID}"

## Pre-requisite steps
# Get things setup for Vim and Certbot
add-apt-repository -y ppa:jonathonf/vim
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
apt-get update

# Install Essentials
apt-get install -y apt-transport-https ca-certificates software-properties-common vim zsh tree curl wget tar zip socat jq silversearcher-ag
chown -R ${USER_ID}.${USER_ID} /usr/local/src
ln -s /usr/local/src ${USER_HOME}/src
chown -h ${USER_ID}.${USER_ID} ${USER_HOME}/src

# Create a shell script to finish personalizing my non-root account setup
cat > ${USER_HOME}/complete-os-setup.sh <<EOF
cd ~/src

# Step 1: Install oh-my-zsh
sudo chsh -s /usr/bin/zsh ${USER_ID}
wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh
sed -i.tmp 's:env zsh::g' install.sh
sed -i.tmp 's:chsh -s .*$::g' install.sh
sh install.sh
rm install.sh*

# Step 2: Setup SSH keys and pull down my .dotfiles repo
cd ~/src
curl -L https://storage.googleapis.com/us-east-4-anand-files/misc-files/linux-bootstrap.tar.gz.enc -H 'Accept: application/octet-stream' --output linux-bootstrap.tar.gz.enc
openssl aes-256-cbc -d -in linux-bootstrap.tar.gz.enc -out linux-bootstrap.tar.gz
tar -xvzf linux-bootstrap.tar.gz
mv ssh/* ~/.ssh/
mv config ~/.config
mkdir -p ~/.kube
mv kube/* ~/.kube/
chmod 700 ~/.ssh/
rm -rf ssh/ ssh.tar.gz
ssh -o "StrictHostKeyChecking no" -T git@github.com

# Step 3: Setup Vim
cd ~
git clone git@github.com:indrayam/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
~/.dotfiles/setup-symlinks-ubuntu.sh
rm -rf ~/.vim/bundle/Vundle.vim
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim -c 'PluginInstall' -c 'qall'
~/.fzf/install --all

# Step 4: Final touches...
mkdir -p ${USER_HOME}/workspace
echo "You're done! Remove this file, exit and log back in to enjoy your new VM"
EOF
chmod +x ${USER_HOME}/complete-os-setup.sh
chown ${USER_ID}.${USER_ID} ${USER_HOME}/complete-os-setup.sh

## Get in position
cd ${USER_HOME}/src

## Download binaries and/or source
wget -q --https-only --timestamping \
  https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy
chown ${USER_ID}.${USER_ID} ${USER_HOME}/src/*

## Install diff-so-fancy
cd ${USER_HOME}/src
chmod +x diff-so-fancy
mv diff-so-fancy /usr/local/bin
diff-so-fancy -v

# Install Docker and Kubernetes
apt-get install -y --allow-unauthenticated docker-ce=$(apt-cache madison docker-ce | grep 17.03 | head -1 | awk '{print $3}')
apt-get install -y kubectl
sudo usermod -a -G docker ubuntu

# Install Go
# sudo add-apt-repository -y ppa:longsleep/golang-backports
# sudo apt-get -y update
# sudo apt-get install -y golang-go
# mkdir -p ${USER_HOME}/workspace/go-apps
## OR 
cd ${USER_HOME}/src
git clone https://github.com/udhos/update-golang
chown -R ${USER_ID}.${USER_ID} update-golang/
RELEASE=1.11 ./update-golang/update-golang.sh
mkdir -p ${USER_HOME}/workspace/go-apps

# Install cfssl and cfssljson
GOPATH="${USER_HOME}/workspace/go-apps"
go get -u github.com/cloudflare/cfssl/cmd/cfssl
go get -u github.com/cloudflare/cfssl/cmd/cfssljson
chown -R ${USER_ID}:${USER_ID} ${USER_HOME}/workspace

# nfs-client (or, nfs-server)
sudo apt-get install -y nfs-common

# Install Kubernetes Power Tools
cd ${USER_HOME}/src
git clone https://github.com/jonmosco/kube-ps1.git ${USER_HOME}/.kube-ps1
git clone --depth 1 https://github.com/junegunn/fzf.git ${USER_HOME}/.fzf
chown -R ${USER_ID}:${USER_ID} ${USER_HOME}/.kube-ps1
chown -R ${USER_ID}:${USER_ID} ${USER_HOME}/.fzf
git clone https://github.com/ahmetb/kubectx /opt/kubectx
curl -L -O https://github.com/wercker/stern/releases/download/1.10.0/stern_linux_amd64
curl -L -O https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz
curl -O -L https://github.com/sharkdp/bat/releases/download/v0.9.0/bat_0.9.0_amd64.deb
rm -f /usr/local/bin/kubectx /usr/local/bin/kubens /usr/local/bin/stern /usr/local/bin/oc
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
chmod +x stern_linux_amd64
sudo mv stern_linux_amd64 /usr/local/bin/stern
tar -xvzf openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz
sudo mv openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit /opt/openshift/
sudo ln -s /opt/openshift/oc /usr/local/bin/oc
sudo apt-get -y install ${USER_HOME}/src/bat_0.9.0_amd64.deb
chown -R ${USER_ID}:${USER_ID} ${USER_HOME}/src

# Setup the Zsh autocompletions
mv /opt/kubectx/completion/kubectx.zsh /usr/local/share/zsh/site-functions/_kubectx
chmod +x /usr/local/share/zsh/site-functions/_kubectx
mv /opt/kubectx/completion/kubens.zsh /usr/local/share/zsh/site-functions/_kubens
chmod +x /usr/local/share/zsh/site-functions/_kubens

# Setup Redis Server
MASTER_IP=192.168.1.10
MASTER_PORT=6382
REDIS_SLAVE_PORT=16382

sudo apt-get install -y build-essential tcl 
cd ${USER_HOME}/src
curl -L -O http://download.redis.io/releases/redis-4.0.11.tar.gz
tar -xvzf redis-4.0.11.tar.gz
cd redis-4.0.11
make
make test
make install
mkdir -p /etc/redis
mkdir -p /var/lib/redis
mkdir -p /var/log/redis
cp redis.conf /etc/redis
cd /etc/redis
sed -i 's/^bind/#bind/g' redis.conf
sed -i 's/^supervised no/supervised systemd/g' redis.conf
sed -i 's/^dir \.\//dir \/var\/lib\/redis/g' redis.conf
sed -i 's/^# requirepass.*/requirepass c1der1cks!/g' redis.conf
sed -i 's/^appendonly no/appendonly yes/g' redis.conf
sed -i "s/^appendfilename.*/appendfilename redis-slave-ao.aof/g" redis.conf
sed -i "s/^# slaveof.*/slaveof ${MASTER_IP} ${MASTER_PORT}/g" redis.conf
sed -i "s/^# masterauth.*/masterauth c0der0cks!/g" redis.conf
sed -i "s/^port.*/port $REDIS_SLAVE_PORT/g" redis.conf
sed -i "s/^logfile.*/logfile \"\/var\/log\/redis\/redis_$REDIS_SLAVE_PORT.log\"/g" redis.conf
adduser --system --group --no-create-home redis
chown redis:redis /etc/redis
chown redis:redis /var/lib/redis
chown redis:redis /var/log/redis
chmod 770 /var/lib/redis
chmod 770 /var/log/redis

# Fix Maximum Open Files Warning:
# You requested maxclients of 10000 requiring at least 10032 max file descriptors.
# Redis can't set maximum open files to 10032 because of OS error: Operation not permitted.
# Current maximum open files is 4096.

# Fix it the systemd way by adding LimitNOFILE entry under "Service"

cat > /etc/systemd/system/redis.service << EOF
[Unit]
Description=Redis In-Memory Data Store
After=network.target

[Service]
User=redis
Group=redis
LimitNOFILE=65536
Type=notify
ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf
ExecStop=/usr/local/bin/redis-cli shutdown
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Fix Socket Maximum Connection Warning:
# The TCP backlog setting of 511 cannot be enforced because /proc/sys/net/core/somaxconn is set to the lower value of 128.

# Fix Memory Overcommit Warning:
# overcommit_memory is set to 0! Background save may fail under low memory condition. 
# To fix this issue add 'vm.overcommit_memory = 1' to /etc/sysctl.conf and then reboot or 
# run the command 'sysctl vm.overcommit_memory=1' for this to take effect.
cat >> /etc/sysctl.conf << EOF
vm.overcommit_memory = 1
net.core.somaxconn=1024
EOF

sudo sysctl -p

# Fix Transparent Huge Pages Warning:
# Disable Transparent Huge Pages feature of Linux Kernel (This works in older Linux OS)
cat > /etc/rc.local << EOF
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
    echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
   echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi
exit 0
EOF

# Disable Transparent Huge Pages feature of Linux Kernel
cat > /etc/systemd/system/disable-thp.service << EOF
[Unit]
Description=Disable Transparent Huge Pages (THP)

[Service]
Type=simple
ExecStart=/bin/sh -c "echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled && echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag"

[Install]
WantedBy=multi-user.target
EOF

cd /etc/systemd/system

systemctl start disable-thp
systemctl enable disable-thp.service

systemctl start redis.service
systemctl enable redis.service


# Update /etc/hosts with the proper entry
export HOST=$(hostname)
export CTRLPLANE_IP=$(hostname -I | awk '{print $1}')
sed -i "1s/^/${CTRLPLANE_IP} ${HOST}\n/" /etc/hosts



