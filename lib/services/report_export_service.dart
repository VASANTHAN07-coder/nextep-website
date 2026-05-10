import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:guidex/models/final_report_response.dart';
import 'package:guidex/models/recommendation.dart';

class ReportExportService {
  static const _bgStart = PdfColor.fromInt(0xFFEAF4FF);
  static const _bgEnd = PdfColor.fromInt(0xFFD6EBFF);
  static const _brand = PdfColor.fromInt(0xFF1E88E5);
  static const _dark = PdfColor.fromInt(0xFF1F2937);
  static const _cardBdr = PdfColor.fromInt(0xFFDCE8F7);
  static const _green = PdfColor.fromInt(0xFF43A047);
  static const _orange = PdfColor.fromInt(0xFFEF6C00);

  static const String _svgCourse =
      '<svg viewBox="0 0 24 24"><path fill="#1E88E5" d="M12 3 1 9l11 6 9-4.91V17h2V9L12 3zm-7 9.18V17l7 4 7-4v-4.82l-7 3.82-7-3.82z"/></svg>';
  static const String _svgLocation =
      '<svg viewBox="0 0 24 24"><path fill="#1E88E5" d="M12 2a7 7 0 0 0-7 7c0 5.16 7 13 7 13s7-7.84 7-13a7 7 0 0 0-7-7zm0 9.5A2.5 2.5 0 1 1 12 6a2.5 2.5 0 0 1 0 5.5z"/></svg>';
  static const String _svgStar =
      '<svg viewBox="0 0 24 24"><path fill="#1E88E5" d="m12 17.27 6.18 3.73-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg>';
  static const String _svgUser =
      '<svg viewBox="0 0 24 24"><path fill="#1E88E5" d="M12 12a5 5 0 1 0-5-5 5 5 0 0 0 5 5zm0 2c-4.42 0-8 2.24-8 5v2h16v-2c0-2.76-3.58-5-8-5z"/></svg>';
  static const String _svgInsight =
      '<svg viewBox="0 0 24 24"><path fill="#1E88E5" d="M19 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V5a2 2 0 0 0-2-2zM9 17H7v-7h2zm4 0h-2V7h2zm4 0h-2v-4h2z"/></svg>';

