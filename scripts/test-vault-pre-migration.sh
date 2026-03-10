#!/bin/bash
# Script to test Vault setup BEFORE migration
# This validates the current state and ensures everything is working

set -e

NAMESPACE="${1:-ibm-verify}"
VAULT_POD="vault-0"

echo "=========================================="
echo "Pre-Migration Vault Test"
echo "=========================================="
echo "Testing Vault in namespace: ${NAMESPACE}"
echo ""

# Test 1: Check if Vault pod exists
echo "Test 1: Checking Vault pod..."
if kubectl get pod -n ${NAMESPACE} ${VAULT_POD} &>/dev/null; then
    echo "  ✓ Vault pod exists"
else
    echo "  ✗ Vault pod not found"
    exit 1
fi

# Test 2: Check if Vault pod is running
echo "Test 2: Checking Vault pod status..."
POD_STATUS=$(kubectl get pod -n ${NAMESPACE} ${VAULT_POD} -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" = "Running" ]; then
    echo "  ✓ Vault pod is running"
else
    echo "  ✗ Vault pod is not running (status: ${POD_STATUS})"
    exit 1
fi

# Test 3: Check Vault status
echo "Test 3: Checking Vault status..."
if kubectl exec -n ${NAMESPACE} ${VAULT_POD} -- vault status &>/dev/null; then
    VAULT_STATUS=$(kubectl exec -n ${NAMESPACE} ${VAULT_POD} -- vault status -format=json)
    INITIALIZED=$(echo "$VAULT_STATUS" | jq -r '.initialized')
    SEALED=$(echo "$VAULT_STATUS" | jq -r '.sealed')
    
    echo "  Initialized: ${INITIALIZED}"
    echo "  Sealed: ${SEALED}"
    
    if [ "$INITIALIZED" = "true" ]; then
        echo "  ✓ Vault is initialized"
    else
        echo "  ✗ Vault is not initialized"
        exit 1
    fi
    
    if [ "$SEALED" = "false" ]; then
        echo "  ✓ Vault is unsealed"
    else
        echo "  ✗ Vault is sealed"
        exit 1
    fi
else
    echo "  ✗ Cannot connect to Vault"
    exit 1
fi

# Test 4: Check if secrets exist
echo "Test 4: Checking for secrets..."
if kubectl get secret -n ${NAMESPACE} ivia-secrets &>/dev/null; then
    echo "  ✓ Kubernetes secret 'ivia-secrets' exists"
else
    echo "  ⚠ Kubernetes secret 'ivia-secrets' not found (may not be synced yet)"
fi

# Test 5: Check VaultStaticSecret
echo "Test 5: Checking VaultStaticSecret..."
if kubectl get vaultstaticsecret -n ${NAMESPACE} &>/dev/null; then
    VSS_COUNT=$(kubectl get vaultstaticsecret -n ${NAMESPACE} --no-headers 2>/dev/null | wc -l)
    echo "  ✓ Found ${VSS_COUNT} VaultStaticSecret(s)"
    
    # Check status of each VaultStaticSecret
    kubectl get vaultstaticsecret -n ${NAMESPACE} -o json | jq -r '.items[] | "\(.metadata.name): \(.status.conditions[0].type) - \(.status.conditions[0].reason)"' 2>/dev/null || true
else
    echo "  ⚠ No VaultStaticSecret resources found"
fi

# Test 6: Check VaultConnection
echo "Test 6: Checking VaultConnection..."
if kubectl get vaultconnection -n ${NAMESPACE} &>/dev/null; then
    VC_COUNT=$(kubectl get vaultconnection -n ${NAMESPACE} --no-headers 2>/dev/null | wc -l)
    echo "  ✓ Found ${VC_COUNT} VaultConnection(s)"
    
    # Show connection details
    kubectl get vaultconnection -n ${NAMESPACE} -o json | jq -r '.items[] | "  \(.metadata.name): \(.spec.address)"' 2>/dev/null || true
else
    echo "  ⚠ No VaultConnection resources found"
fi

# Test 7: Check VaultAuth
echo "Test 7: Checking VaultAuth..."
if kubectl get vaultauth -n ${NAMESPACE} &>/dev/null; then
    VA_COUNT=$(kubectl get vaultauth -n ${NAMESPACE} --no-headers 2>/dev/null | wc -l)
    echo "  ✓ Found ${VA_COUNT} VaultAuth(s)"
else
    echo "  ⚠ No VaultAuth resources found"
fi

# Test 8: List Vault secrets
echo "Test 8: Listing Vault secrets..."
SECRETS_LIST=$(kubectl exec -n ${NAMESPACE} ${VAULT_POD} -- vault kv list -format=json ibm-verify 2>/dev/null || echo "[]")
SECRET_COUNT=$(echo "$SECRETS_LIST" | jq '. | length')
echo "  Found ${SECRET_COUNT} secret(s) in Vault"
if [ "$SECRET_COUNT" -gt 0 ]; then
    echo "$SECRETS_LIST" | jq -r '.[]' | sed 's/^/    - /'
fi

echo ""
echo "=========================================="
echo "Pre-Migration Test Summary"
echo "=========================================="
echo "Vault is ready for migration!"
echo ""
echo "Next steps:"
echo "  1. Run backup script: ./scripts/backup-vault-data.sh"
echo "  2. Deploy new Vault to 'vault' namespace"
echo "  3. Run restore script: ./scripts/restore-vault-data.sh"
echo "  4. Run post-migration tests: ./scripts/test-vault-post-migration.sh"

# Made with Bob
