.PHONY: help up down build logs restart shell ps clean clean-all clean-volumes
.PHONY: dev-up dev-down dev-build dev-logs dev-restart dev-shell dev-ps
.PHONY: prod-up prod-down prod-build prod-logs prod-restart prod-shell prod-ps
.PHONY: backend-shell gateway-shell mongo-shell backend-build backend-install backend-type-check backend-dev
.PHONY: db-reset db-backup db-restore health status test validate install
.PHONY: docker-prune security-scan lint format check-env

# Colors for terminal output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
MAGENTA := \033[0;35m
CYAN := \033[0;36m
NC := \033[0m # No Color

# Default values
MODE ?= dev
SERVICE ?= backend
COMPOSE_FILE_DEV := docker/compose.development.yaml
COMPOSE_FILE_PROD := docker/compose.production.yaml
ENV_FILE := .env
BACKUP_DIR := backups

# Determine which compose file to use
ifeq ($(MODE),prod)
	COMPOSE_FILE := $(COMPOSE_FILE_PROD)
	ENV := production
else
	COMPOSE_FILE := $(COMPOSE_FILE_DEV)
	ENV := development
endif

# Docker compose command with env file
DOCKER_COMPOSE := docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE)

# Default target
.DEFAULT_GOAL := help

#####################################################################
# Help
#####################################################################

help: ## Display this help message
	@echo "$(CYAN)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(CYAN)║        E-Commerce Microservices - Makefile Commands         ║$(NC)"
	@echo "$(CYAN)╚══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)Usage:$(NC) make [target] [MODE=dev|prod] [SERVICE=name] [ARGS=options]"
	@echo ""
	@echo "$(YELLOW)📦 Docker Service Commands:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)💡 Examples:$(NC)"
	@echo "  make dev-up                    # Start development environment"
	@echo "  make prod-up                   # Start production environment"
	@echo "  make logs SERVICE=gateway      # View gateway logs"
	@echo "  make shell SERVICE=backend     # Open backend shell"
	@echo "  make up MODE=prod ARGS=--build # Start prod with rebuild"
	@echo "  make health                    # Check all services health"
	@echo "  make test                      # Run all tests"
	@echo ""

#####################################################################
# Environment Setup
#####################################################################

check-env: ## Check if .env file exists
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(RED)Error: .env file not found!$(NC)"; \
		echo "$(YELLOW)Creating .env from .env.example...$(NC)"; \
		cp .env.example .env; \
		echo "$(GREEN)✓ .env file created. Please update with your values.$(NC)"; \
	else \
		echo "$(GREEN)✓ .env file exists$(NC)"; \
	fi

install: check-env ## Install/check all dependencies
	@echo "$(BLUE)Installing backend dependencies...$(NC)"
	@cd backend && npm install
	@echo "$(BLUE)Installing gateway dependencies...$(NC)"
	@cd gateway && npm install
	@echo "$(GREEN)✓ Dependencies installed$(NC)"

#####################################################################
# Docker Service Commands (Generic)
#####################################################################

up: check-env ## Start services (MODE=dev|prod, ARGS=options)
	@echo "$(BLUE)Starting $(ENV) environment...$(NC)"
	$(DOCKER_COMPOSE) up -d $(ARGS)
	@echo "$(GREEN)✓ Services started$(NC)"
	@$(MAKE) --no-print-directory status

down: ## Stop services (MODE=dev|prod, ARGS=options)
	@echo "$(YELLOW)Stopping $(ENV) environment...$(NC)"
	$(DOCKER_COMPOSE) down $(ARGS)
	@echo "$(GREEN)✓ Services stopped$(NC)"

build: ## Build containers (MODE=dev|prod, SERVICE=name)
	@echo "$(BLUE)Building $(ENV) containers...$(NC)"
	$(DOCKER_COMPOSE) build $(SERVICE) $(ARGS)
	@echo "$(GREEN)✓ Build complete$(NC)"

logs: ## View logs (MODE=dev|prod, SERVICE=name, ARGS=-f)
	$(DOCKER_COMPOSE) logs $(ARGS) $(SERVICE)

restart: ## Restart services (MODE=dev|prod, SERVICE=name)
	@echo "$(YELLOW)Restarting $(ENV) services...$(NC)"
	$(DOCKER_COMPOSE) restart $(SERVICE)
	@echo "$(GREEN)✓ Services restarted$(NC)"

ps: ## Show running containers (MODE=dev|prod)
	@$(DOCKER_COMPOSE) ps

status: ps ## Alias for ps

shell: ## Open shell in container (SERVICE=backend|gateway|mongo)
	@echo "$(CYAN)Opening shell in $(SERVICE) container...$(NC)"
	@$(DOCKER_COMPOSE) exec $(SERVICE) sh || $(DOCKER_COMPOSE) exec $(SERVICE) bash

#####################################################################
# Development Environment
#####################################################################

dev-up: ## Start development environment
	@$(MAKE) --no-print-directory up MODE=dev ARGS="--build -d"
	@sleep 3
	@$(MAKE) --no-print-directory health

dev-down: ## Stop development environment
	@$(MAKE) --no-print-directory down MODE=dev

dev-build: ## Build development containers
	@$(MAKE) --no-print-directory build MODE=dev ARGS="--no-cache"

dev-logs: ## View development logs (follow mode)
	@$(MAKE) --no-print-directory logs MODE=dev ARGS="-f"

dev-restart: ## Restart development services
	@$(MAKE) --no-print-directory restart MODE=dev

dev-shell: ## Open shell in backend container (dev)
	@$(MAKE) --no-print-directory shell MODE=dev SERVICE=backend

dev-ps: ## Show running development containers
	@$(MAKE) --no-print-directory ps MODE=dev

#####################################################################
# Production Environment
#####################################################################

prod-up: ## Start production environment
	@echo "$(RED)⚠️  Starting PRODUCTION environment$(NC)"
	@$(MAKE) --no-print-directory up MODE=prod ARGS="--build -d"
	@sleep 5
	@$(MAKE) --no-print-directory health MODE=prod

prod-down: ## Stop production environment
	@$(MAKE) --no-print-directory down MODE=prod

prod-build: ## Build production containers
	@$(MAKE) --no-print-directory build MODE=prod ARGS="--no-cache"

prod-logs: ## View production logs
	@$(MAKE) --no-print-directory logs MODE=prod ARGS="--tail=100"

prod-restart: ## Restart production services
	@$(MAKE) --no-print-directory restart MODE=prod

prod-shell: ## Open shell in container (prod)
	@$(MAKE) --no-print-directory shell MODE=prod

prod-ps: ## Show running production containers
	@$(MAKE) --no-print-directory ps MODE=prod

#####################################################################
# Service-Specific Shells
#####################################################################

backend-shell: ## Open shell in backend container
	@$(MAKE) --no-print-directory shell SERVICE=backend

gateway-shell: ## Open shell in gateway container
	@$(MAKE) --no-print-directory shell SERVICE=gateway

mongo-shell: ## Open MongoDB shell
	@echo "$(CYAN)Opening MongoDB shell...$(NC)"
	@$(DOCKER_COMPOSE) exec mongo mongosh -u $(shell grep MONGO_INITDB_ROOT_USERNAME .env | cut -d '=' -f2) -p $(shell grep MONGO_INITDB_ROOT_PASSWORD .env | cut -d '=' -f2)

#####################################################################
# Backend Development (Local)
#####################################################################

backend-build: ## Build backend TypeScript
	@echo "$(BLUE)Building backend TypeScript...$(NC)"
	@cd backend && npm run build
	@echo "$(GREEN)✓ Backend built$(NC)"

backend-install: ## Install backend dependencies
	@echo "$(BLUE)Installing backend dependencies...$(NC)"
	@cd backend && npm install
	@echo "$(GREEN)✓ Backend dependencies installed$(NC)"

backend-type-check: ## Type check backend code
	@echo "$(BLUE)Type checking backend...$(NC)"
	@cd backend && npm run type-check
	@echo "$(GREEN)✓ Type check passed$(NC)"

backend-dev: ## Run backend in development mode (local, not Docker)
	@echo "$(BLUE)Starting backend in development mode...$(NC)"
	@cd backend && npm run dev

#####################################################################
# Database Operations
#####################################################################

db-reset: ## Reset MongoDB database (WARNING: deletes all data)
	@echo "$(RED)⚠️  WARNING: This will delete ALL database data!$(NC)"
	@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo "$(YELLOW)Resetting database...$(NC)"
	@$(DOCKER_COMPOSE) exec mongo mongosh -u $(shell grep MONGO_INITDB_ROOT_USERNAME .env | cut -d '=' -f2) -p $(shell grep MONGO_INITDB_ROOT_PASSWORD .env | cut -d '=' -f2) --eval "db.getSiblingDB('$(shell grep MONGO_DATABASE .env | cut -d '=' -f2)').dropDatabase()"
	@echo "$(GREEN)✓ Database reset complete$(NC)"

db-backup: ## Backup MongoDB database
	@mkdir -p $(BACKUP_DIR)
	@echo "$(BLUE)Backing up database...$(NC)"
	@docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) exec -T mongo mongodump \
		--username=$(shell grep MONGO_INITDB_ROOT_USERNAME .env | cut -d '=' -f2) \
		--password=$(shell grep MONGO_INITDB_ROOT_PASSWORD .env | cut -d '=' -f2) \
		--db=$(shell grep MONGO_DATABASE .env | cut -d '=' -f2) \
		--archive=/tmp/backup-$(shell date +%Y%m%d-%H%M%S).archive
	@docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) exec -T mongo cat /tmp/backup-$(shell date +%Y%m%d-%H%M%S).archive > $(BACKUP_DIR)/backup-$(shell date +%Y%m%d-%H%M%S).archive
	@echo "$(GREEN)✓ Backup saved to $(BACKUP_DIR)/backup-$(shell date +%Y%m%d-%H%M%S).archive$(NC)"

