#!/bin/sh
set -e

echo "Starting Hardhat node..."
npx hardhat node --hostname 0.0.0.0 > /tmp/hardhat.log 2>&1 &
NODE_PID=$!

echo "Waiting for node to start..."
sleep 5

echo "Deploying contracts..."
NODE_OPTIONS="--max-old-space-size=4096" npx hardhat run scripts/deploy.js --network localhost

echo "Deployment complete. Node is running..."
wait $NODE_PID
