# Python examples

Runnable Python samples for Azure AI Foundry Local on Apple Silicon Macs.

## Prerequisites

- Python 3.11 or newer
- Azure AI Foundry Local installed with `../../scripts/install-mac.sh`
- A Mac with Apple Silicon

## Create a virtual environment

From this folder:

```bash
python3 -m venv .venv && source .venv/bin/activate
```

## Install

```bash
pip install -r requirements.txt
```

## Native SDK chat

```bash
python3 chat.py qwen2.5-0.5b "What can I build locally?"
```

Arguments are optional. The default model alias is `qwen2.5-0.5b`.
The first run may download the model, so it can take longer than later runs.

## More information

- [Repo overview](../../README.md)
- [SDK guide](../../docs/06-sdk-guide.md)
