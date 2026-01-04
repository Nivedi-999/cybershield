import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final LocalAuthentication _auth = LocalAuthentication(); // ✅ FIX

  bool _unlocked = false;
  bool get unlocked => _unlocked;

  void lock() {
    _unlocked = false;
    notifyListeners();
  }

  Future<bool> authenticate({required String reason}) async {
    try {
      final didAuth = await _auth.authenticate(
        localizedReason: reason,
      );

      if (didAuth) {
        _unlocked = true;
        notifyListeners();
      }
      return didAuth;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unlockWithPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString('vault_pin');

    if (storedPin != null && storedPin == pin) {
      _unlocked = true;
      notifyListeners();
      return true;
    }
    return false;
  }
}
