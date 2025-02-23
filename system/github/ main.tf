terraform {
  required_providers {
    github = {
      source = "integrations/github"
      version = "6.5.0"
    }
  }
}

data "github_repositories" "repositories" {
  query = "org:crashlang-tech"
}

module "global_labels" {
  source = "../../modules/github/global_labels"

  for_each = toset(data.github_repositories.repositories.names)
  repository = each.value
}