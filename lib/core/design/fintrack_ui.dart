import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/glass_container.dart';

/// A centralized UI registry for FinTrack Pro's premium components.
/// These widgets are optimized for performance and visual fidelity.
class FintrackUI {
  /// A premium glass-morphic card with theme-aware shading.
  static Widget glassCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? opacity,
    Color? color,
    BorderRadius? borderRadius,
  }) {
    return Container(
      margin: margin,
      child: GlassContainer(
        padding: padding ?? const EdgeInsets.all(24),
        borderRadius: borderRadius ?? BorderRadius.circular(28),
        opacity: opacity ?? 0.1,
        color: color,
        child: child,
      ),
    );
  }

  /// A standardized header for screen sections.
  static Widget sectionHeader(
    BuildContext context, 
    String title, {
    String? actionLabel,
    VoidCallback? onAction,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: theme.primaryColor),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel, style: TextStyle(color: theme.primaryColor)),
            ),
        ],
      ),
    );
  }

  /// A premium action button with haptic feedback and shimmer capability.
  static Widget actionButton({
    required String label,
    required VoidCallback onPressed,
    required BuildContext context,
    bool isPrimary = true,
    bool isLoading = false,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ElevatedButton(
      onPressed: isLoading ? null : () {
        HapticFeedback.mediumImpact();
        onPressed();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? theme.primaryColor : (isDark ? Colors.white10 : Colors.black12),
        foregroundColor: isPrimary ? Colors.white : (isDark ? Colors.white : Colors.black),
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: isPrimary ? 4 : 0,
        shadowColor: isPrimary ? theme.primaryColor.withValues(alpha: 0.4) : null,
      ),
      child: isLoading
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 12),
                ],
                Text(
                  label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
    );
  }

  /// A high-performance list item wrapper with semantic highlighting.
  static Widget listTile({
    required Widget title,
    required Widget subtitle,
    required Widget leading,
    required Widget trailing,
    VoidCallback? onTap,
    required BuildContext context,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap?.call();
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
      ),
    );
  }
}
