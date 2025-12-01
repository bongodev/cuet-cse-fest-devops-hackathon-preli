.PHONY: help up down build logs restart shell ps status health clean clean-all clean-volumes
.PHONY: dev-up dev-down dev-build dev-logs dev-restart dev-shell dev-ps
.PHONY: prod-up prod-down prod-build prod-logs prod-restart
.PHONY: backend-shell gateway-shell mongo-shell
.PHONY: backend-build backend-install backend-type-check backend-dev
.PHONY: db-reset db-backup

# Variables
MODE ?= dev
SERVICE ?= backend
COMPOSE_FILE_DEV = docker/compose.development.yaml
COMPOSE_FILE_PROD = docker/compose.production.yaml
ARGS ?=

# Determine which compose file to use
ifeq ($(MODE),prod)
	COMPOSE_FILE = $(COMPOSE_FILE_PROD)
	CONTAINER_SUFFIX = -prod
else
	COMPOSE_FILE = $(COMPOSE_FILE_DEV)
	CONTAINER_SUFFIX = -dev
endif

# Default target
.DEFAULT_GOAL := help

# Help target
help:
	@echo "==============================================="
	@echo "  Docker E-Commerce Backend - Makefile"
	@echo "==============================================="
	@echo ""
	@echo "Docker Services:"
	@echo "  up              - Start services (MODE=dev|prod, ARGS='--build')"
	@echo "  down            - Stop services (MODE=dev|prod, ARGS='--volumes')"
	@echo "  build           - Build containers (MODE=dev|prod)"
	@echo "  logs            - View logs (MODE=dev|prod, SERVICE=backend|gateway|mongo)"
	@echo "  restart         - Restart services (MODE=dev|prod)"
	@echo "  shell           - Open shell in container (MODE=dev|prod, SERVICE=backend|gateway)"
	@echo "  ps              - Show running containers (MODE=dev|prod)"
	@echo ""
	@echo "Development Shortcuts:"
	@echo "  dev-up          - Start development environment"
	@echo "  dev-down        - Stop development environment"
	@echo "  dev-build       - Build development containers"
	@echo "  dev-logs        - View development logs"
	@echo "  dev-restart     - Restart development services"
	@echo "  dev-shell       - Open shell in backend container"
	@echo "  dev-ps          - Show running development containers"
	@echo ""
	@echo "Production Shortcuts:"
	@echo "  prod-up         - Start production environment"
	@echo "  prod-down       - Stop production environment"
	@echo "  prod-build      - Build production containers"
	@echo "  prod-logs       - View production logs"
	@echo "  prod-restart    - Restart production services"
	@echo ""
	@echo "Container Access:"
	@echo "  backend-shell   - Open shell in backend container (MODE=dev|prod)"
	@echo "  gateway-shell   - Open shell in gateway container (MODE=dev|prod)"
	@echo "  mongo-shell     - Open MongoDB shell (MODE=dev|prod)"
	@echo ""
	@echo "Backend Commands:"
	@echo "  backend-build   - Build backend TypeScript"
	@echo "  backend-install - Install backend dependencies"
	@echo "  backend-type-check - Type check backend code"
	@echo "  backend-dev     - Run backend in development mode (local)"
	@echo ""
	@echo "Database:"
	@echo "  db-reset        - Reset MongoDB database (WARNING: deletes all data)"
	@echo "  db-backup       - Backup MongoDB database"
	@echo ""
	@echo "Cleanup:"
	@echo "  clean           - Remove containers and networks"
	@echo "  clean-all       - Remove containers, networks, volumes, and images"
	@echo "  clean-volumes   - Remove all volumes"
	@echo ""
	@echo "Utilities:"
	@echo "  status          - Alias for ps"
	@echo "  health          - Check service health"
	@echo ""
	@echo "Examples:"
	@echo "  make dev-up              # Start development"
	@echo "  make prod-up             # Start production"
	@echo "  make logs SERVICE=backend MODE=prod"
	@echo "  make up MODE=prod ARGS='--build'"
	@echo "==============================================="

