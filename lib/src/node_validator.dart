/// @docImport 'package:sanitize_dom/src/node_validator_builder.dart';
library;

import 'package:sanitize_dom/src/node_validators/html5_node_validator.dart';
import 'package:sanitize_dom/src/node_validators/throws_node_validator.dart';
import 'package:sanitize_dom/src/url_policy.dart';
import 'package:web/web.dart';

/// Interface used to validate that only accepted elements and attributes are
/// allowed while parsing HTML strings into DOM nodes.
///
/// In general, customization of validation behavior should be done via the
/// [NodeValidatorBuilder] class to mitigate the chances of incorrectly
/// implementing validation rules.
abstract interface class NodeValidator {
  /// Construct a default NodeValidator which only accepts whitelisted HTML5
  /// elements and attributes.
  ///
  /// If a uriPolicy is not specified then the default uriPolicy will be used.
  factory NodeValidator({UriPolicy? uriPolicy}) = HTML5NodeValidator;

  factory NodeValidator.throws(NodeValidator base) = ThrowsNodeValidator;

  /// Returns true if the tagName is an accepted type.
  bool allowsElement(Element element);

  /// Returns true if the attribute is allowed.
  ///
  /// The attributeName parameter will always be in lowercase.
  ///
  /// See [allowsElement] for format of tagName.
  bool allowsAttribute(Element element, String attributeName, String value);
}
