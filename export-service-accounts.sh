#!/bin/bash

set -e

# echo "🔐 Logging into Confluent Cloud..."
# Uncomment if you want auto login
# confluent login

echo "Exporting Service Accounts..."

# Fetch service accounts
confluent iam service-account list -o json > service-accounts-export.json

echo "Service Accounts exported to service-accounts-export.json"