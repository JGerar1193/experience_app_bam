import { describe, expect, it } from '@jest/globals';
import {
  ContractValidator,
  contractNames,
  type ContractName,
} from '../../src/contracts/contract-validator';

const identifier = '11111111-1111-4111-8111-111111111111';
const timestamp = '2026-10-29T12:00:00Z';
const recipient = {
  recipientId: identifier,
  alias: 'Synthetic recipient',
  fullName: 'Synthetic Account Holder',
  currency: 'COP',
  accountMasked: '****1234',
};
const quoteRequest = {
  sourceWalletId: identifier,
  recipientId: identifier,
  sourceAmount: '10.00',
};
const quote = {
  quoteId: identifier,
  sourceWalletId: identifier,
  sourceAccountMasked: '****5678',
  recipient,
  debit: { currency: 'USD', amount: '10.00' },
  rate: '4000',
  gross: { currency: 'COP', amount: '40000.00' },
  conversionFeePercent: '1',
  conversionFee: { currency: 'COP', amount: '400.00' },
  net: { currency: 'COP', amount: '39600.00' },
  limitUsd: '200.00',
  withinLimit: true,
  issuedAt: timestamp,
  expiresAt: '2026-10-29T12:01:00Z',
  rateSnapshotId: identifier,
  policyVersion: 'synthetic-test-policy',
  irreversibleAfterConfirmation: true,
};
const transfer = {
  transferId: identifier,
  transactionNumber: 'SYNTHETIC-001',
  state: 'CONTABILIZADA',
  quote,
  createdAt: timestamp,
  postedAt: timestamp,
  journalId: identifier,
  reasonCode: null,
};
const errorResponse = {
  code: 'INVALID_REQUEST',
  message: 'Invalid request.',
  correlationId: identifier,
  retryable: false,
};
const validPayloads: Record<ContractName, unknown> = {
  LookupRequest: { accountNumber: '0001234' },
  LookupResponse: {
    lookupId: identifier,
    fullName: 'Synthetic Account Holder',
    currency: 'COP',
    accountMasked: '****1234',
    expiresAt: timestamp,
  },
  RecipientRequest: { lookupId: identifier, alias: 'Synthetic recipient' },
  RecipientResponse: recipient,
  RecipientList: { items: [recipient], nextCursor: null },
  QuoteRequest: quoteRequest,
  QuoteResponse: quote,
  ReserveRequest: { quoteId: identifier },
  ConfirmRequest: { quoteId: identifier, acceptIrreversible: true },
  CancelRequest: { reason: 'USER_ABANDONED' },
  TransferResponse: transfer,
  ReceiptResponse: {
    transactionNumber: 'SYNTHETIC-001',
    transferId: identifier,
    state: 'CONTABILIZADA',
    postedAt: timestamp,
    journalId: identifier,
    quote,
  },
  ErrorResponse: errorResponse,
  OperationResponse: {
    operation: 'transfer-confirm',
    key: identifier,
    httpStatus: 200,
    result: transfer,
  },
};

