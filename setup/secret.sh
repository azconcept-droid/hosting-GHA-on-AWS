
kubectl create secret generic github-token \
  --from-literal=token=your_github_personal_access_token \
  -n actions-runner-system
