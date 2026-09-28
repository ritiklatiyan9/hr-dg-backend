import 'ui/icons.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'scope.dart';
import 'mobile_ui.dart';
import 'ui/components.dart';
import 'graphql/operations.graphql.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key, required this.scope});
  final SiteScope scope;
  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsState();
}

class _AnalyticsState extends ConsumerState<AnalyticsScreen> {
  Map<String, dynamic>? data;
  Object? error;
  bool busy = false;
  int generation = 0;
  late final poller = VisiblePoller(const Duration(seconds: 60), () => load());
  StreamSubscription<String>? invalidation;
  late DateTimeRange range;
  String day(DateTime d) => d.toIso8601String().substring(0, 10);
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    range = DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
    load();
    invalidation = ref.read(apiProvider).invalidations.stream.listen((_) {
      if (mounted) {
        setState(() {
          generation++;
          data = null;
          error = StateError(
            tr(
              'Access changed. Reopen this view.',
              'अनुमति बदल गई। यह पृष्ठ फिर खोलें।',
            ),
          );
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    poller.start(context);
  }

  @override
  void dispose() {
    generation++;
    poller.stop();
    invalidation?.cancel();
    super.dispose();
  }

  Future<void> load({bool explain = false}) async {
    if (busy) return;
    final current = ++generation;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final api = ref.read(apiProvider);
      await api.capabilities(widget.scope);
      final variables = {
        'input': {
          'from': day(range.start),
          'to': day(range.end),
          'siteIds': [widget.scope.siteId],
        },
      };
      final response = explain
          ? await api.scopedWrite(
              widget.scope,
              documentNodeMutationExplainAnalytics,
              variables,
            )
          : await api.scopedRead(
              widget.scope,
              documentNodeQueryAnalytics,
              variables,
            );
      if (mounted && current == generation) {
        setState(
          () => data = Map<String, dynamic>.from(
            response[explain ? 'explainAnalytics' : 'analytics'],
          ),
        );
      }
    } catch (e) {
      if (mounted && current == generation) {
        setState(() {
          data = null;
          error = e;
        });
      }
    } finally {
      if (mounted && current == generation) setState(() => busy = false);
    }
  }

  Future<void> dates() async {
    final next = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: range,
    );
    if (next != null && mounted) {
      setState(() {
        range = next;
        data = null;
      });
      await load();
    }
  }

  String value(Map m) {
    final v = m['value'];
    if (v == null) return '—';
    if (m['unit'] == 'paise') return formatInr(v);
    if (m['unit'] == 'seconds') {
      return '${(double.parse('$v') / 3600).toStringAsFixed(2)} h';
    }
    return '$v';
  }

  @override
  Widget build(BuildContext context) {
    final sites = (data?['sites'] as List?) ?? [],
        explanation = data?['explanation'] as Map?;
    final metrics = sites
        .expand(
          (s) =>
              (s['metrics'] as List).map((m) => Map<String, dynamic>.from(m)),
        )
        .toList();
    final text = Theme.of(context).textTheme;
    return PageScaffold(
      title: tr('Management insights', 'प्रबंधन विश्लेषण'),
      actions: [
        IconButton(
          onPressed: busy ? null : () => load(),
          icon: const AppIcon(AppIcons.rotateCw),
          tooltip: tr('Refresh', 'रिफ्रेश'),
        ),
      ],
      body: PrivacyShieldLite(
        child: ListView(
          padding: Space.page,
          children: [
            ActionButton(
              '${formatDay(context, day(range.start))} → ${formatDay(context, day(range.end))}',
              icon: AppIcons.calendarRange,
              variant: ButtonVariant.secondary,
              onPressed: busy ? null : dates,
            ),
            const SizedBox(height: 8),
            Text(
              tr(
                'Unknown evidence is not absence. Current permitted records only.',
                'अज्ञात जानकारी अनुपस्थिति नहीं है। केवल वर्तमान अनुमत रिकॉर्ड।',
              ),
              style: text.bodySmall,
            ),
            if (busy && data == null)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LoadingState(rows: 4),
              ),
            if (error != null) InlineError(error!, retry: () => load()),
            for (final s in sites)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '${s['name']} · ${s['timezone']} · ${tr('Computed at', 'गणना समय')} ${formatInstant(context, s['asOf'])}',
                  style: text.bodySmall,
                ),
              ),
            if (metrics.isNotEmpty) SectionHeader(tr('Facts', 'तथ्य')),
            for (final m in metrics)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SurfaceCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${m['label']}',
                              style: text.titleSmall,
                            ),
                          ),
                          StatusPill(
                            '${m['state']}'.replaceAll('_', ' '),
                            tone: '${m['state']}' == 'computed'
                                ? StatusTone.success
                                : StatusTone.neutral,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(value(m), style: text.headlineSmall),
                      const SizedBox(height: 6),
                      Text(
                        [
                              m['denominator'],
                              m['eligibility'],
                              m['limitation'],
                              m['source'],
                            ]
                            .whereType<String>()
                            .where((x) => x.isNotEmpty)
                            .join('\n'),
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            if (data != null) SectionHeader(tr('Explanation', 'व्याख्या')),
            if (explanation?['mode'] == 'setup_required')
              NoticeBanner(
                tr(
                  'AI setup required. Computed facts remain available.',
                  'एआई सेटअप आवश्यक है। गणना किए गए तथ्य उपलब्ध हैं।',
                ),
              )
            else if (data != null)
              ActionButton(
                tr('Explain authorized facts', 'अनुमत तथ्यों की व्याख्या'),
                icon: AppIcons.ai,
                variant: ButtonVariant.secondary,
                busy: busy,
                onPressed: busy ? null : () => load(explain: true),
              ),
            if ([
              'recoverable_error',
              'budget_exhausted',
              'insufficient_evidence',
            ].contains(explanation?['mode']))
              NoticeBanner(
                tr(
                  'Explanation unavailable. Retry later.',
                  'व्याख्या उपलब्ध नहीं। बाद में प्रयास करें।',
                ),
                tone: StatusTone.warning,
              ),
            for (final statement in (explanation?['statements'] as List?) ?? [])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text('$statement', style: text.bodyLarge),
              ),
          ],
        ),
      ),
    );
  }
}

/// Hides aggregate figures while the app is in the background.
class PrivacyShieldLite extends StatefulWidget {
  const PrivacyShieldLite({super.key, required this.child});
  final Widget child;
  @override
  State<PrivacyShieldLite> createState() => _PrivacyShieldLiteState();
}

class _PrivacyShieldLiteState extends State<PrivacyShieldLite>
    with WidgetsBindingObserver {
  bool hidden = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final next =
        state == AppLifecycleState.paused || state == AppLifecycleState.hidden;
    if (next != hidden) setState(() => hidden = next);
  }

  @override
  Widget build(BuildContext context) =>
      hidden ? const SizedBox.expand() : widget.child;
}
