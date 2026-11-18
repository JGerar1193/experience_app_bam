import { describe, expect, it } from '@jest/globals';
import { Money, supportedCurrencies } from '../../src/money/money';
import transferSchema from '../../src/contracts/transfer.schema.json';

const maximumMinorUnits = 9223372036854775807n;

describe('TEST-010 exact monetary value', () => {
  it('parses one cent without binary floating point', () => {
    const money = Money.fromDecimal('USD', '0.01');
    expect(money.currency).toBe('USD');
    expect(money.minorUnits).toBe(1n);
    expect(money.toDecimal()).toBe('0.01');
  });

  it.each(supportedCurrencies)('uses two decimals for %s', (currency) => {
    const money = Money.fromDecimal(currency, '123.45');
    expect(money.minorUnits).toBe(12345n);
    expect(money.toJSON()).toEqual({ currency, amount: '123.45' });
  });

  it('keeps supported currencies aligned with the canonical contract', () => {
    expect([...supportedCurrencies]).toEqual(transferSchema.$defs.Currency.enum);
  });

  it('preserves 200.00 exactly', () => {
    expect(Money.fromTransferAmount('USD', '200.00').minorUnits).toBe(20000n);
  });

  it('allows zero as a stored monetary value but not as a transfer origin', () => {
    expect(Money.fromDecimal('COP', '0.00').toMinorUnits()).toBe('0');
    expect(Money.fromMinorUnits('GTQ', 0n).toDecimal()).toBe('0.00');
    expect(() => Money.fromTransferAmount('USD', '0.00')).toThrow('positive');
  });

  it.each([
    '', '0', '1', '1.0', '1.000', '.01', '1.', '01.00', '00.00',
    '-0.01', '-0.00', '+1.00', '1e2', 'NaN', 'Infinity', '1,00',
    ' 1.00', '1.00 ', '1.00\n', '1.00\r\n',
    1, 0.01, Number.NaN, Number.POSITIVE_INFINITY, null, undefined, {}, [],
  ])('rejects invalid decimal input %p without rounding or coercion', (amount) => {
    expect(() => Money.fromDecimal('USD', amount)).toThrow('decimal');
  });

  it.each(['QTZ', 'UYU', 'BTC', 'usd', '', null, undefined, 1])(
    'rejects unsupported currency %p',
    (currency) => {
      expect(() => Money.fromDecimal(currency, '1.00')).toThrow('currency');
      expect(() => Money.fromMinorUnits(currency, 100n)).toThrow('currency');
    },
  );

  it('preserves cents beyond the safe integer range of Number', () => {
    const money = Money.fromDecimal('EUR', '90071992547409.93');
    expect(money.minorUnits).toBe(9007199254740993n);
    expect(money.toDecimal()).toBe('90071992547409.93');
    expect(money.toMinorUnits()).toBe('9007199254740993');
  });

  it('accepts the exact nonnegative PostgreSQL BIGINT maximum', () => {
    const money = Money.fromDecimal('COP', '92233720368547758.07');
    expect(money.minorUnits).toBe(maximumMinorUnits);
    expect(money.toMinorUnits()).toBe('9223372036854775807');
    expect(Money.fromMinorUnits('COP', maximumMinorUnits).toDecimal())
      .toBe('92233720368547758.07');
  });

  it('rejects amounts exceeding storage capacity by one cent', () => {
    expect(() => Money.fromDecimal('USD', '92233720368547758.08'))
      .toThrow('BIGINT');
    expect(() => Money.fromMinorUnits('USD', maximumMinorUnits + 1n))
      .toThrow('BIGINT');
    expect(() => Money.fromMinorUnits('USD', '9223372036854775808'))
      .toThrow('BIGINT');
  });

  it('rejects excessively long decimal and database strings', () => {
    expect(() => Money.fromDecimal('USD', `${'9'.repeat(1000)}.00`)).toThrow();
    expect(() => Money.fromMinorUnits('USD', '9'.repeat(1000))).toThrow();
  });

  it('accepts PostgreSQL BIGINT strings and bigint without converting through Number', () => {
    expect(Money.fromMinorUnits('GTQ', '20000').toDecimal()).toBe('200.00');
    expect(Money.fromMinorUnits('GTQ', 1n).toDecimal()).toBe('0.01');
    expect(Money.fromMinorUnits('GTQ', '0').toDecimal()).toBe('0.00');
  });

  it.each(['', '-1', '+1', '01', '1.0', '1e2', ' 1', '1\n', 1, null, undefined])(
    'rejects invalid minor-unit input %p',
    (minorUnits) => {
      expect(() => Money.fromMinorUnits('USD', minorUnits)).toThrow();
    },
  );

  it('rejects negative bigint values even when representable by PostgreSQL', () => {
    expect(() => Money.fromMinorUnits('USD', -1n)).toThrow('nonnegative');
    expect(() => Money.fromMinorUnits('USD', -9223372036854775808n))
      .toThrow('nonnegative');
  });

  it.each(supportedCurrencies)('round-trips decimal, database and JSON for %s', (currency) => {
    for (const minorUnits of [
      0n, 1n, 9n, 10n, 99n, 100n, 101n, 20000n,
      9007199254740991n, 9007199254740993n,
      maximumMinorUnits - 1n, maximumMinorUnits,
    ]) {
      const original = Money.fromMinorUnits(currency, minorUnits);
      const restored = Money.fromDecimal(currency, original.toDecimal());
      expect(restored.minorUnits).toBe(minorUnits);
      expect(Money.fromMinorUnits(currency, original.toMinorUnits()).minorUnits)
        .toBe(minorUnits);
      expect(JSON.parse(JSON.stringify(original))).toEqual({
        currency,
        amount: original.toDecimal(),
      });
    }
  });

  it('is immutable at runtime', () => {
    const money = Money.fromDecimal('USD', '1.00');
    expect(Object.isFrozen(money)).toBe(true);
    expect(Reflect.set(money, 'minorUnits', 999n)).toBe(false);
    expect(Reflect.set(money, 'currency', 'EUR')).toBe(false);
    expect(money.toJSON()).toEqual({ currency: 'USD', amount: '1.00' });
  });

  it('leaves USD-equivalent transaction limits to their own domain rule', () => {
    expect(Money.fromTransferAmount('USD', '200.01').toDecimal()).toBe('200.01');
  });
});