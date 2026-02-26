# ==============================================================================
# Object Vision — Nginx + Frontend
# Frontend build: Node.js 12.18.3 (Vue 2)
# Runtime: nginx:1.27-alpine
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage 1: Build Web Frontend
# Framework: framework-web-iservice
# Src:       web-iservice-object-vision
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
# Stage 2: Nginx runtime
# ------------------------------------------------------------------------------
FROM nginx:1.27-alpine

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx config
COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf

# Copy built frontend from Stage 1
COPY --from=web-builder /build/dist/ /usr/share/nginx/html/

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
