# Setup OpenStack Cluster Details (RTP Cluster)
NETWORK_ID="net-id=a8bddbc7-8a84-4bf1-b8ba-008909ebc123"
SSH_KEY="anand on macbook"
#FLAVOR_NAME="2vCPUx4GB"
IMAGE_NAME="CoDE-xenial-server-cloudimg-amd64-disk1"

export OS_AUTH_URL="https://cloud-rcdn-1.cisco.com:5000/v3"
export OS_IDENTITY_API_VERSION=3
export OS_PROJECT_NAME="${4:-CD-Services-STAGE}"
export OS_PROJECT_DOMAIN_NAME="cisco"
export OS_USERNAME="anasharm"
export OS_USER_DOMAIN_NAME="cisco"

echo "Using the following OpenStack settings..."
echo "OS_AUTH_URL=${OS_AUTH_URL}"
echo "OS_PROJECT_NAME=${OS_PROJECT_NAME}"
