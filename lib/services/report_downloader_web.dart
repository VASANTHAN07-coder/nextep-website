// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html;

Future<bool> downloadHtmlReport({
  required String fileName,
  required String htmlContent,
}) async {
  final safeName =
      fileName.trim().isEmpty ? 'analysis_report' : fileName.trim();
  final resolvedName =
      safeName.toLowerCase().endsWith('.html') ? safeName : '$safeName.html';

  final bytes = utf8.encode(htmlContent);
  final blob = html.Blob([bytes], 'text/html;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..style.display = 'none'
    ..download = resolvedName;

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);

  return true;
}
