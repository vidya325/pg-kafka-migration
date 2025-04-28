#!/bin/bash

set -e

# Select environment
echo "Select environment:"
select ENVIRONMENT in "default" "staging" "prod"; do
  if [[ -n "$ENVIRONMENT" ]]; then
    echo "Selected environment: $ENVIRONMENT"
    break
  else
    echo "Invalid selection. Please try again."
  fi
done

# Set environment
if [[ "$ENVIRONMENT" == "staging" ]]; then
  ENV_ID="env-5w69yz"
  CLUSTER_ID="lkc-w53vq9"
elif [[ "$ENVIRONMENT" == "prod" ]]; then
  ENV_ID="env-prw73y"
  CLUSTER_ID="lkc-1jqgp6"
else
  ENV_ID="env-oqx7py"
  CLUSTER_ID="lkc-gn2vkm"
fi

confluent environment use $ENV_ID
confluent kafka cluster use $CLUSTER_ID

# Create directory
mkdir -p api-keys
cd api-keys

# Export API keys
echo "Exporting API keys for cluster $CLUSTER_ID..."
confluent api-key list --resource $CLUSTER_ID -o json > $ENVIRONMENT-api-keys.json

echo "API keys exported to $(pwd)/api-keys.json"
