// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This code was extracted from the deprecated `dart:html` package of the Dart
// SDK and migrated to the `web` package.

import 'package:meta/meta.dart';
import 'package:sanitize_dom/src/node_validator.dart';
import 'package:sanitize_dom/src/url_policy.dart';
import 'package:sanitize_dom/src/utilities.dart';
import 'package:web/web.dart';

typedef HTML5AttributeValidator = bool Function(
  Element element,
  String attributeName,
  String value,
  HTML5NodeValidator context,
);

/// A Dart DOM validator generated from Caja whitelists.
///
/// This contains a whitelist of known HTML tagNames and attributes and will only
/// accept known good values.
///
/// See also:
///
/// * <https://code.google.com/p/google-caja/wiki/CajaWhitelists>
class HTML5NodeValidator implements NodeValidator {
  @internal
  static const Set<String> allowedElements = <String>{
    'A',
    'ABBR',
    'ACRONYM',
    'ADDRESS',
    'AREA',
    'ARTICLE',
    'ASIDE',
    'AUDIO',
    'B',
    'BDI',
    'BDO',
    'BIG',
    'BLOCKQUOTE',
    'BR',
    'BUTTON',
    'CANVAS',
    'CAPTION',
    'CENTER',
    'CITE',
    'CODE',
    'COL',
    'COLGROUP',
    'COMMAND',
    'DATA',
    'DATALIST',
    'DD',
    'DEL',
    'DETAILS',
    'DFN',
    'DIR',
    'DIV',
    'DL',
    'DT',
    'EM',
    'FIELDSET',
    'FIGCAPTION',
    'FIGURE',
    'FONT',
    'FOOTER',
    'FORM',
    'H1',
    'H2',
    'H3',
    'H4',
    'H5',
    'H6',
    'HEADER',
    'HGROUP',
    'HR',
    'I',
    'IFRAME',
    'IMG',
    'INPUT',
    'INS',
    'KBD',
    'LABEL',
    'LEGEND',
    'LI',
    'MAP',
    'MARK',
    'MENU',
    'METER',
    'NAV',
    'NOBR',
    'OL',
    'OPTGROUP',
    'OPTION',
    'OUTPUT',
    'P',
    'PRE',
    'PROGRESS',
    'Q',
    'S',
    'SAMP',
    'SECTION',
    'SELECT',
    'SMALL',
    'SOURCE',
    'SPAN',
    'STRIKE',
    'STRONG',
    'SUB',
    'SUMMARY',
    'SUP',
    'TABLE',
    'TBODY',
    'TD',
    'TEXTAREA',
    'TFOOT',
    'TH',
    'THEAD',
    'TIME',
    'TR',
    'TRACK',
    'TT',
    'U',
    'UL',
    'VAR',
    'VIDEO',
    'WBR',
  };

