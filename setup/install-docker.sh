#!/bin/bash

# This script installs docker engine on ubuntu linux
# Author: Azeez Yahaya
# Usage: ./docker-installation-script
# Date: Jan 2024

# Setup docker apt repo

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install latest version of docker
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# verify docker engine is installed successfully
sudo docker run hello-world

# add user to docker group
sudo usermod -aG docker $USER

#happy hacking
echo "*** logout or exit and login back for docker added to sudo group to take effect ***"
echo "*** Happy hacking ***"

