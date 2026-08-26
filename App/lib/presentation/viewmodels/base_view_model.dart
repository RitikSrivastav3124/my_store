import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';

class BaseViewModel extends ChangeNotifier {
  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<T?> guard<T>(Future<T> Function() action) async {
    final shouldNotifyStart = !_loading || _error != null;
    _loading = true;
    _error = null;
    if (shouldNotifyStart) notifyListeners();
    try {
      return await action();
    } on AppException catch (error) {
      _error = error.message;
      return null;
    } catch (_) {
      _error = 'Something went wrong. Please try again.';
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
