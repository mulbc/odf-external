terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.38.0"
    }
  }
}

provider "ibm" {
  region                = "eu-de"
  ibmcloud_api_key      = var.api_key
  iaas_classic_api_key  = var.api_key
  iaas_classic_username = var.api_user
}

resource "ibm_compute_ssh_key" "cblum" {
  label      = "cblum"
  public_key = var.ssh_public_key
}

resource "ibm_compute_bare_metal" "hourly-bm1" {
  # Get values with "ibmcloud sl hardware create-options"
  hostname             = "hourly-bm1"
  domain               = "odf.ninja"
  os_reference_code    = "REDHAT_8_64"
  datacenter           = "fra02"
  network_speed        = 100   # Optional
  hourly_billing       = true  # Optional
  private_network_only = false # Optional
  fixed_config_preset  = "1U_8260_384GB_4X960GB_SSD_RAID10_RAID_10"
  ssh_key_ids          = [ibm_compute_ssh_key.cblum.id]


  user_metadata = "{\"value\":\"newvalue\"}" # Optional
  tags = [
    "cblum",
    "testing",
  ]
  notes = "note test"
}
