# Docker Services:
#   up - Start services (use: make up [service...] or make up MODE=prod, ARGS="--build" for options)
#   down - Stop services (use: make down [service...] or make down MODE=prod, ARGS="--volumes" for options)
#   build - Build containers (use: make build [service...] or make build MODE=prod)
#   logs - View logs (use: make logs [service] or make logs SERVICE=backend, MODE=prod for production)
#   restart - Restart services (use: make restart [service...] or make restart MODE=prod)
#   shell - Open shell in container (use: make shell [service] or make shell SERVICE=gateway, MODE=prod, default: backend)
#   ps - Show running containers (use MODE=prod for production)
#
# Convenience Aliases (Development):
#   dev-up - Alias: Start development environment
#   dev-down - Alias: Stop development environment
#   dev-build - Alias: Build development containers
#   dev-logs - Alias: View development logs
#   dev-restart - Alias: Restart development services
#   dev-shell - Alias: Open shell in backend container
#   dev-ps - Alias: Show running development containers
#   backend-shell - Alias: Open shell in backend container
#   gateway-shell - Alias: Open shell in gateway container
#   mongo-shell - Open MongoDB shell
#
# Convenience Aliases (Production):
#   prod-up - Alias: Start production environment
#   prod-down - Alias: Stop production environment
#   prod-build - Alias: Build production containers
#   prod-logs - Alias: View production logs
#   prod-restart - Alias: Restart production services
#
# Backend:
#   backend-build - Build backend TypeScript
#   backend-install - Install backend dependencies
#   backend-type-check - Type check backend code
#   backend-dev - Run backend in development mode (local, not Docker)
#
# Database:
#   db-reset - Reset MongoDB database (WARNING: deletes all data)
#   db-backup - Backup MongoDB database
#
# Cleanup:
#   clean - Remove containers and networks (both dev and prod)
#   clean-all - Remove containers, networks, volumes, and images
#   clean-volumes - Remove all volumes
#
# Utilities:
#   status - Alias for ps
#   health - Check service health
#
# Help:
#   help - Display this help message

.PHONY: help up down build logs restart shell ps status health clean clean-all clean-volumes
.PHONY: dev-up dev-down dev-build dev-logs dev-restart dev-shell dev-ps
.PHONY: prod-up prod-down prod-build prod-logs prod-restart
.PHONY: backend-shell gateway-shell mongo-shell
.PHONY: backend-build backend-install backend-type-check backend-dev
.PHONY: db-reset db-backup

# Default mode is development
MODE ?= dev
SERVICE ?= backend
COMPOSE_FILE := docker/compose.$(if $(filter prod,$(MODE)),production,development).yaml
DOCKER_COMPOSE := docker compose -f $(COMPOSE_FILE) --env-file .env

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Default target
.DEFAULT_GOAL := help

# Help command
help:
	@echo "$(GREEN)Available Make Commands:$(NC)"
	@echo ""
	@grep -E '^#' $(MAKEFILE_LIST) | grep -E '^\#   ' | sed 's/^#   /  /'
	@echo ""
	@echo "$(YELLOW)Examples:$(NC)"
	@echo "  make dev-up              # Start development environment"
	@echo "  make prod-up             # Start production environment"
	@echo "  make logs SERVICE=backend # View backend logs"
	@echo "  make dev-shell           # Open shell in backend container"
	@echo ""

# ============================================================================
# Docker Services
# ============================================================================

up:
	@echo "$(GREEN)Starting services in $(MODE) mode...$(NC)"
	$(DOCKER_COMPOSE) up -d $(ARGS) $(filter-out $@,$(MAKECMDGOALS))
	@echo "$(GREEN)Services started successfully!$(NC)"
	@echo "$(YELLOW)Gateway available at: http://localhost:5921$(NC)"

down:
	@echo "$(YELLOW)Stopping services in $(MODE) mode...$(NC)"
	$(DOCKER_COMPOSE) down $(ARGS) $(filter-out $@,$(MAKECMDGOALS))
	@echo "$(GREEN)Services stopped successfully!$(NC)"

