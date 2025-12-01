# ============================================================================
# Multi-stage build for optimized production image
# Optimizations applied:
# - Layer caching for faster rebuilds
# - Minimal alpine base image
# - Production dependencies only in final image
# - Non-root user for security
# - Optimized npm install with ci
# - Cache cleaning and file pruning
# ============================================================================

# Stage 1: Dependencies (cached separately for faster rebuilds)
FROM node:18-alpine AS dependencies

WORKDIR /app

# Copy only package files (better layer caching)
COPY package*.json ./

# Install ALL dependencies (needed for build)
# Using npm install (npm ci requires package-lock.json)
RUN npm install --prefer-offline --no-audit --progress=false && \
    npm cache clean --force

# Stage 2: Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copy dependencies from previous stage
COPY --from=dependencies /app/node_modules ./node_modules
COPY package*.json ./
COPY tsconfig.json ./

# Copy source code
COPY src ./src

# Build TypeScript to JavaScript
RUN npm run build && \
    # Remove source maps in production build for smaller size
    find dist -name '*.map' -delete

# Stage 3: Production dependencies
FROM node:18-alpine AS prod-dependencies

WORKDIR /app

COPY package*.json ./

# Install only production dependencies
RUN npm install --only=production --prefer-offline --no-audit --progress=false && \
    npm cache clean --force && \
    # Remove unnecessary files to reduce image size
    rm -rf /tmp/* /root/.npm

# Stage 4: Production runtime (minimal final image)
FROM node:18-alpine AS production

# Install only required system packages
RUN apk add --no-cache tini && \
    # Create non-root user for security
    addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 && \
    # Create app directory with correct permissions
    mkdir -p /app && \
    chown -R nodejs:nodejs /app

WORKDIR /app

# Copy production dependencies
COPY --from=prod-dependencies --chown=nodejs:nodejs /app/node_modules ./node_modules

# Copy package.json for version info
COPY --chown=nodejs:nodejs package*.json ./

# Copy built application from builder stage
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist

# Switch to non-root user
USER nodejs

# Expose backend port
EXPOSE 3847

# Add labels for better image management
LABEL maintainer="DevOps Team" \
      service="backend" \
      version="1.0.0" \
      description="E-commerce Backend Service"

# Health check with optimized settings
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3847/api/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Use tini as init system to handle signals properly
ENTRYPOINT ["/sbin/tini", "--"]

# Start the application
CMD ["node", "--max-old-space-size=512", "dist/index.js"]
