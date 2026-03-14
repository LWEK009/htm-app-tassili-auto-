import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/appointment_model.dart';
import '../models/center_model.dart';
import '../widgets/app_widgets.dart';
import '../constants.dart';
import 'login_screen.dart';
import 'inspection_result_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _auth = AuthService();
  final _fs   = FirestoreService();

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

  Future<void> _signOut() async {
    final ok = await showConfirmDialog(
      context, 
      'تسجيل الخروج', 
      'هل أنت متأكد من رغبتك في تسجيل الخروج من لوحة التحكم؟',
      confirmLabel: 'تسجيل الخروج',
    );
    if (ok != true) return;
    
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Row(
          children: [
            Text('Tassili ', style: GoogleFonts.cairo(color: AppColors.orange, fontWeight: FontWeight.w900, fontSize: 18)),
            Text('Admin', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded),
            tooltip: 'تسجيل الخروج',
            onPressed: _signOut,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.orange,
          indicatorWeight: 4,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.auto_graph_rounded), text: 'الإحصائيات'),
            Tab(icon: Icon(Icons.event_note_rounded), text: 'المواعيد'),
            Tab(icon: Icon(Icons.account_balance_rounded), text: 'المراكز'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _StatsTab(fs: _fs),
          _AppointmentsTab(fs: _fs),
          _CentersTab(fs: _fs),
        ],
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  final FirestoreService fs;
  const _StatsTab({required this.fs});

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppointmentModel>>(
      stream: fs.allAppointmentsStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }
        final all = snap.data ?? [];
        final today = _todayStr();

        final total     = all.length;
        final todayC    = all.where((a) => a.date == today).length;
        final pending   = all.where((a) => a.status == 'pending').length;
        final confirmed = all.where((a) => a.status == 'confirmed').length;
        final done      = all.where((a) => a.status == 'done').length;
        final cancelled = all.where((a) => a.status == 'cancelled').length;
        final paid      = all.where((a) => a.paymentStatus == 'paid').length;
        final unpaid    = all.where((a) => a.paymentStatus == 'unpaid').length;

        final Map<String, int> centerMap = {};
        for (final a in all) {
          centerMap[a.centerName] = (centerMap[a.centerName] ?? 0) + 1;
        }
        final sortedCenters = centerMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('لمحة عامة'),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _StatCard('إجمالي المواعيد', '$total', Icons.analytics_rounded, AppColors.primary),
                  _StatCard("مواعيد اليوم", '$todayC', Icons.event_available_rounded, Colors.indigo),
                  _StatCard('قيد الانتظار', '$pending', Icons.hourglass_empty_rounded, AppColors.orange),
                  _StatCard('مواعيد مؤكدة', '$confirmed', Icons.verified_rounded, AppColors.primaryLight),
                  _StatCard('فحوصات مكتملة', '$done', Icons.task_alt_rounded, AppColors.success),
                  _StatCard('مواعيد ملغاة', '$cancelled', Icons.cancel_rounded, AppColors.error),
                  _StatCard('عمليات مدفوعة', '$paid', Icons.check_circle_rounded, AppColors.success),
                  _StatCard('دفع معلق', '$unpaid', Icons.error_rounded, AppColors.warning),
                ],
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('المراكز الأكثر تفاعلاً'),
              const SizedBox(height: 16),
              if (sortedCenters.isEmpty) _buildEmptyState()
              else ...sortedCenters.take(5).map((e) {
                final maxVal = sortedCenters.first.value.toDouble();
                final ratio = maxVal > 0 ? e.value / maxVal : 0.0;
                return _buildCenterProgress(e.key, e.value, ratio);
              }),
              const SizedBox(height: 32),
              _buildSectionTitle('توزيع المواعيد (7 أيام)'),
              const SizedBox(height: 16),
              _buildActivityChart(all),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoading() => const Center(child: CircularProgressIndicator(color: AppColors.primary));

  Widget _buildSectionTitle(String title) => Text(
    title,
    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark),
    textDirection: TextDirection.rtl,
  );

  Widget _buildEmptyState() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Text('لا توجد بيانات متاحة حالياً', style: GoogleFonts.cairo(color: AppColors.textGrey), textDirection: TextDirection.rtl, textAlign: TextAlign.center),
  );

  Widget _buildCenterProgress(String name, int count, double ratio) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              const Icon(Icons.location_city_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(name, style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 14), textDirection: TextDirection.rtl)),
              StatusBadge(label: '$count موعد', color: AppColors.primary.withOpacity(0.8), icon: Icons.event_rounded),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: AppColors.primary.withOpacity(0.05),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart(List<AppointmentModel> all) {
    final Map<String, int> dayMap = {};
    for (int i = 6; i >= 0; i--) {
      final d = DateTime.now().subtract(Duration(days: i));
      final key = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
      dayMap[key] = all.where((a) => a.date == key).length;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: dayMap.entries.map((e) {
          final maxV = dayMap.values.fold(0, (a, b) => a > b ? a : b);
          final ratio = maxV > 0 ? e.value / maxV : 0.0;
          final parts = e.key.split('-');
          final label = '${parts[2]}/${parts[1]}';
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                SizedBox(width: 45, child: Text(label, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textLight))),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: ratio,
                      backgroundColor: AppColors.orange.withOpacity(0.05),
                      valueColor: const AlwaysStoppedAnimation(AppColors.orange),
                      minHeight: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(width: 25, child: Text('${e.value}', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.orange))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AppointmentsTab extends StatefulWidget {
  final FirestoreService fs;
  const _AppointmentsTab({required this.fs});
  @override
  State<_AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<_AppointmentsTab> {
  String _statusFilter = 'الكل';
  String _centerFilter = 'الكل';
  String _searchText = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: StreamBuilder<List<AppointmentModel>>(
            stream: widget.fs.allAppointmentsStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final all = snap.data ?? [];
              final Map<String, String> statusMap = {
                'قيد الانتظار': 'pending',
                'مؤكد': 'confirmed',
                'مكتمل': 'done',
                'ملغى': 'cancelled',
              };

              var filtered = all;
              if (_statusFilter != 'الكل') filtered = filtered.where((a) => a.status == statusMap[_statusFilter]).toList();
              if (_centerFilter != 'الكل') filtered = filtered.where((a) => a.centerName == _centerFilter).toList();
              if (_searchText.isNotEmpty) {
                final q = _searchText.toLowerCase();
                filtered = filtered.where((a) => a.immatriculation.toLowerCase().contains(q) || a.clientName.toLowerCase().contains(q) || a.marque.toLowerCase().contains(q)).toList();
              }

              if (filtered.isEmpty) return const EmptyState(icon: Icons.search_off_rounded, title: 'لا توجد نتائج', subtitle: 'جرب تغيير معايير البحث');

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: filtered.length,
                itemBuilder: (context, i) => _AdminCard(filtered[i], widget.fs, context),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'بحث بالاسم، السيارة، أو رقم التسجيل...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
              suffixIcon: _searchText.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); setState(() => _searchText = ''); }) : null,
              filled: true,
              fillColor: AppColors.bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            onChanged: (v) => setState(() => _searchText = v),
          ),
          const SizedBox(height: 16),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(child: _DropFilter(label: 'الحالة', value: _statusFilter, items: ['الكل', 'قيد الانتظار', 'مؤكد', 'مكتمل', 'ملغى'], onChanged: (v) => setState(() => _statusFilter = v!))),
              const SizedBox(width: 12),
              // We could fetch dynamic centers here, but for now we keep it simple
              Expanded(child: _DropFilter(label: 'المركز', value: _centerFilter, items: [_centerFilter], onChanged: (v) => setState(() => _centerFilter = v!))),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final AppointmentModel a;
  final FirestoreService fs;
  final BuildContext ctx;
  const _AdminCard(this.a, this.fs, this.ctx);

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed': return AppColors.primary;
      case 'done':      return AppColors.success;
      case 'cancelled': return AppColors.error;
      default:          return AppColors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sc = _statusColor(a.status);
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppShadows.soft),
      child: Column(
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              CircleAvatar(backgroundColor: AppColors.orange.withOpacity(0.1), child: const Icon(Icons.person_rounded, color: AppColors.orange, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text(a.clientName.isNotEmpty ? a.clientName : 'عميل مجهول', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 14), textDirection: TextDirection.rtl)),
              StatusBadge(label: a.statusAr, color: sc, icon: Icons.circle_rounded),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          InfoRow(Icons.directions_car_rounded, '${a.immatriculation} — ${a.marque} ${a.modele}'),
          InfoRow(Icons.apartment_rounded, a.centerName),
          InfoRow(Icons.access_time_filled_rounded, '${a.date} • ${a.time}'),
          const SizedBox(height: 16),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        if (a.status == 'pending') ...[
          _ActionBtn('تأكيد', AppColors.primary, Icons.check_circle_rounded, () => fs.updateStatus(a.id!, 'confirmed')),
          const SizedBox(width: 8),
          _ActionBtn('إلغاء', AppColors.error, Icons.cancel_rounded, () => fs.updateStatus(a.id!, 'cancelled')),
        ],
        if (a.status == 'confirmed')
          _ActionBtn('إنهاء الفحص', AppColors.success, Icons.task_alt_rounded, () => fs.updateStatus(a.id!, 'done')),
        if (a.status == 'done')
          _ActionBtn('عرض التقرير', AppColors.primaryLight, Icons.assignment_rounded, () {
            Navigator.push(ctx, MaterialPageRoute(builder: (_) => InspectionResultScreen(appointment: a)));
          }),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionBtn(this.label, this.color, this.icon, this.onTap);
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.cairo(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    ),
  );
}

