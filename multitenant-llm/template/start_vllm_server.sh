#!/bin/bash

echo Starting vLLM on port $1
#ml apptainer/1.4.1
set -x

#need to create user-specified scratch dir if it does not already exist
mkdir -p $SCRATCH_DIR
# export HUGGINGFACE_HUB_CACHE=~/hh_cache
# mkdir -p $HUGGINGFACE_HUB_CACHE
# Note we have to set HF_HOME to the directory inside the container which then is bound outside

# PROBLEM - so far there does not seem to be a one size fits all way to get VLLM to use a specified
# cache dir. This snippet works for HF auth models but not others:
# --env HF_HOME=/root/.cache/huggingface --bind ${SCRATCH_DIR}:/root/.cache/huggingface
apptainer run --nv -e --fakeroot --env HF_HOME=/root/.cache/ --bind ${SCRATCH_DIR}:/root/.cache  /uufs/chpc.utah.edu/sys/installdir/r8/vllm/vllm-0.8.5p1.sif --host=localhost --port=$port --model=${ollama_models}${ollama_model} --task=$TASK_CHOICE

