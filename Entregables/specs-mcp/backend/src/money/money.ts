export const supportedCurrencies = ['USD', 'EUR', 'COP', 'GTQ'] as const;
export type Currency = (typeof supportedCurrencies)[number];

export interface MoneyPayload {
  currency: Currency;
  amount: string;
}

const maximumMinorUnits = 9223372036854775807n;
const minorUnitsPerMajorUnit = 100n;
const decimalPattern = /^(?:0|[1-9]\d{0,17})\.\d{2}$/;
const minorUnitsPattern = /^(?:0|[1-9]\d{0,18})$/;

export class Money {
  private constructor(
    readonly currency: Currency,
    readonly minorUnits: bigint,
  ) {
    if (minorUnits < 0n) {
      throw new RangeError('Money must be nonnegative.');
    }
    if (minorUnits > maximumMinorUnits) {
      throw new RangeError('Amount exceeds PostgreSQL BIGINT storage capacity.');
    }
    Object.freeze(this);
  }

  static fromDecimal(currency: unknown, amount: unknown): Money {
    const validatedCurrency = Money.validateCurrency(currency);
    const match = typeof amount === 'string' ? decimalPattern.exec(amount) : null;
    if (typeof amount !== 'string' || match?.[0] !== amount) {
      throw new TypeError('Expected a canonical decimal string with two decimal places.');
    }
    return new Money(validatedCurrency, BigInt(amount.replace('.', '')));
  }

  static fromTransferAmount(currency: unknown, amount: unknown): Money {
    const money = Money.fromDecimal(currency, amount);
    if (money.minorUnits === 0n) {
      throw new RangeError('Transfer amount must be positive.');
    }
    return money;
  }

  static fromMinorUnits(currency: unknown, minorUnits: unknown): Money {
    const validatedCurrency = Money.validateCurrency(currency);
    if (typeof minorUnits === 'bigint') {
      return new Money(validatedCurrency, minorUnits);
    }
    const match = typeof minorUnits === 'string'
      ? minorUnitsPattern.exec(minorUnits)
      : null;
    if (typeof minorUnits !== 'string' || match?.[0] !== minorUnits) {
      throw new TypeError('Expected bigint or a canonical integer string for minor units.');
    }
    return new Money(validatedCurrency, BigInt(minorUnits));
  }

  toDecimal(): string {
    const whole = this.minorUnits / minorUnitsPerMajorUnit;
    const fraction = (this.minorUnits % minorUnitsPerMajorUnit).toString().padStart(2, '0');
    return `${whole.toString()}.${fraction}`;
  }

  toMinorUnits(): string {
    return this.minorUnits.toString();
  }

  toJSON(): MoneyPayload {
    return { currency: this.currency, amount: this.toDecimal() };
  }

  private static validateCurrency(currency: unknown): Currency {
    const supported = supportedCurrencies.find((candidate) => candidate === currency);
    if (!supported) {
      throw new RangeError('Unsupported currency.');
    }
    return supported;
  }
}