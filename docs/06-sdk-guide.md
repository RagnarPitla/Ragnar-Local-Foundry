# SDK Guide

[Back to repo README](../README.md) | Previous: [CLI reference](05-cli-reference.md) | Next: [REST API](07-rest-api.md)

The SDK is the primary Foundry Local integration surface. Use it when you are embedding local AI directly into an app and want control over execution provider discovery, model download, load, chat, streaming, audio, and unload.

See the repo examples:

- [`../examples/js/chat.mjs`](../examples/js/chat.mjs)
- [`../examples/python/chat.py`](../examples/python/chat.py)

## JavaScript setup

Requires Node.js 20+.

```bash
npm install foundry-local-sdk openai
```

Windows has a Windows-optimized variant named `foundry-local-sdk-winml`. This Mac repo uses `foundry-local-sdk`.

## JavaScript lifecycle

```js
import { FoundryLocalManager } from 'foundry-local-sdk';

const manager = FoundryLocalManager.create({
  appName: 'my-app',
  logLevel: 'info'
});

manager.discoverEps();

await manager.downloadAndRegisterEps((epName, percent) => {
  console.log(`${epName}: ${percent}%`);
});

const model = await manager.catalog.getModel('qwen2.5-0.5b');
await model.download((p) => {
  console.log(`model: ${p}%`);
});
await model.load();

const chat = model.createChatClient();
const c = await chat.completeChat([
  { role: 'user', content: 'Explain Foundry Local in one sentence.' }
]);

console.log(c.choices[0]?.message?.content);

await model.unload();
```

## JavaScript streaming chat

```js
const messages = [
  { role: 'user', content: 'Give me three local AI demo ideas.' }
];

for await (const chunk of chat.completeStreamingChat(messages)) {
  process.stdout.write(chunk.choices?.[0]?.delta?.content ?? '');
}
```

## JavaScript audio transcription

Foundry Local supports speech-to-text through Whisper audio models. Audio model availability depends on your platform and Foundry Local version, so confirm an audio alias is listed by `foundry model list` before using this path. If your catalog does not list a Whisper model yet, use the chat examples above.

```js
const whisper = await manager.catalog.getModel('whisper-tiny');
await whisper.download();
await whisper.load();

const audio = whisper.createAudioClient();
audio.settings.language = 'en';

const r = await audio.transcribe('recording.wav');
console.log(r.text);

for await (const part of audio.transcribeStreaming('recording.wav')) {
  console.log(part);
}

await whisper.unload();
```

## Python setup

Requires Python 3.11+.

```bash
pip install foundry-local-sdk openai
```

## Python lifecycle

```python
from foundry_local_sdk import Configuration, FoundryLocalManager

config = Configuration(app_name="foundry_local_samples")
FoundryLocalManager.initialize(config)
manager = FoundryLocalManager.instance

model = manager.catalog.get_model("qwen2.5-0.5b")
model.download()
model.load()

client = model.get_chat_client()
response = client.complete_chat([
    {"role": "user", "content": "Explain Foundry Local in one sentence."}
])

print(response.choices[0].message.content)

model.unload()
```

## Python streaming chat

```python
messages = [
    {"role": "user", "content": "Give me three local AI demo ideas."}
]

for chunk in client.complete_streaming_chat(messages):
    text = chunk.choices[0].delta.content
    if text:
        print(text, end="")
```

## Model lifecycle pattern

Use the same lifecycle in apps and examples:

1. Initialize the manager.
2. Discover execution providers.
3. Download and register execution providers when using the JavaScript SDK flow.
4. Resolve a model alias from the catalog.
5. Download the model.
6. Load the model.
7. Create a chat or audio client.
8. Run non-streaming or streaming inference.
9. Unload the model when finished.

## Notes for Mac

On Apple Silicon, Foundry Local can use CPU through MLAS and WebGPU through Dawn to Metal. Let Foundry Local choose the best path. Avoid assuming CUDA, NPU, CoreML, or Apple Neural Engine support.
