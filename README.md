# Infrastructure as Code (IaC)

**Philosophy: Trust No One, Encrypt Everything, Automate or Die.**

---

## 00. Pre-Requisites (Manual Setup)

Langkah ini adalah persiapan Management Layer. Dilakukan secara manual satu kali untuk menyiapkan tempat penyimpanan "State" (ingatan) Terraform di Cloud.

### A. Persiapan Local Environment

Instalasi alat kerja pada laptop Anda sesuai kebutuhan Cloud Provider target.

**1. Core Tools (Wajib)**

* **Terraform CLI**
[Unduh di sini](https://www.terraform.io/downloads)
* **Git**
Untuk manajemen repositori.

**2. Cloud-Specific CLI**

* **Azure CLI (az)**
Windows: `winget install -e --id Microsoft.AzureCLI`
macOS: `brew install azure-cli`
Linux: `curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash`

* **AWS CLI (aws)**
Windows: MSI Installer
macOS: `brew install awscli`
Linux: `curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"`

* **Google Cloud SDK (gcloud & gsutil)**
Windows: Cloud SDK Installer
macOS/Linux : `curl https://sdk.cloud.google.com | bash`


**3. Verifikasi Instalasi**
Jalankan perintah berikut untuk memastikan semua tool terbaca oleh sistem:

```bash
terraform -version
az --version
aws --version
gcloud --version
```

---

### B. Azure Setup (Agnostic Prep)

Gunakan Azure CLI untuk memastikan konsistensi resource manajemen.

**1. Verifikasi Login**

```bash
az login
az account show --output table
```

**2. Provisioning Backend State**
Ubah **staccveritas** (storage account veritas) dengan nama unik pilihan Anda (hanya huruf kecil dan angka).

```bash
# Buat Resource Group khusus Manajemen
az group create --name rg-infra-mgmt --location indonesiacentral

# Buat Storage Account (Gudang Data State)
az storage account create --name staccveritas --resource-group rg-infra-mgmt --location indonesiacentral --sku Standard_LRS

# Buat Container (Folder di dalam Storage Account)
az storage container create --name tfstate --account-name staccveritas
```

---

### C. AWS Setup (Agnostic Prep)

Penyimpanan menggunakan S3 Bucket dan DynamoDB untuk fitur State Locking.

**1. Verifikasi Login**

```bash
aws configure
aws sts get-caller-identity
```

**2. Provisioning Backend State**

```bash
# 1. Buat S3 Bucket
aws s3api create-bucket --bucket veritasiac-state-2026 --region us-east-1

# 2. Buat DynamoDB Table (Untuk State Locking)
aws dynamodb create-table \
--table-name terraform-state-lock \
--attribute-definitions AttributeName=LockID,AttributeType=S \
--key-schema AttributeName=LockID,KeyType=HASH \
--provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

---

### D. GCP Setup (Agnostic Prep)

Penyimpanan menggunakan Google Cloud Storage (GCS) dengan fitur Versioning.

**1. Verifikasi Login**

```bash
gcloud auth login
gcloud config set project [PROJECT_ID]
```

**2. Provisioning Backend State**

```bash
# 1. Buat Bucket GCS
gsutil mb -p [PROJECT_ID] -l asia-southeast2 gs://veritasiac-state-2026/

# 2. Aktifkan Versioning
gsutil versioning set on gs://veritasiac-state-2026/
```

---

Dokumentasi untuk **Section 01** harus mencerminkan apa yang baru saja kita lalui: **Keamanan (Security), Pemisahan Hak Akses (Separation of Duties), dan Penyimpanan Aman (Secret Management).**

Berikut adalah draf dokumentasi untuk menyambung section sebelumnya:

---

## 01. Identity & Access Management (Service Principal)

Langkah ini bertujuan menciptakan "Identitas Digital" bagi robot (Terraform/GitHub Actions) agar dapat mengelola infrastruktur tanpa menggunakan akun personal.

### A. Pembuatan Service Principal (Identity)

Service Principal (SP) bertindak sebagai pengguna non-manusia. Kita memberikan role `Contributor` agar robot bisa membuat dan memodifikasi resource di Azure.

**1. Registrasi Identitas & Role Assignment**
Jalankan perintah ini untuk membuat identitas sekaligus memberikan izin akses pada level Subscription.

```bash
# Ganti [SUBSCRIPTION_ID] dengan ID dari 'az account show'
az ad sp create-for-rbac --name "sp-terraform" --role contributor --scopes /subscriptions/[SUBSCRIPTION_ID] --json-auth
```

> **Catatan Penting:** Simpan output JSON (terutama `clientSecret` atau `password`) karena Azure hanya menampilkannya sekali.

---

### B. Setup Security Vault (Key Vault)

Sesuai prinsip **Encrypt Everything**, rahasia (secrets) tidak boleh disimpan dalam file teks biasa. Kita menggunakan Azure Key Vault sebagai brankas digital.

**1. Registrasi Resource Provider**
Pastikan layanan Key Vault aktif di subscription Anda.

```bash
az provider register --namespace Microsoft.KeyVault
# Verifikasi status hingga "Registered"
az provider show -n Microsoft.KeyVault --query registrationState
```

**2. Provisioning Key Vault**
Buat brankas di dalam Resource Group manajemen.

```bash
az keyvault create --name "kv-veritas-mgmt" --resource-group "rg-infra-mgmt" --location "indonesiacentral"
```

---

### C. Konfigurasi Access & Secret Storage

Gunakan model **RBAC (Role-Based Access Control)** untuk mengizinkan diri Anda mengisi rahasia ke dalam Vault.

**1. Memberikan Izin Secrets Officer**
Dapatkan ID akun Anda dan berikan hak akses untuk mengelola data di dalam Vault.

```bash
# Dapatkan Object ID Anda
USER_ID=$(az ad signed-in-user show --query id -o tsv)

# Assign Role
az role assignment create --role "Key Vault Secrets Officer" --assignee $USER_ID --scope "/subscriptions/[SUBSCRIPTION_ID]/resourceGroups/rg-infra-mgmt/providers/Microsoft.KeyVault/vaults/kv-veritas-mgmt"
```

**2. Menyimpan Rahasia (Mapping variables)**
Simpan data Service Principal dengan nama yang standar agar mudah dikelola oleh sistem automasi.

```bash
# Simpan Client ID (App ID)
az keyvault secret set --vault-name "kv-veritas-mgmt" --name "terraform-client-id" --value "ISI_APP_ID"

# Simpan Client Secret (Password)
az keyvault secret set --vault-name "kv-veritas-mgmt" --name "terraform-client-secret" --value "ISI_PASSWORD"

# Simpan Tenant ID
az keyvault secret set --vault-name "kv-veritas-mgmt" --name "terraform-tenant-id" --value "ISI_TENANT_ID"
```

---


## 02. Infrastructure Structure (Terraform Foundation)

Langkah ini adalah transisi dari manual setup ke **Infrastructure as Code (IaC)**. Kita membangun struktur folder enterprise dan melakukan deployment pertama menggunakan sistem Backend State yang aman.

### A. Directory Structure (Standard Enterprise)

Di dalam folder `D:\infrastructure-as-code\`, buatlah hirarki berikut untuk memisahkan logika antar environment:

```text
📦infrastructure-as-code
 ┣ 📂environments          # Konfigurasi per Life-cycle
 ┃ ┗ 📂labx                # Nama Project
 ┃ ┃ ┗ 📂dev               # Stage: Development
 ┃ ┃ ┃ ┗ 📄main.tf         # Blueprint Utama (Entry Point)
 ┣ 📂modules               # Kumpulan komponen reusable (VNet, VM, DB)
 ┣ 📄.gitignore            # Pencegahan kebocoran data rahasia
 ┗ 📄README.md
```

### B. Security Configuration (`.gitignore`)

Wajib ada untuk mencegah file "ingatan" lokal ter-upload ke repositori publik.

```text
# Terraform internals
.terraform/
*.tfstate
*.tfstate.backup
*.tfvars
*.tfvars.json
```

---

### C. Terraform Blueprint (`main.tf`)

File ini diletakkan di `environments/labx/dev/main.tf`. Ini menghubungkan Terraform ke "Gudang State" di Azure yang kita buat di Section 00.

```hcl
# 1. Konfigurasi Terraform & Backend (State Locking)
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-infra-mgmt"      # RG yang dibuat manual di Section 00
    storage_account_name = "staccveritas"       # Nama storage unik Anda
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}

