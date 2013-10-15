This repository contains code useful for instantiating VM on the Australian
NeCTAR Rsearch Cloud (http://www.nectar.org.au/research-cloud). The scripts
it contains, aid in the instantiation of multiple VM's configured with an NX
server and the generation of NX Session files for use with NoMachine's 
(http://www.nomachine.com/) NX Client v3.5.x (v4 not yet tested).

What this means is that you can quickly instantiate many VM's and get a
remote desktop-like connection using the NoMachine NX Client.

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
  -i "${NECTAR_IMAGE_ID}" \
  -k "${KEYPAIR_NAME}" \
  -n "${NUMBER_OF_VMS}" \
  -s "${FLAVOR_SIZE}"
```

The NXServer image is based on Ubuntu 12.04 64bit but has been configured with an NX server. By default,
these instantiated VMs will be named ```VM-???``` where ```???``` is ```001 - 030```.

The script will also generated a ```hostname2ip.txt``` file which contains mappings
of the VM name to their IP addresses. This is useful for performing post-instantiation sysadmin
tasks using parallel-shell tools (see below).

# Generating NoMachine NX Session Files
Generate the NoMachine NX session files for all the VMs listed in the ```hostname2ip.txt``` file:
```bash
TEMPLATE_NX_SESSION_FILE='template.nxs'
REMOTE_USER_USERNAME='username'
REMOTE_USER_PASSWORD='password'

xargs -L 1 -a <(awk '{gsub(/[=,_]/, "-", $1); print " --host ", $2, " --output ", $1".nxs"}' < hostname2ip.txt) \
  perl nx_template2session_file.pl \
    --template "${TEMPLATE_NX_SESSION_FILE}" \
    --username "${REMOTE_USER_USERNAME}" \
    --password "${REMOTE_USER_PASSWORD}"
```

The supplied NoMachine template session file ```template.nxs``` will result in NX
sessions running in "fullscreen" mode. That is, no window decorations will be
visable. This is a useful configuration for when you do not want to expose users
to the fact they are working on a remote computer.

These session files can simply be "double-clicked" to run the NX client with very
little further configuration. Once the session has connected, simply type
```Ctrl + Alt + k``` so that the VM captures keystrokes such as ```Ctrl + Alt + Delete```,
```Alt + Tab```. Once again, this helps to hide the fact that users are working
on a remote computer. You can then choose the correct time to expose this to them,
if indeed you do at all.

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

To do this, you can simply pass a script to ```instantiate_vms.sh``` using the ```-u```
argument for performing these customisations:
```bash
NECTAR_IMAGE_ID='58cb2d08-325c-468d-93c6-877f9b327aed'
KEYPAIR_NAME='my_keypair'
NUMBER_OF_VMS=30
FLAVOR_SIZE=1

CUSTOMISATION_SCRIPT='post-instantiation.sh'

./instantiate_vms.sh \
  -i "${NECTAR_IMAGE_ID}" \
  -k "${KEYPAIR_NAME}" \
  -n "${NUMBER_OF_VMS}" \
  -s "${FLAVOR_SIZE}" \
  -u "${CUSTOMISATION_SCRIPT}"
```

This script will then be executed by the ```root``` user during instantiation of the VMs. An example
script (```post-instantiation.sh```), written in Bash, for running on an Ubuntu 12.04 base
image could be:
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
echo -e "${REMOTE_USER_USERNAME}:${REMOTE_USER_PASSWORD}" | chpasswd

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

Many languages are supported for this script, just ensure you have the correct "shebang" line and the
language is supported/installed on the image you're instantiating.

# Administering Multiple VM's After Instantiation
Once you've instantiated all the VMs you need, you may find there are things you forgot
to install/configure, a user may want an additional package installed etc. Fear not,
parallel-shell (http://code.google.com/p/parallel-ssh/) to the rescue. Parallel-shell
provides parallel versions of ```SSH``` tools like ```ssh```, ```scp```, ```rsync```,
```nuke``` and ```slurp```. Each command takes a list of hostnames/ip addresses, the
username and password to log into each remote computer.

To install these tool on Ubuntu, simply run the following:
```bash
sudo apt-get install -y pssh
```

In the following examples, we'll extract the IP addresses from ```hostname2ip.txt``` which was created
by the ```instantiate_vms.sh``` script:
```bash
# Install kate and konsole on all the instantiated VMs
SUDO_USER_USERNAME='ubuntu'
parallel-ssh --hosts=<(cut -f 2 hostname2ip.txt) --user=${SUDO_USER_USERNAME} --askpass -O UserKnownHostsFile=/dev/null -O StrictHostKeyChecking=no --timeout=0 sudo apt-get install -y kate konsole
```

```bash
# Copy a file to a user's Desktop
REMOTE_USER_USERNAME='a_username'
parallel-scp --hosts=<(cut -f 2 hostname2ip.txt) --user=${REMOTE_USER_USERNAME} --askpass -O UserKnownHostsFile=/dev/null -O StrictHostKeyChecking=no --timeout=0 ./a_file /home/$REMOTE_USER_USERNAME/Desktop/
```

```bash
# Pull a file from every VM to the current computer
# The following will put the files under ./<ip_address>/
REMOTE_USER_USERNAME='a_username'
parallel-slurp --hosts=<(cut -f 2 hostname2ip.txt) --user=${REMOTE_USER_USERNAME} --askpass -O UserKnownHostsFile=/dev/null -O StrictHostKeyChecking=no --timeout=0 -L ./ /home/$REMOTE_USER_USERNAME/some_file some_file
```


