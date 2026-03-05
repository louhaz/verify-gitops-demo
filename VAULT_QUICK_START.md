
# Vault Integration Quick Start

This is a condensed guide for quickly integrating Vault into your IBM Verify GitOps setup. For detailed information, see [VAULT_INTEGRATION.md](VAULT_INTEGRATION.md).

## Prerequisites

- ArgoCD/OpenShift GitOps installed
- `ibm-verify` namespace created
- Vault CLI installed locally
- Cluster admin access

## Quick Setup (5 Steps)

### 1. Create Initial Secrets

```bash
oc create -n ibm-verify secret generic ivia-secrets \
  --from-literal=aac-code=<AAC activation code> \
  --from-literal=base-code=<base activation code> \
  --from-literal=fed-code=<federation activation code> \
  --from-literal=cfgsvc-passwd=<configuration service password> \
  --from-literal=ldap-binddn=<LDAP bind dn> \
  --from-literal=ldap-passwd=<LDAP password> \
  --from-literal=postgres-passwd=<postgres password> \
  --from-literal=sec-passwd=<sec-master password>
```

### 2. Deploy Everything via ArgoCD

```bash
oc apply -f argocd/bootstrap.yaml
```

This will automatically deploy:
- Vault operators (already configured)
- Vault server
- Vault configuration
- All IBM Verify components

### 3. Wait for Vault to be Ready

```bash
oc wait --for=condition=ready pod -l app.kubernetes.io/name=vault -n ibm-verify --timeout=300s
```

### 4. Initialize and Unseal Vault

```bash
# Port-forward to Vault
oc port-forward -n ibm-verify svc/vault 8200:8200 &

# Initialize Vault
vault operator init -key-shares=5 -key-threshold=3

# Save the output! You'll need the unseal keys and root token

# Unseal Vault (use 3 different unseal keys)
