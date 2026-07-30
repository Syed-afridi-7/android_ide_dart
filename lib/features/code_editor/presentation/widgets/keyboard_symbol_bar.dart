import 'package:flutter/material.dart';

/// A touch-first code accessory bar displaying frequently used programming symbols,
/// quick action keys (Tab, Esc, Ctrl+C), and directional cursor navigation arrows (←, ↑, ↓, →).
class KeyboardSymbolBar extends StatelessWidget {
  final Function(String symbol) onSymbolTap;
  final VoidCallback? onTabTap;
  final VoidCallback? onEscTap;
  final VoidCallback? onCtrlCTap;
  final VoidCallback? onUndoTap;
  final VoidCallback? onRedoTap;
  final VoidCallback? onArrowLeft;
  final VoidCallback? onArrowUp;
  final VoidCallback? onArrowDown;
  final VoidCallback? onArrowRight;

  const KeyboardSymbolBar({
    super.key,
    required this.onSymbolTap,
    this.onTabTap,
    this.onEscTap,
    this.onCtrlCTap,
    this.onUndoTap,
    this.onRedoTap,
    this.onArrowLeft,
    this.onArrowUp,
    this.onArrowDown,
    this.onArrowRight,
  });

  static const List<String> _symbols = [
    '{',
    '}',
    '[',
    ']',
    '(',
    ')',
    ';',
    ':',
    '=',
    '=>',
    '|',
    '"',
    "'",
    '<',
    '>',
    '/',
    '\\',
    '+',
    '-',
    '*',
    '&',
    '!',
    '?',
    '_',
    '\$',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          // Directional Arrows for Cursor Control
          if (onArrowLeft != null)
            _buildArrowChip(context, icon: Icons.arrow_back, onTap: onArrowLeft!),
          if (onArrowUp != null)
            _buildArrowChip(context, icon: Icons.arrow_upward, onTap: onArrowUp!),
          if (onArrowDown != null)
            _buildArrowChip(context, icon: Icons.arrow_downward, onTap: onArrowDown!),
          if (onArrowRight != null)
            _buildArrowChip(context, icon: Icons.arrow_forward, onTap: onArrowRight!),

          if (onArrowLeft != null || onArrowUp != null || onArrowDown != null || onArrowRight != null)
            VerticalDivider(width: 10, indent: 6, endIndent: 6, color: theme.dividerColor),

          // Quick Action Toggles (TAB, ESC, CTRL+C)
          if (onTabTap != null)
            _buildActionChip(context, label: 'Tab', onTap: onTabTap!),
          if (onEscTap != null)
            _buildActionChip(context, label: 'Esc', onTap: onEscTap!),
          if (onCtrlCTap != null)
            _buildActionChip(context, label: 'Ctrl+C', onTap: onCtrlCTap!),
          if (onUndoTap != null)
            _buildActionChip(context, icon: Icons.undo, onTap: onUndoTap!),
          if (onRedoTap != null)
            _buildActionChip(context, icon: Icons.redo, onTap: onRedoTap!),

          VerticalDivider(width: 10, indent: 6, endIndent: 6, color: theme.dividerColor),

          // Scrollable Symbol List
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _symbols.length,
              itemBuilder: (context, index) {
                final symbol = _symbols[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () => onSymbolTap(symbol),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        symbol,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrowChip(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 4.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildActionChip(
    BuildContext context, {
    String? label,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) Icon(icon, size: 14, color: theme.colorScheme.primary),
              if (label != null) ...[
                if (icon != null) const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
