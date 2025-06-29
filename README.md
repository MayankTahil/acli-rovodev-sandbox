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
<<<<<<< HEAD
- 🔑 **SSH Agent Forwarding**: Compatible with 1Password SSH agent for secure key management
=======
>>>>>>> 6c1c1dc (Update README.md file structure)
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

The script will automatically create a `.env` file in the `.rovodev` directory. You can edit it with your Atlassian credentials:

```bash
# The file will be created at ./.rovodev/.env
# You can edit it directly:
nano ./.rovodev/.env
```

Edit `.rovodev/.env` with your details:
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
docker run -it --platform linux/arm64 --env-file ./.rovodev/.env -v $(pwd):/workspace -v /var/run/docker.sock:/var/run/docker.sock rovodev:latest

# For Intel/AMD64
docker build --platform linux/amd64 -t rovodev:latest .
docker run -it --platform linux/amd64 --env-file ./.rovodev/.env -v $(pwd):/workspace -v /var/run/docker.sock:/var/run/docker.sock rovodev:latest
```

### 3. Using the Container

**Default behavior:** The container automatically starts `acli rovodev run` and you can immediately begin interacting with the AI assistant.

**Manual commands (if needed):**
```bash
# Start a shell instead of auto-launching rovodev
docker run -it --env-file ./.rovodev/.env -v $(pwd):/workspace -v /var/run/docker.sock:/var/run/docker.sock rovodev:latest /bin/bash

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

<<<<<<< HEAD
## SSH Agent Forwarding with 1Password

This container supports SSH agent forwarding, making it compatible with the 1Password SSH agent. This allows you to use SSH keys stored in your 1Password vault from within the container without exposing the private keys to the container filesystem.

### Setup 1Password SSH Agent

1. Ensure you have 1Password installed and the SSH agent feature enabled:
   - On macOS: The socket is typically at `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`
   - On Linux: The socket is typically at `~/.1password/agent.sock`

2. Make sure your SSH config is using the 1Password SSH agent:
   ```
   # ~/.ssh/config
   Host *
     IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
   ```

3. Verify the SSH agent is running and the `SSH_AUTH_SOCK` environment variable is set:
   ```bash
   echo $SSH_AUTH_SOCK
   ssh-add -l  # Should list your keys from 1Password
   ```

### Using SSH Keys in the Container

The container automatically detects your SSH agent socket and forwards it appropriately:

- On macOS/Windows with Docker Desktop: Uses the special `/run/host-services/ssh-auth.sock` path
- On Linux: Directly mounts your host's SSH agent socket

When you run SSH commands inside the container (like `git clone` from a private repository), the authentication request will be forwarded to your 1Password app on the host, which will prompt you for authorization.

To test if SSH agent forwarding is working inside the container:
```bash
ssh-add -l  # Should list the same keys as on your host
```

## Docker-in-Docker Usage
=======

## Docker-out-of-Docker Usage
>>>>>>> 6c1c1dc (Update README.md file structure)

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
- Verify your `.rovodev/.env` file has correct email and API token
- Test: `docker run --rm --env-file ./.rovodev/.env -v $(pwd):/workspace -v /var/run/docker.sock:/var/run/docker.sock rovodev:latest bash -c "acli rovodev auth status"`

**Persistence Issues:**
- If persistence isn't working, check if the directory exists: `ls -la ~/.rovodev/persistence`
- Try forcing a rebuild: `./run-rovodev.sh --rebuild --persistence=shared`

**Manual Architecture Override:**
- Force ARM64: `docker build --platform linux/arm64 -t rovodev:latest .`
- Force AMD64: `docker build --platform linux/amd64 -t rovodev:latest .`

**File Structure:**
```
.
<<<<<<< HEAD
├── Dockerfile                      # Container definition
├── entrypoint.sh                   # Container entrypoint script
├── .env.template                   # Environment template (for reference)
├── .gitignore                      # Git ignore rules
├── run-rovodev.sh                  # Helper script
├── README.md                       # This file
├── GITHUB_ACTIONS_SETUP.md         # GitHub Actions setup instructions
├── .github/
│   └── workflows/
│       └── docker-build.yml        # GitHub Actions workflow for Docker builds
└── .rovodev/                       # Persistence directory
    └── persistence/                # Data persistence
=======
├── Dockerfile           # Container definition
├── entrypoint.sh        # Container entrypoint script
├── .env.template        # Environment template (for reference)
├── .gitignore           # Git ignore rules
├── run-rovodev.sh       # Helper script
└── README.md            # This file
>>>>>>> 6c1c1dc (Update README.md file structure)
```

## Setting up the `rdev-new` Command

Pre-req: You already build the docker image based on this dockerfile and it's stored on your host as `rovodev:latest`

If you don't have the docker image built and available, clone this git repository and execute the following command: 

```bash
docker
```


To create a shortcut command that downloads and executes the latest version of the RovoDev script, follow these steps:

### Automatic set-up

Run the following command to set up the `rdev-new` shortcut in one step:

```bash
echo '#!/bin/bash
curl -s https://raw.githubusercontent.com/MayankTahil/acli-rovodev-sandbox/refs/heads/main/run-rovodev.sh -o run-rovodev.sh
chmod +x run-rovodev.sh
./run-rovodev.sh' | sudo tee /usr/local/bin/rdev-new > /dev/null && sudo chmod +x /usr/local/bin/rdev-new
```

### Usage

Once installed, you can run the command from any directory:

```bash
rdev-new
```

This will download the latest version of the script and execute it in your current directory.