resource "github_repository" "this" {
  name        = var.name
  description = var.description
  visibility  = var.visibility

  homepage_url                = var.homepage_url
  topics                      = var.topics
  has_issues                  = var.has_issues
  has_discussions             = var.has_discussions
  has_projects                = var.has_projects
  has_wiki                    = var.has_wiki
  is_template                 = var.is_template
  allow_merge_commit          = var.allow_merge_commit
  allow_squash_merge          = var.allow_squash_merge
  allow_rebase_merge          = var.allow_rebase_merge
  allow_auto_merge            = var.allow_auto_merge
  allow_update_branch         = var.allow_update_branch
  delete_branch_on_merge      = var.delete_branch_on_merge
  web_commit_signoff_required = var.web_commit_signoff_required
  auto_init                   = var.auto_init
  gitignore_template          = var.gitignore_template != "" ? var.gitignore_template : null
  license_template            = var.license_template != "" ? var.license_template : null
  archive_on_destroy          = var.archive_on_destroy
  vulnerability_alerts        = var.vulnerability_alerts

  squash_merge_commit_title   = var.squash_merge_commit_title
  squash_merge_commit_message = var.squash_merge_commit_message

  dynamic "pages" {
    for_each = var.pages != null ? [var.pages] : []
    content {
      build_type = pages.value.build_type
      cname      = pages.value.cname

      dynamic "source" {
        for_each = pages.value.source != null ? [pages.value.source] : []
        content {
          branch = source.value.branch
          path   = source.value.path
        }
      }
    }
  }

  dynamic "template" {
    for_each = var.template != null ? [var.template] : []
    content {
      owner                = template.value.owner
      repository           = template.value.repository
      include_all_branches = template.value.include_all_branches
    }
  }

  security_and_analysis {
    advanced_security {
      status = var.enable_advanced_security ? "enabled" : "disabled"
    }

    secret_scanning {
      status = var.enable_advanced_security ? "enabled" : "disabled"
    }

    secret_scanning_push_protection {
      status = var.enable_secret_scanning_push_protection ? "enabled" : "disabled"
    }
  }

  lifecycle {
    ignore_changes = [
      security_and_analysis, # GHAS settings drift when org-level defaults change
    ]
    prevent_destroy = var.prevent_destroy
  }
}

resource "github_branch_default" "this" {
  repository = github_repository.this.name
  branch     = var.default_branch
}

resource "github_branch_protection" "default" {
  count = var.protect_default_branch ? 1 : 0

  repository_id = github_repository.this.node_id
  pattern       = var.default_branch

  enforce_admins                  = var.enforce_admins
  require_signed_commits          = var.require_signed_commits
  required_linear_history         = var.require_linear_history
  require_conversation_resolution = var.require_conversation_resolution
  allows_deletions                = var.allows_deletions
  allows_force_pushes             = var.allows_force_pushes
  lock_branch                     = var.lock_branch

  required_pull_request_reviews {
    dismiss_stale_reviews           = var.dismiss_stale_reviews
    restrict_dismissals             = var.restrict_dismissals
    dismissal_restrictions          = var.dismissal_restrictions
    require_code_owner_reviews      = var.require_code_owner_reviews
    required_approving_review_count = var.required_approving_review_count
    require_last_push_approval      = var.require_last_push_approval
  }

  restrict_pushes {
    push_allowances = var.push_allowances
  }

  force_push_bypassers = var.force_push_bypassers

  dynamic "required_status_checks" {
    for_each = length(var.required_status_check_contexts) > 0 ? [1] : []
    content {
      strict   = var.required_status_checks_strict
      contexts = var.required_status_check_contexts
    }
  }

  dynamic "required_deployments" {
    for_each = length(var.required_deployment_environments) > 0 ? [1] : []
    content {
      required_deployment_environments = var.required_deployment_environments
    }
  }

  lifecycle {
    prevent_destroy = var.prevent_destroy
  }
}

resource "github_branch_protection" "additional" {
  for_each = { for bp in var.additional_branch_protections : bp.pattern => bp }

  repository_id = github_repository.this.node_id
  pattern       = each.value.pattern

  enforce_admins                  = each.value.enforce_admins
  require_signed_commits          = each.value.require_signed_commits
  required_linear_history         = each.value.required_linear_history
  require_conversation_resolution = each.value.require_conversation_resolution
  allows_deletions                = each.value.allows_deletions
  allows_force_pushes             = each.value.allows_force_pushes
  lock_branch                     = each.value.lock_branch

  required_pull_request_reviews {
    dismiss_stale_reviews           = each.value.dismiss_stale_reviews
    restrict_dismissals             = each.value.restrict_dismissals
    dismissal_restrictions          = each.value.dismissal_restrictions
    require_code_owner_reviews      = each.value.require_code_owner_reviews
    required_approving_review_count = each.value.required_approving_review_count
    require_last_push_approval      = each.value.require_last_push_approval
  }

  restrict_pushes {
    push_allowances = each.value.push_allowances
  }

  force_push_bypassers = each.value.force_push_bypassers

  dynamic "required_status_checks" {
    for_each = length(each.value.required_status_check_contexts) > 0 ? [1] : []
    content {
      strict   = each.value.required_status_checks_strict
      contexts = each.value.required_status_check_contexts
    }
  }

  dynamic "required_deployments" {
    for_each = length(each.value.required_deployment_environments) > 0 ? [1] : []
    content {
      required_deployment_environments = each.value.required_deployment_environments
    }
  }

  lifecycle {
    prevent_destroy = var.prevent_destroy
  }
}
