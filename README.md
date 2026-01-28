# Kubernetes Cluster Configuration

This repository contains Kubernetes manifests and configuration files for managing bare-metal clusters with kubeadm, Calico CNI, and BGP networking.

**⚠️ Security Notice:** This is a public repository. See `SECURITY.md` for information about exposed infrastructure details and best practices.

## Overview

This configuration supports:
- **Kubeadm-based cluster installation** on bare-metal servers
- **Calico CNI** with BGP networking for multi-site connectivity
- **MetalLB** for LoadBalancer services
- **SSH SOCKS5 proxy** for secure remote cluster access

## Quick Start

### Remote Cluster Access Setup

To access Kubernetes cluster from your local machine:

**Option A: Automated Setup (requires passwordless sudo on kuberspb)**

```bash
# 1. Run setup script to extract kubeconfig
cd /home/linroot/code/kube
./setup-k8s-tunnel.sh
# Note: Requires sudo on kuberspb without password prompt

# 2. Start SSH tunnel
~/bin/k8s-tunnel-start

# 3. Enable auto-start on boot
systemctl --user enable k8s-tunnel.service

# 4. Verify connection
kubectl get nodes
```

**Option B: Manual Setup (recommended)**

Follow the manual setup process in `MANUAL_SETUP.md`:

```bash
# 1. SSH to kuberspb and view admin.conf
ssh kuberspb
sudo cat /etc/kubernetes/admin.conf

# 2. Copy certificate data to local machine (see MANUAL_SETUP.md)

# 3. Start tunnel
systemctl --user start k8s-tunnel.service

# 4. Verify connection
kubectl get nodes
```

See `MANUAL_SETUP.md` for detailed step-by-step instructions.

### Cluster Installation

The `kube-install.sh` script contains installation instructions for both control plane and worker nodes. **Do not run this script directly** - it's a reference document.

Manual installation steps for control plane:

```bash
# 1. Install dependencies (kubelet, kubeadm, kubectl, containerd)
# See kube-install.sh lines 4-15

# 2. Configure kernel modules and networking
# See kube-install.sh lines 20-31

# 3. Configure containerd with systemd cgroup driver
# See kube-install.sh lines 38-41

# 4. Initialize cluster
sudo kubeadm init --config=kubeadm-config.yaml

# 5. Install Calico CNI
kubectl apply -f calico/1-tigera-operator.yaml
kubectl apply -f calico/2-custom-resources.yaml

# 6. Install MetalLB (for LoadBalancer services)
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml
kubectl apply -f 5-ipaddresspool.yaml
```

## Directory Structure

```
.
├── calico/                    # Calico CNI configurations
│   ├── 1-tigera-operator.yaml
│   └── 2-custom-resources.yaml
├── cloud/                     # Cloud-specific configurations
│   ├── 1-kubeadm-cloud-config.yaml
│   ├── 2-calico-cloud-bgp-config.yaml
│   ├── 3-calico-cloud-bgp-peer.yaml
│   └── 4-ipaddresspool.yaml
├── kube-install.sh            # Installation reference script
├── setup-k8s-tunnel.sh       # Automated setup script (needs passwordless sudo)
├── setup-kubeconfig-manual.sh  # Manual setup helper
├── extract-kubeconfig-on-server.sh  # Script to run on remote server
├── MANUAL_SETUP.md            # Manual setup instructions
├── kubeadm-config.yaml       # Default kubeadm configuration
├── kubeadm-bay-config.yaml   # Bay location configuration
├── kubeadm-sans-bay-config.yaml
├── kubeadm-cert-update.yaml
├── kube-join.yaml             # Worker join configuration
├── 3-calico-bay-bgp-peer.yaml
├── 4-calico-bay-bgp-config.yaml
├── 5-ipaddresspool.yaml      # MetalLB IP pool configuration
├── calico-bgp-config.yaml    # Calico BGP configuration
├── calico-cluster-bgp-peer.yaml
└── l2advertisement.yaml      # MetalLB L2 advertisement
```

