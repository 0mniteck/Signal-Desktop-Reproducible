# 0mniteck.rego - v0.1.2-Alpha - Multi-Repo Policy File
# Strict requirement for docker public registries: https, and @digest_tag or --checksum
#
#  Demos:
# docker buildx build --policy reset=true,strict=true,filename=$REPO.rego .
# docker buildx build --progress=plain --policy log-level=debug,reset=true,strict=true,filename=$REPO.rego .
# docker buildx policy eval --print --fields image.checksum docker-image://$source_img
# docker buildx policy eval --print $source
# Builtins: print load_json verify_git_signature pin_image
# [input.image.checksum input.image.labels input.image.user input.image.volumes input.image.workingDir \
# input.image.env input.image.hasProvenance input.image.signatures input.image.fullRepo]
#

package docker

default allow := false

allow if input.local

allow if {
  input.image.host == "docker.io"  # Docker Hub
  input.image.checksum == digest
}

allow if {
  input.image.host == "dhi.io"  # Docker Hardened Images
  input.image.hasProvenance     # Include attestation check
}

allow if {
  input.image.isCanonical  # registry.url/org/repo@sha256:digest
}

allow if {
  input.http.schema == "https"  # Require HTTPS for all downloads
}

decision := {"allow": allow}

#WIP from DEMO

allowed_repos := ["myorg/backend", "myorg/frontend", "myorg/worker"]

allow if {
  some repo in allowed_repos
  input.image.repo == repo
  input.image.hasProvenance
  some sig in input.image.signatures
  trusted_github_builder(sig, repo)
}

# Helper to validate GitHub Actions build from main branch
trusted_github_builder(sig, repo) if {
  sig.signer.certificateIssuer == "CN=sigstore-intermediate,O=sigstore.dev"
  sig.signer.issuer == "https://token.actions.githubusercontent.com"
  startswith(sig.signer.buildSignerURI, sprintf("https://github.com/myorg/%s/.github/workflows/", [repo]))
  sig.signer.sourceRepositoryRef == "refs/heads/main"
  sig.signer.runnerEnvironment == "github-hosted"
}

#DEMO2

is_buildkit if {
    input.git.remote == "https://github.com/moby/buildkit.git"
}

is_version_tag if {
    is_buildkit
    regex.match(`^v[0-9]+\.[0-9]+\.[0-9]+$`, input.git.tagName)
}

# Version tags must be signed
allow if {
    is_version_tag
    input.git.tagName != ""
    verify_git_signature(input.git.tag, "maintainers.asc")
}

# Allow unsigned refs for development
allow if {
    is_buildkit
    not is_version_tag
}

#DEMO3

# TODO: Add your pinned images with exact digests
# Docker Hub images use docker.io as host
allowed_dockerhub := {
  "alpine": "sha256:4b7ce07002c69e8f3d704a9c5d6fd3053be500b7f1c69fc0d80990c2ad8dd412",
  "golang": "sha256:abc123...",
}

allow if {
  input.image.host == "docker.io"
  some repo, digest in allowed_dockerhub
  input.image.repo == repo
  input.image.checksum == digest
}

# TODO: Add your pinned DHI images
allowed_dhi := {
  "python": "sha256:def456...",
  "node": "sha256:ghi789...",
}

allow if {
  input.image.host == "dhi.io"
  some repo, digest in allowed_dhi
  input.image.repo == repo
  input.image.checksum == digest
}

# TODO: Add your pinned Git dependencies
allowed_git := {
  "https://github.com/moby/buildkit.git": {
    "tag": "v0.26.1",
    "commit": "abc123...",
  },
}

allow if {
  some url, version in allowed_git
  input.git.remote == url
  input.git.tagName == version.tag
  input.git.commitChecksum == version.commit
}

# TODO: Add your pinned HTTP downloads
allowed_downloads := {
  "https://releases.example.com/app-v1.0.tar.gz": "sha256:def456...",
}

allow if {
  some url, checksum in allowed_downloads
  input.http.url == url
  input.http.checksum == checksum
}