# 2. Provider Configuration
provider "azurerm" {
  features {}
}

# 3. Resource Definition (Infrastruktur Target)
resource "azurerm_resource_group" "rg_dev_app" {
  name     = "rg-labx-dev-app"
  location = "indonesiacentral"
  tags = {
    Environment = "Dev"
    ManagedBy   = "Terraform"
  }
}
```

---

### D. Operasional Lifecycle (CLI Commands)

Jalankan perintah ini secara berurutan di dalam folder `environments/labx/dev/`:

**1. Inisialisasi (Menghubungkan ke Cloud)**
Mendownload provider Azure dan mengunci state di Blob Storage.

```bash
terraform init
```

**2. Perencanaan (Dry Run)**
Melihat perubahan apa yang akan dilakukan tanpa benar-benar mengeksekusinya.

```bash
terraform plan
```

**3. Eksekusi (Provisioning)**
Membuat resource di Azure secara nyata. Ketik `yes` saat konfirmasi muncul.

```bash
terraform apply
```

---

### E. Root Cause Analysis (RCA): State Locking

Jika Anda menemui error `Acquiring state lock...` yang berhenti lama (freezing), lakukan investigasi berikut:

* **Penyebab:** Terraform menandai file state di Azure sebagai "sedang digunakan" (Leased) agar tidak terjadi konflik data. Jika proses terputus paksa, status "Leased" tidak terlepas.
* **Solusi (Manual Overide):** Buka Azure Portal > Storage Account > Container `tfstate` > Klik kanan pada file `.tfstate` > Pilih **Break Lease**.


### F. Warning  

Keberhasilan `apply` barusan masih menggunakan kredensial personal. Di level enterprise, ini dilarang karena tidak memiliki *traceability* yang baik pada identitas sistem.  

---

Kritik diterima secara mutlak. Sebagai calon CTO, dokumentasi teknis Anda tidak boleh hanya berisi narasi, tetapi harus mengandung **Technical Specs** yang bisa direplikasi oleh tim mana pun tanpa perlu bertanya lagi.

Berikut adalah dokumentasi lengkap untuk **Section 03** dengan standar Enterprise:

---

## 03. Identity Impersonation (Local Robot Test)

Langkah ini bertujuan untuk memvalidasi identitas robot (**Service Principal**) secara terisolasi. Kita harus memastikan robot memiliki hak akses yang cukup (**Principle of Least Privilege**) sebelum dilepaskan ke sistem otomasi (GitHub Actions).

### A. Konsep Autentikasi Terraform

Terraform Provider untuk Azure (`azurerm`) mendukung metode autentikasi menggunakan Service Principal. Metode ini lebih aman daripada akun personal karena:

1. **Non-Interactive:** Tidak memerlukan intervensi manusia/browser untuk login.
2. **Explicit Scope:** Akses dibatasi hanya pada subscription yang ditentukan.
3. **Traceability:** Semua perubahan di Azure Audit Logs tercatat atas nama `sp-terraform`.

### B. Variabel Lingkungan (Environment Variables)

Terraform mencari variabel tertentu di dalam *system environment* untuk melakukan login otomatis.

| Variabel | Mapping Azure | Nilai (Value) |
| --- | --- | --- |
| `ARM_CLIENT_ID` | Application (Client) ID | `df2ca4ee-da86-4217-b4fa-29d4684afe9a` |
| `ARM_CLIENT_SECRET` | Client Secret (Password) | `(Diambil dari Azure Key Vault)` |
| `ARM_TENANT_ID` | Directory (Tenant) ID | `99e46526-910f-45df-922d-8330247cd52e` |
| `ARM_SUBSCRIPTION_ID` | Subscription ID | `d9a45233-3f08-438e-8fb0-c0938115776f` |

### C. Prosedur Pengujian (Step-by-Step)

**1. Konfigurasi Variabel di PowerShell**
Jalankan perintah ini di jendela terminal yang akan digunakan (Variabel bersifat temporer/hanya ada di session tersebut).

```powershell
# Set Identitas Robot
$env:ARM_CLIENT_ID = "df2ca4ee-da86-4217-b4fa-29d4684afe9a"
$env:ARM_CLIENT_SECRET = "ISI_SECRET_DARI_KEYVAULT"
$env:ARM_TENANT_ID = "99e46526-910f-45df-922d-8330247cd52e"
$env:ARM_SUBSCRIPTION_ID = "d9a45233-3f08-438e-8fb0-c0938115776f"

