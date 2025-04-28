#!/bin/bash

set -e

# NOTE: for staging and prod, run https://github.com/policygenius/kubernetes-confluent-cloud-proxy 

# # Prompt for credentials
echo "Logging into Confluent Cloud..."
confluent login 

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

echo "Exporting Kafka topics and configurations from cluster $CLUSTER_ID..."

# List all topic names
TOPICS=$(confluent kafka topic list -o json | jq -r '.[].name')

# Create directory
mkdir -p topics
cd topics

# Begin JSON file
echo "{" > $ENVIRONMENT-topics-export.json

# Loop through each topic and fetch config
for topic in $TOPICS; do
  CONFIG=$(confluent kafka topic describe "$topic" -o json)
  PARTITIONS=$(echo "$CONFIG" | jq '.partition_count')
  CONFIGS=$(echo "$CONFIG" | jq '.configs // []')
  CONFIG_MAP=$(echo "$CONFIGS" | jq '[.[] | select(.name != "message.timestamp.type")] | map({(.name): .value}) | add')

  echo "  \"$topic\": {" >> $ENVIRONMENT-topics-export.json
  echo "    \"partitions_count\": $PARTITIONS," >> $ENVIRONMENT-topics-export.json
  echo "    \"config\": $CONFIG_MAP" >> $ENVIRONMENT-topics-export.json
  echo "  }," >> $ENVIRONMENT-topics-export.json
done

# Clean up trailing comma
sed -i '' '$ s/,$//' $ENVIRONMENT-topics-export.json 2>/dev/null || sed -i '$ s/,$//' $ENVIRONMENT-topics-export.json

echo "}" >> $ENVIRONMENT-topics-export.json

echo "Topics exported to $ENVIRONMENT-topics-export.json"
