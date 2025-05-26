# @author madebycm (2025-01-26)
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    nano \
    vim \
    curl \
    wget \
    git \
    build-essential \
    python3 \
    python3-pip \
    net-tools \
    iputils-ping \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Set root password
RUN echo 'root:123' | chpasswd

# Create sandbox user with persistent home
RUN useradd -m -s /bin/bash -u 1000 -g users sandbox && \
    echo 'sandbox ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Create directories for persistent storage
RUN mkdir -p /workspace /etc/sandbox /usr/local && \
    chown -R sandbox:users /workspace

# Set up profile to source shared configs
RUN echo 'if [ -f /etc/sandbox/profile ]; then . /etc/sandbox/profile; fi' >> /etc/bash.bashrc

# Set proper permissions for shared directories
RUN chown -R sandbox:users /usr/local /opt && \
    chmod -R 755 /usr/local /opt

WORKDIR /root

USER root

CMD ["/bin/bash"]