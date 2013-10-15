#!/bin/bash
# Launch the Adelaide SWC Boot Camp VMs
# BUG: Can't regenerate the NX session files with this script as the random password generated on each run of this script
#      won't then match VM's previously launched with this file. Use something like Perl's XML::Twig module (http://search.cpan.org/dist/XML-Twig/)
#####

# Define parameters for the VMs we want to launch
#####
NECTAR_IMAGE_NAME='Software Carpentry'
VM_NAME_PREFIX='basic-'
CELL='monash'
KEYPAIR_NAME='pt-1589'
NUMBER_OF_VMS=1
STARTING_FROM_NUMBER=1
FLAVOR_SIZE=1
TEMPLATE_NX_SESSION_FILE='../../template.nxs'
POST_INSTANTIATION_SCRIPT='post_instantiation_script.sh'

# Define the customisation script which will be passed to each VM during instantiation
#  We'll first define some variables and then use a heredoc to output the script to a file which will then be passed to
#  the instantiation script "instantiate_vms.sh"
#####
# Generate a password for the default ubuntu user so we can perform parallel-ssh commands on all instantiated VMs with ease
REMOTE_UBUNTU_PASSWORD='bioubuntu'
# Create a new trainee user with password
REMOTE_USER_USERNAME='trainee'
REMOTE_USER_FULL_NAME='Trainee'
REMOTE_USER_PASSWORD='trainee'

echo "=============================="
echo "ubuntu:${REMOTE_UBUNTU_PASSWORD}"
echo "${REMOTE_USER_USERNAME}:${REMOTE_USER_PASSWORD}"
echo "=============================="

# The post-instantiation heredoc
#####
cat > ${POST_INSTANTIATION_SCRIPT} <<__SCRIPT__
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

# Add the trainee user and set the account password
useradd --shell /bin/bash --create-home --comment "${REMOTE_USER_FULL_NAME}" ${REMOTE_USER_USERNAME}
echo -e "${REMOTE_USER_USERNAME}:${REMOTE_USER_PASSWORD}" | chpasswd

# Set the time zone
#####
echo "${TIMEZONE}" > /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata

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
chmod u+x /home/${REMOTE_USER_USERNAME}/*.desktop

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

# Create NX Session files from a template
#####
echo -n "Generating NX session files ... "
xargs -L 1 -a <(awk '{gsub(/[=,_]/, "-", $1); print " --host ", $2, " --output ", $1".nxs"}' < hostname2ip.txt) \
  perl ../../nx_template2session_file.pl \
    --template "${TEMPLATE_NX_SESSION_FILE}" \
    --username "${REMOTE_USER_USERNAME}" \
    --password "${REMOTE_USER_PASSWORD}"
echo "DONE"
