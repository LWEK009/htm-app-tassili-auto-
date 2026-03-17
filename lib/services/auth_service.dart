import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _prefUidKey = 'auth_uid';
  static const String _prefUsersKey = 'local_users';

  // ══════════════════════════════════════════════════════════
  // LOCAL PERSISTENT AUTH
  // ══════════════════════════════════════════════════════════
  static List<UserModel> _localUsers = [
    UserModel(uid: 'admin_123', firstName: 'Admin', lastName: 'Tassili', email: 'admin@tassili.com', phone: '0555555555', role: 'admin'),
  ];
  static String? _persistedUid;
  static final _authController = StreamController<String?>.broadcast();
  static final AuthService _instance = AuthService._internal();
  
  late final Future<void> _initFuture = _init();

  factory AuthService() => _instance;

  AuthService._internal();

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load local user database
    final usersJson = prefs.getString(_prefUsersKey);
    if (usersJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(usersJson);
        _localUsers = decoded.map((m) => UserModel.fromMap(m['uid'] ?? '', m)).toList();
        // Ensure admin is always there
        if (!_localUsers.any((u) => u.uid == 'admin_123')) {
          _localUsers.add(UserModel(uid: 'admin_123', firstName: 'Admin', lastName: 'Tassili', email: 'admin@tassili.com', phone: '0555555555', role: 'admin'));
        }
      } catch (_) {}
    }

    _persistedUid = prefs.getString(_prefUidKey);
    _authController.add(_persistedUid);
  }

  String? get currentUid => _persistedUid;

  // Unified Auth Stream
  late final Stream<String?> authStateStream = _buildAuthStateStream().asBroadcastStream();

  Stream<String?> _buildAuthStateStream() async* {
    await _initFuture;
    yield _persistedUid;
    yield* _authController.stream;
  }

  // ── Inscription ──────────────────────────────────────────
  Future<UserModel> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    await _initFuture;
    final fakeUid = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final user = UserModel(
      uid: fakeUid,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim().toLowerCase(),
      phone: phone.trim(),
      role: 'client',
    );

    // Add to Local Database
    if (!_localUsers.any((u) => u.email == user.email)) {
      _localUsers.add(user);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefUsersKey, jsonEncode(_localUsers.map((u) => u.toMap()..['uid'] = u.uid).toList()));
    }

    _persistedUid = fakeUid;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefUidKey, fakeUid);
    _authController.add(fakeUid);

    return user;
  }

  // ── Connexion ────────────────────────────────────────────
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    await _initFuture;
    final cleanEmail = email.trim().toLowerCase();
    
    // Check Local Database
    final localMatch = _localUsers.cast<UserModel?>().firstWhere(
      (u) => u?.email.toLowerCase() == cleanEmail,
      orElse: () => null,
    );

    if (localMatch != null) {
      // For a demo/local app, we just match email. 
      // Password check 'admin123' for admin, others are free for now.
      if (cleanEmail == 'admin@tassili.com' && password != 'admin123') {
        throw 'كلمة المرور غير صحيحة';
      }

      _persistedUid = localMatch.uid;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefUidKey, localMatch.uid);
      _authController.add(localMatch.uid);
      return localMatch;
    }

    throw 'لا يوجد حساب بهذا البريد الإلكتروني';
  }

  // ── Déconnexion ──────────────────────────────────────────
  Future<void> signOut() async {
    _persistedUid = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefUidKey);
    _authController.add(null);
  }

  // ── Récupérer un utilisateur ─────────────────────────────
  Future<UserModel?> getUserById(String uid) async {
    await _initFuture;
    final local = _localUsers.cast<UserModel?>().firstWhere(
      (u) => u?.uid == uid,
      orElse: () => null,
    );
    if (local != null) return local;
    
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
    await _initFuture;
    final u = await getUserById(uid);
    return u?.role;
  }
}
