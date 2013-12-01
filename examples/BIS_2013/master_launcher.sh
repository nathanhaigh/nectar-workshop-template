#!/bin/bash
# Source the OpenStack *-openrc.sh file to set the ENV variables required for launching instances
# under a given project/tenancy
#source ~/BIG-SA-openrc.sh

# Define parameters for the VMs we want to launch
#####
NECTAR_IMAGE_NAME='BIS-2013'
VM_NAME_PREFIX='BIS_2013-'
CELL='monash'
KEYPAIR_NAME='pt-1589'
NUMBER_OF_VMS=110
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
REMOTE_UBUNTU_PASSWORD='bioubuntu'
# Create a new trainee user with password
REMOTE_USER_USERNAME='bis_trainee'
REMOTE_USER_FULL_NAME='BioInfoSummer Trainee'
REMOTE_USER_PASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-${PASSWORD_LENGTH}};echo;)
REMOTE_USER_PASSWORD='trainee'
TIMEZONE='Australia/Adelaide'

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

#####
# Software installation for general workshop tools/data
#####
mkdir -p /etc/skel/BIS_2013/{Tue,Wed,Thu,Fri}

#####
# Software installation for Tue - Phylogenetics
#####
# done - Need user to start ipython notebook server using something like: ipython notebook --profile=ipynbs 127.0.0.1:8888
# PhyML binaries installed under /opt/phyml-20120412/src/
# BiQAnalyzerHT installed under /opt/BiQAnalyzerHT/

# Add a dropcanvas shortcut to the desktop
#####
echo "[Desktop Entry]
Name=Tue Dropcanvas
Type=Application
Encoding=UTF-8
Comment=Access BioInfoSummer 2013 files
Exec=firefox http://dropcanvas.com/suov0
Icon=/usr/lib/firefox/browser/icons/mozicon128.png
Terminal=FALSE" > /etc/skel/Desktop/tue_dropcanvas.desktop


#####
# Software installation for Wed - Systems Biology
#####
# done - Vanted installed in /opt/Vanted/startVanted.sh

# Add a dropcanvas shortcut to the desktop
#####
echo "[Desktop Entry]
Name=Wed Dropcanvas
Type=Application
Encoding=UTF-8
Comment=Access BioInfoSummer 2013 files
Exec=firefox http://dropcanvas.com/l1hpi
Icon=/usr/lib/firefox/browser/icons/mozicon128.png
Terminal=FALSE" > /etc/skel/Desktop/wed_dropcanvas.desktop



#####
# Software installation for Thu - RNA-Seq
#####
# done - except IGV and data
# put data in the following directories
mkdir -p /etc/skel/BIS_2013/Thu/{QC,RNA-seq}
cd /etc/skel/BIS_2013/Thu/QC
files=(
  'https://swift.rc.nectar.org.au:8888/v1/AUTH_809/NGSDataQC/bad_example.fastq'
  'https://swift.rc.nectar.org.au:8888/v1/AUTH_809/NGSDataQC/good_example.fastq'
)
for file in "\${files[@]}"; do
  wget \${file}
done

cd /etc/skel/BIS_2013/Thu/RNA-seq
files=(
  'https://swift.rc.nectar.org.au:8888/v1/AUTH_809/NGSDataRNASeq/2cells_1.fastq'
  'https://swift.rc.nectar.org.au:8888/v1/AUTH_809/NGSDataRNASeq/2cells_2.fastq'
  'https://swift.rc.nectar.org.au:8888/v1/AUTH_809/NGSDataRNASeq/6h_1.fastq'
  'https://swift.rc.nectar.org.au:8888/v1/AUTH_809/NGSDataRNASeq/6h_2.fastq'
  'https://swift.rc.nectar.org.au:8888/v1/AUTH_809/NGSDataRNASeq/Danio_rerio.Zv9.66.spliceSites'
  'https://swift.rc.nectar.org.au:8888/v1/AUTH_809/NGSDataRNASeq/Danio_rerio.Zv9.66.gtf'
  'https://swift.rc.nectar.org.au:8888/v1/AUTH_809/NGSDataRNASeq/Danio_rerio.Zv9.66.dna.fa'
  'https://swift.rc.nectar.org.au:8888/v1/AUTH_809/NGSDataRNASeq/Danio_rerio.Zv9.66.dna.fa.fai'
  'https://swift.rc.nectar.org.au:8888/v1/AUTH_809/NGSDataRNASeq/globalDiffExprs_Genes_qval.01_top100.tab'
  'https://swift.rc.nectar.org.au:8888/v1/AUTH_809/NGSDataRNASeq/2cells_genes.fpkm_tracking'
  'https://swift.rc.nectar.org.au:8888/v1/AUTH_809/NGSDataRNASeq/2cells_isoforms.fpkm_tracking'
  'https://swift.rc.nectar.org.au:8888/v1/AUTH_809/NGSDataRNASeq/2cells_transcripts.gtf'
  'https://swift.rc.nectar.org.au:8888/v1/AUTH_809/NGSDataRNASeq/accepted_hits.bam'
  'https://swift.rc.nectar.org.au:8888/v1/AUTH_809/NGSDataRNASeq/accepted_hits.sorted.bam'
  'https://swift.rc.nectar.org.au:8888/v1/AUTH_809/NGSDataRNASeq/accepted_hits.sorted.bam.bai'
  'https://swift.rc.nectar.org.au:8888/v1/AUTH_809/NGSDataRNASeq/junctions.bed'
  'https://swift.rc.nectar.org.au:8888/v1/AUTH_809/NGSDataRNASeq/deletions.bed'
  'https://swift.rc.nectar.org.au:8888/v1/AUTH_809/NGSDataRNASeq/insertions.bed'
)
for file in "\${files[@]}"; do
  wget \${file}
