import { getPool, isUsingMySQL, fallbackStore } from '../config/db.js';

export const dataService = {
  // USER OPERATIONS
  async findUserByEmail(email) {
    if (isUsingMySQL()) {
      const [rows] = await getPool().query('SELECT * FROM users WHERE email = ?', [email]);
      return rows[0] || null;
    }
    return fallbackStore.users.find(u => u.email.toLowerCase() === email.toLowerCase()) || null;
  },

  async findUserById(id) {
    const numId = Number(id);
    if (isUsingMySQL()) {
      const [rows] = await getPool().query(
        'SELECT id, name, email, phone, wallet_balance, avatar, created_at FROM users WHERE id = ?',
        [numId]
      );
      return rows[0] || null;
    }
    const user = fallbackStore.users.find(u => u.id === numId);
    if (!user) return null;
    const { password, ...safeUser } = user;
    return safeUser;
  },

  async createUser({ name, email, phone, password, wallet_balance = 0, avatar = null }) {
    if (isUsingMySQL()) {
      const [result] = await getPool().query(
        'INSERT INTO users (name, email, phone, password, wallet_balance, avatar) VALUES (?, ?, ?, ?, ?, ?)',
        [name, email, phone, password, wallet_balance, avatar]
      );
      return { id: result.insertId, name, email, phone, wallet_balance, avatar };
    }
    const id = fallbackStore.users.length ? Math.max(...fallbackStore.users.map(u => u.id)) + 1 : 1;
    const newUser = { id, name, email, phone, password, wallet_balance, avatar, created_at: new Date() };
    fallbackStore.users.push(newUser);
    const { password: _, ...safeUser } = newUser;
    return safeUser;
  },

  async updateUserWallet(userId, newBalance) {
    const numId = Number(userId);
    if (isUsingMySQL()) {
      await getPool().query('UPDATE users SET wallet_balance = ? WHERE id = ?', [newBalance, numId]);
      return true;
    }
    const user = fallbackStore.users.find(u => u.id === numId);
    if (user) {
      user.wallet_balance = newBalance;
      return true;
    }
    return false;
  },

  // CATEGORY OPERATIONS
  async getAllCategories() {
    if (isUsingMySQL()) {
      const [rows] = await getPool().query('SELECT * FROM categories ORDER BY id ASC');
      return rows;
    }
    return fallbackStore.categories;
  },

  async getCategoryById(id) {
    const numId = Number(id);
    if (isUsingMySQL()) {
      const [rows] = await getPool().query('SELECT * FROM categories WHERE id = ?', [numId]);
      return rows[0] || null;
    }
    return fallbackStore.categories.find(c => c.id === numId) || null;
  },

  // BOOK OPERATIONS
  async getBooks({ search, category_id, condition_status, min_price, max_price, sort, seller_id, status = 'available', limit = 50, offset = 0 }) {
    if (isUsingMySQL()) {
      let query = `
        SELECT b.*, 
               u.name as seller_name, u.phone as seller_phone, u.avatar as seller_avatar,
               c.name as category_name
        FROM books b
        JOIN users u ON b.seller_id = u.id
        JOIN categories c ON b.category_id = c.id
        WHERE 1=1
      `;
      const params = [];

      if (status && status !== 'all') {
        query += ' AND b.status = ?';
        params.push(status);
      }

      if (seller_id) {
        query += ' AND b.seller_id = ?';
        params.push(Number(seller_id));
      }

      if (category_id) {
        query += ' AND b.category_id = ?';
        params.push(Number(category_id));
      }

      if (condition_status) {
        query += ' AND b.condition_status = ?';
        params.push(condition_status);
      }

      if (min_price) {
        query += ' AND b.price >= ?';
        params.push(Number(min_price));
      }

      if (max_price) {
        query += ' AND b.price <= ?';
        params.push(Number(max_price));
      }

      if (search) {
        query += ' AND (b.title LIKE ? OR b.author LIKE ? OR b.description LIKE ?)';
        const term = `%${search}%`;
        params.push(term, term, term);
      }

      // Sorting
      if (sort === 'price_asc') {
        query += ' ORDER BY b.price ASC';
      } else if (sort === 'price_desc') {
        query += ' ORDER BY b.price DESC';
      } else {
        query += ' ORDER BY b.created_at DESC';
      }

      query += ' LIMIT ? OFFSET ?';
      params.push(Number(limit), Number(offset));

      const [rows] = await getPool().query(query, params);
      return rows;
    }

    // Fallback store filter
    let list = fallbackStore.books.map(b => {
      const seller = fallbackStore.users.find(u => u.id === b.seller_id) || {};
      const cat = fallbackStore.categories.find(c => c.id === b.category_id) || {};
      return {
        ...b,
        seller_name: seller.name || 'فروشنده',
        seller_phone: seller.phone || '',
        seller_avatar: seller.avatar || null,
        category_name: cat.name || 'عمومی'
      };
    });

    if (status && status !== 'all') {
      list = list.filter(b => b.status === status);
    }
    if (seller_id) {
      list = list.filter(b => b.seller_id === Number(seller_id));
    }
    if (category_id) {
      list = list.filter(b => b.category_id === Number(category_id));
    }
    if (condition_status) {
      list = list.filter(b => b.condition_status === condition_status);
    }
    if (min_price) {
      list = list.filter(b => Number(b.price) >= Number(min_price));
    }
    if (max_price) {
      list = list.filter(b => Number(b.price) <= Number(max_price));
    }
    if (search) {
      const s = search.toLowerCase();
      list = list.filter(b =>
        b.title.toLowerCase().includes(s) ||
        b.author.toLowerCase().includes(s) ||
        (b.description && b.description.toLowerCase().includes(s))
      );
    }

    if (sort === 'price_asc') {
      list.sort((a, b) => Number(a.price) - Number(b.price));
    } else if (sort === 'price_desc') {
      list.sort((a, b) => Number(b.price) - Number(a.price));
    } else {
      list.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
    }

    return list.slice(offset, offset + limit);
  },

  async getBookById(id) {
    const numId = Number(id);
    if (isUsingMySQL()) {
      const [rows] = await getPool().query(
        `SELECT b.*, 
                u.name as seller_name, u.phone as seller_phone, u.avatar as seller_avatar, u.email as seller_email,
                c.name as category_name
         FROM books b
         JOIN users u ON b.seller_id = u.id
         JOIN categories c ON b.category_id = c.id
         WHERE b.id = ?`,
        [numId]
      );
      if (!rows[0]) return null;

      // Get reviews
      const [reviews] = await getPool().query(
        `SELECT r.*, u.name as user_name, u.avatar as user_avatar 
         FROM reviews r 
         JOIN users u ON r.user_id = u.id 
         WHERE r.book_id = ? 
         ORDER BY r.created_at DESC`,
        [numId]
      );
      return { ...rows[0], reviews };
    }

    const b = fallbackStore.books.find(item => item.id === numId);
    if (!b) return null;
    const seller = fallbackStore.users.find(u => u.id === b.seller_id) || {};
    const cat = fallbackStore.categories.find(c => c.id === b.category_id) || {};
    const reviews = fallbackStore.reviews
      .filter(r => r.book_id === numId)
      .map(r => {
        const u = fallbackStore.users.find(usr => usr.id === r.user_id) || {};
        return { ...r, user_name: u.name || 'کاربر', user_avatar: u.avatar || null };
      });

    return {
      ...b,
      seller_name: seller.name || 'فروشنده',
      seller_phone: seller.phone || '',
      seller_avatar: seller.avatar || null,
      seller_email: seller.email || '',
      category_name: cat.name || 'عمومی',
      reviews
    };
  },

  async createBook({ seller_id, category_id, title, author, isbn, description, price, condition_status, image_url, stock = 1 }) {
    if (isUsingMySQL()) {
      const [result] = await getPool().query(
        `INSERT INTO books (seller_id, category_id, title, author, isbn, description, price, condition_status, image_url, stock, status)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'available')`,
        [seller_id, category_id, title, author, isbn, description, price, condition_status, image_url, stock]
      );
      return this.getBookById(result.insertId);
    }

    const id = fallbackStore.books.length ? Math.max(...fallbackStore.books.map(b => b.id)) + 1 : 1;
    const newBook = {
      id,
      seller_id: Number(seller_id),
      category_id: Number(category_id),
      title,
      author,
      isbn: isbn || '',
      description: description || '',
      price: Number(price),
      condition_status: condition_status || 'like_new',
      image_url: image_url || null,
      stock: Number(stock),
      status: 'available',
      created_at: new Date(),
      updated_at: new Date()
    };
    fallbackStore.books.unshift(newBook);
    return this.getBookById(id);
  },

  async updateBook(id, updates) {
    const numId = Number(id);
    if (isUsingMySQL()) {
      const fields = [];
      const values = [];
      for (const [key, val] of Object.entries(updates)) {
        fields.push(`\`${key}\` = ?`);
        values.push(val);
      }
      values.push(numId);
      await getPool().query(`UPDATE books SET ${fields.join(', ')} WHERE id = ?`, values);
      return this.getBookById(numId);
    }

    const index = fallbackStore.books.findIndex(b => b.id === numId);
    if (index !== -1) {
      fallbackStore.books[index] = { ...fallbackStore.books[index], ...updates, updated_at: new Date() };
      return this.getBookById(numId);
    }
    return null;
  },

  async deleteBook(id, sellerId) {
    const numId = Number(id);
    if (isUsingMySQL()) {
      const [result] = await getPool().query('DELETE FROM books WHERE id = ? AND seller_id = ?', [numId, Number(sellerId)]);
      return result.affectedRows > 0;
    }
    const index = fallbackStore.books.findIndex(b => b.id === numId && b.seller_id === Number(sellerId));
    if (index !== -1) {
      fallbackStore.books.splice(index, 1);
      return true;
    }
    return false;
  },

  // ORDER OPERATIONS
  async createOrder({ buyer_id, items, shipping_address, payment_method = 'wallet' }) {
    const numBuyerId = Number(buyer_id);
    let totalAmount = 0;

    // Validate items and calculate total
    for (const item of items) {
      const book = await this.getBookById(item.book_id);
      if (!book) throw new Error(`کتاب با شناسه ${item.book_id} یافت نشد`);
      if (book.status !== 'available' || book.stock < item.quantity) {
        throw new Error(`موجودی کتاب "${book.title}" به پایان رسیده است`);
      }
      if (book.seller_id === numBuyerId) {
        throw new Error('شما نمی‌توانید کتاب متعلق به خودتان را خریداری کنید!');
      }
      totalAmount += Number(book.price) * Number(item.quantity);
      item.price = Number(book.price);
      item.seller_id = book.seller_id;
    }

    const buyer = await this.findUserById(numBuyerId);
    if (!buyer) throw new Error('کاربر خریدار معتبر نیست');

    // Check balance if payment_method is wallet
    if (payment_method === 'wallet' && Number(buyer.wallet_balance) < totalAmount) {
      throw new Error(`اعتبار کیف پول کافی نیست. مبلغ مورد نیاز: ${totalAmount.toLocaleString('fa-IR')} تومان، موجودی شما: ${Number(buyer.wallet_balance).toLocaleString('fa-IR')} تومان`);
    }

    if (isUsingMySQL()) {
      const conn = await getPool().getConnection();
      try {
        await conn.beginTransaction();

        // 1. Create order
        const [orderResult] = await conn.query(
          'INSERT INTO orders (buyer_id, total_amount, status, payment_method, shipping_address) VALUES (?, ?, ?, ?, ?)',
          [numBuyerId, totalAmount, 'completed', payment_method, shipping_address]
        );
        const orderId = orderResult.insertId;

        // 2. Insert order items & update books & credit sellers
        for (const item of items) {
          await conn.query(
            'INSERT INTO order_items (order_id, book_id, seller_id, price, quantity) VALUES (?, ?, ?, ?, ?)',
            [orderId, item.book_id, item.seller_id, item.price, item.quantity]
          );

          // Update book stock and status
          await conn.query(
            'UPDATE books SET stock = stock - ?, status = IF(stock <= 0, "sold", "available") WHERE id = ?',
            [item.quantity, item.book_id]
          );

          // Credit seller wallet
          const saleAmount = item.price * item.quantity;
          await conn.query(
            'UPDATE users SET wallet_balance = wallet_balance + ? WHERE id = ?',
            [saleAmount, item.seller_id]
          );

          // Record seller transaction
          await conn.query(
            'INSERT INTO wallet_transactions (user_id, amount, type, description) VALUES (?, ?, ?, ?)',
            [item.seller_id, saleAmount, 'sale_credit', `درآمد حاصل از فروش کتاب (سفارش #${orderId})`]
          );
        }

        // 3. Deduct buyer wallet
        if (payment_method === 'wallet') {
          await conn.query(
            'UPDATE users SET wallet_balance = wallet_balance - ? WHERE id = ?',
            [totalAmount, numBuyerId]
          );

          // Record buyer transaction
          await conn.query(
            'INSERT INTO wallet_transactions (user_id, amount, type, description) VALUES (?, ?, ?, ?)',
            [numBuyerId, -totalAmount, 'purchase_debit', `پرداخت برای خرید کتاب (سفارش #${orderId})`]
          );
        }

        await conn.commit();
        conn.release();

        return { id: orderId, buyer_id: numBuyerId, total_amount: totalAmount, status: 'completed', payment_method, items };
      } catch (err) {
        await conn.rollback();
        conn.release();
        throw err;
      }
    }

    // Fallback store handling
    const orderId = fallbackStore.orders.length ? Math.max(...fallbackStore.orders.map(o => o.id)) + 1 : 1;
    const order = {
      id: orderId,
      buyer_id: numBuyerId,
      total_amount: totalAmount,
      status: 'completed',
      payment_method,
      shipping_address,
      created_at: new Date()
    };
    fallbackStore.orders.unshift(order);

    for (const item of items) {
      fallbackStore.order_items.push({
        id: fallbackStore.order_items.length + 1,
        order_id: orderId,
        book_id: item.book_id,
        seller_id: item.seller_id,
        price: item.price,
        quantity: item.quantity
      });

      // Update book status
      const b = fallbackStore.books.find(bk => bk.id === item.book_id);
      if (b) {
        b.stock -= item.quantity;
        if (b.stock <= 0) b.status = 'sold';
      }

      // Credit seller
      const seller = fallbackStore.users.find(u => u.id === item.seller_id);
      if (seller) {
        seller.wallet_balance = Number(seller.wallet_balance || 0) + item.price * item.quantity;
        fallbackStore.wallet_transactions.unshift({
          id: fallbackStore.wallet_transactions.length + 1,
          user_id: item.seller_id,
          amount: item.price * item.quantity,
          type: 'sale_credit',
          description: `درآمد حاصل از فروش کتاب (سفارش #${orderId})`,
          created_at: new Date()
        });
      }
    }

    // Deduct buyer
    if (payment_method === 'wallet') {
      const buyerObj = fallbackStore.users.find(u => u.id === numBuyerId);
      if (buyerObj) {
        buyerObj.wallet_balance = Number(buyerObj.wallet_balance || 0) - totalAmount;
        fallbackStore.wallet_transactions.unshift({
          id: fallbackStore.wallet_transactions.length + 1,
          user_id: numBuyerId,
          amount: -totalAmount,
          type: 'purchase_debit',
          description: `پرداخت برای خرید کتاب (سفارش #${orderId})`,
          created_at: new Date()
        });
      }
    }

    return { ...order, items };
  },

  async getUserOrders(buyerId) {
    const numId = Number(buyerId);
    if (isUsingMySQL()) {
      const [orders] = await getPool().query(
        'SELECT * FROM orders WHERE buyer_id = ? ORDER BY created_at DESC',
        [numId]
      );
      for (const order of orders) {
        const [items] = await getPool().query(
          `SELECT oi.*, b.title, b.author, b.image_url, u.name as seller_name 
           FROM order_items oi 
           JOIN books b ON oi.book_id = b.id 
           JOIN users u ON oi.seller_id = u.id 
           WHERE oi.order_id = ?`,
          [order.id]
        );
        order.items = items;
      }
      return orders;
    }

    const orders = fallbackStore.orders.filter(o => o.buyer_id === numId);
    return orders.map(order => {
      const items = fallbackStore.order_items
        .filter(oi => oi.order_id === order.id)
        .map(oi => {
          const b = fallbackStore.books.find(bk => bk.id === oi.book_id) || {};
          const s = fallbackStore.users.find(usr => usr.id === oi.seller_id) || {};
          return {
            ...oi,
            title: b.title || 'کتاب',
            author: b.author || '',
            image_url: b.image_url || null,
            seller_name: s.name || 'فروشنده'
          };
        });
      return { ...order, items };
    });
  },

  async getUserSales(sellerId) {
    const numId = Number(sellerId);
    if (isUsingMySQL()) {
      const [sales] = await getPool().query(
        `SELECT oi.*, o.created_at, o.status as order_status, o.shipping_address,
                b.title, b.author, b.image_url,
                u.name as buyer_name, u.phone as buyer_phone, u.email as buyer_email
         FROM order_items oi
         JOIN orders o ON oi.order_id = o.id
         JOIN books b ON oi.book_id = b.id
         JOIN users u ON o.buyer_id = u.id
         WHERE oi.seller_id = ?
         ORDER BY o.created_at DESC`,
        [numId]
      );
      return sales;
    }

    const sales = [];
    for (const oi of fallbackStore.order_items.filter(item => item.seller_id === numId)) {
      const order = fallbackStore.orders.find(o => o.id === oi.order_id) || {};
      const b = fallbackStore.books.find(bk => bk.id === oi.book_id) || {};
      const buyer = fallbackStore.users.find(u => u.id === order.buyer_id) || {};
      sales.push({
        ...oi,
        created_at: order.created_at,
        order_status: order.status || 'completed',
        shipping_address: order.shipping_address || '',
        title: b.title || 'کتاب',
        author: b.author || '',
        image_url: b.image_url || null,
        buyer_name: buyer.name || 'خریدار',
        buyer_phone: buyer.phone || '',
        buyer_email: buyer.email || ''
      });
    }
    return sales;
  },

  // WALLET OPERATIONS
  async addWalletTransaction(userId, amount, type, description) {
    const numId = Number(userId);
    const numAmount = Number(amount);

    if (isUsingMySQL()) {
      await getPool().query(
        'INSERT INTO wallet_transactions (user_id, amount, type, description) VALUES (?, ?, ?, ?)',
        [numId, numAmount, type, description]
      );
      await getPool().query(
        'UPDATE users SET wallet_balance = wallet_balance + ? WHERE id = ?',
        [numAmount, numId]
      );
      const [user] = await getPool().query('SELECT wallet_balance FROM users WHERE id = ?', [numId]);
      return user[0]?.wallet_balance || 0;
    }

    const user = fallbackStore.users.find(u => u.id === numId);
    if (user) {
      user.wallet_balance = Number(user.wallet_balance || 0) + numAmount;
      fallbackStore.wallet_transactions.unshift({
        id: fallbackStore.wallet_transactions.length + 1,
        user_id: numId,
        amount: numAmount,
        type,
        description,
        created_at: new Date()
      });
      return user.wallet_balance;
    }
    return 0;
  },

  async getWalletTransactions(userId) {
    const numId = Number(userId);
    if (isUsingMySQL()) {
      const [rows] = await getPool().query(
        'SELECT * FROM wallet_transactions WHERE user_id = ? ORDER BY created_at DESC LIMIT 50',
        [numId]
      );
      return rows;
    }
    return fallbackStore.wallet_transactions.filter(t => t.user_id === numId);
  },

  // REVIEWS
  async addReview({ book_id, user_id, rating, comment }) {
    const numBookId = Number(book_id);
    const numUserId = Number(user_id);
    if (isUsingMySQL()) {
      const [res] = await getPool().query(
        'INSERT INTO reviews (book_id, user_id, rating, comment) VALUES (?, ?, ?, ?)',
        [numBookId, numUserId, rating, comment]
      );
      return { id: res.insertId, book_id: numBookId, user_id: numUserId, rating, comment, created_at: new Date() };
    }
    const rev = {
      id: fallbackStore.reviews.length + 1,
      book_id: numBookId,
      user_id: numUserId,
      rating,
      comment,
      created_at: new Date()
    };
    fallbackStore.reviews.unshift(rev);
    return rev;
  }
};
