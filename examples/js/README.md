# JavaScript examples

Runnable Node.js samples for Azure AI Foundry Local on Apple Silicon Macs.

## Prerequisites

- Node.js 20 or newer
- Azure AI Foundry Local installed with `../../scripts/install-mac.sh`
- A Mac with Apple Silicon

## Install

From this folder:

```bash
npm install
```

## Native SDK chat

```bash
npm run chat -- qwen2.5-0.5b "What can I build locally?"
```

Arguments are optional. The default model alias is `qwen2.5-0.5b`.

## OpenAI-compatible chat

Foundry Local exposes a local OpenAI-compatible API on a dynamic port.

```bash
FOUNDRY_LOCAL_ENDPOINT=http://localhost:5273 npm run openai -- qwen2.5-0.5b "Say hello from the local model."
```

Environment variables:

- `FOUNDRY_LOCAL_ENDPOINT`: Local Foundry endpoint. If it does not include `/v1`, the sample appends it.
- `FOUNDRY_LOCAL_API_KEY`: Optional local placeholder API key. Defaults to `not-needed`.

If you do not know the endpoint, run `foundry service status` and copy the reported local URL.
The first run may download the execution provider and model, so it can take longer than later runs.

## More information

- [Repo overview](../../README.md)
- [SDK guide](../../docs/06-sdk-guide.md)
- [REST API guide](../../docs/07-rest-api.md)
