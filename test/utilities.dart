// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This code was extracted from the HTML tests of the Dart SDK and migrated
// to the `web` package.

import 'dart:js_interop';

import 'package:test/expect.dart';
import 'package:web/web.dart';

void validateNodeTree(Node a, Node b, [String path = '']) {
  path = '$path${a.runtimeType}';

  expect(a.nodeType, equals(b.nodeType), reason: '$path nodeTypes differ');
  expect(a.nodeValue, equals(b.nodeValue), reason: '$path nodeValues differ');
  expect(a.textContent, equals(b.textContent),
      reason: '$path textContents differ');
  expect(a.childNodes.length, equals(b.childNodes.length),
      reason: '$path childNodes.length differ');

  if (a.isA<Element>()) {
    a as Element;
    b as Element;

    expect(a.tagName, equals(b.tagName), reason: '$path tagNames differ');
    expect(a.attributes.length, equals(b.attributes.length),
        reason: '$path attributes.length differ');

    NamedNodeMap attributes = a.attributes;

    for (int i = 0; i < attributes.length; i++) {
      Attr attribute = attributes.item(i)!;
      expect(attribute.value, b.getAttribute(attribute.name),
          reason: '$path attribute ${attribute.name} values differ');
    }
  }

  for (int i = 0; i < a.childNodes.length; i++) {
    validateNodeTree(a.childNodes.item(i)!, b.childNodes.item(i)!);
  }
}
