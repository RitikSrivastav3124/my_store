import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_store/core/storage/secure_storage_service.dart';
import 'package:my_store/domain/repositories/auth_repository.dart';
import 'package:my_store/presentation/screens/auth/login_screen.dart';
import 'package:my_store/presentation/screens/settings/change_password_screen.dart';
import 'package:my_store/presentation/viewmodels/auth_view_model.dart';
import 'package:provider/provider.dart';

class _FakeAuthViewModel extends AuthViewModel {
  _FakeAuthViewModel({this.shouldSucceed = true, this.logoutCompleter})
    : super(_FakeAuthRepository(), _FakeStorage());

  final bool shouldSucceed;
  final Completer<void>? logoutCompleter;
  var authenticated = true;
  var changePasswordCalls = 0;
  var logoutCalls = 0;
  String? currentPassword;
  String? newPassword;

  @override
  bool get isAuthenticated => authenticated;

  @override
  bool get loading => false;

  @override
  String? get error => shouldSucceed ? null : 'Current password is incorrect';

  @override
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    changePasswordCalls++;
    this.currentPassword = currentPassword;
    this.newPassword = newPassword;
    return shouldSucceed;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    await logoutCompleter?.future;
    authenticated = false;
    notifyListeners();
  }
}

class _FakeStorage extends SecureStorageService {}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<AuthSession> login({
    required String identifier,
    required String password,
    String? fcmToken,
  }) => throw UnimplementedError();

  @override
  Future<void> logout(String? refreshToken) async {}

  @override
  Future<void> registerFcmToken(String token) async {}

  @override
  Future<AuthSession> registerOwner({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) => throw UnimplementedError();
}

Widget _app(_FakeAuthViewModel auth) {
  return ChangeNotifierProvider<AuthViewModel>.value(
    value: auth,
    child: MaterialApp(
      home: Consumer<AuthViewModel>(
        builder: (context, value, _) => value.isAuthenticated
            ? const ChangePasswordScreen()
            : const LoginScreen(),
      ),
    ),
  );
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Future<void> _fillValidForm(
  WidgetTester tester, {
  String? confirmPassword,
}) async {
  await tester.enterText(_field('Current Password'), 'CurrentPass1!');
  await tester.enterText(_field('New Password'), 'NewPassword1!');
  await tester.enterText(
    _field('Confirm New Password'),
    confirmPassword ?? 'NewPassword1!',
  );
}

Future<void> _submit(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Change Password'));
  await tester.pump();
}

void main() {
  testWidgets(
    'empty current password shows validation error without calling the API',
    (tester) async {
      final auth = _FakeAuthViewModel();
      await tester.pumpWidget(_app(auth));

      await tester.enterText(_field('New Password'), 'NewPassword1!');
      await tester.enterText(_field('Confirm New Password'), 'NewPassword1!');
      await _submit(tester);

      expect(find.text('Current password is required'), findsOneWidget);
      expect(auth.changePasswordCalls, 0);
    },
  );

  testWidgets(
    'invalid new password shows validation error without calling the API',
    (tester) async {
      final auth = _FakeAuthViewModel();
      await tester.pumpWidget(_app(auth));

      await tester.enterText(_field('Current Password'), 'CurrentPass1!');
      await tester.enterText(_field('New Password'), 'short');
      await tester.enterText(_field('Confirm New Password'), 'short');
      await _submit(tester);

      expect(find.textContaining('Use 8-72 characters'), findsOneWidget);
      expect(auth.changePasswordCalls, 0);
    },
  );

  testWidgets(
    'mismatched confirmation shows validation error without calling the API',
    (tester) async {
      final auth = _FakeAuthViewModel();
      await tester.pumpWidget(_app(auth));

      await _fillValidForm(tester, confirmPassword: 'DifferentPassword1!');
      await _submit(tester);

      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(auth.changePasswordCalls, 0);
    },
  );

  testWidgets(
    'valid input calls the existing change password flow with both passwords',
    (tester) async {
      final auth = _FakeAuthViewModel();
      await tester.pumpWidget(_app(auth));

      await _fillValidForm(tester);
      await _submit(tester);

      expect(auth.changePasswordCalls, 1);
      expect(auth.currentPassword, 'CurrentPass1!');
      expect(auth.newPassword, 'NewPassword1!');
    },
  );

  testWidgets(
    'successful password change shows confirmation, logs out, and returns to login',
    (tester) async {
      final logoutCompleter = Completer<void>();
      final auth = _FakeAuthViewModel(logoutCompleter: logoutCompleter);
      await tester.pumpWidget(_app(auth));

      await _fillValidForm(tester);
      await _submit(tester);

      expect(
        find.text('Password changed successfully. Please sign in again.'),
        findsOneWidget,
      );
      expect(auth.logoutCalls, 1);

      logoutCompleter.complete();
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, 'Phone or email'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'API failure shows an error and keeps the user on the change password screen',
    (tester) async {
      final auth = _FakeAuthViewModel(shouldSucceed: false);
      await tester.pumpWidget(_app(auth));

      await _fillValidForm(tester);
      await _submit(tester);

      expect(find.text('Current password is incorrect'), findsOneWidget);
      expect(find.text('Change Password'), findsWidgets);
      expect(auth.logoutCalls, 0);
    },
  );
}
