import 'package:sanitize_dom/sanitize_dom.dart';
import 'package:web/web.dart';

void main() {
  document.body!.innerHtml = '<p>anything</p>';
}
