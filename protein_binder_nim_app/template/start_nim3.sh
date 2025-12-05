#!/bin/bash

ml apptainer
set -x
export APPTAINER_DOCKER_USERNAME='$oauthtoken'
if [ -z "${1}" ]; then
  export NGC_API_KEY=$1
else
  export NGC_API_KEY=ajMzaHZmMDdmZzNjYXNvanYzOG41NTZpOHU6MDM5NjY4ZGItMjQxYS00ODk5LTg3NWMtMGVjZGI1NDcxMjFl
fi
export APPTAINER_DOCKER_PASSWORD=$NGC_API_KEY

apptainer run --fakeroot --nv -e -B /scratch/general/vast/app-repo/nim/nvs/.cache/nim/models:/home/nvs/.cache -B /scratch/general/vast/app-repo/nim/proteinmpnn/workspace:/opt/nim/workspace --env NIM_CACHE_PATH=/home/nvs/.cache/nim/models,NIM_HTTP_API_PORT=8083 /uufs/chpc.utah.edu/sys/installdir/r8/nim/proteinmpnn_1.0.sif
