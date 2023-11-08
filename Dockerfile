FROM ubuntu:jammy

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y wget gettext apt-transport-https ca-certificates curl gnupg2 software-properties-common tar git openssl gzip unzip python3 python3-pip\
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

## Helm Tiller
RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash && \
    helm version --client

## Kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl


## Docker Binaries
ARG DOCKER=20.10.5
RUN curl https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER}.tgz > docker.tar.gz && tar xzvf docker.tar.gz -C /usr/local/bin/ --strip-components=1 && \
    rm docker.tar.gz && \
    docker -v

## Docker Compose
ARG DOCKER_COMPOSE=1.27.4
RUN curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE}/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose && \
    docker-compose -v

# Google Cloud CLI
RUN echo "deb http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    apt-get update && apt-get install -y google-cloud-sdk google-cloud-sdk-gke-gcloud-auth-plugin \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

## AWS CLI
RUN pip3 install awscli --upgrade && \
    aws --version

## AWS EKS Ctl \
RUN curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp && \
    mv /tmp/eksctl /usr/local/bin && \
    eksctl version

## AWS ECR credential helper
RUN apt-get update && apt-get install -y amazon-ecr-credential-helper && \
    docker-credential-ecr-login -v && \
    apt-get autoclean && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

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
