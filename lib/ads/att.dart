/// App Tracking Transparency seam (no-op on web).
library;

export 'att_noop.dart' if (dart.library.io) 'att_io.dart';
