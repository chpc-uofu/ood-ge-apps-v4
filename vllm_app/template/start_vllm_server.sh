#!/bin/bash

echo Starting vLLM on port $1
#ml apptainer/1.4.1
set -x

#need to create user-specified scratch dir if it does not already exist
echo $SCRATCH_DIR $TASK_CHOICE
# mkdir -p $SCRATCH_DIR
# export HUGGINGFACE_HUB_CACHE=~/hh_cache
# mkdir -p $HUGGINGFACE_HUB_CACHE
# Note we have to set HF_HOME to the directory inside the container which then is bound outside

# Below line works with model=NousResearch/Meta-Llama-3-8B-Instruct
# and SCRATCH_DIR=/scratch/general/vast/u6040150/vllm_cache

# PROBLEM - so far there does not seem to be a one size fits all way to get VLLM to use a specified
# cache dir. This snippet works for HF auth models but not others:
# --env HF_HOME=/root/.cache/huggingface --bind ${SCRATCH_DIR}:/root/.cache/huggingface

# 1-12-26 - VLLM now requires a chat template file for models that do chat. This is a separate file so we want
# to use it if we have one.
if [ -e $MODEL/chat_template.jinja ]; then
apptainer run --nv -e --fakeroot --env HF_HOME=/root/.cache/ --bind ${SCRATCH_DIR}:/root/.cache  /uufs/chpc.utah.edu/sys/installdir/r8/vllm/vllm_current_cuda_sif_link $MODEL  --host=localhost --port=$nimport --chat-template $MODEL/chat_template.jinja
else
apptainer run --nv -e --fakeroot --env HF_HOME=/root/.cache/ --bind ${SCRATCH_DIR}:/root/.cache  /uufs/chpc.utah.edu/sys/installdir/r8/vllm/vllm_current_cuda_sif_link $MODEL  --host=localhost --port=$nimport 
fi
# --hf-token=$HUGGINGFACE_TOKEN
# --download_dir=$SCRATCH_DIR 
# --task $TASK_CHOICE

