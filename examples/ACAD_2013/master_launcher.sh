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
NECTAR_IMAGE_NAME='NGSTrainingV1.3'
VM_NAME_PREFIX='ACAD-2013-'
CELL='monash'
KEYPAIR_NAME='pt-1589'
NUMBER_OF_VMS=60
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
# Create a new trainee user with password
REMOTE_USER_USERNAME='acad_trainee'
REMOTE_USER_FULL_NAME='ACAD Trainee'
REMOTE_USER_PASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-${PASSWORD_LENGTH}};echo;)
TIMEZONE='Australia/Adelaide'
DROPCANVAS_RO_URL='http://dropcanvas.com/'

WORKSHOP_NAME='ACAD'
PARENT_DIR='/mnt'
TMPDIR="${PARENT_DIR}/tmp"

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

# Add the trainee user and set the account password
useradd --shell /bin/bash --home /mnt/${REMOTE_USER_USERNAME} --create-home --comment "${REMOTE_USER_FULL_NAME}" ${REMOTE_USER_USERNAME}
ln -s /mnt/${REMOTE_USER_USERNAME} /home/${REMOTE_USER_USERNAME}
echo -e "${REMOTE_USER_USERNAME}:${REMOTE_USER_PASSWORD}" | chpasswd

# Set the time zone
#####
echo '${TIMEZONE}' > /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata

# Perform some cleanup
rm /home/${REMOTE_USER_USERNAME}/Desktop/{Cloud\\ BL\\ Homepage,Getting\\ Started}.desktop

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

# Add the dropcanvas shortcut to the desktop
#####
echo "[Desktop Entry]
Name=Dropcanvas
Type=Application
Encoding=UTF-8
Comment=Access files from this boot camp
Exec=firefox ${DROPCANVAS_RO_URL}
Icon=/usr/lib/firefox/browser/icons/mozicon128.png
Terminal=FALSE" > /home/${REMOTE_USER_USERNAME}/Desktop/dropcanvas.desktop

