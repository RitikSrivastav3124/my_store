import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../domain/repositories/auth_repository.dart';

class NotificationService {
  NotificationService(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token != null) await _authRepository.registerFcmToken(token);
      FirebaseMessaging.instance.onTokenRefresh.listen(_authRepository.registerFcmToken);
    } catch (_) {
      return;
    }
  }
}
