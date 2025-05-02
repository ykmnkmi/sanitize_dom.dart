// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This code was extracted from the deprecated `dart:html` package of the Dart
// SDK and migrated to the `web` package.

import 'package:sanitize_dom/src/node_validators/simple_node_validator.dart';
import 'package:sanitize_dom/src/url_policy.dart';
import 'package:sanitize_dom/src/utilities.dart';
import 'package:web/web.dart';

base class CustomElementNodeValidator extends SimpleNodeValidator {
  CustomElementNodeValidator(
    UriPolicy super.uriPolicy,
    Iterable<String> allowedElements,
    Iterable<String>? allowedAttributes,
    Iterable<String>? allowedUriAttributes,
    bool allowTypeExtension,
    bool allowCustomTag,
  )   : allowTypeExtension = allowTypeExtension == true,
        allowCustomTag = allowCustomTag == true,
        super(
          allowedElements: allowedElements,
          allowedAttributes: allowedAttributes,
          allowedUriAttributes: allowedUriAttributes,
        );

  final bool allowTypeExtension;

  final bool allowCustomTag;

  @override
  bool allowsElement(Element element) {
    if (allowTypeExtension) {
      String? isAttribute = element.getAttribute('is');

      if (isAttribute != null) {
        return allowedElements.contains(isAttribute.toUpperCase()) &&
            allowedElements.contains(safeTagName(element));
      }
    }

    return allowCustomTag && allowedElements.contains(safeTagName(element));
  }

  @override
  bool allowsAttribute(Element element, String attributeName, String value) {
    if (allowsElement(element)) {
      if (allowTypeExtension &&
          attributeName == 'is' &&
          allowedElements.contains(value.toUpperCase())) {
        return true;
      }

      return super.allowsAttribute(element, attributeName, value);
    }

    return false;
  }
}
