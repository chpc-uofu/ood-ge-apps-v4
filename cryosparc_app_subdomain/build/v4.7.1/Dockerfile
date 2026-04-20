# For podman build on ondemand-stagning
# Cryosparc installtion expect to see GPU during
# If the host has NO GPU, the installation will fail at Worker connecting to Master step
# a fallback is in place to manually connect Worker to Master without GPU
# See install_cryosparc_v4.7.1.sh

# Clean up storage for podman build
# podman ps -a
# podman container prune
# podman image prune

## check all buildah/external containers
# podman ps --all --external
# podman rm -f XXXX XXXX XXXX

## Podman build
# export LICENSE_ID=xxxxxxx
# podman build --build-arg LICENSE_ID=$LICENSE_ID -t cryosparc:4.7.1 .
# podman build --build-arg LICENSE_ID=$LICENSE_ID -t cryosparc:4.7.1 -f Dockerfile_runtime 2>&1 | tee build.log


## Convert podman/docker image to apptainer image
# podman save -o image.tar --format oci-archive image:tag
# apptainer build image.sif oci-archive:image.tar
# or
# podman save -o myimage.tar --format docker-archive myimage:tag
# apptainer build myimage.sif docker-archive:myimage.tar


FROM docker.io/nvidia/cuda:12.8.1-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Denver

RUN apt-get update && \
    apt-get upgrade -y && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    apt-get install -y --no-install-recommends \
        keyboard-configuration \
        tzdata \
        locales \
        language-pack-en \
        gnupg2 \
        openssh-server \
        openssh-client \
        ssh-askpass \
        lbzip2 \
        zip \
        software-properties-common \
        wget \
        curl \
        less \
        jq \
        iputils-ping \
        nano \
        vim && \
        rm -rf /var/lib/apt/lists/*


ENV no_proxy=localhost,127.0.0.0/8
ENV PATH=/cryosparc_master/bin:/cryosparc_worker/bin:${PATH}

ARG LICENSE_ID
ENV LICENSE_ID=${LICENSE_ID}
RUN echo "License ID: ${LICENSE_ID}"

RUN --mount=type=bind,source=.,target=/mnt \
    bash /mnt/install_cryosparc_v4.7.1.sh
