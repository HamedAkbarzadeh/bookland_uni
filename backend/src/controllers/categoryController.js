import { dataService } from '../models/dataService.js';

export const categoryController = {
  async getCategories(req, res) {
    try {
      const categories = await dataService.getAllCategories();
      return res.json({ success: true, data: { categories } });
    } catch (err) {
      return res.status(500).json({ success: false, message: 'خطا در دریافت دسته‌بندی‌ها' });
    }
  }
};
