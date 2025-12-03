# CI/CD Workflow Documentation

## Overview

This project uses GitHub Actions with a simple two-workflow approach:

1. **Test** - Runs on all pushes and PRs (validates code)
2. **Build** - Runs after merge to main (creates binaries)

## Workflows

### Test Workflow (`test.yml`)

**Trigger:** All pushes and pull requests to any branch

**Purpose:** Validate code quality before merging

**Steps:**
1. Checkout code
2. Set up Flutter
3. Get dependencies (`flutter pub get`)
4. Analyze code (`flutter analyze --no-fatal-infos`)
5. Run tests (`flutter test`)

### Build Workflow (`build.yml`)

**Trigger:** Pushes to `main` branch only

**Purpose:** Build release binaries after code is merged (for testing)

**Jobs:**
- Build Android APK and App Bundle
- Build iOS IPA (unsigned)
- Upload as workflow artifacts

### Release Workflow (`release.yml`)

**Trigger:** When a version tag is pushed (e.g., `v1.0.0`)

**Purpose:** Create GitHub release with downloadable binaries

**Jobs:**
- Build Android APK and App Bundle
- Build iOS IPA (unsigned)
- Create GitHub Release with all binaries attached

## Artifacts

After a successful build on main, download artifacts from the GitHub Actions run:

- **android-apk**: `app-release.apk`
- **android-bundle**: `app-release.aab`
- **ios-ipa**: `app-release.ipa`

## Branch Protection

The `main` branch is protected:
- Requires pull request before merging
- Requires 1 approval
- Dismisses stale reviews on new commits

## Development Workflow

1. Create a feature branch
2. Make changes and push
3. Test workflow runs automatically
4. Create PR to main
5. Get approval and merge
6. Build workflow creates artifacts

## Creating a Release

```bash
# 1. Update version in pubspec.yaml
make version-patch  # or version-minor, version-major

# 2. Commit the version change
git add pubspec.yaml CHANGELOG.md
git commit -m "chore: bump version to X.Y.Z"

# 3. Create and push tag
git tag vX.Y.Z
git push origin main --tags
```

The release workflow will automatically:
- Build Android APK and App Bundle
- Build iOS IPA
- Create GitHub Release with all binaries

## Local Testing

Test workflows locally with act:

```bash
# List workflows
make act-list

# Test the test workflow
make act-test
```

## Troubleshooting

### Tests Failing

```bash
# Run locally
flutter analyze --no-fatal-infos
flutter test
```

### Build Failing

```bash
# Test build locally
flutter build apk --release
flutter build ios --release --no-codesign
```
