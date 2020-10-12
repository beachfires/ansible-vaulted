#!/bin/bash

# Author: Ali Hamdan <ahamdan.dev@gmail.com>
# Maintainer: Ali Hamdan
# Date: 18/04/2019
# Version: 1.0
# Description:
#
#  This is a wrapper script for Ansible. It will handle
#  initialising the ssh keys Ansible needs to connect to
#  the hosts it's managing. This is done through an ansible
#  role which will decrypt the vault encrypted private keys
#  in memory and pass them to ssh-agent with a time-to-live.
#
#  Ansible SSH will use the keys within ssh-agent throughout
#  it's execution within this script. This script will handle
#  the deletion of ssh keys in ssh-agent on EXIT.

# Exit if anything fails
set -e

delete_keys_agent(){
	# Deletes keys from ssh-agent
	ssh-add -D
}

clean_up(){
	# Run clean up tasks
	echo -e '\nExiting. Removing ssh-agent keys.'
	delete_keys_agent
}

# Always delete keys when script exists
trap clean_up EXIT

add_keys_agent() {
	# Adds ansible vaulted keys to ssh-agent
	ansible-playbook playbooks/ssh-agent.yml
}

load_vault_pass(){
	# Get ansible-vault password from user and exports it to env for ansible to use
	stty -echo
	read -p "Vault Password: " vault_passwd; echo
	stty echo
	export VAULT_PASSWORD=$vault_passwd
}

init_ansible(){
	load_vault_pass
	add_keys_agent
}

wrap(){
	# Wrap passed in command with ansible init
	init_ansible
	echo -e "\n$@"
	$@
}


if [ $# -eq 0 ] || [ "$1" == "-h" ]; then
  echo "Usage: `basename $0` ansible-playbook playbooks/debug.yml"
  exit 0
else
  wrap "$@"
fi
