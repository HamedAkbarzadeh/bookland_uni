import jwt from 'jsonwebtoken';
import { hashPassword, comparePassword } from '../utils/hasher.js';
import { dataService } from '../models/dataService.js';

function generateToken(userId) {
  const secret = process.env.JWT_SECRET || 'super_secret_book_marketplace_key_2026';
  const expiresIn = process.env.JWT_EXPIRES_IN || '30d';
  return jwt.sign({ id: userId }, secret, { expiresIn });
}

export const authController = {
  async register(req, res) {
    try {
      const { name, email, phone, password } = req.body;

      if (!name || !email || !password) {
        return res.status(400).json({ success: false, message: 'نام، ایمیل و رمز عبور الزامی هستند' });
      }

      const existingUser = await dataService.findUserByEmail(email);
      if (existingUser) {
        return res.status(400).json({ success: false, message: 'این ایمیل قبلاً ثبت نام شده است' });
      }

      const hashedPassword = await hashPassword(password);
      const user = await dataService.createUser({
        name,
        email,
        phone: phone || '',
        password: hashedPassword,
        wallet_balance: 500000 // هدیه اولیه ۵۰۰ هزار تومانی به کاربران جدید برای تست خرید!
      });

      const token = generateToken(user.id);

      return res.status(201).json({
        success: true,
        message: 'ثبت‌نام با موفقیت انجام شد. اعتبار ۵۰۰ هزار تومانی به کیف پول شما اضافه شد!',
        data: { user, token }
      });
    } catch (err) {
      console.error('Register error:', err);
      return res.status(500).json({ success: false, message: 'خطای سرور در ثبت نام', error: err.message });
    }
  },

  async login(req, res) {
    try {
      const { email, password } = req.body;

      if (!email || !password) {
        return res.status(400).json({ success: false, message: 'ایمیل و کلمه عبور الزامی هستند' });
      }

      const user = await dataService.findUserByEmail(email);
      if (!user) {
        return res.status(401).json({ success: false, message: 'ایمیل یا کلمه عبور اشتباه است' });
      }

      const isMatch = await comparePassword(password, user.password);
      if (!isMatch) {
        return res.status(401).json({ success: false, message: 'ایمیل یا کلمه عبور اشتباه است' });
      }

      const token = generateToken(user.id);
      const { password: _, ...safeUser } = user;

      return res.json({
        success: true,
        message: 'ورود موفقیت‌آمیز بود',
        data: { user: safeUser, token }
      });
    } catch (err) {
      console.error('Login error:', err);
      return res.status(500).json({ success: false, message: 'خطای سرور در ورود', error: err.message });
    }
  },

  async me(req, res) {
    try {
      const user = await dataService.findUserById(req.user.id);
      return res.json({ success: true, data: { user } });
    } catch (err) {
      return res.status(500).json({ success: false, message: 'خطا در دریافت اطلاعات کاربر' });
    }
  }
};
