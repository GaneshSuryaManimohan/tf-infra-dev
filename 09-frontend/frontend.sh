#!/usr/bin/env bash
set -euxo pipefail

component=$1
environment=$2
dnf install -y ansible python3-pip
pip3 install --upgrade pip
pip3 install boto3 botocore
command -v ansible-pull
ansible-pull -i localhost, -U https://github.com/GaneshSuryaManimohan/tf-ansible-roles.git main.yaml -e component=$component -e env=$environment