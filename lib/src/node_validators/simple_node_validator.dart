// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This code was extracted from the deprecated `dart:html` package of the Dart
// SDK and migrated to the `web` package.

import 'package:sanitize_dom/src/node_validator.dart';
import 'package:sanitize_dom/src/node_validators/html5_node_validator.dart';
import 'package:sanitize_dom/src/url_policy.dart';
import 'package:sanitize_dom/src/utilities.dart';
import 'package:web/web.dart';

base class SimpleNodeValidator implements NodeValidator {
  factory SimpleNodeValidator.allowNavigation(UriPolicy uriPolicy) {
    return SimpleNodeValidator(
      uriPolicy,
      allowedElements: const <String>['A', 'FORM'],
      allowedAttributes: const <String>[
        'A::accesskey',
        'A::coords',
        'A::hreflang',
        'A::name',
        'A::shape',
        'A::tabindex',
        'A::target',
        'A::type',
        'FORM::accept',
        'FORM::autocomplete',
        'FORM::enctype',
        'FORM::method',
        'FORM::name',
        'FORM::novalidate',
        'FORM::target',
      ],
      allowedUriAttributes: const <String>['A::href', 'FORM::action'],
    );
  }

  factory SimpleNodeValidator.allowImages(UriPolicy uriPolicy) {
    return SimpleNodeValidator(
      uriPolicy,
      allowedElements: const <String>['IMG'],
      allowedAttributes: const <String>[
        'IMG::align',
        'IMG::alt',
        'IMG::border',
        'IMG::height',
        'IMG::hspace',
        'IMG::ismap',
        'IMG::name',
        'IMG::usemap',
        'IMG::vspace',
        'IMG::width',
      ],
      allowedUriAttributes: const <String>['IMG::src'],
    );
  }

  factory SimpleNodeValidator.allowTextElements() {
    return SimpleNodeValidator(
      null,
      allowedElements: const <String>[
        'B',
        'BLOCKQUOTE',
        'BR',
        'EM',
        'H1',
        'H2',
        'H3',
        'H4',
        'H5',
        'H6',
        'HR',
        'I',
        'LI',
        'OL',
        'P',
        'SPAN',
        'UL',
      ],
    );
  }

  /// Elements must be uppercased tag names. For example `'IMG'`.
  /// Attributes must be uppercased tag name followed by :: followed by
  /// lowercase attribute name. For example `'IMG:src'`.
  SimpleNodeValidator(
    this.uriPolicy, {
    Iterable<String>? allowedElements,
    Iterable<String>? allowedAttributes,
    Iterable<String>? allowedUriAttributes,
  }) {
    this.allowedElements.addAll(allowedElements ?? const <String>[]);
    allowedAttributes = allowedAttributes ?? const <String>[];
    allowedUriAttributes = allowedUriAttributes ?? const <String>[];

    Iterable<String> legalAttributes = allowedAttributes.where(
      (allowedAttribute) => !HTML5NodeValidator.uriAttributes.contains(
        allowedAttribute,
      ),
    );

    Iterable<String> extraUriAttributes = allowedAttributes.where(
      HTML5NodeValidator.uriAttributes.contains,
    );

    this.allowedAttributes.addAll(legalAttributes);
    this.allowedUriAttributes.addAll(allowedUriAttributes);
    this.allowedUriAttributes.addAll(extraUriAttributes);
  }

  final Set<String> allowedElements = <String>{};

  final Set<String> allowedAttributes = <String>{};

  final Set<String> allowedUriAttributes = <String>{};

  final UriPolicy? uriPolicy;

  @override
  bool allowsElement(Element element) {
    return allowedElements.contains(safeTagName(element));
  }

  @override
  bool allowsAttribute(Element element, String attributeName, String value) {
    String tagName = safeTagName(element);

    if (allowedUriAttributes.contains('$tagName::$attributeName')) {
      return uriPolicy!.allowsUri(value);
    }

    if (allowedUriAttributes.contains('*::$attributeName')) {
      return uriPolicy!.allowsUri(value);
    }

    if (allowedAttributes.contains('$tagName::$attributeName')) {
      return true;
    }

    if (allowedAttributes.contains('*::$attributeName')) {
      return true;
    }

    if (allowedAttributes.contains('$tagName::*')) {
      return true;
    }

    if (allowedAttributes.contains('*::*')) {
      return true;
    }

    return false;
  }
}
