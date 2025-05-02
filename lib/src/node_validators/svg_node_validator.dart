// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This code was extracted from the deprecated `dart:html` package of the Dart
// SDK and migrated to the `web` package.

import 'dart:js_interop';

import 'package:sanitize_dom/src/node_validator.dart';
import 'package:sanitize_dom/src/utilities.dart';
import 'package:web/web.dart';

class SVGNodeValidator implements NodeValidator {
  @override
  bool allowsElement(Element element) {
    if (element.isA<SVGScriptElement>()) {
      return false;
    }

    // Firefox 37 has issues with creating foreign elements inside a
    // foreignobject tag as SvgElement. We don't want foreignobject contents
    // anyway, so just remove the whole tree outright. And we can't rely
    // on IE recognizing the SvgForeignObject type, so go by tagName. Bug 23144
    if (element.isA<SVGElement>()) {
      if (safeTagName(element) == 'foreignObject') {
        return false;
      }

      return true;
    }

    return false;
  }

  @override
  bool allowsAttribute(Element element, String attributeName, String value) {
    if (attributeName == 'is' || attributeName.startsWith('on')) {
      return false;
    }

    return allowsElement(element);
  }
}
