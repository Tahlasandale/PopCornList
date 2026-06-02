import 'package:flutter/material.dart';
import '../models/tmdb_movie.dart';
import 'movie_card.dart';

class MovieGrid extends StatelessWidget {
  final List<TmdbMovie> movies;
  final void Function(TmdbMovie movie) onMovieTap;
  final int crossAxisCount;
  final bool isSerie;

  const MovieGrid({
    super.key,
    required this.movies,
    required this.onMovieTap,
    this.crossAxisCount = 3,
    this.isSerie = false,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.55,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        return MovieCard(
          movie: movies[index],
          onTap: () => onMovieTap(movies[index]),
          isSerie: isSerie,
        );
      },
    );
  }
}
