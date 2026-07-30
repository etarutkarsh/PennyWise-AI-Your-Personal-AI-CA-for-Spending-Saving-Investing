import 'dart:html' as html;

/// Clears the web session flag and navigates to the landing page.
/// Returns true so callers know navigation has been handled.
bool redirectToLanding() {
  html.window.localStorage.remove('pw_session');
  html.window.location.replace('./landing.html');
  return true;
}
