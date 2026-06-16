output "repository_id" {
  value       = github_repository.this.id
  description = "GitHub repository ID"
}

output "repository_node_id" {
  value       = github_repository.this.node_id
  description = "GitHub repository GraphQL node ID"
}

output "repository_name" {
  value       = github_repository.this.name
  description = "Repository name"
}

output "repository_full_name" {
  value       = github_repository.this.full_name
  description = "Repository full name (org/name)"
}

output "repository_html_url" {
  value       = github_repository.this.html_url
  description = "Repository HTML URL"
}

output "repository_ssh_clone_url" {
  value       = github_repository.this.ssh_clone_url
  description = "Repository SSH clone URL"
}

output "repository_http_clone_url" {
  value       = github_repository.this.http_clone_url
  description = "Repository HTTP clone URL"
}

output "repository_default_branch" {
  value       = github_branch_default.this.branch
  description = "Default branch name"
}

output "repository_private" {
  value       = github_repository.this.private
  description = "Whether the repository is private"
}

output "repository_visibility" {
  value       = github_repository.this.visibility
  description = "Repository visibility"
}

output "default_branch_protection_id" {
  value       = var.protect_default_branch ? github_branch_protection.default[0].id : null
  description = "Default branch protection rule ID"
}

output "additional_branch_protection_ids" {
  value       = { for k, v in github_branch_protection.additional : k => v.id }
  description = "Map of additional branch protection rule IDs by pattern"
}

output "ruleset_ids" {
  value = var.enable_enhanced_rulesets ? {
    branch = github_repository_ruleset.default_branch[0].id
    push   = length(github_repository_ruleset.push_restrictions) > 0 ? github_repository_ruleset.push_restrictions[0].id : null
  } : null
  description = "Repository ruleset IDs (null if enhanced rulesets disabled)"
}
