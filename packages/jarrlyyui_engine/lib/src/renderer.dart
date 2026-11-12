import 'package:material_ui/material_ui.dart';

import 'document.dart';

typedef JuiActionHandler = Future<void> Function(
  String actionId,
  Map<String, Object?> arguments,
);

/// Converts validated JUI nodes into ordinary Flutter widgets.
class JuiRenderer extends StatelessWidget {
  const JuiRenderer({
    required this.document,
    required this.onAction,
    this.state = const {},
    super.key,
  });

  final JuiDocument document;
  final JuiActionHandler onAction;

  /// Immutable-by-convention view-model data supplied by the Dart host.
  /// JUI can read string values but cannot mutate or execute this state.
  final Map<String, Object?> state;

  @override
  Widget build(BuildContext context) => _buildNode(document.root);

  String _resolveTextBinding(String path) {
    Object? value = state;
    for (final segment in path.split('.')) {
      if (value is! Map) return '';
      value = value[segment];
    }
    return value is String ? value : '';
  }

  Widget _buildNode(JuiNode node) {
    switch (node.type) {
      case 'column':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: node.children.map(_buildNode).toList(growable: false),
        );
      case 'row':
        return Row(
          children: node.children.map(_buildNode).toList(growable: false),
        );
      case 'padding':
        return Padding(
          padding: const EdgeInsets.all(16),
          child: node.children.isEmpty
              ? const SizedBox.shrink()
              : _buildNode(node.children.single),
        );
      case 'text':
        return Text(
          node.bindingPath == null
              ? node.text!
              : _resolveTextBinding(node.bindingPath!),
          style: TextStyle(fontSize: node.number),
        );
      case 'button':
        return ElevatedButton(
          onPressed: () => onAction(node.actionId!, node.actionArguments),
          child: Text(node.text!),
        );
      case 'spacer':
        return const SizedBox(height: 12);
      default:
        return const SizedBox.shrink();
    }
  }
}
