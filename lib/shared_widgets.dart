import 'package:flutter/material.dart';
import 'package:walkmypet/design_system.dart';

/// Shared UI Components for WalkMyPet
///
/// Reusable, consistent components following the DesignSystem principles.
/// Ensures visual consistency and Instagram-level polish across all screens.

// ============================================================================
// BUTTONS
// ============================================================================

/// Primary gradient button with glow effect
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isWalker;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isWalker = true,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        child: AnimatedContainer(
          duration: DesignSystem.animationFast,
          width: width,
          padding: const EdgeInsets.symmetric(
            vertical: DesignSystem.space2,
            horizontal: DesignSystem.space3,
          ),
          decoration: BoxDecoration(
            gradient: isWalker ? DesignSystem.walkerGradient : DesignSystem.ownerGradient,
            borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
            boxShadow: DesignSystem.shadowGlow(
              isWalker ? DesignSystem.walkerPrimary : DesignSystem.ownerPrimary,
            ),
          ),
          child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: DesignSystem.space1),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: DesignSystem.body,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}

/// Secondary outline button
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isDark;
  final IconData? icon;
  final double? width;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(
            vertical: DesignSystem.space2,
            horizontal: DesignSystem.space3,
          ),
          decoration: BoxDecoration(
            color: isDark
              ? DesignSystem.surface2Dark.withValues(alpha: 0.5)
              : DesignSystem.surface2Light,
            borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
            border: Border.all(
              color: DesignSystem.getBorderColor(isDark, opacity: 0.15),
              width: 1.5,
            ),
            boxShadow: DesignSystem.shadowSubtle(Colors.black),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: DesignSystem.getTextPrimary(isDark),
                  size: 20,
                ),
                const SizedBox(width: DesignSystem.space1),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: DesignSystem.body,
                  fontWeight: FontWeight.w700,
                  color: DesignSystem.getTextPrimary(isDark),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// CARDS
// ============================================================================

/// Standard elevated card container
class ElevatedCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final EdgeInsets? padding;
  final LinearGradient? gradient;
  final Color? borderColor;
  final VoidCallback? onTap;

  const ElevatedCard({
    super.key,
    required this.child,
    required this.isDark,
    this.padding,
    this.gradient,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(DesignSystem.space3),
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null
          ? (isDark ? DesignSystem.surfaceDark : DesignSystem.surfaceLight)
          : null,
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
        border: Border.all(
          color: borderColor ?? DesignSystem.getBorderColor(isDark),
          width: 1,
        ),
        boxShadow: DesignSystem.shadowCard(Colors.black),
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
          child: content,
        ),
      );
    }

    return content;
  }
}

// ============================================================================
// SECTION HEADERS
// ============================================================================

/// Section header with icon and title
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final bool isDark;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.isDark,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(DesignSystem.space1_5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                iconColor.withValues(alpha: 0.2),
                iconColor.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: DesignSystem.space2),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: DesignSystem.subheading,
              fontWeight: FontWeight.w700,
              color: DesignSystem.getTextPrimary(isDark),
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ============================================================================
// INPUT FIELDS
// ============================================================================

/// Styled text input field
class StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isDark;
  final bool isWalker;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final int? maxLines;

  const StyledTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.isWalker = true,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: DesignSystem.body,
        fontWeight: FontWeight.w500,
        color: DesignSystem.getTextPrimary(isDark),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          color: DesignSystem.getTextTertiary(isDark),
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          icon,
          color: DesignSystem.getTextSecondary(isDark),
          size: 22,
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
          borderSide: BorderSide(
            color: DesignSystem.getBorderColor(isDark, opacity: 0.1),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
          borderSide: BorderSide(
            color: DesignSystem.getBorderColor(isDark, opacity: 0.1),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
          borderSide: BorderSide(
            color: DesignSystem.getPrimaryColor(isWalker),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
          borderSide: const BorderSide(
            color: DesignSystem.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
          borderSide: const BorderSide(
            color: DesignSystem.error,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: isDark
          ? DesignSystem.backgroundDark.withValues(alpha: 0.5)
          : DesignSystem.backgroundLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignSystem.space2_5,
          vertical: DesignSystem.space2,
        ),
      ),
      validator: validator,
    );
  }
}

// ============================================================================
// BADGES & CHIPS
// ============================================================================

/// Status badge (verified, featured, etc.)
class StatusBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;

  const StatusBadge({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignSystem.space1_5,
        vertical: DesignSystem.space0_5,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: DesignSystem.space0_5),
          Text(
            label,
            style: TextStyle(
              fontSize: DesignSystem.small,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// LOADING & EMPTY STATES
// ============================================================================

/// Loading spinner with message
class LoadingState extends StatelessWidget {
  final String? message;
  final bool isWalker;

  const LoadingState({
    super.key,
    this.message,
    this.isWalker = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: DesignSystem.getPrimaryColor(isWalker),
          ),
          if (message != null) ...[
            const SizedBox(height: DesignSystem.space2),
            Text(
              message!,
              style: const TextStyle(
                fontSize: DesignSystem.caption,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// SNACKBARS
// ============================================================================

/// Show success snackbar
void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
          const SizedBox(width: DesignSystem.space1_5),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: DesignSystem.success,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
      ),
      margin: const EdgeInsets.all(DesignSystem.space2),
      duration: const Duration(seconds: 2),
    ),
  );
}

/// Show error snackbar
void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_rounded, color: Colors.white, size: 20),
          const SizedBox(width: DesignSystem.space1_5),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: DesignSystem.error,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
      ),
      margin: const EdgeInsets.all(DesignSystem.space2),
      duration: const Duration(seconds: 4),
    ),
  );
}

/// Show info snackbar
void showInfoSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.info_rounded, color: Colors.white, size: 20),
          const SizedBox(width: DesignSystem.space1_5),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: DesignSystem.info,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
      ),
      margin: const EdgeInsets.all(DesignSystem.space2),
      duration: const Duration(seconds: 3),
    ),
  );
}
