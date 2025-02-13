# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

# install packages
sudo apt-get update
sudo apt-get upgrade -y

sudo apt-get install -y apt-transport-https ca-certificates curl

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl containerd
sudo apt-mark hold kubelet kubeadm kubectl

sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# activate specific modules
# overlay — The overlay module provides overlay filesystem support, which Kubernetes uses for its pod network abstraction
# br_netfilter — This module enables bridge netfilter support in the Linux kernel, which is required for Kubernetes networking and policy.
sudo -i

modprobe br_netfilter
modprobe overlay

# enable packet forwarding, enable packets crossing a bridge are sent to iptables for processing
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-iptables=1" >> /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

# return to user
# In v1.22 and later, if the user does not set the cgroupDriver field under KubeletConfiguration, kubeadm defaults it to systemd.
# by default containerd set SystemdCgroup = false, so you need to activate SystemdCgroup = true, put it in /etc/containerd/config.toml
# https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/configure-cgroup-driver/
# https://kubernetes.io/docs/setup/production-environment/container-runtimes/#cgroup-drivers
sudo mkdir -p /etc/containerd/
sudo containerd config default | sed -e "s#SystemdCgroup = false#SystemdCgroup = true#g" | tee /etc/containerd/config.toml

sudo systemctl restart containerd

# optionally set internal ip for worker and plane
sudo tee /etc/default/kubelet <<EOF
KUBELET_EXTRA_ARGS=--node-ip=192.168.0.6
EOF

# !!!only on plane node
sudo kubeadm init --config=kubeadm-config.yaml

# set default kubeconfig
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# install cni flannel
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
# Install Flannel as a Kubernetes CNI plugin using kubectl
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml


sudo systemctl daemon-reload && sudo systemctl restart kubelet && sudo systemctl restart containerd
sudo systemctl restart containerd
sudo systemctl restart kubelet

# !!!only on worker node
# add worker nodes
# kubeadm token generate
# kubeadm token create ejr61c.v16chepuleltyqp9 --print-join-command --ttl=0
sudo kubeadm join hash


# Install helm
curl -LO https://get.helm.sh/helm-v3.17.0-linux-amd64.tar.gz
tar -zxvf helm-v3.17.0-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
helm version
# Add repos
### helm repo add bitnami https://charts.bitnami.com/bitnami

# Add nginx with helm on plain
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# default is LoadBalancer
helm install ingress-nginx ingress-nginx/ingress-nginx

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --set controller.service.type=NodePort

# Add metallb for external ips
helm install metallb metallb/metallb --namespace metallb-system --create-namespace
# or direct

###crds first
##kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.6/manifests/crds.yaml

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/main/config/manifests/metallb-native.yaml
#any
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml


kubectl get pods -n default -l app.kubernetes.io/name=ingress-nginx

# Install Cert-Manager:
# first install crds
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.0/cert-manager.crds.yaml
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.0/cert-manager.yaml

# Install Metrics
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

