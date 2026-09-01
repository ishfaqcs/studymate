import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'course.dart';
import 'course_repository.dart';

class CourseFormScreen extends ConsumerStatefulWidget {
  const CourseFormScreen({super.key, this.course});
  final Course? course;

  @override
  ConsumerState<CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends ConsumerState<CourseFormScreen> {
  static const palette = <int>[
    0xFF3457D5,
    0xFF287D6E,
    0xFF8A5A00,
    0xFF7A4FA3,
    0xFF9A4050,
    0xFF3D6F8E,
  ];
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController code;
  late final TextEditingController instructor;
  late final TextEditingController room;
  late final TextEditingController credits;
  late final TextEditingController attendance;
  late int colorValue;
  bool saving = false;

  bool get editing => widget.course != null;

  @override
  void initState() {
    super.initState();
    final course = widget.course;
    name = TextEditingController(text: course?.name);
    code = TextEditingController(text: course?.code);
    instructor = TextEditingController(text: course?.instructor);
    room = TextEditingController(text: course?.room);
    credits = TextEditingController(
        text: course == null ? '3' : _number(course.creditHours));
    attendance = TextEditingController(
        text: course == null ? '' : _number(course.requiredAttendance));
    colorValue = course?.colorValue ?? palette.first;
    if (course == null) _loadDefaultAttendance();
  }

  Future<void> _loadDefaultAttendance() async {
    final value = await ref.read(courseRepositoryProvider).defaultAttendance();
    if (mounted && attendance.text.isEmpty) attendance.text = _number(value);
  }

  static String _number(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);

  @override
  void dispose() {
    for (final controller in [
      name,
      code,
      instructor,
      room,
      credits,
      attendance
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => saving = true);
    final repository = ref.read(courseRepositoryProvider);
    final old = widget.course;
    try {
      final course = Course(
        id: old?.id ?? const Uuid().v4(),
        semesterId: old?.semesterId ?? await repository.activeSemesterId(),
        name: name.text.trim(),
        code: code.text,
        instructor: instructor.text,
        room: room.text,
        creditHours: double.parse(credits.text.trim()),
        requiredAttendance: double.parse(attendance.text.trim()),
        colorValue: colorValue,
        createdAt: old?.createdAt ?? DateTime.now(),
      );
      editing
          ? await repository.update(course)
          : await repository.create(course);
      ref.invalidate(coursesProvider);
      ref.invalidate(courseProvider(course.id));
      if (mounted) context.pop(course);
    } catch (_) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course could not be saved. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(editing ? 'Edit course' : 'Add course')),
        body: SafeArea(
          child: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                _textField(name, 'Course name *', required: true),
                const SizedBox(height: 12),
                _textField(code, 'Course code', capitals: true),
                const SizedBox(height: 12),
                _textField(instructor, 'Instructor'),
                const SizedBox(height: 12),
                _textField(room, 'Room / location'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: credits,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  ],
                  decoration:
                      const InputDecoration(labelText: 'Credit hours *'),
                  validator: (value) {
                    final number = double.tryParse(value?.trim() ?? '');
                    if (number == null) {
                      return 'Enter valid credit hours';
                    }
                    if (number <= 0 || number > 30) {
                      return 'Credit hours must be between 0 and 30';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text('Attendance requirement',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [70, 75, 80, 85]
                      .map((value) => ChoiceChip(
                            label: Text('$value%'),
                            selected: attendance.text == '$value',
                            onSelected: (_) =>
                                setState(() => attendance.text = '$value'),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: attendance,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  ],
                  decoration: const InputDecoration(
                      labelText: 'Custom percentage', suffixText: '%'),
                  validator: validateAttendance,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),
                Text('Course color',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: palette.map(_colorChoice).toList()),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: saving ? null : save,
                  child: Text(saving
                      ? 'Saving…'
                      : editing
                          ? 'Save changes'
                          : 'Save course'),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _textField(TextEditingController controller, String label,
      {bool required = false, bool capitals = false}) {
    return TextFormField(
      controller: controller,
      textCapitalization:
          capitals ? TextCapitalization.characters : TextCapitalization.words,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (value) => value == null || value.trim().isEmpty
              ? 'Course name is required'
              : null
          : null,
    );
  }

  Widget _colorChoice(int value) {
    final selected = colorValue == value;
    return Semantics(
      label: 'Course color${selected ? ', selected' : ''}',
      button: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => setState(() => colorValue = value),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Color(value),
            shape: BoxShape.circle,
            border: selected
                ? Border.all(
                    color: Theme.of(context).colorScheme.onSurface, width: 3)
                : null,
          ),
          child: selected ? const Icon(Icons.check, color: Colors.white) : null,
        ),
      ),
    );
  }
}
