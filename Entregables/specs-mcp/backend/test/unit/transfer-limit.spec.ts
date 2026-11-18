import { describe, expect, it } from '@jest/globals';
import { Money } from '../../src/money/money';
import { isWithinUsdTransferLimit } from '../../src/money/transfer-limit';
import { RateSnapshot } from '../../src/rates/rate-snapshot';
import { createSyntheticRateData } from '../support/synthetic-rate-provider';

const now = (): Date => new Date('2026-10-29T12:15:00Z');

describe('TEST-014 universal USD transfer limit', () => {
  it.each([
    ['199.99', true],
    ['200.00', true],
    ['200.01', false],
  ])('values USD %s without a rate snapshot', (amount, expected) => {
    expect(isWithinUsdTransferLimit(Money.fromTransferAmount('USD', amount), undefined, now()))
      .toBe(expected);
  });

  it.each([
    ['187.50', true],
    ['187.51', false],
  ])('compares EUR %s against the exact normalized USD reference', (amount, expected) => {
    const snapshot = RateSnapshot.parse(createSyntheticRateData(), now());

    expect(snapshot.getRate('EUR', 'USD', now()))
      .toEqual({ numerator: '12800', denominator: '12000' });
    expect(isWithinUsdTransferLimit(Money.fromTransferAmount('EUR', amount), snapshot, now()))
      .toBe(expected);
  });

  it('does not round a periodic equivalent up to the USD limit', () => {
    const data = createSyntheticRateData();
    const snapshot = RateSnapshot.parse({
      ...data,
      rates: {
        ...data.rates,
        EUR: { ...data.rates.EUR, USD: { numerator: '2', denominator: '3' } },
      },
    }, now());

    expect(isWithinUsdTransferLimit(Money.fromTransferAmount('EUR', '300.00'), snapshot, now()))
      .toBe(true);
    expect(isWithinUsdTransferLimit(Money.fromTransferAmount('EUR', '300.01'), snapshot, now()))
      .toBe(false);
  });

  it('requires a current rate snapshot to value non-USD amounts', () => {
    expect(() => isWithinUsdTransferLimit(
      Money.fromTransferAmount('EUR', '1.00'), undefined, now(),
    )).toThrow('rate snapshot is required');
  });
});