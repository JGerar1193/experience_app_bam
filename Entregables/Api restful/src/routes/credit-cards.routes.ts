import { Router } from 'express';
import {
  createCreditCard,
  deleteCreditCard,
  getCreditCard,
  listActiveCreditCards,
  updateCreditCard,
} from '../controllers/credit-cards.controller';

export const creditCardsRouter = Router();

creditCardsRouter.get('/', listActiveCreditCards);
creditCardsRouter.post('/', createCreditCard);
creditCardsRouter.get('/:id', getCreditCard);
creditCardsRouter.patch('/:id', updateCreditCard);
creditCardsRouter.delete('/:id', deleteCreditCard);
