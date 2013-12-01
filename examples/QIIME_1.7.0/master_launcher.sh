#!/bin/bash
# Launch the Adelaide SWC Boot Camp VMs
# BUG: Can't regenerate the NX session files with this script as the random password generated on each run of this script
#      won't then match VM's previously launched with this file. Use something like Perl's XML::Twig module (http://search.cpan.org/dist/XML-Twig/)
#####
#sudo apt-get install -y git

#git clone https://github.com/nathanhaigh/nectar-workshop-template.git SWC_boot_camp_Adelaide
#cd SWC_boot_camp_Adelaide

# Source the OpenStack *-openrc.sh file to set the ENV variables required for launching instances
# under a given project/tenancy
#source ~/BIG-SA-openrc.sh

# Define parameters for the VMs we want to launch
#####
NECTAR_IMAGE_NAME='NXServer'
VM_NAME_PREFIX='QIIME-1.7.0-'
CELL='monash'
KEYPAIR_NAME='pt-1589'
NUMBER_OF_VMS=1
STARTING_FROM_NUMBER=1
FLAVOR_SIZE="m1.medium"
TEMPLATE_NX_SESSION_FILE='../../template.nxs'
POST_INSTANTIATION_SCRIPT='post_instantiation_script.sh'

# Define the customisation script which will be passed to each VM during instantiation
#  We'll first define some variables and then use a heredoc to output the script to a file which will then be passed to
#  the instantiation script "instantiate_vms.sh"
#####
# Generate a password for the default ubuntu user so we can perform parallel-ssh commands on all instantiated VMs with ease
PASSWORD_LENGTH=10
REMOTE_UBUNTU_PASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-${PASSWORD_LENGTH}};echo;)
#REMOTE_UBUNTU_PASSWORD='some_non_random_password'
# Create a new trainee user with password
REMOTE_USER_USERNAME='qiime_trainee'
REMOTE_USER_FULL_NAME='QIIME Trainee'
REMOTE_USER_PASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-${PASSWORD_LENGTH}};echo;)
#REMOTE_USER_PASSWORD='some_non_random_password'
TIMEZONE='Australia/Adelaide'

WORKSHOP_NAME='QIIME'
PARENT_DIR='/mnt'
TMPDIR="${PARENT_DIR}/tmp"

# Please supply your own USEARCH download licence number for usearch v5.2.236
USEARCH_DOWNLOAD_LICENCE=''

echo "=============================="
echo "ubuntu:${REMOTE_UBUNTU_PASSWORD}"
echo "${REMOTE_USER_USERNAME}:${REMOTE_USER_PASSWORD}"
echo "=============================="

# The post-instantiation heredoc
#####
cat > ${POST_INSTANTIATION_SCRIPT} <<__SCRIPT__
#!/bin/bash
# Update the ubuntu user's password
echo -e "ubuntu:${REMOTE_UBUNTU_PASSWORD}" | chpasswd

# Set the time zone
#####
echo '${TIMEZONE}' > /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata

###############
# apt-get configuration
###############
mkdir -p /mnt/apt-cache
apt-get update


###############
# Setup QIIME 1.7.0
###############
mkdir -p --mode 777 ${PARENT_DIR}/${WORKSHOP_NAME}/qiime

# Enable universe and multiverse repos in /etc/apt/sources.list and install the ec2-ami-tools
sed -i "/^# deb.*\?precise\(-updates\)\? \(uni\|multi\)verse/ s/^# //" /etc/apt/sources.list

apt-get update
apt-get --option dir::cache::archives="/mnt/apt-cache" -y install \\
        python-dev \\
        libncurses5-dev \\
        libssl-dev \\
        libzmq-dev \\
        libgsl0-dev \\
        openjdk-6-jdk \\
        libxml2 \\
        libxslt1.1 \\
        libxslt1-dev \\
        ant \\
        git \\
        subversion \\
        build-essential \\
        zlib1g-dev \\
        libpng12-dev \\
        libfreetype6-dev \\
        mpich2 \\
        libreadline-dev \\
        gfortran \\
        unzip \\
        libmysqlclient18 \\
        libmysqlclient-dev \\
        ghc \\
        sqlite3 \\
        libsqlite3-dev

cd ${PARENT_DIR}/${WORKSHOP_NAME}/qiime
if [[ -d qiime-deploy ]]; then
        cd qiime-deploy
        git pull
        cd ../
else   
        git clone https://github.com/qiime/qiime-deploy.git
fi
if [[ -d qiime-deploy-conf ]]; then
        cd qiime-deploy-conf
        git pull
        cd ../
else   
        git clone https://github.com/nathanhaigh/qiime-deploy-conf.git
fi

# run the QIIME deploy script
cd qiime-deploy
python qiime-deploy.py ${PARENT_DIR}/${WORKSHOP_NAME}/qiime/qiime_software/ -f ${PARENT_DIR}/${WORKSHOP_NAME}/qiime/qiime-deploy-conf/qiime-1.7.0/qiime.conf --force-remove-failed-dirs

