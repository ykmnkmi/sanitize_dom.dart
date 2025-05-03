// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This tests HTML validation and sanitization, which is very important
/// for prevent XSS or other attacks. If you suppress this, or parts of it
/// please make it a critical bug and bring it to the attention of the
/// `dart:html` maintainers.
library;

import 'dart:js_interop';

import 'package:sanitize_dom/sanitize_dom.dart';
import 'package:test/test.dart';
import 'package:web/web.dart';

import 'utilities.dart';

void validateHTML(String html, String reference, NodeValidator validator) {
  HTMLElement body = document.body!;

  DocumentFragment a = body.createFragment(html, validator: validator);

  DocumentFragment b =
      body.createFragment(reference, treeSanitizer: NodeTreeSanitizer.trusted);

  // Prevent a false pass when both the html and the reference both get entirely
  // deleted, which is technically a match, but unlikely to be what we meant.
  if (reference != '') {
    expect(b.firstChild, isNotNull);
  }

  validateNodeTree(a, b);
}

class RecordingUriValidator implements UriPolicy {
  final List<String> calls = <String>[];

  @override
  bool allowsUri(String uri) {
    calls.add(uri);
    return false;
  }

  void reset() {
    calls.clear();
  }
}

void testHTML(
  String name,
  NodeValidator validator,
  String html, [
  String? reference,
]) {
  test(name, () {
    reference ??= html;

    validateHTML(html, reference!, validator);
  });
}

