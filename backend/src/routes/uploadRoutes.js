import { Router } from 'express';
import { upload } from '../middleware/upload.js';
import { authenticate } from '../middleware/auth.js';

const router = Router();

router.post('/', authenticate, upload.single('image'), (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'فایلی انتخاب نشده است' });
    }

    const host = req.get('host');
    const protocol = req.protocol;
    const fileUrl = `${protocol}://${host}/uploads/${req.file.filename}`;

    return res.json({
      success: true,
      message: 'تصویر با موفقیت آپلود شد',
      data: {
        url: fileUrl,
        filename: req.file.filename
      }
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'خطا در آپلود تصویر' });
  }
});

export default router;
