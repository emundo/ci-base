FROM ubuntu:rolling

RUN apt-get update && apt-get install -y wget apt-transport-https ca-certificates curl gnupg2 software-properties-common tar git openssl gzip unzip\
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

## Helm Tiller
RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get | bash && \
    helm version --client && \
    tiller -version

## Kubectl
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update && apt-get install -y kubectl \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

## Docker Binaries
ARG DOCKER=19.03.2
RUN curl https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER}.tgz > docker.tar.gz && tar xzvf docker.tar.gz -C /usr/local/bin/ --strip-components=1 && \
    rm docker.tar.gz && \
    docker -v

## Docker Compose
ARG DOCKER_COMPOSE=1.24.1
RUN curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE}/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose && \
    docker-compose -v

# Google Cloud CLI
RUN export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
    echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    apt-get update && apt-get install -y google-cloud-sdk \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

## Rancher Compose
RUN curl -L https://github.com/rancher/rancher-compose/releases/download/v0.12.5/rancher-compose-linux-amd64-v0.12.5.tar.xz | tar xJvf -  --strip-components=2 -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/rancher-compose && \
    rancher-compose --version

# Standard Encoding von ASCII auf UTF-8 stellen
ENV LANG C.UTF-8

## emundo User
RUN addgroup --gid 1101 rancher && \
    # Für RancherOS brauchen wir diese Gruppe: http://rancher.com/docs/os/v1.1/en/system-services/custom-system-services/#creating-your-own-console
    addgroup --gid 999 aws && \
    # Für die AWS brauchen wir diese Gruppe
    useradd -ms /bin/bash emundo && \
    adduser emundo sudo && \
    # Das ist notwendig, damit Docker in Docker in RancherOS funktioniert
    usermod -aG 999 emundo && \
    # Das ist notwendig, damit Docker in Docker in AWS Ubuntu funktioniert
    usermod -aG 1101 emundo && \
    # Das ist notwendig, damit Docker in Docker lokal funktioniert
    usermod -aG sudo emundo
