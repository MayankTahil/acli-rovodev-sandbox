#!/bin/bash

# Script to apply all the persistence feature changes

set -e

echo "Applying persistence feature changes..."

# Backup original files
echo "Creating backups..."
cp Dockerfile Dockerfile.bak
cp run-rovodev.sh run-rovodev.sh.bak
cp .env.template .env.template.bak
cp README.md README.md.bak

# Apply changes
echo "Applying new files..."
cp Dockerfile.new Dockerfile
# entrypoint.sh is already in place
cp run-rovodev.sh.new run-rovodev.sh
cp .env.template.new .env.template
cp README.md.new README.md

# Make scripts executable
chmod +x run-rovodev.sh
chmod +x entrypoint.sh

# Clean up temporary files
echo "Cleaning up temporary files..."
rm Dockerfile.new
rm run-rovodev.sh.new
rm .env.template.new
rm README.md.new

echo "Done! Persistence feature has been implemented."
echo "You can now use: ./run-rovodev.sh --persistence=shared or --persistence=instance"