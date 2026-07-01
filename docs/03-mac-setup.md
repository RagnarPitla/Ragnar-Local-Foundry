# Mac Setup

[Back to repo README](../README.md) | Previous: [Architecture](02-architecture.md) | Next: [Model catalog](04-model-catalog.md)

This is the practical path to run Azure AI Foundry Local on an Apple Silicon Mac.

## Prerequisites

| Requirement | Why it matters |
| --- | --- |
| macOS on Apple Silicon | Foundry Local supports macOS on Apple Silicon only. |
| Admin rights | Installation requires admin rights. |
| Homebrew | Primary macOS install path. |
| Xcode Command Line Tools | Common prerequisite for developer tooling. |
| Node.js 20+ | Required for JavaScript samples and SDK use. |
| Python 3.11+ | Required for Python samples and SDK use. |
| Free disk space | Models are cached locally. See [Model catalog](04-model-catalog.md). |
| Unified memory | Guides model choice. Start smaller on 8 GB machines. |

Install Xcode Command Line Tools if needed:

```bash
xcode-select --install
```

## Install Foundry Local with Homebrew

```bash
brew tap microsoft/foundrylocal
brew install foundrylocal
```

Alternate installer:

```text
https://aka.ms/foundry-local-installer
```

Verify the install:

```bash
foundry --version
```

If verification reports `Request to local service failed`, restart the local service:

```bash
foundry service restart
```

## First model run

Start with the smallest confirmed alias:

```bash
foundry model run qwen2.5-0.5b
```

The first run downloads the model, then opens an interactive chat prompt. Later runs use the cached model.

## Start and inspect the local service

Start the service:

```bash
foundry service start
```

Check status and discover the dynamic local endpoint:

```bash
foundry service status
```

The endpoint is local and dynamic, so do not hard-code a port. Use `foundry service status`, the SDK manager, or this repo's helper targets.

## Check the model cache

Find the cache location:

```bash
foundry cache location
```

List cached models:

```bash
foundry cache list
```

Remove a model when you need disk space:

```bash
foundry cache remove <model>
```

## Use this repo's scripts

The `scripts/` directory wraps the common tasks:

| Script | Purpose |
| --- | --- |
| `scripts/install-mac.sh` | Install Foundry Local on macOS. |
| `scripts/list-models.sh` | List models available to this machine. |
| `scripts/download-models.sh` | Download profile models from `config/models.json`. |
| `scripts/run-model.sh` | Run a selected model alias. |
| `scripts/serve.sh` | Start or inspect the local service. |
| `scripts/health-check.sh` | Validate the local setup. |
| `scripts/uninstall-mac.sh` | Remove the local install workflow artifacts. |

## Use the Makefile

The root `Makefile` gives a single command surface:

```bash
make help
make install
make models PROFILE=starter
make model-list
make run MODEL=qwen2.5-0.5b
make serve
make health
make chat
make chat-openai
make py-chat
make demo
make clean
make uninstall
```

Profiles are `starter`, `balanced`, and `power`. The default profile is `starter`.

## Quick troubleshooting

> If you see a service connection error, run `foundry service restart`. If a model alias is missing, run `foundry model list` because the catalog is dynamic and hardware-aware. For more fixes, see [Troubleshooting](08-troubleshooting.md).
