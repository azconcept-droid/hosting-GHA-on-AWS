# Add the new ARC Helm repository
helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller
helm repo update

# Install cert-manager (required dependency)
sudo k3s kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Wait for cert-manager to be ready
sudo k3s kubectl wait --for=condition=ready pod -l app=cert-manager -n cert-manager --timeout=300s

# Install the controller
helm install arcv1 actions-runner-controller/actions-runner-controller \
  --namespace actions-runner-system \
  --create-namespace

# NAME: arcv1
# LAST DEPLOYED: Fri Jul  4 10:38:55 2025
# NAMESPACE: action-runner-ns
# STATUS: deployed
# REVISION: 1
# TEST SUITE: None
# NOTES:
# 1. Get the application URL by running these commands:
#   export POD_NAME=$(kubectl get pods --namespace action-runner-ns -l "app.kubernetes.io/name=actions-runner-controller,app.kubernetes.io/instance=arcv1" -o jsonpath="{.items[0].metadata.name}")
#   export CONTAINER_PORT=$(kubectl get pod --namespace action-runner-ns $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
#   echo "Visit http://127.0.0.1:8080 to use your application"
#   kubectl --namespace action-runner-ns port-forward $POD_NAME 8080:$CONTAINER_PORT
