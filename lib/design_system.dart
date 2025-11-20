import 'package:flutter/material.dart';

/// WalkMyPet Design System
///
/// A comprehensive design system ensuring visual consistency, modern aesthetics,
/// and Instagram-level polish across the entire application.
///
/// Design Principles:
/// - Clean, minimal visual hierarchy
/// - 8pt grid spacing system
/// - Consistent typography scale
/// - Unified shadow elevation system
/// - Intentional color usage with proper contrast
/// - Smooth, purposeful animations

class DesignSystem {
  // ============================================================================
  // TYPOGRAPHY SCALE (SF Pro / Inter inspired)
  // ============================================================================

  /// Display text for hero sections and major headlines
  static const double displayLarge = 40.0;

  /// Large headlines (H1)
  static const double h1 = 32.0;

  /// Medium headlines (H2)
  static const double h2 = 24.0;

  /// Small headlines (H3)
  static const double h3 = 20.0;

  /// Subheadings
  static const double subheading = 18.0;

  /// Body text
  static const double body = 16.0;

  /// Secondary body text
  static const double bodySmall = 15.0;

  /// Captions and helper text
  static const double caption = 14.0;

  /// Small labels and metadata
  static const double small = 12.0;

  /// Extra small text (timestamps, badges)
  static const double tiny = 11.0;

  /// Micro text (rarely used)
  static const double micro = 10.0;

  // ============================================================================
  // 8PT GRID SPACING SYSTEM
  // ============================================================================

  /// 4px - Micro spacing (within components)
  static const double space0_5 = 4.0;

  /// 8px - Minimal spacing
  static const double space1 = 8.0;

  /// 12px - Compact spacing
  static const double space1_5 = 12.0;

  /// 16px - Standard spacing
  static const double space2 = 16.0;

  /// 20px - Comfortable spacing
  static const double space2_5 = 20.0;

  /// 24px - Section spacing
  static const double space3 = 24.0;

  /// 32px - Large section spacing
  static const double space4 = 32.0;

  /// 40px - Extra large spacing
  static const double space5 = 40.0;

  /// 48px - Hero spacing
  static const double space6 = 48.0;

  /// 64px - Maximum spacing
  static const double space8 = 64.0;

  // ============================================================================
  // BORDER RADIUS (Consistent rounded corners)
  // ============================================================================

  /// 8px - Minimal rounding (small chips, badges)
  static const double radiusTiny = 8.0;

  /// 10px - Compact rounding (small buttons)
  static const double radiusCompact = 10.0;

  /// 12px - Small rounding (cards, buttons)
  static const double radiusSmall = 12.0;

  /// 16px - Medium rounding (standard cards)
  static const double radiusMedium = 16.0;

  /// 20px - Large rounding (featured cards)
  static const double radiusLarge = 20.0;

  /// 24px - Extra large rounding (hero sections)
  static const double radiusXL = 24.0;

  /// 30px - Pill shape (tags, chips)
  static const double radiusPill = 30.0;

  /// 999px - Full circle (avatars, icons)
  static const double radiusFull = 999.0;

  // ============================================================================
  // COLOR PALETTE
  // ============================================================================

  // Primary Colors
  static const Color walkerPrimary = Color(0xFF6366F1); // Indigo
  static const Color walkerSecondary = Color(0xFF8B5CF6); // Purple
  static const Color ownerPrimary = Color(0xFFEC4899); // Pink
  static const Color ownerSecondary = Color(0xFFDB2777); // Deep Pink

  // Success & Status Colors
  static const Color success = Color(0xFF10B981); // Green
  static const Color successDark = Color(0xFF059669);
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Red
  static const Color info = Color(0xFF3B82F6); // Blue

  // Neutral Colors (Dark Mode)
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color surface2Dark = Color(0xFF334155); // Slate 700

  // Neutral Colors (Light Mode)
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight = Color(0xFFFFFFFF); // White
  static const Color surface2Light = Color(0xFFFAFAFA); // Gray

