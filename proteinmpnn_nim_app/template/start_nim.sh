#!/bin/bash

ml apptainer

apptainer run --fakeroot --nv -e -B /scratch/general/vast/u0101881/nvs/.cache/nim/models:/home/nvs/.cache -B /scratch/general/vast/u0101881/nim/proteinmpnn/workspace:/opt/nim/workspace --env NIM_CACHE_PATH=/home/nvs/.cache/nim/models,NIM_HTTP_API_PORT=8083 /uufs/chpc.utah.edu/common/home/u0101881/nvidia/nim//proteinmpnn_1.0.sif
