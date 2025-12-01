# Makefile Guide

This project includes convenient command-line tools for managing the Docker environments.

## For Linux/macOS Users

Use the `Makefile` with the standard `make` command:

```bash
# Show all available commands
make help

# Start development environment
make dev-up

# View logs
make dev-logs

# Stop development environment
make dev-down
```

### Common Make Commands

```bash
# Development
make dev-up              # Start development environment
make dev-down            # Stop development environment  
make dev-logs            # View development logs
make dev-shell           # Open shell in backend container
make dev-ps              # Show running containers

# Production
make prod-up             # Start production environment (with build)
make prod-down           # Stop production environment
make prod-logs           # View production logs

# Database
make mongo-shell         # Access MongoDB shell
make db-backup           # Backup MongoDB database
make db-reset            # Reset database (WARNING: deletes all data)

# Cleanup
make clean               # Remove containers and networks
make clean-all           # Remove everything including volumes and images
```

## For Windows Users

Use the `Makefile.ps1` PowerShell script:

```powershell
# Show all available commands
powershell -ExecutionPolicy Bypass -File .\Makefile.ps1 help

# Or create an alias for convenience (add to your PowerShell profile)
Set-Alias -Name mkf -Value "powershell -ExecutionPolicy Bypass -File .\Makefile.ps1"

# Then you can use:
mkf dev-up
mkf dev-logs
```

### Common PowerShell Commands

```powershell
# Development
.\Makefile.ps1 dev-up              # Start development environment
.\Makefile.ps1 dev-down            # Stop development environment
.\Makefile.ps1 dev-logs            # View development logs
.\Makefile.ps1 dev-shell           # Open shell in backend container
.\Makefile.ps1 dev-ps              # Show running containers

# Production
.\Makefile.ps1 prod-up             # Start production environment (with build)
.\Makefile.ps1 prod-down           # Stop production environment
.\Makefile.ps1 prod-logs           # View production logs

# Database
.\Makefile.ps1 mongo-shell         # Access MongoDB shell
.\Makefile.ps1 db-backup           # Backup MongoDB database
.\Makefile.ps1 db-reset            # Reset database (WARNING: deletes all data)

# Cleanup
.\Makefile.ps1 clean               # Remove containers and networks
.\Makefile.ps1 clean-all           # Remove everything including volumes and images
```

### Create PowerShell Alias (Optional)

To avoid typing the full command each time, add this to your PowerShell profile:

```powershell
# Open your PowerShell profile
notepad $PROFILE

# Add this line:
function mkf { powershell -ExecutionPolicy Bypass -File "C:\path\to\project\Makefile.ps1" @args }

# Save and reload:
. $PROFILE

# Now you can use:
mkf dev-up
mkf prod-logs
mkf health
```

## Advanced Usage

### Using MODE and SERVICE Parameters

**Linux/macOS:**
```bash
# Start production mode
make up MODE=prod

# View backend logs in production
make logs SERVICE=backend MODE=prod

# Open shell in gateway container
make shell SERVICE=gateway MODE=prod

# Build with additional args
make up MODE=prod ARGS="--build"
```

**Windows:**
```powershell
# Start production mode
.\Makefile.ps1 up -Mode prod

# View backend logs in production
.\Makefile.ps1 logs -Service backend -Mode prod

# Open shell in gateway container
.\Makefile.ps1 shell -Service gateway -Mode prod

# Build with additional args
.\Makefile.ps1 up -Mode prod -Args "--build"
```

## Quick Reference

| Action | Linux/macOS | Windows |
|--------|-------------|---------|
| Start dev | `make dev-up` | `.\Makefile.ps1 dev-up` |
| Stop dev | `make dev-down` | `.\Makefile.ps1 dev-down` |
| Start prod | `make prod-up` | `.\Makefile.ps1 prod-up` |
| View logs | `make dev-logs` | `.\Makefile.ps1 dev-logs` |
| Check health | `make health` | `.\Makefile.ps1 health` |
| Backend shell | `make backend-shell` | `.\Makefile.ps1 backend-shell` |
| MongoDB shell | `make mongo-shell` | `.\Makefile.ps1 mongo-shell` |
| Clean all | `make clean-all` | `.\Makefile.ps1 clean-all` |

## Troubleshooting

### Windows PowerShell Execution Policy

If you get an error about execution policy:
```powershell
powershell -ExecutionPolicy Bypass -File .\Makefile.ps1 help
```

Or set your execution policy (as Administrator):
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Make Not Installed on Linux/macOS

Install make:
```bash
# Ubuntu/Debian
sudo apt-get install make

# macOS
xcode-select --install
# or
brew install make
```

## Tips

1. **Always check health** after starting: `make health` or `.\Makefile.ps1 health`
2. **Use dev-logs** to monitor development in real-time
3. **Clean volumes** if you encounter database issues: `make clean-volumes`
4. **Backup before db-reset** to avoid losing important data
5. **Use prod-up** which automatically rebuilds images for production deployments
