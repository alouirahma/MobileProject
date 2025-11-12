// lib/Widgets/add_review_dialog.dart
import 'package:flutter/material.dart';
import 'package:mobile2025/Widgets/rating_widgets.dart';

class AddReviewDialog extends StatefulWidget {
  final String? contentId;
  final String? parentReviewId; // Pour les réponses
  final Function(String ratingType, int rating, String? comment) onSubmit;
  final String? initialRatingType;
  final int? initialRating;
  final String? initialComment;

  const AddReviewDialog({
    super.key,
    this.contentId,
    this.parentReviewId,
    required this.onSubmit,
    this.initialRatingType,
    this.initialRating,
    this.initialComment,
  });

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  late String _ratingType;
  late int _rating;
  late final TextEditingController _commentController;

  bool get _isReply => widget.parentReviewId != null;

  bool get _canSubmit {
    if (_isReply) {
      return _commentController.text.trim().isNotEmpty;
    }
    return _rating > 0;
  }

  @override
  void initState() {
    super.initState();
    _ratingType = widget.initialRatingType ?? 'stars';
    _rating = widget.initialRating ?? 0;
    _commentController = TextEditingController(text: widget.initialComment ?? '');
    _commentController.addListener(_onCommentChanged);
  }

  @override
  void dispose() {
    _commentController.removeListener(_onCommentChanged);
    _commentController.dispose();
    super.dispose();
  }

  void _onCommentChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isReply ? 'Répondre à cet avis' : 'Publier un avis'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isReply) ...[
              const Text('Type de notation'),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: RatingTypeSelector(
                    selectedType: _ratingType,
                    onTypeChanged: (type) {
                      setState(() {
                        _ratingType = type;
                        _rating = 0;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Votre note'),
              const SizedBox(height: 8),
              _buildRatingInput(),
            ] else ...[
              const Text('Votre réponse sera visible publiquement.'),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: _isReply ? 'Votre réponse' : 'Commentaire (optionnel)',
                hintText: _isReply ? 'Écrivez votre réponse...' : 'Partagez votre expérience...',
                border: const OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _canSubmit
              ? () {
                  final commentText = _commentController.text.trim();
                  final finalRatingType = _isReply ? 'stars' : _ratingType;
                  final finalRating = _isReply ? 1 : _rating;
                  widget.onSubmit(
                    finalRatingType,
                    finalRating,
                    commentText.isEmpty ? null : commentText,
                  );
                  Navigator.pop(context);
                }
              : null,
          child: Text(_isReply ? 'Répondre' : 'Publier'),
        ),
      ],
    );
  }

  Widget _buildRatingInput() {
    switch (_ratingType) {
      case 'stars':
        return StarRatingWidget(
          rating: _rating,
          onRatingChanged: (rating) => setState(() => _rating = rating),
        );
      case 'thumbs':
        return ThumbRatingWidget(
          rating: _rating,
          onRatingChanged: (rating) => setState(() => _rating = rating),
        );
      case 'heart':
        return HeartRatingWidget(
          isLiked: _rating == 1,
          onRatingChanged: (isLiked) => setState(() => _rating = isLiked ? 1 : 0),
        );
      default:
        return StarRatingWidget(
          rating: _rating,
          onRatingChanged: (rating) => setState(() => _rating = rating),
        );
    }
  }
}

