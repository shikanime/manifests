terraform {
  required_version = "~> 1.8"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.6"
    }
  }
}

module "github_repository" {
  source = "../../modules/github-repository"

  name        = "shikanime"
  description = "Shikanime Studio — infrastructure and tooling"
  visibility  = "public"

  topics = [
    "nixos",
    "kubernetes",
    "gitops",
    "infrastructure",
  ]

  has_issues      = true
  has_discussions = false
  has_projects    = true
  has_wiki        = false

  allow_merge_commit = false
  allow_squash_merge = true
  allow_rebase_merge = false

  delete_branch_on_merge      = true
  web_commit_signoff_required = true

  vulnerability_alerts                   = true
  enable_advanced_security               = true
  enable_secret_scanning_push_protection = true

  default_branch        = "main"
  protect_default_branch = true

  required_approving_review_count = 1
  dismiss_stale_reviews           = true
  require_code_owner_reviews      = false
  require_last_push_approval      = true

  enforce_admins                  = true
  require_signed_commits          = true
  require_linear_history         = true
  require_conversation_resolution = true

  allows_force_pushes = false
  allows_deletions    = false
  lock_branch         = false

  archive_on_destroy = true
  prevent_destroy    = true

  enable_enhanced_rulesets = true

  restricted_file_extensions = [".exe", ".dll", ".so", ".dylib"]
  max_file_size_mb           = 100
}
