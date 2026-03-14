import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import '../models/appointment_model.dart';
import '../widgets/appointment_card.dart';
import '../widgets/app_widgets.dart';
import '../constants.dart';
import 'inspection_result_screen.dart';
import 'payment_screen.dart';

class AppointmentListScreen extends StatefulWidget {
  final String userId;
  const AppointmentListScreen({super.key, required this.userId});
  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _fs = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTabs(),
        Expanded(
          child: StreamBuilder<List<AppointmentModel>>(
            stream: _fs.clientAppointmentsStream(widget.userId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              }
              if (snap.hasError) {
                return const EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'حدث خطأ',
                  subtitle: 'تعذر تحميل قائمة المواعيد حالياً',
                );
              }
              final all = snap.data ?? [];
              final active    = all.where((a) => a.status == 'pending' || a.status == 'confirmed').toList();
              final done      = all.where((a) => a.status == 'done').toList();
              final cancelled = all.where((a) => a.status == 'cancelled' || a.status == 'expired').toList();

              return TabBarView(
                controller: _tabs,
                children: [
                  _listView(active, 'لا توجد مواعيد نشطة', 'احجز موعداً جديداً من الصفحة الرئيسية'),
                  _listView(done, 'سجل المواعيد فارغ', 'ستظهر المواعيد المكتملة هنا'),
                  _listView(cancelled, 'لا توجد مواعيد ملغاة', 'المواعيد التي قمت بإلغائها ستظهر هنا'),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: TabBar(
        controller: _tabs,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.primary,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textLight,
        labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 13),
        indicatorSize: TabBarIndicatorSize.tab,
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'نشطة'),
          Tab(text: 'منتهية'),
          Tab(text: 'ملغاة'),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: SkeletonLoader(
          height: 180,
          borderRadius: 24,
        ),
      ),
    );
  }

  Widget _listView(List<AppointmentModel> list, String title, String subtitle) {
    if (list.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: EmptyState(
            icon: Icons.calendar_today_rounded,
            title: title,
            subtitle: subtitle,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final a = list[i];
        return AppointmentCard(
          appointment: a,
          onCancel: (a.status != 'cancelled' && a.status != 'done')
              ? () => _cancel(a.id!)
              : null,
          onPay: (a.paymentStatus == 'unpaid' &&
                  a.paymentMethod == 'online' &&
                  a.status != 'cancelled')
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PaymentScreen(appointment: a)),
                  )
              : null,
          onViewResult: a.status == 'done'
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            InspectionResultScreen(appointment: a)),
                  )
              : null,
        );
      },
    );
  }

  Future<void> _cancel(String id) async {
    final ok = await showConfirmDialog(
      context,
      'إلغاء الموعد',
      'هل أنت متأكد من رغبتك في إلغاء هذا الموعد؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmLabel: 'نعم، إلغاء الموعد',
    );
    if (ok != true || !mounted) return;
    
    // Simple state change would stay here, but showing success
    await _fs.cancel(id);
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text('تم إلغاء الموعد بنجاح', style: GoogleFonts.cairo()),
           backgroundColor: AppColors.error,
           behavior: SnackBarBehavior.floating,
         )
       );
    }
  }
}

