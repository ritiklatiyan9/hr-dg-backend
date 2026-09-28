import 'ui/icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'api.dart';
import 'mobile_ui.dart';
import 'providers.dart';
import 'scope.dart';
import 'ui/components.dart';
import 'graphql/operations.graphql.dart';

class PeoplePage extends ConsumerStatefulWidget {
  const PeoplePage({super.key, required this.scope});
  final SiteScope scope;
  @override
  ConsumerState<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends ConsumerState<PeoplePage> {
  String search = '';
  String? after;
  late Future<Query$Employees> data;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    data = ref.read(apiProvider).capabilities(widget.scope).then((access) {
      if (!access.scope.capabilities.contains('employees.view')) {
        throw ApiFailure(
          'FORBIDDEN',
          tr('Team access is restricted', 'टीम अनुमति प्रतिबंधित'),
        );
      }
      return ref
          .read(apiProvider)
          .team(widget.scope, search: search, after: after);
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PageScaffold(
      title: tr('People', 'लोग'),
      body: ListView(
        padding: Space.page,
        children: [
          Text(
            tr(
              'Team membership and field permissions are checked for every record.',
              'हर रिकॉर्ड के लिए टीम सदस्यता और फ़ील्ड अनुमति जाँची जाती है।',
            ),
            style: text.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: tr('Search employees', 'कर्मचारी खोजें'),
              prefixIcon: const AppIcon(AppIcons.search),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (v) => setState(() {
              search = v;
              after = null;
              load();
            }),
          ),
          const SizedBox(height: 8),
          FutureBuilder(
            future: data,
            builder: (context, s) {
              if (s.hasError) {
                return InlineError(s.error!, retry: () => setState(load));
              }
              if (!s.hasData) {
                return const LoadingState(
                  rows: 5,
                  header: false,
                  rowHeight: 60,
                );
              }
              final page = s.data!.employees;
              return Column(
                children: [
                  if (page.nodes.isEmpty)
                    EmptyState(
                      title: tr('No matching people', 'कोई व्यक्ति नहीं मिला'),
                      message: tr('Try another search.', 'दूसरी खोज करें।'),
                      illustration: TinyKind.people,
                    ),
                  for (final (i, e) in page.nodes.indexed)
                    Column(
                      children: [
                        ListTile(
                          leading: Avatar(e.displayName, size: 42),
                          title: Text(e.displayName),
                          subtitle: Text(
                            [
                              e.employeeCode,
                              e.jobTitle,
                              e.department,
                            ].whereType<String>().join(' · '),
                          ),
                          trailing: AppIcon(
                            AppIcons.chevronRight,
                            color: AppTokens.of(context).textSecondary,
                          ),
                          onTap: () =>
                              context.go('/work/team/person', extra: e),
                        ),
                        if (i < page.nodes.length - 1) const Divider(),
                      ],
                    ),
                  const SizedBox(height: 12),
                  if (page.hasNextPage)
                    ActionButton(
                      tr('Next page', 'अगला पृष्ठ'),
                      variant: ButtonVariant.secondary,
                      onPressed: () => setState(() {
                        after = page.endCursor;
                        load();
                      }),
                    ),
                  if (after != null)
                    ActionButton(
                      tr('First page', 'पहला पृष्ठ'),
                      variant: ButtonVariant.text,
                      onPressed: () => setState(() {
                        after = null;
                        load();
                      }),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class PersonDetailPage extends StatefulWidget {
  const PersonDetailPage({
    super.key,
    required this.scope,
    required this.person,
  });
  final SiteScope scope;
  final Object? person;
  @override
  State<PersonDetailPage> createState() => _PersonDetailPageState();
}

class _PersonDetailPageState extends State<PersonDetailPage> {
  bool showSensitive = false;
  @override
  Widget build(BuildContext context) {
    final e = widget.person is Fragment$EmployeeFields
        ? widget.person as Fragment$EmployeeFields
        : null;
    final text = Theme.of(context).textTheme;
    if (e == null) {
      return PageScaffold(
        title: tr('Person', 'व्यक्ति'),
        body: ListView(
          padding: Space.page,
          children: [
            EmptyState(
              title: tr('Open from the people list', 'लोग सूची से खोलें'),
              message: tr(
                'Person details are loaded from the authorized list.',
                'व्यक्ति विवरण अधिकृत सूची से लोड होते हैं।',
              ),
              illustration: TinyKind.people,
              action: ActionButton(
                tr('Go to People', 'लोग पर जाएँ'),
                expanded: false,
                onPressed: () => context.go('/work/team'),
              ),
            ),
          ],
        ),
      );
    }
    final sensitive = e.salary != null || e.bank != null;
    return PageScaffold(
      title: tr('Person', 'व्यक्ति'),
      body: ListView(
        padding: Space.page,
        children: [
          Row(
            children: [
              Avatar(e.displayName, size: 60),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.displayName, style: text.headlineSmall),
                    if (e.jobTitle != null)
                      Text(e.jobTitle!, style: text.bodyMedium),
                    if (e.department != null)
                      Text(e.department!, style: text.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          SectionHeader(tr('Contact', 'संपर्क')),
          KeyValueRow(tr('Employee ID', 'कर्मचारी आईडी'), e.employeeCode),
          if (e.phone != null) KeyValueRow(tr('Phone', 'फ़ोन'), e.phone!),
          if (e.workEmail != null)
            KeyValueRow(tr('Email', 'ईमेल'), e.workEmail!),
          if (e.assignments.isNotEmpty) ...[
            SectionHeader(tr('Site assignments', 'साइट नियुक्ति')),
            for (final (i, a) in e.assignments.indexed)
              TimelineRow(
                title: a.site.name,
                subtitle:
                    '${formatDay(context, a.startsOn)} → ${a.endsOn == null ? tr('Current', 'वर्तमान') : formatDay(context, a.endsOn)}',
                kind: a.endsOn == null
                    ? TimelineKind.start
                    : TimelineKind.neutral,
                first: i == 0,
                last: i == e.assignments.length - 1,
              ),
          ],
          if (sensitive) ...[
            SectionHeader(
              tr('Salary & bank', 'वेतन और बैंक'),
              subtitle: tr(
                'Shown only because your access allows it',
                'केवल आपकी अनुमति के कारण दिख रहा है',
              ),
              trailing: TextButton.icon(
                onPressed: () => setState(() => showSensitive = !showSensitive),
                icon: AppIcon(
                  showSensitive ? AppIcons.eyeOff : AppIcons.eye,
                  size: 18,
                ),
                label: Text(
                  showSensitive ? tr('Hide', 'छिपाएँ') : tr('Show', 'दिखाएँ'),
                ),
              ),
            ),
            if (e.salary != null)
              KeyValueRow(
                tr('Salary', 'वेतन'),
                showSensitive ? e.salary! : '••••••',
                selectable: showSensitive,
              ),
            if (e.bank != null)
              KeyValueRow(
                tr('Bank', 'बैंक'),
                showSensitive ? e.bank! : '••••••',
                selectable: showSensitive,
              ),
          ],
        ],
      ),
    );
  }
}
