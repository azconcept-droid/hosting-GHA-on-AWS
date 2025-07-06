# GitHub App Setup for Actions Runner Controller

## Overview
Actions Runner Controller (ARC) is a Kubernetes operator that orchestrates and scales self-hosted runners for GitHub Actions. A GitHub App provides secure authentication and the necessary permissions for ARC to manage runners.

## Step 1: Create the GitHub App

### Via GitHub Web Interface
1. Go to your GitHub account/organization settings
2. Navigate to "Developer settings" → "GitHub Apps"
3. Click "New GitHub App"

### Required Configuration

#### Basic Information
- **App name**: `actions-runner-controller` (or your preferred name)
- **Description**: `GitHub App for Actions Runner Controller`
- **Homepage URL**: Your organization URL or repository URL
- **Webhook URL**: Leave blank (not needed for ARC)
- **Webhook**: Uncheck "Active" (ARC doesn't need webhooks)

#### Permissions
ARC requires these specific permissions:

**Repository permissions:**
- **Actions**: Read (to access workflow runs)
- **Administration**: Read (to manage runners)
- **Checks**: Read (to access check runs)
- **Contents**: Read (to access repository content)
- **Metadata**: Read (basic repository info)
- **Pull requests**: Read (for PR-triggered workflows)

**Organization permissions:**
- **Members**: Read (if using organization-level runners)
- **Self-hosted runners**: Write (essential for managing runners)

#### Where can this GitHub App be installed?
- Choose "Any account" if you want to use it across multiple organizations
- Choose "Only on this account" if it's for your specific organization only

## Step 2: Generate and Store Credentials

After creating the app, you'll need:

1. **App ID**: Found in the app settings (note this down)
2. **Private Key**: 
   - Click "Generate a private key"
   - Download the `.pem` file
   - Store it securely (you'll need it for ARC configuration)

## Step 3: Install the GitHub App

### For Organization-level Runners
1. In your GitHub App settings, click "Install App"
2. Select your organization
3. Choose "All repositories" or select specific repositories
4. Note the **Installation ID** from the URL (e.g., `https://github.com/settings/installations/12345678`)

### For Repository-level Runners
1. Install the app on specific repositories where you want self-hosted runners
2. Each installation will have its own Installation ID

## Step 4: ARC Configuration

### Kubernetes Secret for GitHub App
Create a Kubernetes secret containing your GitHub App credentials:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: arc-github-app-secret
  namespace: arc-systems
type: Opaque
data:
  # Base64 encoded GitHub App ID
  github_app_id: <base64-encoded-app-id>
  # Base64 encoded GitHub App Installation ID
  github_app_installation_id: <base64-encoded-installation-id>
  # Base64 encoded private key content
  github_app_private_key: <base64-encoded-private-key>
```

### Create the secret using kubectl:
```bash
# Encode your values
echo -n "123456" | base64  # Your App ID
echo -n "987654321" | base64  # Your Installation ID
cat your-private-key.pem | base64 -w 0  # Your private key

# Or create the secret directly
kubectl create secret generic arc-github-app-secret \
  --namespace=arc-systems \
  --from-literal=github_app_id="123456" \
  --from-literal=github_app_installation_id="987654321" \
  --from-file=github_app_private_key=your-private-key.pem
```

## Step 5: ARC Helm Configuration

### Install ARC with Helm
```bash
# Add the ARC Helm repository
helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller

# Install ARC controller
helm install arc \
  --namespace arc-systems \
  --create-namespace \
  actions-runner-controller/actions-runner-controller \
  --set=authSecret.create=true \
  --set=authSecret.github_app_id="123456" \
  --set=authSecret.github_app_installation_id="987654321" \
  --set=authSecret.github_app_private_key_file_path="/tmp/github_app_private_key" \
  --set-file=authSecret.github_app_private_key=your-private-key.pem
```

### Alternative: Using existing secret
```bash
helm install arc \
  --namespace arc-systems \
  --create-namespace \
  actions-runner-controller/actions-runner-controller \
  --set=authSecret.enabled=false \
  --set=githubConfigSecret.enabled=true \
  --set=githubConfigSecret.name="arc-github-app-secret"
```

## Step 6: Runner Deployment Configuration

### Organization-level Runner Pool
```yaml
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: org-runners
  namespace: arc-systems
spec:
  replicas: 3
  template:
    spec:
      organization: your-org-name
      group: default
      labels:
        - self-hosted
        - linux
        - x64
      image: summerwind/actions-runner:latest
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
        limits:
          cpu: 500m
          memory: 512Mi
```

### Repository-level Runner Pool
```yaml
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: repo-runners
  namespace: arc-systems
spec:
  replicas: 2
  template:
    spec:
      repository: your-org/your-repo
      labels:
        - self-hosted
        - linux
        - x64
      image: summerwind/actions-runner:latest
```

### Auto-scaling Runner Set
```yaml
apiVersion: actions.summerwind.dev/v1alpha1
kind: HorizontalRunnerAutoscaler
metadata:
  name: auto-scaling-runners
  namespace: arc-systems
spec:
  scaleTargetRef:
    name: org-runners
  minReplicas: 1
  maxReplicas: 10
  metrics:
    - type: TotalNumberOfQueuedAndInProgressWorkflowRuns
      repositoryNames:
        - your-org/repo1
        - your-org/repo2
  scaleDownDelaySecondsAfterScaleOut: 300
  scaleUpTriggers:
    - githubEvent:
        workflowJob: {}
      amount: 1
      duration: "5m"
```

## Step 7: Verification and Testing

### Check ARC Controller Status
```bash
# Check if ARC controller is running
kubectl get pods -n arc-systems

# Check controller logs
kubectl logs -n arc-systems deployment/arc-actions-runner-controller

# Check runner deployments
kubectl get runnerdeployments -n arc-systems
kubectl get runners -n arc-systems
```

### Test Runner Registration
```bash
# Check if runners are registered in GitHub
# Go to GitHub → Your Org/Repo → Settings → Actions → Runners
```

### Test Workflow
Create a test workflow in your repository:
```yaml
name: Test Self-Hosted Runner
on: [push]

jobs:
  test:
    runs-on: [self-hosted, linux, x64]
    steps:
      - uses: actions/checkout@v4
      - name: Test runner
        run: |
          echo "Running on self-hosted runner"
          hostname
          docker --version
```

## Step 8: Common Configuration Options

### Custom Runner Image
```yaml
spec:
  template:
    spec:
      image: myregistry/custom-runner:latest
      imagePullPolicy: Always
      dockerdWithinRunnerContainer: true
```

### Resource Limits
```yaml
spec:
  template:
    spec:
      resources:
        requests:
          cpu: 500m
          memory: 1Gi
        limits:
          cpu: 2
          memory: 4Gi
```

### Node Selector
```yaml
spec:
  template:
    spec:
      nodeSelector:
        kubernetes.io/arch: amd64
        node-type: runner
```

## Troubleshooting

### Common Issues

1. **Authentication Errors**
   - Verify GitHub App ID and Installation ID
   - Check private key format and encoding
   - Ensure App has correct permissions

2. **Runner Registration Failures**
   - Check network connectivity from cluster
   - Verify GitHub App installation scope
   - Check controller logs for detailed errors

3. **Scaling Issues**
   - Review HorizontalRunnerAutoscaler configuration
   - Check metrics and triggers
   - Monitor resource usage

### Debug Commands
```bash
# Check ARC controller logs
kubectl logs -n arc-systems -l app.kubernetes.io/name=actions-runner-controller

# Check runner pod logs
kubectl logs -n arc-systems <runner-pod-name>

# Check runner deployment status
kubectl describe runnerdeployment -n arc-systems <deployment-name>
```

## Security Best Practices

1. **GitHub App Permissions**
   - Use minimal required permissions
   - Regularly review and audit permissions
   - Consider separate apps for different environments

2. **Kubernetes Security**
   - Use dedicated namespace for ARC
   - Implement network policies
   - Use service accounts with minimal permissions

3. **Secrets Management**
   - Store GitHub App private key securely
   - Use Kubernetes secrets or external secret management
   - Rotate keys regularly

## Monitoring and Maintenance

1. **Monitor Runner Health**
   - Set up alerts for runner failures
   - Monitor resource usage
   - Track job queue lengths

2. **Regular Updates**
   - Keep ARC controller updated
   - Update runner images regularly
   - Monitor GitHub Actions updates

This setup provides a robust, scalable solution for managing GitHub Actions self-hosted runners in Kubernetes using Actions Runner Controller.