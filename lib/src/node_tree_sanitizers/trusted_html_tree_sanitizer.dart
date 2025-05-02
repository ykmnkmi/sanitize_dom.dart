// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This code was extracted from the deprecated `dart:html` package of the Dart
// SDK and migrated to the `web` package.

import 'package:sanitize_dom/src/node_tree_sanitizer.dart';
import 'package:web/web.dart';

/// A sanitizer for trees that we trust. It does no validation and allows
/// any elements.
base class TrustedHTMLTreeSanitizer implements NodeTreeSanitizer {
  const TrustedHTMLTreeSanitizer();

  @override
  void sanitizeTree(Node node) {}
}