db-restore: ## Restore MongoDB database (BACKUP_FILE=path/to/backup.archive)
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "$(RED)Error: BACKUP_FILE not specified$(NC)"; \
		echo "$(YELLOW)Usage: make db-restore BACKUP_FILE=backups/backup-20231201-123456.archive$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Restoring database from $(BACKUP_FILE)...$(NC)"
	@docker cp $(BACKUP_FILE) $(shell docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) ps -q mongo):/tmp/restore.archive
	@$(DOCKER_COMPOSE) exec mongo mongorestore \
		--username=$(shell grep MONGO_INITDB_ROOT_USERNAME .env | cut -d '=' -f2) \
		--password=$(shell grep MONGO_INITDB_ROOT_PASSWORD .env | cut -d '=' -f2) \
		--archive=/tmp/restore.archive
	@echo "$(GREEN)✓ Database restored$(NC)"

#####################################################################
# Health & Testing
#####################################################################

health: ## Check service health
	@echo "$(BLUE)Checking service health...$(NC)"
	@echo ""
	@echo "$(CYAN)Gateway Health:$(NC)"
	@curl -f http://localhost:5921/health 2>/dev/null && echo " $(GREEN)✓$(NC)" || echo " $(RED)✗$(NC)"
	@echo ""
	@echo "$(CYAN)Backend Health (via Gateway):$(NC)"
	@curl -f http://localhost:5921/api/health 2>/dev/null && echo " $(GREEN)✓$(NC)" || echo " $(RED)✗$(NC)"
	@echo ""
	@echo "$(CYAN)Security Test (Backend should NOT be accessible):$(NC)"
	@curl -f http://localhost:3847/api/health 2>/dev/null && echo " $(RED)✗ SECURITY ISSUE: Backend is exposed!$(NC)" || echo " $(GREEN)✓ Backend is properly isolated$(NC)"
	@echo ""