  static Future<void> exportToPDF({
    required String studentName,
    required double studentCutoff,
    required String category,
    required String preferredCourse,
    required List<dynamic> safeColleges,
    required List<dynamic> targetColleges,
    required List<dynamic> preferredColleges,
  }) async {
    final pdf = pw.Document();
    pw.MemoryImage? logo;
    try {
      final ByteData data = await rootBundle.load('assets/image/nextstep_splash_logo.png');
      final bytes = data.buffer.asUint8List();
      logo = pw.MemoryImage(bytes);
    } catch (_) {}
    final now = DateTime.now();
    final date =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final total =
        preferredColleges.length + targetColleges.length + safeColleges.length;

    pdf.addPage(pw.MultiPage(
      maxPages: 100,
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 20, 24, 28),
        buildBackground: (_) => _bg(),
        theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(), bold: pw.Font.helveticaBold()),
      ),
      header: (_) => _logoHeader(logo),
      footer: (ctx) => _footer(date, ctx, logo),
      build: (_) => [
        _banner(logo),
        pw.SizedBox(height: 12),
        _studentCard(studentName, studentCutoff, category, preferredCourse),
        pw.SizedBox(height: 12),
        _insightCard(total, preferredColleges.length, targetColleges.length),
        pw.SizedBox(height: 14),
        if (preferredColleges.isNotEmpty) ...[
          ..._section(
              'Student Preferred Colleges',
              'Colleges selected by you for direct comparison',
              _brand,
              preferredColleges,
              'preferred'),
          pw.SizedBox(height: 10),
        ],
        if (safeColleges.isNotEmpty) ...[
          ..._section('Preferred Choices', 'Higher probability options for secure admission',
              _green, safeColleges, 'safe'),
          pw.SizedBox(height: 10),
        ],
        if (targetColleges.isNotEmpty) ...[
          ..._section('Target Colleges', 'Strong probability of admission',
              _orange, targetColleges, 'target'),
          pw.SizedBox(height: 10),
        ],
      ],
    ));

    // Last page
    pdf.addPage(pw.Page(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 20, 24, 28),
        buildBackground: (_) => _bg(),
        theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(), bold: pw.Font.helveticaBold()),
      ),
      build: (_) => _lastPage(logo, date),
    ));

    await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        name: '${studentName}_NeXtep_Report.pdf');
  }

  // ── Background gradient ──
  static pw.Widget _bg() => pw.FullPage(
      ignoreMargins: true,
      child: pw.Container(
        decoration: const pw.BoxDecoration(
            gradient: pw.LinearGradient(
                colors: [_bgStart, _bgEnd],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight)),
      ));

  // ── Small logo top-right ──
  static pw.Widget _logoHeader(pw.MemoryImage? logo) {
    if (logo == null) return pw.SizedBox();
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
              border: pw.Border.all(color: const PdfColor.fromInt(0x88C3DBF4))),
          child: pw.Image(logo, fit: pw.BoxFit.contain)),
    );
  }

  // ── Blue banner ──
  static pw.Widget _banner(pw.MemoryImage? logo) => pw.Container(
        padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: pw.BoxDecoration(
            gradient: const pw.LinearGradient(colors: [
              PdfColor.fromInt(0xFF42A5F5),
              PdfColor.fromInt(0xFF1E88E5)
            ]),
            borderRadius: pw.BorderRadius.circular(14)),
        child: pw.Row(children: [
          if (logo != null) ...[
            pw.Container(
                width: 58,
                height: 40,
                padding: const pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0x26FFFFFF),
                    borderRadius: pw.BorderRadius.circular(8)),
                child: pw.Image(logo, fit: pw.BoxFit.contain)),
            pw.SizedBox(width: 10),
          ],
          pw.Expanded(
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                pw.Text('College Analysis Report',
                    style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
                pw.SizedBox(height: 3),
                pw.Text('Based on your cutoff and preferences',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.white)),
              ])),
        ]),
      );

  // ── Student summary ──
  static pw.Widget _studentCard(
          String name, double cutoff, String cat, String course) =>
      pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(12),
            border: pw.Border.all(color: _cardBdr)),
        child: pw
            .Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Row(children: [
            _iconLabel(_svgUser, 'Student Summary', _brand, 12),
            pw.Spacer(),
            pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFD8EAFF),
                    borderRadius: pw.BorderRadius.circular(20)),
                child: pw.Text(cat.toUpperCase(),
                    style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: _brand))),
          ]),
          pw.SizedBox(height: 10),
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Expanded(
                flex: 2,
                child: _field('Name', name.isEmpty ? 'Student' : name)),
            pw.SizedBox(width: 10),
            pw.Expanded(
                child: pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFEAF4FF),
                  borderRadius: pw.BorderRadius.circular(10)),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _iconLabel(_svgInsight, 'Cutoff', PdfColors.grey700, 9),
                    pw.SizedBox(height: 4),
                    pw.Text(cutoff.toStringAsFixed(1),
                        style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: _brand)),
                  ]),
            )),
          ]),
          pw.SizedBox(height: 10),
          _field('Selected Course', course.isEmpty ? 'Not provided' : course),
        ]),
      );

  static pw.Widget _field(String label, String value) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFF7FAFE),
            borderRadius: pw.BorderRadius.circular(10),
            border: pw.Border.all(color: const PdfColor.fromInt(0xFFE3EEFA))),
        child: pw
            .Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(label,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.SizedBox(height: 3),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold, color: _dark)),
        ]),
      );

  // ── Overall insight ──
  static pw.Widget _insightCard(int total, int pref, int target) =>
      pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFEAF4FF),
            borderRadius: pw.BorderRadius.circular(12),
            border: pw.Border.all(color: const PdfColor.fromInt(0xFFD0E4FB))),
        child: pw
            .Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          _iconLabel(_svgInsight, 'Overall Insight', _brand, 13),
          pw.SizedBox(height: 8),
          pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Row(children: [
                pw.Text('$total',
                    style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: _brand)),
                pw.SizedBox(width: 8),
                pw.Text('Total Matching Colleges',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey800)),
              ])),
          pw.SizedBox(height: 8),
          pw.Bullet(
              text: 'Preferred choices: $pref',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
          pw.Bullet(
              text: 'Target colleges: $target',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
        ]),
      );

  // ── Section with two-column grid ──
  static List<pw.Widget> _section(String title, String sub, PdfColor color,
      List<dynamic> items, String bucket) {
    return [
      pw.Container(
        padding: const pw.EdgeInsets.only(left: 10),
        decoration: pw.BoxDecoration(
            border: pw.Border(left: pw.BorderSide(color: color, width: 4))),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title,
                  style: pw.TextStyle(
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                      color: color)),
              pw.SizedBox(height: 3),
              pw.Text(sub,
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey700)),
            ]),
      ),
      pw.SizedBox(height: 8),
      if (items.isEmpty)
        pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: _cardBdr)),
            child: pw.Text('No colleges in this section.',
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)))
      else
        _grid(items, bucket),
    ];
  }

  // ── Two-column grid ──
  static pw.Widget _grid(List<dynamic> items, String bucket) {
    final rows = <pw.TableRow>[];
    for (var i = 0; i < items.length; i += 2) {
      final left = items[i];
      final right = i + 1 < items.length ? items[i + 1] : null;
      rows.add(pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.top,
          children: [
            pw.Padding(
                padding: const pw.EdgeInsets.only(right: 8, bottom: 8),
                child: _card(left, bucket)),
            pw.Padding(
                padding: const pw.EdgeInsets.only(left: 8, bottom: 8),
                child: right != null ? _card(right, bucket) : pw.Container()),
          ]));
    }
    return pw.Table(columnWidths: const {
      0: pw.FlexColumnWidth(1),
      1: pw.FlexColumnWidth(1)
    }, children: rows);
  }

  // ── College card ──
  static pw.Widget _card(dynamic c, String bucket) {
    String name = '';
    String course = '';
    double cutoff = 0.0;
    double score = 0.0;
    String district = 'N/A';

    if (c is TargetCollegeResponse) {
      name = c.collegeName;
      course = c.course;
      cutoff = c.cutoff;
      score = c.scorePercentage;
      district = c.district ?? 'N/A';
    } else if (c is SafeCollegeResponse) {
      name = c.collegeName;
      course = c.course;
      cutoff = c.collegeCutoff;
      score = c.probability;
      district = c.district ?? 'N/A';
    } else if (c is Recommendation) {
      name = c.collegeName;
      course = c.courseName;
      cutoff = c.cutoff;
      score = c.probability.toDouble();
      district = c.district ?? 'N/A';
    } else {
      try {
        name = c.collegeName ?? '';
        course = c.courseName ?? (c.course ?? '');
        cutoff = c.cutoff ?? (c.collegeCutoff ?? 0.0);
        score = c.probability ?? 0.0;
        district = c.district ?? 'N/A';
      } catch (_) {}
    }

    final pct = score.clamp(0, 100).toInt();
    final color = bucket == 'preferred' ? _brand : (bucket == 'safe' ? _green : _orange);
    if (district.isEmpty) district = 'N/A';

    return pw.Container(
      constraints: const pw.BoxConstraints(minHeight: 132),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(10),
          border: pw.Border.all(color: _cardBdr)),
      child:
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(
              child: pw.Text(name,
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _dark))),
          pw.SizedBox(width: 6),
          pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFF7FBFF),
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(color: color)),
              child: pw.Text(bucket.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                      color: color))),
        ]),
        pw.SizedBox(height: 6),
        _iconLine(_svgCourse, course, 9),
        pw.SizedBox(height: 4),
        _iconLine(_svgLocation, district, 9),
        pw.SizedBox(height: 4),
        _iconLine(_svgStar, 'Cutoff: ${cutoff.toStringAsFixed(2)}', 9),
        pw.SizedBox(height: 6),
        pw.Row(children: [
          _progressBar(pct, color),
          pw.SizedBox(width: 6),
          pw.Text('$pct%',
              style: pw.TextStyle(
                  fontSize: 8, fontWeight: pw.FontWeight.bold, color: color)),
        ]),
      ]),
    );
  }

  static pw.Widget _iconLine(String svg, String text, double sz) =>
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.SizedBox(width: 10, height: 10, child: pw.SvgImage(svg: svg)),
        pw.SizedBox(width: 4),
        pw.Expanded(
            child: pw.Text(text,
                style: pw.TextStyle(fontSize: sz, color: PdfColors.grey800))),
      ]);

  static pw.Widget _iconLabel(
          String svg, String text, PdfColor color, double sz) =>
      pw.Row(children: [
        pw.SizedBox(width: 12, height: 12, child: pw.SvgImage(svg: svg)),
        pw.SizedBox(width: 5),
        pw.Text(text,
            style: pw.TextStyle(
                fontSize: sz, fontWeight: pw.FontWeight.bold, color: color)),
      ]);

  static pw.Widget _progressBar(int value, PdfColor color) {
    const w = 92.0, h = 6.0;
    return pw.Container(
      width: w,
      height: h,
      decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFFE5EDF6),
          borderRadius: pw.BorderRadius.circular(4)),
      child: pw.Align(
          alignment: pw.Alignment.centerLeft,
          child: pw.Container(
              width: w * (value.clamp(0, 100) / 100.0),
              height: h,
              decoration: pw.BoxDecoration(
                  color: color, borderRadius: pw.BorderRadius.circular(4)))),
    );
  }

  // ── Footer ──
  static pw.Widget _footer(String date, pw.Context ctx, pw.MemoryImage? logo) =>
      pw.Container(
        margin: const pw.EdgeInsets.only(top: 8),
        padding: const pw.EdgeInsets.only(top: 6),
        decoration: const pw.BoxDecoration(
            border: pw.Border(
                top: pw.BorderSide(
                    color: PdfColor.fromInt(0x88A5C8EA), width: 0.7))),
        child: pw.Stack(children: [
          if (logo != null)
            pw.Positioned(
                right: 0,
                top: -2,
                child: pw.Opacity(
                    opacity: 0.08,
                    child: pw.Image(logo, width: 52, fit: pw.BoxFit.contain))),
          pw.Row(children: [
            pw.Expanded(
                child: pw.Text('Generated: $date',
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColors.grey700))),
            pw.Expanded(
                child: pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text('NeXtep | Smart College Guidance',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey700)))),
            pw.Expanded(
                child: pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey700)))),
          ]),
        ]),
      );

  // ── Company last page ──
  static pw.Widget _lastPage(pw.MemoryImage? logo, String date) {
    pw.Widget h(String t) => pw.Text(t,
        style: pw.TextStyle(
            fontSize: 19, fontWeight: pw.FontWeight.bold, color: _dark));
    pw.Widget b(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Text('> $t',
            style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColor.fromInt(0xFF1F2937),
                lineSpacing: 1.2)));

    return pw
        .Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      _logoHeader(logo),
      pw.SizedBox(height: 4),
      pw.Row(children: [
        pw.Container(
            width: 4,
            height: 20,
            decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFF21A34A),
                borderRadius: pw.BorderRadius.circular(3))),
        pw.SizedBox(width: 8),
        h('Your Journey Starts Here'),
      ]),
      pw.SizedBox(height: 8),
      pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF4F4F4),
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFE3E3E3))),
          child: pw.Text('NeXtep Guidance',
              style: pw.TextStyle(
                  fontSize: 18, fontWeight: pw.FontWeight.bold, color: _dark))),
      pw.SizedBox(height: 12),
      h('What NeXtep Will Do For You'),
      pw.SizedBox(height: 5),
      b('College selection strategy based on your cutoff and category'),
      b('Step-by-step guidance for TNEA counselling process'),
      b('Course and career roadmap based on your interests'),
      b('Skill development and recommended courses'),
      b('Placement preparation (resume, aptitude, interviews)'),
      b('Guidance for competitive exams (GATE, UPSC, Banking, etc.)'),
      pw.SizedBox(height: 12),
      h('How We Guide You (Process Section)'),
      pw.SizedBox(height: 5),
      b('Profile analysis - cutoff, interests, and background review'),
      b('Smart prediction - estimate your admission chances'),
      b('College shortlisting - dream, target, and safe colleges'),
      b('Counselling support - step-by-step TNEA application guidance'),
      b('Career growth plan - skills, courses, and placement roadmap'),
      pw.SizedBox(height: 12),
      h('Why Choose Us'),
      pw.SizedBox(height: 5),
      b('Data-driven college prediction system'),
      b('Personalized guidance, not generic advice'),
      b('Covers both college admission and career growth'),
      b('Continuous support till placement'),
      b('Simple, easy-to-understand insights'),
      pw.SizedBox(height: 12),
      h('Contact Details'),
      pw.SizedBox(height: 5),
      pw.Text('Contact Us for More Guidance:',
          style: pw.TextStyle(
              fontSize: 12, fontWeight: pw.FontWeight.bold, color: _dark)),
      pw.SizedBox(height: 4),
      pw.Text('Phone: +91 86105 00872',
          style: const pw.TextStyle(
              fontSize: 11, color: PdfColor.fromInt(0xFF1F2937))),
      pw.SizedBox(height: 2),
      pw.Text('Email: nextepguidance@gmail.com',
          style: const pw.TextStyle(
              fontSize: 11, color: PdfColor.fromInt(0xFF1F2937))),
      pw.SizedBox(height: 2),
      pw.Text('Location: Chennai, Tamil Nadu',
          style: const pw.TextStyle(
              fontSize: 11, color: PdfColor.fromInt(0xFF1F2937))),
      pw.Spacer(),
      pw.Center(
          child: pw.Column(children: [
        pw.Text('Thank you for using NeXtep Smart Guidance.',
            style: pw.TextStyle(
                fontSize: 11, fontWeight: pw.FontWeight.bold, color: _dark)),
        pw.SizedBox(height: 2),
        pw.Text(
            'Based on your profile, this report helps you choose the best path to your dream college and career.',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(
                fontSize: 10, color: PdfColor.fromInt(0xFF374151))),
      ])),
      pw.SizedBox(height: 8),
      pw.Container(
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: const pw.BoxDecoration(
              border: pw.Border(
                  top: pw.BorderSide(
                      color: PdfColor.fromInt(0x88A5C8EA), width: 0.7))),
          child: pw.Row(children: [
            pw.Expanded(
                child: pw.Text('Generated: $date',
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColors.grey700))),
            pw.Expanded(
                child: pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text('NeXtep Smart College Guidance',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey700)))),
            pw.Expanded(
                child: pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text('Last Page',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey700)))),
          ])),
    ]);
  }

  // ── PNG export (unchanged) ──
  static Future<void> exportToPNG(
      {required GlobalKey boundaryKey, required String fileName}) async {
    try {
      RenderRepaintBoundary? boundary = boundaryKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        Uint8List pngBytes = byteData.buffer.asUint8List();
        await Printing.sharePdf(
            bytes: await _convertImageToPdf(pngBytes),
            filename: '$fileName.pdf');
      }
    } catch (e) {
      debugPrint('Error exporting PNG: $e');
    }
  }

  static Future<Uint8List> _convertImageToPdf(Uint8List imageBytes) async {
    final pdf = pw.Document();
    final image = pw.MemoryImage(imageBytes);
    pdf.addPage(pw.Page(
        build: (pw.Context context) => pw.Center(child: pw.Image(image))));
    return pdf.save();
  }
}
