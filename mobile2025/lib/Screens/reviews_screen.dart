import 'package:flutter/material.dart';
import 'package:mobile2025/Entites/content.dart';
import 'package:mobile2025/Entites/review.dart';
import 'package:mobile2025/Services/database_helper.dart';
import 'package:mobile2025/Services/notification_service.dart';
import 'package:mobile2025/Screens/moderation_screen.dart';
import 'package:mobile2025/Widgets/add_review_dialog.dart';
import 'package:mobile2025/Widgets/review_item_widget.dart';

class ReviewsScreen extends StatefulWidget {
  final Content content;
  final String currentUserId;
  final bool isModerator;
  final String? preselectedReviewId;

  const ReviewsScreen({
    super.key,
    required this.content,
    required this.currentUserId,
    this.isModerator = false,
    this.preselectedReviewId,
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Review> _reviews = [];
  Map<String, List<Review>> _replies = {};
  Review? _userReview;
  Map<String, String> _usersLabels = {};
  String? _highlightReviewId;
  bool _isLoading = true;
  bool _isRefreshing = false;
  double _averageRating = 0.0;
  int _reviewCount = 0;
  Map<String, int> _ratingDistribution = {};
  String _selectedRatingType = 'all';
  Map<String, String> _userReactions = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
    _loadUsers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_highlightReviewId != null) {
      Future.microtask(() => _scrollToReview(_highlightReviewId!));
    }
  }

  final ScrollController _scrollController = ScrollController();

