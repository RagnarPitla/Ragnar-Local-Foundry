# Troubleshooting

[Back to repo README](../README.md) | Previous: [REST API](07-rest-api.md) | Next: [Specs](09-specs.md)

Most Foundry Local issues fall into five buckets: service state, model catalog state, first-run downloads, local disk pressure, or local developer tool versions.

## Symptom to fix table

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `Request to local service failed` | Local service is stopped or unhealthy. | Run `foundry service restart`, then `foundry service status`. |
| `Model not found` | Alias is not available on this machine or catalog changed. | Run `foundry model list` and choose an available alias. |
| First `foundry model run` is slow | Model and execution providers may download on first use. | Wait for the first run to complete. Later runs use the cache. |
| Low disk space | Cached models consume local storage. | Run `foundry cache location`, `foundry cache list`, then `foundry cache remove <model>`. |
| Homebrew install problems | Homebrew, permissions, or tap state needs attention. | Confirm Homebrew works, then rerun `brew tap microsoft/foundrylocal` and `brew install foundrylocal`. |
| `Refusing to load formula ... from untrusted tap` | Newer Homebrew gates third-party taps behind an explicit trust step. | Run `brew trust microsoft/foundrylocal`, then `brew install foundrylocal`. The repo installer does this automatically. |
| Wrong Node version | JavaScript SDK requires Node.js 20+. | Install or select Node.js 20+, then rerun the JS example. |
| Wrong Python version | Python SDK requires Python 3.11+. | Install or select Python 3.11+, then rerun the Python example. |
| Cannot find REST endpoint | Local server uses a dynamic port. | Run `foundry service status` or `make serve`. |
| OpenAI SDK asks for an API key | SDK requires a value even though local auth does not use it. | Use a placeholder such as `local-placeholder`. |
| Slow responses on larger models | Model size, memory pressure, or CPU fallback. | Use a smaller alias or a lower profile from [Model catalog](04-model-catalog.md). |

## Service diagnostics

Use the service commands first:

```bash
foundry service status
foundry service ps
foundry service diag
```

If the service is unhealthy:

```bash
foundry service restart
```

## Catalog checks

The catalog is dynamic and hardware-aware. Do not assume every documented alias is present on every machine.

```bash
foundry model list
foundry model info qwen2.5-0.5b
foundry model info qwen2.5-0.5b --license
```

Use filters when the list is large:

```bash
foundry model list --filter task=chat-completion
foundry model list --filter alias=qwen*
```

## Cache checks

```bash
foundry cache location
foundry cache list
foundry cache remove <model>
```

Model sizes in [`../config/models.json`](../config/models.json) are approximate. The live catalog and local cache are authoritative for the current machine.

## Repo health check

Use the repo health target after install:

```bash
make health
```

The expected health flow mirrors the setup:

1. `foundry --version`
2. service status
3. model catalog access
4. cache access
5. endpoint discovery for local REST workflows

For the formal acceptance checklist, see [Specs](09-specs.md).
