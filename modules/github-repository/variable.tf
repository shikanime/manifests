variable "name" {
  type        = string
  description = "Repository name"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]+$", var.name))
    error_message = "Repository name must contain only alphanumeric characters, hyphens, underscores, and dots."
  }
}

variable "description" {
  type        = string
  description = "Repository description"
  default     = ""
}

variable "homepage_url" {
  type        = string
  description = "Repository homepage URL"
  default     = ""
}

variable "visibility" {
  type        = string
  description = "Repository visibility: public, private, or internal"
  default     = "private"

  validation {
    condition     = contains(["public", "private", "internal"], var.visibility)
    error_message = "Visibility must be one of: public, private, internal."
  }
}

variable "topics" {
  type        = list(string)
  description = "Repository topics (tags)"
  default     = []
}

variable "has_issues" {
  type        = bool
  description = "Enable GitHub Issues"
  default     = true
}

variable "has_discussions" {
  type        = bool
  description = "Enable GitHub Discussions"
  default     = false
}

variable "has_projects" {
  type        = bool
  description = "Enable GitHub Projects"
  default     = false
}

variable "has_wiki" {
  type        = bool
  description = "Enable Wiki"
  default     = false
}

variable "is_template" {
  type        = bool
  description = "Mark as template repository"
  default     = false
}

variable "allow_merge_commit" {
  type        = bool
  description = "Allow merge commits"
  default     = false
}

variable "allow_squash_merge" {
  type        = bool
  description = "Allow squash merges"
  default     = true
}

variable "allow_rebase_merge" {
  type        = bool
  description = "Allow rebase merges"
  default     = false
}

variable "allow_auto_merge" {
  type        = bool
  description = "Allow auto-merge of PRs"
  default     = false
}

variable "allow_update_branch" {
  type        = bool
  description = "Suggest updating PR branches"
  default     = true
}

variable "delete_branch_on_merge" {
  type        = bool
  description = "Auto-delete head branch after merge"
  default     = true
}

variable "web_commit_signoff_required" {
  type        = bool
  description = "Require sign-off on web commits"
  default     = true
}

variable "squash_merge_commit_title" {
  type        = string
  description = "Squash merge commit title: PR_TITLE or COMMIT_OR_PR_TITLE"
  default     = "PR_TITLE"

  validation {
    condition     = contains(["PR_TITLE", "COMMIT_OR_PR_TITLE"], var.squash_merge_commit_title)
    error_message = "squash_merge_commit_title must be PR_TITLE or COMMIT_OR_PR_TITLE."
  }
}

variable "squash_merge_commit_message" {
  type        = string
  description = "Squash merge commit message: PR_BODY, COMMIT_MESSAGES, or BLANK"
  default     = "PR_BODY"

  validation {
    condition     = contains(["PR_BODY", "COMMIT_MESSAGES", "BLANK"], var.squash_merge_commit_message)
    error_message = "squash_merge_commit_message must be PR_BODY, COMMIT_MESSAGES, or BLANK."
  }
}

variable "auto_init" {
  type        = bool
  description = "Create initial commit with empty README"
  default     = true
}

variable "gitignore_template" {
  type        = string
  description = "Gitignore template name (e.g., Go, Node, Python)"
  default     = ""
}

variable "license_template" {
  type        = string
  description = "License template (e.g., mit, agpl-3.0, mpl-2.0)"
  default     = ""
}

variable "archive_on_destroy" {
  type        = bool
  description = "Archive repository on destroy instead of deleting"
  default     = true
}

variable "prevent_destroy" {
  type        = bool
  description = "Prevent accidental destruction of the repository and all associated resources (branch protection, rulesets). Destroy operations will fail with an error."
  default     = true
}

variable "vulnerability_alerts" {
  type        = bool
  description = "Enable Dependabot vulnerability alerts"
  default     = true
}

variable "enable_advanced_security" {
  type        = bool
  description = "Enable GitHub Advanced Security (code scanning, secret scanning). Always on for public repos."
  default     = true
}

variable "enable_secret_scanning_push_protection" {
  type        = bool
  description = "Enable secret scanning push protection"
  default     = true
}

variable "default_branch" {
  type        = string
  description = "Default branch name"
  default     = "main"
}

variable "protect_default_branch" {
  type        = bool
  description = "Enable branch protection on the default branch"
  default     = true
}

variable "required_approving_review_count" {
  type        = number
  description = "Number of approving reviews required (0-6)"
  default     = 1

  validation {
    condition     = var.required_approving_review_count >= 0 && var.required_approving_review_count <= 6
    error_message = "required_approving_review_count must be between 0 and 6."
  }
}

variable "dismiss_stale_reviews" {
  type        = bool
  description = "Dismiss stale reviews on new commits"
  default     = true
}

variable "require_code_owner_reviews" {
  type        = bool
  description = "Require code owner review"
  default     = false
}

