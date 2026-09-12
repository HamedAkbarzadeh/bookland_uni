import jwt from 'jsonwebtoken';
import { dataService } from '../models/dataService.js';

export async function authenticate(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, message: 'لطفاً ابتدا وارد حساب کاربری خود شوید' });
    }

    const token = authHeader.split(' ')[1];
    const secret = process.env.JWT_SECRET || 'super_secret_book_marketplace_key_2026';
    const decoded = jwt.verify(token, secret);

    const user = await dataService.findUserById(decoded.id);
    if (!user) {
      return res.status(401).json({ success: false, message: 'کاربر مورد نظر یافت نشد' });
    }

    req.user = user;
    next();
  } catch (err) {
    return res.status(401).json({ success: false, message: 'نشست کاربری نامعتبر یا منقضی شده است' });
  }
}

export function optionalAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next();
  }

  try {
    const token = authHeader.split(' ')[1];
    const secret = process.env.JWT_SECRET || 'super_secret_book_marketplace_key_2026';
    const decoded = jwt.verify(token, secret);
    dataService.findUserById(decoded.id).then(user => {
      if (user) req.user = user;
      next();
    }).catch(() => next());
  } catch (e) {
    next();
  }
}
