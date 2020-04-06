FROM ubuntu:18.04

# To make it easier for build and release pipelines to run apt-get,
# configure apt to not require confirmation (assume the -y argument by default)
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

# Moved some basic tools in the base image from the microsoft "standard"

RUN \
 apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
 && apt-add-repository ppa:git-core/ppa \
 && add-apt-repository ppa:deadsnakes/ppa \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    curl \
    dnsutils \
    netcat \
    file \
    ftp \
    git \
    iproute2 \
    iputils-ping \
    jq \
    locales \
    openssh-client \
    rsync\
    shellcheck \
    sudo \
    telnet \
    time \
    unzip \
    wget \
    zip \
    tzdata \
    libunwind8 \
    libicu60 \
    locales \
    build-essential \
    python3.7 \
    python3-pip \
    python3-venv \
 && rm -rf /var/lib/apt/lists/*

# Install setup tools
RUN python3 -m pip install --upgrade setuptools

# Install dbt
RUN python3 -m pip install dbt-snowflake snowflake-connector-python

# Install azure-storage-blob
RUN python3 -m pip install --upgrade azure-storage-blob azure-storage azure-storage-common

#Setup VENV
RUN python3 -m venv ~/.venv/dbt_runner && python3 -m venv ~/.venv/dbt_docs_uploader

#Install dbt runner Dependencies
RUN . ~/.venv/dbt_runner/bin/activate && pip install dbt-snowflake && deactivate

#Install dbt doc uploader Dependencies
RUN . ~/.venv/dbt_docs_uploader/bin/activate && pip install azure-storage-blob && deactivate

# Setup the locale
ENV LANG en_US.UTF-8
ENV LC_ALL $LANG
RUN locale-gen $LANG && update-locale

# Download and install git-lfs (installing from packagecloud did not work well for me)
RUN curl -sLO https://github.com/git-lfs/git-lfs/releases/download/v2.5.1/git-lfs-linux-amd64-v2.5.1.tar.gz \
    && mkdir git-lfs && tar zxvf git-lfs-linux-amd64-v2.5.1.tar.gz -C git-lfs \
    && mv git-lfs/git-lfs /usr/bin/ \
    && rm -rf git-lfs \
    && rm -rf git-lfs-linux-amd64-v2.5.1.tar.gz

# Accept the TEE EULA
RUN mkdir -p "/root/.microsoft/Team Foundation/4.0/Configuration/TEE-Mementos" \
 && cd "/root/.microsoft/Team Foundation/4.0/Configuration/TEE-Mementos" \
 && echo '<ProductIdData><eula-14.0 value="true"/></ProductIdData>' > "com.microsoft.tfs.client.productid.xml"

RUN alias python='python3'

WORKDIR /vsts

COPY ./start.sh .
RUN chmod +x start.sh

CMD ["./start.sh"]
