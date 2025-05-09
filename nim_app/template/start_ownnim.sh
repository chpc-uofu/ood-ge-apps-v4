#!/bin/bash

echo Starting NIM $2 on port $1
ml apptainer
set -x
export APPTAINER_DOCKER_USERNAME='$oauthtoken'
if [ -z "${1}" ]; then
  export NGC_API_KEY=$3
else
  export NGC_API_KEY=ajMzaHZmMDdmZzNjYXNvanYzOG41NTZpOHU6MDM5NjY4ZGItMjQxYS00ODk5LTg3NWMtMGVjZGI1NDcxMjFl
fi
export APPTAINER_DOCKER_PASSWORD=$NGC_API_KEY

mkdir -p /scratch/general/vast/$USER/nim/.cache
mkdir -p /scratch/general/vast/$USER/nim/nvs
mkdir -p /scratch/general/vast/$USER/nim/workspace

apptainer run --nv -e -B /scratch/general/vast/$USER/nim/nvs:/home/nvs -B /scratch/general/vast/$USER/nim/.cache:/opt/nim/.cache -B /scratch/general/vast/$USER/nim/workspace:/opt/nim/workspace  --env NGC_API_KEY=$NGC_API_KEY,DOCKER_USERNAME='\$oauthtoken',NIM_HTTP_API_PORT=$1,NIM_SERVER_PORT=$1 $2
