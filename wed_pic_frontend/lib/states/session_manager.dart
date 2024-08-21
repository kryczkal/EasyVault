import 'package:flutter/material.dart';

class SessionManager extends ChangeNotifier {
  String? _sessionId;

  String? get sessionId => _sessionId;

  void setSessionId(String sessionId) {
    _sessionId = sessionId;
    notifyListeners();
  }

  void clearSessionId({bool notify = true}) {
    _sessionId = null;
    if (notify) {
      notifyListeners();
    }
  }
}
