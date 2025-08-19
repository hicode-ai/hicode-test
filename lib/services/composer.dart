import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'renderer.dart';

class Composer {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> buildFullTrack(BuildContext context) async {
    try {
      final path = await Renderer.renderLoopWav(bpm: 92.0);
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(DeviceFileSource(path));
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Playing generated loop 🎧')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Playback error: $e')));
      }
    }
  }

  static Future<void> shuffle(BuildContext context) async {
    try {
      final seed = DateTime.now().millisecondsSinceEpoch;
      final bpm = (80 + (seed % 61)).toDouble();
      final path = await Renderer.renderLoopWav(bpm: bpm, seed: seed);
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(DeviceFileSource(path));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Shuffle: ${bpm.toStringAsFixed(0)} BPM 🔀')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Shuffle error: $e')));
      }
    }
  }

  static Future<void> stop(BuildContext context) async {
    await _player.stop();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Stopped.')));
    }
  }
}
