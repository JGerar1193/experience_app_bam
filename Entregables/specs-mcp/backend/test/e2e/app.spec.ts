import { afterAll, beforeAll, describe, it } from '@jest/globals';
import type { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../../src/app.module';

describe('TEST-008 NestJS HTTP bootstrap', () => {
  let application: INestApplication | undefined;

  beforeAll(async () => {
    const testingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    application = testingModule.createNestApplication();
    await application.init();
  });

  afterAll(async () => {
    await application?.close();
  });

  it('returns a health response without claiming database readiness', async () => {
    await request(application!.getHttpServer())
      .get('/health')
      .expect(200)
      .expect({ status: 'ok' });
  });
});