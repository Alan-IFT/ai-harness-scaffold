# ai-harness

[中文](README.md)

A host-agnostic development process for AI coding tools. A task pool collects requests, three gates (plan, verify, review) control delivery, and files in Git carry the work from one tool or session to the next.

**The rules, templates and gate messages are all in Chinese.** There is no English version, so your AI tool will read and produce Chinese process documents unless you tell it otherwise. The gate scripts also match Chinese field names in those documents.

## Requirements

- Windows with Git Bash. macOS and Linux are not supported.
- Git and access to GitHub.
- An AI tool that can read `AGENTS.md` and run bash. Tested with Claude Code and Codex.

## Getting started

In your project, send this to your AI tool. The same sentence covers new projects, existing projects and upgrades:

```
Make a full clone of https://github.com/Alan-IFT/ai-harness-scaffold.git in a temporary directory and follow its skill/SKILL.md to install the ai-harness scaffold into the current project, or upgrade it to the latest version if it is already installed.
```

There is no install command. The AI works out which case applies, installs the latest tag and checks the result. Projects installed from v2.1.3 onward can upgrade later with just "upgrade the scaffold to the latest version".

## Before you use it

- The gates run locally. They catch mistakes but are not a security boundary.
- `ai-verify.sh` runs the `CUSTOM_CHECK` command from `harness/verify.conf`. Read that file before running the scripts on a project you don't trust.

## Feedback and license

Open an [Issue](https://github.com/Alan-IFT/ai-harness-scaffold/issues) for bugs and ideas. Discuss in an Issue before sending a pull request. Report security problems through [private vulnerability reporting](https://github.com/Alan-IFT/ai-harness-scaffold/security/advisories/new).

[MIT](LICENSE). See [README.md](README.md) for full details, in Chinese.
