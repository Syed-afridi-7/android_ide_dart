import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class LivePreviewModal extends StatefulWidget {
  final String filePath;
  final String htmlContent;

  const LivePreviewModal({
    super.key,
    required this.filePath,
    required this.htmlContent,
  });

  static void show(BuildContext context, String filePath, String htmlContent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LivePreviewModal(filePath: filePath, htmlContent: htmlContent),
    );
  }

  @override
  State<LivePreviewModal> createState() => _LivePreviewModalState();
}

class _LivePreviewModalState extends State<LivePreviewModal> {
  double _viewportWidth = double.infinity;
  String _deviceMode = 'Full Width';

  void _setViewport(double width, String mode) {
    setState(() {
      _viewportWidth = width;
      _deviceMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileName = p.basename(widget.filePath);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Browser Window Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                const Icon(Icons.language, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Web Preview: $fileName',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'http://localhost:8080/$fileName ($_deviceMode)',
                        style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Responsive Viewport Selectors
                IconButton(
                  icon: const Icon(Icons.smartphone, size: 18),
                  tooltip: 'Mobile Viewport (375px)',
                  color: _deviceMode == 'Mobile' ? theme.colorScheme.primary : null,
                  onPressed: () => _setViewport(375, 'Mobile'),
                ),
                IconButton(
                  icon: const Icon(Icons.tablet, size: 18),
                  tooltip: 'Tablet Viewport (768px)',
                  color: _deviceMode == 'Tablet' ? theme.colorScheme.primary : null,
                  onPressed: () => _setViewport(768, 'Tablet'),
                ),
                IconButton(
                  icon: const Icon(Icons.desktop_windows, size: 18),
                  tooltip: 'Full Width',
                  color: _deviceMode == 'Full Width' ? theme.colorScheme.primary : null,
                  onPressed: () => _setViewport(double.infinity, 'Full Width'),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Reload',
                  onPressed: () => setState(() {}),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Browser Canvas Area
          Expanded(
            child: Center(
              child: Container(
                width: _viewportWidth,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRect(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      widget.htmlContent.isEmpty
                          ? '<html><body><h1>Empty HTML Document</h1></body></html>'
                          : widget.htmlContent,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
