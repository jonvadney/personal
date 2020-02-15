#!/bin/sh

git config --global user.email "jon.vadney@gmail.com"
git config --global user.name "Jon Vadney"

sudo apt-get update
sudo apt-get upgrade
sudo apt-get dist-upgrade

sudo apt-get install ansible unzip

terraform_url=$(curl https://www.terraform.io/downloads.html | grep -A 5 Linux | grep amd64 | grep -oP '(?<=").*\"' | sed 's/"$//')
terraform_filename=$(basename ${terraform_url})
wget --timestamping ${terraform_url}
unzip ${terraform_filename}
sudo mv terraform /usr/local/bin/
rm ${terraform_filename}