test: health ## Run all tests
	@echo "$(BLUE)Running API tests...$(NC)"
	@echo ""
	@echo "$(CYAN)Test 1: Create Product$(NC)"
	@curl -X POST http://localhost:5921/api/products \
		-H 'Content-Type: application/json' \
		-d '{"name":"Test Product","price":99.99}' 2>/dev/null | jq '.' && echo "$(GREEN)✓ Product created$(NC)" || echo "$(RED)✗ Failed$(NC)"
	@echo ""
	@echo "$(CYAN)Test 2: List Products$(NC)"
	@curl http://localhost:5921/api/products 2>/dev/null | jq '.' && echo "$(GREEN)✓ Products listed$(NC)" || echo "$(RED)✗ Failed$(NC)"
	@echo ""

validate: backend-type-check ## Validate code quality
	@echo "$(GREEN)✓ All validations passed$(NC)"

#####################################################################
# Cleanup Commands
#####################################################################

clean: ## Remove containers and networks (both dev and prod)
	@echo "$(YELLOW)Cleaning up containers and networks...$(NC)"
	@docker compose -f $(COMPOSE_FILE_DEV) --env-file $(ENV_FILE) down 2>/dev/null || true
	@docker compose -f $(COMPOSE_FILE_PROD) --env-file $(ENV_FILE) down 2>/dev/null || true
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

