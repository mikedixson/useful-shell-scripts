#! /bin/bash
set -euo pipefail

usage() {
  echo "Usage: $0 <var_user> <var_ssh_pub_key>"
  echo "Example: $0 user \"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5...\""
}

if [[ $# -ne 2 ]]; then
  usage
  exit 1
fi

GROUPNAME="sudo"
var_user="$1"
shift
var_ssh_pub_key="$*"
id --user "${var_user}" &>/dev/null || sudo adduser -q  --gecos "${var_user}" --ingroup "${GROUPNAME}" --disabled-password "${var_user}"
sudo --user "${var_user}" mkdir -p "/home/${var_user}/.ssh"
sudo --user "${var_user}" touch "/home/${var_user}/.ssh/authorized_keys"
echo "${var_ssh_pub_key}" | sudo --user "${var_user}" tee "/home/${var_user}/.ssh/authorized_keys"


#modified from from: https://askubuntu.com/questions/1112315/create-user-and-ssh-key-via-script
