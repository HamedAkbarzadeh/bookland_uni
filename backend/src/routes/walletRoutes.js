import { Router } from 'express';
import { walletController } from '../controllers/walletController.js';
import { authenticate } from '../middleware/auth.js';

const router = Router();

router.get('/', authenticate, walletController.getWallet);
router.post('/topup', authenticate, walletController.topUp);

export default router;
