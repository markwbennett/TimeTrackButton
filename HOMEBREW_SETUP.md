# Homebrew Distribution Setup

This guide explains how to make IACLS Time Tracker available via Homebrew.

## Option 1: Personal Tap (Easiest)

Create your own Homebrew tap to distribute the app:

### 1. Create a Homebrew Tap Repository

```bash
# Create a new repository named homebrew-tap
# Repository must be named: homebrew-<tapname>
# For example: homebrew-iacls or homebrew-timetracker
```

### 2. Add the Cask Formula

Copy the `iacls-time-tracker.rb` file to your tap repository in a `Casks/` directory:

```
homebrew-iacls/
└── Casks/
    └── iacls-time-tracker.rb
```

### 3. Users Install From Your Tap

Users can then install with:

```bash
# Add your tap
brew tap markwbennett/iacls

# Install the app
brew install --cask iacls-time-tracker
```

## Option 2: Submit to Official Homebrew Cask

To get into the main Homebrew repository:

### 1. Create a GitHub Release

First, create a proper release with a versioned archive:

1. Go to your GitHub repository
2. Click "Releases" → "Create a new release"
3. Tag version: `v1.0.0`
4. Release title: `IACLS Time Tracker v1.0.0`
5. Upload a `.zip` or `.tar.gz` of your app

### 2. Update the Formula

Update `iacls-time-tracker.rb` to point to the release:

```ruby
url "https://github.com/markwbennett/TimeTrackButton/releases/download/v1.0.0/iacls-time-tracker-1.0.0.zip"
sha256 "actual-sha256-hash-of-the-zip-file"
```

### 3. Submit Pull Request

1. Fork the [homebrew-cask](https://github.com/Homebrew/homebrew-cask) repository
2. Add your formula to `Casks/i/iacls-time-tracker.rb`
3. Submit a pull request

## Recommended Approach

**Start with Option 1 (Personal Tap)** because:

- ✅ You have full control
- ✅ Faster to set up
- ✅ No approval process
- ✅ Can iterate quickly

**Later consider Option 2** when:

- ✅ App is stable and well-tested
- ✅ Has good documentation
- ✅ Follows all Homebrew guidelines
- ✅ Has significant user base

## Testing Your Formula

Before publishing, test the formula locally:

```bash
# Install from local file
brew install --cask ./iacls-time-tracker.rb

# Test uninstall
brew uninstall --cask iacls-time-tracker

# Test reinstall
brew install --cask iacls-time-tracker
```

## Formula Requirements

For official Homebrew submission, ensure:

- [ ] App is notarized (for macOS security)
- [ ] Proper version numbering
- [ ] SHA256 checksums for all downloads
- [ ] No network access during installation
- [ ] Follows Homebrew style guidelines
- [ ] Includes proper license information

## Next Steps

1. **Create your tap repository**: `homebrew-iacls`
2. **Copy the formula**: Move `iacls-time-tracker.rb` to `Casks/`
3. **Test locally**: Verify installation works
4. **Document usage**: Update your main README
5. **Announce**: Let users know about Homebrew availability 