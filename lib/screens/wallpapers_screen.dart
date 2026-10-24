/// Wallpapers: a curated list of official fan-kit art, published as
/// wallpapers.json on the app's GitHub Pages site.
library;

import 'package:flutter/material.dart';

import '../config.dart';
import '../services/api.dart';
import '../theme.dart';
import '../widgets/common.dart';

class Wallpaper {
  const Wallpaper(this.title, this.thumbUrl, this.fullUrl);
  final String title;
  final String thumbUrl;
  final String fullUrl;

  static Wallpaper? fromJson(Map<String, dynamic> j) {
    final full = j['url'] as String?;
    if (full == null) return null;
    return Wallpaper(j['title'] as String? ?? '', j['thumb'] as String? ?? full, full);
  }
}

class WallpapersScreen extends StatefulWidget {
  const WallpapersScreen({super.key});

  @override
  State<WallpapersScreen> createState() => _WallpapersScreenState();
}

class _WallpapersScreenState extends State<WallpapersScreen> {
  late Future<List<Wallpaper>> _future = _load();

  Future<List<Wallpaper>> _load() async {
    final raw = await Api().getJson(Uri.parse(AppConfig.wallpapersUrl));
    return ((raw as Map<String, dynamic>)['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Wallpaper.fromJson)
        .whereType<Wallpaper>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallpapers')),
      body: FutureBuilder<List<Wallpaper>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) {
            return MessageView.error(friendlyError(snap.error!),
                () => setState(() => _future = _load()));
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const MessageView(
              icon: Icons.wallpaper_rounded,
              title: 'No wallpapers yet',
              message: 'New art is added from time to time. Check back soon.',
            );
          }
          return GridView.extent(
            padding: const EdgeInsets.all(16),
            maxCrossAxisExtent: 200,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 9 / 16,
            children: [
              for (final w in items)
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => _WallpaperView(wallpaper: w))),
                  child: Hero(
                    tag: w.fullUrl,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ColoredBox(
                        color: Palette.stone,
                        child: ArtImage(w.thumbUrl, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _WallpaperView extends StatelessWidget {
  const _WallpaperView({required this.wallpaper});
  final Wallpaper wallpaper;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.black38,
          title: Text(wallpaper.title, style: Theme.of(context).textTheme.titleMedium),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              maxScale: 4,
              child: Hero(
                tag: wallpaper.fullUrl,
                child: ArtImage(wallpaper.fullUrl, fit: BoxFit.cover),
              ),
            ),
            const Positioned(
              left: 20,
              right: 20,
              bottom: 32,
              child: SafeArea(
                child: Text(
                  'Long-press and save from your browser, or take a screenshot, then set it from Photos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );
}
