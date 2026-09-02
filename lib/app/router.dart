import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/academic/academic_screen.dart';
import '../features/courses/course_form_screen.dart';
import '../features/courses/course_details_screen.dart';
import '../features/courses/course.dart';
import '../features/courses/courses_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/more/more_screen.dart';
import '../features/more/privacy_screen.dart';
import '../features/more/about_screen.dart';
import '../features/notes/notes_screen.dart';
import '../features/notes/note.dart';
import '../features/documents/documents_screen.dart';
import '../features/documents/document_record.dart';
import '../features/search/global_search_screen.dart';
import '../features/settings/data_backup_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/semester_setup/semester_setup_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/tasks/task_form_screen.dart';
import '../features/tasks/tasks_screen.dart';
import '../features/tasks/academic_task.dart';
import '../features/grades/grades_screen.dart';
import '../features/grades/grade_form_screen.dart';
import '../features/grades/course_grades_screen.dart';
import '../features/grades/grading_scale_screen.dart';
import '../features/grades/academic_history_screen.dart';
import '../features/grades/grade_models.dart';
import '../features/timetable/timetable_screen.dart';
import '../features/timetable/schedule_form_screen.dart';
import '../features/timetable/class_schedule.dart';
import '../features/settings/settings_screen.dart';
import '../features/attendance/attendance_screen.dart';
import '../features/attendance/attendance_course_screen.dart';
import '../features/attendance/attendance_form_screen.dart';
import '../features/attendance/attendance_record.dart';
import '../features/v2_foundation/v2_placeholder_screen.dart';
import 'package:flutter/foundation.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/setup', builder: (_, __) => const SemesterSetupScreen()),
    ShellRoute(
      builder: (_, __, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const DashboardScreen()),
        GoRoute(path: '/schedule', builder: (_, __) => const TimetableScreen()),
        GoRoute(path: '/tasks', builder: (_, __) => const TasksScreen()),
        GoRoute(path: '/academic', builder: (_, __) => const AcademicScreen()),
        GoRoute(path: '/more', builder: (_, __) => const MoreScreen()),
      ],
    ),
    GoRoute(path: '/courses', builder: (_, __) => const CoursesScreen()),
    GoRoute(path: '/courses/add', builder: (_, __) => const CourseFormScreen()),
    GoRoute(
      path: '/courses/:id',
      builder: (_, state) =>
          CourseDetailsScreen(courseId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/courses/:id/edit',
      builder: (_, state) => CourseFormScreen(course: state.extra as Course?),
    ),
    GoRoute(path: '/attendance', builder: (_, __) => const AttendanceScreen()),
    GoRoute(
      path: '/attendance/add',
      builder: (_, state) => AttendanceFormScreen(
        initialCourseId: state.uri.queryParameters['course'],
        today: state.uri.queryParameters['today'] == 'true',
      ),
    ),
    GoRoute(
      path: '/attendance/record/:id/edit',
      builder: (_, state) => AttendanceFormScreen(
        record: state.extra as AttendanceRecord?,
      ),
    ),
    GoRoute(
      path: '/attendance/:courseId',
      builder: (_, state) => AttendanceCourseScreen(
        courseId: state.pathParameters['courseId']!,
      ),
    ),
    GoRoute(
      path: '/schedule/add',
      builder: (_, state) => ScheduleFormScreen(
        initialCourseId: state.uri.queryParameters['course'],
      ),
    ),
    GoRoute(
      path: '/schedule/:id/edit',
      builder: (_, state) => ScheduleFormScreen(
        schedule: state.extra as ClassSchedule?,
      ),
    ),
    GoRoute(
      path: '/tasks/add',
      builder: (_, state) => TaskFormScreen(
        initialCourseId: state.uri.queryParameters['course'],
      ),
    ),
    GoRoute(
      path: '/tasks/:id/edit',
      builder: (_, state) => TaskFormScreen(task: state.extra as AcademicTask?),
    ),
    GoRoute(path: '/grades', builder: (_, __) => const GradesScreen()),
    GoRoute(
      path: '/grades/add',
      builder: (_, state) => GradeFormScreen(
        initialCourseId: state.uri.queryParameters['course'],
      ),
    ),
    GoRoute(
      path: '/grades/record/:id/edit',
      builder: (_, state) => GradeFormScreen(
        assessment: state.extra as Assessment?,
      ),
    ),
    GoRoute(
      path: '/grades/:courseId',
      builder: (_, state) => CourseGradesScreen(
        courseId: state.pathParameters['courseId']!,
      ),
    ),
    GoRoute(
      path: '/grading-scale',
      builder: (_, __) => const GradingScaleScreen(),
    ),
    GoRoute(
      path: '/academic/history',
      builder: (_, __) => const AcademicHistoryScreen(),
    ),
    GoRoute(
        path: '/notes',
        builder: (_, state) =>
            NotesScreen(courseId: state.uri.queryParameters['course'])),
    GoRoute(
        path: '/notes/add',
        builder: (_, state) => NoteEditorScreen(
            initialCourseId: state.uri.queryParameters['course'])),
    GoRoute(
        path: '/notes/:id/edit',
        builder: (_, state) =>
            NoteEditorScreen(note: state.extra as StudyNote?)),
    GoRoute(
        path: '/documents',
        builder: (_, state) =>
            DocumentsScreen(courseId: state.uri.queryParameters['course'])),
    GoRoute(
        path: '/documents/add',
        builder: (_, state) => DocumentImportScreen(
            courseId: state.uri.queryParameters['course'])),
    GoRoute(
        path: '/documents/pdf',
        builder: (_, state) =>
            PdfViewerScreen(document: state.extra as DocumentRecord)),
    GoRoute(
        path: '/documents/:id',
        builder: (_, state) =>
            DocumentDetailsScreen(document: state.extra as DocumentRecord)),
    GoRoute(path: '/search', builder: (_, __) => const GlobalSearchScreen()),
    GoRoute(path: '/data-backup', builder: (_, __) => const DataBackupScreen()),
    GoRoute(path: '/privacy', builder: (_, __) => const PrivacyScreen()),
    GoRoute(path: '/about', builder: (_, __) => const AboutScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    for (final route in const {
      '/study-planner': 'Study Planner',
      '/study-session': 'Study Session',
      '/exam-prep': 'Exam Preparation',
      '/analytics': 'Analytics',
      '/grade-predictor': 'Grade Predictor',
      '/cloud-sync': 'Cloud Sync',
      '/ai-assistant': 'AI Assistant',
    }.entries)
      GoRoute(
        path: route.key,
        redirect: (_, __) => kReleaseMode ? '/more' : null,
        builder: (_, __) => V2PlaceholderScreen(route.value),
      ),
  ],
);

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const paths = ['/home', '/schedule', '/tasks', '/academic', '/more'];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = paths.indexOf(location).clamp(0, 4);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(paths[i]),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Schedule'),
          NavigationDestination(
              icon: Icon(Icons.task_alt_outlined),
              selectedIcon: Icon(Icons.task_alt),
              label: 'Tasks'),
          NavigationDestination(
              icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.school),
              label: 'Academic'),
          NavigationDestination(
              icon: Icon(Icons.more_horiz),
              selectedIcon: Icon(Icons.more_horiz),
              label: 'More'),
        ],
      ),
    );
  }
}
