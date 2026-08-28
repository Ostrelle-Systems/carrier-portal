.PHONY: build build-prod run-review run-review-verbose test clean develop develop-reflex river-deps river-install river-migrate river-setup river-ui-install river-ui install-vl-convert db-flip version version-bump version-patch version-minor version-major version-bump-dirty version-patch-dirty version-minor-dirty version-major-dirty version-bump-dry version-patch-dry version-minor-dry version-major-dry build-versioned docker-build docker-build-push docker-build-dry docker-interactive docker-interactive-push docker-interactive-dry docker-build docker-build-push docker-build-versioned docker-build-push-versioned docker-build-dry docker-build-push-dry docker-multiarch docker-multiarch-push docker-multiarch-dry docker-interactive-multiarch docker-interactive-multiarch-push cplrops vendor-prompts-encrypt vendor-prompts-build vendor-prompts-rebuild vendor-docker-build vendor-docker-build-dry vendor-docker-build-push vendor-docker-multiarch-dry vendor-docker-multiarch-push run-debug run-fast logrun api-with-migrations build-with-ui security-sbom security-sbom-cyclonedx security-sbom-spdx security-sbom-validate release-notes-init release-notes-check release-preflight release-gh niceurl niceurl2 run-api run-worker prep-dbctx
.PHONY: upload-secrets download-secrets list-secrets-files legacy-secrets-clear generate-openapi prep-training-data check-training-data
.PHONY: razorpay-webhook-ensure razorpay-webhook-ensure-dry razorpay-verify-plans razorpay-verify-plans-low-pricing
.PHONY: raw-deploy raw-deploy-low-pricing raw-deploy-backend raw-deploy-backend-low-pricing build-staging-with-ui raw-deploy-staging stop-staging

# ============================================================================
# Environment switching
# ============================================================================

.PHONY: switch-env-prod switch-env-prod-low-pricing switch-env-selfhosted-local switch-env-selfhosted-docker switch-env-cloud-local which-env

define SWITCH_ENV
	@if [ ! -f ".env.$(1)" ]; then \
		echo "ERROR: .env.$(1) not found"; \
		exit 1; \
	fi
	@if [ -f .env ]; then cp .env .env.bak && echo "Backed up .env -> .env.bak"; fi
	@cp .env.$(1) .env
	@echo "$(1)" > .current-env
	@echo "Switched to $(1) (.env.$(1) -> .env)"
endef

switch-env-prod:
	$(call SWITCH_ENV,prod)

switch-env-prod-low-pricing:
	$(call SWITCH_ENV,prod-low-pricing)

switch-env-selfhosted-local:
	$(call SWITCH_ENV,selfhosted.local)

switch-env-selfhosted-docker:
	$(call SWITCH_ENV,selfhosted.docker)

switch-env-cloud-local:
	$(call SWITCH_ENV,cloud.local)

which-env:
	@if [ ! -f .current-env ]; then \
		echo "No .current-env found. Run 'make switch-env-<name>' first."; \
	else \
		echo "Current env: $$(cat .current-env)"; \
	fi

