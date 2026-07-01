# Azure AI Foundry Local on Mac: Overview

[Back to repo README](../README.md) | Next: [Architecture](02-architecture.md)

Azure AI Foundry Local is an end-to-end on-device AI runtime for running curated models directly on your machine. The runtime is lightweight, about 20 MB, and is built on ONNX Runtime. For Mac users, this repo focuses on Apple Silicon machines.

The important point: Foundry Local is not primarily a server or a CLI. The core product is an SDK you embed in apps. It also ships an optional OpenAI-compatible local web server and a CLI for development workflows.

## Why it matters

Foundry Local gives builders a practical path to local AI:

| Value | What it means in practice |
| --- | --- |
| On-device execution | Models run entirely on your Mac. |
| Private by default | Data never leaves the device. |
| Offline capable | Once installed and models are cached, local workflows can run without network access. |
| Zero network latency | Inference avoids cloud round trips. |
| No per-token cost | Local inference does not meter tokens through a cloud API. |
| No API keys or Azure subscription | Local app development can start without cloud credentials. |
| No backend to maintain | Apps can embed the SDK or use the optional local server. |

## When to use Foundry Local

Use Foundry Local when you want:

- A local assistant, coding helper, transcription tool, or app feature.
- A private prototype before moving to a managed cloud endpoint.
- Offline demos, field work, classrooms, hackathons, and conference booths.
- Low-latency interactions on the same machine as the app.
- A stable local integration surface through SDKs or OpenAI-compatible REST.

## When to use cloud inference

Use cloud-hosted inference when you need:

- Centralized fleet operations and managed scale.
- Very large models that exceed laptop memory.
- Multi-user serving behind production APIs.
- Enterprise monitoring, governance, regional deployment, and policy controls.
- Guaranteed availability independent of a user's device.

## When to use Foundry Local on Azure Local

This repo is about running Foundry Local on a single Apple Silicon Mac. If you need an enterprise deployment pattern on Kubernetes with Azure Arc and Azure Local, use Foundry Local on Azure Local instead. That option is for infrastructure teams that want local or edge inference managed as part of an enterprise platform.

## Key features

- SDKs for C#, JavaScript, Python, and Rust.
- OpenAI-compatible API support, including the OpenAI Responses API format.
- Optional local OpenAI-compatible web server on a dynamic local port.
- Integration with the OpenAI SDK by pointing the base URL at the local endpoint.
- Integration with LangChain by configuring the local base URL and a placeholder API key.
- Dynamic, hardware-aware model catalog.
- Curated, quantized, compressed, versioned models.
- CLI workflows for model, service, and cache operations.

## How it works

At a high level:

1. Install Foundry Local.
2. Discover and download execution providers.
3. Select an alias, such as `qwen2.5-0.5b`.
4. Foundry Local resolves the best model variant for your hardware.
5. The model downloads into the local cache.
6. The SDK, CLI, or optional local server loads the model.
7. Requests run through ONNX Runtime on the best available execution provider.

On Apple Silicon, Foundry Local can use CPU through MLAS and WebGPU through Dawn, which targets Metal on Mac. There is no CUDA and no NPU execution provider on Mac.

## Where to go next

- Understand the runtime in [Architecture](02-architecture.md).
- Set up your Mac in [Mac setup](03-mac-setup.md).
- Pick a model in [Model catalog](04-model-catalog.md).
- Use commands from [CLI reference](05-cli-reference.md).
- Embed Foundry Local with [SDK guide](06-sdk-guide.md).
- Use OpenAI-compatible REST in [REST API](07-rest-api.md).
- Fix common issues in [Troubleshooting](08-troubleshooting.md).
- Follow the formal build plan in [Specs](09-specs.md).
