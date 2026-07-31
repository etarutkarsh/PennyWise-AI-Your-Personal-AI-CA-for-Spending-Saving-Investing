// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// On the production nginx server (port 80 / 443), hard-navigate to landing.html
/// so the user exits the Flutter SPA and sees the marketing page.
/// On the Flutter dev server (any other port) landing.html doesn't exist,
/// so return false and let the caller fall back to in-app /login navigation.
bool redirectToLanding() {
  final port = html.window.location.port;
  if (port.isEmpty || port == '80' || port == '443') {
    html.window.location.href =
        '${html.window.location.origin}/landing.html';
    return true;
  }
  return false;
}
