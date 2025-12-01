<#
.SYNOPSIS
    Docker E-Commerce Backend - PowerShell Management Script

.DESCRIPTION
    Provides convenient commands for managing Docker environments (dev/prod)

.PARAMETER Command
    The command to execute (help, up, down, build, logs, etc.)

.PARAMETER Mode
    Environment mode: dev or prod (default: dev)

.PARAMETER Service
    Service name: backend, gateway, or mongo

.PARAMETER Args
    Additional arguments to pass to docker-compose

.EXAMPLE
    .\Makefile.ps1 help
    .\Makefile.ps1 dev-up
    .\Makefile.ps1 up -Mode prod -Args "--build"
    .\Makefile.ps1 logs -Service backend -Mode prod
#>

param(
    [Parameter(Position=0)]
    [string]$Command = "help",
    
    [string]$Mode = "dev",
    [string]$Service = "",
    [string]$Args = ""
)

# Variables
$COMPOSE_FILE_DEV = "docker/compose.development.yaml"
$COMPOSE_FILE_PROD = "docker/compose.production.yaml"

# Determine which compose file to use
if ($Mode -eq "prod") {
    $COMPOSE_FILE = $COMPOSE_FILE_PROD
    $CONTAINER_SUFFIX = "-prod"
} else {
    $COMPOSE_FILE = $COMPOSE_FILE_DEV
    $CONTAINER_SUFFIX = "-dev"
}

function Show-Help {
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host "  Docker E-Commerce Backend - PowerShell" -ForegroundColor Cyan
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Docker Services:" -ForegroundColor Yellow
    Write-Host "  .\Makefile.ps1 up              - Start services"
    Write-Host "  .\Makefile.ps1 down            - Stop services"
    Write-Host "  .\Makefile.ps1 build           - Build containers"
    Write-Host "  .\Makefile.ps1 logs            - View logs"
    Write-Host "  .\Makefile.ps1 restart         - Restart services"
    Write-Host "  .\Makefile.ps1 shell           - Open shell in container"
    Write-Host "  .\Makefile.ps1 ps              - Show running containers"
    Write-Host ""
    Write-Host "Development Shortcuts:" -ForegroundColor Yellow
    Write-Host "  .\Makefile.ps1 dev-up          - Start development environment"
    Write-Host "  .\Makefile.ps1 dev-down        - Stop development environment"
    Write-Host "  .\Makefile.ps1 dev-build       - Build development containers"
    Write-Host "  .\Makefile.ps1 dev-logs        - View development logs"
    Write-Host "  .\Makefile.ps1 dev-restart     - Restart development services"
    Write-Host "  .\Makefile.ps1 dev-shell       - Open shell in backend container"
    Write-Host "  .\Makefile.ps1 dev-ps          - Show running development containers"
    Write-Host ""
    Write-Host "Production Shortcuts:" -ForegroundColor Yellow
    Write-Host "  .\Makefile.ps1 prod-up         - Start production environment"
    Write-Host "  .\Makefile.ps1 prod-down       - Stop production environment"
    Write-Host "  .\Makefile.ps1 prod-build      - Build production containers"
    Write-Host "  .\Makefile.ps1 prod-logs       - View production logs"
    Write-Host "  .\Makefile.ps1 prod-restart    - Restart production services"
    Write-Host ""
    Write-Host "Container Access:" -ForegroundColor Yellow
    Write-Host "  .\Makefile.ps1 backend-shell   - Open shell in backend container"
    Write-Host "  .\Makefile.ps1 gateway-shell   - Open shell in gateway container"
    Write-Host "  .\Makefile.ps1 mongo-shell     - Open MongoDB shell"
    Write-Host ""
    Write-Host "Backend Commands:" -ForegroundColor Yellow
    Write-Host "  .\Makefile.ps1 backend-build   - Build backend TypeScript"
    Write-Host "  .\Makefile.ps1 backend-install - Install backend dependencies"
    Write-Host "  .\Makefile.ps1 backend-type-check - Type check backend code"
    Write-Host "  .\Makefile.ps1 backend-dev     - Run backend in development mode"
    Write-Host ""
    Write-Host "Database:" -ForegroundColor Yellow
    Write-Host "  .\Makefile.ps1 db-reset        - Reset MongoDB database"
    Write-Host "  .\Makefile.ps1 db-backup       - Backup MongoDB database"
    Write-Host ""
    Write-Host "Cleanup:" -ForegroundColor Yellow
    Write-Host "  .\Makefile.ps1 clean           - Remove containers and networks"
    Write-Host "  .\Makefile.ps1 clean-all       - Remove containers, networks, volumes, images"
    Write-Host "  .\Makefile.ps1 clean-volumes   - Remove all volumes"
    Write-Host ""
    Write-Host "Utilities:" -ForegroundColor Yellow
    Write-Host "  .\Makefile.ps1 status          - Alias for ps"
    Write-Host "  .\Makefile.ps1 health          - Check service health"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Green
    Write-Host "  .\Makefile.ps1 dev-up"
    Write-Host "  .\Makefile.ps1 prod-up"
    Write-Host "  .\Makefile.ps1 logs -Service backend -Mode prod"
    Write-Host "  .\Makefile.ps1 up -Mode prod -Args '--build'"
    Write-Host "===============================================" -ForegroundColor Cyan
}

