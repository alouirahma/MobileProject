// lib/Screens/moderation_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile2025/Entites/review.dart';
import 'package:mobile2025/Services/database_helper.dart';
import 'package:mobile2025/Services/notification_service.dart';
import 'package:mobile2025/Widgets/review_item_widget.dart';

class ModerationScreen extends StatefulWidget {
  final String moderatorId;

  const ModerationScreen({
    super.key,
    required this.moderatorId,
  });

  @override
  State<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends State<ModerationScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Review> _reportedReviews = [];
  List<Review> _resolvedReviews = [];
  int _minReports = 1;
  String? _filterType;
  String? _sortOption;
  bool _showResolved = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReportedReviews();
  }

  Future<void> _loadReportedReviews() async {
    setState(() => _isLoading = true);
    try {
      final reviewsData = await _db.getReportedReviews(
        minReports: _minReports,
        ratingType: _filterType,
        sortOption: _sortOption,
      );
      setState(() {
        _reportedReviews = reviewsData.map((e) => Review.fromMap(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _loadResolvedReviews() async {
    setState(() => _isLoading = true);
    try {
      final reviewsData = await _db.getModeratedReviews(ratingType: _filterType);
      setState(() {
        _resolvedReviews = reviewsData.map((e) => Review.fromMap(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _moderateReview(Review review, bool approve, {String? reason}) async {
    try {
      await _db.moderateReview(review.id, widget.moderatorId, approve, reason: reason);
      await _loadReportedReviews();
      if (_showResolved) {
        await _loadResolvedReviews();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(approve ? 'Avis approuvé' : 'Avis rejeté')),
        );
      }
      final status = approve ? 'approuvé' : 'rejeté';
      await _db.addNotification(
        review.userId,
        'Modération de votre avis',
        'Votre avis a été $status.',
        payload: '${review.contentId}:${review.id}',
      );
      if (review.userId == widget.moderatorId) {
        await NotificationService().showModerationNotification(
          status: status,
          contentTitle: review.comment ?? '',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _showModerationDialog(Review review) async {
    final reasonController = TextEditingController();
    bool? approve;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Modérer cet avis'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Avis signalé ${review.reportedCount} fois'),
                  if (review.comment != null) ...[
                    const SizedBox(height: 16),
                    Text('Commentaire: ${review.comment}'),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setDialogState(() => approve = true);
                          _moderateReview(review, true);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Approuver'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setDialogState(() => approve = false);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Rejeter'),
                      ),
                    ],
                  ),
                  if (approve == false) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Raison du rejet',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _moderateReview(review, false, reason: reasonController.text.isEmpty ? null : reasonController.text);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Confirmer le rejet'),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _showResolved ? _resolvedReviews : _reportedReviews;
    final pendingCount = _reportedReviews.length;
    final totalReports = _reportedReviews.fold<int>(0, (sum, review) => sum + review.reportedCount);
    final resolvedCount = _resolvedReviews.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modération des avis'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCard(pendingCount, totalReports, resolvedCount),
                const SizedBox(height: 16),
                _buildFilters(context),
                const SizedBox(height: 16),
                if (list.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(_showResolved ? 'Aucun avis rejeté' : 'Aucun avis signalé'),
                    ),
                  )
                else
                  ...list.map((review) => _buildModerationCard(context, review, resolved: _showResolved)),
              ],
            ),
    );
  }

  Widget _buildSummaryCard(int pendingCount, int totalReports, int resolvedCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStat('En attente', '$pendingCount'),
            _buildStat('Signalements', '$totalReports'),
            _buildStat('Rejetés', '$resolvedCount'),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Filtres', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildFilterChip(null, 'Tous'),
            _buildFilterChip('stars', 'Étoiles'),
            _buildFilterChip('thumbs', 'Pouces'),
            _buildFilterChip('heart', 'Cœur'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Min. signalements'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _minReports,
                    isExpanded: true,
                    items: const [1, 2, 3, 5, 10]
                        .map((value) => DropdownMenuItem<int>(
                              value: value,
                              child: Text(value.toString()),
                            ))
                        .toList(),
                    onChanged: (value) async {
                      if (value == null) return;
                      setState(() => _minReports = value);
                      await _loadReportedReviews();
                      if (_showResolved) {
                        await _loadResolvedReviews();
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Tri'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortOption,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'reports_desc', child: Text('Plus signalés')),
                      DropdownMenuItem(value: 'reports_asc', child: Text('Moins signalés')),
                      DropdownMenuItem(value: 'date_desc', child: Text('Plus récents')),
                      DropdownMenuItem(value: 'date_asc', child: Text('Plus anciens')),
                      DropdownMenuItem(value: 'likes_desc', child: Text('Plus de likes')),
                      DropdownMenuItem(value: 'likes_asc', child: Text('Moins de likes')),
                    ],
                    onChanged: (value) async {
                      setState(() => _sortOption = value);
                      await _loadReportedReviews();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Afficher les avis rejetés (historique)'),
          value: _showResolved,
          onChanged: (value) async {
            setState(() => _showResolved = value);
            if (value) {
              await _loadResolvedReviews();
            } else {
              await _loadReportedReviews();
            }
          },
        ),
      ],
    );
  }

  ChoiceChip _buildFilterChip(String? value, String label) {
    final isSelected = _filterType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) async {
        final newValue = selected ? value : null;
        setState(() => _filterType = newValue);
        await _loadReportedReviews();
        if (_showResolved) {
          await _loadResolvedReviews();
        }
      },
    );
  }

  Widget _buildModerationCard(BuildContext context, Review review, {required bool resolved}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReviewItemWidget(
              review: review,
              userName: 'Utilisateur ${review.userId}',
              showReplyButton: false,
              isModerator: true,
            ),
            const SizedBox(height: 8),
            if (!resolved)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _moderateReview(review, true),
                    icon: const Icon(Icons.check, color: Colors.green),
                    label: const Text('Approuver'),
                  ),
                  TextButton.icon(
                    onPressed: () => _showModerationDialog(review),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Rejeter'),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.gavel, size: 16, color: Colors.redAccent),
                      const SizedBox(width: 4),
                      Text('Rejeté par ${review.moderatedBy ?? 'Modérateur'}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Le ${_formatDate(review.moderationDate)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  if (review.moderationReason != null && review.moderationReason!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Raison : ${review.moderationReason}'),
                    ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _moderateReview(review, true),
                      icon: const Icon(Icons.restore, color: Colors.green),
                      label: const Text('Restaurer'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '-';
    try {
      final date = DateTime.parse(iso);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

