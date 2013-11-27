#!/bin/bash
#####
# NOTE: Due to GUI requirements this script can't simply be run from the command line
#####
# Source the OpenStack *-openrc.sh file to set the ENV variables required for launching instances
# under a given project/tenancy
#source ~/BIG-SA-openrc.sh

# Define parameters for the VMs we want to launch
#####
NECTAR_IMAGE_NAME='NXServer'
VM_NAME_PREFIX='BIS_2013-'
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
TIMEZONE='Australia/Adelaide'

# The post-instantiation heredoc
#####
cat > ${POST_INSTANTIATION_SCRIPT} <<__SCRIPT__
#!/bin/bash
# Set the time zone
#####
echo '${TIMEZONE}' > /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata

# set the BIS_2013_desktop.png as the desktop image
wget -O /usr/share/backgrounds/BIS_2013_desktop.png https://swift.rc.nectar.org.au:8888/v1/AUTH_33065ff5c34a4652aa2fefb292b3195a/BIS_2013/BIS_2013_desktop.png
# Customise the desktop picture
sed -i -e 's@\(Golden_Bloom_by_Twinmama.jpg\)@BIS_2013_desktop.png@' /usr/share/glib-2.0/schemas/10_gsettings-desktop-schemas.gschema.override
glib-compile-schemas /usr/share/glib-2.0/schemas/


###############
# apt-get configuration
###############
mkdir -p /mnt/apt-cache
apt-get update

#####
# Software installation for general workshop tools
#####
apt-get install -y --option dir::cache::archives="/mnt/apt-cache" dos2unix debconf-utils

# Install acroread. We need to mess around with the install as the 64bit version of the package doesn't install
# Enable partner repo in /etc/apt/sources.list
sed -i "/^# deb.*\?precise partner/ s/^# //" /etc/apt/sources.list
apt-get update
debconf-set-selections <<\EOF
acroread        acroread-common/default-viewer  boolean true
EOF
apt-get install -y --option dir::cache::archives="/mnt/apt-cache" acroread:i386 libcanberra-gtk-module:i386 gtk2-engines-murrine:i386

#####
# Software installation for Tue - Phylogenetics
#####
# Stephane Guindon
# Install ModelGenerator
wget http://bioinf.nuim.ie/wp-content/uploads/2011/09/modelgenerator_v_851.zip
unzip -d /opt/modelgenerator-851 modelgenerator_v_851.zip && rm modelgenerator_v_851.zip

# Install fitmodel
wget http://fitmodel.googlecode.com/files/fitmodel-20131125.tar.gz
tar xzf fitmodel-20131125.tar.gz && rm fitmodel-20131125.tar.gz
cd fitmodel-20131125
./configure
make clean
make
./configure --enable-coltree
make clean
make
cd ../
mv fitmodel-20131125 /opt/

# Install PhyML
apt-get install -y --option dir::cache::archives="/mnt/apt-cache" mpich2
wget http://phyml.googlecode.com/files/phyml-20120412.tar.gz
tar xzf phyml-20120412.tar.gz && rm phyml-20120412.tar.gz
cd phyml-20120412
./configure && make
./configure --enable-mpi && make
./configure --enable-phytime && make
cd ../
mv phyml-20120412 /opt/
#####

# Sylvain Foret
wget -O install_BiQ_AnalyzerHT.zip 'http://biq-analyzer-ht.bioinf.mpi-inf.mpg.de/get.php?pr=biq-ht&fn=install_BiQ_AnalyzerHT.zip&r=1854622882'
unzip install_BiQ_AnalyzerHT.zip && rm install_BiQ_AnalyzerHT.zip
# Using the GUI run the following and accept defaults except installing under /opt/BiQAnalyzerHT/:
#sudo java -jar install_BiQ_AnalyzerHT.jar
# Fix up issues with windows line endings, executable permissions and not being able to execute from outside the install directory
#sudo chmod +x /opt/BiQAnalyzerHT/*.sh
#sudo dos2unix /opt/BiQAnalyzerHT/*.sh
#sudo sed -i '2s/^/cd $(dirname $0)\n/' /opt/BiQAnalyzerHT/*.sh
#####

# Gavin Huttley
apt-get install -y --option dir::cache::archives="/mnt/apt-cache" build-essential curl python-all-dev python-pip python-mysqldb git zip libzmq1 libzmq-dev ipython-notebook
apt-get build-dep -y --option dir::cache::archives="/mnt/apt-cache" python-matplotlib

wget http://python-distribute.org/distribute_setup.py
python distribute_setup.py
rm distribute*

pip install --upgrade numpy cyvcf sqlalchemy tornado pyzmq "matplotlib>=1.3"
#pip install "matplotlib>=1.3"
#pip install cyvcf

