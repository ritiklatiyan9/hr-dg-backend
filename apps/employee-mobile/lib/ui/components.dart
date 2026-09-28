import 'icons.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../mobile_ui.dart';
import '../providers.dart';
import '../workspace.dart';

// ---------------------------------------------------------------------------
// Formatting helpers
// ---------------------------------------------------------------------------

/// Wall clock used for greetings, relative times and elapsed timers. Tests
/// replace it to keep rendered output deterministic.
DateTime Function() appClock = DateTime.now;

/// Indian-grouped rupees from integer paise: 1234567 → ₹12,345.67
String formatInr(dynamic paise) {
  BigInt v;
  try {
    v = BigInt.parse(paise.toString());
  } catch (_) {
    return '—';
  }
  final negative = v.isNegative;
  v = v.abs();
  final rupees = (v ~/ BigInt.from(100)).toString();
  final fraction = (v % BigInt.from(100)).toString().padLeft(2, '0');
  String grouped;
  if (rupees.length <= 3) {
    grouped = rupees;
  } else {
    final last3 = rupees.substring(rupees.length - 3);
    var rest = rupees.substring(0, rupees.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    grouped = '${parts.join(',')},$last3';
  }
  return '${negative ? '-' : ''}₹$grouped.$fraction';
}

DateTime? parseInstant(dynamic value) =>
    value == null ? null : DateTime.tryParse('$value')?.toLocal();

/// "12 Sep 2026" for YYYY-MM-DD calendar dates (site-derived work dates).
String formatDay(BuildContext context, dynamic ymd) {
  final d = DateTime.tryParse('$ymd');
  if (d == null) return ymd?.toString() ?? '—';
  final l = MaterialLocalizations.of(context);
  return d.year == appClock().year
      ? l.formatMediumDate(d)
      : '${l.formatMediumDate(d)}, ${d.year}';
}

/// "Sep 1" without the weekday, for compact ranges.
String formatDayShort(BuildContext context, dynamic ymd) {
  final d = DateTime.tryParse('$ymd');
  if (d == null) return ymd?.toString() ?? '—';
  final l = MaterialLocalizations.of(context);
  return d.year == appClock().year
      ? l.formatShortMonthDay(d)
      : l.formatShortDate(d);
}

String formatTime(BuildContext context, dynamic iso) {
  final d = parseInstant(iso);
  if (d == null) return '—';
  return MaterialLocalizations.of(
    context,
  ).formatTimeOfDay(TimeOfDay.fromDateTime(d));
}

String formatInstant(BuildContext context, dynamic iso) {
  final d = parseInstant(iso);
  if (d == null) return '—';
  final l = MaterialLocalizations.of(context);
  return '${l.formatMediumDate(d)} · ${l.formatTimeOfDay(TimeOfDay.fromDateTime(d))}';
}

String formatMonth(BuildContext context, dynamic ymd) {
  final d = DateTime.tryParse('$ymd');
  if (d == null) return '$ymd';
  return MaterialLocalizations.of(context).formatMonthYear(d);
}

String formatDuration(Duration d) {
  final h = d.inHours, m = d.inMinutes.remainder(60);
  if (h == 0) return '${m}m';
  return '${h}h ${m.toString().padLeft(2, '0')}m';
}

String relativeTime(BuildContext context, dynamic iso) {
  final d = parseInstant(iso);
  if (d == null) return '';
  final diff = appClock().difference(d);
  if (diff.inMinutes < 1) return tr('Just now', 'अभी');
  if (diff.inMinutes < 60) {
    return tr('${diff.inMinutes} min ago', '${diff.inMinutes} मिनट पहले');
  }
  if (diff.inHours < 24) {
    return tr('${diff.inHours} h ago', '${diff.inHours} घंटे पहले');
  }
  if (diff.inDays < 7) {
    return tr('${diff.inDays} d ago', '${diff.inDays} दिन पहले');
  }
  return MaterialLocalizations.of(context).formatShortDate(d);
}

String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  return parts.map((p) => p.characters.first.toUpperCase()).take(2).join();
}

/// Plain employee-facing wording for backend status codes.
String statusLabel(String status) => tr(
  const {
        'draft': 'Draft',
        'submitted': 'Sent for review',
        'approved': 'Approved',
        'rejected': 'Rejected',
        'returned': 'Needs changes',
        'pending': 'Pending',
        'published': 'Published',
        'validated': 'Validated',
        'reviewed': 'Reviewed',
        'settled': 'Settled',
        'in_progress': 'In progress',
        'resolved': 'Resolved',
        'closed': 'Closed',
        'assigned': 'Assigned',
        'acknowledged': 'Acknowledged',
        'return_requested': 'Return requested',
        'returned_asset': 'Returned',
        'received': 'Received',
        'cleared': 'Cleared',
        'available': 'Available',
        'open': 'Open',
        'todo': 'To do',
        'blocked': 'Blocked',
        'done': 'Done',
        'accepted': 'Accepted',
        'pending_verification': 'Pending verification',
        'pending_sync': 'Waiting to sync',
        'saved_locally': 'Saved on this device',
        'expired': 'Expired',
      }[status] ??
      status.replaceAll('_', ' '),
  const {
        'draft': 'ड्राफ़्ट',
        'submitted': 'समीक्षा के लिए भेजा',
        'approved': 'स्वीकृत',
        'rejected': 'अस्वीकृत',
        'returned': 'बदलाव चाहिए',
        'pending': 'लंबित',
        'published': 'प्रकाशित',
        'validated': 'जाँचा गया',
        'reviewed': 'समीक्षित',
        'settled': 'निपटाया गया',
        'in_progress': 'प्रगति में',
        'resolved': 'हल हुआ',
        'closed': 'बंद',
        'assigned': 'सौंपा गया',
        'acknowledged': 'स्वीकार किया',
        'return_requested': 'वापसी अनुरोध',
        'received': 'प्राप्त',
        'cleared': 'क्लियर',
        'available': 'उपलब्ध',
        'open': 'खुला',
        'todo': 'करना है',
        'blocked': 'रुका हुआ',
        'done': 'पूरा',
        'accepted': 'स्वीकृत',
        'pending_verification': 'सत्यापन लंबित',
        'pending_sync': 'सिंक बाकी',
        'saved_locally': 'इस डिवाइस पर सहेजा',
        'expired': 'समाप्त',
      }[status] ??
      status.replaceAll('_', ' '),
);

