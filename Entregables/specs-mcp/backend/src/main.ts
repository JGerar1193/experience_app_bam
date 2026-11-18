import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap(): Promise<void> {
  const application = await NestFactory.create(AppModule);
  application.enableShutdownHooks();
  await application.listen(process.env.PORT ?? 3000, '127.0.0.1');
}

bootstrap().catch(() => {
  process.stderr.write('Application startup failed.\n');
  process.exitCode = 1;
});