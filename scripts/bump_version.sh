#!/bin/bash

# Version bump script for local development
# Usage: ./scripts/bump_version.sh [major|minor|patch]

set -e

VERSION_TYPE=${1:-patch}

# Validate version type
if [[ ! "$VERSION_TYPE" =~ ^(major|minor|patch)$ ]]; then
    echo "Error: Invalid version type. Use 'major', 'minor', or 'patch'"
    exit 1
fi

# Get current version from pubspec.yaml
CURRENT_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | cut -d'+' -f1)
echo "Current version: $CURRENT_VERSION"

# Split version into components
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Bump version based on type
case $VERSION_TYPE in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
echo "New version: $NEW_VERSION"

# Get current build number
CURRENT_BUILD=$(grep "^version:" pubspec.yaml | sed 's/version: //' | cut -d'+' -f2)
NEW_BUILD=$((CURRENT_BUILD + 1))

# Update pubspec.yaml
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/^version: .*/version: ${NEW_VERSION}+${NEW_BUILD}/" pubspec.yaml
else
    # Linux
    sed -i "s/^version: .*/version: ${NEW_VERSION}+${NEW_BUILD}/" pubspec.yaml
fi

echo "Updated pubspec.yaml to version ${NEW_VERSION}+${NEW_BUILD}"

# Update CHANGELOG.md
DATE=$(date +%Y-%m-%d)
TEMP_FILE=$(mktemp)

# Create new changelog entry
cat > "$TEMP_FILE" << EOF

## [${NEW_VERSION}] - ${DATE}

### Added
- 

### Changed
- 

### Fixed
- 

EOF

# Insert after "## [Unreleased]" line
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "/## \[Unreleased\]/r $TEMP_FILE" CHANGELOG.md
else
    # Linux
    sed -i "/## \[Unreleased\]/r $TEMP_FILE" CHANGELOG.md
fi

rm "$TEMP_FILE"

echo "Updated CHANGELOG.md with new version entry"
echo ""
echo "Next steps:"
echo "1. Edit CHANGELOG.md to add your changes"
echo "2. Commit the changes: git add pubspec.yaml CHANGELOG.md && git commit -m 'chore: bump version to ${NEW_VERSION}'"
echo "3. Create a PR with label '${VERSION_TYPE}' to trigger the release workflow"
