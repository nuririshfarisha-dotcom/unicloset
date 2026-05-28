import 'package:firebase_auth/firebase_auth.dart';

import '../../firebase/services/firebase_auth_service.dart';
import '../../firebase/services/firestore_user_service.dart';
import '../../models/user_model.dart';

class AuthRepository {
  final FirebaseAuthService _authService;
  final FirestoreUserService _userService;

  AuthRepository({
    required FirebaseAuthService authService,
    required FirestoreUserService userService,
  })  : _authService = authService,
        _userService = userService;

  User? get currentUser => _authService.currentUser;

  Stream<User?> authStateChanges() {
    return _authService.authStateChanges();
  }

  Future<UserModel> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final userCredential = await _authService.registerWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = userCredential.user;

    if (firebaseUser == null) {
      throw Exception('Registration failed. User data was not created.');
    }

    final user = UserModel(
      uid: firebaseUser.uid,
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      createdAt: DateTime.now(),
    );

    await _userService.saveUser(user);

    return user;
  }

  Future<UserModel?> loginUser({
    required String email,
    required String password,
  }) async {
    final userCredential = await _authService.loginWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = userCredential.user;

    if (firebaseUser == null) {
      throw Exception('Login failed. User data was not found.');
    }

    return await _userService.getUserById(firebaseUser.uid);
  }

  Future<void> logoutUser() async {
    await _authService.logout();
  }
}