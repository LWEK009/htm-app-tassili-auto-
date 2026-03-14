import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../constants.dart';
import '../widgets/app_widgets.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _auth = AuthService();
  bool _obscure = true;
  bool _loading = false;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await _auth.signIn(
          email: _emailCtrl.text, password: _passCtrl.text);
      if (!mounted) return;
      if (user?.role == 'admin') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } catch (e) {
      if (mounted) showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Cinematic Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, Color(0xFF0F172A), AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          // Floating Shapes for Depth
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  
                  // Logo with Pulse effect (simulated with shadow/glow)
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(55),
                      child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                        text: 'Tassili ',
                        style: GoogleFonts.cairo(
                            color: AppColors.orange,
                            fontSize: 34,
                            fontWeight: FontWeight.w900),
                      ),
                      TextSpan(
                        text: 'AutoContrôle',
                        style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'الفحص التقني للسيارات',
                    style: GoogleFonts.cairo(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                    textDirection: TextDirection.rtl,
                  ),
                  
                  const SizedBox(height: 50),

                  // Glassmorphism Form Card
                  GlassContainer(
                    opacity: 0.08,
                    blur: 20,
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('تسجيل الدخول',
                              style: GoogleFonts.cairo(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white),
                              textDirection: TextDirection.rtl),
                          const SizedBox(height: 4),
                          Text('أدخل بياناتك للمتابعة',
                              style: GoogleFonts.cairo(
                                  color: Colors.white60, fontSize: 14),
                              textDirection: TextDirection.rtl),
                          const SizedBox(height: 32),

                          _buildTextField(
                            controller: _emailCtrl,
                            label: 'البريد الإلكتروني',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => (v == null || !v.contains('@')) ? 'بريد إلكتروني غير صحيح' : null,
                          ),
                          const SizedBox(height: 20),

                          _buildTextField(
                            controller: _passCtrl,
                            label: 'كلمة المرور',
                            icon: Icons.lock_outlined,
                            isPassword: true,
                            obscure: _obscure,
                            onToggleVisibility: () => setState(() => _obscure = !_obscure),
                            validator: (v) => (v == null || v.length < 6) ? '6 أحرف على الأقل' : null,
                          ),
                          const SizedBox(height: 40),

                          LoadingButton(
                            loading: _loading,
                            onPressed: _signIn,
                            label: 'تسجيل الدخول',
                          ),
                          const SizedBox(height: 24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            textDirection: TextDirection.rtl,
                            children: [
                              Text('ليس لديك حساب؟  ',
                                  style: GoogleFonts.cairo(color: Colors.white60)),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const RegisterScreen())),
                                child: Text(
                                  'إنشاء حساب',
                                  style: GoogleFonts.cairo(
                                      color: AppColors.orange,
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
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
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: AppColors.orange),
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.orange, width: 2),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.white38,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
      ),
      validator: validator,
    );
  }
}

