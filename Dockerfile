# Use Ubuntu minimal as base image for better package management support
# Support both AMD64 and ARM64 architectures
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Create a non-root user for security
RUN groupadd -r rovodev && useradd -r -g rovodev -m -s /bin/bash rovodev

# Install essential packages and dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    build-essential \
    python3 \
    python3-pip \
    nodejs \
    npm \
    jq \
    vim \
    nano \
    sudo \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# Install Docker
RUN apt-get update && \
    apt-get install -y apt-transport-https && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin && \
    rm -rf /var/lib/apt/lists/*

# Install acli (Atlassian CLI) with architecture detection
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        ACLI_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        ACLI_ARCH="arm64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    echo "Downloading acli for architecture: $ACLI_ARCH" && \
    curl -LO "https://acli.atlassian.com/linux/latest/acli_linux_${ACLI_ARCH}/acli" && \
    chmod +x ./acli && \
    mv ./acli /usr/local/bin/acli && \
    echo "acli installed successfully for $ACLI_ARCH"

# Create workspace directory with proper permissions
RUN mkdir -p /workspace && chown rovodev:rovodev /workspace

# Create persistence directory with proper permissions
RUN mkdir -p /persistence && chown rovodev:rovodev /persistence

# Create config directory for acli
RUN mkdir -p /home/rovodev/.config/acli && chown -R rovodev:rovodev /home/rovodev/.config

# Create SSH directory for the user
RUN mkdir -p /home/rovodev/.ssh && chmod 700 /home/rovodev/.ssh && chown -R rovodev:rovodev /home/rovodev/.ssh


# Add rovodev user to sudoers for package installation
RUN echo "rovodev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Add rovodev user to the docker group to allow running docker commands without sudo
# Note: The Docker socket permissions are also fixed in entrypoint.sh to ensure proper access
RUN groupadd -f docker && usermod -aG docker rovodev

# Copy entrypoint script
COPY entrypoint.sh /home/rovodev/entrypoint.sh

# Create init folder
RUN mkdir -p /init
COPY ./init /init

# Make entrypoint script executable and set proper ownership
USER root
RUN chmod +x /home/rovodev/entrypoint.sh && chown rovodev:rovodev /home/rovodev/entrypoint.sh

# Switch to non-root user
USER rovodev

# Set working directory
WORKDIR /workspace

# Set entrypoint
ENTRYPOINT ["/home/rovodev/entrypoint.sh"]

# Default command (interactive shell)
CMD []

# Add labels for better container management
LABEL maintainer="rovodev-user"
LABEL description="Atlassian CLI with rovodev utility and Docker support - auto-launches AI assistant"
LABEL version="2.2"