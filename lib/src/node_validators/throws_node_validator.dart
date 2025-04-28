import 'package:sanitize_dom/src/node_validator.dart';
import 'package:sanitize_dom/src/utilities.dart';
import 'package:web/web.dart';

base class ThrowsNodeValidator implements NodeValidator {
  ThrowsNodeValidator(this.validator);

  final NodeValidator validator;

  @override
  bool allowsElement(Element element) {
    if (validator.allowsElement(element)) {
      return true;
    }

    throw ArgumentError(safeTagName(element));
  }

  @override
  bool allowsAttribute(Element element, String attributeName, String value) {
    if (validator.allowsAttribute(element, attributeName, value)) {
      return true;
    }

    throw ArgumentError('${safeTagName(element)}[$attributeName="$value"]');
  }
}
