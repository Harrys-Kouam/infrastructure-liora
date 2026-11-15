variable "proxmox_endpoint" {
  description = "Proxmox API URL, e.g. https://IP:8006/"
  type        = string
}

variable "proxmox_insecure" {
  description = "Accept a self-signed Proxmox certificate"
  type        = bool
  default     = false
}

variable "template_vm_id" {
  description = "VM ID of the Ubuntu cloud-init template to clone"
  type        = number
}

variable "template_node_name" {
  description = "Proxmox node that holds the template"
  type        = string
}

variable "datastore_id" {
  description = "Proxmox storage for VM disks and cloud-init"
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Proxmox bridge used by the VMs"
  type        = string
  default     = "vmbr0"
}

variable "network_prefix" {
  description = "Subnet prefix length, e.g. 24"
  type        = number
  default     = 24
}

variable "network_gateway" {
  description = "Default gateway of the VMs"
  type        = string
}

variable "vm_username" {
  description = "User created by cloud-init; Ansible connects with it"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "SSH public key injected by cloud-init"
  type        = string
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
  description = "The VMs to create, keyed by VM name: 3 'master' and 3 'worker'"
  type = map(object({
    proxmox_node = string
    vm_id        = number
    ip_address   = string
    memory       = number
  }))

  validation {
    condition = (
      length([for name in keys(var.nodes) : name if startswith(name, "master")]) == 3 &&
      length([for name in keys(var.nodes) : name if startswith(name, "worker")]) == 3 &&
      length(var.nodes) == 6
    )
    error_message = "Define exactly 3 nodes named master* and 3 named worker*."
  }
}
