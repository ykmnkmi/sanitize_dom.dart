// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This code was extracted from the deprecated `dart:html` package of the Dart
// SDK and migrated to the `web` package.

import 'package:meta/meta.dart';
import 'package:sanitize_dom/src/node_validators/simple_node_validator.dart';
import 'package:web/web.dart';

base class TemplatingNodeValidator extends SimpleNodeValidator {
  static const allowedTemplateAttibutes = <String>[
    'bind',
    'if',
    'ref',
    'repeat',
    'syntax',
  ];

  TemplatingNodeValidator()
      : templateAttributes = Set<String>.from(allowedTemplateAttibutes),
        super(
          null,
          allowedElements: const <String>['TEMPLATE'],
          allowedAttributes: allowedTemplateAttibutes.map(
            (attribute) => 'TEMPLATE::$attribute',
          ),
        );

  @internal
  final Set<String> templateAttributes;

  @override
  bool allowsAttribute(Element element, String attributeName, String value) {
    if (super.allowsAttribute(element, attributeName, value)) {
      return true;
    }

    if (attributeName == 'template' && value == '') {
      return true;
    }

    if (element.getAttribute('template') == '') {
      return templateAttributes.contains(attributeName);
    }

    return false;
  }
}