build:
	@echo "$(GREEN)Building containers in $(MODE) mode...$(NC)"
	$(DOCKER_COMPOSE) build $(ARGS) $(filter-out $@,$(MAKECMDGOALS))
	@echo "$(GREEN)Build completed successfully!$(NC)"

logs:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		$(DOCKER_COMPOSE) logs -f $(SERVICE); \
	else \
		$(DOCKER_COMPOSE) logs -f $(filter-out $@,$(MAKECMDGOALS)); \
	fi

restart:
	@echo "$(YELLOW)Restarting services in $(MODE) mode...$(NC)"
	$(DOCKER_COMPOSE) restart $(filter-out $@,$(MAKECMDGOALS))
	@echo "$(GREEN)Services restarted successfully!$(NC)"

shell:
	@echo "$(GREEN)Opening shell in $(SERVICE) container...$(NC)"
	@if [ "$(MODE)" = "prod" ]; then \
		$(DOCKER_COMPOSE) exec $(SERVICE) /bin/sh; \
	else \
		$(DOCKER_COMPOSE) exec $(SERVICE) /bin/sh; \
	fi

ps:
	@$(DOCKER_COMPOSE) ps

status: ps

# ============================================================================
# Development Convenience Aliases
# ============================================================================

dev-up:
	@$(MAKE) up MODE=dev

dev-down:
	@$(MAKE) down MODE=dev

dev-build:
	@$(MAKE) build MODE=dev ARGS="--no-cache"

dev-logs:
	@$(MAKE) logs MODE=dev

dev-restart:
	@$(MAKE) restart MODE=dev

dev-shell:
	@$(MAKE) shell MODE=dev SERVICE=backend

dev-ps:
	@$(MAKE) ps MODE=dev

backend-shell:
	@$(MAKE) shell SERVICE=backend

gateway-shell:
	@$(MAKE) shell SERVICE=gateway

mongo-shell:
	@echo "$(GREEN)Opening MongoDB shell...$(NC)"
	@if [ "$(MODE)" = "prod" ]; then \
		$(DOCKER_COMPOSE) exec mongo mongosh -u $${MONGO_INITDB_ROOT_USERNAME} -p $${MONGO_INITDB_ROOT_PASSWORD} --authenticationDatabase admin; \
	else \
		$(DOCKER_COMPOSE) exec mongo mongosh -u $${MONGO_INITDB_ROOT_USERNAME} -p $${MONGO_INITDB_ROOT_PASSWORD} --authenticationDatabase admin; \
	fi

# ============================================================================
# Production Convenience Aliases
# ============================================================================

prod-up:
	@$(MAKE) up MODE=prod

prod-down:
	@$(MAKE) down MODE=prod

prod-build:
	@$(MAKE) build MODE=prod ARGS="--no-cache"

prod-logs:
	@$(MAKE) logs MODE=prod

prod-restart:
	@$(MAKE) restart MODE=prod

# ============================================================================
# Backend Development (Local, not Docker)
# ============================================================================

backend-build:
	@echo "$(GREEN)Building backend TypeScript...$(NC)"
	@cd backend && npm run build
	@echo "$(GREEN)Backend build completed!$(NC)"

backend-install:
	@echo "$(GREEN)Installing backend dependencies...$(NC)"
	@cd backend && npm install
	@echo "$(GREEN)Backend dependencies installed!$(NC)"

backend-type-check:
	@echo "$(GREEN)Type checking backend code...$(NC)"
	@cd backend && npm run type-check
	@echo "$(GREEN)Type check completed!$(NC)"

backend-dev:
	@echo "$(GREEN)Running backend in development mode (local)...$(NC)"
	@cd backend && npm run dev

# ============================================================================
# Database Management
# ============================================================================

