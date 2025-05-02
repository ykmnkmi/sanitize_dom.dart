// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This code was extracted from the deprecated `dart:html` package of the Dart
// SDK and migrated to the `web` package.

import 'dart:js_interop';

import 'package:web/web.dart';

const bool assertionsEnabled =
    bool.fromEnvironment('dart.web.assertions_enabled');

@JS('Function')
external JSFunction createFunction0(String body);

final JSFunction hasCorruptedAttributesJS = createFunction0('''
  if (!(this.attributes instanceof NamedNodeMap)) {
    return true;
  }

  // If something has corrupted the traversal we want to detect
  // these on not only the children (tested below) but on the node itself
  // in case it was bypassed.
  if (this["id"] == 'lastChild' || this["name"] == 'lastChild' ||
      this["id"] == 'previousSibling' || this["name"] == 'previousSibling' ||
      this["id"] == 'children' || this["name"] == 'children') {
    return true;
  }

  var childNodes = this.childNodes;

  if (this.lastChild && this.lastChild !== childNodes[childNodes.length -1]) {
    return true;
  }

  // On Safari, children can apparently be null.
  if (this.children) {
    if (!((this.children instanceof HTMLCollection) ||
          (this.children instanceof NodeList))) {
      return true;
    }
  }

  var length = 0;

  if (this.children) {
    length = this.children.length;
  }

  for (let i = 0; i < length; i++) {
    var child = this.children[i];

    // On IE it seems like we sometimes don't see the clobbered attribute,
    // perhaps as a result of an over-optimization. Also use another route
    // to check of attributes, children, or lastChild are clobbered. It may
    // seem silly to check children as we rely on children to do this iteration,
    // but it seems possible that the access to children might see the real thing,
    // allowing us to check for clobbering that may show up in other accesses.
    if (child["id"] == 'attributes' || child["name"] == 'attributes' ||
        child["id"] == 'lastChild'  || child["name"] == 'lastChild' ||
        child["id"] == 'previousSibling'  || child["name"] == 'previousSibling' ||
        child["id"] == 'children' || child["name"] == 'children') {
      return true;
    }
  }

  return false;''');

/// Verify if any of the attributes that we use in the sanitizer look unexpected,
/// possibly indicating DOM clobbering attacks.
///
/// Those attributes are: attributes, lastChild, children, previousNode and tagName.
bool hasCorruptedAttributes(Element element) {
  JSBoolean result =
      hasCorruptedAttributesJS.callAsFunction(element) as JSBoolean;
  return result.toDart;
}

final JSFunction hasCorruptedAttributesAdditionalCheckJS = createFunction0('''
  return !(this.attributes instanceof NamedNodeMap)''');

/// A secondary check for corruption, needed on IE
bool hasCorruptedAttributesAdditionalCheck(Element element) {
  JSBoolean result = hasCorruptedAttributesAdditionalCheckJS
      .callAsFunction(element) as JSBoolean;
  return result.toDart;
}

final JSFunction safeTagNameJS = createFunction0('''
  var result = 'element tag unavailable';

  try {
    if (typeof this.tagName === 'string') {
      result = this.tagName;
    }
  } catch (error) {}

  return result;''');

/// A secondary check for corruption, needed on IE
String safeTagName(Element element) {
  JSString result = safeTagNameJS.callAsFunction(element) as JSString;
  return result.toDart;
}
