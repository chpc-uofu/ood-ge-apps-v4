# for podman build on ondemand-stagning
#export LICENSE_ID=xxxxxxx
#podman build --build-arg LICENSE_ID=$LICENSE_ID -t cryosparc:4.7.1 .


FROM nvidia/cuda:12.8.1-devel-ubuntu22.04

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
        nvidia-driver-580 \
        nvidia-dkms-580 && \
        rm -rf /var/lib/apt/lists/*

RUN which nvidia-smi
RUN gcc --version && nvcc -V && nvcc --list-gpu-code

ENV no_proxy=localhost,127.0.0.0/8
ENV PATH=/cryosparc_master/bin:/cryosparc_worker/bin:${PATH}

ARG LICENSE_ID
ENV LICENSE_ID=${LICENSE_ID}

RUN --mount=type=bind,source=.,target=/mnt \
    bash /mnt/install_cryosparc_v4.7.1.sh

#RUN bash /mnt/install_cryosparc_v4.7.1.sh


