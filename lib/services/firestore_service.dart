import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/center_model.dart';
import '../models/appointment_model.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ══════════════════════════════════════════════════════════
  // LOCAL FAKE BACKEND (In-Memory)
  // ══════════════════════════════════════════════════════════
  static final List<AppointmentModel> _localAppointments = [];
  static final _localStream = StreamController<List<AppointmentModel>>.broadcast();

  void _notifyLocal() {
    _localStream.add(List.from(_localAppointments));
  }

  // ══════════════════════════════════════════════════════════
  // CENTRES
  // ══════════════════════════════════════════════════════════

  Future<List<CenterModel>> getCenters() async {
    try {
      final snap = await _db
          .collection('centers')
          .get()
          .timeout(const Duration(seconds: 3));
      if (snap.docs.isEmpty) return CenterModel.defaults;
      return snap.docs
          .map((d) => CenterModel.fromMap(d.id, d.data()))
          .toList();
    } catch (_) {
      return CenterModel.defaults;
    }
  }

  Stream<List<CenterModel>> centersStream() =>
      _db.collection('centers').snapshots().map(
            (s) => s.docs
                .map((d) => CenterModel.fromMap(d.id, d.data()))
                .toList(),
          );

  Future<void> addCenter(CenterModel c) =>
      _db.collection('centers').doc(c.id).set(c.toMap());

  Future<void> updateCenter(String id, Map<String, dynamic> data) =>
      _db.collection('centers').doc(id).update(data);

  Future<void> seedCentersIfEmpty() async {
    // Always ensure all default centers are seeded/updated
    for (final c in CenterModel.defaults) {
      await _db.collection('centers').doc(c.id).set(c.toMap());
    }
  }

  // ══════════════════════════════════════════════════════════
  // RENDEZ-VOUS
  // ══════════════════════════════════════════════════════════

  Future<bool> isSlotAvailable(
      String centerId, String date, String time) async {
    final localMatch = _localAppointments.any((a) => 
      a.centerId == centerId && a.date == date && a.time == time && a.status != 'cancelled'
    );
    if (localMatch) return false;

    try {
      final q = await _db
          .collection('appointments')
          .where('centerId', isEqualTo: centerId)
          .where('date', isEqualTo: date)
          .where('time', isEqualTo: time)
          .where('status', whereNotIn: ['cancelled'])
          .get();
      return q.docs.isEmpty;
    } catch (_) {
      return true;
    }
  }

  Future<String> createAppointment(AppointmentModel a) async {
    final available = await isSlotAvailable(a.centerId, a.date, a.time);
    if (!available) throw Exception('الوقت محجوز مسبقاً، اختر وقتاً آخر');
    
    final fakeId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final localA = AppointmentModel.fromMap(fakeId, a.toMap());
    _localAppointments.add(localA);
    _notifyLocal();

    try {
      await _db.collection('appointments').doc(fakeId).set(a.toMap());
    } catch (_) {}
    
    return fakeId;
  }

  Stream<List<AppointmentModel>> clientAppointmentsStream(String uid) {
    final stream = _db
        .collection('appointments')
        .where('userId', isEqualTo: uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => AppointmentModel.fromMap(d.id, d.data()))
            .toList());

    return _combineStreams(stream, uid);
  }

  Stream<List<AppointmentModel>> _combineStreams(Stream<List<AppointmentModel>> dbStream, [String? uid]) {
    final controller = StreamController<List<AppointmentModel>>.broadcast();
    List<AppointmentModel> dbList = [];
    
    void emit() {
      final combined = <AppointmentModel>[];
      final safeUid = (uid == null || uid.isEmpty) ? null : uid;

      // Auto-update local statuses for expiry
      for (int i = 0; i < _localAppointments.length; i++) {
        final a = _localAppointments[i];
        if (a.isPast && (a.status == 'pending' || a.status == 'confirmed')) {
          _localAppointments[i] = a.copyWith(status: 'expired');
        }
      }

      combined.addAll(_localAppointments.where((a) => safeUid == null || a.userId == safeUid));
      
      for (var a in dbList) {
        if (!combined.any((l) => l.id == a.id)) {
          if (a.isPast && (a.status == 'pending' || a.status == 'confirmed')) {
            a = a.copyWith(status: 'expired');
          }
          combined.add(a);
        }
      }
      combined.sort((a, b) => b.date.compareTo(a.date));
      if (!controller.isClosed) controller.add(combined);
    }

    final localSub = _localStream.stream.listen((_) => emit());
    final dbSub = dbStream.listen((list) {
      dbList = list;
      emit();
    }, onError: (_) => emit());

    emit();

    controller.onCancel = () {
      localSub.cancel();
      dbSub.cancel();
    };

    return controller.stream;
  }

  Stream<List<AppointmentModel>> allAppointmentsStream() {
    final stream = _db
        .collection('appointments')
        .orderBy('date', descending: true)
        .snapshots()
        .asyncMap((s) async {
      final Map<String, String> nameCache = {};
      final List<AppointmentModel> result = [];
      for (final doc in s.docs) {
        final data = doc.data();
        final uid = data['userId'] as String? ?? '';
        if (!nameCache.containsKey(uid)) {
          try {
            final u = await _db.collection('users').doc(uid).get();
            nameCache[uid] = u.exists
                ? '${u.data()?['firstName']} ${u.data()?['lastName']}'
                : 'غير معروف';
          } catch (_) {
            nameCache[uid] = 'غير معروف';
          }
        }
        result.add(AppointmentModel.fromMap(
            doc.id, {...data, 'clientName': nameCache[uid]}));
      }
      return result;
    });

    return _combineStreams(stream);
  }

  Future<void> updateStatus(String id, String status) async {
    final idx = _localAppointments.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _localAppointments[idx] = _localAppointments[idx].copyWith(status: status);
      _notifyLocal();
    }
    try {
      await _db.collection('appointments').doc(id).update({'status': status});
    } catch (_) {}
  }

  Future<void> updatePayment(String id, String paymentStatus) async {
    final idx = _localAppointments.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _localAppointments[idx] = _localAppointments[idx].copyWith(paymentStatus: paymentStatus);
      _notifyLocal();
    }
    try {
      await _db.collection('appointments').doc(id).update({'paymentStatus': paymentStatus});
    } catch (_) {}
  }

  Future<void> saveInspectionResult(
      String id, List<InspectionItem> items, bool repairProposed) async {
    final idx = _localAppointments.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _localAppointments[idx] = _localAppointments[idx].copyWith(
        inspectionItems: items,
        repairProposed: repairProposed,
        status: 'done',
      );
      _notifyLocal();
    }
    try {
      await _db.collection('appointments').doc(id).update({
        'inspectionItems': items.map((i) => i.toMap()).toList(),
        'repairProposed': repairProposed,
        'status': 'done',
      });
    } catch (_) {}
  }

  Future<void> respondRepair(String id, bool accepted) async {
    final idx = _localAppointments.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _localAppointments[idx] = _localAppointments[idx].copyWith(repairAccepted: accepted);
      _notifyLocal();
    }
    try {
      await _db.collection('appointments').doc(id).update({'repairAccepted': accepted});
    } catch (_) {}
  }

  Future<void> cancel(String id) async {
    final idx = _localAppointments.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _localAppointments[idx] = _localAppointments[idx].copyWith(status: 'cancelled');
      _notifyLocal();
    }
    try {
      await _db.collection('appointments').doc(id).update({'status': 'cancelled'});
    } catch (_) {}
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

  static String dateToStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}