  @internal
  static const List<String> standardAttributes = <String>[
    '*::class',
    '*::dir',
    '*::draggable',
    '*::hidden',
    '*::id',
    '*::inert',
    '*::itemprop',
    '*::itemref',
    '*::itemscope',
    '*::lang',
    '*::spellcheck',
    '*::title',
    '*::translate',
    'A::accesskey',
    'A::coords',
    'A::hreflang',
    'A::name',
    'A::shape',
    'A::tabindex',
    'A::target',
    'A::type',
    'AREA::accesskey',
    'AREA::alt',
    'AREA::coords',
    'AREA::nohref',
    'AREA::shape',
    'AREA::tabindex',
    'AREA::target',
    'AUDIO::controls',
    'AUDIO::loop',
    'AUDIO::mediagroup',
    'AUDIO::muted',
    'AUDIO::preload',
    'BDO::dir',
    'BODY::alink',
    'BODY::bgcolor',
    'BODY::link',
    'BODY::text',
    'BODY::vlink',
    'BR::clear',
    'BUTTON::accesskey',
    'BUTTON::disabled',
    'BUTTON::name',
    'BUTTON::tabindex',
    'BUTTON::type',
    'BUTTON::value',
    'CANVAS::height',
    'CANVAS::width',
    'CAPTION::align',
    'COL::align',
    'COL::char',
    'COL::charoff',
    'COL::span',
    'COL::valign',
    'COL::width',
    'COLGROUP::align',
    'COLGROUP::char',
    'COLGROUP::charoff',
    'COLGROUP::span',
    'COLGROUP::valign',
    'COLGROUP::width',
    'COMMAND::checked',
    'COMMAND::command',
    'COMMAND::disabled',
    'COMMAND::label',
    'COMMAND::radiogroup',
    'COMMAND::type',
    'DATA::value',
    'DEL::datetime',
    'DETAILS::open',
    'DIR::compact',
    'DIV::align',
    'DL::compact',
    'FIELDSET::disabled',
    'FONT::color',
    'FONT::face',
    'FONT::size',
    'FORM::accept',
    'FORM::autocomplete',
    'FORM::enctype',
    'FORM::method',
    'FORM::name',
    'FORM::novalidate',
    'FORM::target',
    'FRAME::name',
    'H1::align',
    'H2::align',
    'H3::align',
    'H4::align',
    'H5::align',
    'H6::align',
    'HR::align',
    'HR::noshade',
    'HR::size',
    'HR::width',
    'HTML::version',
    'IFRAME::align',
    'IFRAME::frameborder',
    'IFRAME::height',
    'IFRAME::marginheight',
    'IFRAME::marginwidth',
    'IFRAME::width',
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
    'INPUT::accept',
    'INPUT::accesskey',
    'INPUT::align',
    'INPUT::alt',
    'INPUT::autocomplete',
    'INPUT::autofocus',
    'INPUT::checked',
    'INPUT::disabled',
    'INPUT::inputmode',
    'INPUT::ismap',
    'INPUT::list',
    'INPUT::max',
    'INPUT::maxlength',
    'INPUT::min',
    'INPUT::multiple',
    'INPUT::name',
    'INPUT::placeholder',
    'INPUT::readonly',
    'INPUT::required',
    'INPUT::size',
    'INPUT::step',
    'INPUT::tabindex',
    'INPUT::type',
    'INPUT::usemap',
    'INPUT::value',
    'INS::datetime',
    'KEYGEN::disabled',
    'KEYGEN::keytype',
    'KEYGEN::name',
    'LABEL::accesskey',
    'LABEL::for',
    'LEGEND::accesskey',
    'LEGEND::align',
    'LI::type',
    'LI::value',
    'LINK::sizes',
    'MAP::name',
    'MENU::compact',
    'MENU::label',
    'MENU::type',
    'METER::high',
    'METER::low',
    'METER::max',
    'METER::min',
    'METER::value',
    'OBJECT::typemustmatch',
    'OL::compact',
    'OL::reversed',
    'OL::start',
    'OL::type',
    'OPTGROUP::disabled',
    'OPTGROUP::label',
    'OPTION::disabled',
    'OPTION::label',
    'OPTION::selected',
    'OPTION::value',
    'OUTPUT::for',
    'OUTPUT::name',
    'P::align',
    'PRE::width',
    'PROGRESS::max',
    'PROGRESS::min',
    'PROGRESS::value',
    'SELECT::autocomplete',
    'SELECT::disabled',
    'SELECT::multiple',
    'SELECT::name',
    'SELECT::required',
    'SELECT::size',
    'SELECT::tabindex',
    'SOURCE::type',
    'TABLE::align',
    'TABLE::bgcolor',
    'TABLE::border',
    'TABLE::cellpadding',
    'TABLE::cellspacing',
    'TABLE::frame',
    'TABLE::rules',
    'TABLE::summary',
    'TABLE::width',
    'TBODY::align',
    'TBODY::char',
    'TBODY::charoff',
    'TBODY::valign',
    'TD::abbr',
    'TD::align',
    'TD::axis',
    'TD::bgcolor',
    'TD::char',
    'TD::charoff',
    'TD::colspan',
    'TD::headers',
    'TD::height',
    'TD::nowrap',
    'TD::rowspan',
    'TD::scope',
    'TD::valign',
    'TD::width',
    'TEXTAREA::accesskey',
    'TEXTAREA::autocomplete',
    'TEXTAREA::cols',
    'TEXTAREA::disabled',
    'TEXTAREA::inputmode',
    'TEXTAREA::name',
    'TEXTAREA::placeholder',
    'TEXTAREA::readonly',
    'TEXTAREA::required',
    'TEXTAREA::rows',
    'TEXTAREA::tabindex',
    'TEXTAREA::wrap',
    'TFOOT::align',
    'TFOOT::char',
    'TFOOT::charoff',
    'TFOOT::valign',
    'TH::abbr',
    'TH::align',
    'TH::axis',
    'TH::bgcolor',
    'TH::char',
    'TH::charoff',
    'TH::colspan',
    'TH::headers',
    'TH::height',
    'TH::nowrap',
    'TH::rowspan',
    'TH::scope',
    'TH::valign',
    'TH::width',
    'THEAD::align',
    'THEAD::char',
    'THEAD::charoff',
    'THEAD::valign',
    'TR::align',
    'TR::bgcolor',
    'TR::char',
    'TR::charoff',
    'TR::valign',
    'TRACK::default',
    'TRACK::kind',
    'TRACK::label',
    'TRACK::srclang',
    'UL::compact',
    'UL::type',
    'VIDEO::controls',
    'VIDEO::height',
    'VIDEO::loop',
    'VIDEO::mediagroup',
    'VIDEO::muted',
    'VIDEO::preload',
    'VIDEO::width',
  ];

  @internal
  static const List<String> uriAttributes = <String>[
    'A::href',
    'AREA::href',
    'BLOCKQUOTE::cite',
    'BODY::background',
    'COMMAND::icon',
    'DEL::cite',
    'FORM::action',
    'IMG::src',
    'INPUT::src',
    'INS::cite',
    'Q::cite',
    'VIDEO::poster',
  ];

  @internal
  static final Map<String, HTML5AttributeValidator> attributeValidators =
      <String, HTML5AttributeValidator>{};

  final UriPolicy uriPolicy;

  /// All known URI attributes will be validated against the UriPolicy, if
  /// [uriPolicy] is null then a default UriPolicy will be used.
  HTML5NodeValidator({UriPolicy? uriPolicy})
      : uriPolicy = uriPolicy ?? UriPolicy() {
    if (attributeValidators.isEmpty) {
      for (String attribute in standardAttributes) {
        attributeValidators[attribute] = standardAttributeValidator;
      }

      for (String attribute in uriAttributes) {
        attributeValidators[attribute] = uriAttributeValidator;
      }
    }
  }

  @override
  bool allowsElement(Element element) {
    return allowedElements.contains(safeTagName(element));
  }

  @override
  bool allowsAttribute(Element element, String attributeName, String value) {
    String tagName = safeTagName(element);

    HTML5AttributeValidator? validator =
        attributeValidators['$tagName::$attributeName'] ??
            attributeValidators['*::$attributeName'];

    if (validator == null) {
      return false;
    }

    return validator(element, attributeName, value, this);
  }

  static bool standardAttributeValidator(
    Element element,
    String attributeName,
    String value,
    HTML5NodeValidator context,
  ) {
    return true;
  }

  static bool uriAttributeValidator(
    Element element,
    String attributeName,
    String value,
    HTML5NodeValidator context,
  ) {
    return context.uriPolicy.allowsUri(value);
  }
}
