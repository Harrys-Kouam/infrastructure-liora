output "node_ips" {
  description = "IP address of each VM, to fill ansible/inventory.ini"
  value       = { for name, node in var.nodes : name => node.ip_address }
}
