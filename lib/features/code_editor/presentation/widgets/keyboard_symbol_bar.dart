import 'package:flutter/material.dart';

/// A touch-first code accessory bar displaying frequently used programming symbols.
/// Allows rapid symbol insertion without toggling mobile soft-keyboard layouts.
class KeyboardSymbolBar extends StatelessWidget {
  final Function(String symbol) onSymbolTap;
  final VoidCallback? onTabTap;
  final VoidCallback? onUndoTap;
  final VoidCallback? onRedoTap;

  const KeyboardSymbolBar({
    super.key,
    required this.onSymbolTap,
    this.onTabTap,
    this.onUndoTap,
    this.onRedoTap,
  });

  static const List<String> _symbols = [
    '{',
    '}',
    '(',
    ')',
    '[',
    ']',
    ';',
    ':',
    '=',
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
    '|',
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
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          // Quick Utility Toggles
          if (onTabTap != null)
            _buildActionChip(
              context,
              label: 'TAB',
              icon: Icons.keyboard_tab,
              onTap: onTabTap!,
            ),
          if (onUndoTap != null)
            _buildActionChip(
              context,
              icon: Icons.undo,
              onTap: onUndoTap!,
            ),
          if (onRedoTap != null)
            _buildActionChip(
              context,
              icon: Icons.redo,
              onTap: onRedoTap!,
            ),

          VerticalDivider(width: 12, indent: 6, endIndent: 6, color: theme.dividerColor),

          // Scrollable Symbol Bar
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
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        symbol,
                        style: TextStyle(
                          fontSize: 14,
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
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
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
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
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
