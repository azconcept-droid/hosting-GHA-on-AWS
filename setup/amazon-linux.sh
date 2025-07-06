# setup amazon linux

sudo yum update -y

sudo yum groupinstall -y 'Development Tools'

# Create secret first
kubectl create secret generic arc-github-app-secret \
  --namespace=arc-systems \
  --from-literal=github_app_id="YOUR_APP_ID" \
  --from-literal=github_app_installation_id="YOUR_INSTALLATION_ID" \
  --from-file=github_app_private_key=path/to/your-private-key.pem