import 'package:flutter/material.dart';

import 'app/bootstrap/app_bootstrap.dart';

Future<void> main() async {
  // Awaits the cookie jar and the session probe, so the first frame already
  // knows whether this poojari is signed in.
  runApp(await bootstrapApp());
}
