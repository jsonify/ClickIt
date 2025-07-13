# ClickIt - Professional Build & Deploy Makefile
# Inspired by macos-auto-clicker-main with adaptations for Swift Package Manager

.PHONY: help setup update clean build local beta prod test lint install sign release

# Default target
.DEFAULT_GOAL := help

# Configuration
APP_NAME = ClickIt
BUNDLE_ID = com.jsonify.clickit
DIST_DIR = dist
BUILD_MODE = release

# Colors for output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[0;33m
BLUE = \033[0;34m
NC = \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)ClickIt Build & Deploy Commands$(NC)"
	@echo ""
	@echo "$(GREEN)Development:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(YELLOW)%-12s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Examples:$(NC)"
	@echo "  make setup     # Initial project setup"
	@echo "  make build     # Build development version"
	@echo "  make local     # Build and sign for local testing"
	@echo "  make beta      # Create beta release (if on staging branch)"
	@echo "  make prod      # Create production release (if on main branch)"

setup: ## Setup development environment and dependencies
	@echo "$(BLUE)🔧 Setting up ClickIt development environment...$(NC)"
	@# Check if required tools are available
	@which swift > /dev/null || (echo "$(RED)❌ Swift not found. Install Xcode Command Line Tools.$(NC)" && exit 1)
	@which git > /dev/null || (echo "$(RED)❌ Git not found.$(NC)" && exit 1)
	@echo "$(GREEN)✅ Swift and Git are available$(NC)"
	
	@# Check if we should install additional tools
	@if ! which swiftlint > /dev/null 2>&1; then \
		echo "$(YELLOW)⚠️  SwiftLint not found. Install with: brew install swiftlint$(NC)"; \
	else \
		echo "$(GREEN)✅ SwiftLint is available$(NC)"; \
	fi
	
	@# Create necessary directories
	@mkdir -p $(DIST_DIR)
	@mkdir -p scripts
	@echo "$(GREEN)✅ Created necessary directories$(NC)"
	
	@# Initialize git hooks (if we add them later)
	@if [ -d .git ]; then \
		echo "$(GREEN)✅ Git repository detected$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  Not a git repository$(NC)"; \
	fi
	
	@echo "$(GREEN)🎉 Setup complete! Run 'make help' to see available commands.$(NC)"

update: ## Update build tools and dependencies (for future Fastlane/Ruby integration)
	@echo "$(BLUE)🔄 Updating build dependencies...$(NC)"
	@# For now, just update Swift packages
	@swift package update
	@echo "$(GREEN)✅ Dependencies updated$(NC)"
	@# TODO: Add Fastlane/Ruby bundle update when implemented

clean: ## Clean build artifacts and temporary files
	@echo "$(BLUE)🧹 Cleaning build artifacts...$(NC)"
	@swift package clean
	@rm -rf $(DIST_DIR)
	@rm -rf .build
	@echo "$(GREEN)✅ Clean complete$(NC)"

build: ## Build the project (development mode)
	@echo "$(BLUE)🔨 Building $(APP_NAME) in development mode...$(NC)"
	@swift build
	@echo "$(GREEN)✅ Development build complete$(NC)"

test: ## Run all tests
	@echo "$(BLUE)🧪 Running tests...$(NC)"
	@swift test
	@echo "$(GREEN)✅ All tests passed$(NC)"

lint: ## Run SwiftLint code quality checks
	@echo "$(BLUE)🔍 Running SwiftLint...$(NC)"
	@if which swiftlint > /dev/null 2>&1; then \
		swiftlint lint --strict; \
		echo "$(GREEN)✅ Linting passed$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  SwiftLint not installed. Run: brew install swiftlint$(NC)"; \
		exit 1; \
	fi

local: build test lint ## Build, test, lint, and create local app bundle for testing
	@echo "$(BLUE)📱 Creating local app bundle...$(NC)"
	@./build_app.sh $(BUILD_MODE)
	@echo "$(GREEN)✅ Local build complete! Launch with: open $(DIST_DIR)/$(APP_NAME).app$(NC)"

sign: ## Sign the app bundle with development certificate
	@echo "$(BLUE)🔐 Signing app bundle...$(NC)"
	@if [ -z "$(CODE_SIGN_IDENTITY)" ]; then \
		echo "$(RED)❌ CODE_SIGN_IDENTITY not set. See CERTIFICATE_SETUP.md$(NC)"; \
		exit 1; \
	fi
	@./scripts/sign-app.sh
	@echo "$(GREEN)✅ App signing complete$(NC)"

