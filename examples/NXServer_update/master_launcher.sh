#!/bin/bash
# Update the NXServer image

# Define parameters for the VMs we want to launch
#####
NECTAR_IMAGE_NAME='NeCTAR Ubuntu 12.04.2 (Precise) amd64 UEC'
VM_NAME='NXServer-setup'
CELL='monash'
KEYPAIR_NAME='pt-1589'
FLAVOR_SIZE="m1.medium"
POST_INSTANTIATION_SCRIPT='post_instantiation_script.sh'

# Define the customisation script which will be passed to each VM during instantiation
#  We'll first define some variables and then use a heredoc to output the script to a file which will then be passed to
#  the instantiation script "instantiate_vms.sh"
#####

# The post-instantiation heredoc
#####
cat > ${POST_INSTANTIATION_SCRIPT} <<__SCRIPT__
#!/bin/bash
mkdir -p /mnt/apt-cache

# Enable ssh login with passwords
sed -i -e 's@PasswordAuthentication no@PasswordAuthentication yes@' /etc/ssh/sshd_config

# Install dependencies
DEPENDENCIES_INSTALLED=0
until  [ ${DEPENDENCIES_INSTALLED} -eq 1 ]; do
	# TODO: Don't know if recommended packages are needed
	#apt-get -y --option dir::cache::archives="/mnt/apt-cache" --option APT::Install-Recommends="true" install ubuntu-desktop gnome-session-fallback python-software-properties && DEPENDENCIES_INSTALLED=1
	apt-get -y --option dir::cache::archives="/mnt/apt-cache" install ubuntu-desktop gnome-session-fallback python-software-properties && DEPENDENCIES_INSTALLED=1
done

# Add the freenx repo to apt and install freenx
add-apt-repository -y ppa:freenx-team
apt-get update
apt-get -y install freenx
cd /tmp
wget https://bugs.launchpad.net/freenx-server/+bug/576359/+attachment/1378450/+files/nxsetup.tar.gz
tar xzf nxsetup.tar.gz && rm nxsetup.tar.gz
cp nxsetup /usr/lib/nx/nxsetup
/usr/lib/nx/nxsetup --auto --install

# Configure freenx and enable users to authenticate against SSH
ssh-keygen -f "/var/lib/nxserver/home/.ssh/known_hosts" -R 127.0.0.1
sed -i -e 's/^.\(NX_LOG_LEVEL\)=.$/\1=6/' /etc/nxserver/node.conf
sed -i -e 's/^#\(NX_LOGFILE\)/\1/' /etc/nxserver/node.conf
sed -i -e 's/^.\(ENABLE_SSH_AUTHENTICATION\)="."$/\1="1"/' /etc/nxserver/node.conf
sed -i -e 's/^#\(SSHD_PORT\)/\1/' /etc/nxserver/node.conf

# Customise the desktop picture
sed -i -e 's@\(warty-final-ubuntu.png\)@Golden_Bloom_by_Twinmama.jpg@' /usr/share/glib-2.0/schemas/10_gsettings-desktop-schemas.gschema.override
glib-compile-schemas /usr/share/glib-2.0/schemas/

# Restart SSH service and NX Server
service ssh reload
nxserver --restart

# Finish off by ensuring we have the most up-to-date packages installed
apt-get update
apt-get -y --option dir::cache::archives="/mnt/apt-cache" dist-upgrade
apt-get autoremove
apt-get clean

touch /mnt/cloud_init_finished

reboot
__SCRIPT__

BASE_IMAGE_ID=$(nova image-show "${NECTAR_IMAGE_NAME}" | fgrep -w id | perl -ne 'print "$1" if /\|\s+(\S+)\s+\|$/')

nova boot \
    ${VM_NAME} \
    --image "${BASE_IMAGE_ID}" \
    --flavor "${FLAVOR_SIZE}" \
    --hint cell="${CELL}" \
    --security-groups "SSH" \
    --key-name "${KEYPAIR_NAME}" \
    --user-data "${POST_INSTANTIATION_SCRIPT}" \
    --meta description="${VM_NAME}" \
    --meta creator='Nathan S. Watson-Haigh' \
    --poll

#####
# Need to wait till the VM has finished executing the user-data script before continuing below
#####

# Create a snapshot of the updated OS
#  Download the snapshot
#   Create an image in glance
#nova image-create --poll "${VM_NAME}" "${VM_NAME}" && glance image-download --progress --file "${VM_NAME}.raw" "${VM_NAME}" && glance image-create --name NXServer --progress --file "${VM_NAME}.raw" --disk-format qcow2 --container-format bare --is-public True

# delete the instance and the snapshot
#glance image-delete "${VM_NAME}" && nova delete "${VM_NAME}"

