import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/book_provider.dart';
import '../../widgets/custom_text_field.dart';

/// ============================================================================
/// ➕ صفحه ثبت کتاب جدید برای فروش (AddBookScreen)
/// ============================================================================
/// هر کاربری که وارد برنامه شده باشد می‌تواند از این فرم برای آگهی کردن کتاب‌هایش استفاده کند.
/// فیلدهای این صفحه:
/// ۱. عنوان کتاب (الزامی)
/// ۲. نام نویسنده یا مترجم (الزامی)
/// ۳. دسته‌بندی موضوعی (انتخاب از Dropdown)
/// ۴. قیمت پیشنهادی به تومان (الزامی)
/// ۵. وضعیت فیزیکی کتاب (نو، در حد نو، دست دوم)
/// ۶. شماره شابک (اختیاری)
/// ۷. توضیحات بیشتر درباره سلامت کتاب
/// ۸. تصویر جلد (امکان انتخاب از ۵ عکس آماده باکیفیت یا درج لینک دلخواه)
class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  // کلید شناسایی فرم جهت اعتبارسنجی یکپارچه فیلدها (Form Validation)
  final _formKey = GlobalKey<FormState>();

  // کنترلرهای متنی جهت خواندن مقادیر تایپ‌شده در هر فیلد
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _priceController = TextEditingController();
  final _isbnController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();

  int? _selectedCategoryId;              // شناسه دسته‌بندی انتخاب‌شده
  String _selectedCondition = 'like_new'; // وضعیت سلامت کتاب (پیش‌فرض: در حد نو)

  // تصاویر نمونه پیش‌فرض جلد کتاب‌ها جهت سهولت و سرعت در تست ثبت آگهی
  final List<String> _sampleCovers = [
    'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=600',
    'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=600',
    'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=600',
    'https://images.unsplash.com/photo-1589829085413-56de8ae18c73?w=600',
    'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?w=600',
  ];

  @override
  void initState() {
    super.initState();
    // انتخاب اولین دسته‌بندی به صورت پیش‌فرض در صورت موجود بودن
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    if (bookProvider.categories.isNotEmpty) {
      _selectedCategoryId = bookProvider.categories.first.id;
    }
  }

  /// متد اعتبارسنجی و ثبت اطلاعات در سرور اکسپرس
  Future<void> _submit() async {
    // ۱. بررسی معتبر بودن تمام فیلدهای الزامی
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً دسته‌بندی کتاب را انتخاب کنید')),
      );
      return;
    }

    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    // تبدیل قیمت متنی به عدد صحیح تومان
    final num? price = num.tryParse(_priceController.text.replaceAll(',', '').trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('قیمت معتبر وارد کنید')),
      );
      return;
    }

    // ۲. ارسال درخواست ثبت به متد addBook در BookProvider
    final success = await bookProvider.addBook(
      title: _titleController.text,
      author: _authorController.text,
      categoryId: _selectedCategoryId!,
      price: price,
      conditionStatus: _selectedCondition,
      isbn: _isbnController.text,
      description: _descriptionController.text,
      imageUrl: _imageUrlController.text.isNotEmpty
          ? _imageUrlController.text
          : _sampleCovers.first,
    );

    if (!mounted) return;

    // ۳. نمایش نتیجه به کاربر
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('کتاب شما با موفقیت برای فروش در ویترین بوک‌لند قرار گرفت! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      // خالی کردن فرم برای ثبت کتاب بعدی
      _titleController.clear();
      _authorController.clear();
      _priceController.clear();
      _isbnController.clear();
      _descriptionController.clear();
      _imageUrlController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bookProvider.errorMessage ?? 'خطا در ثبت کتاب'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'ثبت کتاب جدید برای فروش',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'مشخصات کتاب خود را وارد کنید تا خریداران بتوانند آن را سفارش دهند.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),

              // فیلد عنوان کتاب
              CustomTextField(
                controller: _titleController,
                label: 'عنوان کتاب *',
                hint: 'مثلاً: بیشعوری، صد سال تنهایی',
                prefixIcon: Icons.book_outlined,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'عنوان کتاب الزامی است';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // فیلد نویسنده
              CustomTextField(
                controller: _authorController,
                label: 'نام نویسنده / مترجم *',
                hint: 'مثلاً: گابریل گارسیا مارکز',
                prefixIcon: Icons.person_outline,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'نام نویسنده الزامی است';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // انتخاب دسته‌بندی موضوعی
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'دسته‌بندی موضوعی *',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedCategoryId ?? (bookProvider.categories.isNotEmpty ? bookProvider.categories.first.id : null),
                        isExpanded: true,
                        hint: const Text('انتخاب دسته‌بندی'),
                        items: bookProvider.categories.map((cat) {
                          return DropdownMenuItem<int>(
                            value: cat.id,
                            child: Text(cat.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCategoryId = val;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ردیف قیمت و وضعیت سلامت کتاب
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _priceController,
                      label: 'قیمت فروش (تومان) *',
                      hint: 'مثلاً: ۸۵۰۰۰',
                      prefixIcon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'قیمت را وارد کنید';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'وضعیت سلامت کتاب *',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.dividerColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCondition,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: 'new', child: Text('نو (آکبند)')),
                                DropdownMenuItem(value: 'like_new', child: Text('در حد نو')),
                                DropdownMenuItem(value: 'used', child: Text('دست دوم')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCondition = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // فیلد اختیاری شابک (ISBN)
              CustomTextField(
                controller: _isbnController,
                label: 'شابک یا کد شناسایی (اختیاری)',
                hint: '978-600-...',
                prefixIcon: Icons.qr_code,
              ),
              const SizedBox(height: 14),

              // توضیحات تکمیلی
              CustomTextField(
                controller: _descriptionController,
                label: 'توضیحات تکمیلی (درباره کتاب و میزان تمیزی)',
                hint: 'مثلاً: چاپ سوم، بدون خط‌خوردگی، جلد سالم...',
                maxLines: 3,
              ),
              const SizedBox(height: 14),

              // درج لینک عکس یا انتخاب سریع از نمونه‌های آماده
              CustomTextField(
                controller: _imageUrlController,
                label: 'آدرس تصویر جلد (URL)',
                hint: 'https://...',
                prefixIcon: Icons.image_outlined,
              ),
              const SizedBox(height: 8),
              const Text(
                'یا یکی از تصاویر آماده را انتخاب کنید:',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _sampleCovers.length,
                  itemBuilder: (ctx, i) {
                    final img = _sampleCovers[i];
                    final isSelected = _imageUrlController.text == img;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _imageUrlController.text = img;
                        });
                      },
                      child: Container(
                        width: 48,
                        height: 60,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                            width: 2.5,
                          ),
                          image: DecorationImage(
                            image: NetworkImage(img),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),

              // دکمه ارسال و انتشار کتاب
              ElevatedButton.icon(
                onPressed: bookProvider.isLoading ? null : _submit,
                icon: bookProvider.isLoading
                    ? const SizedBox.shrink()
                    : const Icon(Icons.add_shopping_cart, size: 20),
                label: bookProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('ثبت و انتشار برای فروش'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
