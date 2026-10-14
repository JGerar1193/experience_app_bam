import express from 'express';
import { errorHandler } from './middleware/error-handler';
import { creditCardsRouter } from './routes/credit-cards.routes';

export const app = express();

app.use(express.json());
app.get('/health', (_req, res) => res.status(200).json({ status: 'ok' }));
app.use('/api/v1/credit-cards', creditCardsRouter);
app.use(errorHandler);
