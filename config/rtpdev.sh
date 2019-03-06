# Setup OpenStack Cluster Details (RTP Cluster)
NETWORK_ID="net-id=cbf11caf-b07c-4d87-a850-4ed2e26f10be"
SSH_KEY="anand on macbook"
FLAVOR_NAME="2vCPUx4GB"
IMAGE_NAME="CoDE-xenial-server-cloudimg-amd64-disk1"

export OS_AUTH_URL="https://cloud-rtp-1.cisco.com:5000/v3"
export OS_IDENTITY_API_VERSION=3
export OS_PROJECT_NAME="${4:-CD-Services-STAGE}"
export OS_PROJECT_DOMAIN_NAME="cisco"
export OS_USERNAME="anasharm"
export OS_USER_DOMAIN_NAME="cisco"
