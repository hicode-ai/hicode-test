import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

class Renderer {
  static const int sampleRate = 44100;

  static Future<String> renderLoopWav({double bpm = 92.0, int? seed}) async {
    final rng = Random(seed ?? DateTime.now().millisecondsSinceEpoch);
    const bars = 4;
    final secondsPerBeat = 60.0 / bpm;
    final secondsPerBar = secondsPerBeat * 4.0;
    final totalSec = bars * secondsPerBar;
    final totalSamples = (totalSec * sampleRate).round();
    final mix = Float32List(totalSamples);

    void add(int i, double v) {
      if (i >= 0 && i < mix.length) mix[i] += v;
    }

    double midiToFreq(int midi) => 440.0 * pow(2, (midi - 69) / 12.0);

    double envADSR(int n, int total,
        {double a = 0.01, double d = 0.1, double s = 0.7, double r = 0.2}) {
      final A = (a * total).floor();
      final D = (d * total).floor();
      final R = (r * total).floor();
      final SStart = A + D;
      final SEnd = total - R;
      if (n < A) return A == 0 ? 1.0 : n / A;
      if (n < SStart) return 1.0 - (n - A) / max(1, D) * (1.0 - s);
      if (n < SEnd) return s;
      final t = (n - SEnd) / max(1, R);
      return s * (1.0 - t);
    }

    void synthKick(int start) {
      final dur = (0.22 * sampleRate).floor();
      for (int i = 0; i < dur; i++) {
        final t = i / sampleRate;
        final f = 120.0 * pow(2, -t * 6);
        final env = exp(-t * 12);
        add(start + i, sin(2 * pi * f * t) * env * 1.1);
      }
    }

    void synthSnare(int start) {
      final dur = (0.18 * sampleRate).floor();
      final r = Random(start ^ (seed ?? 0));
      for (int i = 0; i < dur; i++) {
        final t = i / sampleRate;
        final tone = sin(2 * pi * 180 * t) * exp(-t * 12);
        final noise = (r.nextDouble() * 2 - 1) * exp(-t * 30);
        add(start + i, tone * 0.3 + noise * 0.7);
      }
    }

    void synthHat(int start) {
      final dur = (0.07 * sampleRate).floor();
      final r = Random((start + 1) ^ (seed ?? 0));
      double prev = 0.0;
      for (int i = 0; i < dur; i++) {
        final noise = (r.nextDouble() * 2 - 1);
        final hp = noise - 0.995 * prev;
        prev = noise;
        final t = i / sampleRate;
        final env = exp(-t * 70);
        add(start + i, hp * env * 0.5);
      }
    }

    void synthBass(int start, int len, int midi, {double vel = 0.8}) {
      final f = midiToFreq(midi);
      for (int i = 0; i < len; i++) {
        final env = envADSR(i, len, a: 0.005, d: 0.08, s: 0.7, r: 0.08);
        final t = i / sampleRate;
        final v = (sin(2 * pi * f * t) + 0.4 * sin(2 * pi * 2 * f * t)) * 0.6;
        add(start + i, v * env * vel * 0.9);
      }
    }

    void synthPad(int start, int len, int midi, {double vel = 0.6}) {
      final f = midiToFreq(midi);
      for (int i = 0; i < len; i++) {
        final env = envADSR(i, len, a: 0.2, d: 0.3, s: 0.85, r: 0.5);
        final t = i / sampleRate;
        final v = 0.5 * sin(2 * pi * f * t) +
            0.3 * sin(2 * pi * (f * 0.5) * t) +
            0.2 * sin(2 * pi * (f * 1.5) * t);
        add(start + i, v * env * vel * 0.5);
      }
    }

    int secToSample(double sec) => (sec * sampleRate).round();
    final barDur = secondsPerBar;
    final step16 = barDur / 16.0;
    final noteQ = (barDur / 4.0);

    final addGhostKicks = rng.nextBool();
    final hatSkipChance = rng.nextDouble() * 0.25;
    final swing = rng.nextDouble() * 0.02;

    for (int bar = 0; bar < bars; bar++) {
      final barStart = secToSample(bar * barDur);
      for (int s = 0; s < 16; s++) {
        final swingOffset =
            (s.isOdd ? (swing * secondsPerBeat) : 0.0) * (rng.nextBool() ? 1 : -1);
        final t = barStart + secToSample(s * step16 + swingOffset);

        if (s % 4 == 0) synthKick(t);
        if (addGhostKicks && (s == 6 || s == 14) && rng.nextBool()) synthKick(t);
        if (s == 4 || s == 12) synthSnare(t);
        if (s % 2 == 0 && rng.nextDouble() > hatSkipChance) synthHat(t);
      }
    }

    final progressions = [
      [0, -3, -2, -4],
      [0, -5, -4, -6],
      [0, -2, -3, -5],
    ];
    final prog = progressions[rng.nextInt(progressions.length)];
    final transpose = [-2, -1, 0, 1, 2][rng.nextInt(5)];
    final rootMidi = 49 + transpose;
    final padLen = secToSample(noteQ * 4);

    for (int bar = 0; bar < bars; bar++) {
      final barStart = secToSample(bar * barDur);
      final root = rootMidi + prog[bar % 4];
      for (final off in [0, 3, 7]) {
        synthPad(barStart, padLen, root + off + 12, vel: 0.5);
      }
      for (int q = 0; q < 4; q++) {
        final start = barStart + secToSample(q * noteQ);
        final note = (rng.nextDouble() < 0.25) ? (root - 12 + 7) : (root - 12);
        synthBass(start, secToSample(noteQ * 0.95), note, vel: 0.9);
      }
    }

    double peak = 1e-9;
    for (final v in mix) {
      final a = v.abs();
      if (a > peak) peak = a;
    }
    final g = 0.9 / peak;
    final out = Int16List(mix.length);
    for (int i = 0; i < mix.length; i++) {
      final v = (mix[i] * g).clamp(-1.0, 1.0);
      out[i] = (v * 32767).round();
    }

    final bytes = Uint8List.view(out.buffer);
    final path = await _writeWav(bytes, sampleRate: sampleRate);
    return path;
  }

  static Future<String> _writeWav(Uint8List pcm16,
      {int sampleRate = 44100, int channels = 1}) async {
    final dataSize = pcm16.lengthInBytes;
    final header = BytesBuilder();

    void writeString(String s) => header.add(s.codeUnits);
    void write32(int v) {
      final b = ByteData(4)..setUint32(0, v, Endian.little);
      header.add(b.buffer.asUint8List());
    }
    void write16(int v) {
      final b = ByteData(2)..setUint16(0, v, Endian.little);
      header.add(b.buffer.asUint8List());
    }

    final bytesPerSec = sampleRate * channels * 2;

    writeString('RIFF');
    write32(36 + dataSize);
    writeString('WAVE');
    writeString('fmt ');
    write32(16);
    write16(1);
    write16(channels);
    write32(sampleRate);
    write32(bytesPerSec);
    write16(channels * 2);
    write16(16);
    writeString('data');
    write32(dataSize);

    final fileBytes = BytesBuilder()
      ..add(header.toBytes())
      ..add(pcm16);

    final file = File(
        '${Directory.systemTemp.path}/beatspark_${DateTime.now().millisecondsSinceEpoch}.wav');
    await file.writeAsBytes(fileBytes.toBytes(), flush: true);
    return file.path;
  }
}
