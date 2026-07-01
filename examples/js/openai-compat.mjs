/*
 * OpenAI-compatible Azure AI Foundry Local chat sample for Node.js.
 * Run from this folder with:
 *   npm install
 *   FOUNDRY_LOCAL_ENDPOINT=http://localhost:<port> npm run openai -- <alias> "<prompt>"
 * If you do not set FOUNDRY_LOCAL_ENDPOINT, this sample tries SDK discovery, then localhost:5273.
 */

const DEFAULT_MODEL = 'qwen2.5-0.5b';
const DEFAULT_PROMPT = 'Give one practical reason to use Azure AI Foundry Local on a Mac.';
const FALLBACK_ENDPOINT = 'http://localhost:5273';

function toV1BaseUrl(endpoint) {
  const trimmed = endpoint.replace(/\/+$/, '');
  return trimmed.endsWith('/v1') ? trimmed : `${trimmed}/v1`;
}

function isModuleError(error) {
  return error?.code === 'ERR_MODULE_NOT_FOUND' || /Cannot find package|module not found/i.test(error?.message ?? '');
}

function isEndpointError(error) {
  return /ECONNREFUSED|fetch failed|connection|connect|endpoint|socket|404|Not Found/i.test(error?.message ?? '');
}

function printFriendlyError(error) {
  console.error('\nThe OpenAI-compatible Foundry Local sample could not finish.');

  if (isModuleError(error)) {
    console.error('Run npm install in examples/js, then try again.');
  } else if (isEndpointError(error)) {
    console.error('Check the local endpoint with foundry service status, or run serve.sh if your setup uses it.');
    console.error('Set FOUNDRY_LOCAL_ENDPOINT to the reported local endpoint and try again.');
  } else {
    console.error(error?.message ?? String(error));
  }
}

async function createManagerIfAvailable() {
  try {
    const { FoundryLocalManager } = await import('foundry-local-sdk');
    return FoundryLocalManager.create({ appName: 'ragnar-local-foundry', logLevel: 'info' });
  } catch (error) {
    if (isModuleError(error)) throw error;
    return undefined;
  }
}

async function bestEffortLoadModel(manager, modelAlias) {
  if (!manager) return;

  try {
    const sdkModel = await manager.catalog.getModel(modelAlias);
    await sdkModel.download((progress) => {
      const percent = Number.isFinite(progress) ? Math.round(progress) : 0;
      process.stdout.write(`\rPreparing ${modelAlias}: ${percent}%`);
      if (percent >= 100) process.stdout.write('\n');
    });
    await sdkModel.load();
  } catch (error) {
    console.warn(`Could not preload ${modelAlias} with the SDK. Continuing with the REST server.`);
  }
}

async function main() {
  const model = process.argv[2] || DEFAULT_MODEL;
  const prompt = process.argv[3] || DEFAULT_PROMPT;
  const { default: OpenAI } = await import('openai');

  const manager = process.env.FOUNDRY_LOCAL_ENDPOINT ? undefined : await createManagerIfAvailable();
  let endpoint = process.env.FOUNDRY_LOCAL_ENDPOINT || manager?.endpoint;

  if (!endpoint) {
    endpoint = FALLBACK_ENDPOINT;
    console.warn('Could not discover the Foundry Local endpoint from the SDK.');
    console.warn('Run foundry service status or npm run serve, then set FOUNDRY_LOCAL_ENDPOINT if the port differs.');
  }

  await bestEffortLoadModel(manager, model);

  const baseURL = toV1BaseUrl(endpoint);
  const apiKey = process.env.FOUNDRY_LOCAL_API_KEY || manager?.apiKey || 'not-needed';
  const client = new OpenAI({ baseURL, apiKey });
  const messages = [{ role: 'user', content: prompt }];

  console.log(`Using ${baseURL} with model ${model}`);
  console.log('\nStreaming response:');
  const stream = await client.chat.completions.create({ model, messages, stream: true });
  for await (const chunk of stream) {
    const token = chunk.choices?.[0]?.delta?.content;
    if (token) process.stdout.write(token);
  }
  process.stdout.write('\n');

  console.log('\nNon-streaming response:');
  const completion = await client.chat.completions.create({ model, messages });
  console.log(completion.choices?.[0]?.message?.content ?? '(no content returned)');
}

main().catch((error) => {
  printFriendlyError(error);
  process.exitCode = 1;
});
