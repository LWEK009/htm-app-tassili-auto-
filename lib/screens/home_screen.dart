import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/center_model.dart';
import '../models/user_model.dart';
import '../widgets/center_card.dart';
import '../widgets/app_widgets.dart';
import '../constants.dart';
import 'login_screen.dart';
import 'book_appointment_screen.dart';
import 'appointment_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = AuthService();
  final _fs   = FirestoreService();
  UserModel? _user;
  List<CenterModel> _centers = [];
  bool _loading = true;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _auth.currentUid;
    if (uid == null) return;
    
    // Non-blocking background seed
    _fs.seedCentersIfEmpty().catchError((_) => null);

    // Get centers (FirestoreService returns defaults if DB fails or is slow)
    final centersFuture = _fs.getCenters();
    final userFuture    = _auth.getUserById(uid);

    final results = await Future.wait([centersFuture, userFuture]);
    
    if (mounted) {
      setState(() { 
        _centers = results[0] as List<CenterModel>;
        _user    = results[1] as UserModel?;
        _loading = false; 
      });
    }
  }

  Future<void> _signOut() async {
    final confirm = await showConfirmDialog(
        context, 'تسجيل الخروج', 'هل تريد تسجيل الخروج؟',
        confirmLabel: 'نعم',
        confirmColor: AppColors.error);
    if (confirm != true || !mounted) return;
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  Widget _homeTab() {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: List.generate(4, (i) => const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: SkeletonLoader(height: 120, borderRadius: 24),
          )),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: TassiliHeader(
              greetingAr: 'مرحباً، ${_user?.firstName ?? ''}',
              subtitleAr: 'اختر مركزاً لحجز موعد الفحص',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader(),
                const SizedBox(height: 20),
                if (_centers.isEmpty)
                  const EmptyState(
                    icon: Icons.location_city_outlined,
                    title: 'لا توجد مراكز متاحة',
                    subtitle: 'يرجى المحاولة لاحقاً',
                  )
                else
                  ..._centers.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: CenterCard(
                      center: c,
                      onBook: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookAppointmentScreen(center: c),
                        ),
                      ),
                    ),
                  )),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.orange.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.location_on_rounded, color: AppColors.orange, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مراكز الفحص التقني',
                style: GoogleFonts.cairo(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
                textDirection: TextDirection.rtl,
              ),
              Text(
                'اختر المركز الأقرب إليك',
                style: GoogleFonts.cairo(
                  color: AppColors.textGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadows.soft,
            border: Border.all(color: AppColors.divider.withOpacity(0.5)),
          ),
          child: Text(
            '${_centers.length} مراكز',
            style: GoogleFonts.cairo(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _accountTab() {
    if (_loading) {
       return const Padding(
         padding: EdgeInsets.all(24),
         child: Column(
           children: [
             SizedBox(height: 20),
             SkeletonLoader(height: 200, borderRadius: 30),
             SizedBox(height: 24),
             SkeletonLoader(height: 80, borderRadius: 18),
             SizedBox(height: 16),
             SkeletonLoader(height: 80, borderRadius: 18),
           ],
         ),
       );
    }

    if (_user == null) {
      return EmptyState(
        icon: Icons.person_off_rounded,
        title: 'لم يتم العثور على بيانات',
        subtitle: 'يرجى تسجيل الدخول والتحقق من حسابك',
        actionLabel: 'العودة لتسجيل الدخول',
        onAction: _signOut,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(Icons.person_rounded, size: 50, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                Text(
                  '${_user?.firstName} ${_user?.lastName}',
                  style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark),
                ),
                Text(
                  _user?.email ?? '',
                  style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textGrey, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoItem(Icons.phone_rounded, 'رقم الهاتف', _user?.phone ?? '—'),
          _buildInfoItem(Icons.email_outlined, 'البريد الإلكتروني', _user?.email ?? '—'),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout_rounded),
              label: Text('تسجيل الخروج', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error.withOpacity(0.1),
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                Text(label, style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w700)),
                Text(value, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = 'الرئيسية';
    if (_tabIndex == 1) title = 'مواعيدي';
    if (_tabIndex == 2) title = 'حسابي';

    return Scaffold(
      extendBody: true,
      appBar: _tabIndex != 0 ? AppBar(
        title: Text(
          title,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
        ),
      ) : null,
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _homeTab(),
          AppointmentListScreen(userId: _user?.uid ?? _auth.currentUid ?? ''),
          _accountTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BottomNavigationBar(
          currentIndex: _tabIndex,
          onTap: (i) => setState(() => _tabIndex = i),
          elevation: 0,
          backgroundColor: Colors.white,
          selectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 11),
          unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 11),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'مواعيدي',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    );
  }
}

