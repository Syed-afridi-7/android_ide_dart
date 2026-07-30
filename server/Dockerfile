FROM node:18-slim

# Install system tools for a productive terminal environment
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    wget \
    git \
    python3 \
    python3-pip \
    gcc \
    g++ \
    make \
    vim \
    nano \
    htop \
    tree \
    jq \
    unzip \
    openssh-client \
    ca-certificates \
    locales \
  && rm -rf /var/lib/apt/lists/* \
  && locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV TERM=xterm-256color

WORKDIR /app

# Copy package files and install dependencies
COPY package.json ./
RUN npm install --production

# Copy server code
COPY server.js ./

# Create a workspace directory for terminal users
RUN mkdir -p /home/workspace && chmod 777 /home/workspace

EXPOSE 8080

CMD ["node", "server.js"]
