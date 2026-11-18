import { Money, type Currency } from './money';
import type { ExactRate } from '../rates/rate-snapshot';

export interface ExactMinorUnits {
  readonly numerator: string;
  readonly denominator: string;
}

export interface ConversionResult {
  readonly rate: ExactRate | null;
  readonly grossExactMinorUnits: ExactMinorUnits;
  readonly gross: Money;
  readonly grossRoundingDifferenceMinorUnits: ExactMinorUnits;
  readonly conversionFeeExactMinorUnits: ExactMinorUnits;
  readonly conversionFee: Money;
  readonly conversionFeeRoundingDifferenceMinorUnits: ExactMinorUnits;
  readonly net: Money;
}

const zero = Object.freeze({ numerator: '0', denominator: '1' });
const positiveIntegerPattern = /^[1-9]\d{0,63}$/;
const minorUnitsPerMajorUnit = 100n;
const feeExactMinorUnitsDenominator = 100n;
const feeBasisPointsDenominator = 10000n;

function greatestCommonDivisor(left: bigint, right: bigint): bigint {
  let dividend = left < 0n ? -left : left;
  let divisor = right;
  while (divisor !== 0n) {
    [dividend, divisor] = [divisor, dividend % divisor];
  }
  return dividend;
}

function exactMinorUnits(numerator: bigint, denominator: bigint): ExactMinorUnits {
  const divisor = greatestCommonDivisor(numerator, denominator);
  return Object.freeze({
    numerator: (numerator / divisor).toString(),
    denominator: (denominator / divisor).toString(),
  });
}

function roundHalfUp(numerator: bigint, denominator: bigint): bigint {
  const quotient = numerator / denominator;
  const remainder = numerator % denominator;
  return remainder * 2n >= denominator ? quotient + 1n : quotient;
}

function validateRate(rate: ExactRate | undefined): asserts rate is ExactRate {
  if (
    !rate
    || !positiveIntegerPattern.test(rate.numerator)
    || !positiveIntegerPattern.test(rate.denominator)
  ) {
    throw new RangeError(rate ? 'INVALID_RATE' : 'RATE_REQUIRED');
  }
}

export function calculateConversion(
  source: Money,
  destinationCurrency: Currency,
  rate?: ExactRate,
): ConversionResult {
  const zeroFee = Money.fromMinorUnits(destinationCurrency, 0n);
  if (source.minorUnits <= 0n) {
    throw new RangeError('INVALID_SOURCE_AMOUNT');
  }

  if (source.currency === destinationCurrency) {
    return Object.freeze({
      rate: null,
      grossExactMinorUnits: exactMinorUnits(source.minorUnits, 1n),
      gross: source,
      grossRoundingDifferenceMinorUnits: zero,
      conversionFeeExactMinorUnits: zero,
      conversionFee: zeroFee,
      conversionFeeRoundingDifferenceMinorUnits: zero,
      net: source,
    });
  }

  validateRate(rate);
  const rateNumerator = BigInt(rate.numerator);
  const rateDenominator = BigInt(rate.denominator);
  const grossExactNumerator = source.minorUnits * rateNumerator;
  const grossMinorUnits = roundHalfUp(grossExactNumerator, rateDenominator);
  const gross = Money.fromMinorUnits(destinationCurrency, grossMinorUnits);
  const feeWholeUnits = (grossMinorUnits + feeBasisPointsDenominator - 1n)
    / feeBasisPointsDenominator;
  const feeMinorUnits = feeWholeUnits * minorUnitsPerMajorUnit;
  const conversionFee = Money.fromMinorUnits(destinationCurrency, feeMinorUnits);
  const netMinorUnits = grossMinorUnits - feeMinorUnits;
  if (netMinorUnits <= 0n) {
    throw new RangeError('NON_POSITIVE_NET');
  }

  const frozenRate = Object.freeze({
    numerator: rate.numerator,
    denominator: rate.denominator,
  });
  return Object.freeze({
    rate: frozenRate,
    grossExactMinorUnits: exactMinorUnits(grossExactNumerator, rateDenominator),
    gross,
    grossRoundingDifferenceMinorUnits: exactMinorUnits(
      grossMinorUnits * rateDenominator - grossExactNumerator,
      rateDenominator,
    ),
    conversionFeeExactMinorUnits: exactMinorUnits(
      grossMinorUnits, feeExactMinorUnitsDenominator,
    ),
    conversionFee,
    conversionFeeRoundingDifferenceMinorUnits: exactMinorUnits(
      feeMinorUnits * feeExactMinorUnitsDenominator - grossMinorUnits,
      feeExactMinorUnitsDenominator,
    ),
    net: Money.fromMinorUnits(destinationCurrency, netMinorUnits),
  });
}