# Go parameters
GOENV=env -u GOROOT
GOCMD=$(GOENV) go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
BINARY_NAME=livereview
REQUIRED_GO_VERSION=$(shell awk '/^go /{print $$2; exit}' go.mod)
REQUIRED_GO_TOOLCHAIN_VER=$(shell go version | awk '{print substr($$3,3)}')
REQUIRED_GO_SERIES=$(shell echo $(REQUIRED_GO_VERSION) | awk -F. '{print $$1"."$$2}')
GOVULNCHECK_VERSION=v1.1.4
GOVULNCHECK_CMD=GOTOOLCHAIN=go$(REQUIRED_GO_TOOLCHAIN_VER) $(GOCMD) run -a golang.org/x/vuln/cmd/govulncheck@$(GOVULNCHECK_VERSION)
GH_REPO=HexmosTech/LiveReview
GH=/usr/bin/gh
GHSM_SCRIPT=scripts/ghsm.py
LEGACY_ENV_VARS=DATABASE_URL JWT_SECRET LIVEREVIEW_BACKEND_PORT LIVEREVIEW_FRONTEND_PORT LIVEREVIEW_REVERSE_PROXY LIVEREVIEW_IS_CLOUD CLOUD_JWT_SECRET FW_PARSE_ADMIN_SECRET RAZORPAY_MODE LIVEREVIEW_PRICING_PROFILE RAZORPAY_WEBHOOK_SECRET RAZORPAY_TEST_KEY RAZORPAY_TEST_SECRET RAZORPAY_TEST_MONTHLY_PLAN_ID_USD RAZORPAY_TEST_YEARLY_PLAN_ID_USD RAZORPAY_TEST_MONTHLY_PLAN_ID_INR RAZORPAY_TEST_YEARLY_PLAN_ID_INR RAZORPAY_LIVE_KEY RAZORPAY_LIVE_SECRET RAZORPAY_LIVE_ACTUAL_MONTHLY_PLAN_ID_USD RAZORPAY_LIVE_ACTUAL_YEARLY_PLAN_ID_USD RAZORPAY_LIVE_ACTUAL_MONTHLY_PLAN_ID_INR RAZORPAY_LIVE_ACTUAL_YEARLY_PLAN_ID_INR RAZORPAY_LIVE_LOW_PRICING_MONTHLY_PLAN_ID_USD RAZORPAY_LIVE_LOW_PRICING_YEARLY_PLAN_ID_USD RAZORPAY_LIVE_LOW_PRICING_MONTHLY_PLAN_ID_INR RAZORPAY_LIVE_LOW_PRICING_YEARLY_PLAN_ID_INR DISCORD_SIGNUP_WEBHOOK_URL OVSX_PAT
DEPLOY_ACTUAL_ENV_FILE=.env.prod
DEPLOY_LOW_PRICING_ENV_FILE=.env.prod.low-pricing
DEPLOY_PLAN_CATALOG_FILE=config/plan_catalog.json
DEPLOY_HOST=master
DEPLOY_PATH=/root/public_lr
SYFT_CMD=syft
SBOM_DIR=security_issues/sbom
SBOM_VERSION?=$(shell git describe --tags --exact-match 2>/dev/null || git describe --tags --abbrev=0 2>/dev/null || echo dev)
SBOM_CDX=$(SBOM_DIR)/livereview-$(SBOM_VERSION)-cyclonedx.json
SBOM_SPDX=$(SBOM_DIR)/livereview-$(SBOM_VERSION)-spdx.json
SBOM_UI_CDX=$(SBOM_DIR)/livereview-ui-$(SBOM_VERSION)-cyclonedx.json
SBOM_UI_SPDX=$(SBOM_DIR)/livereview-ui-$(SBOM_VERSION)-spdx.json
RELEASE_NOTES_DIR=docs/releases
RELEASE_NOTES_TEMPLATE=$(RELEASE_NOTES_DIR)/_template.md
RELEASE_GH_SCRIPT=scripts/release_gh.py
OSV_SCANNER_CONFIG=osv-scanner.toml

# Content hash of ui/docs/training_data/ as of the last `make prep-training-data`
# run. Kept up to date automatically by that target (scripts/prep_training_data.sh
# rewrites this line). `make check-training-data` compares it against the
# corpus's current hash and re-runs prep-training-data when they diverge.
TRAINING_DATA_HASH=b07421c6eb497d475ab5255ec2f5c101f5766140cbe0f773875c9c44fd0371b0

# Load environment variables from .env file
-include .env
export

build:
	rm $(BINARY_NAME) || true
	$(GOBUILD) -o $(BINARY_NAME)

build-prod:
	rm $(BINARY_NAME) || true
	$(GOBUILD) -tags production -o $(BINARY_NAME)
# Minimal CI build
build-ci:
	rm -f $(BINARY_NAME)
	SKIP_TYPED_GEN=1 go build -tags=ci -o livereview .

# Vendor prompts: encrypt plaintext templates and generate embedded assets
# Usage examples:
#   make vendor-prompts-encrypt                       # default output dir
#   make vendor-prompts-encrypt ARGS="--build-id 20250101010101"
#   make vendor-prompts-encrypt ARGS="--key-hex <64-hex> --key-id mykey"
vendor-prompts-encrypt:
	$(GOCMD) run ./internal/prompts/vendor/cmd/prompts-encrypt --out internal/prompts/vendor/templates $(ARGS)