```

**2. Simulasi Logout (Zero Trust Verification)**
Putuskan koneksi akun personal Anda untuk memastikan Terraform tidak menggunakan token login Anda.

```bash
az logout

```

**3. Eksekusi Verifikasi Terraform**
Masuk ke direktori project dan jalankan perbandingan state.

```bash
cd D:\infrastructure-as-code\environments\labx\dev
terraform plan

```

### D. Hasil yang Diharapkan (Expected Outcome)

Jika konfigurasi benar, Terraform akan menampilkan:

* `Acquiring state lock...` (Berhasil login ke Storage Account via SP).
* `Refreshing state...` (Berhasil membaca resource di Azure via SP).
* `No changes. Your infrastructure matches the configuration.`

---

### E. Root Cause Analysis (RCA) - Common Failures

| Pesan Error | Akar Masalah | Solusi |
| --- | --- | --- |
| `AuthenticationRequired` | Variabel `ARM_` tidak terbaca oleh terminal. | Cek variabel dengan `Get-ChildItem Env:ARM_*`. |
| `AuthorizationFailed` | Service Principal tidak punya role `Contributor`. | Jalankan `az role assignment create` untuk SP tersebut. |
| `ResourceNotFound` | Subscription ID salah atau tidak terjangkau oleh SP. | Verifikasi `ARM_SUBSCRIPTION_ID`. |

---
