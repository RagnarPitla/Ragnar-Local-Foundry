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

Sizes below are the GPU (WebGPU/Metal) variant that an alias resolves to on Apple Silicon, verified against a live `foundry model list`. CPU variants are slightly larger.

| Alias | Family | Params | Approx size | Min RAM | Task | Mac execution | Use case |
| --- | --- | ---: | ---: | ---: | --- | --- | --- |
| `qwen2.5-0.5b` | Qwen | 0.5B | 0.68 GB | 8 GB | chat-completion | GPU (WebGPU/Metal), CPU fallback | Fastest smoke test, quick chat, low-resource devices |
| `qwen3-0.6b` | Qwen3 | 0.6B | 0.52 GB | 8 GB | chat-completion | GPU (WebGPU/Metal), CPU fallback | Newest tiny chat model with tool support |
| `qwen2.5-1.5b` | Qwen | 1.5B | 1.51 GB | 8 GB | chat-completion | GPU (WebGPU/Metal), CPU fallback | Light general chat with better quality than 0.5B |
| `qwen2.5-coder-1.5b` | Qwen Coder | 1.5B | 1.25 GB | 8 GB | chat-completion | GPU (WebGPU/Metal), CPU fallback | Fast local code completion and code chat |
| `qwen3-4b` | Qwen3 | 4B | 2.87 GB | 16 GB | chat-completion | GPU (WebGPU/Metal), CPU fallback | Strong small general model with tool support |
| `smollm3-3b` | SmolLM3 | 3B | 2.20 GB | 8 GB | chat-completion | GPU (WebGPU/Metal), CPU fallback | Compact open model, good speed on modest Macs |
| `phi-3.5-mini` | Phi | 3.8B | 2.16 GB | 8 GB | chat-completion | GPU (WebGPU/Metal), CPU fallback | Compact instruct model, good reasoning per byte |
| `phi-4-mini` | Phi | 3.8B | 3.72 GB | 8 GB | chat-completion | GPU (WebGPU/Metal), CPU fallback | Balanced default assistant, strong instruction following |
| `phi-4-mini-reasoning` | Phi | 3.8B | 3.15 GB | 8 GB | chat-completion | GPU (WebGPU/Metal), CPU fallback | Chain-of-thought style reasoning at small size |
| `qwen3-8b` | Qwen3 | 8B | 6.00 GB | 16 GB | chat-completion | GPU (WebGPU/Metal), CPU fallback | High-quality newest-gen general assistant |
| `qwen2.5-7b` | Qwen | 7B | 5.20 GB | 16 GB | chat-completion | GPU (WebGPU/Metal), CPU fallback | Strong general-purpose assistant |
| `qwen2.5-coder-7b` | Qwen Coder | 7B | 4.73 GB | 16 GB | chat-completion | GPU (WebGPU/Metal), CPU fallback | High-quality local coding assistant |
| `deepseek-r1-7b` | DeepSeek R1 | 7B | 5.58 GB | 16 GB | chat-completion | GPU (WebGPU/Metal), CPU fallback | Reasoning-distilled model, good for math and logic |
| `mistral-7b-v0.2` | Mistral | 7B | 4.07 GB | 16 GB | chat-completion | GPU (WebGPU/Metal), CPU fallback | Fast, capable general chat and drafting |
| `olmo-3-7b-instruct` | OLMo 3 | 7B | 5.51 GB | 16 GB | chat-completion | GPU (WebGPU/Metal), CPU fallback | Fully open 7B instruct model with tool support |
| `phi-4` | Phi | 14B | 8.37 GB | 32 GB | chat-completion | GPU (WebGPU/Metal), CPU fallback | Top-tier local reasoning and general quality |
| `deepseek-r1-14b` | DeepSeek R1 | 14B | 10.27 GB | 32 GB | chat-completion | GPU (WebGPU/Metal), CPU fallback | Largest local reasoning distill |
| `gpt-oss-20b` | GPT-OSS | 20B | 11.78 GB | 32 GB | chat-completion | GPU (WebGPU/Metal), CPU fallback | Large open-weight model for highest local quality |

The live catalog carries more than this curated subset. Recent `foundry model list` output on Apple Silicon also includes newer families such as `qwen3-1.7b`, `qwen3-14b`, the `qwen3.5` line, vision-language models (`qwen3-vl-2b-instruct`, `qwen3-vl-8b-instruct`), `mistral-nemo-12b-instruct`, and `ministral-3-3b-instruct-2512`. Audio transcription models (Whisper) appear when they are available for your platform and version. Always run `foundry model list` to see the current set.

## Unified-memory guidance

| Mac unified memory | Recommended profile | Practical guidance |
| ---: | --- | --- |
| 8 GB | `starter` | Use `qwen2.5-0.5b` and `qwen3-0.6b`. Keep other apps light. |
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
