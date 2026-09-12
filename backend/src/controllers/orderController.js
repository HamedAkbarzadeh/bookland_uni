import { dataService } from '../models/dataService.js';

export const orderController = {
  async createOrder(req, res) {
    try {
      const buyer_id = req.user.id;
      const { items, shipping_address, payment_method = 'wallet' } = req.body;

      if (!items || !Array.isArray(items) || items.length === 0) {
        return res.status(400).json({ success: false, message: 'سبد خرید خالی است' });
      }

      if (!shipping_address || shipping_address.trim().length === 0) {
        return res.status(400).json({ success: false, message: 'آدرس پستی جهت ارسال کتاب الزامی است' });
      }

      const order = await dataService.createOrder({
        buyer_id,
        items,
        shipping_address,
        payment_method
      });

      return res.status(201).json({
        success: true,
        message: 'سفارش خرید با موفقیت ثبت شد و وجه به حساب فروشنده منظور گردید',
        data: { order }
      });
    } catch (err) {
      console.error('createOrder error:', err);
      return res.status(400).json({
        success: false,
        message: err.message || 'خطا در ثبت سفارش خرید'
      });
    }
  },

  async getMyOrders(req, res) {
    try {
      const orders = await dataService.getUserOrders(req.user.id);
      return res.json({ success: true, data: { orders } });
    } catch (err) {
      console.error('getMyOrders error:', err);
      return res.status(500).json({ success: false, message: 'خطا در دریافت سفارش‌های خرید' });
    }
  },

  async getMySales(req, res) {
    try {
      const sales = await dataService.getUserSales(req.user.id);
      return res.json({ success: true, data: { sales } });
    } catch (err) {
      console.error('getMySales error:', err);
      return res.status(500).json({ success: false, message: 'خطا در دریافت لیست کتاب‌های فروخته‌شده' });
    }
  }
};
