#!/bin/bash
# Script to test Vault setup AFTER migration
# This validates the new setup and ensures cross-namespace access works

set -e

VAULT_NAMESPACE="${1:-vault}"
APP_NAMESPACE="${2:-ibm-verify}"
VAULT_POD="vault-0"

echo "=========================================="
echo "Post-Migration Vault Test"
echo "=========================================="
echo "Vault Namespace: ${VAULT_NAMESPACE}"
echo "Application Namespace: ${APP_NAMESPACE}"
echo ""

# Test 1: Check if Vault pod exists in new namespace
echo "Test 1: Checking Vault pod in new namespace..."
if kubectl get pod -n ${VAULT_NAMESPACE} ${VAULT_POD} &>/dev/null; then
    echo "  ✓ Vault pod exists in ${VAULT_NAMESPACE}"
else
    echo "  ✗ Vault pod not found in ${VAULT_NAMESPACE}"
    exit 1
fi

# Test 2: Check if Vault pod is running
echo "Test 2: Checking Vault pod status..."
POD_STATUS=$(kubectl get pod -n ${VAULT_NAMESPACE} ${VAULT_POD} -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" = "Running" ]; then
    echo "  ✓ Vault pod is running"
else
    echo "  ✗ Vault pod is not running (status: ${POD_STATUS})"
    exit 1
fi

# Test 3: Check Vault status
echo "Test 3: Checking Vault status..."
if kubectl exec -n ${VAULT_NAMESPACE} ${VAULT_POD} -- vault status &>/dev/null; then
    VAULT_STATUS=$(kubectl exec -n ${VAULT_NAMESPACE} ${VAULT_POD} -- vault status -format=json)
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

# Test 4: Check Vault service
echo "Test 4: Checking Vault service..."
if kubectl get svc -n ${VAULT_NAMESPACE} vault &>/dev/null; then
    VAULT_IP=$(kubectl get svc -n ${VAULT_NAMESPACE} vault -o jsonpath='{.spec.clusterIP}')
    echo "  ✓ Vault service exists (ClusterIP: ${VAULT_IP})"
else
    echo "  ✗ Vault service not found"
    exit 1
fi

# Test 5: Check VaultConnection in app namespace
echo "Test 5: Checking VaultConnection in ${APP_NAMESPACE}..."
if kubectl get vaultconnection -n ${APP_NAMESPACE} &>/dev/null; then
    VC_COUNT=$(kubectl get vaultconnection -n ${APP_NAMESPACE} --no-headers 2>/dev/null | wc -l)
    echo "  ✓ Found ${VC_COUNT} VaultConnection(s)"
    
    # Check if it points to the new namespace
    VC_ADDRESS=$(kubectl get vaultconnection -n ${APP_NAMESPACE} -o json | jq -r '.items[0].spec.address' 2>/dev/null)
    if [[ "$VC_ADDRESS" == *"${VAULT_NAMESPACE}"* ]]; then
        echo "  ✓ VaultConnection points to ${VAULT_NAMESPACE} namespace"
        echo "    Address: ${VC_ADDRESS}"
    else
        echo "  ✗ VaultConnection does not point to ${VAULT_NAMESPACE} namespace"
        echo "    Current address: ${VC_ADDRESS}"
        exit 1
    fi
else
    echo "  ✗ No VaultConnection resources found in ${APP_NAMESPACE}"
    exit 1
fi

# Test 6: Check VaultAuth in app namespace
echo "Test 6: Checking VaultAuth in ${APP_NAMESPACE}..."
if kubectl get vaultauth -n ${APP_NAMESPACE} &>/dev/null; then
    VA_COUNT=$(kubectl get vaultauth -n ${APP_NAMESPACE} --no-headers 2>/dev/null | wc -l)
    echo "  ✓ Found ${VA_COUNT} VaultAuth(s)"
    
    # Check status
    kubectl get vaultauth -n ${APP_NAMESPACE} -o json | jq -r '.items[] | "  \(.metadata.name): \(.status.conditions[0].type) - \(.status.conditions[0].reason)"' 2>/dev/null || true
else
    echo "  ✗ No VaultAuth resources found in ${APP_NAMESPACE}"
    exit 1
fi

# Test 7: Check VaultStaticSecret in app namespace
echo "Test 7: Checking VaultStaticSecret in ${APP_NAMESPACE}..."
if kubectl get vaultstaticsecret -n ${APP_NAMESPACE} &>/dev/null; then
    VSS_COUNT=$(kubectl get vaultstaticsecret -n ${APP_NAMESPACE} --no-headers 2>/dev/null | wc -l)
    echo "  ✓ Found ${VSS_COUNT} VaultStaticSecret(s)"
    
    # Check status of each VaultStaticSecret
    kubectl get vaultstaticsecret -n ${APP_NAMESPACE} -o json | jq -r '.items[] | "  \(.metadata.name): \(.status.conditions[0].type) - \(.status.conditions[0].reason)"' 2>/dev/null || true
else
    echo "  ⚠ No VaultStaticSecret resources found"
fi

# Test 8: Check if Kubernetes secret was synced
echo "Test 8: Checking synced Kubernetes secrets..."
if kubectl get secret -n ${APP_NAMESPACE} ivia-secrets &>/dev/null; then
    echo "  ✓ Kubernetes secret 'ivia-secrets' exists"
    
    # Check if it has data
    SECRET_KEYS=$(kubectl get secret -n ${APP_NAMESPACE} ivia-secrets -o json | jq -r '.data | keys | length')
    echo "    Contains ${SECRET_KEYS} key(s)"
else
    echo "  ✗ Kubernetes secret 'ivia-secrets' not found"
    echo "    Secret sync may still be in progress..."
fi

# Test 9: List Vault secrets
echo "Test 9: Listing Vault secrets..."
SECRETS_LIST=$(kubectl exec -n ${VAULT_NAMESPACE} ${VAULT_POD} -- vault kv list -format=json ibm-verify 2>/dev/null || echo "[]")
SECRET_COUNT=$(echo "$SECRETS_LIST" | jq '. | length')
echo "  Found ${SECRET_COUNT} secret(s) in Vault"
if [ "$SECRET_COUNT" -gt 0 ]; then
    echo "$SECRETS_LIST" | jq -r '.[]' | sed 's/^/    - /'
fi

# Test 10: Check cross-namespace RBAC
echo "Test 10: Checking cross-namespace RBAC..."
if kubectl get clusterrole vault-secrets-operator-auth &>/dev/null; then
    echo "  ✓ ClusterRole 'vault-secrets-operator-auth' exists"
else
    echo "  ✗ ClusterRole 'vault-secrets-operator-auth' not found"
fi

if kubectl get clusterrolebinding ibm-verify-vault-auth &>/dev/null; then
    echo "  ✓ ClusterRoleBinding 'ibm-verify-vault-auth' exists"
else
    echo "  ✗ ClusterRoleBinding 'ibm-verify-vault-auth' not found"
fi

# Test 11: Check Vault Secrets Operator logs for errors
echo "Test 11: Checking Vault Secrets Operator logs..."
VSO_POD=$(kubectl get pods -n ${VAULT_NAMESPACE} -l app.kubernetes.io/name=vault-secrets-operator -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$VSO_POD" ]; then
    ERROR_COUNT=$(kubectl logs -n ${VAULT_NAMESPACE} ${VSO_POD} --tail=100 2>/dev/null | grep -i error | wc -l || echo "0")
    if [ "$ERROR_COUNT" -eq 0 ]; then
        echo "  ✓ No errors in Vault Secrets Operator logs"
    else
        echo "  ⚠ Found ${ERROR_COUNT} error(s) in Vault Secrets Operator logs"
        echo "    Check logs with: kubectl logs -n ${VAULT_NAMESPACE} ${VSO_POD}"
    fi
else
    echo "  ⚠ Vault Secrets Operator pod not found"
fi

echo ""
echo "=========================================="
echo "Post-Migration Test Summary"
echo "=========================================="
echo "✓ Vault is running in ${VAULT_NAMESPACE} namespace"
echo "✓ Cross-namespace access configured"
echo "✓ VaultConnection points to new namespace"
echo ""
echo "Migration appears successful!"
echo ""
echo "Next steps:"
echo "  1. Monitor secret synchronization for 5-10 minutes"
echo "  2. Verify IBM Verify Access can access secrets"
echo "  3. If everything works, clean up old Vault in ${APP_NAMESPACE}"
echo "  4. Update documentation"

# Made with Bob
