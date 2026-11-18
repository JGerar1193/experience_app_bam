import { describe, expect, it } from '@jest/globals';
import { DemoTransfers } from '../../src/mcp/demo-transfers';

const quoteRequest = {
  sourceWalletId: 'demo-alice-usd',
  recipientId: 'demo-bob-cop',
  sourceAmount: '10.00',
  idempotencyKey: '11111111-1111-4111-8111-111111111111',
};
const executeKey = '22222222-2222-4222-8222-222222222222';

describe('MCP synthetic demo', () => {
  it('quotes without moving funds and executes an exact conversion once', () => {
    const service = new DemoTransfers();
    const quote = service.quote(quoteRequest);
    expect(quote.gross.amount).toBe('40000.00');
    expect(quote.conversionFee.amount).toBe('400.00');
    expect(quote.net.amount).toBe('39600.00');
    expect(service.balances()[0]?.available).toBe('1000.00');
    const command = { quoteId: quote.quoteId, idempotencyKey: executeKey, acceptIrreversible: true as const };
    const transfer = service.execute(command);
    expect(service.execute(command)).toEqual(transfer);
    expect(service.balances()[0]?.available).toBe('990.00');
    expect(service.receipt(transfer.transferId)).toEqual(transfer);
    expect(transfer.state).toBe('CONTABILIZADA');
    expect(transfer.demo).toBe(true);
    expect(transfer.quote.net.amount).toBe('39600.00');
    expect(() => service.execute({ ...command, idempotencyKey: quoteRequest.idempotencyKey })).toThrow('QUOTE_ALREADY_USED');
  });

  it('enforces expiry at exactly sixty seconds, without debiting', () => {
    let now = Date.parse('2026-11-05T12:00:00Z');
    const service = new DemoTransfers(() => new Date(now));
    const quote = service.quote(quoteRequest);
    now += 60_000;
    expect(() => service.execute({ quoteId: quote.quoteId, idempotencyKey: executeKey, acceptIrreversible: true })).toThrow('QUOTE_EXPIRED');
    expect(service.balances()[0]?.available).toBe('1000.00');
  });

  it('rejects changed parameters with the same key and amounts above USD 200', () => {
    const service = new DemoTransfers();
    const quote = service.quote(quoteRequest);
    expect(service.quote(quoteRequest)).toEqual(quote);
    expect(() => service.quote({ ...quoteRequest, sourceAmount: '11.00' })).toThrow('IDEMPOTENCY_CONFLICT');
    expect(() => service.quote({ ...quoteRequest, sourceAmount: '200.01', idempotencyKey: executeKey })).toThrow('LIMIT_EXCEEDED');
    expect(() => service.quote({ ...quoteRequest, sourceAmount: '0.00' })).toThrow();
    expect(() => service.quote({ ...quoteRequest, sourceAmount: '1.001' })).toThrow();
  });

  it('does not debit on insufficient funds and does not expose mutable internal results', () => {
    const service = new DemoTransfers();
    for (let index = 0; index < 5; index++) {
      const quote = service.quote({ ...quoteRequest, sourceAmount: '200.00', idempotencyKey: `quote-${index}` });
      service.execute({ quoteId: quote.quoteId, idempotencyKey: `execute-${index}`, acceptIrreversible: true });
    }
    const quote = service.quote(quoteRequest);
    quote.net.amount = '999999.00';
    expect(() => service.execute({ quoteId: quote.quoteId, idempotencyKey: executeKey, acceptIrreversible: true })).toThrow('INSUFFICIENT_FUNDS');
    expect(service.balances()[0]?.available).toBe('0.00');
  });

  it('supports all sixteen pairs and same currency without a fee', () => {
    for (const source of ['usd', 'eur', 'cop', 'gtq']) {
      for (const destination of ['usd', 'eur', 'cop', 'gtq']) {
        const service = new DemoTransfers();
        const quote = service.quote({
          sourceWalletId: `demo-alice-${source}`,
          recipientId: `demo-bob-${destination}`,
          sourceAmount: source === 'cop' ? '10000.00' : '100.00',
          idempotencyKey: quoteRequest.idempotencyKey,
        });
        const transfer = service.execute({ quoteId: quote.quoteId, idempotencyKey: executeKey, acceptIrreversible: true });
        expect(transfer.quote.net.amount).toBe(quote.net.amount);
        if (source === destination) expect(quote.conversionFee.amount).toBe('0.00');
      }
    }
  });
});