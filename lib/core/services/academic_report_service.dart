import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../database/app_database.dart';

class AcademicReportService {
  Future<Uint8List> generate() async {
    final db = await AppDatabase.instance.database;
    final profile = await db.query('profile', limit: 1);
    final courses = await db
        .rawQuery("""SELECT c.name,c.code,c.credit_hours,c.final_grade_letter,
COUNT(a.id) attendance_total,SUM(CASE WHEN a.status IN ('present','late') THEN 1 ELSE 0 END) attendance_present
FROM courses c LEFT JOIN attendance a ON a.course_id=c.id AND a.status!='cancelled' GROUP BY c.id ORDER BY c.name""");
    final tasks = await db.rawQuery(
        "SELECT COUNT(*) total,SUM(CASE WHEN status='completed' THEN 1 ELSE 0 END) completed FROM tasks");
    final grades = await db.query('courses',
        columns: ['credit_hours', 'final_grade_point'],
        where: 'final_grade_point IS NOT NULL');
    double credits = 0, points = 0;
    for (final g in grades) {
      final c = (g['credit_hours'] as num).toDouble();
      credits += c;
      points += c * (g['final_grade_point'] as num).toDouble();
    }
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        footer: (c) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Page ${c.pageNumber} of ${c.pagesCount}',
                style: const pw.TextStyle(fontSize: 9))),
        build: (_) => [
              pw.Text('StudyMate Academic Summary',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Text(
                  'Personal planning summary — not an official university transcript',
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey700)),
              pw.SizedBox(height: 18),
              pw.Text('Student',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text(profile.isEmpty
                  ? 'Not available'
                  : '${profile.first['name']}\n${profile.first['university'] ?? ''}\n${profile.first['program'] ?? ''}\n${profile.first['semester'] ?? ''}'),
              pw.SizedBox(height: 14),
              pw.Text('Overview',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text(
                  'GPA: ${credits == 0 ? 'Not available' : (points / credits).toStringAsFixed(2)}\nTasks: ${(tasks.first['completed'] as num?)?.toInt() ?? 0} completed of ${(tasks.first['total'] as num).toInt()}'),
              pw.SizedBox(height: 14),
              pw.Text('Courses',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.TableHelper.fromTextArray(
                  headers: ['Course', 'Credits', 'Attendance', 'Grade'],
                  data: courses.map((c) {
                    final total = (c['attendance_total'] as num).toInt(),
                        present =
                            (c['attendance_present'] as num?)?.toInt() ?? 0;
                    return [
                      '${c['name']}${c['code'] == null ? '' : ' (${c['code']})'}',
                      '${c['credit_hours']}',
                      total == 0
                          ? 'Not available'
                          : '${(present * 100 / total).toStringAsFixed(1)}%',
                      c['final_grade_letter'] ?? 'Not available'
                    ];
                  }).toList()),
              pw.SizedBox(height: 18),
              pw.Text(
                  'Generated ${DateFormat.yMMMMd().add_jm().format(DateTime.now())}',
                  style:
                      const pw.TextStyle(fontSize: 9, color: PdfColors.grey700))
            ]));
    return doc.save();
  }
}
