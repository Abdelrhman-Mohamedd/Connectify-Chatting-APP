// Platform-specific initialization using conditional imports
// This file exports the appropriate implementation based on the platform

// Export the default (web/mobile) implementation
// If compiling for Windows, use the Windows-specific implementation instead
export 'platform_init_stub.dart'
    if (dart.library.io) 'platform_init_io.dart';

