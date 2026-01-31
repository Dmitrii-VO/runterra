import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Сервис авторизации через Firebase + Google Sign-In
///
/// Предоставляет методы для входа/выхода и получения токена.
/// Использует Firebase Auth для управления сессией.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Текущий пользователь Firebase (null если не авторизован)
  User? get currentUser => _firebaseAuth.currentUser;

  /// Стрим изменений состояния авторизации
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Проверка авторизован ли пользователь
  bool get isAuthenticated => currentUser != null;

  /// Получить текущий Firebase ID Token для API запросов
  /// Возвращает null если пользователь не авторизован
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = currentUser;
    if (user == null) return null;
    return await user.getIdToken(forceRefresh);
  }

  /// Вход через Google
  /// 
  /// Возвращает UserCredential при успехе, выбрасывает исключение при ошибке.
  /// Если пользователь отменил вход, выбрасывает [AuthCancelledException].
  Future<UserCredential> signInWithGoogle() async {
    // Запускаем Google Sign-In flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    
    if (googleUser == null) {
      // Пользователь отменил вход
      throw AuthCancelledException('Вход отменён пользователем');
    }

    // Получаем данные авторизации от Google
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Создаём credentials для Firebase
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Входим в Firebase с Google credentials
    return await _firebaseAuth.signInWithCredential(credential);
  }

  /// Выход из аккаунта
  /// 
  /// Выполняет выход из Firebase и Google Sign-In
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}

/// Исключение при отмене авторизации пользователем
class AuthCancelledException implements Exception {
  final String message;
  AuthCancelledException(this.message);
  
  @override
  String toString() => message;
}