function Invoke-DockerCompose {
    param([string]$Action, [string]$AdditionalArgs = "")
    
    $cmd = "docker compose -f $COMPOSE_FILE $Action"
    if ($AdditionalArgs) {
        $cmd += " $AdditionalArgs"
    }
    
    Write-Host "Executing: $cmd" -ForegroundColor Gray
    Invoke-Expression $cmd
}

# Command routing
switch ($Command.ToLower()) {
    "help" { Show-Help }
    
    # Docker Services
    "up" { Invoke-DockerCompose "up -d" $Args }
    "down" { Invoke-DockerCompose "down" $Args }
    "build" { Invoke-DockerCompose "build" $Args }
    "restart" { Invoke-DockerCompose "restart" $Args }
    "ps" { Invoke-DockerCompose "ps" }
    "status" { Invoke-DockerCompose "ps" }
    
    "logs" {
        if ($Service) {
            Invoke-DockerCompose "logs -f $Service"
        } else {
            Invoke-DockerCompose "logs -f"
        }
    }
    
    "shell" {
        $svc = if ($Service) { $Service } else { "backend" }
        docker exec -it "$svc$CONTAINER_SUFFIX" /bin/sh
    }
    
    # Development shortcuts
    "dev-up" {
        $script:Mode = "dev"
        $script:COMPOSE_FILE = $COMPOSE_FILE_DEV
        Invoke-DockerCompose "up -d"
    }
    "dev-down" {
        $script:Mode = "dev"
        $script:COMPOSE_FILE = $COMPOSE_FILE_DEV
        Invoke-DockerCompose "down"
    }
    "dev-build" {
        $script:Mode = "dev"
        $script:COMPOSE_FILE = $COMPOSE_FILE_DEV
        Invoke-DockerCompose "build"
    }
    "dev-logs" {
        $script:Mode = "dev"
        $script:COMPOSE_FILE = $COMPOSE_FILE_DEV
        Invoke-DockerCompose "logs -f"
    }
    "dev-restart" {
        $script:Mode = "dev"
        $script:COMPOSE_FILE = $COMPOSE_FILE_DEV
        Invoke-DockerCompose "restart"
    }
    "dev-shell" {
        docker exec -it "backend-dev" /bin/sh
    }
    "dev-ps" {
        $script:Mode = "dev"
        $script:COMPOSE_FILE = $COMPOSE_FILE_DEV
        Invoke-DockerCompose "ps"
    }
    
    # Production shortcuts
    "prod-up" {
        $script:Mode = "prod"
        $script:COMPOSE_FILE = $COMPOSE_FILE_PROD
        Invoke-DockerCompose "up -d" "--build"
    }
    "prod-down" {
        $script:Mode = "prod"
        $script:COMPOSE_FILE = $COMPOSE_FILE_PROD
        Invoke-DockerCompose "down"
    }
    "prod-build" {
        $script:Mode = "prod"
        $script:COMPOSE_FILE = $COMPOSE_FILE_PROD
        Invoke-DockerCompose "build"
    }
    "prod-logs" {
        $script:Mode = "prod"
        $script:COMPOSE_FILE = $COMPOSE_FILE_PROD
        Invoke-DockerCompose "logs -f"
    }
    "prod-restart" {
        $script:Mode = "prod"
        $script:COMPOSE_FILE = $COMPOSE_FILE_PROD
        Invoke-DockerCompose "restart"
    }
    
    # Container access
    "backend-shell" {
        $svc = "backend$CONTAINER_SUFFIX"
        docker exec -it $svc /bin/sh
    }
    "gateway-shell" {
        $svc = "gateway$CONTAINER_SUFFIX"
        docker exec -it $svc /bin/sh
    }
    "mongo-shell" {
        $svc = "mongo$CONTAINER_SUFFIX"
        docker exec -it $svc mongosh -u admin -p password123 --authenticationDatabase admin
    }
    
    # Backend commands
    "backend-build" {
        Set-Location backend
        npm run build
        Set-Location ..
    }
    "backend-install" {
        Set-Location backend
        npm install
        Set-Location ..
    }
    "backend-type-check" {
        Set-Location backend
        npm run type-check
        Set-Location ..
    }
    "backend-dev" {
        Set-Location backend
        npm run dev
        Set-Location ..
    }
    
    # Database commands
    "db-reset" {
        $confirmation = Read-Host "WARNING: This will delete all data in MongoDB! Are you sure? (yes/no)"
        if ($confirmation -eq "yes") {
            Invoke-DockerCompose "down" "-v"
            docker volume rm "docker_mongo-data$CONTAINER_SUFFIX" 2>$null
            Write-Host "Database reset complete" -ForegroundColor Green
        } else {
            Write-Host "Operation cancelled" -ForegroundColor Yellow
        }
    }
    "db-backup" {
        $backupDir = "backups"
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir | Out-Null
        }
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupFile = "$backupDir/mongodb_backup_$timestamp.archive.gz"
        
        Write-Host "Creating backup..." -ForegroundColor Yellow
        docker exec "mongo$CONTAINER_SUFFIX" mongodump --username admin --password password123 --authenticationDatabase admin --archive --gzip | Set-Content -Path $backupFile -Encoding Byte
        Write-Host "Backup created: $backupFile" -ForegroundColor Green
    }
    
    # Cleanup commands
    "clean" {
        docker compose -f $COMPOSE_FILE_DEV down 2>$null
        docker compose -f $COMPOSE_FILE_PROD down 2>$null
        Write-Host "Containers and networks removed" -ForegroundColor Green
    }
    "clean-all" {
        docker compose -f $COMPOSE_FILE_DEV down -v --rmi all 2>$null
        docker compose -f $COMPOSE_FILE_PROD down -v --rmi all 2>$null
        Write-Host "Containers, networks, volumes, and images removed" -ForegroundColor Green
    }
    "clean-volumes" {
        docker volume rm docker_mongo-data-dev docker_mongo-data-prod 2>$null
        Write-Host "Volumes removed" -ForegroundColor Green
    }
    
    # Health check
    "health" {
        Write-Host "Checking service health..." -ForegroundColor Yellow
        docker ps --filter "name=gateway$CONTAINER_SUFFIX" --filter "name=backend$CONTAINER_SUFFIX" --filter "name=mongo$CONTAINER_SUFFIX" --format "table {{.Names}}`t{{.Status}}"
    }
    
    default {
        Write-Host "Unknown command: $Command" -ForegroundColor Red
        Write-Host "Run '.\Makefile.ps1 help' for available commands" -ForegroundColor Yellow
    }
}
