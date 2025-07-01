# hosting-GHA-on-AWS
Hosting github action on AWS EC2

# Setup Documentation

1. Setup server on aws

2. Install tools
  ### Install docker
  run script install-docker.sh
  ```
  bash install-docker.sh
  ```

  ### Install k3s -- light weight kubernetes
  Edit and run script k3s-install.sh

  ### Install kubectl if not already installed

  ### Install Helm

  ### install arc (Actions runner controller)
  Run arc-install.sh script
  ```
  bash ./setup/arc-install.sh
  ```

  ### git hub secret if using PAT

