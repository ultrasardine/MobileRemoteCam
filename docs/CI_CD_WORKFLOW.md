# CI/CD Workflow Documentation

## Overview

This project uses GitHub Actions for continuous integration and continuous deployment. The workflow is designed to:

1. **Test** all code changes on non-main branches
2. **Build** iOS and Android binaries when PRs are merged to main
3. **Release** with semantic versioning automatically

## Workflows

### 1. Test Workflow (`test.yml`)

**Trigger:** Pushes and PRs to any branch except `main`

**Purpose:** Validate code quality and functionality before merging

**Jobs:**

#### Flutter Tests
- Runs on Ubuntu
- Checks code formatting with `dart format`
- Analyzes code with `flutter analyze`
- Runs all Flutter unit tests with coverage
- Uploads coverage to Codecov

#### Android Tests
- Runs on Ubuntu
- Executes Android lint checks
- Runs Android-specific unit tests
- Uploads test results as artifacts

#### iOS Tests
- Runs on macOS
- Validates iOS build configuration
- Runs iOS unit tests via Xcode
- Uploads test results as artifacts

### 2. Build and Release Workflow (`build-and-release.yml`)

**Trigger:** When a PR is merged to `main`

**Purpose:** Build production binaries and create GitHub releases

**Jobs:**

#### 1. Check Merge
- Verifies the PR was actually merged (not just closed)

#### 2. Determine Version
- Analyzes PR labels to determine version bump type:
  - `breaking` or `major` label → Major version bump (1.0.0 → 2.0.0)
  - `feature`, `minor`, or `enhancement` label → Minor version bump (1.0.0 → 1.1.0)
  - No label or `patch` label → Patch version bump (1.0.0 → 1.0.1)
- Outputs the new semantic version

#### 3. Build Android
- Builds release APK for direct installation
- Builds App Bundle (AAB) for Google Play Store
- Updates version in `pubspec.yaml`
- Uploads artifacts

#### 4. Build iOS
- Builds iOS release binary (unsigned)
- Creates IPA archive
- Updates version in `pubspec.yaml`
- Uploads artifacts

#### 5. Create Release
- Downloads all build artifacts
- Generates release notes from PR information
- Creates GitHub release with semantic version tag
- Attaches APK, AAB, and IPA files
- Updates CHANGELOG.md automatically
- Commits changelog updates

## Semantic Versioning