# download the latest pycogent source from the github repo
wget https://github.com/pycogent/pycogent/archive/master.zip
unzip master.zip && rm master.zip
cd pycogent-master
python setup.py install
cd ../
rm -r pycogent-master

# Setup an iPython notebook profile
ipython profile create ipynbs
wget https://www.dropbox.com/s/20rvl87rpbqz7vh/profile_ipynbs.tar.gz
tar xzf profile_ipynbs.tar.gz && rm profile_ipynbs.tar.gz
rm -rf .ipython/profile_ipynbs && mv profile_ipynbs .ipython/
chown -R root:root .ipython
mv .ipython /etc/skel/
# User needs to start ipython notebook server using "ipython notebook --profile=ipynbs"

# Create an upstart job for running the iPython notebook server
#echo "start on filesystem
#stop on runlevel [!2345]
#respawn
#exec ipython notebook --profile=ipynbs
#" > /etc/init/ipynbs.conf

# Late arrivals
# Install seaview
mkdir seaview
cd seaview
wget https://swift.rc.nectar.org.au:8888/v1/AUTH_33065ff5c34a4652aa2fefb292b3195a/BIS_2013/seaview4-64.tgz
tar xzf seaview4-64.tgz && rm seaview4-64.tgz
cd ../
mv seaview /opt/

# Install FigTree
wget https://swift.rc.nectar.org.au:8888/v1/AUTH_33065ff5c34a4652aa2fefb292b3195a/BIS_2013/FigTree_v1.4.0.tgz
tar xzf FigTree_v1.4.0.tgz && rm FigTree_v1.4.0.tgz
chmod +x FigTree_v1.4.0/bin/figtree
sed -i '2s/^/cd $(dirname $0)\n/' FigTree_v1.4.0/bin/figtree
sed -i 's/ lib/ ..\/lib/' FigTree_v1.4.0/bin/figtree
mv FigTree_v1.4.0 /opt/


