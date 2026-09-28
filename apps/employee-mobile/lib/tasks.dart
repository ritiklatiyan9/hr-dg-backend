import 'ui/icons.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'attendance.dart';
import 'mobile_ui.dart';
import 'providers.dart';
import 'scope.dart';
import 'ui/components.dart';
import 'workspace.dart';

enum TaskFilter { today, upcoming, completed, all }

String priorityLabel(String p) => tr(
  const {
        'low': 'Low',
        'normal': 'Normal',
        'high': 'High',
        'urgent': 'Urgent',
      }[p] ??
      p,
  const {
        'low': 'कम',
        'normal': 'सामान्य',
        'high': 'उच्च',
        'urgent': 'अत्यावश्यक',
      }[p] ??
      p,
);

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key, required this.scope});
  final SiteScope scope;
  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  TaskFilter? filter;
  late final poller = VisiblePoller(
    const Duration(seconds: 30),
    () =>
        ref.read(operationsProvider(widget.scope).notifier).load(silent: true),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    poller.start(context);
  }

  @override
  void dispose() {
    poller.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = widget.scope;
    final ops = ref.watch(operationsProvider(scope));
    final caps =
        ref.watch(capabilityProvider(scope)).value?.scope.capabilities ??
        const <String>[];
    final canAssign =
        caps.contains('tasks.create') &&
        ops.assignable.isNotEmpty &&
        !ops.offline;
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final names = {
      for (final e in ops.assignable) e.id as String: e.displayName as String,
    };
    List<Json> select(TaskFilter f) =>
        ops.tasks.where((t) {
            final done = t['status'] == 'done';
            final due = parseInstant(t['deadline']);
            return switch (f) {
              TaskFilter.today =>
                !done && (due == null || !due.isAfter(endOfDay)),
              TaskFilter.upcoming =>
                !done && due != null && due.isAfter(endOfDay),
              TaskFilter.completed => done,
              TaskFilter.all => true,
            };
          }).toList()
          ..sort((a, b) => '${a['deadline']}'.compareTo('${b['deadline']}'));
    // Land on the first list that has work in it.
    final effective =
        filter ??
        [TaskFilter.today, TaskFilter.upcoming, TaskFilter.all].firstWhere(
          (f) => select(f).isNotEmpty,
          orElse: () => TaskFilter.today,
        );
    final rows = select(effective);
    return PageScaffold(
      title: tr('Tasks', 'कार्य'),
      actions: [
        if (canAssign)
          IconButton(
            tooltip: tr('Assign task', 'कार्य सौंपें'),
            onPressed: () => context.go('/work/tasks/assign'),
            icon: const AppIcon(AppIcons.listPlus),
          ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              4,
              Space.gutter,
              4,
            ),
            child: FilterBar<TaskFilter>(
              value: effective,
              onChanged: (v) => setState(() => filter = v),
              items: [
                (TaskFilter.today, tr('Today', 'आज')),
                (TaskFilter.upcoming, tr('Upcoming', 'आगामी')),
                (TaskFilter.completed, tr('Completed', 'पूर्ण')),
                (TaskFilter.all, tr('All', 'सभी')),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(operationsProvider(scope).notifier).load(),
              child: !ops.loaded
                  ? ListView(
                      padding: Space.page,
                      children: [
                        if (ops.error != null)
                          InlineError(
                            ops.error!,
                            retry: () => ref
                                .read(operationsProvider(scope).notifier)
                                .load(),
                          )
                        else
                          const LoadingState(rows: 4, header: false),
                      ],
                    )
                  : rows.isEmpty
                  ? ListView(
                      padding: Space.page,
                      children: [
                        if (ops.offline)
                          NoticeBanner(
                            tr(
                              'Offline · showing tasks saved for this site.',
                              'ऑफ़लाइन · इस साइट के सहेजे कार्य दिख रहे हैं।',
                            ),
                            tone: StatusTone.warning,
                          ),
                        EmptyState(
                          title: switch (effective) {
                            TaskFilter.today => tr(
                              'Nothing due today',
                              'आज कुछ देय नहीं',
                            ),
                            TaskFilter.upcoming => tr(
                              'No upcoming tasks',
                              'कोई आगामी कार्य नहीं',
                            ),
                            TaskFilter.completed => tr(
                              'No completed tasks yet',
                              'अभी कोई पूर्ण कार्य नहीं',
                            ),
                            TaskFilter.all => tr(
                              'No tasks assigned',
                              'कोई कार्य नहीं',
                            ),
                          },
                          message: tr(
                            'Tasks appear here when your authorized team assigns work.',
                            'जब आपकी टीम काम सौंपती है तो कार्य यहाँ दिखते हैं।',
                          ),
                          illustration: TinyKind.clipboard,
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: Space.page,
                      itemCount: rows.length + (ops.offline ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (ops.offline && i == 0) {
                          return NoticeBanner(
                            tr(
                              'Offline · status changes are online-only; comments are queued.',
                              'ऑफ़लाइन · स्थिति बदलाव केवल ऑनलाइन; टिप्पणियाँ कतार में।',
                            ),
                            tone: StatusTone.warning,
                          );
                        }
                        final t = rows[ops.offline ? i - 1 : i];
                        final due = parseInstant(t['deadline']);
                        final overdue =
                            due != null &&
                            due.isBefore(now) &&
                            t['status'] != 'done';
                        final assignee = t['employee_id'] != ops.me
                            ? names[t['employee_id']]
                            : null;
                        return _TaskRow(
                          task: t,
                          subtitle: [
                            if (due != null)
                              '${overdue ? tr('Overdue', 'देरी') : tr('Due', 'देय')} ${formatInstant(context, t['deadline'])}',
                            ?assignee,
                          ].join(' · '),
                          overdue: overdue,
                          divider: i < rows.length - 1 + (ops.offline ? 1 : 0),
                          onTap: () => context.go('/work/tasks/${t['id']}'),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.subtitle,
    required this.overdue,
    required this.onTap,
    required this.divider,
  });
  final Json task;
  final String subtitle;
  final bool overdue, divider;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final priority = '${task['priority']}';
    final done = task['status'] == 'done';
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.s),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIcon(
                  done ? AppIcons.circleCheck : AppIcons.circle,
                  color: done ? t.success : t.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${task['title']}',
                        style: text.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: text.bodySmall?.copyWith(
                          color: overdue ? t.error : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [
                          StatusPill.status('${task['status']}'),
                          if (priority == 'high' || priority == 'urgent')
                            StatusPill(
                              priorityLabel(priority),
                              tone: priority == 'urgent'
                                  ? StatusTone.error
                                  : StatusTone.warning,
                              icon: AppIcons.badgeAlert,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppIcon(AppIcons.chevronRight, color: t.textSecondary),
              ],
            ),
          ),
        ),
        if (divider) const Divider(),
      ],
    );
  }
}

class TaskDetailPage extends ConsumerStatefulWidget {
  const TaskDetailPage({super.key, required this.scope, required this.id});
  final SiteScope scope;
  final String id;
  @override
  ConsumerState<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends ConsumerState<TaskDetailPage> {
  late final UnsavedWork unsaved;
  @override
  void initState() {
    super.initState();
    unsaved = ref.read(unsavedWorkProvider);
  }

  final comment = TextEditingController();
  bool sending = false;
  Object? error;
  @override
  void dispose() {
    unsaved.mark('task-comment', '', false);
    comment.dispose();
    super.dispose();
  }

  Future<void> send(Json task) async {
    final body = comment.text.trim();
    if (body.isEmpty) return;
    final controller = ref.read(operationsProvider(widget.scope).notifier);
    setState(() {
      sending = true;
      error = null;
    });
    final input = {
      'clientId': const Uuid().v4(),
      'taskId': task['id'],
      'body': body,
    };
    try {
      final ops = ref.read(operationsProvider(widget.scope));
      if (ops.offline) {
        await controller.runtime.enqueue(widget.scope, 'comment', input);
        if (mounted) {
          showConfirmation(
            context,
            tr(
              'Comment saved on this device. It will sync when online.',
              'टिप्पणी इस डिवाइस पर सहेजी। ऑनलाइन होने पर सिंक होगी।',
            ),
          );
        }
      } else {
        await controller.command('comment', input);
        if (mounted) {
          showConfirmation(context, tr('Comment added', 'टिप्पणी जोड़ी गई'));
        }
      }
      comment.clear();
      unsaved.mark('task-comment', '', false);
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> attach(Json task) async {
    final controller = ref.read(operationsProvider(widget.scope).notifier);
    XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 90,
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => error = StateError(
            tr(
              'Camera is unavailable. Allow camera access and try again.',
              'कैमरा उपलब्ध नहीं। अनुमति दें और फिर कोशिश करें।',
            ),
          ),
        );
      }
      return;
    }
    if (file == null) return;
    setState(() {
      sending = true;
      error = null;
    });
    try {
      final bytes = await file.readAsBytes();
      final intent = await controller.command('fileIntent', {
        'clientId': const Uuid().v4(),
        'purpose': 'task',
        'parentId': task['id'],
        'type': 'image/jpeg',
        'bytes': bytes.length,
      });
      await ref
          .read(apiProvider)
          .uploadOperationPhoto(widget.scope, intent['id'] as String, bytes);
      await controller.command('comment', {
        'clientId': const Uuid().v4(),
        'taskId': task['id'],
        'body': tr('Photo attachment', 'फोटो संलग्नक'),
        'attachmentId': intent['id'],
      });
      if (mounted) {
        showConfirmation(context, tr('Photo attached', 'फोटो संलग्न हुई'));
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      final cached = File(file.path);
      if (await cached.exists()) await cached.delete();
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = widget.scope;
    final ops = ref.watch(operationsProvider(scope));
    final controller = ref.read(operationsProvider(scope).notifier);
    final task = ops.tasks.where((t) => '${t['id']}' == widget.id).firstOrNull;
    final text = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    if (!ops.loaded) {
      return PageScaffold(
        title: tr('Task', 'कार्य'),
        body: ListView(
          padding: Space.page,
          children: [
            if (ops.error != null)
              InlineError(ops.error!, retry: controller.load)
            else
              const LoadingState(rows: 3),
          ],
        ),
      );
    }
    if (task == null) {
      return PageScaffold(
        title: tr('Task', 'कार्य'),
        body: ListView(
          padding: Space.page,
          children: [
            EmptyState(
              title: tr('Task unavailable', 'कार्य उपलब्ध नहीं'),
              message: tr(
                'It may belong to another site or is no longer assigned to you.',
                'यह दूसरी साइट का हो सकता है या अब आपको सौंपा नहीं है।',
              ),
              illustration: TinyKind.clipboard,
            ),
          ],
        ),
      );
    }
    final comments =
        ops.comments.where((c) => c['task_id'] == task['id']).toList()..sort(
          (a, b) => '${a['created_at']}'.compareTo('${b['created_at']}'),
        );
    final due = parseInstant(task['deadline']);
    final overdue =
        due != null && due.isBefore(DateTime.now()) && task['status'] != 'done';
    final names = {
      for (final e in ops.assignable) e.id as String: e.displayName as String,
    };
    return PageScaffold(
      title: tr('Task', 'कार्य'),
      body: ListView(
        padding: Space.page,
        children: [
          Text('${task['title']}', style: text.headlineSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusPill.status('${task['status']}'),
              StatusPill(
                priorityLabel('${task['priority']}'),
                tone: task['priority'] == 'urgent'
                    ? StatusTone.error
                    : task['priority'] == 'high'
                    ? StatusTone.warning
                    : StatusTone.neutral,
              ),
              if (due != null)
                StatusPill(
                  '${overdue ? tr('Overdue', 'देरी') : tr('Due', 'देय')} ${formatInstant(context, task['deadline'])}',
                  tone: overdue ? StatusTone.error : StatusTone.neutral,
                  icon: AppIcons.calendarDays,
                ),
              if (task['employee_id'] != ops.me &&
                  names[task['employee_id']] != null)
                StatusPill(
                  names[task['employee_id']]!,
                  icon: AppIcons.userRound,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${task['description'] ?? ''}'.isEmpty
                ? tr('No description.', 'कोई विवरण नहीं।')
                : '${task['description']}',
            style: text.bodyLarge,
          ),
          SectionHeader(tr('Progress', 'प्रगति')),
          if (ops.offline)
            Text(
              tr(
                'Status changes are online-only.',
                'स्थिति बदलाव केवल ऑनलाइन।',
              ),
              style: text.bodySmall,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in ['todo', 'in_progress', 'blocked', 'done'])
                  ChoiceChip(
                    label: Text(statusLabel(s)),
                    selected: task['status'] == s,
                    onSelected: ops.busy || task['status'] == s
                        ? null
                        : (_) async {
                            try {
                              await controller.command('taskStatus', {
                                'id': task['id'],
                                'expectedVersion': task['version'],
                                'status': s,
                              });
                              if (context.mounted) {
                                showConfirmation(
                                  context,
                                  '${tr('Status', 'स्थिति')}: ${statusLabel(s)}',
                                );
                              }
                            } catch (e) {
                              if (context.mounted) setState(() => error = e);
                            }
                          },
                  ),
              ],
            ),
          if (error != null) InlineError(error!),
          SectionHeader(tr('Comments & attachments', 'टिप्पणियाँ और संलग्नक')),
          if (comments.isEmpty)
            Text(
              tr('No comments yet.', 'अभी कोई टिप्पणी नहीं।'),
              style: text.bodySmall,
            ),
          for (final (i, c) in comments.indexed)
            TimelineRow(
              time: formatTime(context, c['created_at']),
              title: '${c['body']}',
              subtitle: formatDay(
                context,
                parseInstant(
                  c['created_at'],
                )?.toIso8601String().substring(0, 10),
              ),
              kind: c['attachment_id'] == null
                  ? TimelineKind.neutral
                  : TimelineKind.visit,
              first: i == 0,
              last: i == comments.length - 1,
              trailing: c['attachment_id'] == null
                  ? null
                  : IconButton.outlined(
                      tooltip: tr('Open attachment', 'संलग्नक खोलें'),
                      style: IconButton.styleFrom(
                        side: BorderSide(color: t.control),
                      ),
                      onPressed: () => context.go(
                        '/work/attachment/${c['attachment_id']}?title=${Uri.encodeComponent('${task['title']}')}',
                      ),
                      icon: const AppIcon(AppIcons.image, size: 20),
                    ),
            ),
          const SizedBox(height: 12),
        ],
      ),
      bottom: ActionPanel(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: comment,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  onChanged: (v) => ref
                      .read(unsavedWorkProvider)
                      .mark(
                        'task-comment',
                        tr('Task comment', 'कार्य टिप्पणी'),
                        v.trim().isNotEmpty,
                      ),
                  decoration: InputDecoration(
                    hintText: tr('Add a comment', 'टिप्पणी लिखें'),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: tr('Attach photo', 'फोटो जोड़ें'),
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  side: BorderSide(color: t.control),
                ),
                onPressed: sending || ops.offline ? null : () => attach(task),
                icon: const AppIcon(AppIcons.camera),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                tooltip: tr('Send comment', 'टिप्पणी भेजें'),
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: t.accent,
                  foregroundColor: t.onAccent,
                ),
                onPressed: sending ? null : () => send(task),
                icon: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const AppIcon(AppIcons.sendHorizontal),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AssignTaskPage extends ConsumerStatefulWidget {
  const AssignTaskPage({super.key, required this.scope});
  final SiteScope scope;
  @override
  ConsumerState<AssignTaskPage> createState() => _AssignTaskPageState();
}

class _AssignTaskPageState extends ConsumerState<AssignTaskPage> {
  late final UnsavedWork unsaved;
  @override
  void initState() {
    super.initState();
    unsaved = ref.read(unsavedWorkProvider);
  }

  final form = GlobalKey<FormState>();
  final title = TextEditingController(), description = TextEditingController();
  String? employee, deadline;
  String priority = 'normal';
  bool busy = false;
  Object? error;
  void dirty() => ref
      .read(unsavedWorkProvider)
      .mark(
        'assign-task',
        tr('Assign task', 'कार्य सौंपें'),
        title.text.isNotEmpty || description.text.isNotEmpty,
      );
  @override
  void dispose() {
    unsaved.mark('assign-task', '', false);
    title.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref
          .read(operationsProvider(widget.scope).notifier)
          .command('task', {
            'clientId': const Uuid().v4(),
            'employeeId': employee,
            'title': title.text.trim(),
            'description': description.text.trim(),
            'deadline': deadline,
            'priority': priority,
          });
      unsaved.mark('assign-task', '', false);
      if (mounted) {
        showConfirmation(context, tr('Task assigned', 'कार्य सौंपा गया'));
        context.pop();
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ops = ref.watch(operationsProvider(widget.scope));
    return PageScaffold(
      title: tr('Assign task', 'कार्य सौंपें'),
      body: Form(
        key: form,
        onChanged: dirty,
        child: FormPageBody(
          fields: [
            AppDropdown<String>(
              label: tr('Employee', 'कर्मचारी'),
              value: employee,
              hint: tr('Choose a team member', 'टीम सदस्य चुनें'),
              items: [
                for (final e in ops.assignable)
                  (e.id as String, e.displayName as String),
              ],
              validator: (v) =>
                  v == null ? tr('Choose an employee', 'कर्मचारी चुनें') : null,
              onChanged: (v) => setState(() => employee = v),
            ),
            AppTextField(
              label: tr('Task title', 'कार्य शीर्षक'),
              controller: title,
              maxLength: 200,
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? tr('Required', 'आवश्यक') : null,
            ),
            AppTextField(
              label: tr('Details', 'विवरण'),
              controller: description,
              minLines: 3,
              maxLines: 6,
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? tr('Required', 'आवश्यक') : null,
            ),
            DateField(
              label: tr('Deadline', 'समय सीमा'),
              value: deadline,
              withTime: true,
              firstDate: DateTime.now().subtract(const Duration(days: 1)),
              validator: (v) => v == null ? tr('Required', 'आवश्यक') : null,
              onChanged: (v) => setState(() => deadline = v),
            ),
            ChoiceChips<String>(
              label: tr('Priority', 'प्राथमिकता'),
              value: priority,
              items: [
                for (final p in ['low', 'normal', 'high', 'urgent'])
                  (p, priorityLabel(p)),
              ],
              onChanged: (v) => setState(() => priority = v),
            ),
            if (error != null) InlineError(error!),
          ],
          actions: [
            ActionButton(
              tr('Assign task', 'कार्य सौंपें'),
              icon: AppIcons.listPlus,
              busy: busy,
              onPressed: busy ? null : submit,
            ),
          ],
        ),
      ),
    );
  }
}
