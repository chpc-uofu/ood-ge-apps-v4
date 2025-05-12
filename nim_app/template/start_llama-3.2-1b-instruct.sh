#!/bin/bash

echo Starting Llama3.2 NIM on port $1
ml apptainer
set -x
export APPTAINER_DOCKER_USERNAME='$oauthtoken'
if [ -z "${1}" ]; then
  export NGC_API_KEY=$2
else
  export NGC_API_KEY=ajMzaHZmMDdmZzNjYXNvanYzOG41NTZpOHU6MDM5NjY4ZGItMjQxYS00ODk5LTg3NWMtMGVjZGI1NDcxMjFl
fi
export APPTAINER_DOCKER_PASSWORD=$NGC_API_KEY

# see https://docs.nvidia.com/nim/large-language-models/latest/configuration.html

mkdir -p /scratch/general/vast/$USER/tmp

apptainer run --nv -e -B /scratch/general/vast/app-repo/nim:/opt/nim/.cache,/scratch/general/vast/$USER/tmp:/tmp --env NGC_API_KEY=$NGC_API_KEY,DOCKER_USERNAME='\$oauthtoken',NIM_SERVER_PORT=$1 /uufs/chpc.utah.edu/sys/installdir/r8/nim/llama-3.2-1b-instruct_1.0.0.sif