class _CentersTab extends StatelessWidget {
  final FirestoreService fs;
  const _CentersTab({required this.fs});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CenterModel>>(
      stream: fs.centersStream(),
      builder: (context, snap) {
        final list = snap.data ?? CenterModel.defaults;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          itemCount: list.length,
          itemBuilder: (context, i) => _CenterAdminCard(list[i], fs),
        );
      },
    );
  }
}

class _CenterAdminCard extends StatelessWidget {
  final CenterModel c;
  final FirestoreService fs;
  const _CenterAdminCard(this.c, this.fs);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AppShadows.soft),
      child: Column(
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.apartment_rounded, color: AppColors.primary)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.name, style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 15), textDirection: TextDirection.rtl),
                Text(c.city, style: GoogleFonts.cairo(color: AppColors.orange, fontSize: 12, fontWeight: FontWeight.w700)),
              ])),
              Column(
                children: [
                  Text(c.isActive ? 'مفتوح' : 'مغلق', style: GoogleFonts.cairo(color: c.isActive ? AppColors.success : AppColors.error, fontWeight: FontWeight.w900, fontSize: 11)),
                  Switch.adaptive(value: c.isActive, activeColor: AppColors.success, onChanged: (v) => fs.updateCenter(c.id, {'isActive': v})),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          InfoRow(Icons.location_on_rounded, c.address),
          InfoRow(Icons.access_time_filled_rounded, c.hours),
          InfoRow(Icons.phone_rounded, c.phone),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: c.timeSlots.map((t) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8)), child: Text(t, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)))).toList()),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: color.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 8))]),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
        const Spacer(),
        Text(value, style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w700), textDirection: TextDirection.rtl, maxLines: 1),
      ],
    ),
  );
}

class _DropFilter extends StatelessWidget {
  final String label, value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _DropFilter({required this.label, required this.value, required this.items, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(14)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        style: GoogleFonts.cairo(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 13),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
        onChanged: onChanged,
        items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, textDirection: TextDirection.rtl))).toList(),
      ),
    ),
  );
}