# Build binary with vendor prompts embedded (requires assets from vendor-prompts-encrypt)
vendor-prompts-build:
	$(GOBUILD) -tags vendor_prompts -o $(BINARY_NAME)_vendor ./livereview.go

# Convenience: regenerate assets and build vendor binary in one step
vendor-prompts-rebuild: vendor-prompts-encrypt vendor-prompts-build

# Email template preview
email-preview:
	$(GOCMD) run cmd/email-preview/main.go

# Version management targets
version:
	@python scripts/lrops.py version

version-bump:
	@python scripts/lrops.py bump $(ARGS)

version-patch:
	@python scripts/lrops.py bump --type patch $(ARGS)

version-minor:
	@python scripts/lrops.py bump --type minor $(ARGS)

version-major:
	@python scripts/lrops.py bump --type major $(ARGS)

# Version management targets that allow dirty working directory
version-bump-dirty:
	@python scripts/lrops.py bump --allow-dirty

version-patch-dirty:
	@python scripts/lrops.py bump --type patch --allow-dirty

version-minor-dirty:
	@python scripts/lrops.py bump --type minor --allow-dirty

version-major-dirty:
	@python scripts/lrops.py bump --type major --allow-dirty

# Dry-run version targets
version-bump-dry:
	@python scripts/lrops.py bump --dry-run --allow-dirty

version-patch-dry:
	@python scripts/lrops.py bump --type patch --dry-run --allow-dirty

version-minor-dry:
	@python scripts/lrops.py bump --type minor --dry-run --allow-dirty

version-major-dry:
	@python scripts/lrops.py bump --type major --dry-run --allow-dirty

build-versioned:
	@python scripts/lrops.py build

# DOCKER-BUILD: Comprehensive Docker image build with automated version management
# Implementation: scripts/lrops.py:cmd_build() -> build_docker_image() (lines 634-661)
# Process Flow:
#   1. Gets current Git version/commit from get_current_version_info() (lines 186-261)
#   2. Builds React UI: cd ui/ && npm install && npm run build (via Dockerfile stage 1)
#   3. Creates multi-stage Docker build with embedded UI assets
#   4. Injects version info via build args: VERSION, BUILD_TIME, GIT_COMMIT (Dockerfile lines 78-85)
#   5. Uses Dockerfile stages: ui-builder (Node.js) -> go-builder (Go+tools) -> alpine runtime
#   6. Embeds dbmate, River CLI/UI tools for database/queue management
#   7. Single-arch build by default (amd64), can be multi-arch with --multiarch
#   8. Interactive confirmation prompt before build execution
# Files: scripts/lrops.py (lines 634-826), Dockerfile (multi-stage), ui/package.json
docker-build:
	@python scripts/lrops.py build --docker $(ARGS)

# DOCKER-BUILD-PUSH: Same as docker-build but automatically pushes to registry
# Implementation: scripts/lrops.py:cmd_build() with push=True flag
# Process Flow:
#   1-7. Same as docker-build above
#   8. Additional push phase via _build_single_arch_image() (lines 827-866)
#   9. Pushes to registry: git.apps.hexmos.com:5050/hexmos/livereview by default
#   10. Tags both version-specific (e.g., v1.2.3) and 'latest' if make_latest=True
#   11. Uses docker push commands for each tag
# Registry: Configurable via --registry, defaults to GitLab Container Registry
# Tags: <registry>/<image>:<version> and optionally <registry>/<image>:latest
docker-build-push:
	@python scripts/lrops.py build --docker --push $(ARGS)

# Interactive Docker build with tag selection
docker-interactive:
	@python scripts/lrops.py docker

docker-interactive-push:
	@python scripts/lrops.py docker --push $(ARGS)

# Dry-run Docker targets
docker-build-dry:
	@python scripts/lrops.py build --docker --dry-run $(ARGS)

docker-interactive-dry:
	@python scripts/lrops.py docker --dry-run

# Legacy build-push for backward compatibility (now uses versioning)
build-push: docker-build-push

