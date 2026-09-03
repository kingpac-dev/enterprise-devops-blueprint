# Copy to your repository root as `.dockerignore`.
#
# Without this file the entire build context is sent to the daemon, including
# .git and any local .env. Anything that reaches the build context can end up
# inside the image, and image layers are additive — deleting a file in a
# later layer does not remove it from the image.

# --- Secrets and local configuration -------------------------------------
.env
.env.*
*.pem
*.key
*.pfx
.netrc

# --- Version control ------------------------------------------------------
.git
.gitignore
.gitattributes
.github

# --- Build output ---------------------------------------------------------
# NOTE: vendor/ is deliberately NOT ignored. If this project uses
# `go mod vendor`, the build needs it in the context. If it does not, the
# directory is absent anyway. Ignoring it would produce a build that fails
# to resolve modules with an error that does not name the cause.
bin/
dist/
*.exe
*.test
*.out

# --- Test and analysis output --------------------------------------------
coverage.out
coverage.html
*.prof
trivy-report.*
sbom-*.json

# --- Editor and OS --------------------------------------------------------
.vscode
.idea
*.swp
.DS_Store
Thumbs.db

# --- Docker and CI --------------------------------------------------------
Dockerfile*
.dockerignore
docker-compose*.yml
compose*.yml
Jenkinsfile*
deployment

# --- Documentation --------------------------------------------------------
README.md
AGENTS.md
docs
