import Ajv2020 from 'ajv/dist/2020';
import addFormats from 'ajv-formats';
import { supportedCurrencies, type Currency } from '../money/money';

export interface ExactRate {
  readonly numerator: string;
  readonly denominator: string;
}

export type RateMatrix = Readonly<Record<Currency, Readonly<Record<Currency, ExactRate>>>>;

export interface RateSnapshotData {
  readonly id: string;
  readonly version: string;
  readonly source: string;
  readonly policyVersion: string;
  readonly asOf: string;
  readonly validUntil: string;
  readonly rates: RateMatrix;
}

export type RateSnapshotErrorCode =
  | 'INVALID_SNAPSHOT'
  | 'INVALID_TIME'
  | 'FUTURE_SNAPSHOT'
  | 'STALE_SNAPSHOT'
  | 'INVALID_IDENTITY_RATE'
  | 'UNSUPPORTED_CURRENCY';

export class RateSnapshotError extends Error {
  constructor(readonly code: RateSnapshotErrorCode) {
    super(code);
    this.name = 'RateSnapshotError';
  }
}

const ajv = new Ajv2020({
  strict: true,
  coerceTypes: false,
  useDefaults: false,
  removeAdditional: false,
});
addFormats(ajv);

const validateSnapshot = ajv.compile<RateSnapshotData>({
  type: 'object',
  additionalProperties: false,
  required: ['id', 'version', 'source', 'policyVersion', 'asOf', 'validUntil', 'rates'],
  properties: {
    id: { type: 'string', format: 'uuid' },
    version: { $ref: '#/$defs/Label' },
    source: { $ref: '#/$defs/Label' },
    policyVersion: { $ref: '#/$defs/Label' },
    asOf: { $ref: '#/$defs/Time' },
    validUntil: { $ref: '#/$defs/Time' },
    rates: {
      type: 'object',
      additionalProperties: false,
      required: [...supportedCurrencies],
      properties: Object.fromEntries(supportedCurrencies.map((currency) => [
        currency, { $ref: '#/$defs/Row' },
      ])),
    },
  },
  $defs: {
    Label: { type: 'string', minLength: 1, maxLength: 128, pattern: String.raw`\S` },
    Time: { type: 'string', format: 'date-time', pattern: 'Z$' },
    PositiveInteger: {
      type: 'string',
      minLength: 1,
      maxLength: 64,
      pattern: String.raw`^[1-9]\d{0,63}$`,
      not: { pattern: String.raw`\s` },
    },
    Rate: {
      type: 'object',
      additionalProperties: false,
      required: ['numerator', 'denominator'],
      properties: {
        numerator: { $ref: '#/$defs/PositiveInteger' },
        denominator: { $ref: '#/$defs/PositiveInteger' },
      },
    },
    Row: {
      type: 'object',
      additionalProperties: false,
      required: [...supportedCurrencies],
      properties: Object.fromEntries(supportedCurrencies.map((currency) => [
        currency, { $ref: '#/$defs/Rate' },
      ])),
    },
  },
});

const currencySet = new Set<Currency>(supportedCurrencies);

function assertCurrent(data: RateSnapshotData, now: Date): void {
  const timestamp = now instanceof Date ? now.getTime() : Number.NaN;
  if (!Number.isFinite(timestamp)) {
    throw new RateSnapshotError('INVALID_TIME');
  }
  if (timestamp < Date.parse(data.asOf)) {
    throw new RateSnapshotError('FUTURE_SNAPSHOT');
  }
  if (timestamp >= Date.parse(data.validUntil)) {
    throw new RateSnapshotError('STALE_SNAPSHOT');
  }
}

export class RateSnapshot {
  private constructor(readonly data: RateSnapshotData) {
    Object.freeze(this);
  }

  static parse(input: unknown, now: Date): RateSnapshot {
    if (!validateSnapshot(input)) {
      throw new RateSnapshotError('INVALID_SNAPSHOT');
    }
    const asOf = Date.parse(input.asOf);
    const validUntil = Date.parse(input.validUntil);
    if (!Number.isFinite(asOf) || !Number.isFinite(validUntil) || asOf >= validUntil) {
      throw new RateSnapshotError('INVALID_SNAPSHOT');
    }
    for (const currency of supportedCurrencies) {
      const identity = input.rates[currency][currency];
      if (BigInt(identity.numerator) !== BigInt(identity.denominator)) {
        throw new RateSnapshotError('INVALID_IDENTITY_RATE');
      }
    }
    assertCurrent(input, now);

    const data = structuredClone(input);
    for (const source of supportedCurrencies) {
      for (const destination of supportedCurrencies) {
        Object.freeze(data.rates[source][destination]);
      }
      Object.freeze(data.rates[source]);
    }
    Object.freeze(data.rates);
    Object.freeze(data);
    return new RateSnapshot(data);
  }

  getRate(source: Currency, destination: Currency, now: Date): ExactRate {
    if (!currencySet.has(source) || !currencySet.has(destination)) {
      throw new RateSnapshotError('UNSUPPORTED_CURRENCY');
    }
    assertCurrent(this.data, now);
    return this.data.rates[source][destination];
  }
}