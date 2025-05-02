// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This code was extracted from the deprecated `dart:html` package of the Dart
// SDK and migrated to the `web` package.

import 'package:sanitize_dom/src/uri_policies/same_origin_uri_policy.dart';

/// Defines the policy for what types of uris are allowed for particular
/// attribute values.
///
/// This can be used to provide custom rules such as allowing all http:// URIs
/// for image attributes but only same-origin URIs for anchor tags.
abstract interface class UriPolicy {
  /// Constructs the default UriPolicy which is to only allow Uris to the same
  /// origin as the application was launched from.
  ///
  /// This will block all ftp: mailto: URIs. It will also block accessing
  /// https://example.com if the app is running from http://example.com.
  factory UriPolicy() = SameOriginUriPolicy;

  /// Checks if the uri is allowed on the specified attribute.
  ///
  /// The uri provided may or may not be a relative path.
  bool allowsUri(String uri);
}
