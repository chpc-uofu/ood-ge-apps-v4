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

apptainer run --nv -e -B /scratch/general/vast/u0101881/nvs:/home/nvs -B /scratch/general/vast/u0101881/nim:/opt/nim/.cache -B /scratch/general/vast/u0101881/nim/workspace:/opt/nim/workspace --env NGC_API_KEY=$NGC_API_KEY,DOCKER_USERNAME='\$oauthtoken',NIM_CACHE_PATH=/home/nvs/.cache/nim/models,NIM_HTTP_API_PORT=8082,CUDA_VISIBLE_DEVICES=0 -B /scratch/general/vast/u0101881/nvs/inputs:/opt/nim/inputs /uufs/chpc.utah.edu/common/home/u0101881/nvidia/nim//rfdiffusion_2.0.sif

