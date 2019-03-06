# OpenStack as Code

## What's inside this repo?

**ubuntu**
This folder contains scripts to spin up virtual machines of specific types

**config**
This folder contains OpenStack environment variables to be sourced based on the cluster we need to connect to

**utils**
Utility scripts for one-off tasks

## Before you begin...

Before you run any scripts documented in this repo, spend some time setting up your laptop with the tools and shortcuts (aliases) listed below

**Setup your .zshrc shell**

Add the following into your `.zshrc` file:

```bash
alias o='openstack'

# Cisco CEC Login. Openstack client will use your CEC password to connect and you do not want to enter it again and again
source ~/.cec
```

Here's the contents of `~/.cec` file:

```bash
export OS_PASSWORD=''
```

Finally, before you run any `openstack` (or `o`) commands, you will need to source the files related to the OpenStack cluster. Assuming you clone this repo in `~/workspace/openstack-as-code` folder, run the following commands to setup softlinks in your home folder:

```bash
ln -s ~/workspace/openstack-as-code/config/allnstg.sh ~/allnstg
ln -s ~/workspace/openstack-as-code/config/allnprd.sh ~/allnprd
ln -s ~/workspace/openstack-as-code/config/rtpplay.sh ~/rtpplay
ln -s ~/workspace/openstack-as-code/config/rcdnplay.sh ~/rcdnplay
ln -s ~/workspace/openstack-as-code/config/rtpstg.sh ~/rtpstg
ln -s ~/workspace/openstack-as-code/config/rtpprd.sh ~/rtpprd
ln -s ~/workspace/openstack-as-code/config/rcdnstg.sh ~/rcdnstg
ln -s ~/workspace/openstack-as-code/config/rcdnprd.sh ~/rcdnprd
```


### CLI Tools

1. You have Python 2.7+ installed on your machine. OpenStack clients do not support Python 3. Ugh.

```bash
(prompt)>python2 -V
Python 2.7.15
(prompt)>pip2 -V
pip 10.0.1 from /usr/local/lib/python2.7/site-packages/pip (python 2.7)
```
2. You have openstack-cli installed on your machine: 

```bash
pip2 install python-openstackclient
```

3. Make sure the installation was successful

```bash
pip2 list | grep -i python-openstackclient
```

4. Set OpenStack environment variables for your respective OpenStack Cluster/Project. Create 3 text files named `rcdnstg`, `rcdnprd`, `allnstg`, `allprd`, `rtpstg` and `rtpprd` in `$HOME/bin` directory.  

`~/rcdnstg`:

```bash
# Set your terminal to point to RCDN Stage

export OS_AUTH_URL="https://cloud-rcdn-1.cisco.com:5000/v3"
export OS_IDENTITY_API_VERSION=3
export OS_PROJECT_NAME="Spinnaker-Stateful-Services-STAGE"
export OS_PROJECT_DOMAIN_NAME="cisco"
export OS_USERNAME="<enter-CEC-userid>"
export OS_USER_DOMAIN_NAME="cisco"
export OS_PASSWORD='<enter-CEC-password>'

echo "Using the following OpenStack settings..."
echo "OS_AUTH_URL=${OS_AUTH_URL}"
echo "OS_PROJECT_NAME=${OS_PROJECT_NAME}"
```

`~/rcdnprd`:

```bash
# Set your terminal to point to RCDN Prod

export OS_AUTH_URL="https://cloud-rcdn-1.cisco.com:5000/v3"
export OS_IDENTITY_API_VERSION=3
export OS_PROJECT_NAME="Spinnaker-Stateful-Services"
export OS_PROJECT_DOMAIN_NAME="cisco"
export OS_USERNAME="<enter-CEC-userid>"
export OS_USER_DOMAIN_NAME="cisco"
export OS_PASSWORD='<enter-CEC-password>'

echo "Using the following OpenStack settings..."
echo "OS_AUTH_URL=${OS_AUTH_URL}"
echo "OS_PROJECT_NAME=${OS_PROJECT_NAME}"
```

`~/allnstg`:

```bash
# Set your terminal to point to ALLN Stage

export OS_AUTH_URL="https://cloud-alln-1.cisco.com:5000/v3"
export OS_IDENTITY_API_VERSION=3
export OS_PROJECT_NAME="Spinnaker-Stateful-Services-STAGE"
export OS_PROJECT_DOMAIN_NAME="cisco"
export OS_USERNAME="<enter-CEC-userid>"
export OS_USER_DOMAIN_NAME="cisco"
export OS_PASSWORD='<enter-CEC-password>'

echo "Using the following OpenStack settings..."
echo "OS_AUTH_URL=${OS_AUTH_URL}"
echo "OS_PROJECT_NAME=${OS_PROJECT_NAME}"
```

