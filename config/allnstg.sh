# Setup OpenStack Cluster Details (ALLN Cluster)
NETWORK_ID="net-id=7a946896-0c9b-47b4-ae6e-2f02182ac3b4"
SSH_KEY="anand on macbook"
#FLAVOR_NAME="2vCPUx4GB"
IMAGE_NAME="CoDE-xenial-server-cloudimg-amd64-disk1"

export OS_AUTH_URL="https://cloud-alln-1.cisco.com:5000/v3"
export OS_IDENTITY_API_VERSION=3
export OS_PROJECT_NAME="${4:-CD-Services-STAGE}"
export OS_PROJECT_DOMAIN_NAME="cisco"
export OS_USERNAME="anasharm"
export OS_USER_DOMAIN_NAME="cisco"
