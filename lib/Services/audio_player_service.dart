// lib/Services/audio_player_service.dart
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mobile2025/Entites/content.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();
  Content? _currentContent;
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final ValueNotifier<Duration?> duration = ValueNotifier(null);
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);

  AudioPlayer get player => _player;
  Content? get currentContent => _currentContent;

  Future<void> playContent(Content content) async {
    _currentContent = content;
    String audioPath;

    if (content.url != null && content.url!.isNotEmpty && await File(content.url!).exists()) {
      audioPath = content.url!;
    } else {
      final byteData = await rootBundle.load('assets/audio/test_song.mp3');
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/test_song.mp3');
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      audioPath = file.path;
    }

    try {
      await _player.setFilePath(audioPath);
      await _player.play();
      isPlaying.value = true;
    } catch (e) {
      debugPrint('Erreur lecture: $e');
    }

    _player.durationStream.listen((d) => duration.value = d);
    _player.positionStream.listen((p) => position.value = p);
    _player.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
      if (state.processingState == ProcessingState.completed) {
        isPlaying.value = false;
      }
    });
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  void seek(Duration pos) => _player.seek(pos);

  void dispose() => _player.dispose();
}