variable "require_last_push_approval" {
  type        = bool
  description = "Require last push approval by someone other than the pusher"
  default     = true
}

variable "enforce_admins" {
  type        = bool
  description = "Enforce branch protection rules for admins"
  default     = true
}

variable "require_signed_commits" {
  type        = bool
  description = "Require GPG-signed commits on protected branches"
  default     = true
}

variable "require_linear_history" {
  type        = bool
  description = "Enforce linear commit history (no merge commits)"
  default     = true
}

variable "require_conversation_resolution" {
  type        = bool
  description = "Require all PR conversations resolved before merge"
  default     = true
}

variable "allows_force_pushes" {
  type        = bool
  description = "Allow force pushes"
  default     = false
}

variable "allows_deletions" {
  type        = bool
  description = "Allow branch deletion"
  default     = false
}

variable "lock_branch" {
  type        = bool
  description = "Make branch read-only"
  default     = false
}

variable "force_push_bypassers" {
  type        = list(string)
  description = "Actor IDs allowed to bypass force push restrictions (user or team node IDs)"
  default     = []
}

variable "push_allowances" {
  type        = list(string)
  description = "Actor IDs allowed to push to protected branch (user or team node IDs)"
  default     = []
}

variable "required_status_check_contexts" {
  type        = list(string)
  description = "List of required status check contexts"
  default     = []
}

variable "required_status_checks_strict" {
  type        = bool
  description = "Require branches to be up-to-date before merge"
  default     = true
}

variable "required_deployment_environments" {
  type        = list(string)
  description = "List of required deployment environments"
  default     = []
}

variable "dismissal_restrictions" {
  type        = list(string)
  description = "Actor IDs with review dismissal access"
  default     = []
}

variable "restrict_dismissals" {
  type        = bool
  description = "Restrict who can dismiss reviews"
  default     = true
}

variable "additional_branch_protections" {
  type = list(object({
    pattern                       = string
    enforce_admins                = optional(bool, true)
    require_signed_commits        = optional(bool, true)
    required_linear_history       = optional(bool, true)
    require_conversation_resolution = optional(bool, true)
    allows_force_pushes           = optional(bool, false)
    allows_deletions              = optional(bool, false)
    lock_branch                   = optional(bool, false)
    required_approving_review_count = optional(number, 1)
    dismiss_stale_reviews         = optional(bool, true)
    require_code_owner_reviews    = optional(bool, false)
    require_last_push_approval    = optional(bool, true)
    restrict_dismissals           = optional(bool, true)
    force_push_bypassers          = optional(list(string), [])
    push_allowances               = optional(list(string), [])
    required_status_check_contexts = optional(list(string), [])
    required_status_checks_strict = optional(bool, true)
    dismissal_restrictions        = optional(list(string), [])
    required_deployment_environments = optional(list(string), [])
  }))
  description = "Additional branch protection rules for non-default branches"
  default     = []
}

variable "pages" {
  type = object({
    build_type = optional(string, "workflow")
    cname      = optional(string, "")
    source = optional(object({
      branch = string
      path   = optional(string, "/")
    }), null)
  })
  description = "GitHub Pages configuration"
  default     = null
}

variable "template" {
  type = object({
    owner                = string
    repository           = string
    include_all_branches = optional(bool, false)
  })
  description = "Template repository to use for initialization"
  default     = null
}

# ── Enhanced Repository Rulesets ──────────────────────────────────

variable "enable_enhanced_rulesets" {
  type        = bool
  description = "Enable repository rulesets in addition to branch protection (for file path restrictions, required code scanning, etc.)"
  default     = false
}

variable "ruleset_bypass_actors" {
  type = list(object({
    actor_id    = string
    actor_type  = string
    bypass_mode = string
  }))
  description = "Actors that can bypass repository rulesets. actor_type: Integration, Team, RepositoryRole, OrganizationAdmin. bypass_mode: always, pull_request."
  default     = []
}

variable "required_code_scanning_tools" {
  type = list(object({
    alerts_threshold          = string
    security_alerts_threshold = string
    tool                      = string
  }))
  description = "Required code scanning tools (e.g., CodeQL with alert thresholds)"
  default     = []
}

variable "file_path_restrictions" {
  type        = list(string)
  description = "Restricted file paths in push ruleset"
  default     = []
}

variable "restricted_file_extensions" {
  type        = list(string)
  description = "Blocked file extensions in push ruleset"
  default     = [".exe", ".dll", ".so", ".dylib"]
}

variable "max_file_size_mb" {
  type        = number
  description = "Maximum file size in MB (push ruleset, 1-100)"
  default     = 100

  validation {
    condition     = var.max_file_size_mb >= 1 && var.max_file_size_mb <= 100
    error_message = "max_file_size_mb must be between 1 and 100."
  }
}
