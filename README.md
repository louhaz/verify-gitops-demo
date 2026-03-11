# ibm-verify-gitops

GitOps for IBM Verify Access

## Overview

![overview diagram](diagram/verify-gitops.drawio.png)

This repository uses ArgoCD (Red Hat OpenShift GitOps) to deploy IBM Verify Access operators and operands, including a basic runtime and web reverse proxy connected to a demo application. The deployment is fully automated using GitOps principles.

Automation is done using the [ibmvia_autoconf](https://lachlan-ibm.github.io/ibmvia_autoconf) Python library.

## Architecture

The deployment includes:
- **IBM Verify Access Operators**: Manages the lifecycle of Verify Access components
- **IBM Verify Directory Operator** (optional): For LDAP directory services
- **HashiCorp Vault** (optional): For secure secret management
- **PostgreSQL**: Database backend for Verify Access
- **OpenLDAP** (optional): Alternative LDAP solution
- **Demo Application**: Sample application for testing

## LDAP Options

There are several LDAP options provided:

- **Local (embedded) LDAP** - Default configuration
- **Remote LDAP** - Using the provided OpenLDAP image
- **IBM Verify Directory** - Enterprise LDAP solution

See [`components/autoconfig/base/config/config.yaml`](components/autoconfig/base/config/config.yaml) for configuration examples. Current configuration uses local (embedded) LDAP.

## Secret Management

This repository uses **HashiCorp Vault** for secure secret management. Vault provides:
- Centralized secret storage and management
- Dynamic secret generation
- Secret rotation capabilities
- Detailed audit logging
- Fine-grained access control
- Kubernetes authentication integration

Vault is automatically deployed as part of the GitOps bootstrap process and integrates seamlessly with IBM Verify Access components.

**📖 For detailed Vault configuration and troubleshooting, see [VAULT_INTEGRATION.md](VAULT_INTEGRATION.md)**

---

## Installation from Blank OpenShift Cluster

Follow these steps to deploy the complete environment on a fresh OpenShift cluster.

### Prerequisites

- **OpenShift Cluster**: Version 4.10 or later
- **Cluster Admin Access**: Required for operator installation
- **oc CLI**: OpenShift command-line tool installed and configured
- **Git**: For repository management
- **IBM Verify Access License**: Activation codes for AAC, base, and federation modules

### Step 1: Install OpenShift GitOps Operator

OpenShift GitOps (ArgoCD) must be installed first to manage all other deployments.

**Option A: Install via Web Console**

1. Log in to the OpenShift web console as a cluster administrator
2. Navigate to **Operators** → **OperatorHub**
3. Search for "OpenShift GitOps"
4. Click **Install** and accept the default settings
5. Wait for the operator to be installed (check **Operators** → **Installed Operators**)

**Option B: Install via CLI**

```bash
cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-gitops-operator
  namespace: openshift-operators
spec:
  channel: latest
  name: openshift-gitops-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
```

Wait for the operator to be ready:

```bash
oc wait --for=condition=Ready pod -l name=openshift-gitops-operator -n openshift-operators --timeout=300s
```

Verify ArgoCD is running:

```bash
oc get pods -n openshift-gitops
```

### Step 2: Fork and Configure Repository

1. **Fork this repository** to your own GitHub account or Git server

2. **Clone your forked repository:**

   ```bash
   git clone <git-repo-url>
   cd verify-gitops-demo
   ```

3. **Update the repository URL** in the following files:
   
   - `argocd/bootstrap.yaml` (line 14)
   - `argocd/kustomization.yaml` (lines 37 and 47)

   Replace `https://github.com/louhaz/verify-gitops-demo` with your forked repository URL.

4. **Commit and push changes:**

   ```bash
   git add argocd/bootstrap.yaml argocd/kustomization.yaml
   git commit -m "Update repository URL to forked repo"
   git push
   ```

### Step 3: Create the IBM Verify Namespace

Create the `ibm-verify` namespace where all IBM Verify components will be deployed:

```bash
oc new-project ibm-verify
```

### Step 4: Deploy the Bootstrap Application

Apply the ArgoCD bootstrap application to start the automated deployment:

```bash
oc apply -f argocd/bootstrap.yaml
```

This creates the bootstrap application that manages all other applications through GitOps, including:
- Vault deployment and configuration
- IBM Verify Access operators
- Supporting services (PostgreSQL, OpenLDAP)
- IBM Verify Access operands

**Note:** Vault will be automatically deployed as part of this bootstrap process. You'll configure it in Step 6.

### Step 5: Monitor Deployment Progress

**Access ArgoCD UI:**

1. Get the ArgoCD route:
   ```bash
   echo "https://$(oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}')"
   ```

2. Get the admin password:
   ```bash
   oc extract secret/openshift-gitops-cluster -n openshift-gitops --to=-
   ```

3. Log in to the ArgoCD UI with username `admin` and the password from step 2

**Monitor via CLI:**

```bash
# Watch all applications
watch oc get applications -n openshift-gitops

# Check specific application status
oc get application <app-name> -n openshift-gitops -o yaml

# View application sync status
oc get applications -n openshift-gitops -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status
```

**Check pod status in ibm-verify namespace:**

```bash
# Watch pods being created
watch oc get pods -n ibm-verify

# Check all resources
oc get all -n ibm-verify
```

**Deployment typically takes 10-15 minutes.** Applications will sync in waves:
1. Namespaces and common resources
2. Vault (if enabled) and RBAC
3. Operators (Verify Access, Verify Directory, Vault Config)
4. Vault server and configuration
5. Supporting services (PostgreSQL, OpenLDAP)
6. IBM Verify operands (Config, Runtime, WRP)
7. Autoconfiguration job
8. Demo application

### Step 6: Configure HashiCorp Vault

After the bootstrap deployment completes and Vault is running, you need to initialize and configure Vault to store secrets.

**Wait for Vault to be ready:**

```bash
# Wait for Vault pod to be ready
oc wait --for=condition=Ready pod -l app.kubernetes.io/name=vault -n vault --timeout=300s
```

**Initialize Vault (first time only):**

```bash
oc exec -n vault vault-0 -- vault operator init -key-shares=1 -key-threshold=1
```

**IMPORTANT:** Save the output! You'll receive:
- **Unseal Key**: Required to unseal Vault after restarts
- **Root Token**: Required for administrative access

Example output:
```
Unseal Key 1: <your-unseal-key-1>
Unseal Key 2: <your-unseal-key-2>
Unseal Key 3: <your-unseal-key-3>
Unseal Key 4: <your-unseal-key-4>
Unseal Key 5: <your-unseal-key-5>
Initial Root Token: <your-root-token>
```

**Unseal Vault:**

```bash
oc exec -n vault vault-0 -- vault operator unseal <your-unseal-key-1>
```
```bash
oc exec -n vault vault-0 -- vault operator unseal <your-unseal-key-2>
```
```bash
oc exec -n vault vault-0 -- vault operator unseal <your-unseal-key-3>
```

**Configure Vault authentication:**

```bash
# Set the root token as an environment variable
export VAULT_TOKEN=<your-root-token>

# Run the configuration script to set up Kubernetes authentication
./scripts/configure-vault.sh
```

This script configures:
- Kubernetes authentication method
- Vault policies for IBM Verify Access
- Authentication roles for service accounts

**Enable KV secrets engine:**

```bash
oc exec -n vault vault-0 -- vault secrets enable -path=ibm-verify kv-v2
```

**Store IBM Verify Access secrets in Vault:**

Replace all values marked with `<>`:

```bash
oc exec -n vault vault-0 -- vault kv put ibm-verify/ivia-secrets \
  aac-code=<AAC activation code> \
  base-code=<base activation code> \
  fed-code=<federation activation code> \
  cfgsvc-passwd=<configuration service password> \
  ldap-binddn=<LDAP bind DN> \
  ldap-passwd=<LDAP password> \
  postgres-passwd=<postgres password> \
  sec-passwd=<sec-master password>
```

**Important Notes:**
- `ldap-binddn` should be `cn=root` for IBM Verify Directory
- `ldap-binddn` should be `cn=root,secAuthority=Default` for OpenLDAP (local or remote)

**For IBM Verify Directory (Optional - only if using Verify Directory):**

```bash
# Store Verify Directory secrets
oc exec -n vault vault-0 -- vault kv put ibm-verify/isvd-secret \
  admin_password=<admin password> \
  license-key=<license key> \
  replication_password=<replication password>

# Store certificates (requires base64 encoding)
oc exec -n vault vault-0 -- vault kv put ibm-verify/isvd-certs \
  server_cert="$(cat <path-to-server-cert.pem> | base64)" \
  server_key="$(cat <path-to-server-key.pem> | base64)"
```

**Verify that secrets are stored:**

```bash
# List secrets
oc exec -n vault vault-0 -- vault kv list ibm-verify

# Read a secret (to verify)
oc exec -n vault vault-0 -- vault kv get ibm-verify/ivia-secrets
```

For detailed Vault configuration and troubleshooting, see [VAULT_INTEGRATION.md](VAULT_INTEGRATION.md).

### Step 7: Verify Deployment

Once Vault is configured and all applications show `Healthy` and `Synced` status:

**Check IBM Verify Access pods:**

```bash
oc get pods -n ibm-verify | grep ivia
```

You should see pods for:
- `ivia-config` - Configuration service
- `ivia-dsc` - Distributed Session Cache
- `ivia-runtime` - Runtime service
- `ivia-wrp` - Web Reverse Proxy

**Check operator pods:**

```bash
oc get pods -n ibm-verify | grep operator
```

**Verify Vault integration:**

```bash
# Check VaultAuth resource
oc get vaultauth -n ibm-verify

# Check VaultStaticSecret resources
oc get vaultstaticsecret -n ibm-verify

# Verify secrets are synced from Vault
oc get secrets -n ibm-verify | grep vault
```

### Step 8: Access Deployed Services

**IBM Verify Access Configuration Service:**

```bash
echo "https://$(oc get route -n ibm-verify ivia-config -o jsonpath='{.spec.host}')"
```

Access the configuration UI at this URL with the credentials you set in `cfgsvc-passwd`.

**IBM Verify Access Web Reverse Proxy:**

```bash
echo "https://$(oc get route -n ibm-verify ivia-wrp -o jsonpath='{.spec.host}')"
```

**Vault UI (if using Vault):**

```bash
echo "http://$(oc get route -n vault vault-ui -o jsonpath='{.spec.host}')"
```

Log in with the root token from Vault initialization.

**PostgreSQL (internal service):**

```bash
oc get svc -n ibm-verify postgresql
```

---



## Additional Resources

- [IBM Verify Access Documentation](https://www.ibm.com/docs/en/sva)
- [IBM Verify Directory Documentation](https://www.ibm.com/docs/en/svd)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [OpenShift GitOps Documentation](https://docs.openshift.com/gitops/)
- [HashiCorp Vault Documentation](https://www.vaultproject.io/docs)
- [Vault Integration Guide](VAULT_INTEGRATION.md)
- [ibmvia_autoconf Library](https://lachlan-ibm.github.io/ibmvia_autoconf)

---

**This deployment provides a complete GitOps-based IBM Verify Access environment with optional HashiCorp Vault integration for enhanced security.**
