#!/bin/bash
# Script to reconfigure Vault Kubernetes authentication for cross-namespace access
# This script should be run after Vault is deployed to the vault namespace

set -e

VAULT_NAMESPACE="vault"
VAULT_POD="vault-0"

echo "=========================================="
echo "Reconfiguring Vault Kubernetes Auth"
echo "=========================================="

# Check if Vault pod is running
echo "Checking Vault pod status..."
if ! kubectl get pod -n ${VAULT_NAMESPACE} ${VAULT_POD} &>/dev/null; then
    echo "ERROR: Vault pod ${VAULT_POD} not found in namespace ${VAULT_NAMESPACE}"
    exit 1
fi

# Check if Vault is unsealed
echo "Checking Vault seal status..."
SEAL_STATUS=$(kubectl exec -n ${VAULT_NAMESPACE} ${VAULT_POD} -- vault status -format=json | jq -r '.sealed')
if [ "$SEAL_STATUS" = "true" ]; then
    echo "ERROR: Vault is sealed. Please unseal Vault first."
    exit 1
fi

echo "Vault is unsealed and ready."

# Configure Kubernetes auth method
echo ""
echo "Configuring Kubernetes auth method..."
kubectl exec -n ${VAULT_NAMESPACE} ${VAULT_POD} -- vault auth enable kubernetes 2>/dev/null || echo "Kubernetes auth already enabled"

# Configure Kubernetes auth with the Kubernetes API
echo "Setting Kubernetes auth configuration..."
kubectl exec -n ${VAULT_NAMESPACE} ${VAULT_POD} -- vault write auth/kubernetes/config \
    kubernetes_host="https://kubernetes.default.svc:443"

# Create policy for ibm-verify namespace
echo ""
echo "Creating ibm-verify policy..."
kubectl exec -n ${VAULT_NAMESPACE} ${VAULT_POD} -- vault policy write ibm-verify-policy - <<EOF
# Allow reading secrets from ibm-verify path
path "ibm-verify/*" {
  capabilities = ["read", "list"]
}

# Allow reading KV v2 secrets
path "ibm-verify/data/*" {
  capabilities = ["read", "list"]
}

path "ibm-verify/metadata/*" {
  capabilities = ["read", "list"]
}
EOF

# Create role for ibm-verify service account
echo ""
echo "Creating Kubernetes auth role for ibm-verify..."
kubectl exec -n ${VAULT_NAMESPACE} ${VAULT_POD} -- vault write auth/kubernetes/role/ibm-verify \
    bound_service_account_names=ibm-verify-sa \
    bound_service_account_namespaces=ibm-verify \
    policies=ibm-verify-policy \
    ttl=24h

echo ""
echo "=========================================="
echo "Vault Kubernetes auth configuration complete!"
echo "=========================================="
echo ""
echo "Service accounts in the ibm-verify namespace can now authenticate to Vault"
echo "using the 'ibm-verify' role."
echo ""
echo "To test authentication:"
echo "  kubectl exec -n ibm-verify <pod> -- vault login -method=kubernetes role=ibm-verify"

# Made with Bob
