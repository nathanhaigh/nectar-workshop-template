#!/bin/bash
#####
# The intent for this script is to copy it to the VM's (using parallel-scp) and execute (using parallel-ssh) it with root privileges. e.g.
# parallel-scp --hosts=<(cut -f 2 hostname2ip.txt) --user=ubuntu --askpass -O UserKnownHostsFile=/dev/null -O StrictHostKeyChecking=no --timeout=0 daily_user_reset.sh /home/ubuntu/
# parallel-ssh --hosts=<(cut -f 2 hostname2ip.txt) --user=ubuntu --askpass -O UserKnownHostsFile=/dev/null -O StrictHostKeyChecking=no --timeout=0 sudo /home/ubuntu/daily_user_reset.sh
#####
# Since the workshop content is stored under /etc/skel, then every new user on the system will get the same pristine copy of the workshop from creation.
# This means we can just delete the user at the end of each day and recreate it.
# Stop the freenx server
/etc/init.d/freenx-server stop
# Delete the bis_trainee
#umount /mnt/bis_trainee/.gvfs
userdel --remove bis_trainee
# Recreate the bis_trainee user and set the password
useradd --non-unique --uid 1001 --shell /bin/bash --home /mnt/bis_trainee --create-home --comment "BioInfoSummer Trainee" bis_trainee
echo -e "bis_trainee:trainee" | chpasswd
# Start the freenx server
/etc/init.d/freenx-server start

