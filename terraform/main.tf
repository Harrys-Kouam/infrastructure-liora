terraform {
  required_version = ">= 1.6.0"

  # State lives in HCP Terraform (workspace in Local execution mode).
  cloud {
    organization = "Harrys-liora"

    workspaces {
      name = "proxmox-kubernetes"
    }
  }

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.122.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  insecure = var.proxmox_insecure
}

# One VM per entry in var.nodes (1 master, 2 workers, 1 runner, 1 monitoring).
resource "proxmox_virtual_environment_vm" "node" {
  for_each = var.nodes

  name      = each.key
  node_name = var.proxmox_node
  vm_id     = each.value.vm_id

  clone {
    vm_id     = var.template_vm_id
    node_name = var.proxmox_node
  }

  agent {
    enabled = true
  }

  cpu {
    cores = var.cpu_cores
    type  = "x86-64-v3"
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = var.disk_size_gb
  }

  network_device {
    bridge = var.network_bridge
  }

  initialization {
    datastore_id = var.datastore_id

    ip_config {
      ipv4 {
        address = "${each.value.ip_address}/${var.network_prefix}"
        gateway = var.network_gateway
      }
    }

    user_account {
      username = var.vm_username
      keys     = [trimspace(var.ssh_public_key)]
    }
  }
}
