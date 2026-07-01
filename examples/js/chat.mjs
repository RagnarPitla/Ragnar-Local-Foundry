/*
 * Native Azure AI Foundry Local SDK chat sample for Node.js.
 * Run from this folder with:
 *   npm install
 *   npm run chat -- <alias> "<prompt>"
 * Example:
 *   npm run chat -- qwen2.5-0.5b "What can I build with Foundry Local?"
 */

const DEFAULT_MODEL = 'qwen2.5-0.5b';
const DEFAULT_PROMPT = 'What is a friendly way to explain Azure AI Foundry Local on a Mac?';

function writeProgress(label, value) {
  const percent = Number.isFinite(value) ? Math.max(0, Math.min(100, Math.round(value))) : 0;
  process.stdout.write(`\r${label}: ${percent}%`);
  if (percent >= 100) process.stdout.write('\n');
}

function isModuleError(error) {
  return error?.code === 'ERR_MODULE_NOT_FOUND' || /Cannot find package|module not found/i.test(error?.message ?? '');
}

function isServiceError(error) {
  return /ECONNREFUSED|fetch failed|connection|connect|service|endpoint|socket/i.test(error?.message ?? '');
}

function printFriendlyError(error) {
  console.error('\nThe Foundry Local chat sample could not finish.');

  if (isModuleError(error)) {
    console.error('Run npm install in examples/js, then try again.');
  } else if (isServiceError(error)) {
    console.error('Foundry Local may not be installed or running. Run ../../scripts/install-mac.sh or foundry service restart.');
  } else {
    console.error(error?.message ?? String(error));
  }
}

async function main() {
  const modelAlias = process.argv[2] || DEFAULT_MODEL;
  const prompt = process.argv[3] || DEFAULT_PROMPT;
  const { FoundryLocalManager } = await import('foundry-local-sdk');
  let model;

  try {
    const manager = FoundryLocalManager.create({ appName: 'ragnar-local-foundry', logLevel: 'info' });
    const eps = manager.discoverEps();
    const epList = eps.length ? eps.map((ep) => `${ep.name} (${ep.isRegistered ? 'registered' : 'not registered'})`).join(', ') : 'none';
    console.log(`Discovered EPs: ${epList}`);

    await manager.downloadAndRegisterEps((epName, percent) => {
      writeProgress(`Preparing ${epName}`, percent);
    });

    model = await manager.catalog.getModel(modelAlias);
    await model.download((progress) => writeProgress(`Downloading ${modelAlias}`, progress));
    console.log(`Loading ${modelAlias}...`);
    await model.load();

    const chatClient = model.createChatClient();
    const messages = [{ role: 'user', content: prompt }];

    console.log('\nNon-streaming response:');
    const completion = await chatClient.completeChat(messages);
    console.log(completion.choices[0]?.message?.content ?? '(no content returned)');

    console.log('\nStreaming response:');
    for await (const chunk of chatClient.completeStreamingChat(messages)) {
      const t = chunk.choices?.[0]?.delta?.content;
      if (t) process.stdout.write(t);
    }
    process.stdout.write('\n');
  } finally {
    if (model) {
      console.log('\nUnloading model...');
      await model.unload();
    }
  }
}

main().catch((error) => {
  printFriendlyError(error);
  process.exitCode = 1;
});
