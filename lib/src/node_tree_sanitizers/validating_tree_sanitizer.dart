// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This code was extracted from the deprecated `dart:html` package of the Dart
// SDK and migrated to the `web` package.

import 'dart:js_interop';

import 'package:meta/meta.dart';
import 'package:sanitize_dom/src/constants.dart';
import 'package:sanitize_dom/src/node_tree_sanitizer.dart';
import 'package:sanitize_dom/src/node_validator.dart';
import 'package:sanitize_dom/src/utilities.dart';
import 'package:web/web.dart';

/// Standard tree sanitizer which validates a node tree against the provided
/// validator and removes any nodes or attributes which are not allowed.
base class ValidatingTreeSanitizer implements NodeTreeSanitizer {
  ValidatingTreeSanitizer(this.validator);

  final NodeValidator validator;

  /// Number of tree modifications this instance has made.
  int treeModificationsCount = 0;

  @override
  void sanitizeTree(Node node) {
    void walk(Node node, Node? parent) {
      sanitizeNode(node, parent);

      Node? child = node.lastChild;

      while (null != child) {
        Node? nextChild;

        try {
          // Child may be removed during the walk, and we may not even be able
          // to get its previousNode. But it's also possible that previousNode
          // (i.e. previousSibling) is being spoofed, so double-check it.
          nextChild = child.previousSibling;

          if (nextChild != null && nextChild.nextSibling != child) {
            throw StateError('Corrupt HTML');
          }
        } catch (error) {
          // Child appears bad, remove it. We want to check the rest of the
          // children of node and, but we have no way of getting to the next
          // child, so start again from the last child.
          removeNode(child, node);
          child = null;
          nextChild = node.lastChild;
        }

        if (child != null) {
          walk(child, node);
        }

        child = nextChild;
      }
    }

    // Walk the tree until no new modifications are added to the tree.
    int previousTreeModificationsCount;

    do {
      previousTreeModificationsCount = treeModificationsCount;
      walk(node, null);
    } while (previousTreeModificationsCount != treeModificationsCount);
  }

  /// Aggressively try to remove node.
  @internal
  void removeNode(Node node, Node? parent) {
    // If we have the parent, it's presumably already passed more sanitization
    // or is the fragment, so ask it to remove the child. And if that fails
    // try to set the outer html.
    treeModificationsCount++;

    if (parent == null || parent != node.parentNode) {
      // Casting to Element to reuse ChilldNode.remove() which also included in
      // Comment and Text.
      node.parentNode?.removeChild(node);
    } else {
      parent.removeChild(node);
    }
  }

  /// Sanitize the element, assuming we can't trust anything about it.
  @internal
  void sanitizeUntrustedElement(Element element, Node? parent) {
    // If the hasCorruptedAttributes does not successfully return false,
    // then we consider it corrupted and remove.
    // TODO(alanknight): This is a workaround because on Firefox
    //  embed/object tags typeof is "function", not "object". We don't recognize
    //  them, and can't call methods. This does mean that you can't explicitly
    //  allow an embed tag. The only thing that will let it through is a null
    //  sanitizer that doesn't traverse the tree at all. But sanitizing while
    //  allowing embeds seems quite unlikely. This is also the reason that we
    //  can't declare the type of element, as an embed won't pass any type
    //  check in dart2js.
    bool corrupted = true;
    String? isAttribute;

    try {
      // If getting/indexing attributes throws, count that as corrupt.
      // attributes = element.attributes;

      isAttribute = element.getAttribute('is');
      corrupted = hasCorruptedAttributes(element);

      // On IE, erratically, the hasCorruptedAttributes test can return false,
      // even though it clearly is corrupted. A separate copy of the test
      // inlining just the basic check seems to help.
      if (!corrupted) {
        corrupted = hasCorruptedAttributesAdditionalCheck(element);
      }
    } catch (_) {}

    String elementText = 'element unprintable';

    try {
      elementText = element.localName;
    } catch (_) {}

    try {
      String elementTagName = safeTagName(element);

      sanitizeElement(
        element,
        parent,
        corrupted,
        elementText,
        elementTagName,
        isAttribute,
      );
    } on ArgumentError {
      // Thrown by ThrowsNodeValidator
      rethrow;
    } catch (_) {
      // Unexpected exception sanitizing -> remove
      removeNode(element, parent);

      if (assertionsEnabled || warnOnRemove) {
        // ignore: avoid_print
        print('Removing corrupted element $elementText');
      }
    }
  }

  /// Having done basic sanity checking on the element, and computed the
  /// important attributes we want to check, remove it if it's not valid
  /// or not allowed, either as a whole or particular attributes.
  @internal
  void sanitizeElement(
    Element element,
    Node? parent,
    bool corrupted,
    String text,
    String tag,
    String? isAttribute,
  ) {
    if (false != corrupted) {
      removeNode(element, parent);

      if (assertionsEnabled || warnOnRemove) {
        // ignore: avoid_print
        print('Removing element due to corrupted attributes on <$text>');
      }

      return;
    }

    if (!validator.allowsElement(element)) {
      removeNode(element, parent);

      if (assertionsEnabled || warnOnRemove) {
        // ignore: avoid_print
        print('Removing disallowed element <$tag> from $parent');
      }

      return;
    }

    if (isAttribute != null) {
      if (!validator.allowsAttribute(element, 'is', isAttribute)) {
        removeNode(element, parent);

        if (assertionsEnabled || warnOnRemove) {
          // ignore: avoid_print
          print('Removing disallowed type extension <$tag is="$isAttribute">');
        }

        return;
      }
    }

    // TODO(blois): Need to be able to get all attributes, irrespective of
    //  XMLNS.
    NamedNodeMap attributes = element.attributes;

    for (int i = attributes.length - 1; i >= 0; --i) {
      Attr attribute = attributes.item(i)!;
      String name = attribute.name;
      String value = attribute.value;

      if (!validator.allowsAttribute(element, name.toLowerCase(), value)) {
        if (assertionsEnabled || warnOnRemove) {
          // ignore: avoid_print
          print('Removing disallowed attribute <$tag $name="$value">');
        }

        attributes.removeNamedItem(name);
      }
    }

    if (element.isA<HTMLTemplateElement>()) {
      HTMLTemplateElement template = element as HTMLTemplateElement;
      sanitizeTree(template.content);
    }
  }

  /// Sanitize the node and its children recursively.
  void sanitizeNode(Node node, Node? parent) {
    switch (node.nodeType) {
      case Node.ELEMENT_NODE:
        sanitizeUntrustedElement(node as Element, parent);
        break;

      case Node.COMMENT_NODE:
      case Node.DOCUMENT_FRAGMENT_NODE:
      case Node.TEXT_NODE:
      case Node.CDATA_SECTION_NODE:
        break;

      default:
        removeNode(node, parent);
    }
  }
}