  // Text Colors
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFD1D5DB); // Gray 300
  static const Color textTertiaryDark = Color(0xFF9CA3AF); // Gray 400

  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569); // Slate 600
  static const Color textTertiaryLight = Color(0xFF64748B); // Slate 500

  // Rating & Special
  static const Color rating = Color(0xFFFBBF24); // Yellow/Gold
  static const Color verified = Color(0xFF10B981); // Green

  // ============================================================================
  // ELEVATION & SHADOW SYSTEM
  // ============================================================================

  /// Subtle elevation - Minimal depth (hover states, subtle cards)
  static List<BoxShadow> shadowSubtle(Color baseColor) => [
    BoxShadow(
      color: baseColor.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  /// Card elevation - Standard card depth
  static List<BoxShadow> shadowCard(Color baseColor) => [
    BoxShadow(
      color: baseColor.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  /// Elevated - Raised elements (modals, dropdowns)
  static List<BoxShadow> shadowElevated(Color baseColor) => [
    BoxShadow(
      color: baseColor.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  /// Float - Floating action buttons, prominent elements
  static List<BoxShadow> shadowFloat(Color baseColor) => [
    BoxShadow(
      color: baseColor.withValues(alpha: 0.16),
      blurRadius: 32,
      offset: const Offset(0, 12),
      spreadRadius: -4,
    ),
  ];

  /// Hero - Hero sections, feature cards
  static List<BoxShadow> shadowHero(Color baseColor) => [
    BoxShadow(
      color: baseColor.withValues(alpha: 0.20),
      blurRadius: 48,
      offset: const Offset(0, 16),
      spreadRadius: -8,
    ),
  ];

  /// Glow - Accent/colored shadows for CTAs
  static List<BoxShadow> shadowGlow(Color accentColor) => [
    BoxShadow(
      color: accentColor.withValues(alpha: 0.4),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  /// Double shadow - Premium depth effect
  static List<BoxShadow> shadowDouble(Color baseColor) => [
    BoxShadow(
      color: baseColor.withValues(alpha: 0.1),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: baseColor.withValues(alpha: 0.06),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

  // ============================================================================
  // ANIMATION DURATIONS
  // ============================================================================

  /// Quick micro-interactions (100ms)
  static const Duration animationQuick = Duration(milliseconds: 100);

  /// Fast transitions (200ms)
  static const Duration animationFast = Duration(milliseconds: 200);

  /// Standard transitions (300ms)
  static const Duration animationStandard = Duration(milliseconds: 300);

  /// Medium transitions (400ms)
  static const Duration animationMedium = Duration(milliseconds: 400);

  /// Slow, noticeable transitions (600ms)
  static const Duration animationSlow = Duration(milliseconds: 600);

  /// Hero animations (800ms)
  static const Duration animationHero = Duration(milliseconds: 800);

  // ============================================================================
  // ANIMATION CURVES
  // ============================================================================

  /// Standard ease out - Most UI transitions
  static const Curve curveEaseOut = Curves.easeOut;

  /// Standard ease in out - Symmetrical animations
  static const Curve curveEaseInOut = Curves.easeInOut;

  /// Smooth cubic - Polished feel
  static const Curve curveEaseOutCubic = Curves.easeOutCubic;

  /// Bouncy - Playful interactions
  static const Curve curveElastic = Curves.elasticOut;

  /// Sharp - Quick, decisive movements
  static const Curve curveSharp = Curves.easeOutExpo;

  // ============================================================================
  // GRADIENT PRESETS
  // ============================================================================

  /// Walker gradient (Indigo to Purple)
  static const LinearGradient walkerGradient = LinearGradient(
    colors: [walkerPrimary, walkerSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Owner gradient (Pink to Deep Pink)
  static const LinearGradient ownerGradient = LinearGradient(
    colors: [ownerPrimary, ownerSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Success gradient
  static const LinearGradient successGradient = LinearGradient(
    colors: [success, successDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Hero gradient (Multi-color)
  static const LinearGradient heroGradient = LinearGradient(
    colors: [walkerPrimary, walkerSecondary, ownerPrimary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get text color based on theme
  static Color getTextPrimary(bool isDark) =>
    isDark ? textPrimaryDark : textPrimaryLight;

  /// Get secondary text color based on theme
  static Color getTextSecondary(bool isDark) =>
    isDark ? textSecondaryDark : textSecondaryLight;

  /// Get tertiary text color based on theme
  static Color getTextTertiary(bool isDark) =>
    isDark ? textTertiaryDark : textTertiaryLight;

  /// Get background color based on theme
  static Color getBackground(bool isDark) =>
    isDark ? backgroundDark : backgroundLight;

  /// Get surface color based on theme
  static Color getSurface(bool isDark) =>
    isDark ? surfaceDark : surfaceLight;

  /// Get secondary surface color based on theme
  static Color getSurface2(bool isDark) =>
    isDark ? surface2Dark : surface2Light;

  /// Get primary color based on user type
  static Color getPrimaryColor(bool isWalker) =>
    isWalker ? walkerPrimary : ownerPrimary;

  /// Get gradient based on user type
  static LinearGradient getGradient(bool isWalker) =>
    isWalker ? walkerGradient : ownerGradient;

  /// Get border color with opacity based on theme
  static Color getBorderColor(bool isDark, {double opacity = 0.1}) =>
    isDark
      ? Colors.white.withValues(alpha: opacity)
      : Colors.black.withValues(alpha: opacity);
}
