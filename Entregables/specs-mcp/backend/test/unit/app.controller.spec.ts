import { describe, expect, it } from '@jest/globals';
import { AppController } from '../../src/app.controller';

describe('TEST-008 application health', () => {
  it('reports the process as available', () => {
    expect(new AppController().getHealth()).toEqual({ status: 'ok' });
  });
});