This project follows [Semantic Versioning 2.0.0](https://semver.org/):

**Format:** `MAJOR.MINOR.PATCH+BUILD`

- **MAJOR:** Breaking changes or major new features
- **MINOR:** New features, backward compatible
- **PATCH:** Bug fixes, backward compatible
- **BUILD:** Build number (auto-incremented)

### Version Bump Rules

| PR Label | Version Change | Example |
|----------|---------------|---------|
| `breaking`, `major` | Major bump | 1.2.3 → 2.0.0 |
| `feature`, `minor`, `enhancement` | Minor bump | 1.2.3 → 1.3.0 |
| None, `patch`, `bugfix` | Patch bump | 1.2.3 → 1.2.4 |

## Usage Guide

### For Feature Development

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/my-new-feature
   ```

2. **Make your changes and commit:**
   ```bash
   git add .
   git commit -m "feat: add new streaming mode"
   ```

3. **Push and create PR:**
   ```bash
   git push origin feature/my-new-feature
   ```
   - The test workflow will run automatically
   - All tests must pass before merging

4. **Add appropriate label to PR:**
   - `major` - for breaking changes
   - `feature` or `minor` - for new features
   - `patch` or leave unlabeled - for bug fixes

5. **Merge PR to main:**
   - Once approved and tests pass, merge the PR
   - The build and release workflow will trigger automatically
   - A new release will be created with binaries

### Local Version Management

Use the provided script to bump versions locally:

```bash
# Bump patch version (0.0.1 → 0.0.2)
./scripts/bump_version.sh patch

# Bump minor version (0.0.1 → 0.1.0)
./scripts/bump_version.sh minor

# Bump major version (0.0.1 → 1.0.0)
./scripts/bump_version.sh major
```

The script will:
- Update `pubspec.yaml` with new version
- Add entry to `CHANGELOG.md`
- Provide next steps for committing

### Manual Release Process

If you need to create a release manually:

1. **Update version in pubspec.yaml:**
   ```yaml
   version: 1.2.3+10
   ```

2. **Update CHANGELOG.md:**
   ```markdown
   ## [1.2.3] - 2025-12-03
   
   ### Added
   - New feature description
   
   ### Fixed
   - Bug fix description
   ```

3. **Commit and tag:**
   ```bash
   git add pubspec.yaml CHANGELOG.md
   git commit -m "chore: bump version to 1.2.3"
   git tag v1.2.3
   git push origin main --tags
   ```

4. **Build manually:**
   ```bash
   # Android
   flutter build apk --release
   flutter build appbundle --release
   
   # iOS
   flutter build ios --release --no-codesign
   ```

## Artifacts

### Android Artifacts

- **APK** (`app-release.apk`): Direct installation file
  - Location: `build/app/outputs/flutter-apk/`
  - Use for: Testing, direct distribution

- **App Bundle** (`app-release.aab`): Google Play Store format
  - Location: `build/app/outputs/bundle/release/`
  - Use for: Google Play Store submission

### iOS Artifacts

- **IPA** (`IPCameraStreaming.ipa`): iOS application archive
  - Location: `build/ios/iphoneos/`
  - Note: Unsigned, requires signing before installation
  - Use for: TestFlight, App Store, or manual distribution

## Troubleshooting

### Tests Failing

**Problem:** Test workflow fails on your branch

**Solutions:**
- Run tests locally: `flutter test`
- Check formatting: `dart format .`
- Run analysis: `flutter analyze`
- Fix issues and push again

### Build Failing

**Problem:** Build workflow fails after merging

**Solutions:**
- Check build logs in GitHub Actions
- Verify dependencies in `pubspec.yaml`
- Test builds locally:
  ```bash
  flutter build apk --release
  flutter build ios --release --no-codesign
  ```

### Version Not Bumping

**Problem:** Release created with wrong version

**Solutions:**
- Ensure PR has correct label (`major`, `minor`, or `patch`)
- Check that PR was merged (not just closed)
- Verify latest tag exists: `git tag -l`

### Release Not Created

**Problem:** PR merged but no release appears

**Solutions:**
- Check GitHub Actions logs for errors
- Verify `GITHUB_TOKEN` has write permissions
- Ensure workflow file is on main branch
- Check if PR was actually merged vs closed

## Best Practices

1. **Always add labels to PRs** - This ensures correct version bumping
2. **Write descriptive PR descriptions** - They become release notes
3. **Keep CHANGELOG.md updated** - Add entries to Unreleased section
4. **Test locally before pushing** - Run `flutter test` and `flutter analyze`
5. **Use conventional commits** - Helps with changelog generation
6. **Review build artifacts** - Download and test APK/IPA before announcing releases

## Workflow Permissions

The workflows require these GitHub permissions:

- `contents: write` - For creating releases and pushing changelog updates
- `actions: read` - For accessing workflow artifacts
- `security-events: write` - For CodeQL analysis (existing)

These are configured in the workflow files and should work with default `GITHUB_TOKEN`.

## Future Enhancements

Potential improvements to consider:

- [ ] Automatic changelog generation from commit messages
- [ ] Code signing for iOS builds
- [ ] Automated Play Store and App Store deployment
- [ ] Performance benchmarking in CI
- [ ] Visual regression testing
- [ ] Automated security scanning
- [ ] Slack/Discord notifications for releases
- [ ] Beta/alpha release channels

## Related Documentation

- [BUILD_SYSTEM.md](BUILD_SYSTEM.md) - Build system details
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribution guidelines
- [CHANGELOG.md](../CHANGELOG.md) - Version history
- [ROADMAP.md](../ROADMAP.md) - Development timeline