describe('TEST-009 JSON contracts', () => {
  it.each(contractNames)('accepts %s with all references resolved', (name) => {
    expect(new ContractValidator().validate(name, validPayloads[name])).toEqual({
      valid: true,
    });
  });

  it.each(['rate', 'customerId', 'ownerId', 'conversionFee'])(
    'rejects injected %s without stripping it',
    (field) => {
      const payload = { ...quoteRequest, [field]: 'synthetic-injected-value' };
      const before = structuredClone(payload);
      const result = new ContractValidator().validate('QuoteRequest', payload);
      expect(result.valid).toBe(false);
      expect(payload).toEqual(before);
      if (!result.valid) {
        expect(result.errors.some((error) => error.keyword === 'additionalProperties'))
          .toBe(true);
        expect(JSON.stringify(result.errors)).not.toContain('synthetic-injected-value');
      }
    },
  );

  it.each(['10.001', '10', '1e2', '-1.00', '01.00', 'NaN', 10])(
    'rejects invalid monetary representation %s',
    (sourceAmount) => {
      expect(
        new ContractValidator().validate('QuoteRequest', {
          ...quoteRequest,
          sourceAmount,
        }).valid,
      ).toBe(false);
    },
  );

  it('rejects invalid UUIDs without coercion', () => {
    expect(new ContractValidator().validate('ReserveRequest', { quoteId: 123 }).valid)
      .toBe(false);
    expect(
      new ContractValidator().validate('ReserveRequest', { quoteId: 'not-a-uuid' }).valid,
    ).toBe(false);
  });

  it.each(['2026-02-30T12:00:00Z', 'not-a-date', '2026-10-29'])(
    'rejects invalid date-time %s',
    (issuedAt) => {
      expect(new ContractValidator().validate('QuoteResponse', { ...quote, issuedAt }).valid)
        .toBe(false);
    },
  );

  it.each(['QTZ', 'UYU', 'BTC'])(
    'rejects unsupported currency %s even in nested responses',
    (currency) => {
      expect(
        new ContractValidator().validate('QuoteResponse', {
          ...quote,
          net: { currency, amount: '39600.00' },
        }).valid,
      ).toBe(false);
    },
  );

  it('rejects extra fields in nested objects', () => {
    expect(
      new ContractValidator().validate('QuoteResponse', {
        ...quote,
        recipient: { ...recipient, privateAccountNumber: 'synthetic-private-value' },
      }).valid,
    ).toBe(false);
  });

  it('requires explicit irreversible consent without inserting defaults', () => {
    const payload = { quoteId: identifier };
    expect(new ContractValidator().validate('ConfirmRequest', payload).valid).toBe(false);
    expect(payload).toEqual({ quoteId: identifier });
    expect(
      new ContractValidator().validate('ConfirmRequest', {
        quoteId: identifier,
        acceptIrreversible: false,
      }).valid,
    ).toBe(false);
  });

  it('rejects absent and non-object request bodies', () => {
    for (const payload of [undefined, null, [], 'invalid']) {
      expect(new ContractValidator().validate('QuoteRequest', payload).valid).toBe(false);
    }
  });

  it('accepts the documented nulls and an empty cancel body', () => {
    const validator = new ContractValidator();
    expect(validator.validate('CancelRequest', {})).toEqual({ valid: true });
    expect(
      validator.validate('TransferResponse', {
        ...transfer,
        state: 'RESERVADA',
        postedAt: null,
        journalId: null,
      }),
    ).toEqual({ valid: true });
    expect(validator.validate('QuoteResponse', { ...quote, rateSnapshotId: null }))
      .toEqual({ valid: true });
  });

  it('resolves every result alternative in an operation response', () => {
    const validator = new ContractValidator();
    for (const name of [
      'LookupResponse',
      'RecipientResponse',
      'QuoteResponse',
      'TransferResponse',
      'ErrorResponse',
    ] as const) {
      expect(
        validator.validate('OperationResponse', {
          operation: 'transfer-confirm',
          key: identifier,
          httpStatus: 200,
          result: validPayloads[name],
        }),
      ).toEqual({ valid: true });
    }
  });

  it('copies errors so subsequent validation cannot overwrite them', () => {
    const validator = new ContractValidator();
    const result = validator.validate('ReserveRequest', { quoteId: 'invalid' });
    expect(result.valid).toBe(false);
    if (!result.valid) {
      const before = structuredClone(result.errors);
      validator.validate('ReserveRequest', { quoteId: identifier });
      expect(result.errors).toEqual(before);
    }
  });

  it('leaves cross-field monetary and temporal rules to the domain', () => {
    const validator = new ContractValidator();
    expect(
      validator.validate('QuoteRequest', { ...quoteRequest, sourceAmount: '0.00' }),
    ).toEqual({ valid: true });
    expect(
      validator.validate('QuoteResponse', {
        ...quote,
        rate: '0',
        expiresAt: '2026-10-28T12:00:00Z',
        conversionFee: { currency: 'COP', amount: '0.10' },
      }),
    ).toEqual({ valid: true });
  });
});