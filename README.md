# Rovodev Docker Environment (For Apple Silicon Mac)

A containerized environment for Atlassian's AI coding agent: **Rovo Dev** (Beta). This Docker setup provides the Atlassian CLI (acli) with automatic authentication and local directory mounting.

## Features

- 🤖 **Rovo Dev**: Atlassian's AI coding agent in a container
- 🚀 **Auto-start**: Automatically launches `acli rovodev run` after authentication
- 🔐 **Auto-authentication**: Set credentials once, auto-login on container start
- 📁 **Local mounting**: Your current directory mounted to `/workspace`
- 🧠 **Persistence**: Optional shared or instance-specific persistence storage
- 🛠️ **Dev tools**: git, python3, nodejs, npm, curl, wget, jq included
- 🐳 **Docker-in-Docker**: Run Docker commands and containers from within the container
- 🔒 **Secure**: Non-root user with sudo access

## Status: ✅ Working

- acli installed with multi-architecture support (AMD64/ARM64)
- **Auto-launch**: Container automatically starts `acli rovodev run` after authentication
- Rovo Dev commands available
- Local file access working
- **New**: Persistence support for maintaining state between sessions
- **Fixed**: Apple Silicon (M1/M2/M3) compatibility issues resolved

## Quick Start

### 1. Setup Environment Variables

Copy the `.env.template` file to `.env` and fill in your Atlassian credentials:

```bash
cp .env.template .env
```

Edit `.env` with your details:
```bash
ATLASSIAN_USERNAME=your.email@company.com
ATLASSIAN_API_TOKEN=your_api_token_here
CONTAINER_NAME=rovodev-workspace
```

**Note:** You only need `ATLASSIAN_USERNAME` (your email) and `ATLASSIAN_API_TOKEN`. No site URL is required.

**To get your API token:**
1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Click "Create API token"
3. Copy the generated token

### 2. Run the Container

**Easy way (auto-starts Rovo Dev):**
```bash
# Normal run
./run-rovodev.sh

# Force rebuild the Docker image (after Dockerfile changes)
./run-rovodev.sh --rebuild

# Run with shared persistence (shared across all instances)
./run-rovodev.sh --persistence=shared

# Run with instance-specific persistence
./run-rovodev.sh --persistence=instance

# Run with instance-specific persistence and custom ID
./run-rovodev.sh --persistence=instance --instance-id=my-project-1
```

The container will automatically:
1. Detect if the Dockerfile has been modified and rebuild if necessary
2. Authenticate with your Atlassian credentials
3. Setup persistence if enabled
4. Launch `acli rovodev run` 
5. Start the AI assistant in your workspace

**Note:** The script automatically detects changes to the Dockerfile and rebuilds the image when needed. Use the `--rebuild` flag to force a rebuild.

**Manual way:**
```bash
# For Apple Silicon (M1/M2/M3)
docker build --platform linux/arm64 -t rovodev:latest .
docker run -it --platform linux/arm64 --env-file .env -v $(pwd):/workspace -v /var/run/docker.sock:/var/run/docker.sock rovodev:latest

# For Intel/AMD64
docker build --platform linux/amd64 -t rovodev:latest .
docker run -it --platform linux/amd64 --env-file .env -v $(pwd):/workspace -v /var/run/docker.sock:/var/run/docker.sock rovodev:latest
```

### 3. Using the Container

**Default behavior:** The container automatically starts `acli rovodev run` and you can immediately begin interacting with the AI assistant.

**Manual commands (if needed):**
```bash
# Start a shell instead of auto-launching rovodev
docker run -it --env-file .env -v $(pwd):/workspace -v /var/run/docker.sock:/var/run/docker.sock rovodev:latest /bin/bash

# Check authentication status
acli rovodev auth status

# Use Rovo Dev commands manually
acli rovodev --help

# Your local files are in /workspace
ls -la

# Install additional packages if needed
sudo apt-get update && sudo apt-get install -y package-name
```

## Persistence Feature

The persistence feature allows Rovo Dev to maintain state between sessions. This is useful for:

- Remembering context from previous conversations
- Storing project-specific knowledge
- Maintaining preferences across sessions

### Persistence Modes

1. **Shared Persistence** (`--persistence=shared`)
   - All instances of Rovo Dev share the same persistence storage
   - Useful for maintaining a single knowledge base across all projects
   - Example: `./run-rovodev.sh --persistence=shared`

2. **Instance Persistence** (`--persistence=instance`)
   - Each instance of Rovo Dev gets its own isolated persistence storage
   - Useful for project-specific knowledge that shouldn't mix with other projects
   - Example: `./run-rovodev.sh --persistence=instance`
   - You can specify a custom instance ID: `./run-rovodev.sh --persistence=instance --instance-id=my-project`

### Persistence Storage Location

Built in memory:


Persistence data is stored in `./.rovodev/persistence/` on your host machine:
- Shared mode: `./.rovodev/persistence/`
- Instance mode: `./.rovodev/persistence/instance-{ID}/`

You can examine or back up this directory as needed.

## Docker-in-Docker Usage

The container includes Docker CLI tools, allowing you to run Docker commands from within the container. This is useful for:

- Building and testing Docker images as part of your development workflow
- Running containerized services needed for your application
- Executing Docker Compose configurations

**Example Docker commands inside the container:**
```bash
# Check Docker version
docker --version

# List running containers on the host
docker ps

# Build an image
docker build -t my-test-image .

# Run a container
docker run --rm my-test-image
```

**Note:** The container uses the host's Docker daemon through the mounted Docker socket (`/var/run/docker.sock`). This means:
- Containers started from within the rovodev container actually run on the host
- Images built inside the container are available on the host
- You don't need to install Docker Engine inside the container

## Troubleshooting

**Architecture Issues (Apple Silicon):**
- If you see `rosetta error: failed to open elf` errors, rebuild the container:
  ```bash
  docker rmi rovodev:latest
  ./run-rovodev.sh
  ```
- The script now automatically detects your architecture and builds accordingly

**Authentication Issues:**
- Verify your `.env` file has correct email and API token
- Test: `docker run --rm --env-file .env -v $(pwd):/workspace -v /var/run/docker.sock:/var/run/docker.sock rovodev:latest bash -c "acli rovodev auth status"`

**Persistence Issues:**
- If persistence isn't working, check if the directory exists: `ls -la ~/.rovodev/persistence`
- Try forcing a rebuild: `./run-rovodev.sh --rebuild --persistence=shared`

**Manual Architecture Override:**
- Force ARM64: `docker build --platform linux/arm64 -t rovodev:latest .`
- Force AMD64: `docker build --platform linux/amd64 -t rovodev:latest .`

**File Structure:**
```
.
├── Dockerfile           # Container definition
├── entrypoint.sh        # Container entrypoint script
├── .env.template        # Environment template
├── .gitignore           # Git ignore rules
├── run-rovodev.sh       # Helper script
└── README.md            # This file
```