# Homebrew Tap Setup Guide

This guide covers everything you need to do manually before the automated workflow can take over.

---

## Overview

Once set up, every production release will automatically:
1. Compute the SHA256 of the released DMG
2. Update the cask formula in your tap repo with the new version + hash
3. Push the change — making `brew upgrade --cask clickit` work for all users

Homebrew users will also never see the Gatekeeper "damaged" warning because the cask runs `xattr -cr` automatically post-install.

---

## Step 1 — Create the Tap Repository

1. Go to **github.com/jsonify** and create a new repository
2. Name it exactly: **`homebrew-clickit`**
   - This naming convention is required by Homebrew (`brew tap jsonify/clickit` maps to `github.com/jsonify/homebrew-clickit`)
3. Set it to **Public**
4. Initialize it with a README (just check the box — content doesn't matter)

---

## Step 2 — Create the Cask Formula File

Inside the `homebrew-clickit` repo, create the following directory and file:

**Path:** `Casks/clickit.rb`

```ruby
cask "clickit" do
  version "1.6.3"
  sha256 "PLACEHOLDER_WILL_BE_SET_BY_CI"

  url "https://github.com/jsonify/ClickIt/releases/download/v#{version}/ClickIt-#{version}.dmg"
  name "ClickIt"
  desc "Native macOS auto-clicker with precision timing and window targeting"
  homepage "https://github.com/jsonify/ClickIt"

  app "ClickIt.app"

  postinstall do
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/ClickIt.app"]
  end

  uninstall quit: "com.jsonify.clickit"

  zap trash: [
    "~/Library/Application Support/ClickIt",
    "~/Library/Preferences/com.jsonify.clickit.plist",
  ]
end
```

> **Note:** The `sha256` and `version` fields will be overwritten automatically by CI on every release. The placeholder value above is just so the file is valid on first commit.

---

## Step 3 — Create a Personal Access Token (PAT)

The CI workflow needs permission to push to `homebrew-clickit` from the `ClickIt` repo.

1. Go to **github.com → Settings → Developer settings → Personal access tokens → Tokens (classic)**
2. Click **Generate new token (classic)**
3. Name it: `ClickIt Homebrew Tap`
4. Set expiration to **No expiration** (or 1 year — just remember to rotate it)
5. Under **Select scopes**, check only: ✅ **`repo`** (full control of private repositories)
6. Click **Generate token**
7. **Copy the token immediately** — you won't be able to see it again

---

## Step 4 — Add the Token as a Secret in ClickIt's Repo

1. Go to **github.com/jsonify/ClickIt → Settings → Secrets and variables → Actions**
2. Click **New repository secret**
3. Name: `HOMEBREW_TAP_TOKEN`
4. Value: paste the PAT from Step 3
5. Click **Add secret**

---

## Step 5 — Tell Claude to Wire Up the Workflow

Once Steps 1–4 are done, come back and say **"the tap repo and token are ready"** and the CI workflow (`cicd.yml`) will be updated to automatically push cask updates on every production release.

The workflow step will:
- Download the released DMG
- Compute its `sha256`
- Clone `homebrew-clickit`
- Update `version` and `sha256` in `Casks/clickit.rb`
- Commit and push using the `HOMEBREW_TAP_TOKEN`

---

## What Users Will Do

### First-time install
```bash
brew tap jsonify/clickit
brew install --cask clickit
```

### Update after a new release
```bash
brew upgrade --cask clickit
```

No Gatekeeper warning. No `xattr` command needed. It just works.

---

## Verification (after first automated release)

Check that the tap updated correctly:
```bash
brew tap jsonify/clickit
brew info --cask clickit
```

You should see the latest version number. If the cask file in the repo shows the right `sha256` and `version`, everything is wired up correctly.
