# Copy to your repository root as `.gitignore`.
#
# The first section is the one that matters. A secret committed and then
# deleted remains in history, in every clone, fork, and mirror, and in any CI
# cache. Deleting the file is not remediation — rotate the credential.

# --- Secrets and local configuration -------------------------------------
.env
.env.*
!.env.example
*.pem
*.key
*.pfx
.netrc

# --- Build output ---------------------------------------------------------
bin/
dist/
*.exe
*.test
*.out
!coverage.out

# NOTE: go.sum is NOT ignored. It must be committed — it pins every module by
# hash, and `go mod download` verifies against it. Without it the same commit
# can resolve different module content, and `go mod verify` in the pipeline
# has nothing to verify against.
#
# NOTE: vendor/ is not ignored either. If the project vendors dependencies,
# they belong in the repository; if it does not, the directory is absent.

# --- Test and analysis output --------------------------------------------
coverage.html
*.prof
.scannerwork/
trivy-report.*
sbom-*.json
*.sarif

# --- Editor and OS --------------------------------------------------------
.vscode/
!.vscode/extensions.json
!.vscode/settings.json
.idea/
.history/
*.swp
*~
.DS_Store
Thumbs.db

# --- Local scratch --------------------------------------------------------
tmp/
temp/
*.local
*.log
