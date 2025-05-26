FROM ubuntu:latest

# @author madebycm (2025-01-26)

# Install sudo and create user
RUN apt-get update && \
    apt-get install -y sudo && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user with password
RUN useradd -m -s /bin/bash developer && \
    echo 'developer:123' | chpasswd && \
    usermod -aG sudo developer

# Configure sudo to not require password for developer
RUN echo 'developer ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Set working directory
WORKDIR /project

# Switch to non-root user
USER developer

# Default command
CMD ["/bin/bash"]