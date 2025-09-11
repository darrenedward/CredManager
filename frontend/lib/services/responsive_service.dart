import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Device type enumeration
enum DeviceType { mobile, tablet, desktop }

/// Responsive breakpoint service for handling different screen sizes
class ResponsiveService {
  // Breakpoint constants
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1200.0;

  /// Get device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return getDeviceTypeFromWidth(screenWidth);
  }

  /// Get device type from width value
  static DeviceType getDeviceTypeFromWidth(double width) {
    if (width < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < tabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Check if current device is mobile
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }

  /// Check if current device is tablet
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  /// Check if current device is desktop
  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop;
  }

  /// Check if device should use mobile layout (mobile or small tablet)
  static bool shouldUseMobileLayout(BuildContext context) {
    return isMobile(context);
  }

  /// Check if device should show drawer instead of sidebar
  static bool shouldUseDrawer(BuildContext context) {
    return isMobile(context);
  }

  /// Check if device should show bottom navigation
  static bool shouldShowBottomNavigation(BuildContext context) {
    return isMobile(context);
  }

  /// Get responsive padding based on device type
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.all(16.0);
      case DeviceType.tablet:
        return const EdgeInsets.all(24.0);
      case DeviceType.desktop:
        return const EdgeInsets.all(32.0);
    }
  }

  /// Get responsive margin based on device type
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.all(8.0);
      case DeviceType.tablet:
        return const EdgeInsets.all(12.0);
      case DeviceType.desktop:
        return const EdgeInsets.all(16.0);
    }
  }

  /// Get responsive card width
  static double getResponsiveCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return screenWidth - 32; // Full width minus padding
      case DeviceType.tablet:
        return (screenWidth - 48) / 2; // Two columns
      case DeviceType.desktop:
        return (screenWidth - 64) / 3; // Three columns
    }
  }

  /// Get minimum tap target size for touch devices
  static double getMinTapTargetSize(BuildContext context) {
    return shouldUseMobileLayout(context) ? 48.0 : 40.0;
  }

  /// Get responsive text scale factor
  static double getResponsiveTextScale(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 1.0;
      case DeviceType.tablet:
        return 1.1;
      case DeviceType.desktop:
        return 1.0;
    }
  }

  /// Get responsive sidebar width
  static double getSidebarWidth(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return MediaQuery.of(context).size.width * 0.85; // 85% of screen width
      case DeviceType.tablet:
        return 280.0;
      case DeviceType.desktop:
        return 250.0;
    }
  }

  /// Get responsive dialog width
  static double getDialogWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return screenWidth - 32; // Almost full width
      case DeviceType.tablet:
        return 500.0;
      case DeviceType.desktop:
        return 600.0;
    }
  }

  /// Check if dialog should be full screen
  static bool shouldUseFullScreenDialog(BuildContext context) {
    return isMobile(context);
  }

  /// Trigger haptic feedback for important actions
  static void triggerHapticFeedback() {
    HapticFeedback.mediumImpact();
  }

  /// Trigger light haptic feedback for selection
  static void triggerLightHaptic() {
    HapticFeedback.selectionClick();
  }

  /// Trigger heavy haptic feedback for important actions
  static void triggerHeavyHaptic() {
    HapticFeedback.heavyImpact();
  }

  /// Check if pull-to-refresh should be enabled (mobile only)
  static bool shouldEnablePullToRefresh(BuildContext context) {
    return isMobile(context);
  }

  /// Get responsive dialog width (alias for getDialogWidth for backward compatibility)
  static double getResponsiveDialogWidth(BuildContext context) {
    return getDialogWidth(context);
  }
}