run-debug: check-training-data
	pkill -9 livereview || true
	@DLV_BIN_DIR=$$($(GOCMD) env GOBIN); \
	if [ -z "$$DLV_BIN_DIR" ]; then DLV_BIN_DIR="$$($(GOCMD) env GOPATH)/bin"; fi; \
	command -v dlv >/dev/null 2>&1 || { \
		echo "Installing Delve with Go $(REQUIRED_GO_VERSION)..."; \
		GOTOOLCHAIN=go$(REQUIRED_GO_TOOLCHAIN_VER) $(GOCMD) install github.com/go-delve/delve/cmd/dlv@latest; \
	}; \
	if ! $(GOCMD) version -m "$$DLV_BIN_DIR/dlv" 2>/dev/null | grep -q "go$(REQUIRED_GO_SERIES)"; then \
		echo "Rebuilding Delve with Go $(REQUIRED_GO_VERSION) for DWARFv5+ compatibility..."; \
		GOTOOLCHAIN=go$(REQUIRED_GO_TOOLCHAIN_VER) $(GOCMD) install github.com/go-delve/delve/cmd/dlv@latest; \
	fi
	which air || $(GOCMD) install github.com/air-verse/air@latest
	DLV_BIN_DIR=$$($(GOCMD) env GOBIN); if [ -z "$$DLV_BIN_DIR" ]; then DLV_BIN_DIR="$$($(GOCMD) env GOPATH)/bin"; fi; PATH="$$DLV_BIN_DIR:$$PATH" air


# Fast dev-run: full compiler optimizations, no Delve. Use this instead of
# `run-debug` when you don't need to attach a debugger - dbctx's
# embedding/scoring code in particular is much slower under run-debug's
# `-gcflags='all=-N -l'`, which disables optimization/inlining across the
# whole binary, not just the code being debugged.
run-fast: check-training-data
	pkill -9 livereview-fast || true
	which air || $(GOCMD) install github.com/air-verse/air@latest
	air -c .air.fast.toml

# Disable Typed OpenAPI schema generation for CI
run-skip-typed:
	SKIP_TYPED_GEN=1 $(MAKE) run-debug

logrun:
	which air || $(GOCMD) install github.com/air-verse/air@latest
	bash -c 'set -o pipefail; air 2>&1 | tee "logrun-$$(date +%Y%m%d-%H%M%S).log"'

develop: check-training-data
	@DLV_BIN_DIR=$$($(GOCMD) env GOBIN); \
	if [ -z "$$DLV_BIN_DIR" ]; then DLV_BIN_DIR="$$($(GOCMD) env GOPATH)/bin"; fi; \
	command -v dlv >/dev/null 2>&1 || { \
		echo "Installing Delve with Go $(REQUIRED_GO_VERSION)..."; \
		GOTOOLCHAIN=go$(REQUIRED_GO_TOOLCHAIN_VER) $(GOCMD) install github.com/go-delve/delve/cmd/dlv@latest; \
	}; \
	if ! $(GOCMD) version -m "$$DLV_BIN_DIR/dlv" 2>/dev/null | grep -q "go$(REQUIRED_GO_SERIES)"; then \
		echo "Rebuilding Delve with Go $(REQUIRED_GO_VERSION) for DWARFv5+ compatibility..."; \
		GOTOOLCHAIN=go$(REQUIRED_GO_TOOLCHAIN_VER) $(GOCMD) install github.com/go-delve/delve/cmd/dlv@latest; \
	fi
	which air || $(GOCMD) install github.com/air-verse/air@latest
	DLV_BIN_DIR=$$($(GOCMD) env GOBIN); if [ -z "$$DLV_BIN_DIR" ]; then DLV_BIN_DIR="$$($(GOCMD) env GOPATH)/bin"; fi; PATH="$$DLV_BIN_DIR:$$PATH" air

develop-reflex: check-training-data
	which reflex || $(GOCMD) install github.com/cespare/reflex@latest
	reflex -r '\.go$$' -s -- sh -c '$(GOENV) go build -o $(BINARY_NAME) && ./$(BINARY_NAME) api'

api-with-migrations:
	dbmate up
	$(GOCMD) run livereview.go api

run-api: build
	./$(BINARY_NAME) api

run-worker: build
	./$(BINARY_NAME) worker

run-review:
	./$(BINARY_NAME) review --dry-run https://git.apps.hexmos.com/hexmos/liveapi/-/merge_requests/365

run-review-verbose:
	./$(BINARY_NAME) review --dry-run --verbose https://git.apps.hexmos.com/hexmos/liveapi/-/merge_requests/365

test:
	$(GOTEST) -v ./...

