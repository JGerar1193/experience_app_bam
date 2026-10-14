import type { ErrorRequestHandler } from 'express';
import { ZodError } from 'zod';
import { HttpError } from './http-error';

export const errorHandler: ErrorRequestHandler = (error: unknown, _req, res, next) => {
  if (res.headersSent) {
    next(error);
    return;
  }

  if (error instanceof HttpError) {
    res.status(error.statusCode).json({
      error: { message: error.message, ...(error.details ? { details: error.details } : {}) },
    });
    return;
  }

  if (error instanceof ZodError) {
    res.status(400).json({
      error: { message: 'La solicitud contiene datos invalidos.', details: error.issues },
    });
    return;
  }

  const databaseError = error as { code?: string };
  if (databaseError.code === '23503') {
    res.status(404).json({ error: { message: 'El usuario indicado no existe.' } });
    return;
  }

  if (databaseError.code === '22P02') {
    res.status(400).json({ error: { message: 'El identificador debe ser un UUID valido.' } });
    return;
  }

  console.error(error);
  res.status(500).json({ error: { message: 'Error interno del servidor.' } });
};