StatusTone statusTone(String status) => switch (status) {
  'approved' ||
  'accepted' ||
  'published' ||
  'done' ||
  'settled' ||
  'resolved' ||
  'closed' ||
  'cleared' ||
  'acknowledged' ||
  'received' => StatusTone.success,
  'rejected' || 'blocked' || 'expired' => StatusTone.error,
  'returned' ||
  'pending_verification' ||
  'return_requested' => StatusTone.warning,
  'submitted' ||
  'pending' ||
  'validated' ||
  'reviewed' ||
  'in_progress' ||
  'pending_sync' ||
  'open' => StatusTone.info,
  'draft' || 'saved_locally' => StatusTone.accent,
  _ => StatusTone.neutral,
};

// ---------------------------------------------------------------------------
// Status pill
// ---------------------------------------------------------------------------

enum StatusTone { neutral, accent, success, warning, error, info }

class StatusPill extends StatelessWidget {
  const StatusPill(
    this.label, {
    super.key,
    this.tone = StatusTone.neutral,
    this.icon,
  });
  StatusPill.status(String status, {Key? key})
    : this(statusLabel(status), key: key, tone: statusTone(status));
  final String label;
  final StatusTone tone;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final (bg, fg) = switch (tone) {
      StatusTone.neutral => (t.surfaceMuted, t.text),
      StatusTone.accent => (t.accentPale, t.text),
      StatusTone.success => (t.successBg, t.success),
      StatusTone.warning => (t.warningBg, t.warning),
      StatusTone.error => (t.errorBg, t.error),
      StatusTone.info => (t.infoBg, t.info),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            AppIcon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header, rows, cards
// ---------------------------------------------------------------------------

class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.subtitle,
    this.trailing,
    this.top = 24,
  });
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final double top;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: top, bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.xl),
    this.color,
    this.onTap,
    this.border = true,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final VoidCallback? onTap;
  final bool border;
  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final radius = BorderRadius.circular(Radii.l);
    return Material(
      color: color ?? t.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: border ? BorderSide(color: t.outline) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// A tappable navigation row: icon in a soft square, title, optional
/// subtitle, count or status on the right, chevron.
class ActionRow extends StatelessWidget {
  const ActionRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.count,
    this.onTap,
    this.locked = false,
    this.accent = false,
    this.divider = true,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final int? count;
  final VoidCallback? onTap;
  final bool locked, accent, divider;
  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.s),
          child: Semantics(
            button: onTap != null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    AppIconBadge(
                      locked ? AppIcons.lockKeyhole : icon,
                      accent: accent,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: text.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(subtitle!, style: text.bodySmall),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (count != null && count! > 0) CountBadge(count!),
                    ?trailing,
                    if (onTap != null) ...[
                      const SizedBox(width: 4),
                      AppIcon(AppIcons.chevronRight, color: t.textSecondary),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (divider) const Divider(),
      ],
    );
  }
}

class CountBadge extends StatelessWidget {
  const CountBadge(this.count, {super.key});
  final int count;
  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: t.text,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: t.canvas,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Grouped label/value line for read-only HR information.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow(
    this.label,
    this.value, {
    super.key,
    this.selectable = true,
    this.trailing,
  });
  final String label, value;
  final bool selectable;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: text.labelMedium),
                const SizedBox(height: 3),
                selectable
                    ? SelectableText(value, style: text.bodyLarge)
                    : Text(value, style: text.bodyLarge),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar(this.name, {super.key, this.size = 44, this.photo});
  final String name;
  final double size;
  final Uint8List? photo;
  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.accentPale,
        shape: BoxShape.circle,
        image: photo == null
            ? null
            : DecorationImage(image: MemoryImage(photo!), fit: BoxFit.cover),
      ),
      child: photo != null
          ? null
          : Text(
              initials(name),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: size * .36,
                color: t.text,
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline
// ---------------------------------------------------------------------------

enum TimelineKind {
  start,
  end,
  breakTime,
  field,
  visit,
  pending,
  done,
  neutral,
}

class TimelineRow extends StatelessWidget {
  const TimelineRow({
    super.key,
    required this.title,
    this.time,
    this.subtitle,
    this.kind = TimelineKind.neutral,
    this.first = false,
    this.last = false,
    this.trailing,
  });
  final String title;
  final String? time, subtitle;
  final TimelineKind kind;
  final bool first, last;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final (color, icon) = switch (kind) {
      TimelineKind.start => (t.success, AppIcons.logIn),
      TimelineKind.end => (t.text, AppIcons.logOut),
      TimelineKind.breakTime => (t.warning, AppIcons.coffee),
      TimelineKind.field => (t.info, AppIcons.compass),
      TimelineKind.visit => (t.info, AppIcons.mapPin),
      TimelineKind.pending => (t.warning, AppIcons.hourglass),
      TimelineKind.done => (t.success, AppIcons.check),
      TimelineKind.neutral => (t.textSecondary, AppIcons.circle),
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 58,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                time ?? '',
                style: text.labelMedium?.copyWith(color: t.text),
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: first ? Colors.transparent : t.outline,
                  ),
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: t.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: AppIcon(icon, size: 13, color: color),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: last ? Colors.transparent : t.outline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: text.bodySmall),
                  ],
                ],
              ),
            ),
          ),
          if (trailing != null)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: trailing,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Buttons and action panel
// ---------------------------------------------------------------------------

enum ButtonVariant { primary, secondary, text, danger }

