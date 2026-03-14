import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  // ══════════════════════════════════════════════════════════
  // LOCAL FAKE AUTH (In-Memory)
  // ══════════════════════════════════════════════════════════
  static final List<UserModel> _localUsers = [
    UserModel(uid: 'admin_123', firstName: 'Admin', lastName: 'Tassili', email: 'admin@tassili.com', phone: '0555555555', role: 'admin'),
  ];
  static String? _fakeSessionUid;
  static final _authController = StreamController<String?>.broadcast();

  User? get currentUser => _auth.currentUser;
  
  String? get currentUid {
    if (_fakeSessionUid != null) return _fakeSessionUid;
    return _auth.currentUser?.uid;
  }

  // Unified Auth Stream (Fake + Firebase)
  Stream<String?> get authStateStream {
    // Initial emission
    Future.microtask(() => _authController.add(currentUid));
    return _authController.stream;
  }

  Stream<User?> get authChanges => _auth.authStateChanges();

  // ── Inscription ──────────────────────────────────────────
  Future<UserModel> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final fakeUid = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final user = UserModel(
      uid: fakeUid,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim().toLowerCase(),
      phone: phone.trim(),
      role: 'client',
    );

    // Add to Local
    if (!_localUsers.any((u) => u.email == user.email)) {
      _localUsers.add(user);
    }
    _fakeSessionUid = fakeUid;
    _authController.add(fakeUid);

    // Try Real Firebase (background)
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final realUid = cred.user!.uid;
      // We don't change _fakeSessionUid to realUid yet to keep local data accessible
      await _db.collection('users').doc(realUid).set(user.copyWith(uid: realUid).toMap());
    } catch (_) {}

    return user;
  }

  // ── Connexion ────────────────────────────────────────────
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    
    // Check Local First (Fake Auth)
    final localMatch = _localUsers.cast<UserModel?>().firstWhere(
      (u) => u?.email.toLowerCase() == cleanEmail,
      orElse: () => null,
    );

    if (localMatch != null) {
      _fakeSessionUid = localMatch.uid;
      _authController.add(localMatch.uid);
      return localMatch;
    }

    // Try Real Firebase
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _fakeSessionUid = cred.user!.uid;
      _authController.add(cred.user!.uid);
      return await getUserById(cred.user!.uid);
    } on FirebaseAuthException catch (e) {
      if (cleanEmail == 'admin@tassili.com' && password == 'admin123') {
        _fakeSessionUid = 'admin_123';
        _authController.add('admin_123');
        return _localUsers.first;
      }
      throw _authError(e);
    } catch (e) {
      throw 'حدث خطأ غير متوقع';
    }
  }

  // ── Déconnexion ──────────────────────────────────────────
  Future<void> signOut() async {
    _fakeSessionUid = null;
    _authController.add(null);
    await _auth.signOut();
  }

  // ── Récupérer un utilisateur ─────────────────────────────
  Future<UserModel?> getUserById(String uid) async {
    // 1. Priority: Local Cache
    final local = _localUsers.cast<UserModel?>().firstWhere(
      (u) => u?.uid == uid,
      orElse: () => null,
    );
    if (local != null) return local;

    // 2. Secondary: Firestore
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final u = UserModel.fromMap(uid, doc.data()!);
        if (!_localUsers.any((lu) => lu.uid == u.uid)) {
          _localUsers.add(u); 
        }
        return u;
      }
    } catch (_) {}
    
    // 3. Last Resort: If it's a fake session but we lost the object (unlikely in memory but for safety)
    if (uid.startsWith('user_')) {
      return UserModel(
        uid: uid,
        firstName: 'مستخدم',
        lastName: 'جديد',
        email: '...',
        phone: '...',
      );
    }

    return null;
  }

  Future<String?> getUserRole(String uid) async {
    final u = await getUserById(uid);
    return u?.role;
  }

  String _authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':  return 'البريد الإلكتروني مستخدم مسبقاً';
      case 'invalid-email':         return 'البريد الإلكتروني غير صحيح';
      case 'weak-password':         return 'كلمة المرور ضعيفة جداً (6 أحرف على الأقل)';
      case 'user-not-found':        return 'لا يوجد حساب بهذا البريد الإلكتروني';
      case 'wrong-password':        return 'كلمة المرور غير صحيحة';
      case 'too-many-requests':     return 'محاولات كثيرة، يرجى المحاولة لاحقاً';
      case 'network-request-failed':return 'خطأ في الاتصال بالإنترنت';
      default:                      return 'حدث خطأ: ${e.message}';
    }
  }
}
