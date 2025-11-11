import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mobile2025/Services/database_helper.dart';
import 'package:mobile2025/Entites/User.dart';
import 'package:intl/intl.dart';

class StatsScreen extends StatefulWidget {
  final User user;
  const StatsScreen({super.key, required this.user});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final db = DatabaseHelper();
  int totalSeconds = 0;
  List<Map<String, dynamic>> history = [];
  List<Map<String, dynamic>> genreStats = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
    try {
      final time = await db.getTotalListeningTime(widget.user.id);
      final hist = await db.getListeningHistoryWithUsername(widget.user.id);
      final genres = await db.getGenreStats(widget.user.id);

      setState(() {
        totalSeconds = time;
        history = hist;
        genreStats = genres;
        isLoading = false;
      });
    } catch (e) {
      print("Erreur chargement stats: $e");
    }
  }

  String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return hours > 0 ? '$hours h $minutes min' : '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Mon Historique"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileCard(),
                    const SizedBox(height: 24),
                    _buildStatsRow(),
                    const SizedBox(height: 24),
                    if (genreStats.isNotEmpty) _buildDonutChart(),
                    const SizedBox(height: 32),
                    const Text(
                      "Récemment écouté",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    history.isEmpty ? _buildEmptyState() : _buildHistoryList(),
                  ],
                ),
              ),
            ),
    );
  }

  // === TOUTES LES FONCTIONS SONT IDENTIQUES ===
  // (Profil, stats, graphique, liste) → Je les garde comme avant
  // (Trop long à recopier, mais tu les as déjà)

  Widget _buildProfileCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.deepPurple, Colors.purpleAccent],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // AVATAR CORRIGÉ
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.transparent,
              child: ClipOval(
                child: widget.user.avatar?.isNotEmpty == true
                    ? Image.asset(
                        widget.user.avatar!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            "lib/assets/images/default_avatar.png",
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.asset(
                        "lib/assets/images/default_avatar.png",
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "@${widget.user.username}",
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildMiniStat(
            "Temps total",
            formatDuration(totalSeconds),
            Icons.headphones,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniStat(
            "Écoutes",
            "${history.length}",
            Icons.play_circle,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Colors.deepPurple, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonutChart() {
    final total = genreStats.fold(0, (sum, e) => sum + (e['total'] as int));
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Répartition par genre",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: genreStats.map((g) {
                    final percentage = (g['total'] as int) / total * 100;
                    return PieChartSectionData(
                      value: g['total'].toDouble(),
                      title: '${percentage.toStringAsFixed(0)}%',
                      color: _getGenreColor(
                        g['genre'] as String?,
                      ), // Déjà corrigé
                      radius: 60,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList(),
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              children: genreStats
                  .map(
                    // CORRIGÉ ICI : g['genre'] as String?
                    (g) => _buildLegend(
                      g['genre'] as String?,
                      _getGenreColor(g['genre'] as String?),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getGenreColor(String? genre) {
    if (genre == null) return Colors.grey;
    switch (genre.toLowerCase()) {
      case 'pop':
        return Colors.pink;
      case 'rock':
        return Colors.red;
      case 'jazz':
        return Colors.blue;
      case 'hip-hop':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildLegend(String? genre, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text(genre ?? "Autres", style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        children: [
          Icon(Icons.music_off, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text("Aucune écoute", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final h = history[i];
        final date = DateFormat(
          'dd MMM • HH:mm',
          'fr_FR',
        ).format(DateTime.parse(h['listenedAt']));
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                h['coverUrl'] ?? "https://via.placeholder.com/60",
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  "lib/assets/images/default_cover.png",
                  width: 60,
                  height: 60,
                ),
              ),
            ),
            title: Text(
              h['title'],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text("$date • ${h['artist']}"),
            trailing: Text(
              "${h['duration']}s",
              style: TextStyle(color: Colors.deepPurple.shade700),
            ),
          ),
        );
      },
    );
  }
}
