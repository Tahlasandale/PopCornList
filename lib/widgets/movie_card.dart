import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/tmdb_movie.dart';

class MovieCard extends StatelessWidget {
  final TmdbMovie movie;
  final VoidCallback onTap;
  final bool isSerie;

  const MovieCard({super.key, required this.movie, required this.onTap, this.isSerie = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  _buildPoster(),
                  if (isSerie)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: popcorn,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SÉRIE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: onyx,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ecran),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: popcorn),
                      const SizedBox(width: 2),
                      Text(
                        movie.voteAverage.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12, color: ticket),
                      ),
                      if (movie.year.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          movie.year,
                          style: const TextStyle(fontSize: 12, color: ticket),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoster() {
    final url = movie.posterUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, _, _) => _placeholder(),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: projecteur,
      child: const Center(child: Icon(Icons.movie_outlined, size: 40, color: ticket)),
    );
  }
}
