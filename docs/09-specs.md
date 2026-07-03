# Technical Specification and Build Plan

[Back to repo README](../README.md) | Previous: [Troubleshooting](08-troubleshooting.md)

This specification defines the build and run plan for `Ragnar-Local-Foundry`, a complete research and implementation guide for Azure AI Foundry Local on Mac Apple Silicon.

## Objectives

- Help a Mac user install Foundry Local correctly.
- Explain the local runtime, SDK, model catalog, CLI, cache, and optional REST server.
- Provide repeatable scripts and Makefile targets for install, model provisioning, serving, examples, health checks, cleanup, and uninstall.
- Document model selection for Apple Silicon unified memory tiers.
- Keep the integration path practical for JavaScript, Python, OpenAI-compatible REST, and LangChain.

## Scope

In scope:

- macOS on Apple Silicon.
- Foundry Local SDK-first local AI workflows.
- Optional OpenAI-compatible local server.
- CLI workflows for `model`, `service`, and `cache`.
- Curated model profiles from [`../config/models.json`](../config/models.json).
- Examples in `examples/js/chat.mjs`, `examples/js/openai-compat.mjs`, and `examples/python/chat.py`.

Out of scope:

- Windows and Linux setup instructions beyond reference context.
- Cloud inference deployment.
- Enterprise Kubernetes or Azure Arc operations.
- Claims of CoreML or Apple Neural Engine support.
- CUDA or NPU execution on Mac.

## Non-goals

- This repo is not a production model-serving platform.
- This repo does not replace the dynamic Foundry Local model catalog.
- This repo does not hard-code local service ports.
- This repo does not require Azure subscription credentials for local execution.

## System requirements matrix

| Area | Requirement | Notes |
| --- | --- | --- |
| Platform | macOS on Apple Silicon | This repo targets Mac Apple Silicon only. |
| Install rights | Admin rights | Required to install Foundry Local. |
| Package manager | Homebrew | Primary path: `brew tap microsoft/foundrylocal`, then `brew install foundrylocal`. |
| Developer tools | Xcode Command Line Tools | Install with `xcode-select --install` when needed. |
| JavaScript | Node.js 20+ | Required for JS SDK examples. |
| Python | Python 3.11+ | Required for Python SDK examples. |
| Memory, starter | 8 GB unified memory | Use `starter` profile. |
| Memory, balanced | 16 GB unified memory | Use `balanced` profile. |
| Memory, power | 32 GB+ unified memory | Use `power` profile. |
| Disk | Enough free space for cached models | See approximate sizes in [Model catalog](04-model-catalog.md). |

## Architecture summary

Foundry Local is a lightweight on-device runtime built on ONNX Runtime. Apps should prefer the SDK for lifecycle control. The optional OpenAI-compatible server is available for tools and frameworks that already speak OpenAI-style REST.

On Apple Silicon, the relevant execution providers are CPU through MLAS and WebGPU through Dawn to Metal. Foundry Local auto-detects hardware and falls back to CPU when needed.

See [Architecture](02-architecture.md) for diagrams and request flow.

## Install and build pipeline

| Phase | Repo command | Script | Foundry Local workflow |
| --- | --- | --- | --- |
| Discover commands | `make help` | Makefile | Print available targets. |
| Install | `make install` | `scripts/install-mac.sh` | Tap and install with Homebrew, then verify with `foundry --version`. |
| List models | `make model-list` | `scripts/list-models.sh` | Run `foundry model list`. |
| Provision models | `make models PROFILE=starter` | `scripts/download-models.sh` | Run `foundry model download <model>` for profile aliases. |
| Run one model | `make run MODEL=qwen2.5-0.5b` | `scripts/run-model.sh` | Run `foundry model run <model>`. |
| Serve | `make serve` | `scripts/serve.sh` | Start service and show `foundry service status`. |
| Health | `make health` | `scripts/health-check.sh` | Validate version, service, catalog, cache, and endpoint. |
| JS SDK chat | `make chat` | Example target | Run `examples/js/chat.mjs`. |
| OpenAI-compatible chat | `make chat-openai` | Example target | Run `examples/js/openai-compat.mjs`. |
| Python chat | `make py-chat` | Example target | Run `examples/python/chat.py`. |
| Demo | `make demo` | Makefile | Run the curated demo flow. |
| Clean | `make clean` | Makefile | Clean repo-local generated artifacts. |
| Uninstall | `make uninstall` | `scripts/uninstall-mac.sh` | Run the repo uninstall workflow. |

