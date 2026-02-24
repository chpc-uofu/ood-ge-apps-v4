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

mkdir -p /scratch/general/vast/$USER/nim/nvs
mkdir -p /scratch/general/vast/$USER/nim/af2/workspace

apptainer run --nv -e -B /scratch/general/vast/$USER/nim/nvs:/home/nvs -B /scratch/general/vast/app-repo/nim:/opt/nim/.cache -B /scratch/general/vast/$USER/nim/af2/workspace:/opt/nim/workspace --env NGC_API_KEY=$NGC_API_KEY,DOCKER_USERNAME='\$oauthtoken',NIM_HTTP_API_PORT=8081,CUDA_VISIBLE_DEVICES=0,NIM_PARALLEL_MSA_RUNNERS=3,NIM_PARALLEL_THREADS_PER_MSA=12,NIM_CACHE_PATH=/opt/nim/.cache,NIM_DISABLE_MODEL_DOWNLOAD=True /uufs/chpc.utah.edu/sys/installdir/r8/nim/alphafold2_2.1.sif

