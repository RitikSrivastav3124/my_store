import '../../core/constants/app_constants.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'base_view_model.dart';

class AuthViewModel extends BaseViewModel {
  AuthViewModel(this._authRepository, this._storage);

  final AuthRepository _authRepository;
  final SecureStorageService _storage;

  AppUser? _user;
  String? _refreshToken;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isOwner => _user?.role == AppConstants.ownerRole;
  bool get isCustomer => _user?.role == AppConstants.customerRole;

  Future<void> bootstrap() async {
    _user = await _storage.readUser();
    _refreshToken = await _storage.readRefreshToken();
    notifyListeners();
  }

  Future<bool> login(String identifier, String password) async {
    final session = await guard(() => _authRepository.login(identifier: identifier, password: password));
    if (session == null) return false;
    _user = session.user;
    _refreshToken = session.refreshToken;
    notifyListeners();
    return true;
  }

  Future<bool> registerOwner(String name, String phone, String email, String password) async {
    final session = await guard(
      () => _authRepository.registerOwner(
        name: name,
        phone: phone,
        email: email,
        password: password,
      ),
    );
    if (session == null) return false;
    _user = session.user;
    _refreshToken = session.refreshToken;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await guard(() => _authRepository.logout(_refreshToken));
    _user = null;
    _refreshToken = null;
    notifyListeners();
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    final result = await guard(
      () => _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );
    return result != null || error == null;
  }
}
