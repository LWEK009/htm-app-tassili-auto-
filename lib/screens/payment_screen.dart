import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/appointment_model.dart';
import '../services/firestore_service.dart';
import '../constants.dart';
import '../widgets/app_widgets.dart';

class PaymentScreen extends StatefulWidget {
  final AppointmentModel appointment;
  const PaymentScreen({super.key, required this.appointment});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // Edahabia Controllers
  final _cardCtrl = TextEditingController(text: '6280 1234 5678 9012');
  final _nameCtrl = TextEditingController(text: 'OUAKIL MOHAMED');
  final _expCtrl  = TextEditingController(text: '08/28');
  final _cvvCtrl  = TextEditingController(text: '123');
  
  // Baridimob Controllers
  final _ripCtrl = TextEditingController(text: '00799999001234567890');
  final _otpCtrl = TextEditingController();
  
  bool _processing = false;
  bool _success = false;
  bool _waitingOtp = false;
  String _paymentType = 'edahabia'; // 'edahabia' | 'baridimob'

  @override
  void dispose() {
    _cardCtrl.dispose(); _nameCtrl.dispose();
    _expCtrl.dispose();  _cvvCtrl.dispose();
    _ripCtrl.dispose();  _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    // Basic validation
    if (_paymentType == 'baridimob' && !_waitingOtp) {
      if (_ripCtrl.text.length < 20) {
        showError(context, 'يرجى إدخال رقم الـ RIP كاملاً (20 رقم)');
        return;
      }
      setState(() => _processing = true);
      await Future.delayed(const Duration(seconds: 2));
      setState(() { _processing = false; _waitingOtp = true; });
      showSuccess(context, 'تم إرسال رمز التحقق إلى هاتفك 📱');
      return;
    }

    if (_paymentType == 'edahabia') {
       if (_cardCtrl.text.isEmpty || _nameCtrl.text.isEmpty) {
         showError(context, 'يرجى إكمال بيانات البطاقة');
         return;
       }
    }

    setState(() => _processing = true);
    await Future.delayed(const Duration(seconds: 2));
    try {
      await FirestoreService().updatePayment(widget.appointment.id!, 'paid');
    } catch (_) {}
    if (!mounted) return;
    setState(() { _processing = false; _success = true; });
  }

