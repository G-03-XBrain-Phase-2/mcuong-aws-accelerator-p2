terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~>6.0"
    }
  }
}

#variables
variable "github_token" {
  type        = string
  sensitive   = true
  description = "Lưu Github access token"
}

provider "github" {
  token = var.github_token
}

resource "github_repository" "cuong_repo" {
  name        = "cuong_repo"
  description = "Creat test Repo"
  visibility  = "public"
  auto_init   = true
}
