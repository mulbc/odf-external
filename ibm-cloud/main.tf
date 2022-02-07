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

resource "ibm_is_ssh_key" "terra_sshkey" {
  name       = "terraform"
  public_key = var.ssh_public_key
}

variable "instance_count" {
  default = 3
}

resource "ibm_is_instance" "terra_instance" {
  count = var.instance_count
  name  = "terraformtest${count.index}"
  # ibm-redhat-8-4-minimal-amd64-1
  image = "r010-a704b088-c2ee-4f92-b384-1a0ac30f2f19"
  # 4 CPUs, 16GB RAM, 150GB instance storage
  profile = "bx2d-4x16"

  primary_network_interface {
    # eu-de-default-vpc
    subnet = "02c7-8b9b249c-27d0-418c-b2bb-dd014465c76e"
  }

  # eu-de-default-vpc
  vpc  = "r010-dc43f1b5-68ac-4a40-aad5-10b4aed6de48"
  zone = "eu-de-2"
  keys = [ibm_is_ssh_key.terra_sshkey.id]
}

resource "ibm_is_floating_ip" "terra_fip" {
  count  = var.instance_count
  name   = "terratestfip${count.index}"
  target = ibm_is_instance.terra_instance[count.index].primary_network_interface[0].id
}

resource "null_resource" "ansible" {
  depends_on = [
    ibm_is_instance.terra_instance,
    ibm_is_floating_ip.terra_fip
  ]
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {

    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${join(",", ibm_is_floating_ip.terra_fip[*].address)},' install-rhcs.yml"
    environment = {
      RHN_USER = var.rhn_user
      RHN_PASS = var.rhn_password
    }
  }
}
