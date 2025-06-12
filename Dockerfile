FROM ubuntu:latest

# @author madebycm (2025-01-26)

# Install sudo, bash-completion, and other essential packages
RUN apt-get update && \
    apt-get install -y sudo bash-completion && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user with password
RUN useradd -m -s /bin/bash sBOX && \
    echo 'sBOX:123' | chpasswd && \
    usermod -aG sudo sBOX

# Configure sudo to not require password for sBOX
RUN echo 'sBOX ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Set working directory
WORKDIR /project

# Switch to non-root user
USER sBOX

# Default command
CMD ["/bin/bash"]