# Discover Go package directories while avoiding restricted directories
TEST_PACKAGES := $(shell find . \
	-path './livereview_pgdata' -prune -o \
	-path './lrdata' -prune -o \
	-path './vendor' -prune -o \
	-path './debug' -prune -o \
	-path './tests' -prune -o \
	-type f -name '*.go' -print 2>/dev/null | \
	xargs -n1 dirname | sort -u | tr '\n' ' ')

# Exclude ./scripts because it contains multiple standalone main programs.
SECURITY_GOVULN_PACKAGES := $(filter-out ./scripts,$(TEST_PACKAGES))

.PHONY: testall
testall:
	$(GOTEST) -count=1 $(TEST_PACKAGES)

.PHONY: security-govulncheck security-govulncheck-json security-osv security-gitleaks security-semgrep security-dependabot security-gh-secret-scanning security-triage

# Run Go vulnerability analysis for reachable vulnerabilities.
security-govulncheck:
	@echo "Running govulncheck $(GOVULNCHECK_VERSION) with Go $(REQUIRED_GO_VERSION)..."
	@$(GOVULNCHECK_CMD) $(SECURITY_GOVULN_PACKAGES)

# Emit govulncheck report as JSON artifact under security_issues/.
security-govulncheck-json:
	mkdir -p security_issues
	$(GOVULNCHECK_CMD) -json $(SECURITY_GOVULN_PACKAGES) > security_issues/govulncheck-$(shell date +%d-%m-%Y).json

# Run OSV scanner against this repository.
security-osv:
	@command -v osv-scanner >/dev/null 2>&1 || { \
		echo "osv-scanner not found. Install from https://github.com/google/osv-scanner"; \
		exit 1; \
	}
	@mkdir -p security_issues
	@dated_report="security_issues/osv-scanner-$(shell date +%d-%m-%Y).json"; \
		latest_report="security_issues/osv-scanner-latest.json"; \
		status=0; \
		osv-scanner scan source --recursive --format json --config $(OSV_SCANNER_CONFIG) --no-call-analysis=go \
			--experimental-exclude=debug \
			--experimental-exclude=scripts \
			--experimental-exclude=tests \
			--experimental-exclude=.livereview_pgdata \
			--experimental-exclude=.lrdata \
			--experimental-exclude=livereview_pgdata \
			--experimental-exclude=lrdata \
			. > "$$dated_report" || status=$$?; \
		if [ $$status -ne 0 ] && [ $$status -ne 1 ]; then \
			echo "osv-scanner failed with exit code $$status"; \
			exit $$status; \
		fi; \
		if [ ! -s "$$dated_report" ]; then \
			echo "osv-scanner did not produce a report"; \
			exit 1; \
		fi; \
		cp "$$dated_report" "$$latest_report"; \
		if [ $$status -eq 1 ]; then \
			echo "osv-scanner reported vulnerabilities (exit 1); report still generated."; \
		fi; \
		echo "Wrote $$dated_report"; \
		echo "Updated $$latest_report"

# Run gitleaks and emit a dated CSV artifact under security_issues/.
security-gitleaks:
	@command -v gitleaks >/dev/null 2>&1 || { \
		echo "gitleaks not found. Install from https://github.com/gitleaks/gitleaks"; \
		exit 1; \
	}
	@mkdir -p security_issues
	@gitleaks git . -f csv -r security_issues/gitleaks-$(shell date +%d-%m-%Y).csv
	@echo "Wrote security_issues/gitleaks-$(shell date +%d-%m-%Y).csv"

