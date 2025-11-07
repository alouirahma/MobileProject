// lib/Screens/mini_player.dart
import 'package:flutter/material.dart';
import 'package:mobile2025/Services/audio_player_service.dart';
import 'package:mobile2025/Entites/content.dart';
import 'dart:io';

class MiniPlayer extends StatelessWidget {
  final AudioPlayerService _service = AudioPlayerService();

  MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Content?>(
      valueListenable: ValueNotifier(_service.currentContent),
      builder: (_, content, __) {
        if (content == null) return const SizedBox.shrink();

        return Container(
          height: 70,
          color: Colors.grey[900],
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    image: content.coverUrl != null && content.coverUrl!.isNotEmpty
                        ? DecorationImage(image: FileImage(File(content.coverUrl!)), fit: BoxFit.cover)
                        : null,
                    color: Colors.grey[700],
                  ),
                  child: content.coverUrl == null || content.coverUrl!.isEmpty
                      ? const Icon(Icons.music_note, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(content.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(content.artist ?? 'Inconnu', style: const TextStyle(color: Colors.grey), maxLines: 1),
                  ],
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _service.isPlaying,
                builder: (_, playing, __) => IconButton(
                  icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.white, size: 32),
                  onPressed: _service.togglePlayPause,
                ),
              ),
              SizedBox(
                width: 100,
                child: ValueListenableBuilder<Duration>(
                  valueListenable: _service.position,
                  builder: (_, pos, __) {
                    final dur = _service.duration.value ?? Duration.zero;
                    final progress = dur.inMilliseconds > 0 ? pos.inMilliseconds / dur.inMilliseconds : 0.0;
                    return SliderTheme(
                      data: SliderThemeData(thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6), trackHeight: 3),
                      child: Slider(
                        value: progress.clamp(0.0, 1.0),
                        onChanged: (v) => _service.seek(Duration(milliseconds: (v * dur.inMilliseconds).toInt())),
                        activeColor: Colors.green,
                        inactiveColor: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}