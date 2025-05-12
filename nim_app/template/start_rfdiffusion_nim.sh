#!/bin/bash

echo Starting RFDiffusion NIM on port $1
ml apptainer
set -x
export APPTAINER_DOCKER_USERNAME='$oauthtoken'
if [ -z "${1}" ]; then
  export NGC_API_KEY=$2
else
  export NGC_API_KEY=ajMzaHZmMDdmZzNjYXNvanYzOG41NTZpOHU6MDM5NjY4ZGItMjQxYS00ODk5LTg3NWMtMGVjZGI1NDcxMjFl
fi
export APPTAINER_DOCKER_PASSWORD=$NGC_API_KEY


apptainer run --nv -e -B /scratch/general/vast/app-repo/nim/nvs:/home/nvs -B /scratch/general/vast/app-repo/nim:/opt/nim/.cache -B /scratch/general/vast/app-repo/nim/workspace:/opt/nim/workspace --env NGC_API_KEY=$NGC_API_KEY,DOCKER_USERNAME='\$oauthtoken',NIM_CACHE_PATH=/home/nvs/.cache/nim/models,NIM_HTTP_API_PORT=$1,CUDA_VISIBLE_DEVICES=0 /uufs/chpc.utah.edu/sys/installdir/r8/nim/rfdiffusion_2.0.sif
