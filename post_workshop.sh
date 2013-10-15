#!/bin/bash
container='melbourne_swc'
# tarball up the swc_trainee home directory on the remote machines
parallel-ssh --hosts=<(cut -f 2 hostname2ip.txt) --user=ubuntu --askpass -O UserKnownHostsFile=/dev/null -O StrictHostKeyChecking=no --timeout=0 'h=$(hostname); cd /home; sudo tar -czf /mnt/swc_trainee_home-${h##*-}.tar.gz --exclude ./swc_trainee/.gvfs ./swc_trainee'

# Pull the tarballs to the local computer
parallel-slurp --hosts=<(cut -f 2 hostname2ip.txt) --user=ubuntu --askpass -O UserKnownHostsFile=/dev/null -O StrictHostKeyChecking=no --timeout=0  -L ./swc_trainee /mnt/swc_trainee_home-*.tar.gz ./
ln -s ./swc_trainee/*/swc_trainee_home-???.tar.gz ./

# Put the tarballs into object storage
swift upload ${container} wc_trainee_home-???.tar.gz
swift post --read-acl='.r:*,.rlistings' ${container}

# URL's are as follows:
echo "https://swift.rc.nectar.org.au:8888/v1/AUTH_${OS_TENANT_ID}/${container}/swc_trainee_home-*.tar.gz"
