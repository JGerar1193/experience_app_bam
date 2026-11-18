import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { createDemoMcpServer } from './server';

async function main(): Promise<void> {
  if (!process.argv.includes('--demo')) throw new Error('Explicit --demo flag required. No production mode exists.');
  const server = createDemoMcpServer();
  for (const signal of ['SIGINT', 'SIGTERM'] as const) {
    process.once(signal, () => { void server.close().then(() => process.exit(0)); });
  }
  await server.connect(new StdioServerTransport());
  console.error('MCP synthetic demo ready on stdio. No real money. State resets on exit.');
}

void main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : 'MCP demo startup failed.');
  process.exitCode = 1;
});