# Run Semgrep and emit a dated JSON artifact under security_issues/.
security-semgrep:
	@command -v semgrep >/dev/null 2>&1 || { \
		echo "semgrep not found. Install from https://semgrep.dev/docs/getting-started/quickstart"; \
		exit 1; \
	}
	@mkdir -p security_issues
	@dated_report="security_issues/semgrep-$(shell date +%d-%m-%Y).json"; \
		latest_report="security_issues/semgrep-latest.json"; \
		fail_on_findings=$${SEMGREP_FAIL_ON_FINDINGS:-1}; \
		status=0; \
		semgrep scan --config auto \
			--exclude ui/docs \
			--exclude ui/build \
			--exclude ui/dist \
			--json --output "$$dated_report" . || status=$$?; \
		if [ $$status -ne 0 ] && [ $$status -ne 1 ]; then \
			echo "semgrep failed with exit code $$status"; \
			exit $$status; \
		fi; \
		if [ ! -s "$$dated_report" ]; then \
			echo "semgrep did not produce a report"; \
			exit 1; \
		fi; \
		cp "$$dated_report" "$$latest_report"; \
		if [ $$status -eq 1 ]; then \
			echo "semgrep reported findings (exit 1); report still generated."; \
			if [ "$$fail_on_findings" = "1" ]; then \
				echo "Failing because SEMGREP_FAIL_ON_FINDINGS=$$fail_on_findings"; \
				exit 1; \
			fi; \
			echo "Continuing because SEMGREP_FAIL_ON_FINDINGS=$$fail_on_findings"; \
		fi; \
		echo "Wrote $$dated_report"; \
		echo "Updated $$latest_report"

# Pull Dependabot alerts via GitHub API and emit a dated JSON artifact under security_issues/.
security-dependabot:
	@command -v $(GH) >/dev/null 2>&1 || { \
		echo "gh not found. Install from https://cli.github.com/"; \
		exit 1; \
	}
	@mkdir -p security_issues
	@dated_report="security_issues/dependabot-live-review-$(shell date +%d-%m-%Y).json"; \
		$(GH) api \
			-H "Accept: application/vnd.github+json" \
			-H "X-GitHub-Api-Version: 2022-11-28" \
			/repos/$(GH_REPO)/dependabot/alerts \
			--paginate > "$$dated_report"; \
		echo "Wrote $$dated_report"

# Pull secret scanning alerts via GitHub API and emit a dated JSON artifact under security_issues/.
security-gh-secret-scanning:
	@command -v $(GH) >/dev/null 2>&1 || { \
		echo "gh not found. Install from https://cli.github.com/"; \
		exit 1; \
	}
	@mkdir -p security_issues
	@dated_report="security_issues/gh-secret-scanning-live-review-$(shell date +%d-%m-%Y).json"; \
		$(GH) api \
			-H "Accept: application/vnd.github+json" \
			-H "X-GitHub-Api-Version: 2022-11-28" \
			/repos/$(GH_REPO)/secret-scanning/alerts \
			--paginate > "$$dated_report"; \
		echo "Wrote $$dated_report"

# Regenerate machine-readable and markdown triage artifacts from the latest OSV report.
security-triage: security-osv
	@python3 scripts/extract_osv_report.py \
		--input security_issues/osv-scanner-latest.json \
		--csv security_issues/osv-triage-latest.csv \
		--md security_issues/osv-triage-latest.md
	@echo "Wrote security_issues/osv-triage-latest.csv"
	@echo "Wrote security_issues/osv-triage-latest.md"

.PHONY: license-test
license-test:
	$(GOTEST) -v ./internal/license -count=1

clean:
	$(GOCLEAN)
	rm -f $(BINARY_NAME)

# River queue setup commands
river-deps:
	$(GOCMD) get github.com/riverqueue/river
	$(GOCMD) get github.com/riverqueue/river/riverdriver/riverpgxv5

river-install:
	$(GOCMD) install github.com/riverqueue/river/cmd/river@latest

river-ui-install:
	$(GOCMD) install riverqueue.com/riverui/cmd/riverui@latest

