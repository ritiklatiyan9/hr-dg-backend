import 'ui/icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mobile_ui.dart';
import 'providers.dart';
import 'ui/components.dart';

class OutboxPage extends ConsumerStatefulWidget {
  const OutboxPage({super.key});
  @override
  ConsumerState<OutboxPage> createState() => _OutboxPageState();
}

class _OutboxPageState extends ConsumerState<OutboxPage> {
  @override
  void initState() {
    super.initState();
    final runtime = ref.read(operationRuntimeProvider);
    if (runtime.context == null) runtime.restoreOffline();
  }

  @override
  Widget build(BuildContext context) {
    final runtime = ref.watch(operationRuntimeProvider);
    final text = Theme.of(context).textTheme;
    return PageScaffold(
      title: tr('Encrypted outbox', 'एन्क्रिप्टेड आउटबॉक्स'),
      showSite: false,
      body: ListenableBuilder(
        listenable: runtime,
        builder: (context, _) {
          final pending = runtime.queue
              .where((e) => !['accepted', 'rejected'].contains(e['state']))
              .length;
          return ListView(
            padding: Space.page,
            children: [
              Text(
                tr(
                  'Every item stays with its original site and account. Signing out deletes unsynchronized local records and their encryption key.',
                  'हर आइटम मूल साइट और खाते से जुड़ा है। साइन आउट पर असिंक रिकॉर्ड और एन्क्रिप्शन कुंजी मिटती है।',
                ),
                style: text.bodyMedium?.copyWith(
                  color: AppTokens.of(context).textSecondary,
                ),
              ),
              if (runtime.notice.isNotEmpty)
                NoticeBanner(runtime.notice, tone: StatusTone.warning),
              const SizedBox(height: 14),
              ActionButton(
                runtime.syncing
                    ? tr('Synchronizing…', 'सिंक हो रहा है…')
                    : pending == 0
                    ? tr('Everything is synced', 'सब सिंक है')
                    : tr('Sync now', 'अभी सिंक करें'),
                icon: pending == 0 ? AppIcons.check : AppIcons.refreshCw,
                variant: pending == 0
                    ? ButtonVariant.secondary
                    : ButtonVariant.primary,
                busy: runtime.syncing,
                onPressed:
                    runtime.syncing || runtime.context == null || pending == 0
                    ? null
                    : () => runtime.sync(force: true),
              ),
              SectionHeader(
                tr('Queued items', 'कतार में आइटम'),
                subtitle: pending == 0
                    ? null
                    : tr('$pending waiting', '$pending प्रतीक्षा में'),
              ),
              if (runtime.queue.isEmpty)
                EmptyState(
                  title: tr('No queued work', 'कोई कतारबद्ध कार्य नहीं'),
                  message: tr(
                    'Permitted captures and comments saved while offline appear here.',
                    'ऑफ़लाइन सहेजे गए अनुमत कैप्चर और टिप्पणियाँ यहाँ दिखेंगी।',
                  ),
                  illustration: TinyKind.cloud,
                ),
              for (final (i, e) in runtime.queue.reversed.indexed)
                ActionRow(
                  icon: e['operation'] == 'event'
                      ? AppIcons.clock3
                      : e['operation'] == 'leave'
                      ? AppIcons.treePalm
                      : AppIcons.messageSquareText,
                  title: e['operation'] == 'event'
                      ? kindLabel('${e['payload']?['kind']}')
                      : e['operation'] == 'leave'
                      ? tr('Leave request', 'छुट्टी अनुरोध')
                      : tr('Task comment', 'कार्य टिप्पणी'),
                  subtitle:
                      '${tr('Original site', 'मूल साइट')}: ${e['siteName'] ?? tr('assigned workspace', 'नियुक्त कार्यक्षेत्र')} · ${formatInstant(context, e['capturedAt'] ?? e['createdAt'])}${e['reason'] == null ? '' : '\n${reasonLabel('${e['reason']}')}'}',
                  trailing: StatusPill.status('${e['state']}'),
                  divider: i < runtime.queue.length - 1,
                ),
            ],
          );
        },
      ),
    );
  }
}