## Model provisioning plan

Profiles come from [`../config/models.json`](../config/models.json):

| Profile | Target Mac | Models |
| --- | --- | --- |
| `starter` | 8 GB+ | `qwen2.5-0.5b`, `qwen3-0.6b` |
| `balanced` | 16 GB+ | `phi-4-mini`, `qwen2.5-coder-1.5b`, `qwen3-4b` |
| `power` | 32 GB+ | `phi-4`, `qwen2.5-7b`, `deepseek-r1-7b`, `mistral-7b-v0.2` |

Provision with:

```bash
make models PROFILE=starter
make models PROFILE=balanced
make models PROFILE=power
```

The live catalog is still authoritative. If a profile alias is unavailable, run `foundry model list` and choose an available alias for the machine.

## Runtime and serve plan

Interactive model run:

```bash
make run MODEL=qwen2.5-0.5b
```

Local service:

```bash
make serve
```

Direct Foundry Local commands:

```bash
foundry service start
foundry service status
foundry service diag
```

The REST endpoint is local and dynamic. Always discover it rather than hard-coding a port.

## Integration surface

| Surface | Use |
| --- | --- |
| JavaScript SDK | App integration with model lifecycle, chat, streaming, and audio. |
| Python SDK | App integration with model lifecycle, chat, and streaming. |
| OpenAI-compatible REST | Existing OpenAI SDK, curl, and framework integration. |
| LangChain | Configure local base URL and placeholder API key. |
| CLI | Developer workflows for model, service, and cache operations. |

See [SDK guide](06-sdk-guide.md) and [REST API](07-rest-api.md).

## Security and privacy posture

Foundry Local runs models on device. Data never leaves the device for inference. Local workflows can operate offline after installation and model caching. There is no per-token cloud cost, no required API key, no Azure subscription requirement, and no backend to maintain for local development.

For OpenAI-compatible local REST, the API key value is a client placeholder. It is not used for local authentication.

## Performance considerations on Apple Silicon

- Prefer aliases so Foundry Local can select the best hardware-aware variant.
- Start with `qwen2.5-0.5b` for smoke tests.
- Use WebGPU through Dawn to Metal when available.
- Expect CPU through MLAS as the universal fallback.
- Larger models need more unified memory and disk.
- Quantized and compressed catalog models reduce local resource pressure.
- Close memory-heavy apps when testing larger models on 8 GB or 16 GB machines.

## Validation and acceptance checklist

The checklist mirrors `make health`:

- [ ] `foundry --version` returns a version.
- [ ] `foundry service status` returns a healthy local service state.
- [ ] The dynamic local endpoint is discoverable.
- [ ] `foundry model list` returns the machine-specific catalog.
- [ ] `foundry cache location` returns a local cache path.
- [ ] `foundry cache list` can inspect cached models.
- [ ] `make models PROFILE=starter` can provision starter aliases when available.
- [ ] `make run MODEL=qwen2.5-0.5b` can launch a first local chat.
- [ ] `make chat` runs the JavaScript SDK example.
- [ ] `make chat-openai` runs the OpenAI-compatible example.
- [ ] `make py-chat` runs the Python SDK example.

## Roadmap

- Add more tested Mac profiles as the dynamic catalog evolves.
- Expand examples for streaming, audio transcription, and LangChain.
- Add richer health output for service endpoint and cache diagnostics.
- Document observed performance notes by Apple Silicon generation and memory tier.
- Keep docs aligned with Microsoft Learn and the Foundry Local product repo.
