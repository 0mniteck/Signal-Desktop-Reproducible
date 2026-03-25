# 0mniteck.rego - v0.1-Alpha - Multi-Repo Policy File
package docker

default allow := false

allow if input.local
# allow if input.git

# Allow docker public registries
allow if {
  input.image.host == "docker.io"  # Docker Hub
}

allow if {
  input.image.host == "dhi.io"  # Docker Hardened Images
}

# Require HTTPS for all downloads
allow if {
  input.http.schema == "https"
}

decision := {"allow": allow}
