# Contributing to PeerAdsSDK

Thank you for your interest in contributing! This document covers everything you need to get started.

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating you agree to uphold it.

## Reporting Bugs

Before opening an issue, search [existing issues](https://github.com/peerads/peerads-ios/issues) to avoid duplicates. When filing a bug report please include:

- SDK version (from `Package.resolved`)
- Xcode version and iOS deployment target
- Device / simulator OS version
- Minimal reproduction steps
- Expected vs actual behaviour
- Xcode console output or crash symbolication

## Suggesting Features

Open a [GitHub Discussion](https://github.com/peerads/peerads-ios/discussions) before filing a feature request.

## Development Setup

```bash
git clone https://github.com/peerads/peerads-ios.git
cd peerads-ios

# Open in Xcode
open Package.swift

# Run tests from command line
swift test
```

## Pull Request Guidelines

1. **Branch** — create a feature branch from `main`: `git checkout -b feat/your-feature`
2. **Small PRs** — one logical change per PR
3. **Tests** — add or update tests in `Tests/PeerAdsSDKTests/`
4. **Swift style** — follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/); run `swift-format` before committing
5. **Documentation** — all public APIs require DocC comments
6. **Commit style** — follow [Conventional Commits](https://www.conventionalcommits.org/)
7. **Changelog** — add an entry to `CHANGELOG.md` under `[Unreleased]`

## Security

Do **not** open a public issue for security vulnerabilities. See [SECURITY.md](SECURITY.md).

## License

By contributing you agree that your contributions will be licensed under the [MIT License](LICENSE).