class ActionButton extends StatelessWidget {
  const ActionButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.variant = ButtonVariant.primary,
    this.expanded = true,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy, expanded;
  final ButtonVariant variant;
  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          )
        else if (icon != null)
          AppIcon(icon, size: 20),
        if (busy || icon != null) const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
    final press = busy ? null : onPressed;
    return switch (variant) {
      ButtonVariant.primary => FilledButton(onPressed: press, child: child),
      ButtonVariant.secondary => OutlinedButton(onPressed: press, child: child),
      ButtonVariant.text => TextButton(onPressed: press, child: child),
      ButtonVariant.danger => OutlinedButton(
        onPressed: press,
        style: OutlinedButton.styleFrom(
          foregroundColor: t.error,
          side: BorderSide(color: t.error),
        ),
        child: child,
      ),
    };
  }
}

/// Bottom action area rendered inside the page, above the persistent
/// navigation. Uses a top divider and page gutters.
class ActionPanel extends StatelessWidget {
  const ActionPanel({super.key, required this.children, this.note});
  final List<Widget> children;
  final String? note;
  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.canvas,
        border: Border(top: BorderSide(color: t.outline)),
      ),
      padding: const EdgeInsets.fromLTRB(Space.gutter, 12, Space.gutter, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (note != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  note!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Scrollable form body. When the visible height is constrained (keyboard
/// open on a small phone) the actions scroll with the content instead of
/// staying pinned, so the last field is never hidden.
class FormPageBody extends StatelessWidget {
  const FormPageBody({
    super.key,
    required this.fields,
    required this.actions,
    this.note,
    this.padding = Space.page,
    this.controller,
  });
  final List<Widget> fields, actions;
  final String? note;
  final EdgeInsets padding;
  final ScrollController? controller;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final pinned = constraints.maxHeight >= 440;
      final list = ListView(
        controller: controller,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: padding,
        children: [
          ...fields,
          if (!pinned) ...[
            const SizedBox(height: 20),
            if (note != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  note!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              actions[i],
            ],
          ],
        ],
      );
      if (!pinned) return list;
      return Column(
        children: [
          Expanded(child: list),
          ActionPanel(note: note, children: actions),
        ],
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Form fields
// ---------------------------------------------------------------------------

/// Visible label above a control.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.help,
    this.optional = false,
  });
  final String label;
  final String? help;
  final bool optional;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: text.titleSmall)),
              if (optional)
                Text(tr('Optional', 'वैकल्पिक'), style: text.labelSmall),
            ],
          ),
          const SizedBox(height: 8),
          child,
          if (help != null) ...[
            const SizedBox(height: 6),
            Text(help!, style: text.bodySmall),
          ],
        ],
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.help,
    this.validator,
    this.keyboardType,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.readOnly = false,
    this.enabled = true,
    this.onTap,
    this.onChanged,
    this.suffix,
    this.prefix,
    this.optional = false,
    this.autofillHints,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
    this.inputFormatters,
  });
  final String label;
  final String? hint, help;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int? minLines, maxLines, maxLength;
  final bool readOnly, enabled, optional, obscureText;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged, onSubmitted;
  final Widget? suffix, prefix;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  @override
  Widget build(BuildContext context) => LabeledField(
    label: label,
    help: help,
    optional: optional,
    child: TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: obscureText ? 1 : maxLines,
      maxLength: maxLength,
      readOnly: readOnly,
      enabled: enabled,
      onTap: onTap,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      autofillHints: autofillHints,
      obscureText: obscureText,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: suffix,
        prefixIcon: prefix,
        counterText: '',
      ),
    ),
  );
}

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.hint,
    this.help,
    this.optional = false,
  });
  final String label;
  final String? hint, help;
  final T? value;
  final List<(T, String)> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final bool optional;
  @override
  Widget build(BuildContext context) => LabeledField(
    label: label,
    help: help,
    optional: optional,
    child: DropdownButtonFormField<T>(
      key: ValueKey(value),
      initialValue: items.any((i) => i.$1 == value) ? value : null,
      isExpanded: true,
      validator: validator,
      hint: hint == null ? null : Text(hint!),
      decoration: const InputDecoration(),
      items: [
        for (final (v, l) in items)
          DropdownMenuItem(
            value: v,
            child: Text(l, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    ),
  );
}

/// Read-only field that opens the platform date (and optionally time) picker.
/// Stores YYYY-MM-DD, or an ISO-8601 UTC instant when [withTime] is true.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.withTime = false,
    this.firstDate,
    this.lastDate,
    this.validator,
    this.help,
    this.optional = false,
    this.enabled = true,
  });
  final String label;
  final String? value, help;
  final ValueChanged<String?> onChanged;
  final bool withTime, optional, enabled;
  final DateTime? firstDate, lastDate;
  final String? Function(String?)? validator;
  @override
  Widget build(BuildContext context) {
    final parsed = value == null ? null : DateTime.tryParse(value!)?.toLocal();
    final display = parsed == null
        ? ''
        : withTime
        ? formatInstant(context, parsed.toIso8601String())
        : MaterialLocalizations.of(context).formatMediumDate(parsed);
    return LabeledField(
      label: label,
      help: help,
      optional: optional,
      child: TextFormField(
        key: ValueKey(value),
        initialValue: display,
        readOnly: true,
        enabled: enabled,
        validator: validator == null ? null : (_) => validator!(value),
        decoration: InputDecoration(
          hintText: withTime
              ? tr('Pick date and time', 'तारीख और समय चुनें')
              : tr('Pick a date', 'तारीख चुनें'),
          suffixIcon: const AppIcon(AppIcons.calendar, size: 20),
        ),
        onTap: !enabled
            ? null
            : () async {
                final now = DateTime.now();
                final day = await showDatePicker(
                  context: context,
                  initialDate: parsed ?? now,
                  firstDate: firstDate ?? DateTime(now.year - 2),
                  lastDate: lastDate ?? DateTime(now.year + 2),
                );
                if (day == null || !context.mounted) return;
                if (!withTime) {
                  onChanged(day.toIso8601String().substring(0, 10));
                  return;
                }
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(parsed ?? now),
                );
                if (time == null) return;
                onChanged(
                  DateTime(
                    day.year,
                    day.month,
                    day.day,
                    time.hour,
                    time.minute,
                  ).toUtc().toIso8601String(),
                );
              },
      ),
    );
  }
}

