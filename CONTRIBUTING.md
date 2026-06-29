# Contributing to LLMWork

Thank you for your interest in contributing to LLMWork! This document provides guidelines and information for contributors.

## How to Contribute

### Reporting Bugs

1. Check existing issues to avoid duplicates
2. Create a new issue with:
   - Clear title describing the problem
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (OS, Flutter version, etc.)

### Suggesting Features

1. Open an issue with the "feature request" label
2. Describe the feature and its use case
3. Explain why it would be valuable

### Submitting Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests if applicable
5. Update documentation if needed
6. Commit with clear messages (`git commit -m 'Add amazing feature'`)
7. Push to your branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## Development Setup

```bash
# Clone your fork
git clone https://github.com/your-username/llmwork.git

# Install dependencies
flutter pub get

# Run in development mode
flutter run -d <device>
```

## Code Style

- Follow Dart style guide
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions focused and concise

## Testing

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/path/to/test.dart
```

## License

By contributing, you agree that your contributions will be licensed under the GNU General Public License v3.0.

## Questions?

Feel free to open an issue for any questions about contributing!
