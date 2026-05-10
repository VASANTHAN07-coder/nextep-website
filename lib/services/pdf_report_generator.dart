import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:guidex/models/recommendation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AnalysisPdfReportData {
  final String fileName;
  final String name;
  final String category;
  final double cutoff;
  final String selectedCourse;
  final String summary;
  final List<Recommendation> preferredColleges;
  final List<Recommendation> safeColleges;
  final List<String> selectedPreferredCollegeNames;
  final String logoAssetPath;
  final DateTime? generatedAt;

  const AnalysisPdfReportData({
    required this.fileName,
    required this.name,
    required this.category,
    required this.cutoff,
    required this.selectedCourse,
    required this.summary,
    required this.preferredColleges,
    required this.safeColleges,
    this.selectedPreferredCollegeNames = const [],
    required this.logoAssetPath,
    this.generatedAt,
  });
}

class _ScoredRecommendation {
  final Recommendation item;
  final int probability;
  final String bucket;

  const _ScoredRecommendation({
    required this.item,
    required this.probability,
    required this.bucket,
  });
}

class _GroupedRecommendations {
  final List<_ScoredRecommendation> preferred;
  final List<_ScoredRecommendation> safe;

  const _GroupedRecommendations({
    required this.preferred,
    required this.safe,
  });

  int get total => preferred.length + safe.length;
}

class PdfReportGenerator {
  static final RegExp _unsupportedGlyphs = RegExp(r'[^\x09\x0A\x0D\x20-\x7E]');

  static const PdfColor _bgStart = PdfColor.fromInt(0xFFEAF4FF);
  static const PdfColor _bgEnd = PdfColor.fromInt(0xFFD6EBFF);
  static const PdfColor _brandBlue = PdfColor.fromInt(0xFF1E88E5);
  static const PdfColor _textDark = PdfColor.fromInt(0xFF1F2937);
  static const PdfColor _cardBorder = PdfColor.fromInt(0xFFDCE8F7);

  static const PdfColor _safeColor = PdfColor.fromInt(0xFF43A047);
  static const PdfColor _preferredColor = PdfColor.fromInt(0xFF1E88E5);

  static const String _iconLocationSvg =
      '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path fill="#1E88E5" d="M12 2a7 7 0 0 0-7 7c0 5.16 7 13 7 13s7-7.84 7-13a7 7 0 0 0-7-7zm0 9.5A2.5 2.5 0 1 1 12 6a2.5 2.5 0 0 1 0 5.5z"/></svg>';
  static const String _iconCourseSvg =
      '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path fill="#1E88E5" d="M12 3 1 9l11 6 9-4.91V17h2V9L12 3zm-7 9.18V17l7 4 7-4v-4.82l-7 3.82-7-3.82z"/></svg>';
  static const String _iconStarSvg =
      '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path fill="#1E88E5" d="m12 17.27 6.18 3.73-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg>';
  static const String _iconUserSvg =
      '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path fill="#1E88E5" d="M12 12a5 5 0 1 0-5-5 5 5 0 0 0 5 5zm0 2c-4.42 0-8 2.24-8 5v2h16v-2c0-2.76-3.58-5-8-5z"/></svg>';
  static const String _iconInsightSvg =
      '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path fill="#1E88E5" d="M19 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V5a2 2 0 0 0-2-2zM9 17H7v-7h2zm4 0h-2V7h2zm4 0h-2v-4h2z"/></svg>';

