// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This code was extracted from the deprecated `dart:html` package of the Dart
// SDK and migrated to the `web` package.

import 'package:sanitize_dom/src/node_tree_sanitizers/trusted_html_tree_sanitizer.dart';
import 'package:sanitize_dom/src/node_tree_sanitizers/validating_tree_sanitizer.dart';
import 'package:sanitize_dom/src/node_validator.dart';
import 'package:web/web.dart';

/// Performs sanitization of a node tree after construction to ensure that it
/// does not contain any disallowed elements or attributes.
///
/// In general custom implementations of this class should not be necessary and
/// all validation customization should be done in custom NodeValidators, but
/// custom implementations of this class can be created to perform more complex
/// tree sanitization.
abstract interface class NodeTreeSanitizer {
  /// Constructs a default tree sanitizer which will remove all elements and
  /// attributes which are not allowed by the provided validator.
  factory NodeTreeSanitizer(NodeValidator validator) {
    return ValidatingTreeSanitizer(validator);
  }

  /// Called with the root of the tree which is to be sanitized.
  ///
  /// This method needs to walk the entire tree and either remove elements and
  /// attributes which are not recognized as safe or throw an exception which
  /// will mark the entire tree as unsafe.
  void sanitizeTree(Node node);

  /// A sanitizer for trees that we trust. It does no validation and allows
  /// any elements. It is also more efficient, since it can pass the text
  /// directly through to the underlying APIs without creating a document
  /// fragment to be sanitized.
  static const NodeTreeSanitizer trusted = TrustedHTMLTreeSanitizer();
}
