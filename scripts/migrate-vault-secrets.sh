#!/bin/bash
# Script to migrate secrets from old Vault to new Vault
# This is an alternative to snapshot restore for manual secret migration

set -e

SOURCE_NAMESPACE="${1:-ibm-verify}"
TARGET_NAMESPACE="${2:-vault}"
SECRET_PATH="${3:-ibm-verify}"

echo "=========================================="
echo "Vault Secrets Migration Script"
echo "=========================================="
echo "Source Namespace: ${SOURCE_NAMESPACE}"
echo "Target Namespace: ${TARGET_NAMESPACE}"
echo "Secret Path: ${SECRET_PATH}"
echo ""

SOURCE_POD="vault-0"
TARGET_POD="vault-0"

# Check if source Vault pod exists
echo "Checking source Vault pod..."
if ! kubectl get pod -n ${SOURCE_NAMESPACE} ${SOURCE_POD} &>/dev/null; then
    echo "ERROR: Source Vault pod ${SOURCE_POD} not found in namespace ${SOURCE_NAMESPACE}"
    exit 1
fi

# Check if target Vault pod exists
echo "Checking target Vault pod..."
if ! kubectl get pod -n ${TARGET_NAMESPACE} ${TARGET_POD} &>/dev/null; then
    echo "ERROR: Target Vault pod ${TARGET_POD} not found in namespace ${TARGET_NAMESPACE}"
    exit 1
fi

# Check if both Vaults are unsealed
echo "Checking Vault seal status..."
SOURCE_SEALED=$(kubectl exec -n ${SOURCE_NAMESPACE} ${SOURCE_POD} -- vault status -format=json 2>/dev/null | jq -r '.sealed')
TARGET_SEALED=$(kubectl exec -n ${TARGET_NAMESPACE} ${TARGET_POD} -- vault status -format=json 2>/dev/null | jq -r '.sealed')

if [ "$SOURCE_SEALED" = "true" ]; then
    echo "ERROR: Source Vault is sealed"
    exit 1
fi

if [ "$TARGET_SEALED" = "true" ]; then
    echo "ERROR: Target Vault is sealed"
    exit 1
fi

echo "Both Vaults are unsealed and ready."
echo ""

# Enable KV v2 secrets engine in target Vault if not already enabled
echo "Enabling KV v2 secrets engine in target Vault..."
kubectl exec -n ${TARGET_NAMESPACE} ${TARGET_POD} -- vault secrets enable -path=${SECRET_PATH} kv-v2 2>/dev/null || echo "KV v2 already enabled at ${SECRET_PATH}"

# Get list of secrets from source Vault
echo ""
echo "Retrieving secrets list from source Vault..."
SECRETS_JSON=$(kubectl exec -n ${SOURCE_NAMESPACE} ${SOURCE_POD} -- vault kv list -format=json ${SECRET_PATH} 2>/dev/null || echo "[]")

if [ "$SECRETS_JSON" = "[]" ]; then
    echo "No secrets found in source Vault at path ${SECRET_PATH}"
    exit 0
fi

# Parse secrets list
SECRETS=$(echo "$SECRETS_JSON" | jq -r '.[]')

if [ -z "$SECRETS" ]; then
    echo "No secrets to migrate"
    exit 0
fi

echo "Found secrets to migrate:"
echo "$SECRETS"
echo ""

# Migrate each secret
for SECRET in $SECRETS; do
    echo "Migrating secret: ${SECRET_PATH}/${SECRET}"
    
    # Get secret from source
    SECRET_DATA=$(kubectl exec -n ${SOURCE_NAMESPACE} ${SOURCE_POD} -- \
        vault kv get -format=json ${SECRET_PATH}/${SECRET} 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo "  WARNING: Failed to read secret ${SECRET}, skipping..."
        continue
    fi
    
    # Extract the data field
    SECRET_VALUES=$(echo "$SECRET_DATA" | jq -r '.data.data')
    
    # Write secret to target
    echo "$SECRET_VALUES" | kubectl exec -i -n ${TARGET_NAMESPACE} ${TARGET_POD} -- \
        vault kv put ${SECRET_PATH}/${SECRET} - 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Successfully migrated ${SECRET}"
    else
        echo "  ✗ Failed to migrate ${SECRET}"
    fi
done

echo ""
echo "=========================================="
echo "Migration completed!"
echo "=========================================="
echo ""
echo "Please verify the secrets in the target Vault:"
echo "  kubectl exec -n ${TARGET_NAMESPACE} ${TARGET_POD} -- vault kv list ${SECRET_PATH}"

# Made with Bob
