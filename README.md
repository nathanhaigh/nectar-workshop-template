# Launch Multiple VMs
To launch multiple VMs you can use a command similar to the one below. Once the VMs are up-and-running, 
a hostname-to-IP address mapping file ```hostname2ip.txt``` is also created.

To launch 30 medium-sized VMs (2 CPUs, 8GB RAM) using the NXServer image using the keypair named
```my_keypair``` execute the following command:
```bash
NECTAR_IMAGE_ID='58cb2d08-325c-468d-93c6-877f9b327aed'
KEYPAIR_NAME='my_keypair'
NUMBER_OF_VMS=30
FLAVOR_SIZE=1

./instantiate_vms.sh \
  -i ${NECTAR_IMAGE_ID} \
  -k ${KEYPAIR_NAME} \
  -n ${NUMBER_OF_VMS} \
  -s ${FLAVOR_SIZE}
```

The NXServer image is based on Ubuntu 12.04 64bit but has been configured with an NX server. By default,
these instantiated VMs will be named ```VM-???``` where ```???``` is ```001 - 030```.

# Generating NX Session Files
Generate the NX session files for all the VMs listed in the ```hostname2ip.txt``` file:
```bash
TEMPLATE_NX_SESSION_FILE='template.nxs'
REMOTE_USERNAME='username'
REMOTE_PASSWORD='password'

xargs -L 1 -a <(awk '{gsub(/[=,_]/, "-", $1); print " --host ", $2, " --output ", $1".nxs"}' < hostname2ip.txt) \
  perl nx_template2session_file.pl \
    --template "${TEMPLATE_NX_SESSION_FILE}" \
    --username "${REMOTE_USERNAME}" \
    --password "${REMOTE_PASSWORD}"
```

# Customising VM's During Instantiation
VM's launched from a particular image can be customised such that they differ from that
base image. This is useful for things such as:

* Updating and upgrading the currently installed software
* Setting the password of the default user on the image
* Adding new users and setting their passwords
* Installing new software from package repositories
* Pulling data onto the VM instances
* Setting the timezone
* Adding convienient desktop links to applications, websites etc

All you need do is to pass a script to ```instantiate_vms.sh``` using the ```-u```
argument. This script is then executed by the root user during instantiation. Many
languages are supported, just ensure you have the correct "shebang" line and the
language is supported/installed on the base image.

Here's an example file (```post-instantiation.sh```), written in Bash, for running on an Ubuntu 12.04 base image:
```bash
#!/bin/bash
# Define some variables for use in the following script
REMOTE_UBUNTU_PASSWORD='secure_ubuntu_password'
REMOTE_USER_USERNAME='new_username'
REMOTE_USER_FULL_NAME='Full Name of New User'
REMOTE_USER_PASSWORD='secure_new_user_password'
TIMEZONE='Australia/Adelaide'
FIREFOX_LINK_URL='http://australianbioinformatics.net/'
#####

# Update the ubuntu user's password
echo -e "ubuntu:${REMOTE_UBUNTU_PASSWORD}" | chpasswd

# Ensure we start with an up-to-date base system
apt-get update && apt-get dist-upgrade -y

# Add the trainee user and set the account password
useradd --shell /bin/bash --create-home --comment "${REMOTE_USER_FULL_NAME}" ${REMOTE_USER_USERNAME}
echo -e "swc_trainee:${REMOTE_USER_PASSWORD}" | chpasswd

# Set the time zone
#####
echo "${TIMEZONE}" > /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata

# Install a bunch of packages from the repositories
#####
apt-get install -y \
  raxml \
  muscle \
  python-biopython \
  python-pip \
  openjdk-7-jdk \
  python-nose \
  gedit-plugins \
  gedit-developer-plugins \
  python-coverage \
  python-matplotlib \
  zlib1g-dev \
  python-scipy

# Add some desktop links
#####
# First, ensure the user has a Desktop directory into which we'll put these files
if [[ ! -e "/home/${REMOTE_USER_USERNAME}/Desktop" ]]; then
  mkdir --mode=755 /home/${REMOTE_USER_USERNAME}/Desktop
fi

# Add a Firefox shortcut to ${FIREFOX_LINK_URL} onto the desktop and make it executable
#####
echo "[Desktop Entry]
Name=Australian Bioinformatics Network
Type=Application
Encoding=UTF-8
Comment=Link to Australian Bioinformatics Network
Exec=firefox ${FIREFOX_LINK_URL}
Icon=/usr/lib/firefox/browser/icons/mozicon128.png
Terminal=FALSE" > /home/${REMOTE_USER_USERNAME}/Desktop/firefox_abn_link.desktop
chmod +x /home/${REMOTE_USER_USERNAME}/Desktop/firefox_abn_link.desktop

# Since this script is run as root, any files created by it are owned by root:root.
# Therefore, we'll ensure all files under /home/${REMOTE_USER_USERNAME} are owned
# by the correct user:
chown --recursive ${REMOTE_USER_USERNAME}:${REMOTE_USER_USERNAME} /home/${REMOTE_USER_USERNAME}/
```
