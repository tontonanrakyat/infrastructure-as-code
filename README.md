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
* [05. Refactoring & Modularity (Standardization)](#05-refactoring--modularity-standardization)

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
| **GCP SDK** | `curl https://sdk.cloud.google.com` |

**Verification:**

```bash
terraform -version && az --version && aws --version && gcloud --version

```

### B. Cloud Backend Setup (Agnostic Prep)

#### 🔵 Azure Setup

*Penamaan diseragamkan dengan format: st[brand][function]*

```bash
# Provisioning Backend State
az group create --name rg-infra-mgmt --location indonesiacentral
az storage account create --name stveritastfstate --resource-group rg-infra-mgmt --location indonesiacentral --sku Standard_LRS
az storage container create --name tfstate --account-name stveritastfstate

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
 ┣ 📂modules                # Reusable Components (Blueprints)
 ┃ ┗ 📂azure-resource-group # Specific Resource Module
 ┣ 📄.gitignore             # Security Filter
 ┗ 📄README.md

```

### B. Operational Commands

| Step | Command | Description |
| --- | --- | --- |
| **1. Init** | `terraform init` | Connect to Cloud Backend & Download Providers. **Re-run after adding modules.** |
| **2. Plan** | `terraform plan` | Dry-run validation (Execution Strategy). |
| **3. Apply** | `terraform apply` | Provisioning real resources to Cloud. **Git-only on Production.** |

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
* **Idempotency:** Automatic check on every run. **Manual Apply is prohibited in main.**

---

## 05. Refactoring & Modularity (Standardization)

Fase transformasi dari kode *Monolith* ke *Reusable Modules* untuk mencapai skalabilitas Enterprise.

### A. Core Philosophy

* **DRY (Don't Repeat Yourself)**: Satu modul digunakan oleh banyak environment.
* **Abstraction**: Menyembunyikan kompleksitas resource Azure di belakang variabel sederhana.
* **State Integrity**: Mengelola "ingatan" Terraform agar tidak terjadi penghapusan data secara tidak sengaja.

### B. The `state mv` Ceremony

Saat memindahkan resource fisik ke dalam modul, alamat resource di dalam State berubah. Gunakan perintah ini untuk memindahkan catatan tanpa menghapus resource asli:

```bash
# Format: terraform state mv [SOURCE_ADDRESS] [DESTINATION_ADDRESS]
terraform state mv azurerm_resource_group.rg_dev_app module.rg_app.azurerm_resource_group.this

```

### C. RCA Matrix: Refactoring Issues

| Issue | Root Cause | Remediation |
| --- | --- | --- |
| `1 added, 1 destroyed` | Terraform misidentifies refactored code as new resource. | Run `terraform state mv` before applying. |
| `Module not found` | `terraform init` was not run after adding module block. | Run `terraform init` to download/link modules. |
| `0 added, 1 changed` | Code changes only affect metadata (tags). | Safe to apply. Expected during standardization. |

### D. Architectural Concepts

* **Backend (Azure Storage)**: Database tempat menyimpan file `.tfstate`. Diperbarui saat `state mv` meskipun infrastruktur tidak berubah.
* **Infrastructure (Azure Resource Manager)**: Barang fisik (RG, VM, DB). Tidak tersentuh jika hanya melakukan `state mv`.

---

