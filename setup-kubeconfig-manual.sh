#!/bin/bash
# Manual setup script for local kubeconfig
# Use this when you've manually extracted kubeconfig data from kuberspb

echo "=== Kubernetes Configuration Setup ==="
echo ""
echo "This script will help you create local kubeconfig manually."
echo ""
echo "You need to run this on kuberspb first:"
echo "  ssh kuberspb"
echo "  sudo bash /path/to/extract-kubeconfig-on-server.sh"
echo ""
echo "Then copy the output back to this machine."
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."

# Prompt for required data
read -p "Enter cluster server address (e.g., https://192.168.10.11:6443): " CLUSTER_SERVER
read -p "Enter certificate-authority-data (base64): " CA_DATA
read -p "Enter client-certificate-data (base64): " CLIENT_CERT_DATA
read -p "Enter client-key-data (base64): " CLIENT_KEY_DATA

# Use default names
CLUSTER_NAME="kuberspb"
USER_NAME="kubernetes-admin"

# Create kubeconfig
mkdir -p ~/.kube
cat > ~/.kube/config <<EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: $CA_DATA
    server: $CLUSTER_SERVER
    proxy-url: socks5://localhost:1080
  name: $CLUSTER_NAME
contexts:
- context:
    cluster: $CLUSTER_NAME
    user: $USER_NAME
  name: $CLUSTER_NAME
current-context: $CLUSTER_NAME
kind: Config
preferences: {}
users:
- name: $USER_NAME
  user:
    client-certificate-data: $CLIENT_CERT_DATA
    client-key-data: $CLIENT_KEY_DATA
EOF

echo ""
echo "Local kubeconfig created at ~/.kube/config"
echo ""
echo "Next steps:"
echo "1. Start SSH tunnel:"
echo "   systemctl --user start k8s-tunnel"
echo ""
echo "2. Enable auto-start:"
echo "   systemctl --user enable k8s-tunnel"
echo ""
echo "3. Test connection:"
echo "   kubectl get nodes"
