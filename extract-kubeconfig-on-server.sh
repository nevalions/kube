#!/bin/bash
# Run this script ON kuberspb to extract kubeconfig data
# Then copy the output back to your local machine

echo "=== Kubernetes Configuration Data for Local Machine ==="
echo ""
echo "Copy the following block and run it on your local machine:"
echo ""

# Extract certificate-authority-data
CA_DATA=$(cat /etc/kubernetes/admin.conf 2>/dev/null | grep "certificate-authority-data:" | awk '{print $2}')

# Extract client-certificate-data
CLIENT_CERT_DATA=$(cat /etc/kubernetes/admin.conf 2>/dev/null | grep "client-certificate-data:" | awk '{print $2}')

# Extract client-key-data
CLIENT_KEY_DATA=$(cat /etc/kubernetes/admin.conf 2>/dev/null | grep "client-key-data:" | awk '{print $2}')

# Get cluster server address
CLUSTER_SERVER=$(cat /etc/kubernetes/admin.conf 2>/dev/null | grep "server:" | awk '{print $2}')

# Get cluster name
CLUSTER_NAME=$(cat /etc/kubernetes/admin.conf 2>/dev/null | grep -A1 "clusters:" | grep "name:" | head -1 | awk '{print $2}')

# Get user name
USER_NAME=$(cat /etc/kubernetes/admin.conf 2>/dev/null | grep -A1 "users:" | grep "name:" | head -1 | awk '{print $2}')

# Output the complete kubeconfig
cat <<EOF
# Run this on your local machine:
mkdir -p ~/.kube
cat > ~/.kube/config <<'KUBECONFIG_EOF'
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
KUBECONFIG_EOF

echo "Configuration complete! Start the SSH tunnel with:"
echo "  systemctl --user start k8s-tunnel"
echo ""
echo "Then test with:"
echo "  kubectl get nodes"
EOF