/// Single-select choices rendered as rounded chips (for 2–5 options).
class ChoiceChips<T> extends StatelessWidget {
  const ChoiceChips({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.help,
  });
  final String label;
  final String? help;
  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) => LabeledField(
    label: label,
    help: help,
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (v, l) in items)
          ChoiceChip(
            label: Text(l),
            selected: v == value,
            onSelected: (_) => onChanged(v),
          ),
      ],
    ),
  );
}

/// Filter chips in a horizontally scrolling row (Today / Upcoming / …).
class FilterBar<T> extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        for (final (v, l) in items)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(l),
              selected: v == value,
              onSelected: (_) => onChanged(v),
            ),
          ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// States: loading, empty, error, success
// ---------------------------------------------------------------------------

class LoadingState extends StatefulWidget {
  const LoadingState({
    super.key,
    this.rows = 3,
    this.rowHeight = 64,
    this.header = true,
  });
  final int rows;
  final double rowHeight;
  final bool header;
  @override
  State<LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<LoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    lowerBound: .55,
    upperBound: 1,
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      pulse.stop();
      pulse.value = 1;
    } else if (!pulse.isAnimating) {
      pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    Widget block(double h, {double? w}) => Container(
      height: h,
      width: w,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: t.surfaceMuted,
        borderRadius: BorderRadius.circular(Radii.s),
      ),
    );
    return Semantics(
      label: tr('Loading', 'लोड हो रहा है'),
      child: FadeTransition(
        opacity: pulse,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.header) block(26, w: 180),
              for (var i = 0; i < widget.rows; i++) block(widget.rowHeight),
            ],
          ),
        ),
      ),
    );
  }
}

class InlineError extends StatelessWidget {
  const InlineError(
    this.error, {
    super.key,
    this.retry,
    this.title,
    this.compact = false,
  });
  final Object error;
  final VoidCallback? retry;
  final String? title;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.errorBg,
        borderRadius: BorderRadius.circular(Radii.m),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(AppIcons.circleAlert, color: t.error, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: text.titleSmall?.copyWith(color: t.error),
                  ),
                Text(
                  friendlyError(error),
                  style: text.bodyMedium?.copyWith(color: t.error),
                ),
                if (retry != null && !compact) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: retry,
                    style: TextButton.styleFrom(
                      foregroundColor: t.error,
                      minimumSize: const Size(48, 40),
                      padding: EdgeInsets.zero,
                    ),
                    icon: const AppIcon(AppIcons.rotateCw, size: 18),
                    label: Text(tr('Try again', 'फिर कोशिश करें')),
                  ),
                ],
              ],
            ),
          ),
          if (retry != null && compact)
            IconButton(
              onPressed: retry,
              icon: const AppIcon(AppIcons.rotateCw),
              tooltip: tr('Try again', 'फिर कोशिश करें'),
            ),
        ],
      ),
    );
  }
}

/// Informational or warning banner (offline, restricted, notice).
class NoticeBanner extends StatelessWidget {
  const NoticeBanner(
    this.message, {
    super.key,
    this.tone = StatusTone.info,
    this.icon,
    this.action,
  });
  final String message;
  final StatusTone tone;
  final IconData? icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final (bg, fg) = switch (tone) {
      StatusTone.warning => (t.warningBg, t.warning),
      StatusTone.error => (t.errorBg, t.error),
      StatusTone.success => (t.successBg, t.success),
      StatusTone.accent => (t.accentPale, t.text),
      _ => (t.infoBg, t.info),
    };
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Radii.m),
      ),
      child: Row(
        children: [
          AppIcon(icon ?? AppIcons.info, size: 20, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: fg),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

enum TinyKind {
  clipboard,
  clock,
  envelope,
  calendar,
  lock,
  cloud,
  site,
  receipt,
  people,
  check,
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.illustration = TinyKind.clipboard,
    this.action,
  });
  final String title, message;
  final TinyKind illustration;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 8),
      child: Column(
        children: [
          TinyIllustration(illustration),
          const SizedBox(height: 16),
          Text(title, style: text.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            message,
            style: text.bodyMedium?.copyWith(
              color: AppTokens.of(context).textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    );
  }
}

/// Small original line illustrations drawn with the token colours.
class TinyIllustration extends StatelessWidget {
  const TinyIllustration(this.kind, {super.key, this.size = 72});
  final TinyKind kind;
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size(size, size),
      painter: _TinyPainter(kind, AppTokens.of(context)),
    ),
  );
}

