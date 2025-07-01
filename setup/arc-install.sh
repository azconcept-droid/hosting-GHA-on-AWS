# Add the new ARC Helm repository
helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller
helm repo update

# Install cert-manager (required dependency)
sudo k3s kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Wait for cert-manager to be ready
sudo k3s kubectl wait --for=condition=ready pod -l app=cert-manager -n cert-manager --timeout=300s

# Install the controller
helm install actions-runner-controller actions-runner-controller/actions-runner-controller \
  --namespace actions-runner-system \
  --create-namespace

# Install the new ARC controller
helm install arc actions-runner-controller/gha-runner-scale-set-controller \
    --namespace actions-runner-system \
    --create-namespace