# Download and setup usearch
wget http://drive5.com/cgi-bin/upload3.py?license=${USEARCH_DOWNLOAD_LICENCE} -O ${PARENT_DIR}/${WORKSHOP_NAME}/qiime/qiime_software/qiime-1.7.0-release/bin/usearch5.2.236_i86linux32
chmod +x ${PARENT_DIR}/${WORKSHOP_NAME}/qiime/qiime_software/qiime-1.7.0-release/bin/usearch5.2.236_i86linux32
ln -s usearch5.2.236_i86linux32 ${PARENT_DIR}/${WORKSHOP_NAME}/qiime/qiime_software/qiime-1.7.0-release/bin/usearch


#####
# Run the QIIME tests
#####
# A user wishing to use QIIME needs to source the activation script
source ${PARENT_DIR}/${WORKSHOP_NAME}/qiime/qiime_software/activate.sh
print_qiime_config.py -t


#####
# Setup /etc/skel files so new users all get the same starting point
#####
# Add the source line to the skeleton bashrc file so they get a working QIIME install on the command line
echo "source ${PARENT_DIR}/${WORKSHOP_NAME}/qiime/qiime_software/activate.sh" >> /etc/skel/.bashrc

# Add default desktop links
#####
mkdir -p /etc/skel/Desktop

# Add a standard Firefox shortcut to the desktop
#####
echo "[Desktop Entry]
Name=Firefox
Type=Application
Encoding=UTF-8
Comment=Firefox Web Browser
Exec=firefox
Icon=/usr/lib/firefox/browser/icons/mozicon128.png
Terminal=FALSE" > /etc/skel/Desktop/firefox.desktop

# Add a standard gedit shortcut to the desktop
#####
echo "[Desktop Entry]
Name=gedit
GenericName=Text Editor
Comment=Edit text files
Keywords=Plaintext;Write;
Exec=gedit %U
Terminal=false
Type=Application
StartupNotify=true
MimeType=text/plain;
Icon=accessories-text-editor
Categories=GNOME;GTK;Utility;TextEditor;
X-GNOME-DocPath=gedit/gedit.xml
X-GNOME-FullName=Text Editor
X-GNOME-Bugzilla-Bugzilla=GNOME
X-GNOME-Bugzilla-Product=gedit
X-GNOME-Bugzilla-Component=general
X-GNOME-Bugzilla-Version=3.4.1
X-GNOME-Bugzilla-ExtraInfoScript=/usr/share/gedit/gedit-bugreport
Actions=Window;Document;
X-Ubuntu-Gettext-Domain=gedit

[Desktop Action Window]
Name=Open a New Window
Exec=gedit --new-window
OnlyShowIn=Unity;

[Desktop Action Document]
Name=Open a New Document
Exec=gedit --new-window
OnlyShowIn=Unity;" > /etc/skel/Desktop/gedit.desktop

# Add a terminal shortcut to the desktop
#####
echo "[Desktop Entry]
Name=Terminal
Comment=Use the command line
TryExec=gnome-terminal
Exec=gnome-terminal
Icon=utilities-terminal
Type=Application
X-GNOME-DocPath=gnome-terminal/index.html
X-GNOME-Bugzilla-Bugzilla=GNOME
X-GNOME-Bugzilla-Product=gnome-terminal
X-GNOME-Bugzilla-Component=BugBuddyBugs
X-GNOME-Bugzilla-Version=3.4.1.1
Categories=GNOME;GTK;Utility;TerminalEmulator;
StartupNotify=true
OnlyShowIn=GNOME;Unity;
Keywords=Run;
Actions=New
X-Ubuntu-Gettext-Domain=gnome-terminal

[Desktop Action New]
Name=New Terminal
Exec=gnome-terminal
OnlyShowIn=Unity" > /etc/skel/Desktop/gnome-terminal.desktop

chmod u+x /etc/skel/Desktop/*.desktop

#####
# Add the trainee user, put the home directory on /mnt and set the account password
#   It will start with the default files etc as laid out in /etc/skel
#####
useradd --shell /bin/bash --home /mnt/${REMOTE_USER_USERNAME} --create-home --comment "${REMOTE_USER_FULL_NAME}" ${REMOTE_USER_USERNAME}
ln -s /mnt/${REMOTE_USER_USERNAME} /home/${REMOTE_USER_USERNAME}
echo -e "${REMOTE_USER_USERNAME}:${REMOTE_USER_PASSWORD}" | chpasswd


#####
# Ensure we finish up with an up-to-date system
#####
gpg --keyserver subkeys.pgp.net --recv-keys 2A8E3034D018A4CE B1A598E8128B92BD
gpg --export --armor 2A8E3034D018A4CE B1A598E8128B92BD | apt-key add -
mkdir -p /mnt/apt-cache
apt-get update && apt-get --option dir::cache::archives="/mnt/apt-cache" dist-upgrade -y && apt-get autoremove && apt-get clean

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
