#!/bin/bash

# Script to set up Git credentials using environment variables
# This should be run inside the container

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up Git credentials...${NC}"

# Check if Git credentials are available
if [ -z "$GIT_USERNAME" ] || [ -z "$GIT_PASSWORD" ]; then
    echo -e "${RED}Error: Git credentials not found in environment variables.${NC}"
    echo -e "${YELLOW}Please make sure GIT_USERNAME and GIT_PASSWORD are set in your .env file.${NC}"
    exit 1
fi

# Configure Git credential helper to use environment variables
git config --global credential.helper '!f() { echo "username=$GIT_USERNAME"; echo "password=$GIT_PASSWORD"; }; f'

# Set user name and email if provided
if [ -n "$GIT_USER_NAME" ]; then
    git config --global user.name "$GIT_USER_NAME"
    echo -e "${GREEN}Git user.name set to: $GIT_USER_NAME${NC}"
fi

if [ -n "$GIT_USER_EMAIL" ]; then
    git config --global user.email "$GIT_USER_EMAIL"
    echo -e "${GREEN}Git user.email set to: $GIT_USER_EMAIL${NC}"
fi

echo -e "${GREEN}Git credentials have been configured successfully!${NC}"
echo -e "${YELLOW}You can now use Git commands without being prompted for credentials.${NC}"