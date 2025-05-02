// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This code was extracted from the deprecated `dart:html` package of the Dart
// SDK and migrated to the `web` package.

import 'package:meta/meta.dart';
import 'package:sanitize_dom/src/url_policy.dart';
import 'package:web/web.dart';

/// Allows URIs to the same origin as the current application was loaded from
/// (such as https://example.com:80).
base class SameOriginUriPolicy implements UriPolicy {
  /// @nodoc
  @internal
  final HTMLAnchorElement hiddenAnchor = HTMLAnchorElement();

  /// @nodoc
  @internal
  final Location location = window.location;

  @override
  bool allowsUri(String uri) {
    hiddenAnchor.href = uri;

    // IE leaves an empty hostname for same-origin URIs.
    return (hiddenAnchor.hostname == location.hostname &&
            hiddenAnchor.port == location.port &&
            hiddenAnchor.protocol == location.protocol) ||
        (hiddenAnchor.hostname == '' &&
            hiddenAnchor.port == '' &&
            (hiddenAnchor.protocol == ':' || hiddenAnchor.protocol == ''));
  }
}
