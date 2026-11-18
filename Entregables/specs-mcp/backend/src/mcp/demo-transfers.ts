import { randomUUID } from 'node:crypto';
import { calculateConversion } from '../money/conversion';
import { Money, supportedCurrencies, type Currency, type MoneyPayload } from '../money/money';

export interface DemoQuoteInput {
  sourceWalletId: string;
  recipientId: string;
  sourceAmount: string;
  idempotencyKey: string;
}

export interface DemoExecuteInput {
  quoteId: string;
  idempotencyKey: string;
  acceptIrreversible: true;
}

interface DemoQuote {
  demo: true;
  quoteId: string;
  sourceWalletId: string;
  recipientId: string;
  recipientAlias: string;
  recipientName: string;
  debit: MoneyPayload;
  rate: { numerator: string; denominator: string } | null;
  gross: MoneyPayload;
  conversionFee: MoneyPayload;
  conversionFeePercent: '0' | '1';
  net: MoneyPayload;
  issuedAt: string;
  expiresAt: string;
  rateSource: 'synthetic-demo-not-a-bank';
  irreversibleAfterConfirmation: true;
}

interface DemoTransfer {
  demo: true;
  transferId: string;
  transactionNumber: string;
  state: 'CONTABILIZADA';
  postedAt: string;
  quote: DemoQuote;
}

interface IdempotentResult {
  fingerprint: string;
  result: DemoQuote | DemoTransfer;
}

const references: Record<Currency, bigint> = { USD: 12000n, EUR: 12800n, COP: 3n, GTQ: 1600n };
const openingBalances: Record<Currency, string> = {
  USD: '1000.00', EUR: '1000.00', COP: '1000000.00', GTQ: '10000.00',
};

export class DemoTransfers {
  private readonly funds = new Map<string, Money>();
  private readonly quotes = new Map<string, DemoQuote>();
  private readonly transfers = new Map<string, DemoTransfer>();
  private readonly usedQuotes = new Set<string>();
  private readonly operations = new Map<string, IdempotentResult>();

  constructor(private readonly clock: () => Date = () => new Date()) {
    for (const currency of supportedCurrencies) {
      this.funds.set(`demo-alice-${currency.toLowerCase()}`, Money.fromDecimal(currency, openingBalances[currency]));
      this.funds.set(`demo-bob-${currency.toLowerCase()}`, Money.fromDecimal(currency, '0.00'));
    }
  }

  balances(walletId?: string) {
    if (walletId && !walletId.startsWith('demo-alice-')) throw new Error('NOT_FOUND');
    const wallets = [...this.funds.entries()].filter(([identifier]) => identifier.startsWith('demo-alice-') && (!walletId || identifier === walletId));
    if (!wallets.length) throw new Error('NOT_FOUND');
    return wallets.map(([identifier, balance]) => ({
      demo: true,
      walletId: identifier,
      currency: balance.currency,
      posted: balance.toDecimal(),
      reserved: '0.00',
      available: balance.toDecimal(),
      asOf: this.clock().toISOString(),
    }));
  }

  recipients() {
    return supportedCurrencies.map((currency) => ({
      recipientId: `demo-bob-${currency.toLowerCase()}`,
      alias: `bob-${currency.toLowerCase()}`,
      fullName: 'Bob Demo (synthetic)',
      currency,
    }));
  }

