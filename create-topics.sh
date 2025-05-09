#!/bin/bash

# Usage: ./create-kafka-topics.sh topics.json

JSON_FILE="$1"

if [[ -z "$JSON_FILE" ]]; then
  echo "Usage: $0 <topics.json>"
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "Error: 'jq' is required but not installed."
  exit 1
fi

if ! command -v confluent &>/dev/null; then
  echo "Error: 'confluent' CLI is not installed."
  exit 1
fi

# Ensure you're logged in
if ! confluent user login describe &>/dev/null; then
  echo "Logging into Confluent Cloud..."
  confluent login || { echo "Login failed"; exit 1; }
fi

if [[ -z "$API_KEY" ]]; then
  read -rp "Enter your Confluent API Key: " API_KEY
fi
if [[ -z "$API_SECRET" ]]; then
  read -rsp "Enter your Confluent API Secret: " API_SECRET
  echo
fi


echo "Fetching available Confluent environments..."
ENVIRONMENTS_JSON=$(confluent environment list -o json)

# Extract names and ids
ENV_NAMES=($(echo "$ENVIRONMENTS_JSON" | jq -r '.[].name'))
ENV_IDS=($(echo "$ENVIRONMENTS_JSON" | jq -r '.[].id'))

if [[ ${#ENV_NAMES[@]} -eq 0 ]]; then
  echo "No environments found."
  exit 1
fi

echo ""
echo "Select a Confluent environment:"
select ENV_NAME in "${ENV_NAMES[@]}"; do
  if [[ -n "$ENV_NAME" ]]; then
    # Find the selected index
    INDEX=$((REPLY-1))
    ENV_ID=${ENV_IDS[$INDEX]}
    echo "Selected environment: $ENV_NAME ($ENV_ID)"
    confluent environment use "$ENV_ID"
    break
  else
    echo "Invalid selection. Please try again."
  fi
done

# Always list Kafka clusters for user to choose
echo ""
echo "Fetching available Kafka clusters..."
CLUSTERS=$(confluent kafka cluster list -o json)

echo ""
echo "Available Kafka Clusters:"
echo "$CLUSTERS" | jq -r '.[] | "\(.id)\t\(.name)\t(\(.environment.name))"'

echo ""
read -rp "Enter the Kafka cluster ID to use: " CLUSTER_ID

# Store and use the API key for this cluster
echo "Configuring API key for Kafka cluster..."
confluent api-key store "$API_KEY" "$API_SECRET" --resource "$CLUSTER_ID" || {
  echo "Failed to store API key"
  exit 1
}

confluent api-key use "$API_KEY" --resource "$CLUSTER_ID" || {
  echo "Failed to use API key"
  exit 1
}

# Select the cluster
confluent kafka cluster use "$CLUSTER_ID" || { echo "Failed to select cluster"; exit 1; }

# Create topics from JSON
echo ""
echo "Creating Kafka topics from $JSON_FILE..."

jq -r 'to_entries[] | "\(.key) \(.value.partitions_count)"' "$JSON_FILE" | while read -r TOPIC PARTITIONS; do
  echo "Creating topic: $TOPIC with $PARTITIONS partitions"

  confluent kafka topic create "$TOPIC" \
    --partitions "$PARTITIONS" || echo "Failed to create $TOPIC (maybe already exists?)"
done



: <<'END_COMMENT'
PG Staging topics - Zinnia-qa cluster

Creating Kafka topics from topics/staging-topics-export.json...
Creating topic: _confluent-ksql-pksqlc-k17zgquery_CTAS_QUERYABLE_AUTOMATIONS_EVENTS_TBL_9-KsqlTopic-Reduce-changelog with 12 partitions
Created topic "_confluent-ksql-pksqlc-k17zgquery_CTAS_QUERYABLE_AUTOMATIONS_EVENTS_TBL_9-KsqlTopic-Reduce-changelog".
Creating topic: autm.progress.delta.v0 with 12 partitions
Created topic "autm.progress.delta.v0".
Creating topic: ful.internal-case-conversation.comp.v0 with 24 partitions
Created topic "ful.internal-case-conversation.comp.v0".
Creating topic: ful.internal-cases.comp.v0 with 24 partitions
Created topic "ful.internal-cases.comp.v0".
Creating topic: ful.vendor-referral.fact.v0 with 12 partitions
Created topic "ful.vendor-referral.fact.v0".
Creating topic: pg.eng.experimental.fulfillment.internal-case-changed.v0 with 30 partitions
Created topic "pg.eng.experimental.fulfillment.internal-case-changed.v0".
Creating topic: pksqlc-k17zg-processing-log with 8 partitions
Created topic "pksqlc-k17zg-processing-log".
Creating topic: pksqlc-k17zgAUTOMATIONS_ACTIONS_STARTED with 12 partitions
Created topic "pksqlc-k17zgAUTOMATIONS_ACTIONS_STARTED".
Creating topic: pksqlc-k17zgAUTOMATIONS_ACTIONS_SUCCEEDED with 12 partitions
Created topic "pksqlc-k17zgAUTOMATIONS_ACTIONS_SUCCEEDED".
Creating topic: pksqlc-k17zgQUERYABLE_AUTOMATIONS_EVENTS_TBL with 12 partitions
Created topic "pksqlc-k17zgQUERYABLE_AUTOMATIONS_EVENTS_TBL".
Creating topic: pksqlc-z55y3-processing-log with 8 partitions
Created topic "pksqlc-z55y3-processing-log".

zinnia_india@Sonawane-Vidya-J3JH65KJQ1 pg-kafka-migration % confluent kafka topic describe _confluent-ksql-pksqlc-k17zgquery_CTAS_QUERYABLE_AUTOMATIONS_EVENTS_TBL_9-KsqlTopic-Reduce-changelog
+--------------------+------------------------------------------------------------------------------------------------------+
| Name               | _confluent-ksql-pksqlc-k17zgquery_CTAS_QUERYABLE_AUTOMATIONS_EVENTS_TBL_9-KsqlTopic-Reduce-changelog |
| Internal           | false                                                                                                |
| Replication Factor | 3                                                                                                    |
| Partition Count    | 12                                                                                                   |
+--------------------+------------------------------------------------------------------------------------------------------+

END_COMMENT