## Configuration Files

### Kubeadm Configurations

- **kubeadm-config.yaml**: Default configuration for single-control-plane cluster
- **kubeadm-bay-config.yaml**: Configuration for bay location (192.168.10.11)
- **kubeadm-sans-bay-config.yaml**: Alternative configuration
- **kube-join.yaml**: Worker node join token configuration

### Calico Networking

- **calico/1-tigera-operator.yaml**: Tigera operator deployment
- **calico/2-custom-resources.yaml**: Custom Calico configuration (IP pool, MTU, encapsulation)
- **calico-bgp-config.yaml**: BGP configuration for local cluster
- **3-calico-bay-bgp-peer.yaml**: BGP peer configuration for bay location
- **4-calico-bay-bgp-config.yaml**: BGP settings for bay location

### MetalLB LoadBalancer

- **5-ipaddresspool.yaml**: IP address pool for LoadBalancer services
- **l2advertisement.yaml**: L2 advertisement configuration

## Network Configuration

### Bay Location (192.168.10.x)
- **Control Plane**: 192.168.10.11
- **Network**: 192.168.10.0/24
- **Pod Subnet**: 10.244.0.0/16
- **Service Subnet**: 10.96.0.0/16

### Cloud Location
- Separate configuration in `cloud/` directory
- Configured for BGP peering with bay location

## Management Commands

### Tunnel Management

```bash
# Start tunnel
~/bin/k8s-tunnel-start

# Stop tunnel
~/bin/k8s-tunnel-stop

# Restart tunnel
~/bin/k8s-tunnel-restart

# Check status
~/bin/k8s-tunnel-status

# View logs
~/bin/k8s-tunnel-logs       # Recent logs
~/bin/k8s-tunnel-logs -f   # Follow logs
```

### Kubernetes Operations

```bash
# Get cluster status
kubectl get nodes
kubectl get pods -A

# Apply manifests
kubectl apply -f <manifest.yaml>

# View logs
kubectl logs -n <namespace> <pod>

# Describe resources
kubectl describe pod <pod-name>
```

## Remote Access Security

The cluster is accessed via SSH SOCKS5 proxy, which provides:
- Secure encrypted tunneling through SSH
- No credential exposure (admin.conf remains on server)
- Automatic reconnection via systemd service
- Centralized access control through SSH keys

See `AGENTS.md` for detailed SSH SOCKS5 proxy setup and troubleshooting.

## Versions

- **Kubernetes**: v1.30
- **Calico**: (see 1-tigera-operator.yaml)
- **MetalLB**: v0.14.9
- **Helm**: v3.17.0
- **Cert-Manager**: v1.17.0

## Troubleshooting

### Tunnel Connection Issues

```bash
# Check if tunnel is running
~/bin/k8s-tunnel-status

# Verify SSH key authentication
ssh -W %h:%p k8s-tunnel echo "OK"

# Check if SOCKS5 proxy is listening
lsof -i:1080

# View tunnel logs
~/bin/k8s-tunnel-logs
```

### kubectl Connection Issues

```bash
# Verify kubeconfig has proxy-url
kubectl config view | grep proxy-url

# Test cluster connectivity
kubectl get nodes
```

## Contributing

When adding new configurations:
1. Follow the numbered file convention for dependencies
2. Document IP ranges and network configurations
3. Include deletion instructions for resources with dependencies
4. Update this README with relevant changes
5. Test with `kubectl apply --dry-run=client` before committing

## Documentation

- **SECURITY.md**: Security policy, exposed information, and incident response
- **AGENTS.md**: Detailed guide for cluster access, validation, and style guidelines
- **MANUAL_SETUP.md**: Step-by-step manual SSH SOCKS5 proxy setup
- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **Calico Documentation**: https://docs.tigera.io/calico/