#####
# Software installation for Wed - Systems Biology
#####
apt-get install -y openjdk-7-jre
# Install VANTED
wget --output-document=vanted2.1.0.zip http://sourceforge.net/projects/vanted/files/vanted2/v2.1.0/vanted2.1.0.zip/download?use_mirror=aarnet
unzip vanted2.1.0.zip && rm vanted2.1.0.zip
chmod a+x Vanted/*.sh
# Fix EOL characters in shell scripts
dos2unix Vanted/*.sh
mv Vanted /opt/
# start Vanted and then close. copy ~/.vanted to /etc/skel/
wget --output-document=/etc/skel/.vanted/addons/sbgn-ed.jar http://vanted.ipk-gatersleben.de/addons/sbgn-ed/downloads/sbgn-ed.jar
wget --output-document=/etc/skel/.vanted/addons/adaptagrams64.so http://vanted.ipk-gatersleben.de/addons/sbgn-ed/downloads/adaptagrams64.so
# Vanted now installed in /opt/Vanted/startVanted.sh



#####
# Software installation for Thu - RNA-Seq
#####
apt-get install -y --option dir::cache::archives="/mnt/apt-cache" firefox icedtea-netx

# Install FastQC
wget http://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.10.1.zip
unzip fastqc_v0.10.1.zip && rm fastqc_v0.10.1.zip
chmod +x FastQC/fastqc
mv FastQC /opt/
echo "export PATH=/opt/FastQC:\$PATH" >> /etc/skel/.bashrc

# Install FastX-Toolkit
wget http://hannonlab.cshl.edu/fastx_toolkit/fastx_toolkit_0.0.13_binaries_Linux_2.6_amd64.tar.bz2
tar xjf fastx_toolkit_0.0.13_binaries_Linux_2.6_amd64.tar.bz2 && rm fastx_toolkit_0.0.13_binaries_Linux_2.6_amd64.tar.bz2
mkdir -p /opt/fastx-toolkit
mv bin /opt/fastx-toolkit/
echo "export PATH=/opt/fastx-toolkit/bin:\$PATH" >> /etc/skel/.bashrc

# Install Picard-tools
wget --output-document=picard-tools-1.103.zip http://sourceforge.net/projects/picard/files/picard-tools/1.103/picard-tools-1.103.zip/download?use_mirror=aarnet
unzip picard-tools-1.103.zip && rm picard-tools-1.103.zip
mv picard-tools-1.103 /opt/

# Install bowtie
wget --output-document=bowtie-1.0.0-linux-x86_64.zip http://sourceforge.net/projects/bowtie-bio/files/bowtie/1.0.0/bowtie-1.0.0-linux-x86_64.zip/download?use_mirror=aarnet
unzip bowtie-1.0.0-linux-x86_64.zip && rm bowtie-1.0.0-linux-x86_64.zip
mv bowtie-1.0.0 /opt/
chmod +x /opt/bowtie-1.0.0/bowtie*
find /opt/bowtie-1.0.0 -type d -execdir chmod +rx {} +
echo "export PATH=/opt/bowtie-1.0.0:\$PATH" >> /etc/skel/.bashrc

# Install samtools
wget --output-document=samtools-0.1.19.tar.bz2 http://sourceforge.net/projects/samtools/files/samtools/0.1.19/samtools-0.1.19.tar.bz2/download?use_mirror=aarnet
tar xjf samtools-0.1.19.tar.bz2 && rm samtools-0.1.19.tar.bz2
cd samtools-0.1.19
mkdir -p ./{lib,include/bam}
ln -s --target-directory ./lib ../libbam.a
cd ./include/bam/ && ln -s ../../*.h ./ && cd ../../../
mv samtools-0.1.19 /opt/
find /opt/samtools-0.1.19 -type d -execdir chmod +rx {} +
echo "export PATH=/opt/samtools-0.1.19:\$PATH" >> /etc/skel/.bashrc

# Install boost
wget --output-document=boost_1_55_0.tar.gz http://sourceforge.net/projects/boost/files/boost/1.55.0/boost_1_55_0.tar.gz/download?use_mirror=aarnet
tar xzf boost_1_55_0.tar.gz && rm boost_1_55_0.tar.gz
cd boost_1_55_0
./bootstrap.sh
./b2 --prefix=/opt/boost_1.55.0 install
cd ../
rm -r boost_1_55_0

# Install tophat
wget http://tophat.cbcb.umd.edu/downloads/tophat-2.0.10.tar.gz
tar xzf tophat-2.0.10.tar.gz && rm tophat-2.0.10.tar.gz
cd tophat-2.0.10
./configure --with-bam=/opt/samtools-0.1.19 --with-boost=/opt/boost_1.55.0 --bindir=/opt/tophat-2.0.10
make && make install && cd ../ && rm -r tophat-2.0.10
echo "export PATH=/opt/tophat-2.0.10:\$PATH" >> /etc/skel/.bashrc

# Install cufflinks
wget http://cufflinks.cbcb.umd.edu/downloads/cufflinks-2.1.1.Linux_x86_64.tar.gz
tar xzf cufflinks-2.1.1.Linux_x86_64.tar.gz && rm cufflinks-2.1.1.Linux_x86_64.tar.gz
mv cufflinks-2.1.1.Linux_x86_64 /opt/cufflinks-2.1.1
echo "export PATH=/opt/cufflinks-2.1.1:\$PATH" >> /etc/skel/.bashrc

# Install IGV
wget http://www.broadinstitute.org/igv/projects/downloads/IGV_2.3.25.zip
unzip IGV_2.3.25.zip && rm IGV_2.3.25.zip
mv /tmp/IGV_2.3.25 /opt/
# run IGV, get the Zebrafish Zv9 genome and the copy ~/igv to /etc/skel/
sudo cp -r ~/igv /etc/skel/


#####
# Software installation for Fri - Intro Programming
#####

#####
# Software installation for Fri - R Packages
#####
# Enable backports repo in /etc/apt/sources.list and install
sed -i "/^# deb.*\?precise-backports/ s/^# //" /etc/apt/sources.list
#add-apt-repository "deb http://cran.rstudio.com/bin/ubuntu precise/"
add-apt-repository "deb http://mirror.aarnet.edu.au/pub/CRAN/bin/linux/ubuntu precise/" && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
apt-get update
apt-get install -y --option dir::cache::archives="/mnt/apt-cache" build-essential r-base r-base-dev libjpeg62 libcurl4-openssl-dev
wget http://download1.rstudio.org/rstudio-0.97.551-amd64.deb
dpkg -i rstudio-0.97.551-amd64.deb && rm rstudio-0.97.551-amd64.deb

# set AARNET mirrors for CRAN and BioC
echo 'options(repos=c(CRAN="http://mirror.aarnet.edu.au/pub/CRAN/"))
options(BioC_mirror=c("AARNet (Australia)" = "http://mirror.aarnet.edu.au/pub/bioconductor"))
' >> /etc/R/Rprofile.site

echo '
install.packages("ggplot2")
install.packages("devtools")
install.packages("roxygen2")
install.packages("plyr")
install.packages("reshape2")
' > r_workshop_dependencies.R
R --no-save --no-restore < r_workshop_dependencies.R && rm r_workshop_dependencies.R


#####
# Software installation for Fri - Advanced Programming
#####




#####
# Setup /etc/skel files so new users all get the same starting point
#####
rm /etc/skel/examples.desktop

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

chmod +x /etc/skel/Desktop/*.desktop

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

