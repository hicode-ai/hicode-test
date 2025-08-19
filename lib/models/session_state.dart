import 'package:flutter/foundation.dart';

class SessionState extends ChangeNotifier {
  double? detectedBpm;
  String? detectedKey;

  void setAnalysis({required double bpm, required String key}) {
    detectedBpm = bpm;
    detectedKey = key;
    notifyListeners();
  }

  void clear() {
    detectedBpm = null;
    detectedKey = null;
    notifyListeners();
  }
}
