# OpenAI-Compatible REST API

[Back to repo README](../README.md) | Previous: [SDK guide](06-sdk-guide.md) | Next: [Troubleshooting](08-troubleshooting.md)

Foundry Local includes an optional OpenAI-compatible local web server. Use it when you want existing OpenAI SDK, REST, or LangChain code to point at your local machine instead of a cloud endpoint.

The server is local and uses a dynamic port. Discover the endpoint each time instead of hard-coding it.

## Start and discover the endpoint

```bash
foundry service start
foundry service status
```

Or use this repo:

```bash
make serve
```

The service status output includes the local endpoint. Use that value as `FOUNDRY_LOCAL_ENDPOINT` or another local environment variable name in your shell. The exact variable name is up to your script.

## List local models

```bash
curl "$FOUNDRY_LOCAL_ENDPOINT/v1/models"
```

## Chat completions with curl

The local API key is not used for authentication, but OpenAI-compatible clients often require a placeholder value.

```bash
curl "$FOUNDRY_LOCAL_ENDPOINT/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer local-placeholder" \
  -d '{
    "model": "qwen2.5-0.5b",
    "messages": [
      { "role": "user", "content": "Explain Foundry Local in one sentence." }
    ]
  }'
```

## JavaScript OpenAI SDK

See [`../examples/js/openai-compat.mjs`](../examples/js/openai-compat.mjs).

```js
import OpenAI from 'openai';

const client = new OpenAI({
  baseURL: process.env.FOUNDRY_LOCAL_ENDPOINT + '/v1',
  apiKey: 'local-placeholder'
});

const response = await client.chat.completions.create({
  model: 'qwen2.5-0.5b',
  messages: [
    { role: 'user', content: 'Give me a one-line local AI demo idea.' }
  ]
});

console.log(response.choices[0]?.message?.content);
```

## Python OpenAI SDK

```python
import os
from openai import OpenAI

client = OpenAI(
    base_url=os.environ["FOUNDRY_LOCAL_ENDPOINT"] + "/v1",
    api_key="local-placeholder",
)

response = client.chat.completions.create(
    model="qwen2.5-0.5b",
    messages=[
        {"role": "user", "content": "Give me a one-line local AI demo idea."}
    ],
)

print(response.choices[0].message.content)
```

## LangChain

Use the OpenAI-compatible integration path and point the base URL at the local endpoint with a placeholder API key.

Configuration shape:

```text
base_url: <local endpoint>/v1
api_key: local-placeholder
model: qwen2.5-0.5b
```

Keep the endpoint dynamic. Use `foundry service status`, `make serve`, or the SDK manager to discover it.

## REST vs SDK

| Use SDK when | Use REST when |
| --- | --- |
| You are building a local app and want lifecycle control. | You are adapting OpenAI-compatible code. |
| You need execution provider and model lifecycle APIs. | You want a local endpoint for tools and frameworks. |
| You want direct chat and audio clients. | You want `/v1/chat/completions` and `/v1/models`. |
