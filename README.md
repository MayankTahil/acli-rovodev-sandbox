# Rovodev Docker Environment

A containerized environment for Atlassian's AI coding agent: **Rovo Dev** (Beta). This Docker setup provides the Atlassian CLI (acli) with automatic authentication and local directory mounting.

## Features

- 🤖 **Rovo Dev**: Atlassian's AI coding agent in a container
- 🚀 **Auto-start**: Automatically launches `acli rovodev run` after authentication
- 🔐 **Auto-authentication**: Set credentials once, auto-login on container start
- 📁 **Local mounting**: Your current directory mounted to `/workspace`
- 🛠️ **Dev tools**: git, python3, nodejs, npm, curl, wget, jq included
- 🔒 **Secure**: Non-root user with sudo access

## Status: ✅ Working

- acli installed with multi-architecture support (AMD64/ARM64)
- **Auto-launch**: Container automatically starts `acli rovodev run` after authentication
- Rovo Dev commands available
- Local file access working
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
./run-rovodev.sh
```

The container will automatically:
1. Authenticate with your Atlassian credentials
2. Launch `acli rovodev run` 
3. Start the AI assistant in your workspace

**Manual way:**
```bash
# For Apple Silicon (M1/M2/M3)
docker build --platform linux/arm64 -t rovodev:latest .
docker run -it --platform linux/arm64 --env-file .env -v $(pwd):/workspace rovodev:latest

# For Intel/AMD64
docker build --platform linux/amd64 -t rovodev:latest .
docker run -it --platform linux/amd64 --env-file .env -v $(pwd):/workspace rovodev:latest
```

### 3. Using the Container

**Default behavior:** The container automatically starts `acli rovodev run` and you can immediately begin interacting with the AI assistant.

**Manual commands (if needed):**
```bash
# Start a shell instead of auto-launching rovodev
docker run -it --env-file .env -v $(pwd):/workspace rovodev:latest /bin/bash

# Check authentication status
acli rovodev auth status

# Use Rovo Dev commands manually
acli rovodev --help

# Your local files are in /workspace
ls -la

# Install additional packages if needed
sudo apt-get update && sudo apt-get install -y package-name
```

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
- Test: `docker run --rm --env-file .env -v $(pwd):/workspace rovodev:latest bash -c "acli rovodev auth status"`

**Manual Architecture Override:**
- Force ARM64: `docker build --platform linux/arm64 -t rovodev:latest .`
- Force AMD64: `docker build --platform linux/amd64 -t rovodev:latest .`

**File Structure:**
```
.
├── Dockerfile           # Container definition
├── .env.template       # Environment template
├── .gitignore          # Git ignore rules
├── run-rovodev.sh      # Helper script
└── README.md           # This file
```