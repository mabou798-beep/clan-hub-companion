/// Shared building blocks: loading / empty / error states, art with a safe
/// fallback, section headers and stat pills.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label = 'Loading…'});
  final String label;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(strokeWidth: 3, color: Palette.gold),
            ),
            const SizedBox(height: 14),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
}

class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.tone = Palette.gold,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color tone;

  factory MessageView.error(String message, VoidCallback onRetry) => MessageView(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load',
        message: message,
        actionLabel: 'Try again',
        onAction: onRetry,
        tone: Palette.ember,
      );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: tone, size: 34),
              ),
              const SizedBox(height: 16),
              Text(title, style: t.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(message, style: t.bodyMedium, textAlign: TextAlign.center),
              if (actionLabel != null) ...[
                const SizedBox(height: 18),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Network art that never shows a broken image and never prints a name, so
/// it is safe to use inside quiz questions.
class ArtImage extends StatelessWidget {
  const ArtImage(this.url, {super.key, this.fit = BoxFit.contain, this.size});
  final String? url;
  final BoxFit fit;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null) return _Placeholder(size: size);
    return CachedNetworkImage(
      imageUrl: u,
      fit: fit,
      width: size,
      height: size,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, _) => _Placeholder(size: size, pulse: true),
      errorWidget: (_, _, _) => _Placeholder(size: size),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.size, this.pulse = false});
  final double? size;
  final bool pulse;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(
            pulse ? Icons.hourglass_empty_rounded : Icons.shield_moon_outlined,
            color: Palette.line,
            size: (size ?? 48) * 0.45,
          ),
        ),
      );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            ?trailing,
          ],
        ),
      );
}

class StatPill extends StatelessWidget {
  const StatPill({super.key, required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Palette.stoneHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label.toUpperCase(),
                style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w800,
                    color: Palette.inkFaint)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontFamily: displayFont,
                    fontSize: 17,
                    color: color ?? Palette.ink)),
          ],
        ),
      );
}

/// Soft vignette card background used for hero art.
BoxDecoration glowDecoration(Color tone, {double radius = 18}) => BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: RadialGradient(
        center: const Alignment(0, -0.3),
        radius: 0.95,
        colors: [tone.withValues(alpha: 0.32), Palette.stone],
      ),
      border: Border.all(color: Palette.line),
    );
