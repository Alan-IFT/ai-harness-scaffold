# ai-harness

[中文](README.md)

A host-agnostic development process for AI coding tools. A task pool collects requests, three gates (plan, verify, review) control delivery, and files in Git carry the work from one tool or session to the next.

**The rules, templates and gate messages are all in Chinese.** There is no English version, so your AI tool will read and produce Chinese process documents unless you tell it otherwise. The gate scripts also match Chinese field names in those documents.

## Requirements

- Windows with Git Bash. macOS and Linux are not supported.
- Git.
- An AI tool that can read `AGENTS.md` and run bash. Tested with Claude Code and Codex.

## Getting started

```bash
git clone https://github.com/Alan-IFT/ai-harness-scaffold.git
```

Use `git clone`, because installing and upgrading rely on Git tags and history. A ZIP download will not work.

There is no install command. Give your AI tool the path to the clone and ask it to follow `skill/SKILL.md`, for example: "Install the ai-harness scaffold into `D:\code\my-project` using `skill/SKILL.md`." It installs the latest tag and checks the result.

## Before you use it

- The gates run locally. They catch mistakes but are not a security boundary.
- `ai-verify.sh` runs the `CUSTOM_CHECK` command from `harness/verify.conf`. Read that file before running the scripts on a project you don't trust.

## Feedback and license

Open an [Issue](https://github.com/Alan-IFT/ai-harness-scaffold/issues) for bugs and ideas. Discuss in an Issue before sending a pull request. Report security problems through [private vulnerability reporting](https://github.com/Alan-IFT/ai-harness-scaffold/security/advisories/new).

[MIT](LICENSE). See [README.md](README.md) for full details, in Chinese.