  Future<void> _scrollToReview(String reviewId) async {
    if (!_scrollController.hasClients) return;
    // Basic approach: scroll to top for now. Could be improved with keys.
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadUsers() async {
    final usersData = await _db.getAllUsers();
    final labels = <String, String>{};
    for (final user in usersData) {
      final id = user['id'] as String?;
      final name = user['name'] as String?;
      if (id != null) {
        labels[id] = name ?? 'Utilisateur';
      }
    }
    if (mounted) {
      setState(() {
        _usersLabels = labels;
      });
    }
  }

  Future<void> _loadAll() async {
    final shouldToggleLoading = !_isRefreshing;
    if (shouldToggleLoading) {
      setState(() => _isLoading = true);
    }
    try {
      if (_isRefreshing) {
        await _loadReviews();
      } else {
        await Future.wait([
          _loadReviews(),
          _loadStatistics(),
        ]);
      }
    } finally {
      _isRefreshing = false;
      if (mounted && shouldToggleLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadReviews() async {
    final reviewsData = await _db.getContentReviews(
      widget.content.id,
      ratingType: _selectedRatingType == 'all' ? null : _selectedRatingType,
    );

    final reviews = reviewsData.map((map) => Review.fromMap(map)).toList();
    final replyGroups = <String, List<Review>>{};
    final otherReviews = <Review>[];
    Review? userReview;

    for (final review in reviews.where((review) => review.isReply)) {
      replyGroups.putIfAbsent(review.parentId ?? '', () => []).add(review);
    }

    for (final review in reviews.where((review) => !review.isReply)) {
      if (review.userId == widget.currentUserId) {
        userReview = review;
      } else {
        otherReviews.add(review);
      }
    }

    final userReactions = widget.currentUserId.isNotEmpty
        ? await _db.getUserReactionsForContent(widget.content.id, widget.currentUserId)
        : <String, String>{};

    if (mounted) {
      setState(() {
        _userReview = userReview;
        _reviews = otherReviews;
        _replies = replyGroups;
        _userReactions = userReactions;
      });
      if (widget.preselectedReviewId != null) {
        _highlightReviewId = widget.preselectedReviewId;
      }
    }
  }

  Future<void> _loadStatistics() async {
    final average = await _db.getAverageRating(widget.content.id);
    final count = await _db.getReviewCount(widget.content.id);
    final distribution = await _db.getRatingDistribution(widget.content.id);
    if (mounted) {
      setState(() {
        _averageRating = average;
        _reviewCount = count;
        _ratingDistribution = distribution;
      });
    }
  }

  Future<void> _addReview(String ratingType, int rating, String? comment, {String? parentId}) async {
    try {
      final reviewData = {
        'contentId': widget.content.id,
        'userId': widget.currentUserId,
        'ratingType': ratingType,
        'rating': rating,
        'comment': comment,
        'parentId': parentId,
      };

      Map<String, dynamic>? parentReview;
      if (parentId != null) {
        parentReview = await _db.getReviewById(parentId);
      }

      if (parentId != null) {
        await _db.addReview(reviewData);
      } else {
        await _db.upsertReview(reviewData);
      }

      if (parentReview != null) {
        final parentUserId = parentReview['userId'] as String?;
        if (parentUserId != null && parentUserId != widget.currentUserId) {
          final responderName = _usersLabels[widget.currentUserId] ?? 'Utilisateur ${widget.currentUserId}';
          final body = comment != null && comment.isNotEmpty
              ? '$responderName a répondu : ${comment.length > 40 ? '${comment.substring(0, 40)}…' : comment}'
              : '$responderName a répondu à votre avis.';
          final payload = '${widget.content.id}:${parentReview['id']}';
          await _db.addNotification(parentUserId, 'Nouvelle réponse', body, payload: payload);
          if (parentUserId == widget.currentUserId) {
            await NotificationService().showReplyNotification(
              responderName: responderName,
              contentTitle: widget.content.title,
            );
          }
        }
      }

      await _loadAll();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(parentId == null ? 'Avis enregistré.' : 'Réponse publiée.')),
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

  Future<void> _reportReview(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Signaler cet avis'),
        content: const Text('Souhaitez-vous signaler cet avis comme inapproprié ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Signaler'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _db.reportReview(review.id, widget.currentUserId);
        await _loadReviews();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avis signalé. Merci pour votre aide.')),
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
  }

  void _showUserReviewActions(Review review) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Modifier mon avis'),
              onTap: () {
                Navigator.pop(ctx);
                _showAddReviewDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteReview(review);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteReview(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer mon avis'),
        content: const Text('Cette action supprimera votre note et vos réponses associées.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteReview(review.id);
    }
  }

  void _showReplyActions(Review reply) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Modifier ma réponse'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditReplyDialog(reply);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Supprimer ma réponse',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteReply(reply);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditReplyDialog(Review reply) async {
    final controller = TextEditingController(text: reply.comment ?? '');
    String? result;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final canSave = controller.text.trim().isNotEmpty;
            return AlertDialog(
              title: const Text('Modifier votre réponse'),
              content: TextField(
                controller: controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Mettre à jour votre réponse...',
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: canSave
                      ? () {
                          result = controller.text.trim();
                          Navigator.pop(ctx);
                        }
                      : null,
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();

    if (result != null && result != reply.comment) {
      await _updateReplyComment(reply, result!);
    }
  }

  Future<void> _updateReplyComment(Review reply, String text) async {
    try {
      await _db.updateReview(reply.id, {
        'comment': text,
        'date': DateTime.now().toIso8601String(),
      });
      _isRefreshing = true;
      await _loadAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réponse mise à jour.')),
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

  Future<void> _confirmDeleteReply(Review reply) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ma réponse'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette réponse ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteReview(reply.id, successMessage: 'Votre réponse a été supprimée.');
    }
  }

  Future<void> _deleteReview(String reviewId, {String successMessage = 'Votre avis a été supprimé.'}) async {
    try {
      await _db.deleteReview(reviewId);
      await _loadAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
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

  Future<void> _toggleReaction(Review review, String reaction) async {
    try {
      await _db.toggleReviewReaction(review.id, widget.currentUserId, reaction);
      _isRefreshing = true;
      await _loadAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _likeReview(Review review) async {
    await _toggleReaction(review, 'like');
  }

  Future<void> _dislikeReview(Review review) async {
    await _toggleReaction(review, 'dislike');
  }

  void _showAddReviewDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AddReviewDialog(
        contentId: widget.content.id,
        initialRatingType: _userReview?.ratingType,
        initialRating: _userReview?.rating,
        initialComment: _userReview?.comment,
        onSubmit: (ratingType, rating, comment) {
          _addReview(ratingType, rating, comment);
        },
      ),
    );
  }

  void _showReplyDialogWithMention(Review parentReview, {String? mention}) {
    showDialog(
      context: context,
      builder: (ctx) => AddReviewDialog(
        contentId: widget.content.id,
        parentReviewId: parentReview.id,
        initialComment: mention,
        onSubmit: (ratingType, rating, comment) {
          _addReview(ratingType, rating, comment, parentId: parentReview.id);
        },
      ),
    );
  }

  void _showModerationPanel() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ModerationScreen(moderatorId: widget.currentUserId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Avis • ${widget.content.title}'),
        actions: [
          if (widget.isModerator)
            IconButton(
              onPressed: _showModerationPanel,
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Modération',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  _buildStatisticsSection(),
                  _buildFilters(),
                  _buildUserReviewSection(),
                  _buildReviewsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Note moyenne', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  Text(
                    _averageRating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Nombre d\'avis', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  Text('$_reviewCount', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_ratingDistribution.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _ratingDistribution.entries.map((entry) {
                final parts = entry.key.split(':');
                final type = parts[0];
                final value = parts.length > 1 ? parts[1] : '';
                final label = _formatDistributionLabel(type, value);
                final percentage = _reviewCount > 0 ? (entry.value / _reviewCount * 100) : 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(width: 120, child: Text(label)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey[300],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${entry.value} (${percentage.round()}%)'),
                    ],
                  ),
                );
              }).toList(),
            )
          else
            const Text('Pas encore de statistiques.'),
        ],
      ),
    );
  }

  String _formatDistributionLabel(String type, String value) {
    switch (type) {
      case 'stars':
        return '$value étoiles';
      case 'thumbs':
        return value == '1' ? 'Pouce levé' : 'Pouce baissé';
      case 'heart':
        return 'Coups de cœur';
      default:
        return '$type $value';
    }
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: 8,
        children: [
          _buildFilterChip('all', 'Tous'),
          _buildFilterChip('stars', 'Étoiles'),
          _buildFilterChip('thumbs', 'Pouces'),
          _buildFilterChip('heart', 'Cœur'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    return FilterChip(
      label: Text(label),
      selected: _selectedRatingType == value,
      onSelected: (selected) {
        setState(() {
          _selectedRatingType = value;
        });
        _loadReviews();
        _loadStatistics();
      },
    );
  }

  Widget _buildUserReviewSection() {
    final review = _userReview;
    if (review == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Partagez votre avis', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Donnez une note et un commentaire pour aider la communauté et améliorer les recommandations.',
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _showAddReviewDialog,
                    icon: const Icon(Icons.star_rate_rounded),
                    label: const Text('Donner une note'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Votre avis', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ReviewItemWidget(
                review: review,
                userName: 'Vous',
                showReplyButton: false,
                margin: EdgeInsets.zero,
                onLongPress: () => _showUserReviewActions(review),
                userReaction: _userReactions[review.id],
                highlight: _highlightReviewId == review.id,
              ),
              ..._buildReplyThread(review.id, depth: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    if (_reviews.isEmpty) {
      return const SizedBox(height: 32);
    }

    return Column(
      children: _reviews.map((review) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReviewItemWidget(
              review: review,
              userName: review.userId == widget.currentUserId ? 'Vous' : _usersLabels[review.userId] ?? 'Utilisateur ${review.userId}',
              onReport: () => _reportReview(review),
              onReply: () => _showReplyDialogWithMention(review, mention: _mentionFor(review.userId)),
              onLike: review.userId == widget.currentUserId ? null : () => _likeReview(review),
              onDislike: review.userId == widget.currentUserId ? null : () => _dislikeReview(review),
              isModerator: widget.isModerator,
              userReaction: _userReactions[review.id],
              highlight: _highlightReviewId == review.id,
            ),
            ..._buildReplyThread(review.id, depth: 1),
            const Divider(height: 32),
          ],
        );
      }).toList(),
    );
  }

  List<Widget> _buildReplyThread(String parentId, {int depth = 1}) {
    final replies = _replies[parentId] ?? [];
    if (replies.isEmpty) return [];

    final indent = 24.0 * depth;

    return replies.expand((reply) {
      final widgets = <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ReviewItemWidget(
            review: reply,
            userName: reply.userId == widget.currentUserId ? 'Vous' : _usersLabels[reply.userId] ?? 'Utilisateur ${reply.userId}',
            onReport: () => _reportReview(reply),
            onReply: () => _showReplyDialogWithMention(reply, mention: _mentionFor(reply.userId)),
            onLike: reply.userId == widget.currentUserId ? null : () => _likeReview(reply),
            onDislike: reply.userId == widget.currentUserId ? null : () => _dislikeReview(reply),
            onLongPress: reply.userId == widget.currentUserId ? () => _showReplyActions(reply) : null,
            userReaction: _userReactions[reply.id],
            showReplyButton: true,
            margin: EdgeInsets.only(left: indent, right: 16),
            highlight: _highlightReviewId == reply.id,
          ),
        ),
      ];
      widgets.addAll(_buildReplyThread(reply.id, depth: depth + 1));
      return widgets;
    }).toList();
  }

  String _mentionFor(String userId) {
    final name = _usersLabels[userId] ?? 'Utilisateur $userId';
    return '@$name ';
  }
}

