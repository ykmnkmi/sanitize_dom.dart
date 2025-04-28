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
