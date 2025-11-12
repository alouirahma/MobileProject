// lib/Widgets/review_item_widget.dart
import 'package:flutter/material.dart';
import 'package:mobile2025/Entites/review.dart';
import 'package:mobile2025/Widgets/rating_widgets.dart';

class ReviewItemWidget extends StatelessWidget {
  final Review review;
  final String? userName;
  final String? userAvatar;
  final VoidCallback? onReport;
  final VoidCallback? onReply;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? margin;
  final String? userReaction;
  final bool highlight;
  final bool showReplyButton;
  final bool isModerator;

  const ReviewItemWidget({
    super.key,
    required this.review,
    this.userName,
    this.userAvatar,
    this.onReport,
    this.onReply,
    this.onLike,
    this.onDislike,
    this.onLongPress,
    this.margin,
    this.userReaction,
    this.highlight = false,
    this.showReplyButton = true,
    this.isModerator = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Card(
        color: highlight ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12) : null,
        margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec utilisateur et notation
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: userAvatar != null ? NetworkImage(userAvatar!) : null,
                  child: userAvatar == null ? Text(userName?.substring(0, 1).toUpperCase() ?? 'U') : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName ?? 'Utilisateur',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      if (!review.isReply)
                      RatingDisplayWidget(
                        ratingType: review.ratingType,
                        rating: review.rating,
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Réponse',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(review.date),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            
            // Commentaire
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(review.comment!),
            ],
            
            // Actions (Like, Dislike, Reply, Report)
            const SizedBox(height: 12),
            Row(
              children: [
                if (onLike != null)
                  _ReactionButton(
                    icon: Icons.thumb_up_outlined,
                    count: review.likes,
                    isActive: userReaction == 'like',
                    onPressed: onLike,
                  ),
                if (onDislike != null)
                  _ReactionButton(
                    icon: Icons.thumb_down_outlined,
                    count: review.dislikes,
                    isActive: userReaction == 'dislike',
                    onPressed: onDislike,
                  ),
                const Spacer(),
                if (onReply != null)
                  TextButton.icon(
                    onPressed: onReply,
                    icon: const Icon(Icons.reply, size: 16),
                    label: const Text('Répondre'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                if (onReport != null)
                  IconButton(
                    icon: const Icon(Icons.flag_outlined),
                    iconSize: 18,
                    onPressed: onReport,
                    tooltip: 'Signaler',
                    color: Colors.orange,
                  ),
                if (isModerator && review.reportedCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${review.reportedCount} signalements',
                      style: const TextStyle(fontSize: 10, color: Colors.orange),
                    ),
                  ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return 'Il y a ${difference.inMinutes} min';
        }
        return 'Il y a ${difference.inHours} h';
      } else if (difference.inDays < 7) {
        return 'Il y a ${difference.inDays} j';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }
}

class _ReactionButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool isActive;
  final VoidCallback? onPressed;

  const _ReactionButton({
    required this.icon,
    required this.count,
    this.isActive = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Theme.of(context).colorScheme.primary : Colors.grey[700];
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(48, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 4),
          Text('$count',
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              )),
        ],
      ),
    );
  }
}

