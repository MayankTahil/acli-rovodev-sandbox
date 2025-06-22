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