// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:sanitize_dom/sanitize_dom.dart';
import 'package:test/test.dart';
import 'package:web/web.dart';

JSAny? oldAdoptNode;

/// We want to verify that with the trusted sanitizer we are not
/// creating a document fragment. So make DocumentFragment operation
/// throw.
void makeDocumentFragmentAdoptionThrow() {
  oldAdoptNode = document.getProperty('adoptNode'.toJS);
  document.setProperty('adoptNode'.toJS, null);
}

void restoreOldAdoptNode() {
  document.setProperty('adoptNode'.toJS, oldAdoptNode);
}

void main() {
  group('not_create_document_fragment', () {
    setUp(makeDocumentFragmentAdoptionThrow);
    tearDown(restoreOldAdoptNode);

    test('setInnerHTMLSafe', () {
      document.body!.setInnerHtml('<div foo="baz">something</div>',
          treeSanitizer: NodeTreeSanitizer.trusted);
    });

    test('appendHTMLSafe', () {
      String oldStuff = document.body!.innerHtml;
      String newStuff = '<div rumplestiltskin="value">content</div>';

      document.body!
          .appendHtml(newStuff, treeSanitizer: NodeTreeSanitizer.trusted);

      expect(document.body!.innerHtml, oldStuff + newStuff);
    });
  });

  group('untrusted', () {
    setUp(makeDocumentFragmentAdoptionThrow);
    tearDown(restoreOldAdoptNode);

    test('untrusted', () {
      expect(() => document.body!.innerHtml = '<p>anything</p>',
          throwsA(anything));
    });
  });
}
