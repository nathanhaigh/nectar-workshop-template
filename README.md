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
  -i ${NECTAR_IMAGE_ID} \
  -k ${KEYPAIR_NAME} \
  -n ${NUMBER_OF_VMS} \
  -s ${FLAVOR_SIZE}
```

The NXServer image is based on Ubuntu 12.04 64bit but has been configured with an NX server. By default,
these instantiated VMs will be named ```VM-???``` where ```???``` is ```001 - 030```.

# Generating NX Session Files
Generate the NX session files for all the VMs listed in the ```hostname2ip.txt``` file:
```bash
TEMPLATE_NX_SESSION_FILE='template.nxs'
REMOTE_USERNAME='username'
REMOTE_PASSWORD='password'

xargs -L 1 -a <(awk '{outfile=$1; sub(/[=,_]/, "-", outfile); print " --host ", $2, " --output ", outfile".nxs"}' < hostname2ip.txt) \
  perl nx_template2session_file.pl \
    --template "${TEMPLATE_NX_SESSION_FILE}" \
    --username "${REMOTE_USERNAME}" \
    --password "${REMOTE_PASSWORD}"
```

