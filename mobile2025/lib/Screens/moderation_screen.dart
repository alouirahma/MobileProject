// lib/Screens/moderation_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile2025/Entites/review.dart';
import 'package:mobile2025/Services/database_helper.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReportedReviews();
  }

  Future<void> _loadReportedReviews() async {
    setState(() => _isLoading = true);
    try {
      final reviewsData = await _db.getReportedReviews(minReports: 1);
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

  Future<void> _moderateReview(Review review, bool approve, {String? reason}) async {
    try {
      await _db.moderateReview(review.id, widget.moderatorId, approve, reason: reason);
      await _loadReportedReviews();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(approve ? 'Avis approuvé' : 'Avis rejeté')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modération des avis'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reportedReviews.isEmpty
              ? const Center(child: Text('Aucun avis signalé'))
              : ListView.builder(
                  itemCount: _reportedReviews.length,
                  itemBuilder: (ctx, index) {
                    final review = _reportedReviews[index];
                    return Column(
                      children: [
                        ReviewItemWidget(
                          review: review,
                          userName: 'Utilisateur ${review.userId}',
                          showReplyButton: false,
                          isModerator: true,
                        ),
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
                        ),
                        const Divider(),
                      ],
                    );
                  },
                ),
    );
  }
}

