import 'report_downloader_stub.dart'
    if (dart.library.html) 'report_downloader_web.dart' as report_downloader;

Future<bool> downloadHtmlReport({
  required String fileName,
  required String htmlContent,
}) {
  return report_downloader.downloadHtmlReport(
    fileName: fileName,
    htmlContent: htmlContent,
  );
}
