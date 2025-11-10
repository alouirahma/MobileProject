// lib/Widgets/rating_widgets.dart
import 'package:flutter/material.dart';

// Widget pour notation par étoiles
class StarRatingWidget extends StatelessWidget {
  final int rating;
  final int maxRating;
  final double size;
  final Color? color;
  final bool readOnly;
  final ValueChanged<int>? onRatingChanged;

  const StarRatingWidget({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 24.0,
    this.color,
    this.readOnly = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final starIndex = index + 1;
        return GestureDetector(
          onTap: readOnly ? null : () => onRatingChanged?.call(starIndex),
          child: Icon(
            starIndex <= rating ? Icons.star : Icons.star_border,
            size: size,
            color: color ?? Colors.amber,
          ),
        );
      }),
    );
  }
}

// Widget pour notation par pouces (thumbs)
class ThumbRatingWidget extends StatelessWidget {
  final int rating; // 1 = up, 2 = down
  final double size;
  final bool readOnly;
  final ValueChanged<int>? onRatingChanged;

  const ThumbRatingWidget({
    super.key,
    required this.rating,
    this.size = 32.0,
    this.readOnly = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: readOnly ? null : () => onRatingChanged?.call(1),
          child: Icon(
            Icons.thumb_up,
            size: size,
            color: rating == 1 ? Colors.green : Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: readOnly ? null : () => onRatingChanged?.call(2),
          child: Icon(
            Icons.thumb_down,
            size: size,
            color: rating == 2 ? Colors.red : Colors.grey,
          ),
        ),
      ],
    );
  }
}

// Widget pour notation par cœur
class HeartRatingWidget extends StatelessWidget {
  final bool isLiked;
  final double size;
  final bool readOnly;
  final ValueChanged<bool>? onRatingChanged;

  const HeartRatingWidget({
    super.key,
    required this.isLiked,
    this.size = 32.0,
    this.readOnly = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: readOnly ? null : () => onRatingChanged?.call(!isLiked),
      child: Icon(
        isLiked ? Icons.favorite : Icons.favorite_border,
        size: size,
        color: isLiked ? Colors.red : Colors.grey,
      ),
    );
  }
}

// Widget sélecteur de type de notation
class RatingTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onTypeChanged;

  const RatingTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildTypeButton('stars', Icons.star, 'Étoiles', context),
        const SizedBox(width: 8),
        _buildTypeButton('thumbs', Icons.thumb_up, 'Pouces', context),
        const SizedBox(width: 8),
        _buildTypeButton('heart', Icons.favorite, 'Cœur', context),
      ],
    );
  }

  Widget _buildTypeButton(String type, IconData icon, String label, BuildContext context) {
    final isSelected = selectedType == type;
    return GestureDetector(
      onTap: () => onTypeChanged(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: isSelected ? Colors.white : Colors.grey[700]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget pour afficher la notation selon le type
class RatingDisplayWidget extends StatelessWidget {
  final String ratingType;
  final int rating;
  final double size;

  const RatingDisplayWidget({
    super.key,
    required this.ratingType,
    required this.rating,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    switch (ratingType) {
      case 'stars':
        return StarRatingWidget(rating: rating, size: size, readOnly: true);
      case 'thumbs':
        return ThumbRatingWidget(rating: rating, size: size, readOnly: true);
      case 'heart':
        return HeartRatingWidget(isLiked: rating == 1, size: size, readOnly: true);
      default:
        return StarRatingWidget(rating: rating, size: size, readOnly: true);
    }
  }
}