  quote(input: DemoQuoteInput): DemoQuote {
    const fingerprint = JSON.stringify([input.sourceWalletId, input.recipientId, input.sourceAmount]);
    const previous = this.recover<DemoQuote>('quote', input.idempotencyKey, fingerprint);
    if (previous) return previous;
    if (this.quotes.size >= 1000) throw new Error('DEMO_CAPACITY_REACHED');
    const source = this.funds.get(input.sourceWalletId);
    const recipient = this.recipients().find((candidate) => candidate.recipientId === input.recipientId);
    if (!source || !input.sourceWalletId.startsWith('demo-alice-') || !recipient) throw new Error('NOT_FOUND');
    const amount = Money.fromTransferAmount(source.currency, input.sourceAmount);
    if (amount.minorUnits * references[amount.currency] > 20000n * references.USD) throw new Error('LIMIT_EXCEEDED');
    const rate = {
      numerator: references[source.currency].toString(),
      denominator: references[recipient.currency].toString(),
    };
    const conversion = calculateConversion(amount, recipient.currency, rate);
    const now = this.clock();
    const quote: DemoQuote = {
      demo: true,
      quoteId: randomUUID(),
      sourceWalletId: input.sourceWalletId,
      recipientId: input.recipientId,
      recipientAlias: recipient.alias,
      recipientName: recipient.fullName,
      debit: amount.toJSON(),
      rate: conversion.rate,
      gross: conversion.gross.toJSON(),
      conversionFee: conversion.conversionFee.toJSON(),
      conversionFeePercent: source.currency === recipient.currency ? '0' : '1',
      net: conversion.net.toJSON(),
      issuedAt: now.toISOString(),
      expiresAt: new Date(now.getTime() + 60_000).toISOString(),
      rateSource: 'synthetic-demo-not-a-bank',
      irreversibleAfterConfirmation: true,
    };
    this.quotes.set(quote.quoteId, quote);
    this.save('quote', input.idempotencyKey, fingerprint, quote);
    return structuredClone(quote);
  }

  execute(input: DemoExecuteInput): DemoTransfer {
    const fingerprint = JSON.stringify([input.quoteId, input.acceptIrreversible]);
    const previous = this.recover<DemoTransfer>('execute', input.idempotencyKey, fingerprint);
    if (previous) return previous;
    if (input.acceptIrreversible !== true) throw new Error('ACCEPTANCE_REQUIRED');
    const quote = this.quotes.get(input.quoteId);
    if (!quote) throw new Error('NOT_FOUND');
    if (this.usedQuotes.has(quote.quoteId)) throw new Error('QUOTE_ALREADY_USED');
    const now = this.clock();
    if (now.getTime() >= Date.parse(quote.expiresAt)) throw new Error('QUOTE_EXPIRED');
    const source = this.funds.get(quote.sourceWalletId)!;
    const destination = this.funds.get(quote.recipientId)!;
    const debit = Money.fromDecimal(quote.debit.currency, quote.debit.amount);
    const net = Money.fromDecimal(quote.net.currency, quote.net.amount);
    if (source.minorUnits < debit.minorUnits) throw new Error('INSUFFICIENT_FUNDS');
    const sourceAfter = Money.fromMinorUnits(source.currency, source.minorUnits - debit.minorUnits);
    const destinationAfter = Money.fromMinorUnits(destination.currency, destination.minorUnits + net.minorUnits);
    const transfer: DemoTransfer = {
      demo: true,
      transferId: randomUUID(),
      transactionNumber: `DEMO-${this.transfers.size + 1}`,
      state: 'CONTABILIZADA',
      postedAt: now.toISOString(),
      quote: structuredClone(quote),
    };
    this.funds.set(quote.sourceWalletId, sourceAfter);
    this.funds.set(quote.recipientId, destinationAfter);
    this.usedQuotes.add(quote.quoteId);
    this.transfers.set(transfer.transferId, transfer);
    this.save('execute', input.idempotencyKey, fingerprint, transfer);
    return structuredClone(transfer);
  }

  transfer(transferId: string): DemoTransfer {
    const result = this.transfers.get(transferId);
    if (!result) throw new Error('NOT_FOUND');
    return structuredClone(result);
  }

  receipt(transferId: string): DemoTransfer {
    return this.transfer(transferId);
  }

  private recover<Result extends DemoQuote | DemoTransfer>(operation: string, key: string, fingerprint: string): Result | undefined {
    const previous = this.operations.get(`${operation}:${key}`);
    if (!previous) return undefined;
    if (previous.fingerprint !== fingerprint) throw new Error('IDEMPOTENCY_CONFLICT');
    return structuredClone(previous.result) as Result;
  }

  private save(operation: string, key: string, fingerprint: string, result: DemoQuote | DemoTransfer): void {
    this.operations.set(`${operation}:${key}`, { fingerprint, result: structuredClone(result) });
  }
}