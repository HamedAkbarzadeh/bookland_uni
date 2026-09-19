import path from 'path';
import { fileURLToPath } from 'url';
import { hashPassword } from '../utils/hasher.js';
import { initDatabase, getPool, isUsingMySQL, fallbackStore } from '../config/db.js';

export const initialCategories = [
  { id: 1, name: 'داستانی و رمان', slug: 'fiction', icon: 'auto_stories' },
  { id: 2, name: 'روانشناسی و فردی', slug: 'psychology', icon: 'psychology' },
  { id: 3, name: 'تاریخ و فلسفه', slug: 'history-philosophy', icon: 'history_edu' },
  { id: 4, name: 'مدیریت و کسب‌وکار', slug: 'business', icon: 'trending_up' },
  { id: 5, name: 'علمی و آموزشی', slug: 'science', icon: 'science' },
  { id: 6, name: 'شعر و ادبیات', slug: 'poetry', icon: 'menu_book' }
];

export async function seedDatabase(options = {}) {
  const { fresh = false, isCli = false } = options;
  const hashedPassword = await hashPassword('123456');

  const initialUsers = [
    {
      id: 1,
      name: 'رضا کمالی (فروشنده)',
      email: 'seller@example.com',
      phone: '09121112233',
      password: hashedPassword,
      wallet_balance: 550000,
      avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'
    },
    {
      id: 2,
      name: 'سارا امینی (خریدار)',
      email: 'buyer@example.com',
      phone: '09198887766',
      password: hashedPassword,
      wallet_balance: 1200000,
      avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150'
    },
    {
      id: 3,
      name: 'علی حسینی',
      email: 'ali@example.com',
      phone: '09355554433',
      password: hashedPassword,
      wallet_balance: 300000,
      avatar: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150'
    },
    {
      id: 4,
      name: 'مریم راد (دانشجو و کتاب‌خوان)',
      email: 'maryam@example.com',
      phone: '09123334455',
      password: hashedPassword,
      wallet_balance: 450000,
      avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150'
    }
  ];

  const initialBooks = [
    {
      id: 1,
      seller_id: 1,
      category_id: 2,
      title: 'عادت‌های اتمی',
      author: 'جیمز کلیر',
      isbn: '978-600-405-234-1',
      description: 'یک روش آسان و اثبات‌شده برای ایجاد عادت‌های خوب و ترک عادت‌های بد. این کتاب تغییرات کوچکی را به شما می‌آموزد که نتایج شگفت‌انگیزی رقم می‌زنند.',
      price: 135000,
      condition_status: 'like_new',
      image_url: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=600',
      stock: 2,
      status: 'available'
    },
    {
      id: 2,
      seller_id: 1,
      category_id: 1,
      title: 'چشم‌هایش',
      author: 'بزرگ علوی',
      isbn: '978-964-00-0128-6',
      description: 'یکی از ماندگارترین رمان‌های عاشقانه و معمایی ادبیات معاصر ایران. داستان زنی به نام فرنگیس و استاد ماکان نقاش نامدار.',
      price: 95000,
      condition_status: 'used',
      image_url: 'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=600',
      stock: 2,
      status: 'available'
    },
    {
      id: 3,
      seller_id: 3,
      category_id: 2,
      title: 'انسان در جستجوی معنی',
      author: 'ویکتور فرانکل',
      isbn: '978-964-374-123-0',
      description: 'روایت شگفت‌انگیز دکتر فرانکل از اردوگاه‌های کار اجباری نازی‌ها و معرفی رویکرد معنادرمانی (لوگوتراپی).',
      price: 110000,
      condition_status: 'new',
      image_url: 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=600',
      stock: 3,
      status: 'available'
    },
    {
      id: 4,
      seller_id: 1,
      category_id: 4,
      title: 'اثر مرکب',
      author: 'دارن هاردی',
      isbn: '978-600-118-090-4',
      description: 'آغاز جهشی در درآمد، موفقیت و زندگی شما. رازهای کاربردی برای ایجاد پیشرفت‌های پایدار در زندگی و کسب‌وکار.',
      price: 85000,
      condition_status: 'like_new',
      image_url: 'https://images.unsplash.com/photo-1589829085413-56de8ae18c73?w=600',
      stock: 1,
      status: 'available'
    },
    {
      id: 5,
      seller_id: 3,
      category_id: 1,
      title: 'قلعه حیوانات',
      author: 'جورج اورول',
      isbn: '978-964-363-221-5',
      description: 'شاهکار تمثیلی و سیاسی جورج اورول که سرگذشت حیوانات یک مزرعه پس از شورش علیه اربابشان را روایت می‌کند.',
      price: 75000,
      condition_status: 'used',
      image_url: 'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?w=600',
      stock: 2,
      status: 'available'
    },
    {
      id: 6,
      seller_id: 4,
      category_id: 3,
      title: 'انسان خردمند: تاریخ مختصر بشر',
      author: 'یووال نوح هراری',
      isbn: '978-600-690-345-2',
      description: 'کاوشی جامع و هیجان‌انگیز در تاریخ تکامل نوع بشر از عصر حجر تا عصر اطلاعات و جهان معاصر.',
      price: 240000,
      condition_status: 'new',
      image_url: 'https://images.unsplash.com/photo-1495640388908-05fa85288e61?w=600',
      stock: 2,
      status: 'available'
    },
    {
      id: 7,
      seller_id: 4,
      category_id: 6,
      title: 'دیوان حافظ (با تصحیح قزوینی و غنی)',
      author: 'خواجه شمس‌الدین محمد حافظ شیرازی',
      isbn: '978-964-445-120-1',
      description: 'مجموعه کامل و نفیس غزلیات لسان‌الغیب حافظ شیرازی، همراه با نسخه معتبر مصححان برجسته.',
      price: 180000,
      condition_status: 'new',
      image_url: 'https://images.unsplash.com/photo-1457369804613-52c61a468e7d?w=600',
      stock: 2,
      status: 'available'
    },
    {
      id: 8,
      seller_id: 3,
      category_id: 5,
      title: 'کیهان (Cosmos)',
      author: 'کارل سیگن',
      isbn: '978-964-889-450-3',
      description: 'سفری مسحورکننده در اعماق گیتی، تاریخ علم نجوم و جایگاه بشریت در کیهان پهناور.',
      price: 195000,
      condition_status: 'like_new',
      image_url: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=600',
      stock: 1,
      status: 'available'
    }
  ];

  const initialReviews = [
    {
      id: 1,
      book_id: 1,
      user_id: 2,
      rating: 5,
      comment: 'کتاب فوق‌العاده کاربردی بود، ارسال فروشنده هم سریع و تمیز بود.'
    },
    {
      id: 2,
      book_id: 3,
      user_id: 2,
      rating: 5,
      comment: 'یکی از الهام‌بخش‌ترین کتاب‌هایی که تا به حال خوانده‌ام. وضعیت کتاب کاملاً نو و عالی بود.'
    },
    {
      id: 3,
      book_id: 5,
      user_id: 4,
      rating: 4,
      comment: 'ترجمه روان و کتاب سالم. تشکر از آقای حسینی.'
    }
  ];

  const initialOrders = [
    {
      id: 1,
      buyer_id: 2,
      total_amount: 95000,
      status: 'completed',
      payment_method: 'wallet',
      shipping_address: 'تهران، میدان انقلاب، خیابان کارگر شمالی، پلاک ۱۲، زنگ ۳'
    }
  ];

  const initialOrderItems = [
    {
      id: 1,
      order_id: 1,
      book_id: 2,
      seller_id: 1,
      price: 95000,
      quantity: 1
    }
  ];

  const initialTransactions = [
    {
      id: 1,
      user_id: 1,
      amount: 95000,
      type: 'sale_credit',
      description: 'درآمد حاصل از فروش کتاب چشم‌هایش (سفارش #1)'
    },
    {
      id: 2,
      user_id: 2,
      amount: -95000,
      type: 'purchase_debit',
      description: 'پرداخت برای خرید کتاب چشم‌هایش (سفارش #1)'
    },
    {
      id: 3,
      user_id: 2,
      amount: 1295000,
      type: 'deposit',
      description: 'افزایش موجودی اولیه کیف پول'
    }
  ];

  // Update in-memory fallback store as well
  fallbackStore.categories = [...initialCategories];
  fallbackStore.users = [...initialUsers];
  fallbackStore.books = [...initialBooks];
  fallbackStore.reviews = initialReviews.map(r => ({ ...r, created_at: new Date() }));
  fallbackStore.orders = initialOrders.map(o => ({ ...o, created_at: new Date() }));
  fallbackStore.order_items = [...initialOrderItems];
  fallbackStore.wallet_transactions = initialTransactions.map(t => ({ ...t, created_at: new Date() }));

  // Seed MySQL if available
  if (isUsingMySQL()) {
    const conn = await getPool().getConnection();
    try {
      if (fresh) {
        console.log('🔄 پاک‌سازی داده‌های قبلی (Fresh Mode)...');
        await conn.query('SET FOREIGN_KEY_CHECKS = 0');
        await conn.query('TRUNCATE TABLE reviews');
        await conn.query('TRUNCATE TABLE order_items');
        await conn.query('TRUNCATE TABLE orders');
        await conn.query('TRUNCATE TABLE wallet_transactions');
        await conn.query('TRUNCATE TABLE books');
        await conn.query('TRUNCATE TABLE categories');
        await conn.query('TRUNCATE TABLE users');
        await conn.query('SET FOREIGN_KEY_CHECKS = 1');
        console.log('✅ جداول با موفقیت پاک شدند.');
      }

      // 1. Categories
      console.log('📁 در حال درج دسته‌بندی‌ها در MySQL...');
      for (const cat of initialCategories) {
        await conn.query(
          `INSERT INTO categories (id, name, slug, icon) 
           VALUES (?, ?, ?, ?) 
           ON DUPLICATE KEY UPDATE name = VALUES(name), slug = VALUES(slug), icon = VALUES(icon)`,
          [cat.id, cat.name, cat.slug, cat.icon]
        );
      }

      // 2. Users
      console.log('👤 در حال درج کاربران در MySQL...');
      for (const u of initialUsers) {
        await conn.query(
          `INSERT INTO users (id, name, email, phone, password, wallet_balance, avatar) 
           VALUES (?, ?, ?, ?, ?, ?, ?) 
           ON DUPLICATE KEY UPDATE name = VALUES(name), phone = VALUES(phone), wallet_balance = VALUES(wallet_balance), avatar = VALUES(avatar)`,
          [u.id, u.name, u.email, u.phone, u.password, u.wallet_balance, u.avatar]
        );
      }

      // 3. Books
      console.log('📚 در حال درج کتاب‌ها در MySQL...');
      for (const b of initialBooks) {
        await conn.query(
          `INSERT INTO books (id, seller_id, category_id, title, author, isbn, description, price, condition_status, image_url, stock, status) 
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) 
           ON DUPLICATE KEY UPDATE title = VALUES(title), author = VALUES(author), price = VALUES(price), stock = VALUES(stock), status = VALUES(status)`,
          [b.id, b.seller_id, b.category_id, b.title, b.author, b.isbn, b.description, b.price, b.condition_status, b.image_url, b.stock, b.status]
        );
      }

      // 4. Reviews
      console.log('⭐ در حال درج نظرات در MySQL...');
      for (const r of initialReviews) {
        await conn.query(
          `INSERT IGNORE INTO reviews (id, book_id, user_id, rating, comment) 
           VALUES (?, ?, ?, ?, ?)`,
          [r.id, r.book_id, r.user_id, r.rating, r.comment]
        );
      }

      // 5. Orders & Order Items
      console.log('📦 در حال درج سفارشات نمونه در MySQL...');
      for (const o of initialOrders) {
        await conn.query(
          `INSERT IGNORE INTO orders (id, buyer_id, total_amount, status, payment_method, shipping_address) 
           VALUES (?, ?, ?, ?, ?, ?)`,
          [o.id, o.buyer_id, o.total_amount, o.status, o.payment_method, o.shipping_address]
        );
      }

      for (const oi of initialOrderItems) {
        await conn.query(
          `INSERT IGNORE INTO order_items (id, order_id, book_id, seller_id, price, quantity) 
           VALUES (?, ?, ?, ?, ?, ?)`,
          [oi.id, oi.order_id, oi.book_id, oi.seller_id, oi.price, oi.quantity]
        );
      }

      // 6. Wallet Transactions
      console.log('💳 در حال درج تراکنش‌های کیف پول در MySQL...');
      for (const t of initialTransactions) {
        await conn.query(
          `INSERT IGNORE INTO wallet_transactions (id, user_id, amount, type, description) 
           VALUES (?, ?, ?, ?, ?)`,
          [t.id, t.user_id, t.amount, t.type, t.description]
        );
      }

      console.log('====================================================');
      console.log('🎉 عملیات Seeder با موفقیت در دیتابیس MySQL انجام شد!');
      console.log(`📊 آمار ذخیره‌شده:`);
      console.log(`   - ${initialCategories.length} دسته‌بندی`);
      console.log(`   - ${initialUsers.length} کاربر تستی (فروشنده و خریدار با رمز 123456)`);
      console.log(`   - ${initialBooks.length} کتاب با عکس و مشخصات کامل`);
      console.log(`   - ${initialReviews.length} نظر و امتیاز`);
      console.log(`   - ${initialOrders.length} سفارش نمونه همراه با تراکنش کیف پول`);
      console.log('====================================================');
    } catch (err) {
      console.error('❌ خطا در Seeder دیتابیس MySQL:', err.message);
      throw err;
    } finally {
      conn.release();
    }
  } else {
    console.log('⚠️ اتصال MySQL برقرار نبود، داده‌ها فقط در حافظه بارگذاری شدند.');
  }
}

// Auto-run if executed directly via CLI: `node src/seeds/seed.js` or `npm run seed`
const currentFile = fileURLToPath(import.meta.url);
const invokedFile = process.argv[1] ? path.resolve(process.argv[1]) : null;

if (invokedFile && (currentFile === invokedFile || currentFile.endsWith(path.basename(invokedFile)))) {
  const isFresh = process.argv.includes('--fresh') || process.argv.includes('--clean');
  
  (async () => {
    try {
      console.log('🚀 در حال اتصال به دیتابیس برای اجرای Seeder...');
      const connected = await initDatabase();
      if (!connected) {
        console.error('❌ خطا: اتصال به MySQL برقرار نشد. لطفاً از روشن بودن سرور MySQL (مثلاً در XAMPP) اطمینان حاصل کنید.');
        process.exit(1);
      }

      await seedDatabase({ fresh: isFresh, isCli: true });
      
      const pool = getPool();
      if (pool) {
        await pool.end();
      }
      process.exit(0);
    } catch (error) {
      console.error('❌ اجرای Seeder با خطا مواجه شد:', error);
      process.exit(1);
    }
  })();
}
