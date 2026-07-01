# CLI Reference

[Back to repo README](../README.md) | Previous: [Model catalog](04-model-catalog.md) | Next: [SDK guide](06-sdk-guide.md)

The `foundry` CLI is a developer workflow companion for the SDK. It has three command groups: `model`, `service`, and `cache`.

Get help:

```bash
foundry --help
foundry model --help
foundry service --help
foundry cache --help
```

## Model commands

| Command | Use |
| --- | --- |
| `foundry model run <model>` | Download on first run, load the model, and open an interactive REPL. |
| `foundry model list` | List the hardware-aware catalog for this machine. |
| `foundry model list --filter <key>=<value>` | List models matching one filter. |
| `foundry model info <model>` | Show model details. |
| `foundry model info <model> --license` | Show model license details. |
| `foundry model download <model>` | Download a model into the local cache. |
| `foundry model load <model>` | Load a model. |
| `foundry model unload <model>` | Unload a model. |

Example:

```bash
foundry model run qwen2.5-0.5b
```

## Service commands

| Command | Use |
| --- | --- |
| `foundry service start` | Start the local service. |
| `foundry service stop` | Stop the local service. |
| `foundry service restart` | Restart the local service. |
| `foundry service status` | Show service status and local endpoint. |
| `foundry service ps` | Show service processes. |
| `foundry service diag` | Gather diagnostics and logs. |
| `foundry service set <options>` | Configure service options. |

The local server uses a dynamic local port. Discover it with:

```bash
foundry service status
```

## Cache commands

| Command | Use |
| --- | --- |
| `foundry cache location` | Show where models are stored. |
| `foundry cache list` | List cached models. |
| `foundry cache cd <path>` | Change cache path. |
| `foundry cache remove <model>` | Remove a cached model. |

## Filters

`foundry model list --filter` supports one filter per command.

| Key | Values |
| --- | --- |
| `device` | `CPU`, `GPU`, `NPU` |
| `provider` | `CPUExecutionProvider`, `CUDAExecutionProvider`, `WebGpuExecutionProvider`, `QNNExecutionProvider`, `OpenVINOExecutionProvider`, `NvTensorRTRTXExecutionProvider`, `VitisAIExecutionProvider` |
| `task` | `chat-completion`, `text-generation` |
| `alias` | Alias values, with wildcard support for alias only |

Examples:

```bash
foundry model list --filter device=CPU
foundry model list --filter device=!GPU
foundry model list --filter provider=WebGpuExecutionProvider
foundry model list --filter task=chat-completion
foundry model list --filter alias=qwen*
```

Filters are case-insensitive. Negation prefixes the value with `!`. Wildcard matching is supported for `alias`.

## Alias vs model ID

Use an alias such as `qwen2.5-0.5b` for normal workflows. Foundry Local chooses the best model variant for your hardware. Use a full model ID, such as `qwen2.5-0.5b-instruct-generic-cpu`, when you need an exact pinned variant.

## Repo command mapping

| Repo script or target | Underlying Foundry Local workflow |
| --- | --- |
| `scripts/install-mac.sh` | `brew tap microsoft/foundrylocal`, `brew install foundrylocal`, `foundry --version` |
| `scripts/list-models.sh` | `foundry model list` |
| `scripts/download-models.sh` | `foundry model download <model>` for models in a profile |
| `scripts/run-model.sh` | `foundry model run <model>` |
| `scripts/serve.sh` | `foundry service start` and `foundry service status` |
| `scripts/health-check.sh` | Version, service, catalog, cache, and endpoint checks |
| `scripts/uninstall-mac.sh` | Local uninstall workflow for this repo |
| `make help` | Print repo command help |
| `make install` | Run `scripts/install-mac.sh` |
| `make models` | Run profile download with `PROFILE=starter`, `balanced`, or `power` |
| `make model-list` | Run `scripts/list-models.sh` |
| `make run` | Run `scripts/run-model.sh` with `MODEL=<alias>` |
| `make serve` | Run `scripts/serve.sh` |
| `make health` | Run `scripts/health-check.sh` |
| `make chat` | Run `examples/js/chat.mjs` |
| `make chat-openai` | Run `examples/js/openai-compat.mjs` |
| `make py-chat` | Run `examples/python/chat.py` |
| `make demo` | Run the repo demo flow |
| `make clean` | Clean repo-local generated artifacts |
| `make uninstall` | Run `scripts/uninstall-mac.sh` |
