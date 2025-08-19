import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/session_state.dart';
import 'services/audio_analyzer.dart';
import 'services/composer.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => SessionState(),
      child: const BeatSparkApp(),
    ),
  );
}

class BeatSparkApp extends StatelessWidget {
  const BeatSparkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeatSpark',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SessionState>();

    return Scaffold(
      appBar: AppBar(title: const Text('BeatSpark')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.mic),
              label: const Text('Record Voice Memo'),
              onPressed: () async {
                await AudioAnalyzer.recordAndAnalyze(context);
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Import Audio'),
              onPressed: () async {
                await AudioAnalyzer.importAndAnalyze(context);
              },
            ),
            const SizedBox(height: 12),
            if (state.detectedBpm != null && state.detectedKey != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tempo: ${state.detectedBpm} BPM'),
                    Text('Key: ${state.detectedKey}'),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.music_note),
              label: const Text('Build a Beat'),
              onPressed: () {
                Composer.buildFullTrack(context);
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.shuffle),
              label: const Text('Shuffle Sound'),
              onPressed: () {
                Composer.shuffle(context);
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
              onPressed: () {
                Composer.stop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
