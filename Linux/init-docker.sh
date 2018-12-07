#!/usr/bin/env bash

sudo apt-get remove -y docker docker-engine
sudo apt-get update

sudo apt-get install -y \
    linux-image-extra-$(uname -r) \
    linux-image-extra-virtual

 sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# sudo apt-key fingerprint 0EBFCD88

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get update
sudo apt-get install docker-ce
apt-cache madison docker-ce


# sudo systemctl enable docker
# OR
# echo manual | sudo tee /etc/init/docker.override