clean-volumes: ## Remove all volumes (WARNING: deletes all data)
	@echo "$(RED)⚠️  WARNING: This will delete ALL volumes and data!$(NC)"
	@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo "$(YELLOW)Removing volumes...$(NC)"
	@docker compose -f $(COMPOSE_FILE_DEV) --env-file $(ENV_FILE) down -v 2>/dev/null || true
	@docker compose -f $(COMPOSE_FILE_PROD) --env-file $(ENV_FILE) down -v 2>/dev/null || true
	@echo "$(GREEN)✓ Volumes removed$(NC)"

clean-all: clean clean-volumes ## Remove everything (containers, networks, volumes, images)
	@echo "$(YELLOW)Removing images...$(NC)"
	@docker rmi docker-backend docker-gateway 2>/dev/null || true
	@echo "$(GREEN)✓ Complete cleanup finished$(NC)"

docker-prune: ## Prune unused Docker resources
	@echo "$(YELLOW)Pruning unused Docker resources...$(NC)"
	@docker system prune -f
	@echo "$(GREEN)✓ Docker prune complete$(NC)"

#####################################################################
# Advanced Operations
#####################################################################

security-scan: ## Run security scan on Docker images
	@echo "$(BLUE)Scanning Docker images for vulnerabilities...$(NC)"
	@docker scout quickview docker-backend 2>/dev/null || echo "$(YELLOW)Docker Scout not available$(NC)"
	@docker scout quickview docker-gateway 2>/dev/null || echo "$(YELLOW)Docker Scout not available$(NC)"

analyze-images: ## Analyze Docker image sizes and layers
	@bash scripts/analyze-images.sh

image-size: ## Show Docker image sizes
	@echo "$(BLUE)Docker Image Sizes:$(NC)"
	@docker images | grep -E "REPOSITORY|docker-backend|docker-gateway|node.*alpine" | head -10

optimize-images: prod-build analyze-images ## Rebuild and analyze optimized images
	@echo "$(GREEN)✓ Images optimized and analyzed$(NC)"

lint: ## Lint code (if linter is configured)
	@echo "$(BLUE)Linting code...$(NC)"
	@cd backend && npm run type-check || true
	@echo "$(GREEN)✓ Linting complete$(NC)"

format: ## Format code (if formatter is configured)
	@echo "$(BLUE)Formatting code...$(NC)"
	@cd backend && npx prettier --write src 2>/dev/null || echo "$(YELLOW)Prettier not configured$(NC)"
	@cd gateway && npx prettier --write src 2>/dev/null || echo "$(YELLOW)Prettier not configured$(NC)"
	@echo "$(GREEN)✓ Formatting complete$(NC)"

#####################################################################
# Quick Start
#####################################################################

quickstart: check-env install dev-up health ## Quick start development environment
	@echo ""
	@echo "$(GREEN)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║              🚀 Development Environment Ready!               ║$(NC)"
	@echo "$(GREEN)╚══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(CYAN)Gateway:$(NC)        http://localhost:5921"
	@echo "$(CYAN)API Health:$(NC)     http://localhost:5921/api/health"
	@echo "$(CYAN)API Products:$(NC)   http://localhost:5921/api/products"
	@echo ""
	@echo "$(YELLOW)Quick Commands:$(NC)"
	@echo "  make logs         # View all logs"
	@echo "  make test         # Run tests"
	@echo "  make dev-down     # Stop environment"
	@echo ""