# Install vl-convert binary (Vega-Lite → PNG renderer) for the local OS/arch.
# Downloads the pre-built release from GitHub and places it in /usr/local/bin.
# Requires glibc >= 2.38 on Linux (pre-built against Ubuntu 24.04).
# On older Linux (glibc < 2.38), use Docker or pip install vl-convert-python instead.
VL_CONVERT_VERSION ?= v1.9.0
install-vl-convert:
	@OS=$$(uname -s | tr '[:upper:]' '[:lower:]'); \
	ARCH=$$(uname -m); \
	case "$$OS" in \
		linux)  glibc_ver=$$(ldd --version 2>&1 | awk '/GLIBC/{print $$NF; exit}'); \
			$$(expr "$$glibc_ver" \< "2.38" >/dev/null 2>&1) && { \
				echo "Detected GLIBC $$glibc_ver — too old for the pre-built binary (needs >= 2.38)."; \
				echo "Use one of these alternatives:"; \
				echo "  • pip install vl-convert-python        (native Python wheel)"; \
				echo "  • cargo install vl-convert             (build from source, requires Rust)"; \
				exit 1; \
			}; \
			case "$$ARCH" in \
				x86_64|amd64) asset="vl-convert_linux-64.zip" ;; \
				aarch64|arm64) asset="vl-convert_linux-aarch64.zip" ;; \
				*) echo "Unsupported arch: $$ARCH"; exit 1 ;; \
			esac ;; \
		darwin) case "$$ARCH" in \
					x86_64) asset="vl-convert_osx-64.zip" ;; \
					arm64)  asset="vl-convert_osx-arm64.zip" ;; \
					*) echo "Unsupported arch: $$ARCH"; exit 1 ;; \
				esac ;; \
		mingw*|msys*|cygwin*) asset="vl-convert_win-64.zip" ;; \
		*) echo "Unsupported OS: $$OS"; exit 1 ;; \
	esac; \
	url="https://github.com/vega/vl-convert/releases/download/$(VL_CONVERT_VERSION)/$$asset"; \
	echo "Downloading $$asset..."; \
	curl -sL --fail "$$url" -o /tmp/vl-convert.zip && \
	unzip -o /tmp/vl-convert.zip -d /tmp/vl-convert-extracted && \
	sudo mkdir -p /usr/local/lib/vl-convert && \
	sudo cp /tmp/vl-convert-extracted/bin/vl-convert /usr/local/bin/ && \
	sudo cp /tmp/vl-convert-extracted/bin/LICENSE /tmp/vl-convert-extracted/bin/thirdparty_* /usr/local/lib/vl-convert/ 2>/dev/null; \
	rm -rf /tmp/vl-convert.zip /tmp/vl-convert-extracted && \
	echo "Installed: $$(/usr/local/bin/vl-convert --version 2>&1 || true)"

river-migrate:
	river migrate-up --database-url "$(DATABASE_URL)"

river-ui:
	@echo "Starting River UI with DATABASE_URL: $(DATABASE_URL)"
	DATABASE_URL="$(DATABASE_URL)" riverui

staging-river-ui:
	@if [ ! -f $(DEPLOY_STAGING_ENV_FILE) ]; then \
		echo "❌ ERROR: $(DEPLOY_STAGING_ENV_FILE) not found"; \
		exit 1; \
	fi
	@echo "Starting River UI with Staging DATABASE_URL..."
	@set -a && . ./$(DEPLOY_STAGING_ENV_FILE) && set +a && DATABASE_URL="$$DATABASE_URL" riverui

# 🚀 ONE COMMAND TO DO IT ALL - Install River dependencies, CLI tool, UI tool, and run migrations
river-setup: river-deps river-install river-ui-install river-migrate

# Database URL switcher - flips between localhost and livereview-db
db-flip:
	@echo "Current DATABASE_URL in .env:"
	@grep "DATABASE_URL=" .env
	@if grep -q "@localhost:" .env; then \
		echo "Switching from localhost to livereview-db..."; \
		sed -i 's/@localhost:/@livereview-db:/g' .env; \
	elif grep -q "@livereview-db:" .env; then \
		echo "Switching from livereview-db to localhost..."; \
		sed -i 's/@livereview-db:/@localhost:/g' .env; \
	else \
		echo "No recognized database host found in .env file"; \
		exit 1; \
	fi
	@echo "New DATABASE_URL in .env:"
	@grep "DATABASE_URL=" .env

# Build dbctx index from local .env DATABASE_URL and import terminology
prep-dbctx: export PATH := $(HOME)/go/bin:$(PATH)
prep-dbctx:
	@if [ -z "$(DATABASE_URL)" ]; then \
		echo "❌ ERROR: DATABASE_URL not set. Check your .env file."; \
		exit 1; \
	fi
	-rm -f $(HOME)/livereview.dtx $(HOME)/livereview.dtx-wal $(HOME)/livereview.dtx-shm $(HOME)/livereview.dtx-journal
	@DBURL=$$(echo '$(DATABASE_URL)' | sed 's/?sslmode=.*//'); \
	echo "🔨 Building dbctx index from $$(echo "$$DBURL" | sed -E 's#(://[^:]+:)[^@]+(@)#\1***\2#')..."; \ 
