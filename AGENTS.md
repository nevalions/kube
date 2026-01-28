# Kubernetes Configuration Repository

This repository contains Kubernetes manifests and deployment scripts for cluster management.

## Security Policy

**This repository is PUBLIC** and contains infrastructure information. See `SECURITY.md` for detailed security considerations.

### What to Know

**Exposed information:**
- Internal IP addresses and network topology
- Server names and locations
- Infrastructure patterns (Calico, BGP, MetalLB)

**NOT exposed:**
- Private keys or certificates
- Passwords or authentication tokens
- Actual kubeconfig files

### Best Practices

- Never commit `admin.conf` or kubeconfig files
- Use environment variables for sensitive values
- Replace example IPs with your own network ranges
- Generate unique credentials (don't copy tokens)
- See `SECURITY.md` for complete security guidelines

## Validation Commands

### YAML Syntax Validation
```bash
# Validate single file
kubectl apply --dry-run=client -f <file.yaml>

# Validate entire directory
kubectl apply --dry-run=client -R -f <directory>

# Check for deprecated APIs
kubectl-apply-validate --local <file.yaml>  # if kubectl-apply-validate is installed
```

### Apply Manifests
```bash
# Apply single file
kubectl apply -f <file.yaml>

# Apply directory
kubectl apply -R -f <directory>

# Apply with specific namespace
kubectl apply -n <namespace> -f <file.yaml>
```

### Common Verification Commands
```bash
# Check pod status
kubectl get pods -A

# Check resource status
kubectl get all -A

# Check logs
kubectl logs -n <namespace> <pod-name>

# Describe resource
kubectl describe -n <namespace> <resource-type> <resource-name>

# Get events
kubectl get events -A --sort-by='.lastTimestamp'
```

## File Naming and Organization

### Numbered Files
- Prefix files with numbers to indicate application order (e.g., `1-tigera-operator.yaml`)
- Sequential numbering is critical for dependencies (e.g., CRDs must be applied before resources)
- Use hyphens between numbers and names

### Directory Structure
- `calico/` - Calico CNI configurations
- `cloud/` - Cloud-specific configurations
- Root directory - General cluster configurations

## YAML Style Guidelines

### Metadata
```yaml
apiVersion: <version>
kind: <Kind>
metadata:
  name: <resource-name>
  namespace: <namespace>  # Only if namespaced
  labels:
    app: <app-name>
    # Additional labels as needed
```

### Comments
- Include deletion instructions in comments when resources have dependencies
- Place deletion commands at the top of files for webhook configurations
- Comment out alternate configurations rather than deleting them
- Use `#` for all comments

### IP Addresses and Network Configuration
- Document specific IP ranges in comments
- Avoid hardcoded IPs when possible; use environment variables or ConfigMaps
- Include CIDR notation consistently

### Resource Limits
```yaml
spec:
  containers:
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "500m"
        memory: "512Mi"
```

## Common Patterns

### Multi-Document YAML
- Separate documents with `---`
- Group related resources in single files when possible
- Use multiple files for resources applied at different times

### Namespace Configuration
- Create namespace before applying namespaced resources
- Use namespace labels for organizational metadata

### ConfigMaps and Secrets
- Prefer ConfigMaps over hardcoded values
- Never commit secrets; use Sealed Secrets or external secret management
- Reference ConfigMaps in pods using `configMapKeyRef`

### Workaround Comments
- Document workarounds with `###` prefix
- Include links to related issues or documentation

## Remote Cluster Access via SSH SOCKS5 Proxy

This repository includes configuration for secure remote kubectl access using SSH SOCKS5 proxy.

### Architecture
- **SSH SOCKS5 Tunnel**: Creates a secure proxy on localhost:1080
- **Traffic Flow**: Local kubectl → SOCKS5 proxy (localhost:1080) → SSH tunnel → Kubernetes API server
- **Security**: Credentials never leave the remote server; all traffic encrypted via SSH

### Setup Instructions

#### 1. SSH Configuration
A `k8s-tunnel` host entry is configured in `~/.ssh/config` with:
- DynamicForward 1080 (SOCKS5 proxy)
- ServerAliveInterval 60 (keep connection alive)
- ExitOnForwardFailure yes (fail if tunnel breaks)

#### 2. Systemd Service
User-level systemd service: `~/.config/systemd/user/k8s-tunnel.service`
- Auto-starts on boot
- Auto-restarts on failure
- No sudo required

#### 3. Initial Configuration
Run the setup script to extract kubeconfig data from remote server:
```bash
cd /home/linroot/code/kube
./setup-k8s-tunnel.sh
```

**Important**: Do NOT run this script with sudo. The script will prompt for sudo password on the remote server (kuberspb) to read `/etc/kubernetes/admin.conf`.

This script:
- Extracts certificate data from `/etc/kubernetes/admin.conf` on kuberspb
- Creates local `~/.kube/config` with SOCKS5 proxy configuration
- Sets `proxy-url: socks5://localhost:1080` in kubeconfig

#### 4. Tunnel Management Scripts

Helper scripts in `~/bin/`:

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
~/bin/k8s-tunnel-logs      # Recent logs
~/bin/k8s-tunnel-logs -f    # Follow logs
```

#### 5. Manual Tunnel Commands

```bash
# Start systemd service
systemctl --user start k8s-tunnel.service

# Enable on boot
systemctl --user enable k8s-tunnel.service

# Check status
systemctl --user status k8s-tunnel.service

# View logs
journalctl --user -u k8s-tunnel.service -f
```

#### 6. Verify Connection

```bash
# Check tunnel is running
~/bin/k8s-tunnel-status

# Test kubectl
kubectl get nodes
kubectl get pods -A
```

### Troubleshooting

**Problem: Tunnel won't start**
```bash
# Check logs
journalctl --user -u k8s-tunnel.service -n 50

# Common issues:
- SSH key authentication failing
- Network connectivity to remote server
- Port 1080 already in use
```

**Problem: kubectl can't connect**
```bash
# Verify kubeconfig has proxy-url
kubectl config view | grep proxy-url

# Should show: proxy-url: socks5://localhost:1080

# Verify SOCKS5 proxy is listening
lsof -i:1080

# Test SSH connection
ssh -W %h:%p k8s-tunnel echo "OK"
```

**Problem: Connection drops frequently**
- Increase `ServerAliveInterval` in `~/.ssh/config`
- Check network stability
- Verify SSH keys are working properly

### Security Benefits

1. **No credential exposure**: admin.conf remains on remote server
2. **SSH encryption**: All traffic encrypted through SSH
3. **Access control**: Leverages existing SSH key authentication
4. **Audit trail**: SSH logs provide connection history
5. **Revocable**: Revoke SSH access to instantly remove kubectl access

## Safety Checklist

Before applying manifests:
1. Run `kubectl apply --dry-run=client` on all files
2. Verify namespace existence before applying namespaced resources
3. Check for duplicate resource names
4. Ensure CRDs are installed before CR resources
5. Validate webhook configurations can be deleted without causing errors
6. Ensure SSH SOCKS5 tunnel is active before running kubectl commands (if using remote cluster)

## Version References

This repo uses specific versions:
- Kubernetes: v1.30
- Calico: (see Tigera operator version in 1-tigera-operator.yaml)
- Helm: v3.17.0
- Cert-Manager: v1.17.0

Update versions in documentation when changing in manifests.
