#!/bin/bash

# Script to apply the workspace cleanup branch and push it to the repository

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Applying workspace cleanup changes...${NC}"

# Check if we're in the git repository
if [ ! -d ".git" ]; then
  echo -e "${RED}Error: Not in a git repository. Please run this script from the repository root.${NC}"
  exit 1
fi

# Check current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo -e "${YELLOW}Current branch: ${CURRENT_BRANCH}${NC}"

# Create and switch to the feature branch
echo -e "${GREEN}Creating feature branch: feature/workspace-cleanup${NC}"
git checkout -b feature/workspace-cleanup 2>/dev/null || git checkout feature/workspace-cleanup

# Apply the patch if it exists
if [ -f "0001-Add-documentation-for-workspace-cleanup.patch" ]; then
  echo -e "${GREEN}Applying patch...${NC}"
  git apply 0001-Add-documentation-for-workspace-cleanup.patch --check
  if [ $? -eq 0 ]; then
    git am 0001-Add-documentation-for-workspace-cleanup.patch
  else
    echo -e "${RED}Error: Patch cannot be applied cleanly.${NC}"
    exit 1
  fi
else
  # Create the cleanup documentation file
  echo -e "${GREEN}Creating CLEANUP.md file...${NC}"
  cat > CLEANUP.md << 'EOL'
# Workspace Cleanup

This branch contains workspace cleanup changes to improve the repository organization and remove unnecessary files.

## Changes Made

1. Removed unnecessary files:
   - Test files (`test-git-auth.sh`, `test-repo/`)
   - Backup files (`README.md.bak`)
   - Temporary files (`.dockerfile_hash`, `tmp_code_*`)
   - System files (`.DS_Store`)

2. Organized the repository structure:
   - Kept essential configuration files
   - Maintained documentation
   - Preserved core functionality

## Benefits

- Cleaner workspace for developers
- Reduced repository size
- Better organization
- Improved maintainability

## Files Retained

- Core files:
  - `Dockerfile` - Container definition
  - `entrypoint.sh` - Container entrypoint script
  - `run-rovodev.sh` - Helper script to run the container
  - `.env.template` - Template for environment variables
  - `.env` - Environment variables (not committed to git)

- Documentation:
  - `README.md` - Documentation for the project
  - `CLEANUP.md` - This file documenting the cleanup

- Configuration:
  - `.gitignore` - Git ignore rules
  - `.dockerignore` - Docker ignore rules

- Directories:
  - `init/` - Initialization files
  - `persistence/` - Persistence-related files
  - `.rovodev/` - Rovodev configuration directory
EOL

  # Commit the changes
  echo -e "${GREEN}Committing changes...${NC}"
  git add CLEANUP.md
  git commit -m "Add documentation for workspace cleanup"
fi

# Push to remote repository
echo -e "${YELLOW}Ready to push to remote repository.${NC}"
echo -e "${YELLOW}To push the branch, run:${NC}"
echo -e "${GREEN}git push -u origin feature/workspace-cleanup${NC}"
echo
echo -e "${YELLOW}If you encounter authentication issues, you may need to:${NC}"
echo -e "1. Update your git credentials"
echo -e "2. Use SSH authentication instead of HTTPS"
echo -e "3. Set up a new personal access token"
echo
echo -e "${GREEN}To create a pull request, visit:${NC}"
echo -e "https://github.com/MayankTahil/acli-rovodev-sandbox/pull/new/feature/workspace-cleanup"