#!/bin/bash

# Define parameters for the VMs we want to launch
#####
NECTAR_IMAGE_NAME='NeCTAR Ubuntu 14.04 (Trusty) amd64'
VM_NAME_PREFIX='acpfg_master_api-'
CELL='sa'
KEYPAIR_NAME='pt-1589'
NUMBER_OF_VMS=1
STARTING_FROM_NUMBER=1
FLAVOR_SIZE='m1.medium'
POST_INSTANTIATION_SCRIPT='post_instantiation_script.sh'

# Define the customisation script which will be passed to each VM during instantiation
#  We'll first define some variables and then use a heredoc to output the script to a file which will then be passed to
#  the instantiation script "instantiate_vms.sh"
#####
TIMEZONE='Australia/Adelaide'

# The post-instantiation heredoc
#####
cat > ${POST_INSTANTIATION_SCRIPT} <<__SCRIPT__
#!/bin/bash
# Set the time zone
#####
echo "${TIMEZONE}" > /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata

# Install the Openstack (OS) API clients using pip
apt-get update
apt-get install -y python-pip python-dev libffi-dev libssl-dev build-essential
pip install python-novaclient python-swiftclient python-keystoneclient python-glanceclient

# Install parallel-ssh
apt-get install -y pssh

reboot
__SCRIPT__

# Launch the VMs
#####
../../instantiate_vms.sh \
  -i $(nova image-show "${NECTAR_IMAGE_NAME}" | fgrep -w id | perl -ne 'print "$1" if /\|\s+(\S+)\s+\|$/') \
  -p "${VM_NAME_PREFIX}" \
  -n "${NUMBER_OF_VMS}" \
  -f "${STARTING_FROM_NUMBER}" \
  -s "${FLAVOR_SIZE}" \
  -c "${CELL}" \
  -k "${KEYPAIR_NAME}" \
  -u "${POST_INSTANTIATION_SCRIPT}"

