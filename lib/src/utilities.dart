import 'dart:js_interop';

import 'package:web/web.dart';

const bool assertionsEnabled =
    bool.fromEnvironment('dart.web.assertions_enabled');

@JS('Function')
external JSFunction createFunction1(String argumentName, String body);

final JSFunction hasCorruptedAttributesJS = createFunction1('element', '''
  if (!(element.attributes instanceof NamedNodeMap)) {
    return true;
  }

  // If something has corrupted the traversal we want to detect
  // these on not only the children (tested below) but on the node itself
  // in case it was bypassed.
  if (element["id"] == 'lastChild' || element["name"] == 'lastChild' ||
      element["id"] == 'previousSibling' || element["name"] == 'previousSibling' ||
      element["id"] == 'children' || element["name"] == 'children') {
    return true;
  }

  var childNodes = element.childNodes;

  if (element.lastChild && element.lastChild !== childNodes[childNodes.length -1]) {
    return true;
  }

  // On Safari, children can apparently be null.
  if (element.children) {
    if (!((element.children instanceof HTMLCollection) ||
          (element.children instanceof NodeList))) {
      return true;
    }
  }

  var length = 0;

  if (element.children) {
    length = element.children.length;
  }

  for (let i = 0; i < length; i++) {
    var child = element.children[i];

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
  JSBoolean result = hasCorruptedAttributesJS.callAsFunction(
    null,
    element,
  ) as JSBoolean;

  return result.toDart;
}

final JSFunction hasCorruptedAttributesAdditionalCheckJS =
    createFunction1('element', '''
  return !(element.attributes instanceof NamedNodeMap)''');

/// A secondary check for corruption, needed on IE
bool hasCorruptedAttributesAdditionalCheck(Element element) {
  JSBoolean result = hasCorruptedAttributesAdditionalCheckJS.callAsFunction(
    null,
    element,
  ) as JSBoolean;

  return result.toDart;
}

final JSFunction safeTagNameJS = createFunction1('element', '''
  var result = 'element tag unavailable';

  try {
    if (typeof element.tagName === 'string') {
      result = element.tagName;
    }
  } catch (error) {}

  return result;''');

/// A secondary check for corruption, needed on IE
String safeTagName(Element element) {
  JSString result = hasCorruptedAttributesAdditionalCheckJS.callAsFunction(
    null,
    element,
  ) as JSString;

  return result.toDart;
}
