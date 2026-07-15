import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CommandPaletteAction {
  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;
  final String? shortcut;
  final VoidCallback onTap;

  const CommandPaletteAction({
    required this.id,
    required this.title,
    this.subtitle,
    required this.icon,
    this.shortcut,
    required this.onTap,
  });
}

class CommandPalette extends StatefulWidget {
  final List<CommandPaletteAction> actions;

  const CommandPalette({super.key, required this.actions});

  /// Show the command palette as an overlay/dialog
  static Future<void> show(
    BuildContext context, {
    required List<CommandPaletteAction> actions,
  }) {
    return showDialog(
      context: context,
      builder: (_) => CommandPalette(actions: actions),
    );
  }

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  int _selectedIndex = 0;
  List<CommandPaletteAction> _filteredActions = [];

  @override
  void initState() {
    super.initState();
    _filteredActions = widget.actions;
    _controller.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _controller.text.toLowerCase();
    setState(() {
      _selectedIndex = 0;
      _filteredActions = query.isEmpty
          ? widget.actions
          : widget.actions
              .where((a) =>
                  a.title.toLowerCase().contains(query) ||
                  (a.subtitle?.toLowerCase().contains(query) ?? false))
              .toList();
    });
  }

  void _moveSelection(int delta) {
    if (_filteredActions.isEmpty) return;
    setState(() {
      _selectedIndex =
          (_selectedIndex + delta) % _filteredActions.length;
      if (_selectedIndex < 0) {
        _selectedIndex = _filteredActions.length - 1;
      }
    });
  }

  void _executeSelection() {
    if (_filteredActions.isEmpty) return;
    final action = _filteredActions[_selectedIndex];
    Navigator.of(context).pop();
    action.onTap();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Request focus on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _moveSelection(1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _moveSelection(-1),
        const SingleActivator(LogicalKeyboardKey.enter): _executeSelection,
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(),
      },
      child: Focus(
        autofocus: true,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 560,
            constraints: const BoxConstraints(maxHeight: 420),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF23242A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF2D2F3A) : const Color(0xFFE5E7EB),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search input
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search commands...',
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        size: 20,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1A1B23)
                          : const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
            // Divider
            Container(
              height: 1,
              color:
                  isDark ? const Color(0xFF2D2F3A) : const Color(0xFFE5E7EB),
            ),
            // Results
            Flexible(
              child: _filteredActions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No commands found',
                        style: TextStyle(
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shrinkWrap: true,
                      itemCount: _filteredActions.length,
                      itemBuilder: (context, index) {
                        final action = _filteredActions[index];
                        final isSelected = index == _selectedIndex;
                        const accentColor = Color(0xFF2563EB);
                        return InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            action.onTap();
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? accentColor.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  action.icon,
                                  size: 18,
                                  color: isSelected
                                      ? accentColor
                                      : theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        action.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: isSelected
                                              ? accentColor
                                              : theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      if (action.subtitle != null)
                                        Text(
                                          action.subtitle!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme
                                                .colorScheme.onSurface
                                                .withOpacity(0.5),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (action.shortcut != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? accentColor.withOpacity(0.1)
                                          : (isDark
                                              ? const Color(0xFF1A1B23)
                                              : const Color(0xFFF3F4F6)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      action.shortcut!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }
}