class _TinyPainter extends CustomPainter {
  _TinyPainter(this.kind, this.t);
  final TinyKind kind;
  final AppTokens t;
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = Paint()
      ..color = t.text
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .045
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = t.accent;
    final pale = Paint()..color = t.accentPale;
    final r = Radius.circular(s * .12);
    canvas.drawCircle(Offset(s * .5, s * .5), s * .48, pale);
    switch (kind) {
      case TinyKind.clipboard:
      case TinyKind.check:
        final body = RRect.fromRectAndRadius(
          Rect.fromLTWH(s * .26, s * .22, s * .48, s * .6),
          r,
        );
        canvas.drawRRect(body, Paint()..color = t.surface);
        canvas.drawRRect(body, stroke);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(s * .4, s * .16, s * .2, s * .12),
            Radius.circular(s * .04),
          ),
          fill,
        );
        final p = Path()
          ..moveTo(s * .38, s * .52)
          ..lineTo(s * .47, s * .61)
          ..lineTo(s * .63, s * .43);
        canvas.drawPath(p, stroke);
      case TinyKind.clock:
        canvas.drawCircle(
          Offset(s * .5, s * .5),
          s * .3,
          Paint()..color = t.surface,
        );
        canvas.drawCircle(Offset(s * .5, s * .5), s * .3, stroke);
        canvas.drawLine(Offset(s * .5, s * .5), Offset(s * .5, s * .3), stroke);
        canvas.drawLine(
          Offset(s * .5, s * .5),
          Offset(s * .64, s * .58),
          stroke,
        );
        canvas.drawCircle(Offset(s * .5, s * .5), s * .04, fill);
      case TinyKind.envelope:
        final body = RRect.fromRectAndRadius(
          Rect.fromLTWH(s * .2, s * .3, s * .6, s * .42),
          r,
        );
        canvas.drawRRect(body, Paint()..color = t.surface);
        canvas.drawRRect(body, stroke);
        final flap = Path()
          ..moveTo(s * .2, s * .34)
          ..lineTo(s * .5, s * .55)
          ..lineTo(s * .8, s * .34);
        canvas.drawPath(flap, stroke);
        canvas.drawCircle(Offset(s * .76, s * .3), s * .08, fill);
      case TinyKind.calendar:
        final body = RRect.fromRectAndRadius(
          Rect.fromLTWH(s * .22, s * .26, s * .56, s * .5),
          r,
        );
        canvas.drawRRect(body, Paint()..color = t.surface);
        canvas.drawRRect(body, stroke);
        canvas.drawLine(
          Offset(s * .22, s * .4),
          Offset(s * .78, s * .4),
          stroke,
        );
        canvas.drawLine(
          Offset(s * .36, s * .2),
          Offset(s * .36, s * .32),
          stroke,
        );
        canvas.drawLine(
          Offset(s * .64, s * .2),
          Offset(s * .64, s * .32),
          stroke,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(s * .5, s * .5, s * .14, s * .14),
            Radius.circular(s * .03),
          ),
          fill,
        );
      case TinyKind.lock:
        final body = RRect.fromRectAndRadius(
          Rect.fromLTWH(s * .28, s * .44, s * .44, s * .34),
          r,
        );
        canvas.drawRRect(body, Paint()..color = t.surface);
        canvas.drawRRect(body, stroke);
        canvas.drawArc(
          Rect.fromLTWH(s * .36, s * .22, s * .28, s * .36),
          math.pi,
          math.pi,
          false,
          stroke,
        );
        canvas.drawCircle(Offset(s * .5, s * .6), s * .05, fill);
      case TinyKind.cloud:
        final p = Path()
          ..moveTo(s * .3, s * .64)
          ..arcToPoint(
            Offset(s * .38, s * .44),
            radius: Radius.circular(s * .12),
          )
          ..arcToPoint(
            Offset(s * .62, s * .42),
            radius: Radius.circular(s * .14),
          )
          ..arcToPoint(
            Offset(s * .72, s * .64),
            radius: Radius.circular(s * .12),
          )
          ..close();
        canvas.drawPath(p, Paint()..color = t.surface);
        canvas.drawPath(p, stroke);
        canvas.drawLine(
          Offset(s * .42, s * .56),
          Offset(s * .58, s * .56),
          Paint()
            ..color = t.accent
            ..strokeWidth = s * .05
            ..strokeCap = StrokeCap.round,
        );
      case TinyKind.site:
        final pin = Path()
          ..moveTo(s * .5, s * .78)
          ..quadraticBezierTo(s * .26, s * .5, s * .32, s * .38)
          ..arcToPoint(
            Offset(s * .68, s * .38),
            radius: Radius.circular(s * .18),
          )
          ..quadraticBezierTo(s * .74, s * .5, s * .5, s * .78)
          ..close();
        canvas.drawPath(pin, Paint()..color = t.surface);
        canvas.drawPath(pin, stroke);
        canvas.drawCircle(Offset(s * .5, s * .42), s * .07, fill);
      case TinyKind.receipt:
        final body = RRect.fromRectAndRadius(
          Rect.fromLTWH(s * .28, s * .2, s * .44, s * .6),
          Radius.circular(s * .06),
        );
        canvas.drawRRect(body, Paint()..color = t.surface);
        canvas.drawRRect(body, stroke);
        for (final y in [.36, .48, .6]) {
          canvas.drawLine(
            Offset(s * .38, s * y),
            Offset(s * .62, s * y),
            stroke,
          );
        }
        canvas.drawCircle(Offset(s * .64, s * .7), s * .06, fill);
      case TinyKind.people:
        canvas.drawCircle(
          Offset(s * .4, s * .4),
          s * .1,
          Paint()..color = t.surface,
        );
        canvas.drawCircle(Offset(s * .4, s * .4), s * .1, stroke);
        canvas.drawCircle(Offset(s * .64, s * .44), s * .08, fill);
        canvas.drawArc(
          Rect.fromLTWH(s * .22, s * .52, s * .36, s * .3),
          math.pi,
          math.pi,
          false,
          stroke,
        );
        canvas.drawArc(
          Rect.fromLTWH(s * .5, s * .56, s * .28, s * .24),
          math.pi,
          math.pi,
          false,
          stroke,
        );
    }
  }

  @override
  bool shouldRepaint(_TinyPainter old) => old.kind != kind || old.t != t;
}

/// Confirmed-success mark: a small animated check with a label. Shown only
/// after the server acknowledged the action.
class ConfirmedCheck extends StatefulWidget {
  const ConfirmedCheck({super.key, required this.label, this.detail});
  final String label;
  final String? detail;
  @override
  State<ConfirmedCheck> createState() => _ConfirmedCheckState();
}

