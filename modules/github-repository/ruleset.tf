locals {
  rule_bypass_actors = [
    for actor in var.ruleset_bypass_actors : {
      actor_id    = actor.actor_id
      actor_type  = actor.actor_type
      bypass_mode = actor.bypass_mode
    }
  ]

  allowed_merge_methods = compact([
    var.allow_merge_commit ? "merge" : "",
    var.allow_squash_merge ? "squash" : "",
    var.allow_rebase_merge ? "rebase" : "",
  ])
}

resource "github_repository_ruleset" "default_branch" {
  count = var.enable_enhanced_rulesets ? 1 : 0

  name        = "${var.name}-branch-rules"
  repository  = github_repository.this.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~ALL"]
      exclude = []
    }
  }

  dynamic "bypass_actors" {
    for_each = local.rule_bypass_actors
    content {
      actor_id    = bypass_actors.value.actor_id
      actor_type  = bypass_actors.value.actor_type
      bypass_mode = bypass_actors.value.bypass_mode
    }
  }

  rules {
    creation                = true
    update                  = true
    deletion                = true
    required_linear_history = var.require_linear_history
    required_signatures     = var.require_signed_commits
    non_fast_forward        = !var.allows_force_pushes

    pull_request {
      allowed_merge_methods           = local.allowed_merge_methods
      dismiss_stale_reviews_on_push   = var.dismiss_stale_reviews
      require_code_owner_review       = var.require_code_owner_reviews
      require_last_push_approval      = var.require_last_push_approval
      required_approving_review_count = var.required_approving_review_count
    }

    dynamic "required_deployments" {
      for_each = length(var.required_deployment_environments) > 0 ? [1] : []
      content {
        required_deployment_environments = var.required_deployment_environments
      }
    }

    dynamic "required_status_checks" {
      for_each = length(var.required_status_check_contexts) > 0 ? [1] : []
      content {
        strict_required_check_suite_configurations = []
        strict_required_status_checks_policy       = var.required_status_checks_strict
        required_status_checks = [
          for ctx in var.required_status_check_contexts : {
            context        = ctx
            integration_id = 0
          }
        ]
      }
    }

    dynamic "required_code_scanning" {
      for_each = length(var.required_code_scanning_tools) > 0 ? [1] : []
      content {
        dynamic "required_code_scanning_tool" {
          for_each = var.required_code_scanning_tools
          content {
            alerts_threshold          = required_code_scanning_tool.value.alerts_threshold
            security_alerts_threshold = required_code_scanning_tool.value.security_alerts_threshold
            tool                      = required_code_scanning_tool.value.tool
          }
        }
      }
    }
  }

  lifecycle {
    prevent_destroy = var.prevent_destroy
  }
}

resource "github_repository_ruleset" "push_restrictions" {
  count = var.enable_enhanced_rulesets && (length(var.file_path_restrictions) > 0 || length(var.restricted_file_extensions) > 0) ? 1 : 0

  name        = "${var.name}-push-rules"
  repository  = github_repository.this.name
  target      = "push"
  enforcement = "active"

  dynamic "bypass_actors" {
    for_each = local.rule_bypass_actors
    content {
      actor_id    = bypass_actors.value.actor_id
      actor_type  = bypass_actors.value.actor_type
      bypass_mode = bypass_actors.value.bypass_mode
    }
  }

  rules {
    dynamic "file_path_restriction" {
      for_each = length(var.file_path_restrictions) > 0 ? [1] : []
      content {
        restricted_file_paths = var.file_path_restrictions
      }
    }

    dynamic "file_extension_restriction" {
      for_each = length(var.restricted_file_extensions) > 0 ? [1] : []
      content {
        restricted_file_extensions = var.restricted_file_extensions
      }
    }

    max_file_size {
      max_file_size = var.max_file_size_mb
    }
  }

  lifecycle {
    prevent_destroy = var.prevent_destroy
  }
}
