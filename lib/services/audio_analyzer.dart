import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../models/session_state.dart';

class AudioAnalyzer {
  static Future<void> recordAndAnalyze(BuildContext context) async {
    await Future.delayed(const Duration(seconds: 2));
    _setFakeAnalysis(context, source: 'Recording');
  }

  static Future<void> importAndAnalyze(BuildContext context) async {
    await FilePicker.platform.pickFiles(type: FileType.audio);
    _setFakeAnalysis(context, source: 'Imported Audio');
  }

  static void _setFakeAnalysis(BuildContext context, {required String source}) {
    context.read<SessionState>().setAnalysis(bpm: 92.0, key: 'C# Minor');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Idea Analyzed ✅'),
        content: const Text('Tempo: 92 BPM\nKey: C# Minor'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$source analyzed: 92 BPM • C# Minor')),
    );
  }
}
