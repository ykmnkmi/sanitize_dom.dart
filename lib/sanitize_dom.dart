import 'dart:js_interop';

import 'package:sanitize_dom/src/node_tree_sanitizer.dart';
import 'package:sanitize_dom/src/node_tree_sanitizers/trusted_html_tree_sanitizer.dart';
import 'package:sanitize_dom/src/node_tree_sanitizers/validating_tree_sanitizer.dart';
import 'package:sanitize_dom/src/node_validator.dart';
import 'package:sanitize_dom/src/node_validator_builder.dart';
import 'package:web/web.dart';

export 'package:sanitize_dom/src/node_tree_sanitizer.dart';
export 'package:sanitize_dom/src/node_validator.dart';
export 'package:sanitize_dom/src/node_validator_builder.dart';
export 'package:sanitize_dom/src/url_policy.dart';

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

extension ElementSetInnerHTML on Element {
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
    insertAdjacentHtml(
      'beforeend',
      text,
      validator: validator,
      treeSanitizer: treeSanitizer,
    );
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

    if (contextElement.notEquals(parsedBody).toDart) {
      contextElement.remove();
    }

    treeSanitizer.sanitizeTree(fragment);
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
      insertAdjacentNode(
        where,
        createFragment(
          html,
          validator: validator,
          treeSanitizer: treeSanitizer,
        ),
      );
    }
  }

  void insertAdjacentNode(String where, Node node) {
    switch (where.toLowerCase()) {
      case 'beforebegin':
        parentNode!.insertBefore(node, this);
        break;

      case 'afterbegin':
        Node? first = childNodes.length > 0 ? childNodes.item(0) : null;
        insertBefore(node, first);
        break;

      case 'beforeend':
        append(node);
        break;

      case 'afterend':
        parentNode!.insertBefore(node, nextSibling);
        break;

      default:
        throw ArgumentError('Invalid position $where');
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

extension DocumentFragmentSetInnerHTML on DocumentFragment {
  String get innerHtml {
    HTMLDivElement div = document.createElement('div') as HTMLDivElement;
    div.append(cloneNode(true));
    return div.innerHtml;
  }

  void setInnerHTML(
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

extension HTMLTemplateElementSetInnerHTML on HTMLTemplateElement {
  void setInnerHTML(
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
