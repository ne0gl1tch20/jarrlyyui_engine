import 'package:flutter/material.dart';

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
    super.key,
  });

  final JuiDocument document;
  final JuiActionHandler onAction;

  @override
  Widget build(BuildContext context) => _buildNode(document.root);

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
          node.text!,
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
