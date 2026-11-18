import { describe, expect, it } from '@jest/globals';
import { calculateConversion } from '../../src/money/conversion';
import { Money, supportedCurrencies } from '../../src/money/money';
import type { ExactRate } from '../../src/rates/rate-snapshot';

describe('TEST-011 exact conversion and commission', () => {
  it.each(supportedCurrencies)('keeps same-currency %s transfers free', (currency) => {
    const source = Money.fromTransferAmount(currency, '25.00');
    const result = calculateConversion(source, currency);

    expect(result.gross.toJSON()).toEqual(source.toJSON());
    expect(result.conversionFee.toDecimal()).toBe('0.00');
    expect(result.net.toJSON()).toEqual(source.toJSON());
    expect(result.rate).toBeNull();
    expect(result.grossExactMinorUnits).toEqual({ numerator: '2500', denominator: '1' });
    expect(result.grossRoundingDifferenceMinorUnits)
      .toEqual({ numerator: '0', denominator: '1' });
    expect(result.conversionFeeExactMinorUnits)
      .toEqual({ numerator: '0', denominator: '1' });
    expect(result.conversionFeeRoundingDifferenceMinorUnits)
      .toEqual({ numerator: '0', denominator: '1' });
  });

  it('rounds a half-cent gross HALF_UP and calculates commission on the rounded gross', () => {
    const rate: ExactRate = { numerator: '20001', denominator: '20000' };
    const result = calculateConversion(Money.fromTransferAmount('USD', '100.00'), 'EUR', rate);

    expect(result.gross.toDecimal()).toBe('100.01');
    expect(result.grossExactMinorUnits).toEqual({ numerator: '20001', denominator: '2' });
    expect(result.grossRoundingDifferenceMinorUnits)
      .toEqual({ numerator: '1', denominator: '2' });
    expect(result.conversionFeeExactMinorUnits)
      .toEqual({ numerator: '10001', denominator: '100' });
    expect(result.conversionFee.toDecimal()).toBe('2.00');
    expect(result.conversionFeeRoundingDifferenceMinorUnits)
      .toEqual({ numerator: '9999', denominator: '100' });
    expect(result.net.toDecimal()).toBe('98.01');
    expect(result.rate).toEqual(rate);
  });

  it.each([
    ['10.00', '1.00', { numerator: '10', denominator: '1' }],
    ['10.10', '1.00', { numerator: '101', denominator: '10' }],
    ['100.00', '1.00', { numerator: '100', denominator: '1' }],
    ['101.00', '2.00', { numerator: '101', denominator: '1' }],
  ])('rounds the 1%% fee up to whole destination units for gross %s', (gross, fee, exactFee) => {
    const result = calculateConversion(
      Money.fromTransferAmount('USD', gross),
      'EUR',
      { numerator: '1', denominator: '1' },
    );

    expect(result.gross.toDecimal()).toBe(gross);
    expect(result.conversionFeeExactMinorUnits).toEqual(exactFee);
    expect(result.conversionFee.toDecimal()).toBe(fee);
    expect(result.net.minorUnits + result.conversionFee.minorUnits).toBe(result.gross.minorUnits);
  });

  it.each(['0.99', '1.00'])('rejects a conversion with gross %s and non-positive net', (gross) => {
    expect(() => calculateConversion(
      Money.fromTransferAmount('USD', gross),
      'EUR',
      { numerator: '1', denominator: '1' },
    )).toThrow('NON_POSITIVE_NET');
  });

  it('accepts a positive net after the minimum whole-unit fee', () => {
    const result = calculateConversion(
      Money.fromTransferAmount('USD', '1.01'),
      'EUR',
      { numerator: '1', denominator: '1' },
    );

    expect(result.conversionFee.toDecimal()).toBe('1.00');
    expect(result.net.toDecimal()).toBe('0.01');
  });

  it('requires a positive exact rate for cross-currency conversions', () => {
    const source = Money.fromTransferAmount('USD', '10.00');

    expect(() => calculateConversion(source, 'EUR')).toThrow('RATE_REQUIRED');
    expect(() => calculateConversion(source, 'EUR', { numerator: '0', denominator: '1' }))
      .toThrow('INVALID_RATE');
    expect(() => calculateConversion(source, 'EUR', { numerator: '1', denominator: '0' }))
      .toThrow('INVALID_RATE');
  });
});