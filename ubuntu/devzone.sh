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
apt-get install -y apt-transport-https ca-certificates software-properties-common vim zsh tree curl wget tar zip socat jq silversearcher-ag gnupg2
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
~/.fzf/install

# Step 4: Setup dotkube
cd ~
rm -rf ~/.kube
git clone git@github.com:indrayam/dotkube.git ~/.dotkube
ln -s ~/.dotkube .kube

# Step 5: Final touches...
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

## Install Nginx and Certbot
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
export HOSTNAME=$(hostname)
WEBROOT='/var/www/html'
apt-get install -y nginx certbot
mkdir -p /var/www/letsencrypt/.well-known/acme-challenge
chown ${USER_ID}.${USER_ID} $WEBROOT
cat > $WEBROOT/index.html << EOF
<html>
  <head>
    <title>VM Demo from ${HOSTNAME}</title>
  </head>
  <body>
    <h3>VM Demo from ${HOSTNAME}</h3>
  </body>
</html>
EOF
cat > /etc/nginx/tcppassthrough.conf << EOF
## tcp LB  and SSL passthrough for backend ##
stream {

    log_format combined '\$remote_addr - - [\$time_local] \$protocol \$status \$bytes_sent \$bytes_received \$session_time "\$upstream_addr"';

    access_log /var/log/nginx/stream-access.log combined;

    upstream httpenvoy {
        server 64.102.179.228:31143 max_fails=3 fail_timeout=10s;
        server 64.102.179.80:31143 max_fails=3 fail_timeout=10s;
        server 64.102.179.202:31143 max_fails=3 fail_timeout=10s;
        server 64.102.178.218:31143 max_fails=3 fail_timeout=10s;
        server 64.102.179.84:31143 max_fails=3 fail_timeout=10s;
    }

    upstream httpsenvoy {
        server 64.102.179.228:32224 max_fails=3 fail_timeout=10s;
        server 64.102.179.80:32224 max_fails=3 fail_timeout=10s;
        server 64.102.179.202:32224 max_fails=3 fail_timeout=10s;
        server 64.102.178.218:32224 max_fails=3 fail_timeout=10s;
        server 64.102.179.84:32224 max_fails=3 fail_timeout=10s;
    }

    server {
        listen 80;
        proxy_pass httpenvoy;
        proxy_next_upstream on;
    }

    server {
        listen 443;
        proxy_pass httpsenvoy;
        proxy_next_upstream on;
    }
}
EOF
chown ${USER_ID}.${USER_ID} $WEBROOT/index.html
systemctl start nginx

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
git clone https://github.com/udhos/update-golang
chown -R ${USER_ID}.${USER_ID} update-golang/
RELEASE=1.12 ./update-golang/update-golang.sh
RELEASE=1.12 sudo ./update-golang.sh
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

# Install Java
apt-get -y install default-jdk
ln -s /usr/lib/jvm/java-8-openjdk-amd64 /usr/local/java

# Install Hugo
cd ${USER_HOME}/src
version=0.54.0
wget https://github.com/gohugoio/hugo/releases/download/v"$version"/hugo_"$version"_Linux-64bit.tar.gz -O hugo.tar.gz
tar -xvf hugo.tar.gz
rm README.md LICENSE hugo.tar.gz
install hugo /usr/local/bin/hugo
rm hugo
hugo version

# Update /etc/hosts with the proper entry
export HOST=$(hostname)
export CTRLPLANE_IP=$(hostname -I | awk '{print $1}')
sed -i "1s/^/${CTRLPLANE_IP} ${HOST}\n/" /etc/hosts
