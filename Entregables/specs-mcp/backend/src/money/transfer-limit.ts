import type { Money } from './money';
import type { RateSnapshot } from '../rates/rate-snapshot';

const usdLimitMinorUnits = 20000n;

export function isWithinUsdTransferLimit(
  amount: Money,
  snapshot: RateSnapshot | undefined,
  now: Date,
): boolean {
  if (amount.currency === 'USD') {
    return amount.minorUnits <= usdLimitMinorUnits;
  }

  if (!snapshot) {
    throw new RangeError('A rate snapshot is required to value non-USD amounts.');
  }

  const rate = snapshot.getRate(amount.currency, 'USD', now);
  return amount.minorUnits * BigInt(rate.numerator)
    <= usdLimitMinorUnits * BigInt(rate.denominator);
}