  @override
  Widget build(BuildContext context) {
    if (_success) return _successScreen();

    final a = widget.appointment;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('دفع إلكتروني جزائري', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (_waitingOtp) setState(() => _waitingOtp = false);
            else Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_waitingOtp) ...[
              _buildTypeSelector(),
              const SizedBox(height: 24),
              _buildBillSummary(a),
              const SizedBox(height: 32),
              if (_paymentType == 'edahabia') ...[
                _buildEdahabiaCard(),
                const SizedBox(height: 32),
                _buildCardForm(),
              ] else ...[
                _buildBaridimobForm(),
              ],
            ] else ...[
              _buildOtpScreen(),
            ],
            
            const SizedBox(height: 24),
            _buildSimulationWarning(),

            const SizedBox(height: 32),
            LoadingButton(
              label: _waitingOtp ? 'تـأكيد الدفع الآن' : (_paymentType == 'baridimob' ? 'تحقق من الحساب' : 'تأكيد عملية الدفع'),
              onPressed: _pay,
              loading: _processing,
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppShadows.soft),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          _buildTypeBtn('edahabia', 'البطاقة الذهبية', Icons.credit_card_rounded),
          _buildTypeBtn('baridimob', 'BaridiMob', Icons.phone_android_rounded),
        ],
      ),
    );
  }

  Widget _buildTypeBtn(String type, String label, IconData icon) {
    bool sel = _paymentType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: sel ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: sel ? Colors.white : AppColors.textLight, size: 18),
              const SizedBox(width: 8),
              Text(label, style: GoogleFonts.cairo(color: sel ? Colors.white : AppColors.textGrey, fontWeight: FontWeight.w900, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillSummary(AppointmentModel a) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.primary.withOpacity(0.1))),
      child: Column(
        children: [
          Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المبلغ الإجمالي:', style: GoogleFonts.cairo(fontWeight: FontWeight.w700, color: AppColors.textGrey)),
              Text('2 500 دج', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.primary)),
            ],
          ),
          const Divider(height: 24),
          _summaryRow(Icons.pin_rounded, 'رمز الحجز', '#${a.id?.substring(0, 8).toUpperCase() ?? "NEW"}'),
          const SizedBox(height: 8),
          _summaryRow(Icons.location_on_rounded, 'المركز', a.centerName),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData i, String l, String v) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Icon(i, size: 16, color: AppColors.textLight),
        const SizedBox(width: 8),
        Text(l, style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textGrey)),
        const Spacer(),
        Text(v, style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textDark)),
      ],
    );
  }

  Widget _buildEdahabiaCard() {
    return Container(
      height: 210,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.grey[900]!, Colors.grey[800]!], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/c/c4/Logo_Alg%C3%A9rie_Poste.svg/1200px-Logo_Alg%C3%A9rie_Poste.svg.png', height: 40, errorBuilder: (_,__,___) => const Icon(Icons.account_balance, color: Colors.amber, size: 30)),
              Text('EDAHABIA', style: GoogleFonts.exo2(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2)),
            ],
          ),
          const Spacer(),
          Text(_cardCtrl.text.isEmpty ? '**** **** **** ****' : _cardCtrl.text, style: GoogleFonts.exo2(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 3)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _cardInfo('HOLDER NAME', _nameCtrl.text),
              _cardInfo('EXPIRY', _expCtrl.text),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardInfo(String l, String v) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l, style: GoogleFonts.exo2(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold)),
      Text(v, style: GoogleFonts.exo2(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildCardForm() {
    return Column(
      children: [
        _field(_cardCtrl, 'رقم البطاقة الذهبية (16 رقم)', Icons.credit_card_rounded, keyboard: TextInputType.number, onChange: (_) => setState(() {})),
        const SizedBox(height: 16),
        _field(_nameCtrl, 'الاسم كما هو في البطاقة', Icons.person_rounded, onChange: (_) => setState(() {})),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _field(_expCtrl, 'تاريخ (MM/YY)', Icons.calendar_today_rounded, onChange: (_) => setState(() {}))),
            const SizedBox(width: 16),
            Expanded(child: _field(_cvvCtrl, 'رمز CVV', Icons.lock_rounded, obscure: true, keyboard: TextInputType.number)),
          ],
        ),
      ],
    );
  }

  Widget _buildBaridimobForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AppShadows.soft),
      child: Column(
        children: [
          Image.network('https://www.poste.dz/storage/baridimob_logo.png', height: 60, errorBuilder: (_,__,___) => const Icon(Icons.phone_android, color: Colors.blue, size: 40)),
          const SizedBox(height: 24),
          Text('الدفع عبر تطبيق BaridiMob', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 8),
          Text('أدخل رقم الـ RIP الخاص بحسابك البريدي للتحقق', style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textGrey), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          _field(_ripCtrl, 'رقم الـ RIP المكون من 20 رقم', Icons.account_balance_wallet_rounded, keyboard: TextInputType.number),
        ],
      ),
    );
  }

  Widget _buildOtpScreen() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AppShadows.soft),
      child: Column(
        children: [
          const Icon(Icons.mark_email_read_rounded, size: 60, color: AppColors.primary),
          const SizedBox(height: 20),
          Text('رمز التحقق (OTP)', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 8),
          Text('أدخل الرمز المكون من 6 أرقام المرسل إلى هاتفك المرتبط بـ BaridiMob', style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textGrey), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: GoogleFonts.exo2(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.primary, letterSpacing: 10),
            decoration: InputDecoration(
              hintText: '000000',
              hintStyle: TextStyle(color: AppColors.divider, letterSpacing: 10),
              counterText: '',
              filled: true,
              fillColor: AppColors.bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => showSuccess(context, 'تم إعادة إرسال الرمز'),
            child: Text('إعادة إرسال الرمز؟', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: AppColors.orange)),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String l, IconData i, {bool obscure = false, TextInputType? keyboard, Function(String)? onChange}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboard,
      onChanged: onChange,
      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
      decoration: InputDecoration(
        labelText: l,
        prefixIcon: Icon(i, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.divider.withOpacity(0.5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
  }

  Widget _buildSimulationWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.amber.withOpacity(0.2))),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          const Icon(Icons.security_rounded, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text('بيئة دفع تجريبية آمنة — لن يتم خصم مبالغ حقيقية من بطاقتك أو حسابك البريدي.', style: GoogleFonts.cairo(color: Colors.brown, fontSize: 11, fontWeight: FontWeight.w800), textDirection: TextDirection.rtl)),
        ],
      ),
    );
  }

  Widget _successScreen() => Scaffold(
    backgroundColor: Colors.white,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, size: 100, color: AppColors.success),
            const SizedBox(height: 32),
            Text('تم الدفع بنجاح!', style: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.success)),
            const SizedBox(height: 12),
            Text('لقد استلمنا المبلغ، موعدك مؤكد الآن.', style: GoogleFonts.cairo(color: AppColors.textLight, fontWeight: FontWeight.w700, fontSize: 15), textAlign: TextAlign.center),
            const SizedBox(height: 60),
            LoadingButton(
              label: 'العودة للرئيسية',
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              loading: false,
            ),
          ],
        ),
      ),
    ),
  );
}
