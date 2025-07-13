#!/bin/bash

# Setup Git Hooks for ClickIt Development
# Configures commit message template and pre-commit hooks

set -e

echo "🔧 Setting up Git hooks and configuration..."

# Set commit message template
echo "📝 Configuring commit message template..."
git config commit.template .gitmessage
echo "✅ Commit template configured (use git commit to see template)"

# Create pre-commit hook
echo "🔍 Setting up pre-commit hook..."
mkdir -p .git/hooks

cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

# Pre-commit hook for ClickIt
# Runs basic checks before allowing commits

set -e

echo "🔍 Running pre-commit checks..."

# Check if SwiftLint is available and run it
if command -v swiftlint >/dev/null 2>&1; then
    echo "📋 Running SwiftLint..."
    if ! swiftlint lint --quiet; then
        echo "❌ SwiftLint failed. Fix the issues above and try again."
        echo "💡 Run 'swiftlint lint' to see detailed errors"
        exit 1
    fi
    echo "✅ SwiftLint passed"
else
    echo "⚠️  SwiftLint not found. Install with: brew install swiftlint"
fi

# Check for build errors (quick build test)
echo "🔨 Testing build..."
if ! swift build >/dev/null 2>&1; then
    echo "❌ Build failed. Fix build errors and try again."
    echo "💡 Run 'swift build' to see detailed errors"
    exit 1
fi
echo "✅ Build test passed"

# Check for TODO/FIXME in staged files (optional warning)
STAGED_FILES=$(git diff --cached --name-only --diff-filter=AM | grep '\.swift$' || true)
if [ -n "$STAGED_FILES" ]; then
    TODO_COUNT=$(grep -c "TODO\|FIXME" $STAGED_FILES 2>/dev/null || echo "0")
    if [ "$TODO_COUNT" -gt 0 ]; then
        echo "⚠️  Found $TODO_COUNT TODO/FIXME comments in staged files"
        echo "   Consider addressing them before committing"
    fi
fi

echo "✅ All pre-commit checks passed!"
EOF

chmod +x .git/hooks/pre-commit

# Create commit-msg hook for conventional commits validation
echo "📝 Setting up commit message validation..."
cat > .git/hooks/commit-msg << 'EOF'
#!/bin/bash

# Commit message hook for ClickIt
# Validates conventional commit format

commit_regex='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?: .{1,50}'

if ! grep -qE "$commit_regex" "$1"; then
    echo "❌ Invalid commit message format!"
    echo ""
    echo "📋 Conventional commit format required:"
    echo "   <type>(<scope>): <description>"
    echo ""
    echo "🔧 Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert"
    echo "🎯 Scopes: ui, core, permissions, window, click, hotkeys, build, docs"
    echo ""
    echo "✅ Examples:"
    echo "   feat(ui): add dark mode toggle"
    echo "   fix(permissions): resolve detection bug"
    echo "   docs: update installation guide"
    echo ""
    echo "💡 Use 'git commit' (without -m) to see the template"
    exit 1
fi
EOF

chmod +x .git/hooks/commit-msg

# Set up helpful git aliases
echo "⚡ Setting up helpful Git aliases..."
git config alias.cm "commit -m"
git config alias.co "checkout"
git config alias.br "branch"
git config alias.st "status"
git config alias.unstage "reset HEAD --"
git config alias.last "log -1 HEAD"
git config alias.visual "!gitk"
git config alias.pushup "push -u origin"
git config alias.release-beta "!f() { git tag beta-v\$1-\$(date +%Y%m%d) && git push origin --tags; }; f"
git config alias.release-prod "!f() { git tag v\$1 && git push origin --tags; }; f"

echo "✅ Git hooks and configuration complete!"
echo ""
echo "📋 What was configured:"
echo "   ✅ Commit message template (.gitmessage)"
echo "   ✅ Pre-commit hook (SwiftLint + build test)"
echo "   ✅ Commit message validation (conventional commits)"
echo "   ✅ Helpful Git aliases"
echo ""
echo "🚀 Usage:"
echo "   git commit              # Use template"
echo "   git cm \"feat: add feature\" # Quick commit"
echo "   git release-beta 1.0.0  # Create beta tag"
echo "   git release-prod 1.0.0  # Create production tag"