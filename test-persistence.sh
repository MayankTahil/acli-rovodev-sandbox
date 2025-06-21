#!/bin/bash

# Script to test the persistence feature

set -e

echo "Testing persistence feature..."

# Test shared persistence
echo "Testing shared persistence..."
./run-rovodev.sh --persistence=shared --rebuild bash -c "echo 'Test data' > /persistence/shared/test.txt && cat /persistence/shared/test.txt"

echo "Verifying shared persistence data..."
./run-rovodev.sh --persistence=shared bash -c "cat /persistence/shared/test.txt"

# Test instance persistence
echo "Testing instance persistence..."
./run-rovodev.sh --persistence=instance --instance-id=test-instance --rebuild bash -c "echo 'Instance test data' > /persistence/instance-test-instance/test.txt && cat /persistence/instance-test-instance/test.txt"

echo "Verifying instance persistence data..."
./run-rovodev.sh --persistence=instance --instance-id=test-instance bash -c "cat /persistence/instance-test-instance/test.txt"

echo "All tests completed successfully!"