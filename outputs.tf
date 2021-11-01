locals {
  url = "https://${var.domain}"
}

output "url" {
  description = "URL of the main website"
  value       = local.url
}

output "alternate_urls" {
  description = "Alternate URLs of the website"
  value       = formatlist("https://%s", var.domain_aliases)
}

