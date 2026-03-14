import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../constants.dart';
import '../widgets/app_widgets.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _firstCtrl  = TextEditingController();
  final _lastCtrl   = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _confCtrl   = TextEditingController();
  final _auth = AuthService();
  bool _ob1 = true, _ob2 = true, _loading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.signUp(
        firstName: _firstCtrl.text,
        lastName:  _lastCtrl.text,
        email:     _emailCtrl.text,
        phone:     _phoneCtrl.text,
        password:  _passCtrl.text,
      );
      if (!mounted) return;
      showSuccess(context, 'تم إنشاء الحساب بنجاح ✅');
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      if (mounted) showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('إنشاء حساب جديد', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('أنشئ حسابك',
                  style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark),
                  textDirection: TextDirection.rtl),
              Text('أدخل معلوماتك الشخصية للمتابعة',
                  style: GoogleFonts.cairo(color: AppColors.textGrey, fontSize: 14, fontWeight: FontWeight.w600),
                  textDirection: TextDirection.rtl),
              const SizedBox(height: 32),

              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: _buildField(_firstCtrl, 'الاسم الأول', Icons.person_outline_rounded),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildField(_lastCtrl, 'اللقب', Icons.person_outline_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildField(
                _emailCtrl, 
                'البريد الإلكتروني', 
                Icons.email_outlined,
                keyboard: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@')) ? 'بريد إلكتروني غير صحيح' : null,
              ),
              const SizedBox(height: 16),

              _buildField(
                _phoneCtrl, 
                'رقم الهاتف', 
                Icons.phone_outlined,
                keyboard: TextInputType.phone,
                validator: (v) => (v == null || v.length < 9) ? 'رقم غير صحيح' : null,
              ),
              const SizedBox(height: 16),

              _buildField(
                _passCtrl, 
                'كلمة المرور', 
                Icons.lock_outlined,
                isPassword: true,
                obscure: _ob1,
                onToggle: () => setState(() => _ob1 = !_ob1),
                validator: (v) => (v == null || v.length < 6) ? '6 أحرف على الأقل' : null,
              ),
              const SizedBox(height: 16),

              _buildField(
                _confCtrl, 
                'تأكيد كلمة المرور', 
                Icons.lock_reset_outlined,
                isPassword: true,
                obscure: _ob2,
                onToggle: () => setState(() => _ob2 = !_ob2),
                validator: (v) => v != _passCtrl.text ? 'كلمتا المرور غير متطابقتين' : null,
              ),
              const SizedBox(height: 40),

              LoadingButton(
                loading: _loading, 
                onPressed: _register, 
                label: 'إنشاء الحساب',
              ),
              const SizedBox(height: 24),

              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.cairo(fontSize: 14),
                    children: [
                      const TextSpan(text: 'لديك حساب بالفعل؟ ', style: TextStyle(color: AppColors.textGrey)),
                      TextSpan(
                        text: 'تسجيل الدخول', 
                        style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && obscure,
      keyboardType: keyboard,
      style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textLight,
                ),
                onPressed: onToggle,
              )
            : null,
      ),
      validator: validator ?? (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
    );
  }
}

