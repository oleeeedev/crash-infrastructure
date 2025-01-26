terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.50.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

data "cloudflare_zone" "main_domain" {
  account_id = var.cloudflare_account_id
  name       = "crash.tech"
}

module "proxy" {
  source = "../../modules/docker/proxy"

  certificate_hostnames = [
    "plane.crash.tech",
    "outline.crash.tech",
  ]
}

module "plane" {
  source = "../../modules/docker/plane"

  web_url                 = "plane.crash.tech"
  docker_proxy_network_id = module.proxy.docker_proxy_network_id
}

module "outline" {
  source = "../../modules/docker/outline"

  web_url                 = "outline.crash.tech"
  docker_proxy_network_id = module.proxy.docker_proxy_network_id
}

resource "cloudflare_record" "server_ip" {
  name    = "server_administration"
  type    = "A"
  zone_id = data.cloudflare_zone.main_domain.id
  content = var.server_administration_ip
  proxied = true

  comment = "Managed by Terraform"
}

resource "cloudflare_record" "server_cname" {
  for_each = toset([
    "plane",
    "outline",
  ])

  name    = each.value
  type    = "CNAME"
  zone_id = data.cloudflare_zone.main_domain.id
  content = cloudflare_record.server_ip.hostname
  proxied = true

  comment = "Managed by Terraform"
}