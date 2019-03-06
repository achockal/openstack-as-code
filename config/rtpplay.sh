# Setup OpenStack Cluster Details (RTP Cluster)
NETWORK_ID="net-id=956aab19-97a2-4949-b79d-2a7bd6733ea9"
SSH_KEY="anand on macbook"
FLAVOR_NAME="2vCPUx4GB"
IMAGE_NAME="CoDE-xenial-server-cloudimg-amd64-disk1"

export OS_AUTH_URL="https://cloud-rtp-1.cisco.com:5000/v3"
export OS_IDENTITY_API_VERSION=3
export OS_PROJECT_NAME="${4:-CoDE-Playground}"
export OS_PROJECT_DOMAIN_NAME="cisco"
export OS_USERNAME="anasharm"
export OS_USER_DOMAIN_NAME="cisco"

echo "Using the following OpenStack settings..."
echo "OS_AUTH_URL=${OS_AUTH_URL}"
echo "OS_PROJECT_NAME=${OS_PROJECT_NAME}"