install: local ## Build and install to /Applications (for easy testing)
	@echo "$(BLUE)📦 Installing $(APP_NAME) to /Applications...$(NC)"
	@if [ -d "/Applications/$(APP_NAME).app" ]; then \
		echo "$(YELLOW)⚠️  Removing existing installation...$(NC)"; \
		rm -rf "/Applications/$(APP_NAME).app"; \
	fi
	@cp -R "$(DIST_DIR)/$(APP_NAME).app" "/Applications/"
	@echo "$(GREEN)✅ $(APP_NAME) installed to /Applications$(NC)"
	@echo "$(BLUE)Launch from Launchpad or: open \"/Applications/$(APP_NAME).app\"$(NC)"

beta: ## Create beta release (requires staging branch and git tag matching beta*)
	@echo "$(BLUE)🚀 Creating beta release...$(NC)"
	@# Check if we're on staging branch
	@CURRENT_BRANCH=$$(git rev-parse --abbrev-ref HEAD); \
	if [ "$$CURRENT_BRANCH" != "staging" ]; then \
		echo "$(RED)❌ Beta releases must be created from 'staging' branch. Current: $$CURRENT_BRANCH$(NC)"; \
		exit 1; \
	fi
	@# Check for beta tag pattern
	@CURRENT_TAG=$$(git describe --exact-match --tags HEAD 2>/dev/null || echo ""); \
	if [ -z "$$CURRENT_TAG" ] || [[ ! "$$CURRENT_TAG" =~ ^beta ]]; then \
		echo "$(RED)❌ Beta release requires a git tag matching 'beta*' pattern$(NC)"; \
		echo "$(BLUE)Create one with: git tag beta-v1.0.0-$(shell date +%Y%m%d) && git push origin --tags$(NC)"; \
		exit 1; \
	fi
	@# TODO: Implement Fastlane beta workflow when ready
	@echo "$(YELLOW)⚠️  Beta workflow not yet implemented. Use 'make local' for now.$(NC)"

prod: ## Create production release (requires main branch and git tag matching v*)
	@echo "$(BLUE)🚀 Creating production release...$(NC)"
	@# Check if we're on main branch
	@CURRENT_BRANCH=$$(git rev-parse --abbrev-ref HEAD); \
	if [ "$$CURRENT_BRANCH" != "main" ]; then \
		echo "$(RED)❌ Production releases must be created from 'main' branch. Current: $$CURRENT_BRANCH$(NC)"; \
		exit 1; \
	fi
	@# Check for production tag pattern
	@CURRENT_TAG=$$(git describe --exact-match --tags HEAD 2>/dev/null || echo ""); \
	if [ -z "$$CURRENT_TAG" ] || [[ ! "$$CURRENT_TAG" =~ ^v[0-9] ]]; then \
		echo "$(RED)❌ Production release requires a git tag matching 'v*' pattern$(NC)"; \
		echo "$(BLUE)Create one with: git tag v1.0.0 && git push origin --tags$(NC)"; \
		exit 1; \
	fi
	@# TODO: Implement Fastlane production workflow when ready
	@echo "$(YELLOW)⚠️  Production workflow not yet implemented. Use 'make local' for now.$(NC)"

release: ## Interactive release helper - guides through proper release process
	@echo "$(BLUE)🎯 ClickIt Release Helper$(NC)"
	@echo ""
	@echo "$(GREEN)Current status:$(NC)"
	@CURRENT_BRANCH=$$(git rev-parse --abbrev-ref HEAD); \
	echo "  Branch: $$CURRENT_BRANCH"
	@CURRENT_TAG=$$(git describe --exact-match --tags HEAD 2>/dev/null || echo "none"); \
	echo "  Tag: $$CURRENT_TAG"
	@git status --porcelain | wc -l | xargs -I {} echo "  Uncommitted changes: {}"
	@echo ""
	@echo "$(GREEN)Release options:$(NC)"
	@echo "  $(YELLOW)make local$(NC)  - Build for local testing"
	@echo "  $(YELLOW)make beta$(NC)   - Beta release (staging branch + beta-* tag)"
	@echo "  $(YELLOW)make prod$(NC)   - Production release (main branch + v* tag)"
	@echo ""
	@echo "$(GREEN)Next steps:$(NC)"
	@CURRENT_BRANCH=$$(git rev-parse --abbrev-ref HEAD); \
	if [ "$$CURRENT_BRANCH" = "main" ]; then \
		echo "  1. Create production tag: git tag v1.0.0"; \
		echo "  2. Push tag: git push origin --tags"; \
		echo "  3. Run: make prod"; \
	elif [ "$$CURRENT_BRANCH" = "staging" ]; then \
		echo "  1. Create beta tag: git tag beta-v1.0.0-$(shell date +%Y%m%d)"; \
		echo "  2. Push tag: git push origin --tags"; \
		echo "  3. Run: make beta"; \
	else \
		echo "  1. Switch to staging (beta) or main (prod) branch"; \
		echo "  2. Follow appropriate tagging steps above"; \
	fi