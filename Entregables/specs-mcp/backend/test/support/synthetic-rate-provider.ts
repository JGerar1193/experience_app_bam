import { supportedCurrencies, type Currency } from '../../src/money/money';
import type { RateProvider } from '../../src/rates/rate-provider';
import {
  RateSnapshot,
  type ExactRate,
  type RateMatrix,
  type RateSnapshotData,
} from '../../src/rates/rate-snapshot';

export function createSyntheticRateData(): RateSnapshotData {
  const syntheticReferences: Record<Currency, bigint> = {
    USD: 12000n,
    EUR: 12800n,
    COP: 3n,
    GTQ: 1600n,
  };
  const rates = Object.fromEntries(supportedCurrencies.map((source) => [
    source,
    Object.fromEntries(supportedCurrencies.map((destination) => [
      destination,
      {
        numerator: syntheticReferences[source].toString(),
        denominator: syntheticReferences[destination].toString(),
      } satisfies ExactRate,
    ])),
  ])) as RateMatrix;

  return {
    id: '22222222-2222-4222-8222-222222222222',
    version: 'synthetic-snapshot-v1',
    source: 'synthetic-fixture-not-a-bank-rate',
    policyVersion: 'synthetic-gtq-reference-v1',
    asOf: '2026-10-29T12:00:00Z',
    validUntil: '2026-10-29T13:00:00Z',
    rates,
  };
}

export class SyntheticRateProvider implements RateProvider {
  constructor(private readonly clock: () => Date) {}

  async snapshot(): Promise<RateSnapshot> {
    return RateSnapshot.parse(createSyntheticRateData(), this.clock());
  }
}