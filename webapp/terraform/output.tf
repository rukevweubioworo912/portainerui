output "master_public_ip" {
  description = "Public IP of the master node"
  value       = azurerm_public_ip.master_pip.ip_address
}

output "worker_public_ips" {
  description = "Public IPs of the worker nodes"
  value       = [for ip in azurerm_public_ip.worker_pip : ip.ip_address]
}

output "admin_username" {
  description = "Admin username for VMs"
  value       = var.admin_username
}