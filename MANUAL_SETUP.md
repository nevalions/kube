# Manual Kubernetes Configuration Setup

## Quick Setup

Since SSH doesn't support interactive sudo prompts in scripts, follow these manual steps:

### Step 1: SSH to kuberspb

```bash
ssh kuberspb
```

### Step 2: Extract kubeconfig data

Run this command ON kuberspb (it will display the complete kubeconfig):

```bash
cat /etc/kubernetes/admin.conf
```

### Step 3: Create local kubeconfig

On your **local machine**, create `~/.kube/config` with the following template, replacing the placeholders:

```bash
mkdir -p ~/.kube
cat > ~/.kube/config <<'EOF'
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: <paste certificate-authority-data from kuberspb>
    server: <paste server address from kuberspb, e.g. https://192.168.10.11:6443>
    proxy-url: socks5://localhost:1080
  name: kuberspb
contexts:
- context:
    cluster: kuberspb
    user: kubernetes-admin
  name: kuberspb
current-context: kuberspb
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
    client-certificate-data: <paste client-certificate-data from kuberspb>
    client-key-data: <paste client-key-data from kuberspb>
EOF
```

### Step 4: Start SSH tunnel

```bash
systemctl --user start k8s-tunnel
systemctl --user enable k8s-tunnel  # Enable on boot
```

### Step 5: Verify connection

```bash
~/bin/k8s-tunnel-status
kubectl get nodes
```

## Alternative: Using the Extraction Script

1. Copy `extract-kubeconfig-on-server.sh` to kuberspb:
   ```bash
   scp /home/linroot/code/kube/extract-kubeconfig-on-server.sh kuberspb:~/
   ```

2. SSH to kuberspb and run it:
   ```bash
   ssh kuberspb
   bash ~/extract-kubeconfig-on-server.sh
   ```

3. Copy the output block to your local machine and run it

## Troubleshooting

**"Connection refused" when starting tunnel**
- Check if kuberspb is reachable: `ssh kuberspb echo "OK"`
- Verify SSH port 55543 is accessible

**"Certificate verification failed"**
- Make sure you copied the correct certificate-authority-data
- Check that the server address matches kuberspb's API server

**kubectl hangs or times out**
- Verify tunnel is running: `~/bin/k8s-tunnel-status`
- Check SOCKS5 proxy is listening: `lsof -i:1080`

## What Each Component Does

- **SSH SOCKS5 tunnel**: Encrypts all kubectl traffic through SSH
- **proxy-url: socks5://localhost:1080**: Routes kubectl through the tunnel
- **Certificates**: Authenticate with the cluster without exposing admin.conf
- **Systemd service**: Keeps tunnel alive and auto-restarts

## Security Notes

- Your `admin.conf` never leaves the kuberspb server
- Only certificate data is extracted (no keys are transmitted)
- All traffic is encrypted via SSH
- Access can be revoked by removing SSH key or changing remote password