class _ConfirmedCheckState extends State<ConfirmedCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        c.value = 1;
      } else {
        c.forward();
      }
    });
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.successBg,
        borderRadius: BorderRadius.circular(Radii.m),
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: CurvedAnimation(parent: c, curve: Curves.easeOutBack),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: t.success,
                shape: BoxShape.circle,
              ),
              child: AppIcon(AppIcons.check, color: t.successBg, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: text.titleSmall?.copyWith(color: t.success),
                ),
                if (widget.detail != null)
                  Text(
                    widget.detail!,
                    style: text.bodySmall?.copyWith(color: t.success),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Elapsed time since an instant; rebuilds only itself once per second and
/// is muted automatically when its tab is offstage (TickerMode).
class ElapsedSince extends StatefulWidget {
  const ElapsedSince(this.since, {super.key, this.style});
  final DateTime since;
  final TextStyle? style;
  @override
  State<ElapsedSince> createState() => _ElapsedSinceState();
}

class _ElapsedSinceState extends State<ElapsedSince>
    with SingleTickerProviderStateMixin {
  late final Ticker ticker;
  int shown = -1;
  @override
  void initState() {
    super.initState();
    ticker = createTicker((_) {
      final seconds = appClock().difference(widget.since).inSeconds;
      if (seconds != shown) setState(() => shown = seconds);
    })..start();
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = Duration(
      seconds: math.max(0, appClock().difference(widget.since).inSeconds),
    );
    final h = d.inHours.toString().padLeft(2, '0'),
        m = d.inMinutes.remainder(60).toString().padLeft(2, '0'),
        s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Text(
      '$h:$m:$s',
      style: widget.style,
      semanticsLabel: '${d.inHours} h ${d.inMinutes.remainder(60)} min',
    );
  }
}

// ---------------------------------------------------------------------------
// Site chip and picker
// ---------------------------------------------------------------------------

/// Compact site selector shown in every page header.
class SiteChip extends ConsumerWidget {
  const SiteChip({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTokens.of(context);
    final b = ref.watch(bootstrapProvider).value?.bootstrap;
    final selected = ref.watch(workspaceProvider).siteId;
    final site = b?.sites.where((s) => s.id == selected).firstOrNull;
    final label = site?.name ?? tr('Choose site', 'साइट चुनें');
    return Semantics(
      button: true,
      label: '${tr('Site', 'साइट')}: $label',
      child: Material(
        color: site == null ? t.accent : t.surface,
        shape: StadiumBorder(
          side: BorderSide(color: site == null ? t.accent : t.control),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: b == null ? null : () => showSitePicker(context, ref),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: compact ? 186 : 210,
              minHeight: 40,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(AppIcons.mapPin, size: 18, color: t.text),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: t.text,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 2),
                  AppIcon(
                    AppIcons.chevronDown,
                    size: 18,
                    color: t.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Body-contained site picker with search for longer lists. Site switching
/// itself is delegated to [AppShellScope.changeSite].
Future<void> showSitePicker(BuildContext context, WidgetRef ref) async {
  final b = ref.read(bootstrapProvider).value?.bootstrap;
  if (b == null) return;
  final chosen = await showAppSheet<String>(
    context,
    builder: (ctx) =>
        _SitePickerSheet(sites: b.sites.map((s) => (s.id, s.name)).toList()),
  );
  if (chosen == null || !context.mounted) return;
  await AppShellScope.of(context)?.changeSite(chosen);
}

class _SitePickerSheet extends StatefulWidget {
  const _SitePickerSheet({required this.sites});
  final List<(String, String)> sites;
  @override
  State<_SitePickerSheet> createState() => _SitePickerSheetState();
}

class _SitePickerSheetState extends State<_SitePickerSheet> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final visible = widget.sites
        .where((s) => s.$2.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        4,
        Space.gutter,
        Space.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('Choose your work site', 'अपनी साइट चुनें'),
            style: text.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            tr(
              'Attendance, reports and requests are recorded at the selected site.',
              'उपस्थिति, रिपोर्ट और अनुरोध चयनित साइट पर दर्ज होते हैं।',
            ),
            style: text.bodySmall,
          ),
          if (widget.sites.length > 5) ...[
            const SizedBox(height: 14),
            TextField(
              autofocus: false,
              decoration: InputDecoration(
                hintText: tr('Search sites', 'साइट खोजें'),
                prefixIcon: const AppIcon(AppIcons.search),
              ),
              onChanged: (v) => setState(() => query = v),
            ),
          ],
          const SizedBox(height: 10),
          if (widget.sites.isEmpty)
            EmptyState(
              title: tr(
                'No active site membership',
                'कोई सक्रिय साइट सदस्यता नहीं',
              ),
              message: tr(
                'Contact your administrator.',
                'व्यवस्थापक से संपर्क करें।',
              ),
              illustration: TinyKind.site,
            ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final (id, name) in visible)
                  ListTile(
                    leading: AppIcon(AppIcons.mapPin, color: t.text),
                    title: Text(name),
                    trailing: AppIcon(
                      AppIcons.chevronRight,
                      color: t.textSecondary,
                    ),
                    onTap: () => Navigator.of(context).pop(id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shell scope (implemented by AppShell) and page scaffold
// ---------------------------------------------------------------------------

/// Actions the shell exposes to pages: site switching and sign-out with
/// unsaved-work guards.
abstract class AppShellActions {
  Future<void> changeSite(String siteId);
  Future<void> signOut();
}

class AppShellScope extends InheritedWidget {
  const AppShellScope({super.key, required this.actions, required super.child});
  final AppShellActions actions;
  static AppShellActions? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppShellScope>()?.actions;
  @override
  bool updateShouldNotify(AppShellScope old) => old.actions != actions;
}

/// Tablet width: keeps content readable by centring it in a 760 dp column
/// while the familiar navigation stays in place. Tight constraints are kept
/// so scrollables inside still receive a bounded height.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({super.key, required this.child, this.maxWidth = 760});
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final extra = constraints.maxWidth - maxWidth;
      if (extra <= 0) return child;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: extra / 2),
        child: child,
      );
    },
  );
}

/// Standard page: title, optional back, site chip, body, optional pinned
/// bottom panel rendered above the persistent navigation.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.bottom,
    this.showSite = true,
    this.leading,
    this.titleWidget,
  });
  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? bottom, leading, titleWidget;
  final bool showSite;
  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: false,
    appBar: AppBar(
      leading: leading,
      title: titleWidget ?? Text(title, overflow: TextOverflow.ellipsis),
      actions: [
        ...actions,
        if (showSite)
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: SiteChip(compact: true)),
          ),
      ],
    ),
    body: ReadableWidth(child: body),
    bottomNavigationBar: bottom,
  );
}

// ---------------------------------------------------------------------------
// Sheets and dialogs
// ---------------------------------------------------------------------------

/// Routine pickers and filters: body-contained sheet on the branch navigator
/// so the bottom navigation stays visible.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  useRootNavigator: false,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (ctx) => ConstrainedBox(
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * .8),
    child: builder(ctx),
  ),
);

