// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// Hard-navigate to landing.html on any port — both production (80/443) and
/// the local dev server (3000). Returns true always on web.
bool redirectToLanding() {
  html.window.location.href =
      '${html.window.location.origin}/landing.html';
  return true;
}
