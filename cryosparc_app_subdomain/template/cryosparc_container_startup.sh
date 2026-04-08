#!/usr/bin/env bash
set -x

echo "=== SLURM_JOB_ID: [$SLURM_JOB_ID]"
# SLURM_JOB_GPUS=0 if job lands on first GPU, and SLURM_JOB_GPUS=1 if job lands on second GPU. (both SLURM_STEP_GPUS=0,1)
echo "=== SLURM_JOB_GPUS [$SLURM_JOB_GPUS]"

user_cryosparc_directory=$USER_CRYOSPARC_DIRECTORY
echo $user_cryosparc_directory
first_launch=$FIRST_LAUNCH
echo $first_launch

#if [  "$first_launch" = true ]; then
#    tar xzf /cryosparc_master_run_init_files-v4.7.1.tar.gz -C $user_cryosparc_directory
#fi

# select a random number between 39100 and 39990
#cryo_port=39$(shuf -i 10-99 -n 1)0
cryo_port=$CRYOSPARC_BASE_PORT
echo $cryo_port

echo $CRYOSPARC_LICENSE_ID > $user_cryosparc_directory/cryosparc_license/license_id
chmod 600 $user_cryosparc_directory/cryosparc_license/license_id
echo $CRYOSPARC_LICENSE_ID

################################################################################
# TODO this ssdquota section is specific to HPRC, update as needed
ssdpath="$TMPDIR"
# use a max of 1.4TB for quota which is the size of the $TMPDIR
#ssdquota=1400000
#quotamax=1400000
#if [ $ssdquota -gt $quotamax ]; then
#    ssdquota=$quotamax
#fi
echo "=== Using ssdpath: $ssdpath with max quota (MB) $ssdquota"
################################################################################

# Start CryoSPARC Server
echo "=== Starting CryoSPARC"


nvidia-smi
nvidia-smi -L
nvidia-smi -a

nvidia='--nv'
usegpu="--gpus $CUDA_VISIBLE_DEVICES"
echo "=== CUDA_VISIBLE_DEVICES: $CUDA_VISIBLE_DEVICES"
echo "=== SLURM_JOB_GPUS: $SLURM_JOB_GPUS"


if [ "$first_launch" = true ]; then
    export FIRST_LAUNCH=false
    # first launch order of commands
    echo "=== initializing first launch"
    cryosparcm start
    sleep 10
    cryosparcm checkdb
    cryosparcm createuser \
      --email "${CRYOSPARC_ADMIN_EMAIL}" \
      --password "${CRYOSPARC_LICENSE_ID:0:4}" \
      --username "admin" \
      --firstname "admin" \
      --lastname "admin"
    sleep 10
else
    cryosparcm stop
    sleep 10
    cryosparcm start database
    sleep 10
#    $cryosparc_singularity_command cryosparcm mongo
#nc -zv localhost 39400
#nc -zv localhost 39401
    cryosparcm fixdbport
    sleep 10
    cryosparcm restart
    sleep 10
    # clear previous worker node
    remove_hosts.sh
    sleep 10
    cryosparcm status
    # # Count users in Mongo
    # USER_COUNT=$(cryosparcm mongo --eval "
    # db = db.getSiblingDB('meteor');
    # print(db.users.countDocuments({}));
    # " | tail -n1)

    # echo "User count: $USER_COUNT"

    # if [[ "$USER_COUNT" == "0" ]]; then
    #     echo "No users found — creating initial admin user"

    #     cryosparcm createuser \
    #   --email "admin@cryo.edu" \
    #   --password "admin" \
    #   --username "admin" \
    #   --firstname "admin" \
    #   --lastname "admin"

    #     cryosparcm makeuseradmin --email "${EMAIL}"

    #     echo "Admin user created"
    # else
    #     echo "Users already exist — skipping"
    # fi
fi

sleep 10
# connect current compute node
cryosparcw connect \
    --worker localhost \
    --master localhost \
    --port $cryo_port \
    --ssdpath /tmp \
    --cpus $SLURM_CPUS_ON_NODE \
    --lane default \
    --newlane \
    $usegpu

sleep 10

# update worker node with ssdquota since it doesn't work with the first connection command (maybe it does in newer versions)
cryosparcw connect \
    --cpus $SLURM_CPUS_ON_NODE \
    --port $cryo_port \
    --worker localhost \
    --master localhost \
    --update --ssdquota 50000

sleep 10
cryosparcm env
cryosparcm status

env | grep SLURM
env | grep APPTAINER

echo "${host}"
echo "cryosparc port $cryo_port"
#firefox --private-window localhost:$cryo_port

# echo "nginx port $NGINX_PORT"

# nginx -g "daemon off;"