import 'dart:collection';

/// A validated, immutable JUI document.
class JuiDocument {
  const JuiDocument({
    required this.schemaVersion,
    required this.screenId,
    required this.root,
  });

  final int schemaVersion;
  final String screenId;
  final JuiNode root;
}

/// Declarative node. Properties and children are immutable after parsing.
class JuiNode {
  JuiNode({
    required this.type,
    Map<String, Object?> properties = const {},
    List<JuiNode> children = const [],
  })  : properties = UnmodifiableMapView(properties),
        children = List.unmodifiable(children);

  final String type;
  final Map<String, Object?> properties;
  final List<JuiNode> children;

  String? get text => properties['text'] as String?;
  String? get bindingPath => properties['binding'] as String?;
  double? get number => (properties['fontSize'] as num?)?.toDouble();
  String? get actionId => (properties['action'] as Map?)?['id'] as String?;
  Map<String, Object?> get actionArguments => Map<String, Object?>.from(
        (properties['action'] as Map?)?['arguments'] as Map? ?? const {},
      );
}

/// A parse/validation failure with a useful document path.
class JuiFormatException implements Exception {
  const JuiFormatException(this.message, {this.path = r'$'});

  final String message;
  final String path;

  @override
  String toString() => 'JuiFormatException at $path: $message';
}
