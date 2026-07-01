# Architecture

[Back to repo README](../README.md) | Previous: [Overview](01-overview.md) | Next: [Mac setup](03-mac-setup.md)

Azure AI Foundry Local is a local runtime and SDK stack for on-device AI. It uses ONNX Runtime underneath, picks hardware acceleration through execution providers, manages a local model cache, and can expose models through either embedded SDK clients or an optional OpenAI-compatible local server.

## Components

| Component | Role |
| --- | --- |
| Lightweight runtime | Installs the local runtime, about 20 MB, and hosts local inference capabilities. |
| ONNX Runtime engine | Executes optimized model graphs on the device. |
| Execution providers | Hardware-specific acceleration libraries used by ONNX Runtime. |
| Local model cache | Stores downloaded model variants and execution provider artifacts. |
| SDK | Primary integration surface for apps in C#, JavaScript, Python, and Rust. |
| Optional local server | Exposes an OpenAI-compatible REST endpoint on a local dynamic port. |
| CLI | Developer workflow surface for model, service, and cache commands. |

## Architecture diagram

```mermaid
flowchart LR
    App[App or sample] --> SDK[Foundry Local SDK]
    CLI[foundry CLI] --> Runtime[Foundry Local runtime]
    SDK --> Runtime
    OpenAI[OpenAI SDK or LangChain] --> Server[Optional local OpenAI-compatible server]
    Server --> Runtime
    Runtime --> Catalog[Dynamic model catalog]
    Runtime --> Cache[Local model cache]
    Runtime --> ORT[ONNX Runtime]
    ORT --> EP{Execution provider}
    EP --> WebGPU[WebGPU via Dawn to Metal on Mac]
    EP --> CPU[CPU via MLAS]
    Cache --> Model[Quantized local model]
    Model --> ORT
```

## End-to-end request flow

```mermaid
sequenceDiagram
    participant User
    participant App
    participant SDK as Foundry Local SDK
    participant Runtime
    participant Cache
    participant ORT as ONNX Runtime
    participant EP as CPU or WebGPU EP

    User->>App: Prompt or audio input
    App->>SDK: Request model alias
    SDK->>Runtime: Resolve hardware-aware model variant
    Runtime->>Cache: Check local model cache
    Cache-->>Runtime: Model present or downloaded earlier
    Runtime->>ORT: Load model
    ORT->>EP: Select available acceleration path
    App->>SDK: Chat or transcription request
    SDK->>Runtime: Inference request
    Runtime->>ORT: Execute
    ORT-->>Runtime: Tokens or transcript
    Runtime-->>SDK: Result
    SDK-->>App: Response
```

## Hardware acceleration selection

Foundry Local auto-detects hardware and picks the best available execution provider, with CPU fallback.

```mermaid
flowchart TD
    Start[Start model load] --> Detect[Detect hardware and available EPs]
    Detect --> Mac{macOS Apple Silicon?}
    Mac -->|Yes| WebGPU{WebGPU available?}
    WebGPU -->|Yes| UseWebGPU[Use WebGPU through Dawn to Metal]
    WebGPU -->|No| UseCPU[Use CPU through MLAS]
    Mac -->|No| Other[Use platform-specific EPs if available]
    Other --> Fallback[Fallback to CPU when needed]
```

## Mac Apple Silicon execution provider story

On macOS Apple Silicon, the relevant execution providers are:

| Provider | Mac role |
| --- | --- |
| CPUExecutionProvider | Universal fallback using MLAS. |
| WebGpuExecutionProvider | GPU path using Dawn, which targets Metal on Mac. |

Do not expect CUDA on Mac. CUDA is NVIDIA-only. Do not expect an NPU execution provider on Mac. Do not assume CoreML or Apple Neural Engine support for Foundry Local. The safe Mac guidance is CPU through MLAS plus WebGPU through Dawn to Metal, with automatic fallback to CPU.

## SDK first, server optional

The SDK is the primary product surface. Use it when you are building a local app and want lifecycle control over execution providers, downloads, loading, unloading, chat, streaming, and audio.

Use the optional OpenAI-compatible server when you want existing OpenAI SDK or LangChain code to talk to a local endpoint. The endpoint uses a dynamic local port. Discover it with `foundry service status` or through the SDK manager.

## Related docs

- Install the runtime with [Mac setup](03-mac-setup.md).
- Pick models with [Model catalog](04-model-catalog.md).
- Use the server with [REST API](07-rest-api.md).
- See the formal build plan in [Specs](09-specs.md).
