/// App-wide constants: endpoints, links and the publisher disclaimer.
library;

class AppConfig {
  AppConfig._();

  /// Cloudflare Worker that holds the official API token. Override with
  /// --dart-define=WORKER_BASE=https://... once the Worker is deployed.
  static const workerBase = String.fromEnvironment(
    'WORKER_BASE',
    defaultValue: 'https://clan-hub-proxy.mabou798.workers.dev',
  );

  /// Community CDN with game art and static game data (ClashKing).
  static const cdnBase = 'https://assets.clashk.ing';

  static const pagesBase = 'https://mabou798-beep.github.io/clan-hub-companion';
  static const supportUrl = '$pagesBase/';
  static const privacyUrl = '$pagesBase/privacy.html';
  static const wallpapersUrl = '$pagesBase/wallpapers.json';

  static const supportEmail = 'mabou798@gmail.com';
  static const policyUrl = 'https://supercell.com/en/fan-content-policy/';

  /// Copied verbatim from Supercell's Fan Content Policy (checked 2026-10-24).
  static const disclaimer =
      "This material is unofficial and is not endorsed by Supercell. For more "
      "information see Supercell's Fan Content Policy: "
      "www.supercell.com/fan-content-policy.";

  static const appVersion = '1.0.0';
}
