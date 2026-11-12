import 'package:material_ui/material_ui.dart';

import 'document.dart';

typedef JuiActionHandler = Future<void> Function(
  String actionId,
  Map<String, Object?> arguments,
);
typedef JuiInputHandler = Future<void> Function(String inputId, String value);

/// Converts validated JUI nodes into ordinary Flutter widgets.
class JuiRenderer extends StatelessWidget {
  const JuiRenderer({
    required this.document,
    required this.onAction,
    this.state = const {},
    this.onInput,
    super.key,
  });

  final JuiDocument document;
  final JuiActionHandler onAction;

  /// Immutable-by-convention view-model data supplied by the Dart host.
  /// JUI can read string values but cannot mutate or execute this state.
  final Map<String, Object?> state;
  final JuiInputHandler? onInput;

  @override
  Widget build(BuildContext context) => _buildNode(document.root);

  String _resolveTextBinding(String path, {Map<String, Object?>? item}) {
    final segments = path.split('.');
    Object? value;
    if (segments.first == 'item') {
      value = item;
      segments.removeAt(0);
    } else {
      value = state;
    }
    for (final segment in segments) {
      if (value is! Map) return '';
      value = value[segment];
    }
    return value is String ? value : '';
  }

  Object? _resolveStateValue(String path) {
    Object? value = state;
    for (final segment in path.split('.')) {
      if (value is! Map) return null;
      value = value[segment];
    }
    return value;
  }

  Widget _buildNode(JuiNode node, {Map<String, Object?>? item}) {
    switch (node.type) {
      case 'column':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: node.children
              .map((child) => _buildNode(child, item: item))
              .toList(growable: false),
        );
      case 'row':
        return Row(
          children: node.children
              .map((child) => _buildNode(child, item: item))
              .toList(growable: false),
        );
      case 'padding':
        return Padding(
          padding: const EdgeInsets.all(16),
          child: node.children.isEmpty
              ? const SizedBox.shrink()
              : _buildNode(node.children.single, item: item),
        );
      case 'text':
        return Text(
          node.bindingPath == null
              ? node.text!
              : _resolveTextBinding(node.bindingPath!, item: item),
          style: TextStyle(fontSize: node.number),
        );
      case 'input':
        return TextFormField(
          initialValue: node.bindingPath == null
              ? null
              : _resolveTextBinding(node.bindingPath!, item: item),
          enabled: onInput != null,
          decoration: InputDecoration(
            labelText: node.label,
            hintText: node.placeholder,
          ),
          onChanged: onInput == null
              ? null
              : (value) => onInput!(node.inputId!, value),
        );
      case 'repeat':
        final collection = _resolveStateValue(node.bindingPath!);
        if (collection is! List) return const SizedBox.shrink();
        final children = <Widget>[];
        for (var index = 0; index < collection.length && index < 100; index++) {
          final entry = collection[index];
          if (entry is Map && entry.keys.every((key) => key is String)) {
            children.add(
              KeyedSubtree(
                key: ValueKey<int>(index),
                child: _buildNode(
                  node.children.single,
                  item: Map<String, Object?>.from(entry),
                ),
              ),
            );
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
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
