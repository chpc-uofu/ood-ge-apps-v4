mkdir -p ${JOB_TMP_DIR}/samba/log
mkdir -p ${JOB_TMP_DIR}/samba/lock
mkdir -p ${JOB_TMP_DIR}/samba/private
mkdir -p ${JOB_TMP_DIR}/samba/cache 
mkdir -p ${JOB_TMP_DIR}/samba/ncalrpc

# note that the smb.conf file used to be create here but that is now
# passed in as env var to submit form because information must be retrieved prior to
# network isolation.
cat > ${script_path}/smb.conf <<EOL
[global]
   workgroup = WORKGROUP
   server string = Samba Server
   security = user
   map to guest = Bad User
   log file = ${JOB_TMP_DIR}/samba.log
   max log size = 50
   follow symlinks = yes
   wide links = yes
   unix extensions = no
   interfaces = 127.0.0.1/8
   bind interfaces only = yes
   logging = file
   panic action = /bin/echo %d >> ${JOB_TMP_DIR}/samba/panic_action.log
   load printers = no
   printing = bsd
   printcap name = /dev/null
   disable spoolss = yes
   disable netbios = yes
   server role = standalone server
   server services = -dns, -nbt
   smb ports = 445
   pid directory = ${JOB_TMP_DIR}/samba
   lock directory = ${JOB_TMP_DIR}/samba/lock
   state directory = ${JOB_TMP_DIR}/samba
   cache directory = ${JOB_TMP_DIR}/samba/cache
   private dir = ${JOB_TMP_DIR}/samba/private
   ncalrpc dir = ${JOB_TMP_DIR}/samba/ncalrpc
   usershare allow guests = yes
   guest account = $SLURM_JOB_USER
   enable core files = yes
   restrict anonymous = no
   allow insecure wide links = yes

[home]
   path = /uufs/chpc.utah.edu/common/home/$USER
   read only = no
   guest ok = yes
   guest only = yes
   create mask = 0777
   directory mask = 0777

[scratch]
   path = /scratch/general/vast/$USER
   read only = no
   guest ok = yes
   guest only = yes
   create mask = 0777
   directory mask = 0777

EOL

#Now to add group shares
for sd in $SMBCONF;
do cat >> ${script_path}/smb.conf <<EOL
[$(basename ${sd})]
   path = ${sd}
   read only = no
   guest ok = yes
   guest only = yes
   create mask = 0777
   directory mask = 0777
   browsable = yes

EOL

done

while true; do
    echo "SAMBA.SH:  $(date): Starting smbd..."

    if [[ $(</proc/sys/crypto/fips_enabled) == 1 ]]
    then
	echo "SAMBA.SH:  Preload launching smbd..."
	# Launch smbd such that it is not aware of FIPS mode
        LD_PRELOAD=/uufs/chpc.utah.edu/sys/installdir/r8/apache_guacamole/gnutls_fips_override/gnutls_fips_override.so smbd --configfile=${script_path}/smb.conf --no-process-group --foreground --debug-stdout
    else
	echo "SAMBA.SH: native smbd..."
	# Launch smbd normally
        smbd --configfile=${script_path}/smb.conf --no-process-group --foreground --debug-stdout
    fi
    # Check the exit status
    exit_status=$?
    echo "SAMBA.SH:  $(date): smbd exited with status $exit_status"

    # Optional: add a short delay before restarting to prevent rapid restart loops
    sleep 1

    echo "SAMBA.SH:  $(date): Restarting smbd..."
done &
disown

