variable "proxmox_endpoint" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://151.115.97.89:8006/"
}

variable "proxmox_insecure" {
  description = "Accept a self-signed Proxmox certificate"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Proxmox node that holds the template and runs every VM"
  type        = string
  default     = "sep25-continu-devops-fastapi"
}

variable "template_vm_id" {
  description = "VM ID of the Ubuntu cloud-init template to clone"
  type        = number
  default     = 9000
}

variable "datastore_id" {
  description = "Proxmox storage for VM disks and cloud-init"
  type        = string
  default     = "local"
}

variable "network_bridge" {
  description = "Proxmox bridge used by the VMs"
  type        = string
  default     = "vmbr1"
}

variable "network_prefix" {
  description = "Subnet prefix length"
  type        = number
  default     = 24
}

variable "network_gateway" {
  description = "Default gateway of the VMs"
  type        = string
  default     = "192.168.100.1"
}

variable "vm_username" {
  description = "User created by cloud-init; Ansible connects with it"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "SSH public key injected by cloud-init (the private key is the SSH_PRIVATE_KEY secret)"
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOnxfDHaZBQ75AyjtCxJA29JOGMMjYeInXCk1syJGbCH task-manager-ansible"
}

variable "cpu_cores" {
  description = "vCPU cores per VM"
  type        = number
  default     = 2
}

variable "disk_size_gb" {
  description = "Disk size per VM in GiB (not smaller than the template disk)"
  type        = number
  default     = 20
}

variable "nodes" {
  description = "The VMs to create, keyed by VM name: 1 master, 2 workers, 1 runner, 1 monitoring"
  type = map(object({
    vm_id      = number
    ip_address = string
    memory     = number
  }))
  default = {
    master-1     = { vm_id = 500, ip_address = "192.168.100.13", memory = 3072 }
    worker-1     = { vm_id = 501, ip_address = "192.168.100.20", memory = 4096 }
    worker-2     = { vm_id = 502, ip_address = "192.168.100.21", memory = 4096 }
    runner-1     = { vm_id = 503, ip_address = "192.168.100.30", memory = 2048 }
    monitoring-1 = { vm_id = 504, ip_address = "192.168.100.40", memory = 4096 }
  }

  validation {
    condition = (
      length([for name in keys(var.nodes) : name if startswith(name, "master")]) == 1 &&
      length([for name in keys(var.nodes) : name if startswith(name, "worker")]) == 2 &&
      length([for name in keys(var.nodes) : name if startswith(name, "runner")]) == 1 &&
      length([for name in keys(var.nodes) : name if startswith(name, "monitoring")]) == 1 &&
      length(var.nodes) == 5
    )
    error_message = "Define exactly 5 nodes: 1 master*, 2 worker*, 1 runner* and 1 monitoring*."
  }
}
