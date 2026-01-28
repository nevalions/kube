# Security Policy

## Overview

This repository contains Kubernetes configurations for managing bare-metal clusters. Since this is a **public repository**, please be aware of the following security considerations.

## Exposed Information

### Network Infrastructure
This repository publicly exposes the following infrastructure details:

- **Internal IP addresses**: 192.168.10.x, 9.11.0.x network segments
- **Server names**: kuberspb, controlbay, cloud servers
- **Network topology**: BGP peering configurations between locations
- **Service endpoints**: Kubernetes API server addresses
- **Port configurations**: Custom SSH ports (55543), Kubernetes API (6443)

### What IS NOT Exposed
- ❌ No private keys or certificates
- ❌ No passwords or tokens
- ❌ No actual kubeconfig files (admin.conf is NOT tracked)
- ❌ No authentication credentials

### Risk Assessment

**Current Risk Level: LOW-MEDIUM**

**Attackers can learn:**
- Your network structure and IP ranges
- Server names and locations
- Infrastructure patterns (Calico, BGP, MetalLB)
- API endpoint addresses

**Attackers CANNOT:**
- Access your clusters
- Execute commands on servers
- Decrypt communications
- Extract or modify data

**Why the risk is not critical:**
- All sensitive data (keys, certs, tokens) is excluded from git
- Authentication required for cluster access
- SSH keys are never committed
- admin.conf remains on servers only

## Security Best Practices

### For Repository Maintainers

1. **Never commit sensitive files:**
   - kubeconfig files (*.conf)
   - Private keys (*.key, *.pem)
   - Certificates (*.crt)
   - Secrets directories

2. **Use environment variables** for sensitive values:
   ```yaml
   env:
     - name: SECRET_VALUE
       valueFrom:
         secretKeyRef:
           name: my-secret
           key: password
   ```

3. **Review all commits** before pushing:
   ```bash
   git diff --staged
   git grep "BEGIN.*PRIVATE.*KEY\|BEGIN.*CERTIFICATE"
   ```

4. **Keep SSH keys secure:**
   - Never add SSH private keys to this repo
   - Use separate SSH key management
   - Rotate keys regularly

### For Repository Users

1. **Do NOT copy examples verbatim:**
   - Replace IP addresses with your own network ranges
   - Change server names to match your infrastructure
   - Regenerate your own certificates and tokens

2. **Generate unique credentials:**
   ```bash
   # Generate new join token
   kubeadm token create --print-join-command

   # Create new certificates
   openssl genrsa -out my-key.pem 2048
   ```

3. **Review security implications** before applying manifests:
   - Ensure no hardcoded passwords
   - Verify RBAC permissions are minimal
   - Check network policies are appropriate

## Incident Response

If you discover a security issue in this repository:

1. **Do NOT create a public issue**
2. Email: nevalions@gmail.com
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact

We will respond within 48 hours and coordinate disclosure.

## Version History

- **2025-01-28**: Initial security policy, documenting exposed infrastructure information

## References

- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/security-checklist/)
- [OWASP Kubernetes Top 10](https://owasp.org/www-project-kubernetes-top-ten/)
- [Git Security](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage.html)
