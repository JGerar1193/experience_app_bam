import { randomUUID } from 'node:crypto';
import { resolve } from 'node:path';
import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StdioClientTransport } from '@modelcontextprotocol/sdk/client/stdio.js';
import type { CallToolResult } from '@modelcontextprotocol/sdk/types.js';
import { describe, expect, it } from '@jest/globals';

describe('MCP stdio synthetic demo', () => {
  it('initializes, lists tools, quotes, executes, retries and reads receipt through a real subprocess', async () => {
    const client = new Client({ name: 'demo-smoke-test', version: '0.1.0' });
    const transport = new StdioClientTransport({
      command: process.execPath,
      args: [resolve(__dirname, '../../src/mcp/main.js'), '--demo'],
      stderr: 'pipe',
    });
    try {
      await client.connect(transport);
      const tools = await client.listTools();
      expect(tools.tools.map((tool) => tool.name).sort()).toEqual([
        'balances_get', 'receipt_get', 'recipients_list', 'transfer_execute', 'transfer_get', 'transfer_quote',
      ]);
      expect(tools.tools.every((tool) => tool.inputSchema.additionalProperties === false)).toBe(true);
      const call = async (name: string, args: Record<string, unknown> = {}): Promise<CallToolResult> =>
        await client.callTool({ name, arguments: args }) as CallToolResult;
      const before = await call('balances_get');
      expect(before.isError).not.toBe(true);
      expect(before.structuredContent).toMatchObject({ demo: true, data: { items: [{ available: '1000.00' }, {}, {}, {}] } });
      const recipients = await call('recipients_list');
      expect(recipients.isError).not.toBe(true);
      const quote = await call('transfer_quote', {
        sourceWalletId: 'demo-alice-usd', recipientId: 'demo-bob-cop',
        sourceAmount: '10.00', idempotencyKey: randomUUID(),
      });
      expect(quote.isError).not.toBe(true);
      const quoteData = quote.structuredContent?.data as Record<string, unknown>;
      expect(quoteData).toMatchObject({ gross: { amount: '40000.00' }, net: { amount: '39600.00' } });
      const command = { quoteId: quoteData.quoteId, idempotencyKey: randomUUID(), acceptIrreversible: true };
      const executed = await call('transfer_execute', command);
      expect(executed.isError).not.toBe(true);
      const executedData = executed.structuredContent?.data as Record<string, unknown>;
      expect(executedData).toMatchObject({ state: 'CONTABILIZADA', demo: true });
      expect(await call('transfer_execute', command)).toEqual(executed);
      expect(await call('receipt_get', { transferId: executedData.transferId })).toEqual(executed);
      expect(await call('transfer_get', { transferId: executedData.transferId })).toEqual(executed);
      const after = await call('balances_get', { walletId: 'demo-alice-usd' });
      expect(after.structuredContent).toMatchObject({ data: { items: [{ available: '990.00' }] } });
      const duplicate = await call('transfer_execute', { ...command, idempotencyKey: randomUUID() });
      expect(duplicate.isError).toBe(true);
      expect(duplicate.content).toMatchObject([{ type: 'text', text: expect.stringContaining('QUOTE_ALREADY_USED') }]);
      for (const invalid of [
        { ...command, actorId: 'another-user' },
        { ...command, acceptIrreversible: false },
        { ...command, idempotencyKey: 'not-a-uuid' },
      ]) {
        expect((await call('transfer_execute', invalid)).isError).toBe(true);
      }
      expect((await call('transfer_quote', {
        sourceWalletId: 'demo-alice-usd', recipientId: 'demo-bob-cop',
        sourceAmount: 10, idempotencyKey: randomUUID(),
      })).isError).toBe(true);
      expect((await call('balances_get', { walletId: 'demo-bob-cop' })).isError).toBe(true);
    } finally {
      await client.close();
      await transport.close();
    }
  });
});