  static Future<void> generateAndDownloadPdf(AnalysisPdfReportData data) async {
    final document = pw.Document();
    final logoImage = await _loadLogo(data.logoAssetPath);
    final generatedAt = data.generatedAt ?? DateTime.now();
    final grouped = _groupByProbability(data);

    document.addPage(
      pw.MultiPage(
        maxPages: 500,
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(24, 20, 24, 28),
          buildBackground: (context) => _buildPageBackground(),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        header: (context) => _buildTopRightLogoHeader(logoImage),
        footer: (context) => _buildFooter(
          context: context,
          generatedAt: generatedAt,
          logoImage: logoImage,
        ),
        build: (context) => [
          _buildCoverBanner(logoImage),
          pw.SizedBox(height: 12),
          _buildStudentSummaryCard(data),
          pw.SizedBox(height: 12),
          _buildOverallInsightCard(
            summary: data.summary,
            totalColleges: grouped.total,
            preferredCount: grouped.preferred.length,
            safeCount: grouped.safe.length,
            selectedPreferredCount: data.selectedPreferredCollegeNames.length,
          ),
          pw.SizedBox(height: 14),
          ..._buildCategorySection(
            title: 'Your Preferred Colleges',
            subtitle: 'Colleges selected by you for direct comparison',
            titleColor: _preferredColor,
            items: grouped.preferred,
          ),
          pw.SizedBox(height: 10),
          ..._buildCategorySection(
            title: 'Target Colleges',
            subtitle: 'Top colleges by weighted scoring model',
            titleColor: _safeColor,
            items: grouped.safe,
          ),
        ],
      ),
    );

    document.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(24, 20, 24, 28),
          buildBackground: (context) => _buildPageBackground(),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        build: (context) => _buildCompanyDetailsLastPage(
          logoImage: logoImage,
          generatedAt: generatedAt,
        ),
      ),
    );

    final pdfBytes = await document.save();

    try {
      await Printing.layoutPdf(
        name: data.fileName,
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (_) {
      // Fallback for devices without print services.
      await Printing.sharePdf(bytes: pdfBytes, filename: data.fileName);
    }
  }

  static _GroupedRecommendations _groupByProbability(
      AnalysisPdfReportData data) {
    final preferred = <_ScoredRecommendation>[];
    final safe = <_ScoredRecommendation>[];

    final seen = <String>{};

    void addItems(List<Recommendation> items, String bucket) {
      for (final item in items) {
        final key =
            '${_safe(item.collegeName).toLowerCase()}|${_safe(item.courseName).toLowerCase()}';
        if (!seen.add(key)) {
          continue;
        }

        final scored = _ScoredRecommendation(
          item: item,
          probability: item.probability.clamp(0, 100).toInt(),
          bucket: bucket,
        );

        if (bucket == 'preferred') {
          preferred.add(scored);
        } else {
          safe.add(scored);
        }
      }
    }

    addItems(data.preferredColleges, 'preferred');
    addItems(data.safeColleges, 'safe');

    int compare(_ScoredRecommendation a, _ScoredRecommendation b) {
      final byProbability = b.probability.compareTo(a.probability);
      if (byProbability != 0) {
        return byProbability;
      }

      final byCutoff = b.item.cutoff.compareTo(a.item.cutoff);
      if (byCutoff != 0) {
        return byCutoff;
      }

      return a.item.collegeName.toLowerCase().compareTo(
            b.item.collegeName.toLowerCase(),
          );
    }

    preferred.sort(compare);
    safe.sort(compare);

    return _GroupedRecommendations(
      preferred: preferred,
      safe: safe,
    );
  }

  static Future<pw.MemoryImage> _loadLogo(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    return pw.MemoryImage(bytes);
  }

  static pw.Widget _buildPageBackground() {
    return pw.FullPage(
      ignoreMargins: true,
      child: pw.Container(
        decoration: const pw.BoxDecoration(
          gradient: pw.LinearGradient(
            colors: [_bgStart, _bgEnd],
            begin: pw.Alignment.topLeft,
            end: pw.Alignment.bottomRight,
          ),
        ),
        child: pw.Stack(
          children: [
            pw.Positioned(
              right: -50,
              top: -35,
              child: pw.Container(
                width: 145,
                height: 145,
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0x22FFFFFF),
                  shape: pw.BoxShape.circle,
                ),
              ),
            ),
            pw.Positioned(
              left: -40,
              bottom: -36,
              child: pw.Container(
                width: 130,
                height: 130,
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0x1AFFFFFF),
                  shape: pw.BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTopRightLogoHeader(pw.MemoryImage logoImage) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 56,
        height: 24,
        padding: const pw.EdgeInsets.all(2),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xCCFFFFFF),
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: const PdfColor.fromInt(0x88C3DBF4)),
        ),
        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
      ),
    );
  }

  static pw.Widget _buildCoverBanner(pw.MemoryImage logoImage) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [PdfColor.fromInt(0xFF42A5F5), PdfColor.fromInt(0xFF1E88E5)],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
        borderRadius: pw.BorderRadius.circular(14),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 58,
            height: 40,
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0x26FFFFFF),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'College Analysis Report',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Based on your cutoff and preferences',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStudentSummaryCard(AnalysisPdfReportData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _cardBorder),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              _labelWithIcon(_iconUserSvg, 'Student Summary', _brandBlue, 12),
              pw.Spacer(),
              _categoryBadge(data.category),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 2,
                child: _summaryField(
                  label: 'Name',
                  value: _safe(data.name).isEmpty ? 'Student' : data.name,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFEAF4FF),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _labelWithIcon(
                          _iconInsightSvg, 'Cutoff', PdfColors.grey700, 9),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        data.cutoff.toStringAsFixed(1),
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: _brandBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          _summaryField(
            label: 'Selected Course',
            value: _safe(data.selectedCourse).isEmpty
                ? 'Not provided'
                : data.selectedCourse,
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryField({
    required String label,
    required String value,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF7FAFE),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE3EEFA)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildOverallInsightCard({
    required String summary,
    required int totalColleges,
    required int preferredCount,
    required int safeCount,
    required int selectedPreferredCount,
  }) {
    final resolvedSummary = _safe(summary).isEmpty
        ? 'This report summarizes colleges based on your cutoff and eligibility trends.'
        : summary;

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFEAF4FF),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFD0E4FB)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _labelWithIcon(_iconInsightSvg, 'Overall Insight', _brandBlue, 13),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  '$totalColleges',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: _brandBlue,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  'Total Colleges',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            resolvedSummary,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColor.fromInt(0xFF29496B),
              lineSpacing: 1.4,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Bullet(
            text: 'Preferred results: $preferredCount',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
          ),
          pw.Bullet(
            text: 'Target colleges: $safeCount',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
          ),
          pw.Bullet(
            text: 'Colleges selected by user: $selectedPreferredCount',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildCategorySection({
    required String title,
    required String subtitle,
    required PdfColor titleColor,
    required List<_ScoredRecommendation> items,
  }) {
    final widgets = <pw.Widget>[
      pw.Container(
        padding: const pw.EdgeInsets.only(left: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            left: pw.BorderSide(color: titleColor, width: 4),
          ),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
                color: titleColor,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              subtitle,
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 8),
    ];

    if (items.isEmpty) {
      widgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(10),
            border: pw.Border.all(color: _cardBorder),
          ),
          child: pw.Text(
            'No colleges available in this section.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ),
      );
      return widgets;
    }

    widgets.add(_buildTwoColumnGrid(items));
    return widgets;
  }

  static pw.Widget _buildTwoColumnGrid(List<_ScoredRecommendation> items) {
    final rows = <pw.TableRow>[];

    for (var i = 0; i < items.length; i += 2) {
      final left = items[i];
      final right = i + 1 < items.length ? items[i + 1] : null;

      rows.add(
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.top,
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.only(right: 8, bottom: 8),
              child: _buildCollegeCard(left),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 8, bottom: 8),
              child: right == null ? pw.Container() : _buildCollegeCard(right),
            ),
          ],
        ),
      );
    }

    return pw.Table(
      columnWidths: const <int, pw.TableColumnWidth>{
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1),
      },
      children: rows,
    );
  }

  static pw.Widget _buildCollegeCard(_ScoredRecommendation scored) {
    final item = scored.item;
    final district =
        _safe(item.district).isEmpty ? 'N/A' : _safe(item.district);
    final tagColor = _tagColor(scored.bucket);

    return pw.Container(
      constraints: const pw.BoxConstraints(minHeight: 132),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _cardBorder),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  _safe(item.collegeName),
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _textDark,
                  ),
                ),
              ),
              pw.SizedBox(width: 6),
              _recommendationBadge(scored.bucket, tagColor),
            ],
          ),
          pw.SizedBox(height: 6),
          _iconLine(_iconCourseSvg, _safe(item.courseName), 9),
          pw.SizedBox(height: 4),
          _iconLine(_iconLocationSvg, district, 9),
          pw.SizedBox(height: 4),
          _iconLine(
              _iconStarSvg, 'Cutoff: ${item.cutoff.toStringAsFixed(2)}', 9),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              _progressBar(value: scored.probability, color: tagColor),
              pw.SizedBox(width: 6),
              pw.Text(
                '${scored.probability}%',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: tagColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _iconLine(String svg, String text, double fontSize) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 10,
          height: 10,
          child: pw.SvgImage(svg: svg),
        ),
        pw.SizedBox(width: 4),
        pw.Expanded(
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: fontSize,
              color: PdfColors.grey800,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _labelWithIcon(
    String svg,
    String text,
    PdfColor color,
    double fontSize,
  ) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 12,
          height: 12,
          child: pw.SvgImage(svg: svg),
        ),
        pw.SizedBox(width: 5),
        pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static pw.Widget _progressBar({required int value, required PdfColor color}) {
    const width = 92.0;
    const height = 6.0;

    return pw.Container(
      width: width,
      height: height,
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFE5EDF6),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Align(
        alignment: pw.Alignment.centerLeft,
        child: pw.Container(
          width: width * (value.clamp(0, 100) / 100.0),
          height: height,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildFooter({
    required pw.Context context,
    required DateTime generatedAt,
    required pw.MemoryImage logoImage,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: PdfColor.fromInt(0x88A5C8EA),
            width: 0.7,
          ),
        ),
      ),
      child: pw.Stack(
        children: [
          pw.Positioned(
            right: 0,
            top: -2,
            child: pw.Opacity(
              opacity: 0.08,
              child: pw.Image(
                logoImage,
                width: 52,
                fit: pw.BoxFit.contain,
              ),
            ),
          ),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'Generated: ${_formatDate(generatedAt)}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'NextStep • Smart College Guidance',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Page ${context.pageNumber} / ${context.pagesCount}',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCompanyDetailsLastPage({
    required pw.MemoryImage logoImage,
    required DateTime generatedAt,
  }) {
    pw.Widget sectionTitle(String text) {
      return pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 19,
          fontWeight: pw.FontWeight.bold,
          color: _textDark,
        ),
      );
    }

    pw.Widget point(String text) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Text(
          '> $text',
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColor.fromInt(0xFF1F2937),
            lineSpacing: 1.2,
          ),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildTopRightLogoHeader(logoImage),
        pw.SizedBox(height: 4),
        pw.Row(
          children: [
            pw.Container(
              width: 4,
              height: 20,
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFF21A34A),
                borderRadius: pw.BorderRadius.circular(3),
              ),
            ),
            pw.SizedBox(width: 8),
            sectionTitle('Your Journey Starts Here'),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFF4F4F4),
            borderRadius: pw.BorderRadius.circular(12),
            border: pw.Border.all(color: const PdfColor.fromInt(0xFFE3E3E3)),
          ),
          child: pw.Text(
            'NeXtep Guidance',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: _textDark,
            ),
          ),
        ),
        pw.SizedBox(height: 12),
        sectionTitle('What NeXtep Will Do For You'),
        pw.SizedBox(height: 5),
        point('College selection strategy based on your cutoff and category'),
        point('Step-by-step guidance for TNEA counselling process'),
        point('Course and career roadmap based on your interests'),
        point('Skill development and recommended courses'),
        point('Placement preparation (resume, aptitude, interviews)'),
        point('Guidance for competitive exams (GATE, UPSC, Banking, etc.)'),
        pw.SizedBox(height: 12),
        sectionTitle('How We Guide You (Process Section)'),
        pw.SizedBox(height: 5),
        point('Profile analysis - cutoff, interests, and background review'),
        point('Smart prediction - estimate your admission chances'),
        point('College shortlisting - dream, target, and safe colleges'),
        point('Counselling support - step-by-step TNEA application guidance'),
        point('Career growth plan - skills, courses, and placement roadmap'),
        pw.SizedBox(height: 12),
        sectionTitle('Why Choose Us'),
        pw.SizedBox(height: 5),
        point('Data-driven college prediction system'),
        point('Personalized guidance, not generic advice'),
        point('Covers both college admission and career growth'),
        point('Continuous support till placement'),
        point('Simple, easy-to-understand insights'),
        pw.SizedBox(height: 12),
        sectionTitle('Contact Details'),
        pw.SizedBox(height: 5),
        pw.Text(
          'Contact Us for More Guidance:',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: _textDark,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Phone: +91 86105 00872',
          style: const pw.TextStyle(
            fontSize: 11,
            color: PdfColor.fromInt(0xFF1F2937),
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'Email: nextepguidance@gmail.com',
          style: const pw.TextStyle(
            fontSize: 11,
            color: PdfColor.fromInt(0xFF1F2937),
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'Location: Chennai, Tamil Nadu',
          style: const pw.TextStyle(
            fontSize: 11,
            color: PdfColor.fromInt(0xFF1F2937),
          ),
        ),
        pw.Spacer(),
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                'Thank you for using NextStep Smart Guidance.',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _textDark,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Based on your profile, this report helps you choose the best path to your dream college and career.',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColor.fromInt(0xFF374151),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(
                color: PdfColor.fromInt(0x88A5C8EA),
                width: 0.7,
              ),
            ),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'Generated: ${_formatDate(generatedAt)}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'NeXtep Smart College Guidance',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Last Page',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _categoryBadge(String category) {
    final resolved = _safe(category).isEmpty ? 'N/A' : _safe(category);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFD8EAFF),
        borderRadius: pw.BorderRadius.circular(20),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFBEDBFB)),
      ),
      child: pw.Text(
        resolved,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: _brandBlue,
        ),
      ),
    );
  }

  static pw.Widget _recommendationBadge(String text, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF7FBFF),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: color),
      ),
      child: pw.Text(
        text.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  static PdfColor _tagColor(String bucket) {
    if (bucket == 'preferred') {
      return _preferredColor;
    }
    if (bucket == 'safe') {
      return _safeColor;
    }
    return _preferredColor;
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  static String _safe(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return '';
    }

    return trimmed
        .replaceAll(_unsupportedGlyphs, '?')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
