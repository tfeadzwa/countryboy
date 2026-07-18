/// Helpers for 58mm thermal receipt text.
///
/// Many POS printers / PDF Helvetica subsets lack Unicode glyphs like `→`,
/// which print as blank boxes. Prefer ASCII separators on receipts.
String formatRouteLabel(String origin, String destination) =>
    '$origin -> $destination';

String sanitizeReceiptText(String value) {
  return value
      .replaceAll('→', '->')
      .replaceAll('⟶', '->')
      .replaceAll('⇒', '=>')
      .replaceAll('·', '-')
      .replaceAll('•', '-')
      .replaceAll('—', '-')
      .replaceAll('–', '-')
      .replaceAll('’', "'")
      .replaceAll('‘', "'")
      .replaceAll('“', '"')
      .replaceAll('”', '"');
}