void main() {
  group('dom_sanitization', () {
    NodeValidatorBuilder validator = NodeValidatorBuilder.common();

    testHTML('allows simple constructs', validator,
        '<div class="baz">something</div>');

    testHTML('blocks unknown attributes', validator,
        '<div foo="baz">something</div>', '<div>something</div>');

    testHTML('blocks custom element', validator,
        '<x-my-element>something</x-my-element>', '');

    testHTML('blocks custom is element', validator,
        '<div is="x-my-element">something</div>', '');

    testHTML(
        'blocks body elements', validator, '<body background="s"></body>', '');

    testHTML('allows select elements', validator,
        '<select><option>a</option></select>');

    testHTML('blocks sequential script elements', validator,
        '<div><script></script><script></script></div>', '<div></div>');

    testHTML('blocks inline styles', validator,
        '<div style="background: red"></div>', '<div></div>');

    testHTML('blocks namespaced attributes', validator,
        '<div ns:foo="foo"></div>', '<div></div>');

    testHTML('blocks namespaced common attributes', validator,
        '<div ns:class="foo"></div>', '<div></div>');

    testHTML('blocks namespaced common elements', validator,
        '<ns:div></ns:div>', '');

    testHTML('allows CDATA sections', validator,
        '<span>![CDATA[ some text ]]></span>');

    testHTML('backquotes not removed', validator,
        '<img src="dice.png" alt="``onload=xss()" />');

    testHTML('0x3000 not removed', validator,
        '<a href="&#x3000;javascript:alert(1)">CLICKME</a>');

    test('sanitizes template contents', () {
      String html = '<template><div></div><script></script>'
          '<img src="http://example.com/foo"/></template>';

      DocumentFragment fragment =
          document.body!.createFragment(html, validator: validator);

      HTMLTemplateElement template = fragment.firstChild as HTMLTemplateElement;

      DocumentFragment expectedContent =
          document.body!.createFragment('<div></div><img/>');

      validateNodeTree(template.content, expectedContent);
    });

    test('appendHTMLSafe is sanitized', () {
      String html = '<body background="s"></body><div></div>';
      document.body!.appendHtml('<div id="stuff"></div>');

      Element stuff = document.querySelector('#stuff')!;
      stuff.appendHtml(html);
      expect(stuff.childNodes.length, equals(1));
      stuff.remove();
    });

    test('documentFragment.appendHTMLSafe is sanitized', () {
      String html = '<div id="things></div>';
      DocumentFragment fragment = document.body!.createFragment(html);
      fragment.appendHtml('<div id="bad"><script></script></div>');
      expect(fragment.childNodes.length, equals(1));

      Element child = fragment.firstChild as Element;
      expect(child.id, equals('bad'));
      expect(child.childNodes.length, isZero);
    });

    testHTML(
        'sanitizes embed',
        validator,
        "<div><embed src='' type='application/x-shockwave-flash'></embed></div>",
        '<div></div>');
  });

  group('URI_sanitization', () {
    RecordingUriValidator recorder = RecordingUriValidator();
    NodeValidatorBuilder validator = NodeValidatorBuilder()
      ..allowHTML5(uriPolicy: recorder);

    void checkUriPolicyCalls(
      String name,
      String html,
      String reference,
      List<String> expectedCalls,
    ) {
      test(name, () {
        recorder.reset();

        validateHTML(html, reference, validator);
        expect(recorder.calls, expectedCalls);
      });
    }

    checkUriPolicyCalls(
        'a::href', '<a href="s"></a>', '<a></a>', <String>['s']);

    checkUriPolicyCalls(
        'area::href', '<area href="s"></area>', '<area></area>', <String>['s']);

    checkUriPolicyCalls(
        'blockquote::cite',
        '<blockquote cite="s"></blockquote>',
        '<blockquote></blockquote>',
        <String>['s']);
    checkUriPolicyCalls(
        'command::icon', '<command icon="s"/>', '<command/>', <String>['s']);
    checkUriPolicyCalls('img::src', '<img src="s"/>', '<img/>', <String>['s']);
    checkUriPolicyCalls(
        'input::src', '<input src="s"/>', '<input/>', <String>['s']);
    checkUriPolicyCalls(
        'ins::cite', '<ins cite="s"></ins>', '<ins></ins>', <String>['s']);
    checkUriPolicyCalls(
        'q::cite', '<q cite="s"></q>', '<q></q>', <String>['s']);
    checkUriPolicyCalls(
        'video::poster', '<video poster="s"/>', '<video/>', <String>['s']);
  });

  group('allowNavigation', () {
    NodeValidatorBuilder validator = NodeValidatorBuilder()..allowNavigation();

    testHTML('allows anchor tags', validator, '<a href="#foo">foo</a>');

    testHTML('allows form elements', validator,
        '<form method="post" action="/foo"></form>');

    testHTML('disallows script navigation', validator,
        '<a href="javascript:foo = 1">foo</a>', '<a>foo</a>');

    testHTML('disallows cross-site navigation', validator,
        '<a href="http://example.com">example.com</a>', '<a>example.com</a>');

    testHTML('blocks other elements', validator,
        '<a href="#foo"><b>foo</b></a>', '<a href="#foo"></a>');

    testHTML('blocks tag extension', validator, '<a is="x-foo"></a>', '');
  });

  group('allowImages', () {
    NodeValidatorBuilder validator = NodeValidatorBuilder()..allowImages();

    testHTML('allows images', validator,
        '<img src="/foo.jpg" alt="something" width="100" height="100"/>');

    testHTML('blocks onerror', validator,
        '<img src="/foo.jpg" onerror="something"/>', '<img src="/foo.jpg"/>');

    testHTML('enforces same-origin', validator,
        '<img src="http://example.com/foo.jpg"/>', '<img/>');
  });

  group('allowCustomElement', () {
    var validator = NodeValidatorBuilder()
      ..allowCustomElement('x-foo',
          attributes: <String>['bar'], uriAttributes: <String>['baz'])
      ..allowHTML5();

    testHTML('allows custom elements', validator,
        '<x-foo bar="something" baz="/foo.jpg"></x-foo>');

    testHTML('validates custom tag URIs', validator,
        '<x-foo baz="http://example.com/foo.jpg"></x-foo>', '<x-foo></x-foo>');

    testHTML('blocks type extensions', validator, '<div is="x-foo"></div>', '');

    testHTML('blocks tags on non-matching elements', validator,
        '<div bar="foo"></div>', '<div></div>');
  });

  group('identify Uri attributes listed as attributes', () {
    NodeValidatorBuilder validator = NodeValidatorBuilder()
      ..allowElement('a', attributes: <String>['href']);

    testHTML(
        'reject different-origin link',
        validator,
        '<a href="http://www.google.com/foo">Google-Foo</a>',
        '<a>Google-Foo</a>');
  });

  group('allowTagExtension', () {
    NodeValidatorBuilder validator = NodeValidatorBuilder()
      ..allowTagExtension('x-foo', 'div',
          attributes: <String>['bar'], uriAttributes: <String>['baz'])
      ..allowHTML5();

    testHTML('allows tag extensions', validator,
        '<div is="x-foo" bar="something" baz="/foo.jpg"></div>');

    testHTML('blocks custom elements', validator, '<x-foo></x-foo>', '');

    testHTML(
        'validates tag extension URIs',
        validator,
        '<div is="x-foo" baz="http://example.com/foo.jpg"></div>',
        '<div is="x-foo"></div>');

    testHTML('blocks tags on non-matching elements', validator,
        '<div bar="foo"></div>', '<div></div>');

    testHTML('blocks non-matching tags', validator,
        '<span is="x-foo">something</span>', '');

    validator = NodeValidatorBuilder()
      ..allowTagExtension('x-foo', 'div',
          attributes: <String>['bar'], uriAttributes: <String>['baz'])
      ..allowTagExtension('x-else', 'div');

    testHTML('blocks tags on non-matching custom elements', validator,
        '<div bar="foo" is="x-else"></div>', '<div is="x-else"></div>');
  });

  group('allowTemplating', () {
    NodeValidatorBuilder validator = NodeValidatorBuilder()
      ..allowTemplating()
      ..allowHTML5();

    testHTML(
        'allows templates', validator, '<template bind="{{a}}"></template>');

    testHTML(
        'allows template attributes',
        validator,
        '<template bind="{{a}}" ref="foo" repeat="{{}}" if="{{}}" syntax="foo">'
            '</template>');

    testHTML('allows template attribute', validator,
        '<div template repeat="{{}}"></div>');

    testHTML('blocks illegal template attribute', validator,
        '<div template="foo" repeat="{{}}"></div>', '<div></div>');
  });

  group('allowSVG', () {
    NodeValidatorBuilder validator = NodeValidatorBuilder()
      ..allowSVG()
      ..allowTextElements();

    testHTML(
        'allows basic SVG',
        validator,
        '<svg xmlns="http://www.w3.org/2000/svg'
            'xmlns:xlink="http://www.w3.org/1999/xlink">'
            '<image xlink:href="foo" data-foo="bar"/>'
            '</svg>');

    testHTML('blocks script elements', validator,
        '<svg xmlns="http://www.w3.org/2000/svg><script></script></svg>', '');

    testHTML(
        'blocks script elements but allows other',
        validator,
        // original line
        // '<svg xmlns="http://www.w3.org/2000/svg>'
        '<svg xmlns="http://www.w3.org/2000/svg">'
            '<script></script><ellipse cx="200" cy="80" rx="100" ry="50">'
            '</ellipse></svg>',
        // original line
        // '<svg xmlns="http://www.w3.org/2000/svg><ellipse cx="200" cy="80" '
        '<svg xmlns="http://www.w3.org/2000/svg"><ellipse cx="200" cy="80" '
            'rx="100" ry="50"></ellipse></svg>');

    testHTML(
        'blocks script handlers',
        validator,
        '<svg xmlns="http://www.w3.org/2000/svg'
            'xmlns:xlink="http://www.w3.org/1999/xlink">'
            '<image xlink:href="foo" onerror="something"/></svg>',
        '<svg xmlns="http://www.w3.org/2000/svg'
            'xmlns:xlink="http://www.w3.org/1999/xlink">'
            '<image xlink:href="foo"/></svg>');

    testHTML(
        'blocks foreignObject content',
        validator,
        '<svg xmlns="http://www.w3.org/2000/svg">'
            '<foreignobject width="100" height="150">'
            '<body xmlns="http://www.w3.org/1999/xhtml"><div>Some content</div>'
            '</body></foreignobject><b>42</b></svg>',
        '<svg xmlns="http://www.w3.org/2000/svg"><b>42</b></svg>');
  });

  group('allowInlineStyles', () {
    NodeValidatorBuilder validator = NodeValidatorBuilder()
      ..allowTextElements()
      ..allowInlineStyles();

    testHTML('allows inline styles', validator,
        '<span style="background-color:red">text</span>');

    testHTML('blocks other attributes', validator,
        '<span class="red-span"></span>', '<span></span>');

    validator = NodeValidatorBuilder()
      ..allowTextElements()
      ..allowInlineStyles(tagName: 'span');

    testHTML('scoped allows inline styles on spans', validator,
        '<span style="background-color:red">text</span>');

    testHTML('scoped blocks inline styles on LIs', validator,
        '<li style="background-color:red">text</li>', '<li>text</li>');
  });

  group('throws', () {
    NodeValidator validator =
        NodeValidator.throws(NodeValidatorBuilder.common());

    Matcher validationError = throwsArgumentError;

    test('does not throw on valid syntax', () {
      expect(() {
        document.body!.createFragment('<div></div>', validator: validator);
      }, returnsNormally);
    });

    test('throws on invalid elements', () {
      expect(() {
        document.body!.createFragment('<foo></foo>', validator: validator);
      }, validationError);
    });

    test('throws on invalid attributes', () {
      expect(() {
        document.body!
            .createFragment('<div foo="bar"></div>', validator: validator);
      }, validationError);
    });

    test('throws on invalid attribute values', () {
      expect(() {
        document.body!.createFragment('<img src="http://example.com/foo.jpg"/>',
            validator: validator);
      }, validationError);
    });
  });

  group('svg', () {
    test('parsing', () {
      String svgText = '<svg xmlns="http://www.w3.org/2000/svg'
          'xmlns:xlink="http://www.w3.org/1999/xlink">'
          '<image xlink:href="foo" data-foo="bar"/>'
          '</svg>';

      DocumentFragment fragment = SVGSVGElement().createFragment(svgText);
      Element element = fragment.firstChild as Element;
      expect(element.isA<SVGSVGElement>(), isTrue);
      expect(element.children.item(0).isA<SVGImageElement>(), isTrue);
    });
  });

  group('dom_clobbering', () {
    NodeValidatorBuilder validator = NodeValidatorBuilder.common();

    testHTML(
      'DOM clobbering of attributes with single node',
      validator,
      "<form id='single_node_clobbering' onmouseover='alert(1)'><input name='attributes'>",
      '',
    );

    testHTML(
        'DOM clobbering of attributes with multiple nodes',
        validator,
        "<form onmouseover='alert(1)'><input name='attributes'>"
            "<input name='attributes'>",
        '');

    testHTML('DOM clobbering of lastChild', validator,
        "<form><input name='lastChild'><input onmouseover='alert(1)'>", '');

    testHTML(
        'DOM clobbering of both children and lastChild',
        validator,
        "<form><input name='lastChild'><input name='children'>"
            "<input id='children'><input onmouseover='alert(1)'>",
        '');

    testHTML(
        'DOM clobbering of both children and lastChild, different order',
        validator,
        "<form><input name='children'><input name='children'>"
            "<input id='children' name='lastChild'>"
            "<input id='bad' onmouseover='alert(1)'>",
        '');

    // Walking templates triggers a recursive sanitization call, which shouldn't
    // invalidate the information collected from the previous visit of the later
    // nodes in the walk.
    testHTML(
        'DOM clobbering with recursive sanitize call using templates',
        validator,
        '<form><div>'
            '<input id=childNodes />'
            '<template></template>'
            '<input id=childNodes name=lastChild />'
            "<img id=exploitImg src=0 onerror='alert(1)' />"
            '</div></form>',
        '');

    test('tagName makes containing form invalid', () {
      DocumentFragment fragment = document.body!.createFragment(
          "<form onmouseover='alert(2)'><input name='tagName'>",
          validator: validator);

      HTMLFormElement? form = fragment.lastChild as HTMLFormElement?;

      // If the tagName was clobbered, the sanitizer should have removed
      // the whole thing and form is null.
      // If the tagName was not clobbered, then there will be content,
      // but the tagName should be the normal value. IE11 has started
      // doing this.
      if (form != null) {
        expect(form.tagName, 'FORM');
      }
    });

    test('tagName without mouseover', () {
      DocumentFragment fragment = document.body!
          .createFragment("<form><input name='tagName'>", validator: validator);

      HTMLFormElement? form = fragment.lastChild as HTMLFormElement?;

      // If the tagName was clobbered, the sanitizer should have removed
      // the whole thing and form is null.
      // If the tagName was not clobbered, then there will be content,
      // but the tagName should be the normal value.
      if (form != null) {
        expect(form.tagName, 'FORM');
      }
    });
  });
}
