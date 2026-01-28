#!/bin/bash
# Script to extract Kubernetes configuration data from remote server
# Run this script to extract certificate data from kuberspb
# NOTE: Do NOT run with sudo - it will fail to find SSH config

# Check if running with sudo
if [ "$EUID" -eq 0 ]; then
    echo "ERROR: Do NOT run this script with sudo."
    echo "This script uses your personal SSH config from ~/.ssh/config."
    echo "The remote commands will prompt for sudo password on kuberspb."
    exit 1
fi

echo "Extracting Kubernetes configuration data from kuberspb..."
echo "Note: This requires passwordless sudo on kuberspb, or manual setup."
echo "For manual setup, see MANUAL_SETUP.md"
echo ""

# Extract certificate-authority-data
CA_DATA=$(ssh kuberspb "sudo cat /etc/kubernetes/admin.conf" | grep "certificate-authority-data:" | awk '{print $2}')

# Extract client-certificate-data
CLIENT_CERT_DATA=$(ssh kuberspb "sudo cat /etc/kubernetes/admin.conf" | grep "client-certificate-data:" | awk '{print $2}')

# Extract client-key-data
CLIENT_KEY_DATA=$(ssh kuberspb "sudo cat /etc/kubernetes/admin.conf" | grep "client-key-data:" | awk '{print $2}')

# Get the cluster server address
CLUSTER_SERVER=$(ssh kuberspb "sudo cat /etc/kubernetes/admin.conf" | grep "server:" | awk '{print $2}')

# Get cluster name
CLUSTER_NAME=$(ssh kuberspb "sudo cat /etc/kubernetes/admin.conf" | grep -A1 "clusters:" | grep "name:" | awk '{print $2}')

# Get user name
USER_NAME=$(ssh kuberspb "sudo cat /etc/kubernetes/admin.conf" | grep -A1 "users:" | grep "name:" | awk '{print $2}')

# Check if extraction succeeded
if [ -z "$CA_DATA" ] || [ -z "$CLUSTER_SERVER" ]; then
    echo ""
    echo "ERROR: Failed to extract configuration data."
    echo ""
    echo "This usually happens because sudo requires a password."
    echo "SSH scripts can't prompt for interactive sudo passwords."
    echo ""
    echo "For manual setup, follow these steps:"
    echo ""
    echo "1. SSH to kuberspb:"
    echo "   ssh kuberspb"
    echo ""
    echo "2. Copy the admin.conf:"
    echo "   sudo cat /etc/kubernetes/admin.conf"
    echo ""
    echo "3. See MANUAL_SETUP.md for detailed instructions"
    exit 1
fi

echo "Configuration data extracted successfully!"
echo ""
echo "Cluster Server: $CLUSTER_SERVER"
echo "Cluster Name: $CLUSTER_NAME"
echo "User Name: $USER_NAME"
echo ""

# Create local kubeconfig
mkdir -p ~/.kube
cat > ~/.kube/config <<EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: $CA_DATA
    server: $CLUSTER_SERVER
    proxy-url: socks5://localhost:1080
  name: kuberspb
contexts:
- context:
    cluster: kuberspb
    user: $USER_NAME
  name: kuberspb
current-context: kuberspb
kind: Config
preferences: {}
users:
- name: $USER_NAME
  user:
    client-certificate-data: $CLIENT_CERT_DATA
    client-key-data: $CLIENT_KEY_DATA
EOF

echo "Local kubeconfig created at ~/.kube/config"
echo ""
echo "Configuration complete! Start the SSH tunnel with:"
echo "  systemctl --user start k8s-tunnel"
echo ""
echo "Then test with:"
echo "  kubectl get nodes"
