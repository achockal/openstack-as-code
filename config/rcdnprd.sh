# Setup OpenStack Cluster Details (RTP Cluster)
NETWORK_ID="net-id=5e68d4a7-dddf-4687-b5d3-64cad7465810"
SSH_KEY="anand on macbook"
#FLAVOR_NAME="2vCPUx4GB"
IMAGE_NAME="CoDE-xenial-server-cloudimg-amd64-disk1"

export OS_AUTH_URL="https://cloud-rcdn-1.cisco.com:5000/v3"
export OS_IDENTITY_API_VERSION=3
export OS_PROJECT_NAME="${4:-CD-Services}"
export OS_PROJECT_DOMAIN_NAME="cisco"
export OS_USERNAME="anasharm"
export OS_USER_DOMAIN_NAME="cisco"
