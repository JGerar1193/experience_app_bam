import type { RequestHandler } from 'express';
import { pool } from '../db/pool';
import { HttpError } from '../middleware/http-error';
import {
  createCreditCardSchema,
  updateCreditCardSchema,
  type UpdateCreditCardInput,
} from '../schemas/credit-card.schema';

const cardColumns = `
  id,
  user_id AS "userId",
  credit_limit AS "creditLimit",
  status,
  created_at AS "createdAt",
  updated_at AS "updatedAt"
`;

export const listActiveCreditCards: RequestHandler = async (_req, res) => {
  const result = await pool.query(
    `SELECT ${cardColumns}
     FROM credit_cards
     WHERE deleted_at IS NULL AND status = 'active'
     ORDER BY created_at DESC`,
  );
  res.status(200).json(result.rows);
};

export const getCreditCard: RequestHandler<{ id: string }> = async (req, res) => {
  const result = await pool.query(
    `SELECT ${cardColumns}
     FROM credit_cards
     WHERE id = $1 AND deleted_at IS NULL`,
    [req.params.id],
  );
  if (!result.rows[0]) throw new HttpError(404, 'Tarjeta no encontrada.');
  res.status(200).json(result.rows[0]);
};

export const createCreditCard: RequestHandler = async (req, res) => {
  const input = createCreditCardSchema.parse(req.body);
  const result = await pool.query(
    `INSERT INTO credit_cards (user_id, credit_limit, status)
     VALUES ($1, $2, $3)
     RETURNING ${cardColumns}`,
    [input.userId, input.creditLimit, input.status ?? 'active'],
  );
  res.status(201).json(result.rows[0]);
};

export const updateCreditCard: RequestHandler<{ id: string }> = async (req, res) => {
  const input: UpdateCreditCardInput = updateCreditCardSchema.parse(req.body);
  const values: unknown[] = [];
  const assignments: string[] = [];

  if (input.creditLimit !== undefined) {
    values.push(input.creditLimit);
    assignments.push(`credit_limit = $${values.length}`);
  }
  if (input.status !== undefined) {
    values.push(input.status);
    assignments.push(`status = $${values.length}`);
  }

  values.push(req.params.id);
  const result = await pool.query(
    `UPDATE credit_cards
     SET ${assignments.join(', ')}, updated_at = NOW()
     WHERE id = $${values.length} AND deleted_at IS NULL
     RETURNING ${cardColumns}`,
    values,
  );
  if (!result.rows[0]) throw new HttpError(404, 'Tarjeta no encontrada.');
  res.status(200).json(result.rows[0]);
};

export const deleteCreditCard: RequestHandler<{ id: string }> = async (req, res) => {
  const result = await pool.query(
    `UPDATE credit_cards
     SET deleted_at = NOW(), updated_at = NOW()
     WHERE id = $1 AND deleted_at IS NULL`,
    [req.params.id],
  );
  if (result.rowCount === 0) throw new HttpError(404, 'Tarjeta no encontrada.');
  res.status(204).send();
};