/// Consequential confirmation: root dialog whose scrim covers the whole app,
/// including the navigation bar.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) {
      final t = AppTokens.of(ctx);
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel ?? tr('Cancel', 'रद्द करें')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: t.error,
                    foregroundColor: t.errorBg,
                  )
                : null,
            child: Text(confirmLabel ?? tr('Confirm', 'पुष्टि करें')),
          ),
        ],
      );
    },
  );
  return result == true;
}

/// Asks for a written reason (minimum length enforced) with an optional
/// decision. Returns null when cancelled.
Future<({bool approve, String note})?> askDecision(
  BuildContext context, {
  required String title,
  String? message,
  String? approveLabel,
  String? rejectLabel,
  bool decision = true,
  int minLength = 8,
  Widget? extra,
}) async {
  final controller = TextEditingController();
  try {
    return await showDialog<({bool approve, String note})>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) {
          final ok = controller.text.trim().length >= minLength;
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (message != null) ...[
                    Text(message),
                    const SizedBox(height: 14),
                  ],
                  if (extra != null) ...[extra, const SizedBox(height: 14)],
                  TextField(
                    controller: controller,
                    onChanged: (_) => set(() {}),
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 500,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: tr(
                        'Write a short reason',
                        'संक्षिप्त कारण लिखें',
                      ),
                      helperText: tr(
                        'At least $minLength characters',
                        'कम से कम $minLength अक्षर',
                      ),
                      counterText: '',
                    ),
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.end,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(tr('Cancel', 'रद्द करें')),
              ),
              if (decision)
                OutlinedButton(
                  onPressed: ok
                      ? () => Navigator.pop(ctx, (
                          approve: false,
                          note: controller.text.trim(),
                        ))
                      : null,
                  child: Text(rejectLabel ?? tr('Reject', 'अस्वीकार करें')),
                ),
              FilledButton(
                onPressed: ok
                    ? () => Navigator.pop(ctx, (
                        approve: true,
                        note: controller.text.trim(),
                      ))
                    : null,
                child: Text(
                  approveLabel ??
                      (decision
                          ? tr('Approve', 'स्वीकार करें')
                          : tr('Confirm', 'पुष्टि करें')),
                ),
              ),
            ],
          );
        },
      ),
    );
  } finally {
    Future.delayed(const Duration(milliseconds: 400), controller.dispose);
  }
}

