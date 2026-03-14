import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'payment_screen.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/center_model.dart';
import '../models/appointment_model.dart';
import '../constants.dart';
import '../widgets/app_widgets.dart';

class BookAppointmentScreen extends StatefulWidget {
  final CenterModel center;
  const BookAppointmentScreen({super.key, required this.center});
  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _marqueCtrl = TextEditingController();
  final _modeleCtrl = TextEditingController();
  final _immatCtrl  = TextEditingController();
  final _anneeCtrl  = TextEditingController();
  final _msgCtrl    = TextEditingController();
  final _fs   = FirestoreService();
  final _auth = AuthService();

  String? _vehicleType;
  String? _selectedTime;
  String  _paymentMethod = 'center';
  DateTime? _selectedDate;
  bool _loading = false;

  final List<String> _types = [
    'سيارة سياحية (VL)',
    'عربة خفيفة متعددة الاستخدامات (VUL)',
    'شاحنة ثقيلة (PL)',
    'دراجة نارية / تريسيكل',
    'حافلة نقل عام (TC)',
    'مركبة خاصة بذوي الاحتياجات',
  ];

  @override
  void dispose() {
    for (final c in [_marqueCtrl, _modeleCtrl, _immatCtrl, _anneeCtrl, _msgCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 60)),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
            textTheme: GoogleFonts.cairoTextTheme(),
          ),
          child: child!,
        );
      },
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  String _fmtDateAr(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      showError(context, 'يرجى اختيار تاريخ'); return;
    }
    if (_selectedTime == null) {
      showError(context, 'يرجى اختيار وقت'); return;
    }
    if (_vehicleType == null) {
      showError(context, 'يرجى اختيار نوع المركبة'); return;
    }

    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final user = await _auth.getUserById(uid);
      final a = AppointmentModel(
        userId: uid,
        clientName: user?.fullName ?? '',
        centerId: widget.center.id,
        centerName: widget.center.name,
        marque: _marqueCtrl.text.trim(),
        modele: _modeleCtrl.text.trim(),
        immatriculation: _immatCtrl.text.trim().toUpperCase(),
        annee: _anneeCtrl.text.trim(),
        vehicleType: _vehicleType!,
        date: _fmtDate(_selectedDate!),
        time: _selectedTime!,
        message: _msgCtrl.text.trim(),
        paymentMethod: _paymentMethod,
        createdAt: DateTime.now(),
      );
      final createdA = await _fs.createAppointment(a);
      if (!mounted) return;
      
      if (_paymentMethod == 'online') {
        // Create an appointment instance with the fake ID for the payment screen
        final apptForPayment = AppointmentModel.fromMap(createdA, a.toMap());
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PaymentScreen(appointment: apptForPayment)),
        );
      } else {
        showSuccess(context, '✅ تم تأكيد موعدك بنجاح!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showError(context,
            e.toString().contains('محجوز')
                ? '⚠️ هذا الوقت محجوز، اختر وقتاً آخر'
                : 'حدث خطأ: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('حجز موعد', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCenterCard(),
              const SizedBox(height: 24),

              SectionCard(
                icon: Icons.directions_car_filled_rounded,
                title: 'معلومات السيارة',
                child: Column(
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Expanded(child: _buildTF(_marqueCtrl, 'الماركة', Icons.branding_watermark_rounded)),
                        const SizedBox(width: 14),
                        Expanded(child: _buildTF(_modeleCtrl, 'الطراز', Icons.directions_car_rounded)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTF(
                      _immatCtrl, 
                      'رقم التسجيل', 
                      Icons.confirmation_number_rounded,
                      dir: TextDirection.ltr,
                      hint: '123456-001-16',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _anneeCtrl,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                            decoration: const InputDecoration(
                              labelText: 'سنة الصنع',
                              prefixIcon: Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'مطلوب';
                              final y = int.tryParse(v);
                              if (y == null || y < 1960 || y > 2026) return 'غير صحيح';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: _buildTypeDropdown()),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              SectionCard(
                icon: Icons.access_time_filled_rounded,
                title: 'التاريخ والوقت',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDatePickerTrigger(),
                    const SizedBox(height: 20),
                    Text(
                      'اختر وقتاً مناسباً',
                      style: GoogleFonts.cairo(
                        color: AppColors.textLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 12),
                    _buildTimeSlots(),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              SectionCard(
                icon: Icons.payment_rounded,
                title: 'طريقة الدفع',
                child: Column(
                  children: [
                    _buildPayOption('online', 'البطاقة الذهبية / Baridimob', 'ادفع الآن سريعاً وبأمان', Icons.credit_card_rounded),
                    const SizedBox(height: 12),
                    _buildPayOption('center', 'الدفع في المركز', 'ادفع عند حضورك للمركز', Icons.store_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              SectionCard(
                icon: Icons.edit_note_rounded,
                title: 'ملاحظات إضافية',
                child: TextFormField(
                  controller: _msgCtrl,
                  maxLines: 3,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'أكتب أي ملاحظة هنا (اختياري)...',
                    hintStyle: GoogleFonts.cairo(color: AppColors.textGrey),
                    filled: true,
                    fillColor: AppColors.bg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              LoadingButton(
                loading: _loading,
                onPressed: _submit,
                label: 'تأكيد حجز الموعد',
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.location_on_rounded, color: AppColors.orange, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.center.name,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                Text(
                  widget.center.address,
                  style: GoogleFonts.cairo(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTF(TextEditingController ctrl, String label, IconData icon, {TextDirection dir = TextDirection.rtl, String? hint}) {
    return TextFormField(
      controller: ctrl,
      textDirection: dir,
      style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: GoogleFonts.cairo(fontSize: 12),
        prefixIcon: Icon(icon, color: AppColors.primary),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
    );
  }

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _vehicleType,
      isExpanded: true,
      style: GoogleFonts.cairo(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 13),
      decoration: const InputDecoration(
        labelText: 'الصنف',
        prefixIcon: Icon(Icons.category_rounded, color: AppColors.primary),
      ),
      items: _types.map((t) => DropdownMenuItem(
        value: t,
        child: Text(t, textDirection: TextDirection.rtl, overflow: TextOverflow.ellipsis),
      )).toList(),
      onChanged: (v) => setState(() => _vehicleType = v),
      validator: (v) => v == null ? 'مطلوب' : null,
    );
  }

  Widget _buildDatePickerTrigger() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider.withOpacity(0.8)),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
            const SizedBox(width: 16),
            Text(
              _selectedDate != null ? _fmtDateAr(_selectedDate!) : 'اختر تاريخ الموعد',
              style: GoogleFonts.cairo(
                color: _selectedDate != null ? AppColors.textDark : AppColors.textLight,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            const Icon(Icons.expand_more_rounded, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlots() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: widget.center.timeSlots.map((t) {
        final sel = _selectedTime == t;
        return GestureDetector(
          onTap: () => setState(() => _selectedTime = t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: sel ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: sel ? AppColors.primary : AppColors.divider, width: 2),
              boxShadow: sel ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
            ),
            child: Text(
              t,
              style: GoogleFonts.cairo(
                color: sel ? Colors.white : AppColors.textDark,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPayOption(String value, String label, String subtitle, IconData icon, {bool disabled = false}) {
    final sel = _paymentMethod == value;
    return GestureDetector(
      onTap: disabled ? null : () => setState(() => _paymentMethod = value),
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: sel ? AppColors.primary.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: sel ? AppColors.primary : AppColors.divider, width: sel ? 2 : 1),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : AppColors.bg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: sel ? Colors.white : AppColors.textGrey, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 15, color: sel ? AppColors.primary : AppColors.textDark),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.cairo(color: AppColors.textGrey, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Radio<String>(
                value: value,
                groupValue: _paymentMethod,
                onChanged: disabled ? null : (v) => setState(() => _paymentMethod = v!),
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

