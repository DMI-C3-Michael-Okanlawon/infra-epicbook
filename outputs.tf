output "app_public_ip" {
  description = "Frontend public IP for the EpicBook URL"
  value       = azurerm_public_ip.frontend.ip_address
}

output "backend_public_ip" {
  description = "Backend SSH address for the App Pipeline"
  value       = azurerm_public_ip.backend.ip_address
}

output "backend_private_ip" {
  description = "Nginx upstream address on the VNet"
  value       = azurerm_network_interface.backend.private_ip_address
}

output "mysql_fqdn" {
  description = "Private MySQL Flexible Server hostname"
  value       = azurerm_mysql_flexible_server.epicbook.fqdn
}

output "admin_user" {
  value = var.admin_user
}
