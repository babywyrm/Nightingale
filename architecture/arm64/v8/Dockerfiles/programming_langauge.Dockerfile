# Use build arguments for platform
ARG TARGETPLATFORM=linux/arm64/v8
ARG RUBY=slim

# Stage 1: Base stage
FROM --platform=$TARGETPLATFORM debian:stable-slim AS base

# Install common dependencies
RUN apt-get update -y --fix-missing && \
    apt-get install -y --no-install-recommends \
    wget \
    tar \
    make \
    gcc \
    ca-certificates \
    software-properties-common \
    build-essential

# Stage 2: Python 2 stage
# Removed Python 2 stage as it is deprecated and not recommended for use.
# FROM python:3.13-slim AS python2 

# Stage 3: Python 3 stage
FROM python:3.13.5-slim AS python3

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3-full \
    python3-pip \
    python3-venv \
    python3-dev \
    python3-openssl \
    python3-distutils && \
    python3 -m venv /opt/venv3 && \
    pip install --upgrade pip && \
    pip install setuptools && \
    pip install pipx

# Stage 4: Ruby stage
FROM --platform=$TARGETPLATFORM ruby:$RUBY AS ruby-builder

RUN gem install nokogiri

# Stage 5: Build Go dependencies
FROM base AS go-builder
WORKDIR /home
RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    wget -q https://go.dev/dl/go1.23.2.linux-arm64.tar.gz -O go.tar.gz && \
    tar -C /usr/local -xzf go.tar.gz && \
    rm go.tar.gz

# Stage 6: Java stage (ARM64)
FROM --platform=$TARGETPLATFORM openjdk:26-jdk-oracle AS java

# Stage 7: Final stage
FROM --platform=$TARGETPLATFORM debian:stable-slim AS final

COPY configuration/nodejs-env/node-installation-script.sh /temp/node-installation-script.sh

RUN apt-get update -y --fix-missing && \
    apt-get install -y --no-install-recommends \
    wget \
    unzip \
    tar \
    make \
    gcc \
    cmake \
    software-properties-common \
    build-essential \
    libcurl4-openssl-dev \
    libexpat1-dev \
    libguava-java \
    libiconv-hook1 \
    libiconv-hook-dev \
    libjson-c-dev \
    liblzma-dev \
    libpcap-dev \
    libpq-dev \
    libruby \
    libsmali-java \
    libsqlite3-dev \
    libssl-dev \
    libstringtemplate-java \
    libwebsockets-dev \
    libwww-perl \
    libxmlunit-java \
    libxpp3-java \
    libyaml-snake-java \
    libz-dev \
    linux-libc-dev \
    libev4 \
    libffi-dev \
    libbz2-dev \
    libreadline-dev \
    llvm \
    libncurses5-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    python3-full \
    python3-pip \
    python3-venv \
    python3-dev \
    python3-openssl \
    python3-distutils \
    pipx


# Copy necessary files from other stages
# Removed Python 2 environment variable as it is deprecated
# COPY --from=python2 /usr/local/bin/python2.7 /usr/local/bin/python2.7
COPY --from=python3 /usr/bin/python3 /usr/bin/python3
COPY --from=python3 /opt/venv3 /opt/venv3
COPY --from=go-builder /usr/local/go /usr/local/go
COPY --from=go-builder /home /home
COPY --from=java /usr/java/openjdk-26 /usr/java/openjdk-26

RUN apt-get update && \
    apt-get install -y --no-install-recommends default-jdk && \
    rm -rf /var/lib/apt/lists/*

# Set environment variables
# Removed Python 2 environment variable as it is deprecated
# ENV PYTHON2="/usr/local/bin/python2.7"
ENV PYTHON3="/usr/bin/python3"
ENV GOROOT="/usr/local/go"
ENV GOPATH="/home/go"
ENV JAVA_HOME="/usr/local/openjdk-26"
ENV PATH="$GOPATH/bin:$GOROOT/bin:$PYTHON3:$JAVA_HOME:$PATH"