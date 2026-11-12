import 'dart:convert';

import 'document.dart';

/// Strict JSON-based JUI v1 parser. Scripts are data, never executable code.
class JuiParser {
  const JuiParser({
    this.maxDocumentBytes = 256 * 1024,
    this.maxDepth = 32,
    this.maxNodes = 2000,
  });

  final int maxDocumentBytes;
  final int maxDepth;
  final int maxNodes;

  static const _rootKeys = {'schemaVersion', 'screen', 'root'};
  static const _containerTypes = {'column', 'row', 'padding'};
  static const _leafTypes = {'text', 'button', 'spacer'};
  static const supportedTypes = {..._containerTypes, ..._leafTypes};

  JuiDocument parse(String source) {
    if (utf8.encode(source).length > maxDocumentBytes) {
      throw const JuiFormatException('Document exceeds the size limit');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw JuiFormatException('Invalid JSON: ${error.message}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const JuiFormatException('Document root must be an object');
    }
    _rejectUnknownKeys(decoded, _rootKeys, r'$');

    final version = decoded['schemaVersion'];
    if (version != 1) {
      throw JuiFormatException('Unsupported schemaVersion: $version');
    }
    final screen = decoded['screen'];
    if (screen is! String || screen.isEmpty || screen.length > 80) {
      throw const JuiFormatException(
        'screen must be a non-empty string (max 80 chars)',
        path: r'$.screen',
      );
    }
    var count = 0;
    final root = _parseNode(decoded['root'], r'$.root', 0, () => ++count);
    return JuiDocument(schemaVersion: 1, screenId: screen, root: root);
  }

  JuiNode _parseNode(
    Object? value,
    String path,
    int depth,
    int Function() nextCount,
  ) {
    if (depth > maxDepth) {
      throw JuiFormatException('Maximum nesting depth exceeded', path: path);
    }
    if (nextCount() > maxNodes) {
      throw JuiFormatException('Maximum node count exceeded', path: path);
    }
    if (value is! Map<String, dynamic>) {
      throw JuiFormatException('Node must be an object', path: path);
    }
    final type = value['type'];
    if (type is! String || !supportedTypes.contains(type)) {
      throw JuiFormatException(
        'Unknown or missing node type: $type',
        path: '$path.type',
      );
    }
    final allowedKeys = switch (type) {
      'column' || 'row' || 'padding' => {'type', 'children'},
      'text' => {'type', 'text', 'binding', 'fontSize'},
      'button' => {'type', 'text', 'action'},
      'spacer' => {'type'},
      _ => {'type'},
    };
    _rejectUnknownKeys(value, allowedKeys, path);

    final text = value['text'];
    final binding = value['binding'];
    if (type == 'text') {
      final hasLiteral = text is String;
      final hasBinding = binding is String;
      if (hasLiteral == hasBinding) {
        throw JuiFormatException(
          'text requires exactly one of text or binding',
          path: path,
        );
      }
      if (hasBinding &&
          !RegExp(
            r'^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*$',
          ).hasMatch(binding)) {
        throw JuiFormatException(
          'Invalid binding path',
          path: '$path.binding',
        );
      }
    } else if (type == 'button' && text is! String) {
      throw JuiFormatException(
        'button requires a text string',
        path: '$path.text',
      );
    }
    if (text is String && text.length > 4000) {
      throw JuiFormatException(
        'Text exceeds 4000 characters',
        path: '$path.text',
      );
    }
    final fontSize = value['fontSize'];
    if (fontSize != null &&
        (fontSize is! num || fontSize < 8 || fontSize > 72)) {
      throw JuiFormatException(
        'fontSize must be between 8 and 72',
        path: '$path.fontSize',
      );
    }

    final rawChildren = value['children'] ?? const [];
    if (rawChildren is! List) {
      throw JuiFormatException(
        'children must be an array',
        path: '$path.children',
      );
    }
    if (_leafTypes.contains(type) && rawChildren.isNotEmpty) {
      throw JuiFormatException(
        '$type cannot have children',
        path: '$path.children',
      );
    }
    if (type == 'padding' && rawChildren.length != 1) {
      throw JuiFormatException(
        'padding requires exactly one child',
        path: '$path.children',
      );
    }
    if (_containerTypes.contains(type) && rawChildren.length > 200) {
      throw JuiFormatException(
        'Container has too many children',
        path: '$path.children',
      );
    }

    final rawAction = value['action'];
    final Map<String, Object?> properties = {'type': type};
    if (text is String) {
      properties['text'] = text;
    }
    if (binding is String) {
      properties['binding'] = binding;
    }
    if (fontSize is num) {
      properties['fontSize'] = fontSize;
    }
    if (type == 'button') {
      if (rawAction is! Map<String, dynamic>) {
        throw JuiFormatException(
          'button requires an action object',
          path: '$path.action',
        );
      }
      _rejectUnknownKeys(rawAction, {'id', 'arguments'}, '$path.action');
      final id = rawAction['id'];
      final args = rawAction['arguments'] ?? const <String, dynamic>{};
      if (id is! String || !RegExp(r'^[a-z][a-z0-9_.-]{0,79}$').hasMatch(id)) {
        throw JuiFormatException(
          'Invalid action id',
          path: '$path.action.id',
        );
      }
      if (args is! Map<String, dynamic>) {
        throw JuiFormatException(
          'arguments must be an object',
          path: '$path.action.arguments',
        );
      }
      final frozenArguments = _freezeJsonValue(
        args,
        '$path.action.arguments',
        depth + 1,
        nextCount,
      ) as Map<String, Object?>;
      properties['action'] = {
        'id': id,
        'arguments': frozenArguments,
      };
    } else if (rawAction != null) {
      throw JuiFormatException(
        'Only button nodes may declare actions',
        path: '$path.action',
      );
    }

    final children = <JuiNode>[];
    for (var i = 0; i < rawChildren.length; i++) {
      children.add(
        _parseNode(rawChildren[i], '$path.children[$i]', depth + 1, nextCount),
      );
    }
    return JuiNode(type: type, properties: properties, children: children);
  }

  Object? _freezeJsonValue(
    Object? value,
    String path,
    int depth,
    int Function() nextCount,
  ) {
    if (depth > maxDepth) {
      throw JuiFormatException(
        'Maximum nesting depth exceeded',
        path: path,
      );
    }
    if (nextCount() > maxNodes) {
      throw JuiFormatException('Maximum node count exceeded', path: path);
    }
    if (value is Map<String, dynamic>) {
      final frozen = <String, Object?>{};
      for (final entry in value.entries) {
        frozen[entry.key] = _freezeJsonValue(
          entry.value,
          '$path.${entry.key}',
          depth + 1,
          nextCount,
        );
      }
      return Map<String, Object?>.unmodifiable(frozen);
    }
    if (value is List) {
      return List<Object?>.unmodifiable([
        for (var i = 0; i < value.length; i++)
          _freezeJsonValue(value[i], '$path[$i]', depth + 1, nextCount),
      ]);
    }
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    throw JuiFormatException('Unsupported JSON value', path: path);
  }

  void _rejectUnknownKeys(
    Map<String, dynamic> value,
    Set<String> allowed,
    String path,
  ) {
    final unknown = value.keys.where((key) => !allowed.contains(key));
    if (unknown.isNotEmpty) {
      throw JuiFormatException(
        'Unknown field: ${unknown.first}',
        path: path,
      );
    }
  }
}
).hasMatch(id)) {
        throw JuiFormatException(
          'Invalid action id',
          path: '$path.action.id',
        );
      }
      if (args is! Map<String, dynamic>) {
        throw JuiFormatException(
          'arguments must be an object',
          path: '$path.action.arguments',
        );
      }
      final frozenArguments = _freezeJsonValue(
        args,
        '$path.action.arguments',
        depth + 1,
        nextCount,
      ) as Map<String, Object?>;
      properties['action'] = {
        'id': id,
        'arguments': frozenArguments,
      };
    } else if (rawAction != null) {
      throw JuiFormatException(
        'Only button nodes may declare actions',
        path: '$path.action',
      );
    }

    final children = <JuiNode>[];
    for (var i = 0; i < rawChildren.length; i++) {
      children.add(
        _parseNode(rawChildren[i], '$path.children[$i]', depth + 1, nextCount),
      );
    }
    return JuiNode(type: type, properties: properties, children: children);
  }

  Object? _freezeJsonValue(
    Object? value,
    String path,
    int depth,
    int Function() nextCount,
  ) {
    if (depth > maxDepth) {
      throw JuiFormatException(
        'Maximum nesting depth exceeded',
        path: path,
      );
    }
    if (nextCount() > maxNodes) {
      throw JuiFormatException('Maximum node count exceeded', path: path);
    }
    if (value is Map<String, dynamic>) {
      final frozen = <String, Object?>{};
      for (final entry in value.entries) {
        frozen[entry.key] = _freezeJsonValue(
          entry.value,
          '$path.${entry.key}',
          depth + 1,
          nextCount,
        );
      }
      return Map<String, Object?>.unmodifiable(frozen);
    }
    if (value is List) {
      return List<Object?>.unmodifiable([
        for (var i = 0; i < value.length; i++)
          _freezeJsonValue(value[i], '$path[$i]', depth + 1, nextCount),
      ]);
    }
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    throw JuiFormatException('Unsupported JSON value', path: path);
  }

  void _rejectUnknownKeys(
    Map<String, dynamic> value,
    Set<String> allowed,
    String path,
  ) {
    final unknown = value.keys.where((key) => !allowed.contains(key));
    if (unknown.isNotEmpty) {
      throw JuiFormatException(
        'Unknown field: ${unknown.first}',
        path: path,
      );
    }
  }
}
