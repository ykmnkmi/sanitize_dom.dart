import 'package:sanitize_dom/src/node_tree_sanitizer.dart';
import 'package:web/web.dart';

/// A sanitizer for trees that we trust. It does no validation and allows
/// any elements.
base class TrustedHTMLTreeSanitizer implements NodeTreeSanitizer {
  const TrustedHTMLTreeSanitizer();

  @override
  void sanitizeTree(Node node) {}
}
