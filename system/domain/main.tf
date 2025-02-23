terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.50.0"
    }
    gitlab = {
      source = "gitlabhq/gitlab"
      version = "17.8.0"
    }
  }
}

data "cloudflare_zone" "main_domain" {
  account_id = var.cloudflare_account_id
  name       = "crash.tech"
}

resource "cloudflare_zone_settings_override" "main" {
  zone_id = data.cloudflare_zone.main_domain.id

  settings {
    ssl = "strict"
  }
}

module "docs_pages" {
  source = "../../modules/gitlab/pages_domain"

  cloudflare_domain_name = "docs"
  cloudflare_zone_id = data.cloudflare_zone.main_domain.id
  gitlab_project_path = "crashlang-tech/development/telescopium"
  gitlab_unique_pages_url = "docs-crashlang-tech-c91f18c0d2259c041bf05138b194e6bb082059fe38eff2e.gitlab.io"
}

module "landing_page_pages" {
  source = "../../modules/gitlab/pages_domain"

  cloudflare_domain_name = "@"
  cloudflare_zone_id = data.cloudflare_zone.main_domain.id
  gitlab_project_path = "crashlang-tech/development/landing-page"
  gitlab_unique_pages_url = "landing-page-crashlang-tech-development-b2dc2848e053fa1893b1dfbb1ba.gitlab.io"
}

resource "cloudflare_record" "github_verification" {
  name    = "_github-challenge-crashlang-tech-org"
  type    = "TXT"
  zone_id = data.cloudflare_zone.main_domain.id
  content = "e3447326f4"
  comment = "Managed by Terraform"
}

resource "cloudflare_record" "strato_spf" {
  name    = "@"
  type    = "TXT"
  zone_id = data.cloudflare_zone.main_domain.id
  content = "v=spf1 redirect=smtp.strato.de"
  comment = "Managed by Terraform"
}

resource "cloudflare_record" "strato_dkim" {
  name    = "strato-dkim-0002._domainkey"
  type    = "CNAME"
  zone_id = data.cloudflare_zone.main_domain.id
  content = "strato-dkim-0002._domainkey.strato.de"
  comment = "Managed by Terraform"
}

resource "cloudflare_ruleset" "force_https" {
  kind  = "zone"
  name  = "force_https"
  phase = "http_request_dynamic_redirect"
  zone_id = data.cloudflare_zone.main_domain.id

  rules {
    ref = "redirect_http"
    expression = "(http.request.full_uri wildcard r\"http://*\")"
    action = "redirect"
    action_parameters {
      from_value {
        status_code = 302
        target_url {
          expression = "wildcard_replace(http.request.full_uri, \"http://*\", \"https://${"$"}{1}\")"
        }
        preserve_query_string = true
      }
    }
  }
}