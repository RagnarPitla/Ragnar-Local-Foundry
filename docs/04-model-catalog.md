# Model Catalog

[Back to repo README](../README.md) | Previous: [Mac setup](03-mac-setup.md) | Next: [CLI reference](05-cli-reference.md)

Foundry Local uses a curated, quantized, compressed, versioned model catalog. The catalog is dynamic and hardware-aware. The source of truth for your Mac is always:

```bash
foundry model list
```

This repo includes representative aliases in [`../config/models.json`](../config/models.json) so the docs, scripts, and Makefile can agree on starter, balanced, and power profiles.

## Model families

| Family | Primary use |
| --- | --- |
| GPT-OSS | Large open-weight local chat models. |
| Qwen | General chat and coding variants. |
| DeepSeek | Reasoning-distilled chat models. |
| Mistral | General chat and drafting. |
| Phi | Compact and capable instruction-following models. |
| Whisper | Local audio transcription. |

## Alias vs full model ID

An alias, such as `qwen2.5-0.5b`, lets Foundry Local select the best variant for your hardware. A full model ID pins an exact variant, such as `qwen2.5-0.5b-instruct-generic-cpu`.

For most app and demo work, use aliases. Use full model IDs only when you need exact reproducibility for a specific variant.

## Listing and filtering

List everything available for this machine:

```bash
foundry model list
```

Filter examples:

```bash
foundry model list --filter device=CPU
foundry model list --filter device=!GPU
foundry model list --filter task=chat-completion
foundry model list --filter alias=qwen*
```

Supported filter keys:

| Key | Values |
| --- | --- |
| `device` | `CPU`, `GPU`, `NPU` |
| `provider` | `CPUExecutionProvider`, `CUDAExecutionProvider`, `WebGpuExecutionProvider`, `QNNExecutionProvider`, `OpenVINOExecutionProvider`, `NvTensorRTRTXExecutionProvider`, `VitisAIExecutionProvider` |
| `task` | `chat-completion`, `text-generation` |
| `alias` | Alias values, with wildcard support such as `alias=qwen*` |

Rules: one filter per command, case-insensitive. Negation uses `!`, for example `device=!GPU`. Wildcard is supported for alias only.

## Repo model table

Built from `config/models.json`:

| Alias | Family | Params | Approx size | Min RAM | Task | Mac execution | Use case |
| --- | --- | ---: | ---: | ---: | --- | --- | --- |
| `qwen2.5-0.5b` | Qwen | 0.5B | 0.7 GB | 8 GB | chat-completion | CPU / WebGPU (Metal) | Fastest smoke test, quick chat, low-resource devices |
| `qwen2.5-1.5b` | Qwen | 1.5B | 1.2 GB | 8 GB | chat-completion | CPU / WebGPU (Metal) | Light general chat with better quality than 0.5B |
| `qwen2.5-7b` | Qwen | 7B | 5.0 GB | 16 GB | chat-completion | CPU / WebGPU (Metal) | Strong general-purpose assistant |
| `qwen2.5-coder-1.5b` | Qwen Coder | 1.5B | 1.2 GB | 8 GB | chat-completion | CPU / WebGPU (Metal) | Fast local code completion and code chat |
| `qwen2.5-coder-7b` | Qwen Coder | 7B | 5.0 GB | 16 GB | chat-completion | CPU / WebGPU (Metal) | High-quality local coding assistant |
| `phi-3.5-mini-instruct` | Phi | 3.8B | 2.2 GB | 8 GB | chat-completion | CPU / WebGPU (Metal) | Compact instruct model, good reasoning per byte |
| `phi-4-mini-instruct` | Phi | 3.8B | 2.5 GB | 8 GB | chat-completion | CPU / WebGPU (Metal) | Balanced default assistant, strong instruction following |
| `phi-4-mini-reasoning` | Phi | 3.8B | 2.5 GB | 8 GB | chat-completion | CPU / WebGPU (Metal) | Chain-of-thought style reasoning at small size |
| `phi-4` | Phi | 14B | 8.5 GB | 32 GB | chat-completion | CPU / WebGPU (Metal) | Top-tier local reasoning and general quality |
| `deepseek-r1-distill-qwen-1.5b` | DeepSeek R1 | 1.5B | 1.2 GB | 8 GB | chat-completion | CPU / WebGPU (Metal) | Small reasoning-distilled model, good for math/logic |
| `deepseek-r1-distill-qwen-7b` | DeepSeek R1 | 7B | 5.0 GB | 16 GB | chat-completion | CPU / WebGPU (Metal) | Reasoning-focused mid-size model |
| `deepseek-r1-distill-qwen-14b` | DeepSeek R1 | 14B | 9.5 GB | 32 GB | chat-completion | CPU / WebGPU (Metal) | Largest local reasoning distill |
| `mistral-7b-v0.2` | Mistral | 7B | 4.5 GB | 16 GB | chat-completion | CPU / WebGPU (Metal) | Fast, capable general chat and drafting |
| `gpt-oss-20b` | GPT-OSS | 20B | 12.5 GB | 32 GB | chat-completion | CPU / WebGPU (Metal) | Large open-weight model for highest local quality |
| `whisper-tiny` | Whisper | 39M | 0.15 GB | 8 GB | audio-transcription | CPU / WebGPU (Metal) | Local speech-to-text transcription |

## Unified-memory guidance

| Mac unified memory | Recommended profile | Practical guidance |
| ---: | --- | --- |
| 8 GB | `starter` | Use `qwen2.5-0.5b` and `whisper-tiny`. Keep other apps light. |
| 16 GB | `balanced` | Use small and mid-size chat models, including coding and reasoning options. |
| 32 GB | `power` | Use larger local models such as `phi-4` and 7B reasoning or coding models. |
| 64 GB+ | `power` | Best headroom for larger models, multitasking, and repeated local experiments. |

Download profile models with:

```bash
make models PROFILE=starter
make models PROFILE=balanced
make models PROFILE=power
```

Remember: `foundry model list` is authoritative for what is actually available on the current machine.
