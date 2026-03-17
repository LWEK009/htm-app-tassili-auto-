import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/center_model.dart';
import '../models/appointment_model.dart';

class FirestoreService {
  static const String _prefAppointmentsKey = 'local_appointments';
  static const String _prefCentersKey = 'local_centers';

  // ══════════════════════════════════════════════════════════
  // LOCAL PERSISTENT BACKEND
  // ══════════════════════════════════════════════════════════
  static List<AppointmentModel> _localAppointments = [];
  static List<CenterModel> _localCenters = [];
  static final _localStream = StreamController<List<AppointmentModel>>.broadcast();

  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  
  FirestoreService._internal() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Appointments
    final apptsJson = prefs.getString(_prefAppointmentsKey);
    if (apptsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(apptsJson);
        _localAppointments = decoded.map((m) => AppointmentModel.fromMap(m['id'] ?? '', m)).toList();
        _notifyLocal();
      } catch (_) {}
    }

    // Load Centers
    final centersJson = prefs.getString(_prefCentersKey);
    if (centersJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(centersJson);
        _localCenters = decoded.map((m) => CenterModel.fromMap(m['id'] ?? '', m)).toList();
      } catch (_) {}
    }
  }

  Future<void> _saveAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefAppointmentsKey, jsonEncode(_localAppointments.map((a) => a.toMap()..['id'] = a.id).toList()));
  }

  Future<void> _saveCenters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefCentersKey, jsonEncode(_localCenters.map((c) => c.toMap()).toList()));
  }

  void _notifyLocal() {
    _localStream.add(List.from(_localAppointments));
  }

  // ══════════════════════════════════════════════════════════
  // CENTRES
  // ══════════════════════════════════════════════════════════

  Future<List<CenterModel>> getCenters() async {
    if (_localCenters.isNotEmpty) return _localCenters;
    _localCenters = CenterModel.defaults;
    await _saveCenters();
    return _localCenters;
  }

  Stream<List<CenterModel>> centersStream() async* {
    yield await getCenters();
  }

  Future<void> addCenter(CenterModel c) async {
    _localCenters.add(c);
    await _saveCenters();
  }

  Future<void> updateCenter(String id, Map<String, dynamic> data) async {
    final idx = _localCenters.indexWhere((c) => c.id == id);
    if (idx != -1) {
       // Update center logic would go here
       await _saveCenters();
    }
  }

  Future<void> seedCentersIfEmpty() async {
    if (_localCenters.isEmpty) {
        _localCenters = CenterModel.defaults;
        await _saveCenters();
    }
  }

  // ══════════════════════════════════════════════════════════
  // appointments
  // ══════════════════════════════════════════════════════════

  Future<bool> isSlotAvailable(String centerId, String date, String time) async {
    return !_localAppointments.any((a) => 
      a.centerId == centerId && a.date == date && a.time == time && a.status != 'cancelled'
    );
  }

  Future<String> createAppointment(AppointmentModel a) async {
    final available = await isSlotAvailable(a.centerId, a.date, a.time);
    if (!available) throw Exception('الوقت محجوز مسبقاً، اختر وقتاً آخر');
    
    final fakeId = 'appt_${DateTime.now().millisecondsSinceEpoch}';
    final localA = AppointmentModel.fromMap(fakeId, a.toMap());
    _localAppointments.add(localA);
    await _saveAppointments();
    _notifyLocal();
    return fakeId;
  }

  Stream<List<AppointmentModel>> clientAppointmentsStream(String uid) {
    return _localStream.stream.map((list) => 
      list.where((a) => a.userId == uid).toList()..sort((a,b) => b.date.compareTo(a.date))
    );
  }

  Stream<List<AppointmentModel>> allAppointmentsStream() {
    return _localStream.stream.map((list) => 
      List<AppointmentModel>.from(list)..sort((a,b) => b.date.compareTo(a.date))
    );
  }

  Future<void> updateStatus(String id, String status) async {
    final idx = _localAppointments.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _localAppointments[idx] = _localAppointments[idx].copyWith(status: status);
      await _saveAppointments();
      _notifyLocal();
    }
  }

  Future<void> updatePayment(String id, String paymentStatus) async {
    final idx = _localAppointments.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _localAppointments[idx] = _localAppointments[idx].copyWith(paymentStatus: paymentStatus);
      await _saveAppointments();
      _notifyLocal();
    }
  }

  Future<void> saveInspectionResult(String id, List<InspectionItem> items, bool repairProposed) async {
    final idx = _localAppointments.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _localAppointments[idx] = _localAppointments[idx].copyWith(
        inspectionItems: items,
        repairProposed: repairProposed,
        status: 'done',
      );
      await _saveAppointments();
      _notifyLocal();
    }
  }

  Future<void> respondRepair(String id, bool accepted) async {
    final idx = _localAppointments.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _localAppointments[idx] = _localAppointments[idx].copyWith(repairAccepted: accepted);
      await _saveAppointments();
      _notifyLocal();
    }
  }

  Future<void> cancel(String id) async {
    final idx = _localAppointments.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _localAppointments[idx] = _localAppointments[idx].copyWith(status: 'cancelled');
      await _saveAppointments();
      _notifyLocal();
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    final all = _localAppointments;
    final today = _todayStr();
    final Map<String, int> centerCounts = {};
    for (final a in all) {
      centerCounts[a.centerName] = (centerCounts[a.centerName] ?? 0) + 1;
    }

    return {
      'total':     all.length,
      'today':     all.where((a) => a.date == today).length,
      'pending':   all.where((a) => a.status == 'pending').length,
      'confirmed': all.where((a) => a.status == 'confirmed').length,
      'done':      all.where((a) => a.status == 'done').length,
      'expired':   all.where((a) => a.status == 'expired').length,
      'cancelled': all.where((a) => a.status == 'cancelled').length,
      'paid':      all.where((a) => a.paymentStatus == 'paid').length,
      'unpaid':    all.where((a) => a.paymentStatus == 'unpaid').length,
      'centers':   centerCounts,
    };
  }

  static String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}
