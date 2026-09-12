import { dataService } from '../models/dataService.js';

export const walletController = {
  async getWallet(req, res) {
    try {
      const user = await dataService.findUserById(req.user.id);
      const transactions = await dataService.getWalletTransactions(req.user.id);

      return res.json({
        success: true,
        data: {
          balance: Number(user.wallet_balance || 0),
          transactions
        }
      });
    } catch (err) {
      return res.status(500).json({ success: false, message: 'خطا در دریافت اطلاعات کیف پول' });
    }
  },

  async topUp(req, res) {
    try {
      const { amount } = req.body;
      const numAmount = Number(amount);

      if (!numAmount || numAmount <= 0) {
        return res.status(400).json({ success: false, message: 'مبلغ شارژ باید بزرگتر از صفر باشد' });
      }

      const newBalance = await dataService.addWalletTransaction(
        req.user.id,
        numAmount,
        'deposit',
        `شارژ آنلاین حساب کاربری (${numAmount.toLocaleString('fa-IR')} تومان)`
      );

      return res.json({
        success: true,
        message: `کیف پول شما با موفقیت به میزان ${numAmount.toLocaleString('fa-IR')} تومان شارژ شد`,
        data: { balance: newBalance }
      });
    } catch (err) {
      return res.status(500).json({ success: false, message: 'خطا در شارژ کیف پول' });
    }
  }
};
