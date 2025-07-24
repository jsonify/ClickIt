#!/bin/bash
# scripts/install-git-hooks.sh
# Install git hooks for version validation

set -e

echo "🔧 Installing git hooks for version validation..."

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Not in a git repository"
    exit 1
fi

# Create .git/hooks directory if it doesn't exist
mkdir -p .git/hooks

# Install pre-commit hook
if [ -f ".githooks/pre-commit" ]; then
    cp .githooks/pre-commit .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit
    echo "✅ Pre-commit hook installed"
else
    echo "❌ .githooks/pre-commit not found"
    exit 1
fi

# Set git hooks path (optional - uses .githooks directly)
git config core.hooksPath .githooks

echo "🎉 Git hooks installation complete!"
echo ""
echo "📋 Installed hooks:"
echo "   • pre-commit: Version synchronization validation"
echo ""
echo "💡 The pre-commit hook will:"
echo "   • Validate version sync before each commit"
echo "   • Provide warnings if versions are mismatched"
echo "   • Not block commits (warnings only)"
echo ""
echo "🔧 To uninstall: git config --unset core.hooksPath"