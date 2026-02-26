# ==============================================================================
# Object Vision Service
# Server v1.05.05 | Web v1.05.03
# OS: Ubuntu 24.04 LTS
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage 1: Build Web Frontend
# Framework: framework-web-iservice v3.3.0.5
# Src:       web-iservice-object-vision v1.05.03
# Node.js:   12.18.3
# Structure: framework / src
# ------------------------------------------------------------------------------
FROM node:12.18.3 AS web-builder

WORKDIR /build

# Set custom Advantech npm registry
ARG NPM_REGISTRY=http://172.22.135.200:55000/
RUN npm config set registry ${NPM_REGISTRY}

# Copy framework-web-iservice (base framework)
COPY framework-web-iservice/ ./

# Copy web-iservice-object-vision into src/ (project overlay)
COPY web-iservice-object-vision/ ./src/

# Sync frameworkversion in src/package.json to match the framework's version
# (initialization-check-version.js requires both to match exactly)
RUN FRAMEWORK_VER=$(node -e "console.log(require('./package.json').frameworkversion)") && \
    node -e " \
      const fs = require('fs'); \
      const pkg = JSON.parse(fs.readFileSync('./src/package.json','utf8')); \
      pkg.frameworkversion = '${FRAMEWORK_VER}'; \
      fs.writeFileSync('./src/package.json', JSON.stringify(pkg, null, 2)); \
    " && \
    echo "Synced src frameworkversion to ${FRAMEWORK_VER}"

# Install framework dependencies (including devDependencies for build)
RUN npm install

# Install additional workspace dependencies from web-iservice-object-vision
RUN npm install \
    @advantech/service-regex@^1.7.0 \
    exceljs@^4.3.0 \
    exif-js@^2.3.0 \
    file-saver@^2.0.5 \
    @types/file-saver@^2.0.5 \
    fabric@5.3.0 \
    vue-form-wizard@^0.8.4

# Build production bundle
RUN npm run build

# ------------------------------------------------------------------------------
# Stage 2: Server Runtime
# Framework:  framework-server v3.01.00
# Workspace:  server-object-vision v1.05.05
# Node.js:    18.17.1
# OS:         Ubuntu 24.04 LTS
# Structure:  framework / workspace
# ------------------------------------------------------------------------------
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

# Copy built web frontend from Stage 1 into workspace/custom/web/
COPY --from=web-builder /build/dist/ ./workspace/custom/web/

# HTTP and HTTPS ports (matching server-object-vision/config/default/core.ts)
EXPOSE 6090 4473

ENV NODE_ENV=production

CMD ["npm", "start"]
