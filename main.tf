module "organization" {
  source = "github.com/gcp-foundation/modules//resources/organization?ref=0.0.2"
  domain = var.domain
}

module "folder" {
  source       = "github.com/gcp-foundation/modules//resources/folder?ref=0.0.2"
  parent       = module.organization.name
  display_name = "fldr-test"
}

module "project" {
  source = "github.com/gcp-foundation/modules//resources/project?ref=0.0.2"
  folder = module.folder.id
  name   = "prj-logging-keys"
  services = [
    "compute.googleapis.com",
    "oslogin.googleapis.com",
    "cloudkms.googleapis.com",
    "logging.googleapis.com"
  ]
  billing_account = var.billing_account
  labels          = var.labels
}

module "logging_kms_key_ring" {
  source   = "github.com/gcp-foundation/modules//kms/key_ring?ref=0.0.2"
  name     = "kms-logging"
  project  = module.project.project_id
  location = "global"
}

data "google_logging_organization_settings" "settings" {
  organization = module.organization.org_id
}

data "google_logging_folder_settings" "settings" {
  folder = module.folder.folder_id
}

data "google_logging_project_settings" "settings" {
  project = module.project.project_id
}

module "org_logging_kms_key" {
  source     = "github.com/gcp-foundation/modules//kms/key?ref=0.0.2"
  name       = "kms-org-logging"
  key_ring   = module.logging_kms_key_ring.id
  project    = module.project.project_id
  location   = var.location
  encrypters = ["serviceAccount:${data.google_logging_organization_settings.settings.kms_service_account_id}"]
  decrypters = ["serviceAccount:${data.google_logging_organization_settings.settings.kms_service_account_id}"]
}

module "folder_logging_kms_key" {
  source     = "github.com/gcp-foundation/modules//kms/key?ref=0.0.2"
  name       = "kms-folder-logging"
  key_ring   = module.logging_kms_key_ring.id
  project    = module.project.project_id
  location   = var.location
  encrypters = ["serviceAccount:${data.google_logging_folder_settings.settings.kms_service_account_id}"]
  decrypters = ["serviceAccount:${data.google_logging_folder_settings.settings.kms_service_account_id}"]
}

module "project_logging_kms_key" {
  source     = "github.com/gcp-foundation/modules//kms/key?ref=0.0.2"
  name       = "kms-project-logging"
  key_ring   = module.logging_kms_key_ring.id
  project    = module.project.project_id
  location   = var.location
  encrypters = ["serviceAccount:${data.google_logging_project_settings.settings.kms_service_account_id}"]
  decrypters = ["serviceAccount:${data.google_logging_project_settings.settings.kms_service_account_id}"]
}

/*
resource "google_logging_organization_settings" "settings" {
  disable_default_sink = false
  kms_key_name         = module.org_logging_kms_key.key_id
  organization         = module.organization.org_id
  storage_location     = "global"
  depends_on           = [module.org_logging_kms_key.encrpters, module.org_logging_kms_key.decrypters]
}

resource "google_logging_folder_settings" "settings" {
  disable_default_sink = false
  kms_key_name         = module.folder_logging_kms_key.key_id
  folder               = module.folder.folder_id
  storage_location     = "global"
  depends_on           = [module.folder_logging_kms_key.encrpters, module.folder_logging_kms_key.decrypters]
}
*/
