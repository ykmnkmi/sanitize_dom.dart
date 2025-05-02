// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This code was extracted from the deprecated `dart:html` package of the Dart
// SDK and migrated to the `web` package.

import 'package:sanitize_dom/src/node_validator.dart';
import 'package:sanitize_dom/src/utilities.dart';
import 'package:web/web.dart';

base class ThrowsNodeValidator implements NodeValidator {
  ThrowsNodeValidator(this.validator);

  final NodeValidator validator;

  @override
  bool allowsElement(Element element) {
    if (validator.allowsElement(element)) {
      return true;
    }

    throw ArgumentError(safeTagName(element));
  }

  @override
  bool allowsAttribute(Element element, String attributeName, String value) {
    if (validator.allowsAttribute(element, attributeName, value)) {
      return true;
    }

    throw ArgumentError('${safeTagName(element)}[$attributeName="$value"]');
  }
}
