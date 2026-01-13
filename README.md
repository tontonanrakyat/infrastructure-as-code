# 🤖 Infrastructure as Code (IaC) - Veritas Project

> All infrastructure is managed via Code. Manual changes in the Portal are strictly prohibited.
> **Trust No One, Encrypt Everything, Automate or Die.**


---

## 📋 Table of Contents
* [00. Pre-Requisites (Management Layer)](#00-pre-requisites-manual-setup)
* [01. Identity & Access Management](#01-identity--access-management-service-principal)
* [02. Terraform Foundation](#02-infrastructure-structure-terraform-foundation)
* [03. Identity Impersonation (Validation)](#03-identity-impersonation-local-robot-test)
* [04. GitHub Automation (CI/CD)](#04-github-automation-cicd-pipeline)

---

## 00. Pre-Requisites (Manual Setup)

Persiapan **Management Layer**. Dilakukan manual satu kali untuk menginisialisasi "State" (ingatan) Terraform di Cloud.

### A. Local Environment

| Tool | Installation Link / Command |
| --- | --- |
| **Terraform CLI** | [Download Here](https://www.terraform.io/downloads) |
| **Git** | Standard Installation |
| **Azure CLI** | `winget install -e --id Microsoft.AzureCLI` |
| **AWS CLI** | MSI Installer / `brew install awscli` |
| **GCP SDK** | `curl https://sdk.cloud.google.com |

**Verification:**

```bash
terraform -version && az --version && aws --version && gcloud --version
```

### B. Cloud Backend Setup (Agnostic Prep)

#### 🔵 Azure Setup

```bash
# Provisioning Backend State
az group create --name rg-infra-mgmt --location indonesiacentral
az storage account create --name staccveritas --resource-group rg-infra-mgmt --location indonesiacentral --sku Standard_LRS
az storage container create --name tfstate --account-name staccveritas
```

#### 🟠 AWS Setup

```bash
aws s3api create-bucket --bucket stveritastfstate --region us-east-1
aws dynamodb create-table --table-name terraform-state-lock --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

#### 🟡 GCP Setup

```bash
gsutil mb -p [PROJECT_ID] -l asia-southeast2 gs://stveritastfstate/
gsutil versioning set on gs://stveritastfstate/
```

---

## 01. Identity & Access Management (Service Principal)

Menciptakan **Identitas Digital** non-manusia untuk robot automasi.

### A. Service Principal (Identity)

```bash
# Registrasi & Role Assignment (Contributor)
az ad sp create-for-rbac --name "sp-terraform" --role contributor --scopes /subscriptions/[SUBSCRIPTION_ID] --json-auth
```

### B. Security Vault (Azure Key Vault)

Penerapan prinsip **Encrypt Everything**.

```bash
# Register Provider & Create Vault
az provider register --namespace Microsoft.KeyVault
az keyvault create --name "kv-veritas-mgmt" --resource-group "rg-infra-mgmt" --location "indonesiacentral"
```

### C. Secret Storage Mapping

```bash
# Assign Role 'Key Vault Secrets Officer' to Admin
az role assignment create --role "Key Vault Secrets Officer" --assignee [USER_ID] --scope [VAULT_SCOPE]

# Set Secrets
az keyvault secret set --vault-name "kv-veritas-mgmt" --name "terraform-client-id" --value "[APP/CLIENT_ID]"
az keyvault secret set --vault-name "kv-veritas-mgmt" --name "terraform-client-secret" --value "[APP/CLIENT_PASSWORD]"
az keyvault secret set --vault-name "kv-veritas-mgmt" --name "terraform-tenant-id" --value "[TENANT_ID]"
```

---

## 02. Infrastructure Structure (Terraform Foundation)

### A. Directory Hierarchy

```text
📦infrastructure-as-code
 ┣ 📂.github/workflows      # CI/CD Pipeline
 ┣ 📂environments           # Configuration per Life-cycle
 ┃ ┗ 📂labx                 # Project Name
 ┃ ┃ ┗ 📂dev                # Stage: Development
 ┃ ┃   ┗ 📄main.tf          # Entry Point Blueprint
 ┣ 📂modules                # Reusable Components
 ┣ 📄.gitignore             # Security Filter
 ┗ 📄README.md

```

### B. Operational Commands

| Step | Command | Description |
| --- | --- | --- |
| **1. Init** | `terraform init` | Connect to Cloud Backend & Download Providers |
| **2. Plan** | `terraform plan` | Dry-run validation (Execution Strategy) |
| **3. Apply** | `terraform apply` | Provisioning real resources to Cloud |

### C. RCA: State Locking Failure

* **Symptom:** Hanging at `Acquiring state lock...`
* **Root Cause:** Blob Lease is active due to previous process crash.
* **Solution:** Azure Portal > Storage Account > `tfstate` Container > Right-click `.tfstate` file > **Break Lease**.

---

## 03. Identity Impersonation (Local Robot Test)

Validasi **Least Privilege** dan konektivitas robot sebelum integrasi CI/CD.

### A. Environment Variables Mapping (PowerShell)

```powershell
$env:ARM_CLIENT_ID       = "[APP/CLIENT_ID]"
$env:ARM_CLIENT_SECRET   = "[APP/CLIENT_PASSWORD]"
$env:ARM_TENANT_ID       = "[TENANT_ID]"
$env:ARM_SUBSCRIPTION_ID = "[SUBSCRIPTION_ID]"

```

### B. Validation Procedure

1. `az logout` (Zero Trust Verification).
2. `terraform plan` (Verify SP Token).
3. **Success:** Output `No changes. Your infrastructure matches the configuration.`

---

## 04. GitHub Automation (CI/CD Pipeline)

### A. GitHub Secrets Configuration

| Name | Description |
| --- | --- |
| `AZURE_CLIENT_ID` | Application (Client) ID |
| `AZURE_CLIENT_SECRET` | Client Secret String |
| `AZURE_TENANT_ID` | Directory (Tenant) ID |
| `AZURE_SUBSCRIPTION_ID` | Subscription ID |

### B. Pipeline Specification (`terraform.yml`)

* **Trigger:** Push to `main` branch or any Pull Request.
* **Security:** Secrets Masking (`***`) on logs.
* **Idempotency:** Automatic check on every run.

### C. Pipeline RCA Matrix

| Step | Failure Cause | Remediation |
| --- | --- | --- |
| **Init** | Incorrect Backend Config | Verify `backend "azurerm"` block in `main.tf` |
| **Plan** | Permission Denied | Verify SP Role in IAM Azure |
| **Apply** | Concurrency Conflict | Break Lease in Azure Storage |

---