void showConfirmation(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          AppIcon(
            AppIcons.circleCheck,
            size: 20,
            color: AppTokens.dark.success,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

/// Chooses a tone-appropriate icon for an inbox/event type.
IconData eventIcon(String eventType) {
  if (eventType.startsWith('task')) return AppIcons.listTodo;
  if (eventType.startsWith('leave')) return AppIcons.treePalm;
  if (eventType.startsWith('attendance') || eventType.startsWith('event')) {
    return AppIcons.clock3;
  }
  if (eventType.startsWith('visit')) return AppIcons.mapPin;
  if (eventType.startsWith('dwr')) return AppIcons.mic;
  if (eventType.startsWith('payroll')) return AppIcons.receiptText;
  if (eventType.startsWith('announcement') || eventType.startsWith('policy')) {
    return AppIcons.megaphone;
  }
  if (eventType.startsWith('document')) return AppIcons.fileText;
  if (eventType.startsWith('expense')) return AppIcons.walletCards;
  if (eventType.startsWith('asset')) return AppIcons.monitorSmartphone;
  if (eventType.startsWith('helpdesk') || eventType.startsWith('grievance')) {
    return AppIcons.headset;
  }
  return AppIcons.bell;
}

/// Plain-language title for an inbox/event type.
String eventTitle(String event) {
  if (event.endsWith('reminder')) {
    return tr('Your daily report is due', 'आपकी दैनिक रिपोर्ट देय है');
  }
  return switch (event) {
    'attendance.accepted' => tr('Attendance recorded', 'उपस्थिति दर्ज हुई'),
    'attendance.pending_verification' || 'attendance.review_required' => tr(
      'Attendance needs review',
      'उपस्थिति की समीक्षा आवश्यक है',
    ),
    'event.reviewed' => tr(
      'Attendance review completed',
      'उपस्थिति समीक्षा पूरी हुई',
    ),
    'task.assigned' => tr('A task was assigned to you', 'आपको कार्य सौंपा गया'),
    'task.updated' => tr('Task updated', 'कार्य अद्यतन हुआ'),
    'task.commented' => tr('New task comment', 'कार्य पर नई टिप्पणी'),
    'leave.requested' => tr(
      'Leave request received',
      'छुट्टी अनुरोध प्राप्त हुआ',
    ),
    'leave.decided' => tr(
      'Leave decision available',
      'छुट्टी का निर्णय उपलब्ध है',
    ),
    'visit.assigned' => tr('A visit was assigned', 'दौरा सौंपा गया'),
    'dwr.submitted' => tr(
      'A report is ready for review',
      'रिपोर्ट समीक्षा के लिए तैयार है',
    ),
    'dwr.prepared' => tr(
      'Your daily report is ready',
      'आपकी दैनिक रिपोर्ट तैयार है',
    ),
    'dwr.group.added' => tr(
      'You were added to a DWR group',
      'आपको DWR समूह में जोड़ा गया',
    ),
    'dwr.reviewed' || 'dwr.returned' || 'dwr.approved' => tr(
      'Your report was reviewed',
      'आपकी रिपोर्ट की समीक्षा हुई',
    ),
    'payroll.published' => tr('A payslip is available', 'वेतन पर्ची उपलब्ध है'),
    'payroll.paid' => tr('Salary payment recorded', 'वेतन भुगतान दर्ज हुआ'),
    'employee.profile_updated' => tr(
      'Your profile was updated',
      'आपकी प्रोफ़ाइल अपडेट हुई',
    ),
    'document.reminders' || 'document.reminder' => tr(
      'A document is expiring soon',
      'एक दस्तावेज़ जल्द समाप्त हो रहा है',
    ),
    'expense.decided' ||
    'expense.settled' => tr('Expense update', 'व्यय अद्यतन'),
    'asset.assigned' => tr(
      'An asset was assigned to you',
      'आपको उपकरण सौंपा गया',
    ),
    'document.expiring' => tr(
      'A document is expiring',
      'एक दस्तावेज़ समाप्त हो रहा है',
    ),
    'announcement.published' => tr('New announcement', 'नई घोषणा'),
    'policy.published' => tr(
      'New policy to acknowledge',
      'नई नीति स्वीकार करें',
    ),
    'helpdesk.updated' || 'grievance.updated' => tr(
      'Your request was updated',
      'आपका अनुरोध अपडेट हुआ',
    ),
    _ => _genericEventTitle(event),
  };
}

String _genericEventTitle(String event) {
  final kind = event.split('.').first, action = event.split('.').last;
  final subject = switch (kind) {
    'expense' => tr('expense claim', 'व्यय दावा'),
    'asset' => tr('asset', 'उपकरण'),
    'helpdesk' => tr('helpdesk request', 'सहायता अनुरोध'),
    'grievance' => tr('confidential case', 'गोपनीय मामला'),
    'document' => tr('document', 'दस्तावेज़'),
    'policy' => tr('policy', 'नीति'),
    'announcement' => tr('announcement', 'घोषणा'),
    'lifecycle' => tr('employment record', 'रोजगार रिकॉर्ड'),
    'payroll' => tr('payslip', 'वेतन पर्ची'),
    'leave' => tr('leave request', 'छुट्टी अनुरोध'),
    'task' => tr('task', 'कार्य'),
    _ => tr('work item', 'कार्य आइटम'),
  };
  final verb = switch (action) {
    'submitted' => tr('was sent for review', 'समीक्षा के लिए भेजा गया'),
    'approved' => tr('was approved', 'स्वीकृत हुआ'),
    'rejected' => tr('was rejected', 'अस्वीकृत हुआ'),
    'settled' => tr('was settled', 'निपटाया गया'),
    'published' => tr('was published', 'प्रकाशित हुआ'),
    'assigned' => tr('was assigned to you', 'आपको सौंपा गया'),
    'returned' ||
    'return_requested' => tr('return was requested', 'वापसी का अनुरोध हुआ'),
    'started' || 'in_progress' => tr('is being worked on', 'पर काम हो रहा है'),
    'resolved' => tr('was resolved', 'हल हुआ'),
    'closed' => tr('was closed', 'बंद हुआ'),
    'commented' || 'comment' => tr('has a new comment', 'पर नई टिप्पणी है'),
    'expiring' ||
    'reminder' ||
    'reminders' => tr('needs attention soon', 'पर जल्द ध्यान दें'),
    'decided' => tr('has a decision', 'पर निर्णय हुआ'),
    _ => tr('was updated', 'अद्यतन हुआ'),
  };
  final text = '$subject $verb';
  return text[0].toUpperCase() + text.substring(1);
}

/// Known attendance verification reasons from the server, in plain Hindi when
/// the app runs in Hindi. Unknown text is shown unchanged.
String reasonLabel(String reason) => tr(
  reason,
  const {
        'Accuracy exceeds policy limit': 'सटीकता नीति सीमा से अधिक है',
        'Device reports mock location': 'डिवाइस नकली स्थान बता रहा है',
        'No location observation': 'कोई स्थान अवलोकन नहीं',
        'Observation is stale relative to capture':
            'स्थान अवलोकन कैप्चर से पुराना है',
        'Accuracy circle crosses geofence boundary':
            'सटीकता वृत्त साइट सीमा को पार करता है',
        'Entry/exit location is outside or unverified; no absence inferred':
            'प्रवेश/निकास स्थान बाहर या असत्यापित है; अनुपस्थिति नहीं मानी गई',
        'Evidence accepted under versioned policy; device time within server window':
            'नीति के तहत साक्ष्य स्वीकृत; डिवाइस समय सर्वर सीमा में',
        'Capture predates the declared geofence version':
            'कैप्चर घोषित साइट-सीमा संस्करण से पहले का है',
        'Visit accuracy circle is not inside the assigned location':
            'दौरे का सटीकता वृत्त निर्धारित स्थान के भीतर नहीं है',
        'Visit location is unverified': 'दौरे का स्थान असत्यापित है',
        'Upload exceeds configured offline window':
            'अपलोड निर्धारित ऑफ़लाइन अवधि से बाहर है',
        'Server accepted': 'सर्वर ने स्वीकार किया',
      }[reason] ??
      reason,
);

/// A small "IN/OUT" text used where colour alone must not carry meaning.
String kindLabel(String kind) => tr(
  const {
        'IN': 'Checked in',
        'OUT': 'Checked out',
        'BREAK_START': 'Break started',
        'BREAK_END': 'Break ended',
        'FIELD_START': 'Field duty started',
        'FIELD_END': 'Field duty ended',
        'VISIT_START': 'Arrived at visit',
        'VISIT_END': 'Left visit',
        'LOCATION': 'Location sample',
      }[kind] ??
      kind,
  const {
        'IN': 'चेक-इन',
        'OUT': 'चेक-आउट',
        'BREAK_START': 'ब्रेक शुरू',
        'BREAK_END': 'ब्रेक समाप्त',
        'FIELD_START': 'फील्ड ड्यूटी शुरू',
        'FIELD_END': 'फील्ड ड्यूटी समाप्त',
        'VISIT_START': 'दौरे पर पहुँचे',
        'VISIT_END': 'दौरा छोड़ा',
        'LOCATION': 'स्थान नमूना',
      }[kind] ??
      kind,
);

/// Muted helper for "poll only while visible" timers.
bool isVisibleTab(BuildContext context) => TickerMode.valuesOf(context).enabled;

/// Debounced periodic refresh that only fires while the page is visible and
/// the app is in the foreground.
class VisiblePoller {
  VisiblePoller(this.interval, this.onTick);
  final Duration interval;
  final Future<void> Function() onTick;
  Timer? _timer;
  BuildContext? _context;
  void start(BuildContext context) {
    _context = context;
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) {
      final c = _context;
      if (c == null || !c.mounted || !TickerMode.valuesOf(c).enabled) return;
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return;
      }
      onTick();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
