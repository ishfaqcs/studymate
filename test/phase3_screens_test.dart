import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentplanner/features/attendance/attendance_course_screen.dart';
import 'package:studentplanner/features/attendance/attendance_form_screen.dart';
import 'package:studentplanner/features/attendance/attendance_record.dart';
import 'package:studentplanner/features/attendance/attendance_repository.dart';
import 'package:studentplanner/features/attendance/attendance_screen.dart';
import 'package:studentplanner/features/courses/course_repository.dart';
import 'package:studentplanner/features/timetable/schedule_form_screen.dart';
import 'package:studentplanner/features/timetable/schedule_repository.dart';
import 'package:studentplanner/features/timetable/timetable_screen.dart';

import 'course_test_support.dart';
import 'phase3_test_support.dart';

Widget app(Widget child,
        {required MemoryScheduleRepository schedules,
        required MemoryAttendanceRepository attendance}) =>
    ProviderScope(
      overrides: [
        courseRepositoryProvider
            .overrideWithValue(MemoryCourseRepository([sampleCourse()])),
        scheduleRepositoryProvider.overrideWithValue(schedules),
        attendanceRepositoryProvider.overrideWithValue(attendance),
      ],
      child: MaterialApp(home: child),
    );

void largeView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('timetable shows an empty state', (tester) async {
    await tester.pumpWidget(app(const TimetableScreen(),
        schedules: MemoryScheduleRepository(),
        attendance: MemoryAttendanceRepository()));
    await tester.pumpAndSettle();
    expect(find.text('No classes scheduled'), findsOneWidget);
    expect(find.text('Add schedule'), findsWidgets);
  });

  testWidgets('timetable displays a scheduled class', (tester) async {
    await tester.pumpWidget(app(const TimetableScreen(),
        schedules: MemoryScheduleRepository([sampleSchedule()]),
        attendance: MemoryAttendanceRepository()));
    await tester.pumpAndSettle();
    expect(find.text('Artificial Intelligence'), findsOneWidget);
    expect(find.textContaining('CS-401'), findsOneWidget);
  });

  testWidgets('add schedule validates required fields', (tester) async {
    largeView(tester);
    await tester.pumpWidget(app(const ScheduleFormScreen(),
        schedules: MemoryScheduleRepository(),
        attendance: MemoryAttendanceRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save schedule'));
    await tester.pump();
    expect(find.text('Select a course'), findsOneWidget);
  });

  testWidgets('attendance course list shows no-data state', (tester) async {
    await tester.pumpWidget(app(const AttendanceScreen(),
        schedules: MemoryScheduleRepository(),
        attendance: MemoryAttendanceRepository()));
    await tester.pumpAndSettle();
    expect(find.text('No attendance data'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('attendance marking selects an explicit status', (tester) async {
    largeView(tester);
    await tester.pumpWidget(app(
        const AttendanceFormScreen(initialCourseId: 'course-1'),
        schedules: MemoryScheduleRepository(),
        attendance: MemoryAttendanceRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Present'));
    await tester.pump();
    final chip =
        tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Present'));
    expect(chip.selected, isTrue);
  });

  testWidgets('attendance insight renders safe-miss calculation',
      (tester) async {
    final records = List.generate(
        4,
        (index) => sampleAttendance(
            id: '$index',
            status: index == 3
                ? AttendanceStatus.absent
                : AttendanceStatus.present));
    await tester.pumpWidget(app(
        const AttendanceCourseScreen(courseId: 'course-1'),
        schedules: MemoryScheduleRepository(),
        attendance: MemoryAttendanceRepository(records)));
    await tester.pumpAndSettle();
    expect(find.text('75.0%'), findsOneWidget);
    expect(find.textContaining('You can miss'), findsOneWidget);
  });
}
