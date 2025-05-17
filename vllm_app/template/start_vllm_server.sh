#!/bin/bash

echo Starting vLLM on port $1
ml apptainer
set -x
#export APPTAINER_DOCKER_USERNAME='$oauthtoken'
# if [ -z "${1}" ]; then
#  export NGC_API_KEY=$2
#else
#  export NGC_API_KEY=ajMzaHZmMDdmZzNjYXNvanYzOG41NTZpOHU6MDM5NjY4ZGItMjQxYS00ODk5LTg3NWMtMGVjZGI1NDcxMjFl
#fi
export SERVER_PORT=$1
export LLM_MODEL=$2
export HUGGINGFACE_TOKEN=$3
# see https://docs.nvidia.com/nim/large-language-models/latest/configuration.html
apptainer run --nv -e -B /scratch/general/vast/$USER/vllm_cache:/root/.cache/huggingface  /uufs/chpc.utah.edu/sys/installdir/r8/vllm/vllm-0.8.5p1.sif --host=localhost --port=$SERVER_PORT --model=$LLM_MODEL --hf-token=$HUGGINGFACE_TOKEN