done
# reorganise the files
mkdir -p ./{data,annotation,genome}
mv {2cells,6h}_{1,2}.fastq data/
mv Danio_rerio.Zv9.66.{gtf,spliceSites} annotation/
mv Danio_rerio.Zv9.66.dna.fa* genome/

mkdir -p ./{tophat,cuffdiff}
mv globalDiffExprs_Genes_qval.01_top100.tab cuffdiff/

mkdir -p ./cufflinks/{ZV9_2cells,ZV9_6h}_gtf_guided
mv 2cells_genes.fpkm_tracking ./cufflinks/ZV9_2cells_gtf_guided/genes.fpkm_tracking
mv 2cells_isoforms.fpkm_tracking ./cufflinks/ZV9_2cells_gtf_guided/isoforms.fpkm_tracking
mv 2cells_transcripts.gtf ./cufflinks/ZV9_2cells_gtf_guided/transcripts.gtf
touch ./cufflinks/ZV9_2cells_gtf_guided/skipped.gtf

mkdir -p ./tophat/ZV9_2cells
mv accepted_hits.* *.bed ./tophat/ZV9_2cells/


# Add a dropcanvas shortcut to the desktop
#####
echo "[Desktop Entry]
Name=Thu Dropcanvas
Type=Application
Encoding=UTF-8
Comment=Access BioInfoSummer 2013 files
Exec=firefox http://dropcanvas.com/ivysr
Icon=/usr/lib/firefox/browser/icons/mozicon128.png
Terminal=FALSE" > /etc/skel/Desktop/thu_dropcanvas.desktop



#####
# Software installation for Fri - Intro Programming
#####
# done - Perl v5.14.2 installed by default

# Add a dropcanvas shortcut to the desktop
#####
echo "[Desktop Entry]
Name=Fri (Intro) Dropcanvas
Type=Application
Encoding=UTF-8
Comment=Access BioInfoSummer 2013 files
Exec=firefox http://dropcanvas.com/7tk9e
Icon=/usr/lib/firefox/browser/icons/mozicon128.png
Terminal=FALSE" > /etc/skel/Desktop/fri_intro_dropcanvas.desktop


#####
# Software installation for Fri - R Packages
#####
# done - check rstudio install

# Add a dropcanvas shortcut to the desktop
#####
echo "[Desktop Entry]
Name=Fri (R) Dropcanvas
Type=Application
Encoding=UTF-8
Comment=Access BioInfoSummer 2013 files
Exec=firefox http://dropcanvas.com/kzj4h
Icon=/usr/lib/firefox/browser/icons/mozicon128.png
Terminal=FALSE" > /etc/skel/Desktop/fri_r_dropcanvas.desktop

#####
# Software installation for Fri - Advanced Programming
#####
#done - Need user to start ipython notebook server using something like: ipython notebook --profile=ipynbs

# Add a dropcanvas shortcut to the desktop
#####
echo "[Desktop Entry]
Name=Fri (Adv) Dropcanvas
Type=Application
Encoding=UTF-8
Comment=Access BioInfoSummer 2013 files
Exec=firefox http://dropcanvas.com/bsm2g
Icon=/usr/lib/firefox/browser/icons/mozicon128.png
Terminal=FALSE" > /etc/skel/Desktop/fri_adv_dropcanvas.desktop



#####
# Setup /etc/skel files so new users all get the same starting point
#####
chmod +x /etc/skel/Desktop/*.desktop

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
