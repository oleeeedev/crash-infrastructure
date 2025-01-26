terraform {
  backend "http" {}

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.50.0"
    }
    gitlab = {
      source = "gitlabhq/gitlab"
      version = "17.8.0"
    }
    github = {
      source  = "integrations/github"
      version = "6.5.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "gitlab" {
  token = var.gitlab_api_token
  base_url = "https://gitlab.com/api/v4/"
}

provider "github" {
  owner = "crashlang-tech"
  app_auth {
    id = ""
    installation_id = ""
    pem_file = var.github_app_key
  }
}

module "domain" {
  source = "../../system/domain"
  cloudflare_account_id = var.cloudflare_account_id
  cloudflare_api_token = var.cloudflare_api_token
}

module "github" {
  source = "../../system/github"
}