# SonarQube configuration — Go application.
#
# Copy to your repository root as `sonar-project.properties`.
# Implements: docs/05-ci-cd/ and templates/sonar/quality-gate-baseline.md
#
# The analysis token is supplied by Jenkins Credentials at run time and must
# NEVER appear here.

# --- Project identity -----------------------------------------------------
# ADJUST. Must match the repository, Harbor project, and the `service` label.
sonar.projectKey=orders-go-api
sonar.projectName=Orders Go API

# --- Sources and tests ----------------------------------------------------
# Go keeps tests beside the code they test, so sources and tests share a
# root and are separated by the _test.go suffix rather than by directory.
sonar.sources=.
sonar.tests=.
sonar.test.inclusions=**/*_test.go
sonar.exclusions=**/vendor/**,**/*_test.go,**/*.pb.go,**/mocks/**

sonar.sourceEncoding=UTF-8

# --- Coverage -------------------------------------------------------------
# Produced by:
#   go test ./... -coverprofile=coverage.out -covermode=atomic
#
# -covermode=atomic is required when tests run with -race, and it is what the
# pipeline uses. A profile written with a different mode may not merge.
sonar.go.coverage.reportPaths=coverage.out

# Generated code carries no useful coverage signal. It is excluded from
# COVERAGE but not from analysis — generated code can still contain a defect
# worth flagging.
sonar.coverage.exclusions=**/*_test.go,**/*.pb.go,**/mocks/**,**/cmd/**/main.go

# --- Analysis scope -------------------------------------------------------
# TBD: whether the gate evaluates new code only. See ADR-0003.
