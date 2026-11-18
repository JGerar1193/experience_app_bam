import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import type { CallToolResult } from '@modelcontextprotocol/sdk/types.js';
import { z } from 'zod';
import { DemoTransfers } from './demo-transfers';

const identifier = z.string().min(1).max(80);
const money = z.strictObject({ currency: z.enum(['USD', 'EUR', 'COP', 'GTQ']), amount: z.string() });
const quoteSchema = z.strictObject({
  demo: z.literal(true),
  quoteId: z.uuid(),
  sourceWalletId: identifier,
  recipientId: identifier,
  recipientAlias: z.string(),
  recipientName: z.string(),
  debit: money,
  rate: z.strictObject({ numerator: z.string(), denominator: z.string() }).nullable(),
  gross: money,
  conversionFee: money,
  conversionFeePercent: z.enum(['0', '1']),
  net: money,
  issuedAt: z.iso.datetime(),
  expiresAt: z.iso.datetime(),
  rateSource: z.literal('synthetic-demo-not-a-bank'),
  irreversibleAfterConfirmation: z.literal(true),
});
const transferSchema = z.strictObject({
  demo: z.literal(true),
  transferId: z.uuid(),
  transactionNumber: z.string(),
  state: z.literal('CONTABILIZADA'),
  postedAt: z.iso.datetime(),
  quote: quoteSchema,
});
const safeCodes = new Set([
  'NOT_FOUND', 'LIMIT_EXCEEDED', 'DEMO_CAPACITY_REACHED', 'IDEMPOTENCY_CONFLICT',
  'ACCEPTANCE_REQUIRED', 'QUOTE_ALREADY_USED', 'QUOTE_EXPIRED', 'INSUFFICIENT_FUNDS',
  'NON_POSITIVE_NET',
]);

function envelope<Schema extends z.ZodType>(schema: Schema) {
  return z.strictObject({ demo: z.literal(true), mode: z.literal('synthetic-in-memory'), data: schema });
}

function respond(action: () => Record<string, unknown>): CallToolResult {
  try {
    const payload = { demo: true, mode: 'synthetic-in-memory', data: action() };
    return { content: [{ type: 'text', text: JSON.stringify(payload) }], structuredContent: payload };
  } catch (error) {
    const code = error instanceof Error && safeCodes.has(error.message) ? error.message : 'INVALID_REQUEST';
    const payload = { demo: true, code, message: code, retryable: false };
    return { isError: true, content: [{ type: 'text', text: JSON.stringify(payload) }] };
  }
}

export function createDemoMcpServer(service = new DemoTransfers()): McpServer {
  const server = new McpServer({ name: 'synthetic-wallet-transfers', version: '0.1.0' }, {
    instructions: 'Local synthetic demo only. All data resets on process exit. No real money, bank access, authentication, human consent, reservations or accounting ledger. Quote before executing. acceptIrreversible is machine acknowledgement, not human consent.',
  });
  const readAnnotations = { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false };
  server.registerTool('balances_get', {
    description: 'Read Alice synthetic wallet balances. Optional walletId filters the result.',
    inputSchema: z.strictObject({ walletId: identifier.optional() }),
    outputSchema: envelope(z.strictObject({ items: z.array(z.strictObject({
      demo: z.literal(true), walletId: identifier, currency: money.shape.currency,
      posted: z.string(), reserved: z.string(), available: z.string(), asOf: z.iso.datetime(),
    })) })),
    annotations: readAnnotations,
  }, ({ walletId }) => respond(() => ({ items: service.balances(walletId) })));
  server.registerTool('recipients_list', {
    description: 'List four saved synthetic Bob recipients and their aliases.',
    inputSchema: z.strictObject({}),
    outputSchema: envelope(z.strictObject({ items: z.array(z.strictObject({
      recipientId: identifier, alias: z.string(), fullName: z.string(), currency: money.shape.currency,
    })) })),
    annotations: readAnnotations,
  }, () => respond(() => ({ items: service.recipients() })));
  server.registerTool('transfer_quote', {
    description: 'Create a synthetic quote valid for 60 seconds. Does not move or reserve funds. Amount is a decimal string; limit USD 200 equivalent.',
    inputSchema: z.strictObject({
      sourceWalletId: identifier,
      recipientId: identifier,
      sourceAmount: z.string().max(21).regex(/^(0|[1-9]\d{0,17})\.\d{2}$/),
      idempotencyKey: z.uuid(),
    }),
    outputSchema: envelope(quoteSchema),
    annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false },
  }, (input) => respond(() => ({ ...service.quote(input) })));
  server.registerTool('transfer_execute', {
    description: 'Execute a synthetic quote once in memory. acceptIrreversible is a demo machine acknowledgement, NOT verified human consent. Retry identical parameters with the same idempotencyKey.',
    inputSchema: z.strictObject({ quoteId: z.uuid(), idempotencyKey: z.uuid(), acceptIrreversible: z.literal(true) }),
    outputSchema: envelope(transferSchema),
    annotations: { readOnlyHint: false, destructiveHint: true, idempotentHint: true, openWorldHint: false },
  }, (input) => respond(() => ({ ...service.execute(input) })));
  for (const name of ['transfer_get', 'receipt_get'] as const) {
    server.registerTool(name, {
      description: name === 'receipt_get' ? 'Read an immutable synthetic receipt, not a bank receipt.' : 'Read a synthetic transfer result by ID.',
      inputSchema: z.strictObject({ transferId: z.uuid() }),
      outputSchema: envelope(transferSchema),
      annotations: readAnnotations,
    }, ({ transferId }) => respond(() => ({ ...service.transfer(transferId) })));
  }
  return server;
}