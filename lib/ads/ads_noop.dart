/// Web / preview stand-ins: same API as ads_io.dart, renders nothing.
library;

import 'package:flutter/widgets.dart';

class Ads {
  Ads._();
  static Future<void> init() async {}
  static void onQuizRoundEnd() {}
}

class AnchoredBanner extends StatelessWidget {
  const AnchoredBanner({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class NativeAdTile extends StatelessWidget {
  const NativeAdTile({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
