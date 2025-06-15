# Rovodev Docker Environment

A containerized environment for Atlassian's AI coding agent: **Rovo Dev** (Beta). This Docker setup provides the Atlassian CLI (acli) with automatic authentication and local directory mounting.

## Features

- 🤖 **Rovo Dev**: Atlassian's AI coding agent in a container
- 🔐 **Auto-authentication**: Set credentials once, auto-login on container start
- 📁 **Local mounting**: Your current directory mounted to `/workspace`
- 🛠️ **Dev tools**: git, python3, nodejs, npm, curl, wget, jq included
- 🔒 **Secure**: Non-root user with sudo access

## Status: ✅ Working

- acli v1.2.1-stable installed and authenticated
- Rovo Dev commands available
- Local file access working
- Compatible with Apple Silicon (minor Rosetta warnings are normal)

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

**Easy way:**
```bash
./run-rovodev.sh
```

**Manual way:**
```bash
docker build -t rovodev:latest .
docker run -it --env-file .env -v $(pwd):/workspace rovodev:latest
```

### 3. Using the Container

```bash
# Check authentication status
acli rovodev auth status

# Use Rovo Dev commands
acli rovodev --help

# Your local files are in /workspace
ls -la

# Install additional packages if needed
sudo apt-get update && sudo apt-get install -y package-name
```

## Troubleshooting

**Authentication Issues:**
- Verify your `.env` file has correct email and API token
- Test: `docker run --rm --env-file .env -v $(pwd):/workspace rovodev:latest bash -c "acli rovodev auth status"`

**Rosetta Errors (Apple Silicon):**
- "rosetta error" messages are normal and don't affect functionality

**File Structure:**
```
.
├── Dockerfile           # Container definition
├── .env.template       # Environment template
├── .gitignore          # Git ignore rules
├── run-rovodev.sh      # Helper script
└── README.md           # This file
```