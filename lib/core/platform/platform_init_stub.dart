// Stub implementation for web and non-IO platforms
// This is used when dart:io is not available (web platform)

Future<void> initializePlatformSpecific(List<String> args) async {
  // On web, deep links are handled through URL routing (go_router)
  // Browsers naturally handle single-tab behavior
  // No additional initialization needed
  return Future.value();
}
