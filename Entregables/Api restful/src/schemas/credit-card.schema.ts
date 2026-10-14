import { z } from 'zod';

export const createCreditCardSchema = z.object({
  userId: z.string().uuid(),
  creditLimit: z.number().positive(),
  status: z.enum(['active', 'blocked']).optional(),
}).strict();

export const updateCreditCardSchema = z.object({
  creditLimit: z.number().positive().optional(),
  status: z.enum(['active', 'blocked']).optional(),
}).strict().refine((body) => Object.keys(body).length > 0, {
  message: 'Debes enviar creditLimit o status para actualizar.',
});

export type CreateCreditCardInput = z.infer<typeof createCreditCardSchema>;
export type UpdateCreditCardInput = z.infer<typeof updateCreditCardSchema>;
