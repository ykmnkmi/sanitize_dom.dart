// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This code was extracted from the deprecated `dart:html` package of the Dart
// SDK and migrated to the `web` package.

import 'package:meta/meta.dart';
import 'package:sanitize_dom/src/node_validator.dart';
import 'package:sanitize_dom/src/node_validators/custom_element_node_validator.dart';
import 'package:sanitize_dom/src/node_validators/html5_node_validator.dart';
import 'package:sanitize_dom/src/node_validators/simple_node_validator.dart';
import 'package:sanitize_dom/src/node_validators/svg_node_validator.dart';
import 'package:sanitize_dom/src/node_validators/templating_node_validator.dart';
import 'package:sanitize_dom/src/url_policy.dart';
import 'package:web/web.dart';

/// Class which helps construct standard node validation policies.
///
/// By default this will not accept anything, but the 'allow*' functions can be
/// used to expand what types of elements or attributes are allowed.
///
/// All allow functions are additive- elements will be accepted if they are
/// accepted by any specific rule.
///
/// It is important to remember that sanitization is not just intended to prevent
/// cross-site scripting attacks, but also to prevent information from being
/// displayed in unexpected ways. For example something displaying basic
/// formatted text may not expect `<video>` tags to appear. In this case an
/// empty NodeValidatorBuilder with just [allowTextElements] might be
/// appropriate.
base class NodeValidatorBuilder implements NodeValidator {
  NodeValidatorBuilder();

  /// Creates a new NodeValidatorBuilder which accepts common constructs.
  ///
  /// By default this will accept HTML5 elements and attributes with the default
  /// [UriPolicy] and templating elements.
  ///
  /// Notable syntax which is filtered:
  ///
  /// * Only known-good HTML5 elements and attributes are allowed.
  /// * All URLs must be same-origin, use [allowNavigation] and [allowImages] to
  /// specify additional URI policies.
  /// * Inline-styles are not allowed.
  /// * Custom element tags are disallowed, use [allowCustomElement].
  /// * Custom tags extensions are disallowed, use [allowTagExtension].
  /// * SVG Elements are not allowed, use [allowSvg].
  ///
  /// For scenarios where the HTML should only contain formatted text
  /// [allowTextElements] is more appropriate.
  ///
  /// Use [allowSvg] to allow SVG elements.
  NodeValidatorBuilder.common() {
    allowHTML5();
    allowTemplating();
  }

  /// @nodoc
  @internal
  final List<NodeValidator> validators = <NodeValidator>[];

  /// Allows navigation elements- Form and Anchor tags, along with common
  /// attributes.
  ///
  /// The UriPolicy can be used to restrict the locations the navigation elements
  /// are allowed to direct to. By default this will use the default [UriPolicy].
  void allowNavigation([UriPolicy? uriPolicy]) {
    uriPolicy ??= UriPolicy();
    add(SimpleNodeValidator.allowNavigation(uriPolicy));
  }

  /// Allows image elements.
  ///
  /// The UriPolicy can be used to restrict the locations the images may be
  /// loaded from. By default this will use the default [UriPolicy].
  void allowImages([UriPolicy? uriPolicy]) {
    uriPolicy ??= UriPolicy();
    add(SimpleNodeValidator.allowImages(uriPolicy));
  }

  /// Allow basic text elements.
  ///
  /// This allows a subset of HTML5 elements, specifically just these tags and
  /// no attributes.
  ///
  /// * B
  /// * BLOCKQUOTE
  /// * BR
  /// * EM
  /// * H1
  /// * H2
  /// * H3
  /// * H4
  /// * H5
  /// * H6
  /// * HR
  /// * I
  /// * LI
  /// * OL
  /// * P
  /// * SPAN
  /// * UL
  void allowTextElements() {
    add(SimpleNodeValidator.allowTextElements());
  }

  /// Allow inline styles on elements.
  ///
  /// If [tagName] is not specified then this allows inline styles on all
  /// elements. Otherwise tagName limits the styles to the specified elements.
  void allowInlineStyles({String? tagName}) {
    if (tagName == null) {
      tagName = '*';
    } else {
      tagName = tagName.toUpperCase();
    }

    add(SimpleNodeValidator(null, allowedAttributes: ['$tagName::style']));
  }

  /// Allow common safe HTML5 elements and attributes.
  ///
  /// This list is based off of the Caja whitelists at:
  /// https://code.google.com/p/google-caja/wiki/CajaWhitelists.
  ///
  /// Common things which are not allowed are script elements, style attributes
  /// and any script handlers.
  void allowHTML5({UriPolicy? uriPolicy}) {
    add(HTML5NodeValidator(uriPolicy: uriPolicy));
  }

  /// Allow SVG elements and attributes except for known bad ones.
  void allowSvg() {
    add(SVGNodeValidator());
  }

  /// Allow custom elements with the specified tag name and specified attributes.
  ///
  /// This will allow the elements as custom tags (such as
  /// &lt;x-foo&gt;&lt;/x-foo&gt;), but will not allow tag extensions. Use
  /// [allowTagExtension] to allow tag extensions.
  void allowCustomElement(
    String tagName, {
    UriPolicy? uriPolicy,
    Iterable<String>? attributes,
    Iterable<String>? uriAttributes,
  }) {
    var tagNameUpper = tagName.toUpperCase();

    var attrs = attributes
        ?.map<String>((name) => '$tagNameUpper::${name.toLowerCase()}');

    var uriAttrs = uriAttributes
        ?.map<String>((name) => '$tagNameUpper::${name.toLowerCase()}');

    uriPolicy ??= UriPolicy();

    add(CustomElementNodeValidator(
      uriPolicy,
      <String>[tagNameUpper],
      attrs,
      uriAttrs,
      false,
      true,
    ));
  }

  /// Allow custom tag extensions with the specified type name and specified
  /// attributes.
  ///
  /// This will allow tag extensions (such as <div is="x-foo"></div>),
  /// but will not allow custom tags. Use [allowCustomElement] to allow
  /// custom tags.
  void allowTagExtension(
    String tagName,
    String baseName, {
    UriPolicy? uriPolicy,
    Iterable<String>? attributes,
    Iterable<String>? uriAttributes,
  }) {
    var baseNameUpper = baseName.toUpperCase();
    var tagNameUpper = tagName.toUpperCase();

    var attrs = attributes
        ?.map<String>((name) => '$baseNameUpper::${name.toLowerCase()}');

    var uriAttrs = uriAttributes
        ?.map<String>((name) => '$baseNameUpper::${name.toLowerCase()}');

    uriPolicy ??= UriPolicy();

    add(CustomElementNodeValidator(
      uriPolicy,
      [tagNameUpper, baseNameUpper],
      attrs,
      uriAttrs,
      true,
      false,
    ));
  }

  void allowElement(
    String tagName, {
    UriPolicy? uriPolicy,
    Iterable<String>? attributes,
    Iterable<String>? uriAttributes,
  }) {
    allowCustomElement(
      tagName,
      uriPolicy: uriPolicy,
      attributes: attributes,
      uriAttributes: uriAttributes,
    );
  }

  /// Allow templating elements (such as <template> and template-related
  /// attributes.
  ///
  /// This still requires other validators to allow regular attributes to be
  /// bound (such as [allowHTML5]).
  void allowTemplating() {
    add(TemplatingNodeValidator());
  }

  /// Add an additional validator to the current list of validators.
  ///
  /// Elements and attributes will be accepted if they are accepted by any
  /// validators.
  void add(NodeValidator validator) {
    validators.add(validator);
  }

  @override
  bool allowsElement(Element element) {
    return validators.any((validator) => validator.allowsElement(element));
  }

  @override
  bool allowsAttribute(Element element, String attributeName, String value) {
    return validators.any((validator) =>
        validator.allowsAttribute(element, attributeName, value));
  }
}
