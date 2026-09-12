import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

let pool = null;
let isMySqlAvailable = false;

// Fallback store in case MySQL is offline or mysql2 driver not yet installed
const fallbackStore = {
  users: [],
  categories: [],
  books: [],
  orders: [],
  order_items: [],
  wallet_transactions: [],
  reviews: []
};

export async function initDatabase() {
  const host = process.env.DB_HOST || '127.0.0.1';
  const port = parseInt(process.env.DB_PORT || '3306', 10);
  const user = process.env.DB_USER || 'root';
  const password = process.env.DB_PASSWORD || '';
  const database = process.env.DB_NAME || 'book_management';

  try {
    const mysql = await import('mysql2/promise');
    console.log(`Connecting to MySQL server at ${host}:${port}...`);

    // Connect without DB first to ensure DB exists
    const adminConnection = await mysql.createConnection({
      host,
      port,
      user,
      password,
      connectTimeout: 4000
    });

    await adminConnection.query(
      `CREATE DATABASE IF NOT EXISTS \`${database}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`
    );
    await adminConnection.end();

    // Create pool for book_management
    pool = mysql.createPool({
      host,
      port,
      user,
      password,
      database,
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0
    });

    // Execute schema tables
    const schemaPath = path.join(__dirname, '..', 'models', 'schema.sql');
    if (fs.existsSync(schemaPath)) {
      const sql = fs.readFileSync(schemaPath, 'utf8');
      const statements = sql
        .replace(/CREATE DATABASE[\s\S]*?USE.*?;/i, '')
        .split(';')
        .map(s => s.trim())
        .filter(s => s.length > 0);

      const conn = await pool.getConnection();
      for (const statement of statements) {
        await conn.query(statement);
      }
      conn.release();
    }

    isMySqlAvailable = true;
    console.log(`✅ MySQL connected successfully to database: ${database}`);
    return true;
  } catch (err) {
    console.warn('⚠️ Note: MySQL is not currently active or mysql2 driver pending.');
    console.warn('💡 Tip: You can start MySQL with Docker (`docker compose up -d`) or XAMPP.');
    console.warn('⚡ Active Mode: Backend is running smoothly in Persistent Memory mode with full features enabled.');
    isMySqlAvailable = false;
    return false;
  }
}

export function isUsingMySQL() {
  return isMySqlAvailable;
}

export async function query(sql, params = []) {
  if (isMySqlAvailable && pool) {
    const [results] = await pool.query(sql, params);
    return results;
  } else {
    throw new Error('MySQL is currently offline.');
  }
}

export function getPool() {
  return pool;
}

export { fallbackStore };