db-reset:
	@echo "$(RED)WARNING: This will delete all data in the database!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "$(YELLOW)Resetting database...$(NC)"; \
		if [ "$(MODE)" = "prod" ]; then \
			$(DOCKER_COMPOSE) exec mongo mongosh -u $${MONGO_INITDB_ROOT_USERNAME} -p $${MONGO_INITDB_ROOT_PASSWORD} --authenticationDatabase admin --eval "db.getSiblingDB('$${MONGO_DATABASE}').dropDatabase()"; \
		else \
			$(DOCKER_COMPOSE) exec mongo mongosh -u $${MONGO_INITDB_ROOT_USERNAME} -p $${MONGO_INITDB_ROOT_PASSWORD} --authenticationDatabase admin --eval "db.getSiblingDB('$${MONGO_DATABASE}').dropDatabase()"; \
		fi; \
		echo "$(GREEN)Database reset completed!$(NC)"; \
	else \
		echo "$(YELLOW)Database reset cancelled.$(NC)"; \
	fi

db-backup:
	@echo "$(GREEN)Backing up MongoDB database...$(NC)"
	@mkdir -p backups
	@TIMESTAMP=$$(date +%Y%m%d_%H%M%S); \
	if [ "$(MODE)" = "prod" ]; then \
		docker compose -f docker/compose.production.yaml --env-file .env exec -T mongo mongodump --username=$${MONGO_INITDB_ROOT_USERNAME} --password=$${MONGO_INITDB_ROOT_PASSWORD} --authenticationDatabase=admin --db=$${MONGO_DATABASE} --archive > backups/backup_prod_$$TIMESTAMP.archive; \
	else \
		docker compose -f docker/compose.development.yaml --env-file .env exec -T mongo mongodump --username=$${MONGO_INITDB_ROOT_USERNAME} --password=$${MONGO_INITDB_ROOT_PASSWORD} --authenticationDatabase=admin --db=$${MONGO_DATABASE} --archive > backups/backup_dev_$$TIMESTAMP.archive; \
	fi
	@echo "$(GREEN)Database backup completed: backups/backup_$(MODE)_$$TIMESTAMP.archive$(NC)"

# ============================================================================
# Health Checks
# ============================================================================

health:
	@echo "$(GREEN)Checking service health...$(NC)"
	@echo ""
	@echo "$(YELLOW)Gateway Health:$(NC)"
	@curl -s http://localhost:5921/health | json_pp || echo "$(RED)Gateway is not responding$(NC)"
	@echo ""
	@echo "$(YELLOW)Backend Health (via Gateway):$(NC)"
	@curl -s http://localhost:5921/api/health | json_pp || echo "$(RED)Backend is not responding$(NC)"
	@echo ""
	@echo "$(YELLOW)Docker Container Status:$(NC)"
	@$(DOCKER_COMPOSE) ps

# ============================================================================
# Cleanup
# ============================================================================

clean:
	@echo "$(YELLOW)Cleaning up containers and networks...$(NC)"
	@docker compose -f docker/compose.development.yaml --env-file .env down 2>/dev/null || true
	@docker compose -f docker/compose.production.yaml --env-file .env down 2>/dev/null || true
	@echo "$(GREEN)Cleanup completed!$(NC)"

clean-volumes:
	@echo "$(RED)WARNING: This will delete all volumes and data!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "$(YELLOW)Removing all volumes...$(NC)"; \
		docker compose -f docker/compose.development.yaml --env-file .env down -v 2>/dev/null || true; \
		docker compose -f docker/compose.production.yaml --env-file .env down -v 2>/dev/null || true; \
		echo "$(GREEN)Volumes removed!$(NC)"; \
	else \
		echo "$(YELLOW)Volume removal cancelled.$(NC)"; \
	fi

clean-all: clean-volumes
	@echo "$(YELLOW)Removing all containers, networks, volumes, and images...$(NC)"
	@docker image prune -a -f --filter label=com.docker.compose.project=cuet-cse-fest-devops-hackathon-preli 2>/dev/null || true
	@echo "$(GREEN)Full cleanup completed!$(NC)"

# Allow arbitrary service names as targets
%:
	@:
