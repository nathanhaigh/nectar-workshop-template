#!/bin/bash
# Launch the Adelaide SWC Boot Camp VMs
# BUG: Can't regenerate the NX session files with this script as the random password generated on each run of this script
#      won't then match VM's previously launched with this file. Use something like Perl's XML::Twig module (http://search.cpan.org/dist/XML-Twig/)
#####
#OS_PASSWORD="Y2EyNTc0Yjg0N2M0Yzgx"
#sudo apt-get install -y git

#git clone https://github.com/nathanhaigh/nectar-workshop-template.git SWC_boot_camp_Adelaide
#cd SWC_boot_camp_Adelaide

# Source the OpenStack *-openrc.sh file to set the ENV variables required for launching instances
# under a given project/tenancy
#source ~/BIG-SA-openrc.sh

# Define parameters for the VMs we want to launch
#####
NECTAR_IMAGE_NAME='Software Carpentry'
VM_NAME_PREFIX='SWC_Bootcamp-'
CELL='monash'
KEYPAIR_NAME='pt-1589'
NUMBER_OF_VMS=40
STARTING_FROM_NUMBER=1
FLAVOR_SIZE=1
TEMPLATE_NX_SESSION_FILE='../../template.nxs'
POST_INSTANTIATION_SCRIPT='post_instantiation_script.sh'

# Define the customisation script which will be passed to each VM during instantiation
#  We'll first define some variables and then use a heredoc to output the script to a file which will then be passed to
#  the instantiation script "instantiate_vms.sh"
#####
# Generate a password for the default ubuntu user so we can perform parallel-ssh commands on all instantiated VMs with ease
PASSWORD_LENGTH=10
REMOTE_UBUNTU_PASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-${PASSWORD_LENGTH}};echo;)
# Create a new trainee user with password
REMOTE_USER_USERNAME='swc_trainee'
REMOTE_USER_FULL_NAME='Software Carpentry Trainee'
REMOTE_USER_PASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-${PASSWORD_LENGTH}};echo;)
TIMEZONE='Australia/Melbourne'

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

# Add the trainee user and set the account password
useradd --shell /bin/bash --create-home --comment "${REMOTE_USER_FULL_NAME}" ${REMOTE_USER_USERNAME}
echo -e "swc_trainee:${REMOTE_USER_PASSWORD}" | chpasswd

# Set the time zone
#####
echo '${TIMEZONE}' > /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata


# Ensure we start with an up-to-date base system
apt-get update && apt-get dist-upgrade -y

# Install packages
#####
apt-get install -y raxml muscle python-biopython python-pip openjdk-7-jdk python-nose gedit-plugins gedit-developer-plugins python-coverage python-matplotlib zlib1g-dev python-scipy gitg
pip install sphinx

# Install the Eclipse IDE with default repositories and plugins
#####
# Eclipse and plugin installation
wget http://mirror.aarnet.edu.au/pub/eclipse/technology/epp/downloads/release/kepler/R/eclipse-standard-kepler-R-linux-gtk-x86_64.tar.gz
tar xzf eclipse-standard-*-R-linux-gtk-x86_64.tar.gz
mv eclipse /opt/
ln -s /opt/eclipse/eclipse /usr/local/bin/eclipse
eclipse \\
  -noSplash \\
  -application org.eclipse.equinox.p2.director \\
  -repository \\
    http://download.eclipse.org/releases/kepler,http://pydev.org/updates,http://download.walware.de/eclipse-4.2,http://e-p-i-c.sf.net/updates/testing \\
  -installIU \\
    org.eclipse.epp.mpc.feature.group,org.eclipse.egit.feature.group,org.eclipse.jgit.feature.group,org.python.pydev.feature.feature.group,de.walware.statet.r.feature.group,org.epic.feature.main.feature.group

# Add some desktop links
#####
# First, ensure the user has a Desktop directory into which we'll put these files
if [[ ! -e "/home/${REMOTE_USER_USERNAME}/Desktop" ]]; then
  mkdir --mode=755 /home/${REMOTE_USER_USERNAME}/Desktop
fi
chown ${REMOTE_USER_USERNAME}:${REMOTE_USER_USERNAME} /home/${REMOTE_USER_USERNAME}/Desktop

# Add a standard Firefox shortcut to the desktop
#####
echo "[Desktop Entry]
Name=Firefox
Type=Application
Encoding=UTF-8
Comment=Firefox Web Browser
Exec=firefox
Icon=/usr/lib/firefox/browser/icons/mozicon128.png
Terminal=FALSE" > /home/${REMOTE_USER_USERNAME}/Desktop/firefox.desktop

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
OnlyShowIn=Unity;" > /home/${REMOTE_USER_USERNAME}/Desktop/gedit.desktop

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
OnlyShowIn=Unity" > /home/${REMOTE_USER_USERNAME}/Desktop/gnome-terminal.desktop

# Add an Eclipse shortcut to the desktop
#####
echo "[Desktop Entry]
Name=Eclipse IDE
Type=Application
Encoding=UTF-8
Comment=Eclipse Integrated Development Environment
Exec=eclipse
Icon=/opt/eclipse/icon.xpm
Terminal=FALSE" > /home/${REMOTE_USER_USERNAME}/Desktop/eclipse.desktop

# Add the MEL etherpad shortcut to the desktop
#####
echo "[Desktop Entry]
Name=Boot Camp Etherpad
Type=Application
Encoding=UTF-8
Comment=Etherpad
Exec=firefox https://etherpad.mozilla.org/swcmelbourne
Icon=/usr/lib/firefox/browser/icons/mozicon128.png
Terminal=FALSE" > /home/${REMOTE_USER_USERNAME}/Desktop/etherpad.desktop

# Add the #swcmel hashtag shortcut to the desktop
#####
echo "[Desktop Entry]
Name=Tweet About It
Type=Application
Encoding=UTF-8
Comment=Tweet about this Boot Camp using our hashtag
Exec=firefox https://twitter.com/intent/tweet?button_hashtag=swcmel
Icon=/usr/lib/firefox/browser/icons/mozicon128.png
Terminal=FALSE" > /home/${REMOTE_USER_USERNAME}/Desktop/tweet.desktop

# Add the dropcanvas shortcut to the desktop
#####
echo "[Desktop Entry]
Name=Dropcanvas
Type=Application
Encoding=UTF-8
Comment=Access files from this boot camp
Exec=firefox http://dropcanvas.com/faykm
Icon=/usr/lib/firefox/browser/icons/mozicon128.png
Terminal=FALSE" > /home/${REMOTE_USER_USERNAME}/Desktop/dropcanvas.desktop

chown ${REMOTE_USER_USERNAME}:${REMOTE_USER_USERNAME} /home/${REMOTE_USER_USERNAME}/Desktop/*.desktop
chmod 744 /home/${REMOTE_USER_USERNAME}/Desktop/*.desktop

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
