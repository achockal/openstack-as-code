#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

USER_ID="${USER_ID:-ubuntu}"
USER_HOME="/home/${USER_ID}"

## Pre-requisite steps
# Get things setup for Vim and Certbot
add-apt-repository -y ppa:jonathonf/vim
add-apt-repository -y ppa:certbot/certbot
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

## Install Nginx
cd ${USER_HOME}/src
wget https://nginx.org/keys/nginx_signing.key
apt-key add nginx_signing.key
cat > /etc/apt/sources.list.d/nginx.list <<EOF
#Add the following lines to nginx.list:
deb https://nginx.org/packages/mainline/ubuntu/ xenial nginx
deb-src https://nginx.org/packages/mainline/ubuntu/ xenial nginx
EOF
sudo apt-get remove -y nginx
sudo apt-get update
sudo apt-get install -y nginx

# Configure Nginx as TCP Proxy for all Redis Instance(s)
# Build tcpassthrough.conf file header
cat > /etc/nginx/tcppassthrough.conf << EOF
## tcp LB  and SSL passthrough for backend ##
stream {

    log_format combined '\$remote_addr - - [\$time_local] \$protocol \$status \$bytes_sent \$bytes_received \$session_time "\$upstream_addr"';

    access_log /var/log/nginx/stream-access.log combined;

EOF

# Setup TCP Proxy configuration file /etc/nginx/tcppassthrough.conf
ORCA_IP=192.168.1.5
CLOUDDRIVER_IP=192.168.1.10
OTHERS_IP=192.168.1.26

declare -A ip=(  ["orca"]="$ORCA_IP" ["clouddriver"]="$CLOUDDRIVER_IP" ["others"]="$OTHERS_IP" )

# Beware. Hard-coded values. Make sure it syncs with the values in setup-stage.sh file
# declare -A port=( ["gate"]="6379" ["fiat"]="6380" ["orca"]="6381" ["clouddriver"]="6382" ["igor"]="6383" ["rosca"]="6384" ["kayenta"]="6385" )
declare -A port=( ["orca"]="6381" ["clouddriver"]="6382" ["others"]="6380" )

for ms in orca clouddriver others
do
    # Incrementally build tcpassthrough.conf file for each redis instance
    cat >> /etc/nginx/tcppassthrough.conf << EOF
    upstream $ms-${port[$ms]} {
        server ${ip[$ms]}:${port[$ms]} max_fails=3 fail_timeout=10s;
    }

    server {
        listen ${port[$ms]};
        proxy_pass $ms-${port[$ms]};
        proxy_next_upstream on;
    }

EOF

done

# End the tcppassthrough.conf file
cat >> /etc/nginx/tcppassthrough.conf << EOF
}
EOF

echo "Completed setting up of /etc/nginx/tcppassthrough.conf..."

# Configure nginx.conf to use tcppassthrough.conf
cat > /etc/nginx/nginx.conf << EOF
user  nginx;
worker_processes  1;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    #include /etc/nginx/conf.d/*.conf;
}

include /etc/nginx/tcppassthrough.conf;
EOF

echo "Completed setting up of /etc/nginx/nginx.conf..."

# (Re)start Nginx
nginx -t
systemctl stop nginx
systemctl start nginx

# Install Docker and Kubernetes
apt-get install -y --allow-unauthenticated docker-ce=$(apt-cache madison docker-ce | grep 17.03 | head -1 | awk '{print $3}')
apt-get install -y kubectl
sudo usermod -a -G docker ubuntu

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

# Update /etc/hosts with the proper entry
export HOST=$(hostname)
export CTRLPLANE_IP=$(hostname -I | awk '{print $1}')
sed -i "1s/^/${CTRLPLANE_IP} ${HOST}\n/" /etc/hosts

# Flush IPv4 and IPv6 rules
# cat > ${USER_HOME}/src/clear-all-rules << EOF
# # Empty the entire filter table
# *filter
# :INPUT ACCEPT [0:0]
# :FORWARD ACCEPT [0:0]
# :OUTPUT ACCEPT [0:0]
# COMMIT
# EOF
# iptables-save > ${USER_HOME}/src/firewall-rules-ipv4.txt
# ip6tables-save > ${USER_HOME}/src/firewall-rules-ipv6.txt
# iptables-restore < ${USER_HOME}/src/clear-all-rules
# ip6tables-restore < ${USER_HOME}/src/clear-all-rules
# chown -R ${USER_ID}:${USER_ID} ${USER_HOME}/src
