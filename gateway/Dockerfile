# ============================================================================
# Optimized Production Dockerfile for Gateway
# Optimizations applied:
# - Multi-stage build for layer caching
# - Minimal alpine base image
# - Production dependencies only
# - Non-root user for security
# - Optimized npm install
# - Cache cleaning and file pruning
# ============================================================================

# Stage 1: Dependencies
FROM node:18-alpine AS dependencies

WORKDIR /app

# Copy only package files for better layer caching
COPY package*.json ./

# Install production dependencies only
RUN npm install --only=production --prefer-offline --no-audit --progress=false && \
    npm cache clean --force && \
    # Remove unnecessary files
    rm -rf /tmp/* /root/.npm

# Stage 2: Production runtime
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

# Copy production dependencies from previous stage
COPY --from=dependencies --chown=nodejs:nodejs /app/node_modules ./node_modules

# Copy package.json for version info
COPY --chown=nodejs:nodejs package*.json ./

# Copy application source code
COPY --chown=nodejs:nodejs src ./src

# Switch to non-root user
USER nodejs

# Expose gateway port
EXPOSE 5921

# Add labels for better image management
LABEL maintainer="DevOps Team" \
      service="gateway" \
      version="1.0.0" \
      description="API Gateway Service"

# Health check with optimized settings
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD node -e "require('http').get('http://localhost:5921/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Use tini as init system to handle signals properly
ENTRYPOINT ["/sbin/tini", "--"]

# Start the application with memory limit
CMD ["node", "--max-old-space-size=256", "src/gateway.js"]
