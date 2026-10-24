/// More: support, privacy, data sources and the publisher's disclaimer.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../theme.dart';
import 'quiz_screen.dart';
import 'wallpapers_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  Future<void> _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget tile(IconData icon, String title, String? sub, VoidCallback onTap) => ListTile(
          leading: Icon(icon, color: Palette.gold),
          title: Text(title, style: t.titleMedium),
          subtitle: sub == null ? null : Text(sub, style: t.bodyMedium),
          trailing: const Icon(Icons.chevron_right_rounded, color: Palette.inkFaint),
          onTap: onTap,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              tile(Icons.psychology_alt_rounded, 'Quiz', 'Ten quick questions per round',
                  () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuizScreen()))),
              tile(Icons.wallpaper_rounded, 'Wallpapers', null,
                  () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WallpapersScreen()))),
              const Divider(height: 24),
              tile(Icons.support_agent_rounded, 'Support', AppConfig.supportEmail,
                  () => _open(AppConfig.supportUrl)),
              tile(Icons.privacy_tip_rounded, 'Privacy policy', null, () => _open(AppConfig.privacyUrl)),
              tile(Icons.description_outlined, 'Open-source licences', null,
                  () => showLicensePage(
                        context: context,
                        applicationName: 'Clan Hub',
                        applicationVersion: AppConfig.appVersion,
                      )),
              const Divider(height: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: Text('Data sources', style: t.titleLarge),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  'Player and event data come from the official game API. '
                  'Unit stats and art come from the community ClashKing asset library. '
                  'Clan Hub is an independent fan project.',
                  style: TextStyle(color: Palette.inkSoft, height: 1.45),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Palette.stone,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Palette.gold.withValues(alpha: 0.45)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Unofficial fan app',
                        style: TextStyle(fontFamily: displayFont, fontSize: 18, color: Palette.gold)),
                    const SizedBox(height: 8),
                    const Text(
                      AppConfig.disclaimer,
                      style: TextStyle(fontSize: 15, color: Palette.ink, height: 1.5),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () => _open(AppConfig.policyUrl),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Read the Fan Content Policy'),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Clan Hub ${AppConfig.appVersion} · © 2026 Mohamed Abounachit',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Palette.inkFaint, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
