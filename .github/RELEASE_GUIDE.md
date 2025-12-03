# Release Guide

Quick reference for creating releases using the automated CI/CD pipeline.

## Automated Release Process

### Step 1: Create Feature Branch

```bash
git checkout main
git pull origin main
git checkout -b feature/my-feature
```

### Step 2: Make Changes

- Implement your feature
- Add tests
- Update documentation

### Step 3: Test Locally

```bash
# Run all tests
flutter test

# Check formatting
dart format .

# Analyze code
flutter analyze

# Test builds
flutter build apk --release
flutter build ios --release --no-codesign
```

### Step 4: Update CHANGELOG

Add your changes to the `[Unreleased]` section in `CHANGELOG.md`:

```markdown
## [Unreleased]

### Added
- Your new feature description

### Changed
- Any modifications to existing features

### Fixed
- Bug fixes
```

### Step 5: Commit and Push

```bash
git add .
git commit -m "feat: add my new feature"
git push origin feature/my-feature
```

### Step 6: Create Pull Request

1. Go to GitHub and create a PR from your branch to `main`
2. **Add the appropriate label:**
   - `major` or `breaking` - Breaking changes (1.0.0 → 2.0.0)
   - `feature`, `minor`, or `enhancement` - New features (1.0.0 → 1.1.0)
   - `patch` or no label - Bug fixes (1.0.0 → 1.0.1)
3. Fill out the PR template
4. Wait for CI checks to pass

### Step 7: Merge PR

Once approved and all checks pass:
1. Merge the PR to `main`
2. The build and release workflow will automatically:
   - Determine the new version based on the label
   - Build Android APK and AAB
   - Build iOS IPA
   - Create a GitHub release
   - Attach all binaries
   - Update CHANGELOG.md

### Step 8: Verify Release

1. Go to the [Releases page](https://github.com/yourusername/ip-camera-streaming/releases)
2. Verify the new release is created
3. Download and test the binaries

## Manual Release (Emergency)

If the automated workflow fails, you can create a release manually:

### 1. Bump Version

```bash
./scripts/bump_version.sh [major|minor|patch]
```

### 2. Update CHANGELOG

Edit `CHANGELOG.md` to add your changes under a new version heading.

### 3. Commit Changes

```bash
git add pubspec.yaml CHANGELOG.md
git commit -m "chore: bump version to X.Y.Z"
git push origin main
```

### 4. Create Tag

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

### 5. Build Binaries

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release --no-codesign
cd build/ios/iphoneos
mkdir -p Payload
cp -r Runner.app Payload/
zip -r IPCameraStreaming.ipa Payload
```

### 6. Create GitHub Release

1. Go to [Releases](https://github.com/yourusername/ip-camera-streaming/releases)
2. Click "Draft a new release"
3. Select the tag you created
4. Add release notes
5. Attach the binaries:
   - `build/app/outputs/flutter-apk/app-release.apk`
   - `build/app/outputs/bundle/release/app-release.aab`
   - `build/ios/iphoneos/IPCameraStreaming.ipa`
6. Publish release

## Version Numbering

Format: `MAJOR.MINOR.PATCH+BUILD`

- **MAJOR**: Incompatible API changes
- **MINOR**: New functionality, backward compatible
- **PATCH**: Bug fixes, backward compatible
- **BUILD**: Auto-incremented build number

Examples:
- `1.0.0+1` - Initial release
- `1.1.0+2` - Added new feature
- `1.1.1+3` - Fixed bug
- `2.0.0+4` - Breaking change

## PR Labels Reference

| Label | Version Bump | Use Case |
|-------|--------------|----------|
| `major`, `breaking` | 1.0.0 → 2.0.0 | Breaking API changes, major rewrites |
| `feature`, `minor`, `enhancement` | 1.0.0 → 1.1.0 | New features, enhancements |
| `patch`, `bugfix`, none | 1.0.0 → 1.0.1 | Bug fixes, minor improvements |

## Troubleshooting

### Tests Failing in CI

**Problem:** Your PR shows failing tests

**Solution:**
```bash
# Run tests locally
flutter test

# Check specific test
flutter test test/path/to/test.dart

# Fix issues and push again
git add .
git commit -m "fix: resolve test failures"
git push
```

### Build Failing After Merge

**Problem:** Build workflow fails after merging to main

**Solution:**
1. Check the [Actions tab](https://github.com/yourusername/ip-camera-streaming/actions)
2. Review the error logs
3. If it's a transient error, re-run the workflow
4. If it's a code issue, create a hotfix PR

### Release Not Created

**Problem:** PR merged but no release appears

**Solution:**
1. Verify the PR was merged (not just closed)
2. Check that the PR had a label
3. Review the workflow logs in Actions tab
4. If needed, create a manual release (see above)

### Wrong Version Number

**Problem:** Release created with incorrect version

**Solution:**
1. Delete the incorrect release and tag from GitHub
2. Delete the local tag: `git tag -d vX.Y.Z`
3. Delete the remote tag: `git push origin :refs/tags/vX.Y.Z`
4. Create a new PR with the correct label

## Best Practices

1. **Always test locally** before pushing
2. **Use descriptive commit messages** following conventional commits
3. **Add appropriate labels** to PRs immediately
4. **Update documentation** in the same PR as code changes
5. **Keep PRs focused** - one feature or fix per PR
6. **Review the release** after it's created to ensure quality

## Questions?

- Check [docs/CI_CD_WORKFLOW.md](../docs/CI_CD_WORKFLOW.md) for detailed documentation
- Review [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines
- Open an issue if you encounter problems