chown ${REMOTE_USER_USERNAME}:${REMOTE_USER_USERNAME} /home/${REMOTE_USER_USERNAME}/Desktop/*.desktop
chmod u+x /home/${REMOTE_USER_USERNAME}/Desktop/*.desktop

mkdir --mode=777 ${TMPDIR}
mkdir -p ${PARENT_DIR}/${WORKSHOP_NAME}/{tools,working_dir}
mkdir -p ${PARENT_DIR}/${WORKSHOP_NAME}/working_dir/{Mon,Tue,Wed,Thu,Fri}
chown -R ${REMOTE_USER_USERNAME} ${PARENT_DIR}/${WORKSHOP_NAME}/working_dir

# setup some convienient things from the trainee's perspective
#sudo su ${REMOTE_USER_USERNAME}
# Home and Desktop symlinks to the workshop's working directory
ln -s ${PARENT_DIR}/${WORKSHOP_NAME}/working_dir /home/${REMOTE_USER_USERNAME}/${WORKSHOP_NAME}
if [[ ! -e "/home/${REMOTE_USER_USERNAME}/Desktop" ]]; then
  mkdir --mode=755 /home/${REMOTE_USER_USERNAME}/Desktop
fi
ln -s ${PARENT_DIR}/${WORKSHOP_NAME}/working_dir /home/${REMOTE_USER_USERNAME}/Desktop/${WORKSHOP_NAME}

###############
# apt-get configuration
###############
mkdir -p /mnt/apt-cache
apt-get update


###############
# Setup for Mon - Commandline
###############
cd ${PARENT_DIR}/${WORKSHOP_NAME}/working_dir/Mon
wget https://swift.rc.nectar.org.au:8888/v1/AUTH_33065ff5c34a4652aa2fefb292b3195a/ACAD_Mon/Commandline.zip && unzip Commandline.zip && rm Commandline.zip
wget https://swift.rc.nectar.org.au:8888/v1/AUTH_33065ff5c34a4652aa2fefb292b3195a/ACAD_Mon/words.zip && unzip words.zip && rm words.zip

###############
# Setup for Tue - NGS Ancient DNA
###############
# install some additional tools for Tue Hands-on
cd ${TMPDIR}
wget http://pysam.googlecode.com/files/pysam-0.6.tar.gz
tar -zxf pysam-0.6.tar.gz
python setup.py install
easy_install https://bitbucket.org/james_taylor/bx-python/get/tip.tar.bz2

cd ${PARENT_DIR}/${WORKSHOP_NAME}/working_dir/Tue
# pull down all the contents of the day's container
curl --silent https://swift.rc.nectar.org.au:8888/v1/AUTH_33065ff5c34a4652aa2fefb292b3195a/ACAD_Tue | awk -v container=ACAD_Tue '{print "https://swift.rc.nectar.org.au:8888/v1/AUTH_33065ff5c34a4652aa2fefb292b3195a/" container "/" $0}' | xargs -I {} wget {}

# Install SRAToolkit in /opt
cd /opt
tool='sratoolkit'
version='2.3.3-4'
url="https://swift.rc.nectar.org.au:8888/v1/AUTH_33065ff5c34a4652aa2fefb292b3195a/ACAD_Tue/\${version}/sratoolkit.\${version}-ubuntu64.tar.gz"
wget \${url}
tar xzf \${url##*/} && rm \${url##*/}
#ln -s /opt/sratoolkit.\${version}-ubuntu64/bin/* /usr/local/bin/

# Install seqtk
cd /opt
git clone https://github.com/lh3/seqtk.git seqtk-head
cd seqtk-head
make
rm -f /usr/local/bin/seqtk
ln -s /opt/seqtk-head/seqtk /usr/local/bin/

# Install AdapterRemoval 1.5
cd /tmp
wget http://adapterremoval.googlecode.com/files/AdapterRemoval-1.5.tar.gz
tar xzf AdapterRemoval-1.5.tar.gz
cd AdapterRemoval-1.5
make && make install

# Install picardtools 1.101
cd /usr/share/java
tool='picard-tools'
version='1.101'
url="https://swift.rc.nectar.org.au:8888/v1/AUTH_33065ff5c34a4652aa2fefb292b3195a/ACAD_Tue/picard-tools-${version}.zip"
wget $url
unzip -q picard-tools-${version}.zip && rm picard-tools-${version}.zip
rm -f picard
ln -s picard-tools-${version} picard

# Install mapDamage 2.0.1i
wget http://pysam.googlecode.com/files/pysam-0.7.5.tar.gz
tar xzf pysam-0.7.5.tar.gz
cd pysam-0.7.5
python setup.py build
python setup.py install

cd /tmp
git clone https://github.com/ginolhac/mapDamage.git
cd mapDamage
git submodule update --init
python setup.py build
python setup.py install


# Install Structure
wget http://pritchardlab.stanford.edu/structure_software/release_versions/v2.3.4/release/structure_linux_frontend.tar.gz
tar xzvf structure_linux_frontend.tar.gz && rm structure_linux_frontend.tar.gz
cd frontend
./install

# Install TreeMix
wget https://swift.rc.nectar.org.au:8888/v1/AUTH_33065ff5c34a4652aa2fefb292b3195a/ACAD_Tue/treemix-1.12.tar.gz
tar xzf treemix-1.12.tar.gz && rm treemix-1.12.tar.gz
cd treemix-1.12
./configure
make
make install


###############
# Setup for Wed - NGS Ancient DNA
###############
cd ${PARENT_DIR}/${WORKSHOP_NAME}
curl --silent https://swift.rc.nectar.org.au:8888/v1/AUTH_33065ff5c34a4652aa2fefb292b3195a/ACAD_Wed | awk -v container=ACAD_Wed '{print "https://swift.rc.nectar.org.au:8888/v1/AUTH_33065ff5c34a4652aa2fefb292b3195a/" container "/" $0}' | xargs -I {} wget {}

###############
# Setup for Thu - QIIME 1.7.0
###############
mkdir -p --mode 777 ${PARENT_DIR}/${WORKSHOP_NAME}/qiime

# Enable universe and multiverse repos in /etc/apt/sources.list and install the ec2-ami-tools
sed -i "/^# deb.*\?precise\(-updates\)\? \(uni\|multi\)verse/ s/^# //" /etc/apt/sources.list

apt-get update
apt-get --option dir::cache::archives="/mnt/apt-cache" -y install \
        python-dev \
        libncurses5-dev \
        libssl-dev \
        libzmq-dev \
        libgsl0-dev \
        openjdk-6-jdk \
        libxml2 \
        libxslt1.1 \
        libxslt1-dev \
        ant \
        git \
        subversion \
        build-essential \
        zlib1g-dev \
        libpng12-dev \
        libfreetype6-dev \
        mpich2 \
        libreadline-dev \
        gfortran \
        unzip \
        libmysqlclient18 \
        libmysqlclient-dev \
        ghc \
        sqlite3 \
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

# Run the QIIME tests
# A user wishing to use QIIME needs to source the activation script
source ${PARENT_DIR}/${WORKSHOP_NAME}/qiime/qiime_software/activate.sh
print_qiime_config.py -t

# Add the source line to the bashrc file for 
echo "source ${PARENT_DIR}/${WORKSHOP_NAME}/qiime/qiime_software/activate.sh" >> /home/${REMOTE_USER_USERNAME}/.bashrc


# Ensure we finish up with an up-to-date system
#####
gpg --keyserver subkeys.pgp.net --recv-keys 2A8E3034D018A4CE B1A598E8128B92BD
gpg --export --armor 2A8E3034D018A4CE B1A598E8128B92BD | apt-key add -
mkdir -p /mnt/apt-cache
apt-get update && apt-get --option dir::cache::archives="/mnt/apt-cache" dist-upgrade -y && apt-get autoremove && apt-get clean

###############
# Post-workshop
###############
# tar up the working_dir using the machine's IP address
#myip=$(ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].*)
#cd; tar -zcf ${myip}.tar.gz working_dir
#swift upload ACAD_working_dirs ${myip}.tar.gz

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
