#!/usr/bin/env nix
#! nix shell nixpkgs#nushell nixpkgs#gitnr --command nu

# Update gitignore
^gitnr create ghc:Nix repo:shikanime/gitignore/refs/heads/main/Devenv.gitignore tt:jetbrains+all tt:linux tt:macos tt:terraform tt:vim tt:visualstudiocode tt:windows
  | save .gitignore --force

# Process apps and clusters
ls [apps clusters] | each { |dir|
  let base_dir = $"($dir.name)/base"
  if ($base_dir | path exists) and ($"($base_dir)/update.sh" | path exists) {
    nu $"($base_dir)/update.sh" | lines | each { |line| $"[($dir.name)] ($line)" } | str collect
  }
}

#   # Process overlays
#   ls $"($dir.name)/overlays" | each { |overlay|
#     let overlay_path = $"($overlay.name)/update.sh"
#     if ($overlay_path | path exists) {
#       nu $overlay_path | lines | each { |line| $"[($dir.name)/($overlay.name)] ($line)" } | str collect
#     }
#   }
# }

# # Process nix packages
# ls nix/packages/* | each { |dir|
#   let update_script = $"($dir.name)/update.sh"
#   if ($update_script | path exists) {
#     nu $update_script | lines | each { |line| $"[packages] ($line)" } | str collect
#   }
# }

# # Process infra
# ls infra/* | each { |dir|
#   let update_script = $"($dir.name)/update.sh"
#   if ($update_script | path exists) {
#     nu $update_script | lines | each { |line| $"[($dir.name)] ($line)" } | str collect
#   }
# }
