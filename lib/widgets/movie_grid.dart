import 'package:flutter/material.dart';
import '../models/tmdb_movie.dart';
import 'movie_card.dart';

class MovieGrid extends StatelessWidget {
  final List<TmdbMovie> movies;
  final void Function(TmdbMovie movie) onMovieTap;
  final int crossAxisCount;
  final Future<void> Function()? onRefresh;

  const MovieGrid({
    super.key,
    required this.movies,
    required this.onMovieTap,
    this.crossAxisCount = 3,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final grid = GridView.builder(
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
        );
      },
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        child: grid,
      );
    }
    return grid;
  }
}
