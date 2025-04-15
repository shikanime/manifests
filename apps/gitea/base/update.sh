#!/usr/bin/env nix
#! nix shell nixpkgs#nushell nixpkgs#skopeo nixpkgs#kustomize --command nu

def --wrapped kustomize [...rest] {
    cd $env.FILE_PWD
    exec kustomize ...$rest
}

{ gitea: docker.io/gitea/gitea } | items { |name, image|
    let latest_version = (
        ^skopeo list-tags $"docker://($image)"
        | from json
        | get Tags
        | where ($it  =~ ^[0-9]+\.[0-9]+\.[0-9]+$)
        | sort-by { |tag| $tag | split row "." | each { |n| ($n | into int) } }
        | last
    )

    if ($latest_version | is-empty) {
        print $"Image '$image' not found in registry."
        return
    }

    kustomize edit set image $"($name)=($image):($latest_version)"

    open $"($env.FILE_PWD)/kustomization.yaml"
    | update labels { |label|
        $label | update pairs { |it|
            $it | upsert "app.kubernetes.io/version" $latest_version
        }
    }
    | save -f kustomization.yaml
}