`~/allnprd`:

```bash
# Set your terminal to point to ALLN Prod

export OS_AUTH_URL="https://cloud-alln-1.cisco.com:5000/v3"
export OS_IDENTITY_API_VERSION=3
export OS_PROJECT_NAME="Spinnaker-Stateful-Services"
export OS_PROJECT_DOMAIN_NAME="cisco"
export OS_USERNAME="<enter-CEC-userid>"
export OS_USER_DOMAIN_NAME="cisco"
export OS_PASSWORD='<enter-CEC-password>'

echo "Using the following OpenStack settings..."
echo "OS_AUTH_URL=${OS_AUTH_URL}"
echo "OS_PROJECT_NAME=${OS_PROJECT_NAME}"
```

`~/rtpstg`:

```bash
# Set your terminal to point to RTP Stage

export OS_AUTH_URL="https://cloud-rtp-1.cisco.com:5000/v3"
export OS_IDENTITY_API_VERSION=3
export OS_PROJECT_NAME="Spinnaker-Stateful-Services-STAGE"
export OS_PROJECT_DOMAIN_NAME="cisco"
export OS_USERNAME="<enter-CEC-userid>"
export OS_USER_DOMAIN_NAME="cisco"
export OS_PASSWORD='<enter-CEC-password>'

echo "Using the following OpenStack settings..."
echo "OS_AUTH_URL=${OS_AUTH_URL}"
echo "OS_PROJECT_NAME=${OS_PROJECT_NAME}"
```

`~/rtpprd`:

```bash
# Set your terminal to point to RTP Prod

export OS_AUTH_URL="https://cloud-rtp-1.cisco.com:5000/v3"
export OS_IDENTITY_API_VERSION=3
export OS_PROJECT_NAME="Spinnaker-Stateful-Services"
export OS_PROJECT_DOMAIN_NAME="cisco"
export OS_USERNAME="<enter-CEC-userid>"
export OS_USER_DOMAIN_NAME="cisco"
export OS_PASSWORD='<enter-CEC-password>'

echo "Using the following OpenStack settings..."
echo "OS_AUTH_URL=${OS_AUTH_URL}"
echo "OS_PROJECT_NAME=${OS_PROJECT_NAME}"
```

5. Before running any OpenStack command, run the following to select the appropriate OpenStack cluster to run your commands against:

```bash
source ~/bin/rtpstg
# OR source ~/bin/rtpprd
# ...
```

6. Test the connection:

```bash
o server list
o image list
o flavor list
```

## Getting an OpenStack Project Ready!

If you are starting with a brand new OpenStack project, in order to run these scripts against that project, the following steps must be completed

### Create custom Ubuntu 16.04 server image

All OpenStack VMs instantiated will use custom image titled `CoDE-xenial-server-cloudimg-amd64-disk1`. Here's how to create the custom image and upload it to the OpenStack project

- Get the image from [OpenStack Documentation: Get Images](https://docs.openstack.org/image-guide/obtain-images.html) page. Go to the Ubuntu section for the link. The most recent version of the 64-bit QCOW2 image for Ubuntu 16.04 is [xenial-server-cloudimg-amd64-disk1.img](http://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img)

- Download `qemu-image` software on your laptop. Use [Convert Images](https://docs.openstack.org/image-guide/convert-images.html) section as reference.

```bash
qemu-img convert ./xenial-server-cloudimg-amd64-disk1.img ./xenial-server-cloudimg-amd64-disk1.raw
o image create --private --file xenial-server-cloudimg-amd64-disk1.raw --disk-format raw "CoDE-xenial-server-cloudimg-amd64-disk1"
```

### Key Pairs

Make sure you have the SSH key-pair defined and uploaded into the project. You will be refering to this key-pair during invocation of `openstack create` commands

### Security Groups

Make sure you have the necessary Rules defined, preferably as a new Security Group, that allows TCP traffic that you want your VMs to permit

### Network

Make sure you create a new Network with appropriate Subnet using private IP address namespace (for example: 192.168.1.0/24). Once the Network is created, you will need to create a Router and add an Interface to this router that permits external traffic to come to VMs attched to this new network
