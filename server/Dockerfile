# ==============================================================================
# Object Vision — Server (Backend Only)
# Framework: framework-server
# Workspace: server-object-vision
# OS: Ubuntu 24.04 LTS | Node.js 18.17.1
# ==============================================================================

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies and build tools (needed for native modules like ffi-napi)
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    xz-utils \
    python3 \
    python3-setuptools \
    make \
    g++ \
    pkg-config \
    libffi-dev \
    libcairo2-dev \
    libpango1.0-dev \
    libjpeg-dev \
    libgif-dev \
    librsvg2-dev \
    libpixman-1-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 18.17.1
ARG TARGETARCH
RUN ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "x64") && \
    curl -fsSL https://nodejs.org/dist/v18.17.1/node-v18.17.1-linux-${ARCH}.tar.xz | \
    tar -xJ -C /usr/local --strip-components=1 && \
    node --version && npm --version

WORKDIR /app

# Set custom Advantech npm registry
ARG NPM_REGISTRY=http://172.22.135.200:55000/
RUN npm config set registry ${NPM_REGISTRY}

# Copy framework-server (base framework)
COPY framework-server/ ./

# Copy server-object-vision as workspace/
COPY server-object-vision/ ./workspace/

# Install framework dependencies
RUN npm install --production

# Install additional workspace dependencies from server-object-vision
RUN npm install --save \
    @advantech/server-service-draw@^1.3.0 \
    @advantech/server-service-email@^1.3.0 \
    @advantech/server-service-websocket@^1.5.2 \
    @advantech/service-regex@^1.8.0 \
    axios@^1.4.0 \
    exceljs@^4.3.0 \
    firebase-admin@^13.1.0 \
    form-data@^4.0.0 \
    socket.io-client@^4.8.1 \
    xml2js@^0.4.23

# Remove build tools to reduce image size
RUN apt-get purge -y python3 python3-setuptools make g++ && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Create empty web directory to prevent Express static middleware errors
# (frontend is served by nginx, not this container)
RUN mkdir -p workspace/custom/web

# Only expose HTTP port (nginx handles external traffic and SSL)
EXPOSE 6090

ENV NODE_ENV=production

CMD ["npm", "start"]
