import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/appointment_model.dart';
import '../services/firestore_service.dart';
import '../constants.dart';
import '../widgets/app_widgets.dart';

class InspectionResultScreen extends StatefulWidget {
  final AppointmentModel appointment;
  const InspectionResultScreen({super.key, required this.appointment});
  @override
  State<InspectionResultScreen> createState() => _InspectionResultScreenState();
}

class _InspectionResultScreenState extends State<InspectionResultScreen> {
  bool _responding = false;

  Color _itemColor(String status) {
    switch (status) {
      case 'ok':      return AppColors.success;
      case 'warning': return AppColors.orange;
      case 'fail':    return AppColors.error;
      default:        return AppColors.textGrey;
    }
  }

  IconData _itemIcon(String status) {
    switch (status) {
      case 'ok':      return Icons.check_circle_rounded;
      case 'warning': return Icons.warning_amber_rounded;
      case 'fail':    return Icons.cancel_rounded;
      default:        return Icons.help_outline;
    }
  }

  String _itemLabel(String status) {
    switch (status) {
      case 'ok':      return 'سليم';
      case 'warning': return 'تحذير';
      case 'fail':    return 'مشكلة';
      default:        return '';
    }
  }

  Future<void> _respond(bool accepted) async {
    setState(() => _responding = true);
    try {
      await FirestoreService().respondRepair(widget.appointment.id!, accepted);
      if (!mounted) return;
      showSuccess(context, accepted
          ? '✅ تم قبول الإصلاح، سيتم التواصل معك قريباً'
          : 'تم رفض اقتراح الإصلاح');
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _responding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.appointment;
    final ok    = a.inspectionItems.where((i) => i.status == 'ok').length;
    final warn  = a.inspectionItems.where((i) => i.status == 'warning').length;
    final fail  = a.inspectionItems.where((i) => i.status == 'fail').length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('تقرير الفحص التقني', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Vehicle Header ──
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.directions_car_filled_rounded, color: AppColors.orange, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${a.marque} ${a.modele}',
                              style: GoogleFonts.cairo(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                              textDirection: TextDirection.rtl,
                            ),
                            Text(
                              a.immatriculation,
                              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      const Icon(Icons.apartment_rounded, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text(a.centerName, style: GoogleFonts.cairo(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text(a.date, style: GoogleFonts.cairo(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Quick Summary ──
             _buildSectionTitle('ملخص الفحص'),
             const SizedBox(height: 12),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(child: _SumCard(ok, 'سليم', AppColors.success, Icons.check_circle_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _SumCard(warn, 'تحذير', AppColors.orange, Icons.warning_amber_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _SumCard(fail, 'مشكلة', AppColors.error, Icons.cancel_rounded)),
              ],
            ),
            const SizedBox(height: 32),

            // ── Detailed Results ──
            _buildSectionTitle('التفاصيل الفنية'),
            const SizedBox(height: 12),
            if (a.inspectionItems.isEmpty)
              const EmptyState(icon: Icons.assignment_late_rounded, title: 'النتائج معلقة', subtitle: 'سيقوم الخبير بتحديث النتائج قريباً')
            else
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AppShadows.soft),
                child: Column(
                  children: a.inspectionItems.map((item) {
                    final color = _itemColor(item.status);
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.bg, width: 2))),
                      child: Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(_itemIcon(item.status), color: color, size: 20)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textDark), textDirection: TextDirection.rtl),
                                if (item.note.isNotEmpty) Text(item.note, style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w600), textDirection: TextDirection.rtl),
                              ],
                            ),
                          ),
                          StatusBadge(label: _itemLabel(item.status), color: color, icon: _itemIcon(item.status)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            
            // ── Repair Suggestion ──
            if (a.hasIssues && a.repairProposed && !a.repairAccepted) ...[
               const SizedBox(height: 32),
               _buildRepairProposal(),
            ],

            if (a.repairAccepted) ...[
              const SizedBox(height: 32),
              _buildRepairStatus('تم قبول الإصلاح بنجاح ✅\nسيقوم فريقنا بالتواصل معك لتنسيق الموعد'),
            ],
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark), textDirection: TextDirection.rtl);

  Widget _buildRepairProposal() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.08), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.orange.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              const Icon(Icons.build_circle_rounded, color: AppColors.orange, size: 28),
              const SizedBox(width: 12),
              Text('اقتراح إصلاح معتمد', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'بناءً على نتائج الفحص، حدد خبراؤنا بعض القطع التي تحتاج التدخل. هل ترغب في تولي المركز عملية الإصلاح بضمان الجودة؟',
            style: GoogleFonts.cairo(color: AppColors.textDark, fontSize: 13, height: 1.6, fontWeight: FontWeight.w600),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 24),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: LoadingButton(
                  label: 'قبول الإصلاح',
                  loading: _responding,
                  onPressed: () => _respond(true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: _responding ? null : () => _respond(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('رفض العرض', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRepairStatus(String msg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.success.withOpacity(0.3))),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.success, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(msg, style: GoogleFonts.cairo(color: AppColors.success, fontWeight: FontWeight.w800, height: 1.5), textDirection: TextDirection.rtl)),
        ],
      ),
    );
  }
}

class _SumCard extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;
  const _SumCard(this.count, this.label, this.color, this.icon);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))]),
    child: Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text('$count', style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w800), textDirection: TextDirection.rtl),
      ],
    ),
  );
}
