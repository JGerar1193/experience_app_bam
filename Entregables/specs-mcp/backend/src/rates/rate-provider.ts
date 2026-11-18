import type { RateSnapshot } from './rate-snapshot';

export interface RateProvider {
  snapshot(): Promise<RateSnapshot>;
}