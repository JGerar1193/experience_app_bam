import { describe, expect, it } from '@jest/globals';
import { supportedCurrencies, type Currency } from '../../src/money/money';
import { RateSnapshot } from '../../src/rates/rate-snapshot';
import {
  createSyntheticRateData,
  SyntheticRateProvider,
} from '../support/synthetic-rate-provider';

const now = (): Date => new Date('2026-10-29T12:15:00Z');

describe('TEST-012 normalized rate snapshots', () => {
  it('accepts a complete positive and versioned synthetic snapshot', () => {
    const snapshot = RateSnapshot.parse(createSyntheticRateData(), now());
    expect(snapshot.data.version).toBe('synthetic-snapshot-v1');
    expect(snapshot.data.source).toBe('synthetic-fixture-not-a-bank-rate');
    expect(snapshot.data.policyVersion).toBe('synthetic-gtq-reference-v1');
  });

  it.each(supportedCurrencies.flatMap((source) =>
    supportedCurrencies.map((destination) => [source, destination] as const),
  ))('returns an exact reference for %s/%s', (source, destination) => {
    const data = createSyntheticRateData();
    const snapshot = RateSnapshot.parse(data, now());
    expect(snapshot.getRate(source, destination, now()))
      .toEqual(data.rates[source][destination]);
  });

  it('preserves a periodic EUR/USD reference as an exact ratio', () => {
    const rate = RateSnapshot.parse(createSyntheticRateData(), now())
      .getRate('EUR', 'USD', now());
    expect(rate).toEqual({ numerator: '12800', denominator: '12000' });
    expect(BigInt(rate.numerator) * 15n).toBe(BigInt(rate.denominator) * 16n);
  });

  it.each(['id', 'version', 'source', 'policyVersion', 'asOf', 'validUntil', 'rates'] as const)(
    'rejects a snapshot missing %s',
    (field) => {
      const { [field]: removed, ...incomplete } = createSyntheticRateData();
      expect(removed).toBeDefined();
      expect(() => RateSnapshot.parse(incomplete, now())).toThrow('INVALID_SNAPSHOT');
    },
  );

  it('rejects a missing currency row or pair instead of deriving an inverse', () => {
    const data = createSyntheticRateData();
    const { COP: removedRow, ...withoutCop } = data.rates;
    expect(removedRow).toBeDefined();
    expect(() => RateSnapshot.parse({ ...data, rates: withoutCop }, now()))
      .toThrow('INVALID_SNAPSHOT');
    const { USD: removedPair, ...withoutEurUsd } = data.rates.EUR;
    expect(removedPair).toBeDefined();
    expect(() => RateSnapshot.parse({
      ...data,
      rates: { ...data.rates, EUR: withoutEurUsd },
    }, now())).toThrow('INVALID_SNAPSHOT');
  });

  it.each(['0', '-1', '+1', '01', '1.1', '1e2', '1\n', '9'.repeat(65), 1, null])(
    'rejects invalid rate component %p',
    (component) => {
      const data = createSyntheticRateData();
      for (const field of ['numerator', 'denominator']) {
        expect(() => RateSnapshot.parse({
          ...data,
          rates: {
            ...data.rates,
            USD: {
              ...data.rates.USD,
              EUR: { ...data.rates.USD.EUR, [field]: component },
            },
          },
        }, now())).toThrow('INVALID_SNAPSHOT');
      }
    },
  );

  it.each(['version', 'source', 'policyVersion'])(
    'rejects empty or whitespace-only %s',
    (field) => {
      for (const value of ['', '   ']) {
        expect(() => RateSnapshot.parse({ ...createSyntheticRateData(), [field]: value }, now()))
          .toThrow('INVALID_SNAPSHOT');
      }
    },
  );

  it.each(['2026-02-30T12:00:00Z', 'not-a-time', '2026-10-29', '2026-10-29T12:00:00+00:00'])(
    'rejects malformed or noncanonical UTC time %s',
    (asOf) => {
      expect(() => RateSnapshot.parse({ ...createSyntheticRateData(), asOf }, now()))
        .toThrow('INVALID_SNAPSHOT');
    },
  );

  it('rejects invalid time ordering', () => {
    const data = createSyntheticRateData();
    expect(() => RateSnapshot.parse({ ...data, validUntil: data.asOf }, now()))
      .toThrow('INVALID_SNAPSHOT');
    expect(() => RateSnapshot.parse({ ...data, validUntil: '2026-10-29T11:00:00Z' }, now()))
      .toThrow('INVALID_SNAPSHOT');
  });

  it('requires an authoritative valid clock', () => {
    expect(() => RateSnapshot.parse(createSyntheticRateData(), new Date('invalid')))
      .toThrow('INVALID_TIME');
  });

  it('rejects references from the future', () => {
    expect(() => RateSnapshot.parse(createSyntheticRateData(), new Date('2026-10-29T11:59:59Z')))
      .toThrow('FUTURE_SNAPSHOT');
  });

  it('accepts the asOf boundary but rejects expiration exactly and after it', () => {
    const data = createSyntheticRateData();
    expect(RateSnapshot.parse(data, new Date(data.asOf)).data.id).toBe(data.id);
    expect(() => RateSnapshot.parse(data, new Date(data.validUntil)))
      .toThrow('STALE_SNAPSHOT');
    expect(() => RateSnapshot.parse(data, new Date('2026-10-29T13:00:01Z')))
      .toThrow('STALE_SNAPSHOT');
  });

  it('rechecks freshness on lookup instead of using an expired cached snapshot', () => {
    const snapshot = RateSnapshot.parse(createSyntheticRateData(), now());
    expect(() => snapshot.getRate('USD', 'EUR', new Date(snapshot.data.validUntil)))
      .toThrow('STALE_SNAPSHOT');
    expect(() => snapshot.getRate('USD', 'EUR', new Date('invalid')))
      .toThrow('INVALID_TIME');
  });

  it('rejects a same-currency rate different from one', () => {
    const data = createSyntheticRateData();
    expect(() => RateSnapshot.parse({
      ...data,
      rates: { ...data.rates, USD: { ...data.rates.USD, USD: { numerator: '2', denominator: '1' } } },
    }, now())).toThrow('INVALID_IDENTITY_RATE');
  });

  it('does not impose reciprocal or GTQ cross rates on normalized commercial pairs', () => {
    const data = createSyntheticRateData();
    const snapshot = RateSnapshot.parse({
      ...data,
      policyVersion: 'synthetic-directional-policy',
      rates: {
        ...data.rates,
        USD: { ...data.rates.USD, EUR: { numerator: '11', denominator: '10' } },
        EUR: { ...data.rates.EUR, USD: { numerator: '9', denominator: '10' } },
      },
    }, now());
    expect(snapshot.getRate('USD', 'EUR', now())).toEqual({ numerator: '11', denominator: '10' });
    expect(snapshot.getRate('EUR', 'USD', now())).toEqual({ numerator: '9', denominator: '10' });
  });

  it('rejects unsupported currency rows and extra rate properties', () => {
    const data = createSyntheticRateData();
    expect(() => RateSnapshot.parse({ ...data, rates: { ...data.rates, QTZ: data.rates.GTQ } }, now()))
      .toThrow('INVALID_SNAPSHOT');
    expect(() => RateSnapshot.parse({
      ...data,
      rates: { ...data.rates, USD: { ...data.rates.USD, EUR: { ...data.rates.USD.EUR, hidden: true } } },
    }, now())).toThrow('INVALID_SNAPSHOT');
  });

  it('rejects unsupported lookup currencies at runtime', () => {
    const snapshot = RateSnapshot.parse(createSyntheticRateData(), now());
    expect(() => snapshot.getRate('QTZ' as Currency, 'USD', now()))
      .toThrow('UNSUPPORTED_CURRENCY');
    expect(() => snapshot.getRate('USD', 'UYU' as Currency, now()))
      .toThrow('UNSUPPORTED_CURRENCY');
  });

  it('defensively copies input and freezes all nested references', () => {
    const data = createSyntheticRateData();
    const snapshot = RateSnapshot.parse(data, now());
    expect(Object.isFrozen(snapshot)).toBe(true);
    expect(Object.isFrozen(snapshot.data)).toBe(true);
    expect(Object.isFrozen(snapshot.data.rates)).toBe(true);
    expect(Object.isFrozen(snapshot.data.rates.USD)).toBe(true);
    expect(Object.isFrozen(snapshot.getRate('USD', 'EUR', now()))).toBe(true);
    expect(Reflect.set(data.rates.USD.EUR, 'numerator', '999')).toBe(true);
    expect(snapshot.getRate('USD', 'EUR', now()).numerator).toBe('12000');
    expect(Reflect.set(snapshot.data.rates.USD.EUR, 'numerator', '999')).toBe(false);
    expect(JSON.parse(JSON.stringify(snapshot.data))).toEqual(createSyntheticRateData());
  });

  it('does not extend reference lifetime or turn it into a 60-second quote', () => {
    const data = createSyntheticRateData();
    const snapshot = RateSnapshot.parse(data, now());
    expect(snapshot.data.validUntil).toBe('2026-10-29T13:00:00Z');
    expect(data).toEqual(createSyntheticRateData());
  });

  it('fulfills the asynchronous provider port using only synthetic data', async () => {
    const provider = new SyntheticRateProvider(now);
    await expect(provider.snapshot()).resolves.toBeInstanceOf(RateSnapshot);
    const expired = new SyntheticRateProvider(() => new Date('2026-10-29T13:00:00Z'));
    await expect(expired.snapshot()).rejects.toThrow('STALE_SNAPSHOT');
  });
});