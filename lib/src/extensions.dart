// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This code was extracted from the deprecated `dart:html` package of the Dart
// SDK and migrated to the `web` package.

import 'dart:js_interop';

import 'package:sanitize_dom/src/node_tree_sanitizer.dart';
import 'package:sanitize_dom/src/node_tree_sanitizers/trusted_html_tree_sanitizer.dart';
import 'package:sanitize_dom/src/node_tree_sanitizers/validating_tree_sanitizer.dart';
import 'package:sanitize_dom/src/node_validator.dart';
import 'package:sanitize_dom/src/node_validator_builder.dart';
import 'package:web/web.dart';

/// A hard-coded list of the tag names for which createContextualFragment
/// isn't supported.
const Set<String> _tagsForWhichCreateContextualFragmentIsNotSupported =
    <String>{
  'HEAD',
  'AREA',
  'BASE',
  'BASEFONT',
  'BR',
  'COL',
  'COLGROUP',
  'EMBED',
  'FRAME',
  'FRAMESET',
  'HR',
  'IMAGE',
  'IMG',
  'INPUT',
  'ISINDEX',
  'LINK',
  'META',
  'PARAM',
  'SOURCE',
  'STYLE',
  'TITLE',
  'WBR',
};

Document? _parseDocument;
Range? _parseRange;

extension SafeElement on Element {
  @JS('innerHTML')
  external String get innerHtml;

  set innerHtml(String html) {
    setInnerHtml(html);
  }

  void appendHtml(
    String text, {
    NodeValidator? validator,
    NodeTreeSanitizer? treeSanitizer,
  }) {
    insertAdjacentHtml('beforeend', text,
        validator: validator, treeSanitizer: treeSanitizer);
  }

  DocumentFragment createFragment(
    String html, {
    NodeValidator? validator,
    NodeTreeSanitizer? treeSanitizer,
  }) {
    if (treeSanitizer == null) {
      validator ??= NodeValidatorBuilder.common();
      treeSanitizer = ValidatingTreeSanitizer(validator);
    } else if (validator != null) {
      throw ArgumentError(
          'validator can only be oassed if treeSanitizer is null');
    }

    // TODO(ykmnkmi): Switch to DOMParser

    Document parseDocument;
    Range parseRange;

    if (_parseDocument == null) {
      parseDocument = document.implementation.createHTMLDocument();
      _parseDocument = parseDocument;

      parseRange = parseDocument.createRange();
      _parseRange = parseRange;

      // Workaround for Safari bug. Was also previously Chrome bug 229142
      // - URIs are not resolved in new doc.
      HTMLBaseElement base =
          parseDocument.createElement('base') as HTMLBaseElement;

      base.href = document.baseURI;
      parseDocument.head!.append(base);
    } else {
      parseDocument = _parseDocument!;
      parseRange = _parseRange!;
    }

    // TODO(terry): Fixes Chromium 50 change no body after createHTMLDocument()
    HTMLElement parsedBody = parseDocument.body ??=
        parseDocument.createElement('body') as HTMLBodyElement;

    Element contextElement;

    if (isA<HTMLBodyElement>()) {
      contextElement = parsedBody;
    } else {
      contextElement = parseDocument.createElement(tagName);
      parsedBody.append(contextElement);
    }

    DocumentFragment fragment;

    if (_tagsForWhichCreateContextualFragmentIsNotSupported.contains(tagName)) {
      parseRange.selectNodeContents(contextElement);
      fragment = parseRange.createContextualFragment(html.toJS);
    } else {
      contextElement.innerHTML = html.toJS;

      fragment = parseDocument.createDocumentFragment();

      while (contextElement.firstChild != null) {
        fragment.append(contextElement.firstChild!);
      }
    }

    if (contextElement != parsedBody) {
      contextElement.remove();
    }

    treeSanitizer.sanitizeTree(fragment);
    // Copy the fragment over to the main document (fix for 14184)
    document.adoptNode(fragment);
    return fragment;
  }

  void insertAdjacentHtml(
    String where,
    String html, {
    NodeValidator? validator,
    NodeTreeSanitizer? treeSanitizer,
  }) {
    if (treeSanitizer is TrustedHTMLTreeSanitizer) {
      insertAdjacentHTML(where, html.toJS);
    } else {
      DocumentFragment fragment = createFragment(html,
          validator: validator, treeSanitizer: treeSanitizer);

      switch (where.toLowerCase()) {
        case 'beforebegin':
          parentNode!.insertBefore(fragment, this);
          break;

        case 'afterbegin':
          Node? first = childNodes.length > 0 ? firstChild : null;
          insertBefore(fragment, first);
          break;

        case 'beforeend':
          append(fragment);
          break;

        case 'afterend':
          parentNode!.insertBefore(fragment, nextSibling);
          break;

        default:
          throw ArgumentError('Invalid position $where');
      }
    }
  }

  void setInnerHtml(
    String html, {
    NodeValidator? validator,
    NodeTreeSanitizer? treeSanitizer,
  }) {
    textContent = null;

    if (treeSanitizer is TrustedHTMLTreeSanitizer) {
      innerHTML = html.toJS;
    } else {
      append(createFragment(html,
          validator: validator, treeSanitizer: treeSanitizer));
    }
  }
}

extension SafeDocumentFragment on DocumentFragment {
  String get innerHtml {
    HTMLDivElement div = document.createElement('div') as HTMLDivElement;
    div.append(cloneNode(true));
    return div.innerHtml;
  }

  set innerHtml(String value) {
    setInnerHtml(value);
  }

  void appendHtml(
    String text, {
    NodeValidator? validator,
    NodeTreeSanitizer? treeSanitizer,
  }) {
    append(document.body!.createFragment(text,
        validator: validator, treeSanitizer: treeSanitizer));
  }

  void setInnerHtml(
    String html, {
    NodeValidator? validator,
    NodeTreeSanitizer? treeSanitizer,
  }) {
    while (firstChild != null) {
      removeChild(firstChild!);
    }

    append(document.body!.createFragment(html,
        validator: validator, treeSanitizer: treeSanitizer));
  }
}

extension SafeSVGElement on SVGElement {
  DocumentFragment createFragment(
    String? svg, {
    NodeValidator? validator,
    NodeTreeSanitizer? treeSanitizer,
  }) {
    if (treeSanitizer == null) {
      validator ??= NodeValidatorBuilder.common()..allowSVG();
      treeSanitizer = NodeTreeSanitizer(validator);
    }

    // We create a fragment which will parse in the HTML parser.
    String html = '<svg version="1.1">$svg</svg>';

    DocumentFragment fragment =
        document.body!.createFragment(html, treeSanitizer: treeSanitizer);

    DocumentFragment svgFragment = DocumentFragment();

    // The root is the <svg/> element, need to pull out the contents.
    Node root = fragment.firstChild!;

    while (root.firstChild != null) {
      svgFragment.append(root.firstChild!);
    }

    return svgFragment;
  }
}

extension SafeHTMLTemplateElement on HTMLTemplateElement {
  void setInnerHtml(
    String html, {
    NodeValidator? validator,
    NodeTreeSanitizer? treeSanitizer,
  }) {
    textContent = null;

    while (firstChild != null) {
      removeChild(firstChild!);
    }

    DocumentFragment fragment = createFragment(html,
        validator: validator, treeSanitizer: treeSanitizer);

    content.append(fragment);
  }
}
