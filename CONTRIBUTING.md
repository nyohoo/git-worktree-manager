# Contributing to Git Worktree Manager

Thank you for your interest in contributing! 🎉

## Development Setup

1. **Fork and clone the repository**

```bash
git clone https://github.com/YOUR_USERNAME/git-worktree-manager.git
cd git-worktree-manager
```

2. **Install development dependencies**

```bash
# Install shellcheck for linting
brew install shellcheck  # macOS
# or
apt-get install shellcheck  # Ubuntu/Debian
```

3. **Test your changes**

```bash
# Run shellcheck
shellcheck gwm.zsh install.sh uninstall.sh

# Manual testing
source gwm.zsh
zclaude help
```

## Contribution Guidelines

### Reporting Bugs

When reporting bugs, please include:

- **Environment**: OS, shell version (`zsh --version`)
- **Steps to reproduce**: Exact commands that trigger the bug
- **Expected vs actual behavior**
- **Error messages**: Full output if applicable

### Suggesting Enhancements

- Check if the feature is already requested in Issues
- Describe the use case and why it's useful
- Provide examples of how the feature would work

### Pull Requests

1. **Create a feature branch**

```bash
git checkout -b feature/your-feature-name
```

2. **Make your changes**

- Follow the existing code style
- Add comments for complex logic
- Update documentation if needed

3. **Test thoroughly**

- Test on a clean environment
- Test edge cases
- Ensure backward compatibility

4. **Commit your changes**

```bash
git commit -m "feat: add support for custom branch naming"
```

Use conventional commit messages:
- `feat:` new features
- `fix:` bug fixes
- `docs:` documentation changes
- `refactor:` code refactoring
- `test:` test additions/changes
- `chore:` maintenance tasks

5. **Push and create a PR**

```bash
git push origin feature/your-feature-name
```

Then create a pull request on GitHub with:
- Clear description of changes
- Reference to related issues (if any)
- Screenshots/examples (if applicable)

## Code Style

### Shell Script Best Practices

- Use `#!/usr/bin/env zsh` for zsh scripts
- Use `#!/usr/bin/env bash` for bash scripts
- Quote variables: `"$variable"` not `$variable`
- Use `[[ ]]` instead of `[ ]` for conditionals
- Check command existence: `command -v <cmd> >/dev/null 2>&1`
- Handle errors with `set -e` or explicit checks

### Function Naming

- Internal functions: `_prefix_function_name()`
- User-facing commands: `commandname()`
- Use descriptive names

### Comments

- Add comments for non-obvious logic
- Use section headers:
  ```bash
  # ============================================================================
  # Section Name
  # ============================================================================
  ```

## Documentation

- Update `README.md` for user-facing changes
- Update `worktree-commands-README.md` for detailed usage
- Add examples for new features
- Keep language simple and clear

## Testing

Currently manual testing is required. Future improvements:

- [ ] Automated tests with bats-core
- [ ] CI/CD with GitHub Actions
- [ ] Integration tests

## Questions?

Feel free to open an issue for:
- Questions about contributing
- Architecture discussions
- Feature brainstorming

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
