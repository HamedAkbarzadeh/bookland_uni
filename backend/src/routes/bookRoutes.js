import { Router } from 'express';
import { bookController } from '../controllers/bookController.js';
import { authenticate } from '../middleware/auth.js';

const router = Router();

router.get('/', bookController.getBooks);
router.get('/my/listings', authenticate, bookController.getMyListings);
router.get('/:id', bookController.getBookById);
router.post('/', authenticate, bookController.createBook);
router.put('/:id', authenticate, bookController.updateBook);
router.delete('/:id', authenticate, bookController.deleteBook);
router.post('/:id/reviews', authenticate, bookController.addReview);

export default router;
