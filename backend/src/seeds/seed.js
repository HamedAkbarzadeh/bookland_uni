import { hashPassword } from '../utils/hasher.js';
import { getPool, isUsingMySQL, fallbackStore } from '../config/db.js';

export const initialCategories = [
  { id: 1, name: 'داستانی و رمان', slug: 'fiction', icon: 'auto_stories' },
  { id: 2, name: 'روانشناسی و فردی', slug: 'psychology', icon: 'psychology' },
  { id: 3, name: 'تاریخ و فلسفه', slug: 'history-philosophy', icon: 'history_edu' },
  { id: 4, name: 'مدیریت و کسب‌وکار', slug: 'business', icon: 'trending_up' },
  { id: 5, name: 'علمی و آموزشی', slug: 'science', icon: 'science' },
  { id: 6, name: 'شعر و ادبیات', slug: 'poetry', icon: 'menu_book' }
];

export async function seedDatabase() {
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
      stock: 1,
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
      description: 'روایت شگفت‌انگیز دکتر فرانکل از اردوگاه‌های کار اجباری نازی‌ها و معرفی رویکرد لوگوتراپی (معنادرمانی).',
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
      description: 'آغاز جهشی در درآمد، موفقیت و زندگی شما. دارن هاردی به عنوان مدیر سابق مجله موفقیت رازهای کاربردی را بازگو می‌کند.',
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
      description: 'شاهکار تمثیلی و سیاسی جورج اورول که سرگذشت حیوانات یک مزرعه پس از انقلاب علیه اربابشان را روایت می‌کند.',
      price: 75000,
      condition_status: 'used',
      image_url: 'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?w=600',
      stock: 1,
      status: 'available'
    },
    {
      id: 6,
      seller_id: 1,
      category_id: 3,
      title: 'انسان خردمند: تاریخ مختصر بشر',
      author: 'یووال نوح هراری',
      isbn: '978-600-690-345-2',
      description: 'کاوشی جامع و هیجان‌انگیز در تاریخ تکامل نوع بشر از عصر حجر تا جهان معاصر.',
      price: 240000,
      condition_status: 'new',
      image_url: 'https://images.unsplash.com/photo-1495640388908-05fa85288e61?w=600',
      stock: 2,
      status: 'available'
    }
  ];

  // Seed Fallback Store first
  fallbackStore.categories = [...initialCategories];
  fallbackStore.users = [...initialUsers];
  fallbackStore.books = [...initialBooks];
  fallbackStore.reviews = [
    {
      id: 1,
      book_id: 1,
      user_id: 2,
      rating: 5,
      comment: 'کتاب فوق‌العاده کاربردی بود، ارسال فروشنده هم سریع و تمیز بود.',
      created_at: new Date()
    }
  ];

  // If MySQL is active, seed MySQL tables
  if (isUsingMySQL()) {
    const conn = await getPool().getConnection();
    try {
      // Check if users table has records
      const [existingUsers] = await conn.query('SELECT COUNT(*) as count FROM users');
      if (existingUsers[0].count === 0) {
        console.log('Seeding MySQL categories...');
        for (const cat of initialCategories) {
          await conn.query(
            'INSERT IGNORE INTO categories (id, name, slug, icon) VALUES (?, ?, ?, ?)',
            [cat.id, cat.name, cat.slug, cat.icon]
          );
        }

        console.log('Seeding MySQL users...');
        for (const u of initialUsers) {
          await conn.query(
            'INSERT IGNORE INTO users (id, name, email, phone, password, wallet_balance, avatar) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [u.id, u.name, u.email, u.phone, u.password, u.wallet_balance, u.avatar]
          );
        }

        console.log('Seeding MySQL books...');
        for (const b of initialBooks) {
          await conn.query(
            `INSERT IGNORE INTO books (id, seller_id, category_id, title, author, isbn, description, price, condition_status, image_url, stock, status)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [b.id, b.seller_id, b.category_id, b.title, b.author, b.isbn, b.description, b.price, b.condition_status, b.image_url, b.stock, b.status]
          );
        }

        console.log('Seeding completed successfully in MySQL!');
      }
    } catch (err) {
      console.warn('Seed error in MySQL:', err.message);
    } finally {
      conn.release();
    }
  }
}