# Docker Services
up:
	docker compose -f $(COMPOSE_FILE) up -d $(ARGS)

down:
	docker compose -f $(COMPOSE_FILE) down $(ARGS)

build:
	docker compose -f $(COMPOSE_FILE) build $(ARGS)

logs:
	@if [ "$(SERVICE)" != "" ]; then \
		docker compose -f $(COMPOSE_FILE) logs -f $(SERVICE); \
	else \
		docker compose -f $(COMPOSE_FILE) logs -f; \
	fi

restart:
	docker compose -f $(COMPOSE_FILE) restart $(ARGS)

shell:
	docker exec -it $(SERVICE)$(CONTAINER_SUFFIX) /bin/sh

ps:
	docker compose -f $(COMPOSE_FILE) ps

status: ps

# Development shortcuts
dev-up:
	@$(MAKE) up MODE=dev

dev-down:
	@$(MAKE) down MODE=dev

dev-build:
	@$(MAKE) build MODE=dev

dev-logs:
	@$(MAKE) logs MODE=dev

dev-restart:
	@$(MAKE) restart MODE=dev

dev-shell:
	@$(MAKE) shell MODE=dev SERVICE=backend

dev-ps:
	@$(MAKE) ps MODE=dev

# Production shortcuts
prod-up:
	@$(MAKE) up MODE=prod ARGS="--build"

prod-down:
	@$(MAKE) down MODE=prod

prod-build:
	@$(MAKE) build MODE=prod

prod-logs:
	@$(MAKE) logs MODE=prod

prod-restart:
	@$(MAKE) restart MODE=prod

# Container access
backend-shell:
	@$(MAKE) shell SERVICE=backend

gateway-shell:
	@$(MAKE) shell SERVICE=gateway

mongo-shell:
	docker exec -it mongo$(CONTAINER_SUFFIX) mongosh -u admin -p password123 --authenticationDatabase admin

# Backend commands
backend-build:
	cd backend && npm run build

backend-install:
	cd backend && npm install

backend-type-check:
	cd backend && npm run type-check

backend-dev:
	cd backend && npm run dev

# Database commands
db-reset:
	@echo "WARNING: This will delete all data in MongoDB!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker compose -f $(COMPOSE_FILE) down -v; \
		docker volume rm docker_mongo-data$(CONTAINER_SUFFIX) 2>/dev/null || true; \
		echo "Database reset complete"; \
	fi

db-backup:
	@mkdir -p backups
	@TIMESTAMP=$$(date +%Y%m%d_%H%M%S); \
	docker exec mongo$(CONTAINER_SUFFIX) mongodump --username admin --password password123 --authenticationDatabase admin --archive --gzip | cat > backups/mongodb_backup_$$TIMESTAMP.archive.gz
	@echo "Backup created in backups/ directory"

# Cleanup commands
clean:
	docker compose -f $(COMPOSE_FILE_DEV) down 2>/dev/null || true
	docker compose -f $(COMPOSE_FILE_PROD) down 2>/dev/null || true
	@echo "Containers and networks removed"

clean-all: clean
	docker compose -f $(COMPOSE_FILE_DEV) down -v --rmi all 2>/dev/null || true
	docker compose -f $(COMPOSE_FILE_PROD) down -v --rmi all 2>/dev/null || true
	@echo "Containers, networks, volumes, and images removed"

clean-volumes:
	docker volume rm docker_mongo-data-dev docker_mongo-data-prod 2>/dev/null || true
	@echo "Volumes removed"

# Health check
health:
	@echo "Checking service health..."
	@docker ps --filter "name=gateway$(CONTAINER_SUFFIX)" --filter "name=backend$(CONTAINER_SUFFIX)" --filter "name=mongo$(CONTAINER_SUFFIX)" --format "table {{.Names}}\t{{.Status}}"

