import crypto from 'crypto';

let bcryptModule = null;
try {
  bcryptModule = await import('bcrypt');
} catch (e) {
  try {
    bcryptModule = await import('bcryptjs');
  } catch (_) {
    bcryptModule = null;
  }
}

export async function hashPassword(password) {
  if (bcryptModule && bcryptModule.hash) {
    return await bcryptModule.hash(password, 10);
  }
  // Native fallback using SHA256 + salt
  const salt = crypto.randomBytes(16).toString('hex');
  const hash = crypto.pbkdf2Sync(password, salt, 1000, 64, 'sha256').toString('hex');
  return `sha256$${salt}$${hash}`;
}

export async function comparePassword(password, storedHash) {
  if (storedHash.startsWith('sha256$')) {
    const parts = storedHash.split('$');
    const salt = parts[1];
    const originalHash = parts[2];
    const hash = crypto.pbkdf2Sync(password, salt, 1000, 64, 'sha256').toString('hex');
    return hash === originalHash;
  }

  if (bcryptModule && bcryptModule.compare) {
    return await bcryptModule.compare(password, storedHash);
  }

  return false;
}
