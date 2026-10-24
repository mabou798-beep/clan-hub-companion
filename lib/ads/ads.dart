/// Ads entry point. Mobile builds get the real SDK; the web preview gets
/// no-op stand-ins with the same API.
library;

export 'ads_noop.dart' if (dart.library.io) 'ads_io.dart';
