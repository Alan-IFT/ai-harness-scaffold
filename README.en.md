<div align="center">

# ai-harness

**A verifiable delivery process for AI coding tools that survives switching tools and sessions.**

[![selftest](https://github.com/Alan-IFT/ai-harness-scaffold/actions/workflows/selftest.yml/badge.svg)](https://github.com/Alan-IFT/ai-harness-scaffold/actions/workflows/selftest.yml)
[![Release](https://img.shields.io/github/v/release/Alan-IFT/ai-harness-scaffold)](https://github.com/Alan-IFT/ai-harness-scaffold/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
![Platform: Windows (Git Bash)](https://img.shields.io/badge/platform-Windows%20(Git%20Bash)-lightgrey)

[简体中文](README.md) | English

</div>

ai-harness is a development process you install into a project: rule documents, Bash gate scripts and process templates. A task pool collects requests, three gates (plan, verify, review) control delivery, and files in Git carry the work from one tool or session to the next. It has no server and no runtime dependencies.

**The rules, templates and gate messages are all in Chinese.** There is no English version, so your AI tool will read and produce Chinese process documents unless you tell it otherwise. The gate scripts also match Chinese field names in those documents. This page is a summary; [README.md](README.md) has the full details, in Chinese.

## Getting started

Requirements:

- Windows with Git Bash. macOS and Linux are not supported.
- Git and access to GitHub.
- An AI tool that can read `AGENTS.md` and run bash. Tested with Claude Code and Codex.

In your project, send this to your AI tool. The same sentence covers new projects, existing projects and upgrades:

```
Make a full clone of https://github.com/Alan-IFT/ai-harness-scaffold.git in a temporary directory and follow its skill/SKILL.md to install the ai-harness scaffold into the current project, or upgrade it to the latest version if it is already installed.
```

There is no install command. The AI works out which case applies, installs the latest tag and checks the result. Projects installed from v2.1.3 onward can upgrade later with just "upgrade the scaffold to the latest version".

## How it works

You state requests in plain language and the AI runs the process. Each request becomes a Spec that passes three gates before it is archived:

```mermaid
flowchart TD
    A["Request in plain language"] --> B["Task pool: keeps the original wording"]
    B --> C["Spec: requirements, acceptance criteria, plan"]
    C --> G1{"g1 plan"}
    G1 -- fail --> C
    G1 -- pass --> D["Code one task at a time"]
    D --> V["ai-verify.sh: formal verification"]
    V --> G2{"g2 verify"}
    G2 -- fail --> D
    G2 -- pass --> R["Review in a separate context"]
    R --> G3{"g3 review"}
    G3 -- critical issues --> D
    G3 -- pass --> E["Archive and take the next task"]
```

- **g1 plan**: the original request, acceptance criteria and plan are filled in, and no open questions remain.
- **g2 verify**: all tasks are done and the configured check passed against the current code. Any code change afterwards invalidates the result.
- **g3 review**: a context that did not write the code reports zero critical issues. Requests that touch data, permissions, releases or architecture also need a person's decision.

To switch tools, have the new one run `bash scripts/ai-resume.sh owner`. It summarizes gate status, the current Spec's progress and uncommitted changes.

## Architecture

The scaffold does not keep running. The AI installs the template into your project, and every AI tool then reads the same rules and runs the same scripts:

```mermaid
flowchart TB
    subgraph SC["Scaffold repository"]
        SK["skill/SKILL.md<br/>install instructions"]
        T["template/<br/>everything that gets installed"]
    end

    H["AI tool<br/>Claude Code, Codex and others"]

    subgraph P["Your project"]
        L1["Rules<br/>AGENTS.md, .agents/skills/"]
        L2["Mechanism<br/>scripts/"]
        L3["Configuration<br/>harness/"]
        L4["State<br/>process/, MEMORY.md, docs/architecture/, Git"]
    end

    SK -- guides install and upgrade --> H
    T -- read by version --> H
    H -- reads --> L1
    H -- runs --> L2
    H -- reads and writes --> L4
    L2 -- reads limits and check command --> L3
    L2 -- checks and advances --> L4
```

## Before you use it

- The gates run locally. They catch mistakes but are not a security boundary.
- `ai-verify.sh` runs the `CUSTOM_CHECK` command from `harness/verify.conf`. Read that file before running the scripts on a project you don't trust.

## Feedback and license

Open an [Issue](https://github.com/Alan-IFT/ai-harness-scaffold/issues) for bugs and ideas. Discuss in an Issue before sending a pull request. Report security problems through [private vulnerability reporting](https://github.com/Alan-IFT/ai-harness-scaffold/security/advisories/new).

[MIT](LICENSE).
