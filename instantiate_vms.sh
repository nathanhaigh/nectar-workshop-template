#!/bin/bash

usage="USAGE: $(basename $0) [-h] [-d] -i <image id> [-p <prefix>] [-u <script>] [-n <number of VMs>] [-f <int>] [-s <int>] [-x <string>] -k <ssh key>
  where:
    -h Show this help text
    -d dry run
    -i Image ID from which to instantiate VMs
    -p VM name prefix [Default: 'VM-']
    -u Post-instantiation script. Can be a local path or HTTP(S)
    -f First integer for suffix used to number the VMs [Default: 1]
    -n Number of VMs to instantiate [Default: 1]
    -x Suffix format string [Default: %03.f]
    -s Instance size/flavour [Default: 1]
    -k SSH Key name
"

# default command line argument values
#####
DRYRUN=0
IMAGE_ID=
VM_NAME_PREFIX="VM-"
USER_DATA_FILE=
N_VMs=1
SSH_KEY_NAME=
FIRST=1
FLAVOUR=1
FORMAT='%03.f'

# parse any command line options to change default values
while getopts ":hdi:p:u:n:x:k:f:s:" opt; do
case $opt in
    h) echo "$usage"
       exit
       ;;
    d) DRYRUN=1
       ;;
    i) IMAGE_ID=$OPTARG
       ;;
    p) VM_NAME_PREFIX=$OPTARG
       ;;
    u) USER_DATA_FILE=$OPTARG
       ;;
    n) N_VMs=$OPTARG
       ;;
    f) FIRST=$OPTARG
       ;;
    s) FLAVOUR=$OPTARG
       ;;
    x) FORMAT=$OPTARG
       ;;
    k) SSH_KEY_NAME=$OPTARG
       ;;
    ?) printf "Illegal option: '-%s'\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      echo "$usage" >&2
      exit 1
      ;;
  esac
done

if [[ -z $IMAGE_ID ]] || [[ -z $VM_NAME_PREFIX ]] || [[ -z $N_VMs ]] || [[ -z $FIRST ]] || [[ -z $SSH_KEY_NAME ]] || [[ -z $FLAVOUR ]] || [[ -z $FORMAT ]]
then
  echo "$usage" >&2
  exit 1
fi

case ${USER_DATA_FILE%%://*} in
    http) wget --quiet --no-clobber $USER_DATA_FILE -O /tmp/${USER_DATA_FILE##*/}
       USER_DATA_FILE="/tmp/${USER_DATA_FILE##*/}"
       ;;
    https) wget --quiet --no-clobber $USER_DATA_FILE -O /tmp/${USER_DATA_FILE##*/}
       USER_DATA_FILE="/tmp/${USER_DATA_FILE##*/}"
       ;;
    *)
       USER_DATA_FILE=${USER_DATA_FILE}
       ;;
esac

# Start the boot process
#####
echo "Booting VMs ... "
n_booted=0
wait_every_n_instantiated=5
LAST=$((FIRST+N_VMs-1))
for i in `seq --format="${FORMAT}" ${FIRST} ${LAST}`; do
  INSTANCE_NAME="${VM_NAME_PREFIX}${i}"
  echo -n "  VM: ${INSTANCE_NAME} ... "
  # Only instantiate a VM if the given name doesn't already exist
  if [[ ! $(nova list --name "^${INSTANCE_NAME}$" | fgrep ${INSTANCE_NAME}) ]]; then
    echo "Booting"
    (( n_booted++ ))
    if [[ ${DRYRUN} == 0 ]]; then
        nova boot --flavor=${FLAVOUR} --image=${IMAGE_ID} ${INSTANCE_NAME} --security-groups="SSH" --key-name=${SSH_KEY_NAME} --user-data=${USER_DATA_FILE} --meta description="${VM_NAME_PREFIX}${i}" --meta creator='Nathan S. Watson-Haigh'
    fi
  else
    echo "A VM with this name already exists"
  fi
  if [[ $DRYRUN == 0 ]]; then
          if (( ${n_booted} > 0 )); then
            if (( ${n_booted} % ${wait_every_n_instantiated} == 0 || ${i} == ${LAST})); then
              echo "  Waiting for all previously instantiated VMs to come out of the BUILD status ... "
              while [[ $(nova list --name "^${VM_NAME_PREFIX}[0-9]+$" --status BUILD | fgrep ${VM_NAME_PREFIX}) ]]; do
                # sleep for 30s for every 5 VM's build requests and for
                # which 1 or more still have a BUILD status
                echo -n "    Waiting for 15s ... "
                sleep 15s
                echo "DONE"
              done
            fi
          fi
  fi
done

echo -n "Generating mapping file (hostname2ip.txt) ... "
nova list --name "^${VM_NAME_PREFIX}[0-9]+$" --status ACTIVE | perl -ne 'print "$1\t$2\n" if /('${VM_NAME_PREFIX}'\d+).+?(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/' > hostname2ip.txt
echo "DONE"


#echo "nova list --name '^${VM_NAME_PREFIX}[0-9]+$' --status ACTIVE | perl -ne 'print \"\$1\t\$2\n\" if /(${VM_NAME_PREFIX}\d+).+?(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/' > hostname2ip.txt"


#echo "nova list --name '^${VM_NAME_PREFIX}[0-9]+$' --status ACTIVE | perl -ne 'print \"\$1\t\$2\n\" if /(${VM_NAME_PREFIX}\d+).+?(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/' > hostname2ip.txt"
#echo ""
# Use parallel ssh to submit the same command to multiple VMs
#echo "parallel-ssh --hosts=<(cut -f 2 hostname2ip.txt) --user=ubuntu --askpass -O UserKnownHostsFile=/dev/null -O StrictHostKeyChecking=no --timeout=0 --inline ls -l | fgrep cloud_init.finished | wc -l"

#echo "parallel-ssh --hosts=VM_ips.txt --user=ngstrainee --askpass -O UserKnownHostsFile=/dev/null -O StrictHostKeyChecking=no --timeout=0 --outdir=${VM_NAME_PREFIX}stdout --errdir=${VM_NAME_PREFIX}stderr ls -l"


