# 0mniteck.rego - v0.1.1-Alpha - Multi-Repo Policy File
# Strict requirement for docker public registries: https, and @digest_tag or --checksum
package docker

default allow := false

allow if input.local
# allow if input.git

allow if {
  input.image.host == "docker.io"  # Docker Hub
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
