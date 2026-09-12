import { dataService } from '../models/dataService.js';

export const bookController = {
  async getBooks(req, res) {
    try {
      const {
        search,
        category_id,
        condition_status,
        min_price,
        max_price,
        sort,
        page = 1,
        limit = 30
      } = req.query;

      const offset = (Math.max(1, Number(page)) - 1) * Number(limit);

      const books = await dataService.getBooks({
        search,
        category_id,
        condition_status,
        min_price,
        max_price,
        sort,
        status: 'available',
        limit: Number(limit),
        offset
      });

      return res.json({
        success: true,
        data: {
          books,
          page: Number(page),
          limit: Number(limit)
        }
      });
    } catch (err) {
      console.error('getBooks error:', err);
      return res.status(500).json({ success: false, message: 'خطا در دریافت لیست کتاب‌ها', error: err.message });
    }
  },

  async getBookById(req, res) {
    try {
      const { id } = req.params;
      const book = await dataService.getBookById(id);
      if (!book) {
        return res.status(404).json({ success: false, message: 'کتاب مورد نظر یافت نشد' });
      }
      return res.json({ success: true, data: { book } });
    } catch (err) {
      return res.status(500).json({ success: false, message: 'خطا در دریافت اطلاعات کتاب' });
    }
  },

  async createBook(req, res) {
    try {
      const seller_id = req.user.id;
      const {
        title,
        author,
        category_id,
        price,
        condition_status,
        isbn,
        description,
        image_url,
        stock = 1
      } = req.body;

      if (!title || !author || !category_id || !price) {
        return res.status(400).json({
          success: false,
          message: 'عنوان کتاب، نام نویسنده، دسته‌بندی و قیمت الزامی هستند'
        });
      }

      const book = await dataService.createBook({
        seller_id,
        category_id,
        title,
        author,
        isbn,
        description,
        price,
        condition_status: condition_status || 'like_new',
        image_url,
        stock
      });

      return res.status(201).json({
        success: true,
        message: 'کتاب شما با موفقیت برای فروش ثبت شد',
        data: { book }
      });
    } catch (err) {
      console.error('createBook error:', err);
      return res.status(500).json({ success: false, message: 'خطا در ثبت کتاب', error: err.message });
    }
  },

  async updateBook(req, res) {
    try {
      const { id } = req.params;
      const book = await dataService.getBookById(id);
      if (!book) {
        return res.status(404).json({ success: false, message: 'کتاب یافت نشد' });
      }

      if (book.seller_id !== req.user.id) {
        return res.status(403).json({ success: false, message: 'شما فقط مجاز به ویرایش کتاب‌های خودتان هستید' });
      }

      const { title, author, category_id, price, condition_status, isbn, description, image_url, stock, status } = req.body;
      const updates = {};
      if (title !== undefined) updates.title = title;
      if (author !== undefined) updates.author = author;
      if (category_id !== undefined) updates.category_id = category_id;
      if (price !== undefined) updates.price = price;
      if (condition_status !== undefined) updates.condition_status = condition_status;
      if (isbn !== undefined) updates.isbn = isbn;
      if (description !== undefined) updates.description = description;
      if (image_url !== undefined) updates.image_url = image_url;
      if (stock !== undefined) updates.stock = stock;
      if (status !== undefined) updates.status = status;

      const updated = await dataService.updateBook(id, updates);
      return res.json({
        success: true,
        message: 'کتاب با موفقیت بروزرسانی شد',
        data: { book: updated }
      });
    } catch (err) {
      return res.status(500).json({ success: false, message: 'خطا در ویرایش کتاب' });
    }
  },

  async deleteBook(req, res) {
    try {
      const { id } = req.params;
      const book = await dataService.getBookById(id);
      if (!book) {
        return res.status(404).json({ success: false, message: 'کتاب یافت نشد' });
      }

      if (book.seller_id !== req.user.id) {
        return res.status(403).json({ success: false, message: 'شما فقط مجاز به حذف کتاب‌های خودتان هستید' });
      }

      const success = await dataService.deleteBook(id, req.user.id);
      if (success) {
        return res.json({ success: true, message: 'کتاب با موفقیت حذف شد' });
      }
      return res.status(400).json({ success: false, message: 'عملیات حذف ناموفق بود' });
    } catch (err) {
      return res.status(500).json({ success: false, message: 'خطا در حذف کتاب' });
    }
  },

  async getMyListings(req, res) {
    try {
      const books = await dataService.getBooks({
        seller_id: req.user.id,
        status: 'all',
        limit: 100
      });
      return res.json({ success: true, data: { books } });
    } catch (err) {
      return res.status(500).json({ success: false, message: 'خطا در دریافت لیست کتاب‌های من' });
    }
  },

  async addReview(req, res) {
    try {
      const { id } = req.params;
      const { rating, comment } = req.body;

      if (!rating || rating < 1 || rating > 5) {
        return res.status(400).json({ success: false, message: 'امتیاز باید عددی بین ۱ تا ۵ باشد' });
      }

      const review = await dataService.addReview({
        book_id: id,
        user_id: req.user.id,
        rating,
        comment: comment || ''
      });

      return res.status(201).json({
        success: true,
        message: 'نظر و امتیاز شما با موفقیت ثبت شد',
        data: { review }
      });
    } catch (err) {
      return res.status(500).json({ success: false, message: 'خطا در ثبت نظر' });
    }
  }
};
