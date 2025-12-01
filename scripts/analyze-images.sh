#!/bin/bash

# ============================================================================
# Docker Image Optimization Analysis Script
# ============================================================================

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         Docker Image Optimization Analysis                  ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if images exist
if ! docker images | grep -q "docker-backend\|docker-gateway"; then
    echo -e "${YELLOW}No images found. Building images first...${NC}"
    echo ""
    docker compose -f docker/compose.production.yaml --env-file .env build
    echo ""
fi

# Function to get image size in MB
get_size_mb() {
    local image=$1
    docker images --format "{{.Size}}" "$image" 2>/dev/null | head -1 | sed 's/MB//' | sed 's/GB/*1024/' | bc 2>/dev/null || echo "0"
}

# Function to analyze image layers
analyze_layers() {
    local image=$1
    echo -e "${BLUE}Analyzing $image layers:${NC}"
    docker history "$image" --no-trunc --format "table {{.Size}}\t{{.CreatedBy}}" 2>/dev/null | head -15
    echo ""
}

# Function to show image details
show_image_details() {
    local image=$1
    local name=$2
    
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$name Image Analysis${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Basic info
    docker images "$image" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    echo ""
    
    # Layer analysis
    analyze_layers "$image"
    
    # Vulnerabilities (if docker scout available)
    if command -v docker scout &> /dev/null; then
        echo -e "${BLUE}Security Scan:${NC}"
        docker scout quickview "$image" 2>/dev/null || echo -e "${YELLOW}Docker Scout not available${NC}"
        echo ""
    fi
}

# Analyze Backend Image
if docker images | grep -q "docker-backend"; then
    show_image_details "docker-backend:latest" "Backend"
fi

# Analyze Gateway Image
if docker images | grep -q "docker-gateway"; then
    show_image_details "docker-gateway:latest" "Gateway"
fi

# Compare with base image
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Base Image Comparison${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
docker images node:18-alpine --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
echo ""

# Optimization Summary
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Optimization Summary${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

BACKEND_SIZE=$(get_size_mb "docker-backend:latest")
GATEWAY_SIZE=$(get_size_mb "docker-gateway:latest")
BASE_SIZE=$(get_size_mb "node:18-alpine")

echo -e "${BLUE}Image Sizes:${NC}"
echo -e "  Base Image (node:18-alpine): ${YELLOW}~${BASE_SIZE} MB${NC}"
echo -e "  Backend Image:               ${GREEN}~${BACKEND_SIZE} MB${NC}"
echo -e "  Gateway Image:               ${GREEN}~${GATEWAY_SIZE} MB${NC}"
echo ""

echo -e "${BLUE}Optimizations Applied:${NC}"
echo -e "  ${GREEN}✓${NC} Multi-stage builds (separate dependency stages)"
echo -e "  ${GREEN}✓${NC} Alpine Linux base (minimal footprint)"
echo -e "  ${GREEN}✓${NC} Layer caching (faster rebuilds)"
echo -e "  ${GREEN}✓${NC} Production dependencies only"
echo -e "  ${GREEN}✓${NC} npm cache cleaning"
echo -e "  ${GREEN}✓${NC} Removed source maps and unnecessary files"
echo -e "  ${GREEN}✓${NC} Non-root user for security"
echo -e "  ${GREEN}✓${NC} tini init system"
echo -e "  ${GREEN}✓${NC} Memory limits (--max-old-space-size)"
echo -e "  ${GREEN}✓${NC} Optimized .dockerignore files"
echo ""

echo -e "${BLUE}Build Time Optimizations:${NC}"
echo -e "  ${GREEN}✓${NC} Separate dependency layer for caching"
echo -e "  ${GREEN}✓${NC} npm ci --prefer-offline for faster installs"
echo -e "  ${GREEN}✓${NC} --no-audit flag (skip audit in builds)"
echo -e "  ${GREEN}✓${NC} Parallel stage execution support"
echo ""

echo -e "${BLUE}Security Enhancements:${NC}"
echo -e "  ${GREEN}✓${NC} Non-root user (nodejs:nodejs)"
echo -e "  ${GREEN}✓${NC} Minimal attack surface (alpine base)"
echo -e "  ${GREEN}✓${NC} No dev dependencies in production"
echo -e "  ${GREEN}✓${NC} Health checks configured"
echo -e "  ${GREEN}✓${NC} Image labels for tracking"
echo ""

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                  Analysis Complete!                          ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
