#!/bin/bash

# Simple script to push the workspace cleanup branch to the remote repository

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Pushing workspace cleanup branch to remote repository...${NC}"

# Check if we're on the correct branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "feature/workspace-cleanup" ]; then
  echo -e "${YELLOW}Currently on branch: ${CURRENT_BRANCH}${NC}"
  echo -e "${YELLOW}Switching to feature/workspace-cleanup branch...${NC}"
  git checkout feature/workspace-cleanup
fi

# Get current remote URL
CURRENT_REMOTE=$(git remote get-url origin)
echo -e "${YELLOW}Current remote URL: ${CURRENT_REMOTE}${NC}"

# Push to remote repository
echo -e "${GREEN}Pushing to remote repository...${NC}"
git push -u origin feature/workspace-cleanup

# Check push result
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Successfully pushed to remote repository!${NC}"
  echo -e "${GREEN}To create a pull request, visit:${NC}"
  echo -e "https://github.com/MayankTahil/acli-rovodev-sandbox/pull/new/feature/workspace-cleanup"
else
  echo -e "${RED}Failed to push to remote repository.${NC}"
  echo -e "${YELLOW}You may need to:${NC}"
  echo -e "1. Update your git credentials"
  echo -e "2. Use SSH authentication instead of HTTPS"
  echo -e "3. Set up a new personal access token"
  
  # Offer to manually set the remote URL
  echo -e "${YELLOW}Would you like to manually set the remote URL? (y/n)${NC}"
  read -r response
  if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo -e "${YELLOW}Enter the SSH URL for your repository (e.g., git@github.com:username/repo.git):${NC}"
    read -r ssh_url
    
    if [ -n "$ssh_url" ]; then
      echo -e "${GREEN}Setting remote URL to: ${ssh_url}${NC}"
      git remote set-url origin "$ssh_url"
      echo -e "${GREEN}Remote URL changed. Trying to push again...${NC}"
      git push -u origin feature/workspace-cleanup
      
      if [ $? -eq 0 ]; then
        echo -e "${GREEN}Successfully pushed to remote repository!${NC}"
        echo -e "${GREEN}To create a pull request, visit the repository's GitHub page.${NC}"
      else
        echo -e "${RED}Still failed to push. Please check your SSH keys and authentication.${NC}"
      fi
    else
      echo -e "${RED}No URL provided. Aborting.${NC}"
    fi
  fi
fi