import 'dart:typed_data';
import 'package:gql/ast.dart';
import 'package:defence_garden_employee/api.dart';
import 'package:defence_garden_employee/operation_runtime.dart';
import 'package:defence_garden_employee/scope.dart';
import 'package:defence_garden_employee/ui/components.dart';
import 'package:defence_garden_employee/graphql/operations.graphql.dart';

/// Generated models require `__typename` on every object.
dynamic typed(dynamic value, [String name = 'Object']) {
  if (value is Map) {
    return <String, dynamic>{
      '__typename': name,
      for (final e in value.entries)
        e.key.toString(): typed(e.value, e.key.toString()),
    };
  }
  if (value is List) return [for (final v in value) typed(v, name)];
  return value;
}

/// In-memory API with synthetic fixtures. No network, no secrets.
class FakeApi extends HrApi {
  FakeApi({
    this.sites = const [('site-dg', 'Defence Garden')],
    this.caps = employeeCaps,
    this.checkedIn = false,
  }) : super(baseUrl: 'http://127.0.0.1:1');
  final List<(String, String)> sites;
  final List<String> caps;
  final bool checkedIn;
  final writes = <Map<String, dynamic>>[];
  static const employeeCaps = [
    'my_hr.view',
    'my_hr.submit',
    'my_attendance.view',
    'my_attendance.create',
    'my_leave.view',
    'my_dwr.view',
    'my_dwr.create',
    'my_dwr.edit',
    'my_dwr.delete',
    'my_dwr.submit',
    'my_payroll.view',
    'expenses.view',
    'helpdesk.view',
    'my_documents.view',
    'assets.view',
    'inbox.view',
    'announcements.view',
  ];
  static const managerCaps = [
    ...employeeCaps,
    'employees.view',
    'dwr_review.view',
    'dwr_review.approve',
    'leave.approve',
    'access.view',
  ];

  @override
  Future<bool> restore() async => true;
  @override
  Future<void> refresh() async {}
  @override
  Future<void> logout() async {}
  @override
  Future<bool> hasLocalDwrDrafts() async => false;
  @override
  Future<void> switchSite() async => scopeEpoch.change();

  Map<String, dynamic> get bootstrapJson => typed({
    'bootstrap': {
      'organization': {'id': 'org-1', 'name': 'Defence Garden'},
      'actor': {'id': 'actor-1', 'permissionVersion': 3},
      'sites': [
        for (final (id, name) in sites)
          {'id': id, 'name': name, 'timezone': 'Asia/Kolkata'},
      ],
    },
  });

  @override
  Future<Query$Bootstrap> bootstrap() async =>
      Query$Bootstrap.fromJson(bootstrapJson);

  String siteName(String id) =>
      sites.where((s) => s.$1 == id).firstOrNull?.$2 ?? id;

  Map<String, dynamic> profileJson(SiteScope scope) => typed({
    'myProfile': {
      'userId': 'actor-1',
      'allowedActions': ['view'],
      'permittedFields': ['contact', 'employment'],
      'salary': null,
      'bank': null,
      'identity': null,
      'id': 'emp-1',
      'employeeCode': 'DG-0007',
      'displayName': 'Arjun Mehta',
      'workEmail': 'employee@example.test',
      'phone': '+91 9000000000',
      'jobTitle': 'Field Supervisor',
      'department': 'Operations',
      'version': 4,
      'isSelf': true,
      'employment': [
        {
          'id': 'emp-rec-1',
          'startsOn': '2024-04-01',
          'endsOn': null,
          'legalEmployer': {
            'id': 'le-1',
            'name': 'Defence Garden Estates Pvt Ltd',
          },
        },
      ],
      'assignments': [
        {
          'id': 'as-1',
          'startsOn': '2024-04-01',
          'endsOn': null,
          'site': {
            'id': scope.siteId,
            'name': siteName(scope.siteId),
            'timezone': 'Asia/Kolkata',
          },
        },
      ],
    },
  });

  @override
  Future<Query$MyProfile> profile(SiteScope scope) async =>
      Query$MyProfile.fromJson(profileJson(scope));

  @override
  Future<Map<String, dynamic>> scopedRead(
    SiteScope scope,
    DocumentNode document, [
    Map<String, dynamic> variables = const {},
  ]) async {
    final name = siteName(scope.siteId);
    final now = appClock();
    if (document == documentNodeQuerySiteScope) {
      return typed({
        'scope': {
          'site': {
            'id': scope.siteId,
            'name': name,
            'timezone': 'Asia/Kolkata',
          },
          'modules': [
            for (final id in [
              'my_attendance',
              'my_leave',
              'my_dwr',
              'my_payroll',
              'expenses',
              'helpdesk',
              'my_documents',
              'assets',
              'employees',
              'access',
            ])
              {
                'id': id,
                'name': id,
                'hindi': id,
                'group': 'Self service',
                'phase': 3,
                'available': true,
                'actions': ['view'],
                'fields': [],
                'dependencies': [],
              },
          ],
          'decisions': [],
          'capabilities': caps,
          'workDate': '2026-09-22',
        },
      });
    }
    if (document == documentNodeQueryOperations) {
      return {
        'operations': {
          'me': 'emp-1',
          'siteName': name,
          'serverTime': now.toUtc().toIso8601String(),
          'policy': {
            'version': 1,
            'rules': {
              'allowOffline': false,
              'maxSessionHours': 14,
              'attendanceApproverId': 'actor-9',
            },
          },
          'geofence': {'version': 1},
          'sessions': [
            if (checkedIn)
              {
                'id': 'duty-1',
                'employee_id': 'emp-1',
                'status': 'open',
                'opened_at': now
                    .subtract(const Duration(hours: 2))
                    .toUtc()
                    .toIso8601String(),
                'last_sequence': 1,
                'segments': [],
                'gaps': [],
              },
          ],
          'events': [
            if (checkedIn)
              {
                'id': 'ev-1',
                'duty_id': 'duty-1',
                'kind': 'IN',
                'sequence': 1,
                'captured_at': now
                    .subtract(const Duration(hours: 2))
                    .toUtc()
                    .toIso8601String(),
                'status': 'accepted',
              },
          ],
          'adjustments': [],
          'visits': [],
          'leaveTypes': [
            {'id': 'lt-1', 'code': 'CL', 'label': 'Casual leave'},
          ],
          'leaveRequests': [],
          'balances': [
            {'employee_id': 'emp-1', 'type_id': 'lt-1', 'balance': '6'},
          ],
          'tasks': [
            {
              'id': 'task-1',
              'employee_id': 'emp-1',
              'title': 'Inspect irrigation at $name',
              'description': 'Check the pump house and log readings.',
              'status': 'todo',
              'priority': 'high',
              'deadline': now
                  .add(const Duration(hours: 3))
                  .toUtc()
                  .toIso8601String(),
              'version': 1,
            },
          ],
          'comments': [],
          'inbox': [
            {
              'id': 'n-1',
              'module': 'tasks',
              'entity_id': 'task-1',
              'event_type': 'task.assigned',
              'created_at': now
                  .subtract(const Duration(minutes: 30))
                  .toUtc()
                  .toIso8601String(),
              'read_at': null,
              'push_status': 'queued',
            },
          ],
          'files': [],
        },
      };
    }
    if (document == documentNodeQueryDwr) {
      return {
        'dwr': {
          'reports': [],
          'workDate': '2026-09-22',
          'settings': {'offline_drafts': false, 'amendments': false},
          'agent': {'configured': true, 'online': true, 'model': 'synthetic'},
          'site': {'name': name},
          'inbox': [],
        },
      };
    }
    if (document == documentNodeQueryDwrChat) {
      final view = (variables['input'] as Map)['view'];
      final agent = {'configured': true, 'online': true, 'model': 'synthetic'};
      final today = {
        'workDate': '2026-09-22',
        'messages': 2,
        'report': null,
        'job': {
          'status': 'queued',
          'dueAt': now
              .add(const Duration(minutes: 8))
              .toUtc()
              .toIso8601String(),
          'errorCode': null,
          'preparedAt': null,
        },
      };
      if (view == 'home') {
        return {
          'dwrChat': {
            'site': {'name': name, 'timezone': 'Asia/Kolkata'},
            'workDate': '2026-09-22',
            'agent': agent,
            'me': {
              'userId': 'actor-1',
              'employeeId': 'emp-1',
              'name': 'Asha Verma',
            },
            'permissions': {
              'post': caps.contains('my_dwr.create'),
              'edit': true,
              'delete': true,
              'createGroups': false,
              'editGroups': false,
              'moderate': false,
              'oversee': false,
              'review': false,
            },
            'personal': {
              'last': {
                'body': 'Checked pump room',
                'deleted': false,
                'at': now.toUtc().toIso8601String(),
              },
              'today': today,
            },
            'groups': [
              {
                'id': 'group-1',
                'name': 'Site Operations',
                'description': '',
                'version': 1,
                'createdAt': now.toUtc().toIso8601String(),
                'archived': false,
                'role': 'member',
                'memberCount': 3,
                'unread': 2,
                'last': {
                  'body': 'Valve arrives tomorrow',
                  'deleted': false,
                  'at': now.toUtc().toIso8601String(),
                  'userId': 'user-2',
                  'author': 'Ravi Kumar',
                },
              },
            ],
          },
        };
      }
      if (view == 'thread') {
        final personal = (variables['input'] as Map)['groupId'] == null;
        final at = now.toUtc();
        return {
          'dwrChat': {
            'site': {'name': name, 'timezone': 'Asia/Kolkata'},
            'workDate': '2026-09-22',
            'month': '2026-09',
            'serverTime': at.toIso8601String(),
            'agent': agent,
            'thread': {
              'groupId': personal ? null : 'group-1',
              'name': personal ? 'My DWR Agent' : 'Site Operations',
              'description': '',
              'archived': false,
              'role': personal ? null : 'member',
              'memberCount': personal ? 1 : 3,
              'canPost': caps.contains('my_dwr.create'),
              'canManage': false,
            },
            'me': {'userId': 'actor-1', 'employeeId': 'emp-1'},
            'messages': [
              {
                'id': 'm-2',
                'groupId': personal ? null : 'group-1',
                'userId': 'actor-1',
                'workDate': '2026-09-22',
                'body': 'Pump room ka valve replace kiya',
                'version': 1,
                'createdAt': at
                    .subtract(const Duration(minutes: 5))
                    .toIso8601String(),
                'updatedAt': at
                    .subtract(const Duration(minutes: 5))
                    .toIso8601String(),
                'editedAt': null,
                'deletedAt': null,
                'deletedByModerator': false,
                'mine': true,
                'canEdit': true,
                'canDelete': true,
              },
              {
                'id': 'm-1',
                'groupId': personal ? null : 'group-1',
                'userId': personal ? 'actor-1' : 'user-2',
                'workDate': '2026-09-21',
                'body': 'Storage tank cleaning complete',
                'version': 1,
                'createdAt': at
                    .subtract(const Duration(days: 1))
                    .toIso8601String(),
                'updatedAt': at
                    .subtract(const Duration(days: 1))
                    .toIso8601String(),
                'editedAt': null,
                'deletedAt': null,
                'deletedByModerator': false,
                'mine': personal,
                'canEdit': false,
                'canDelete': false,
              },
            ],
            'hasMore': false,
            'before': null,
            'people': {'actor-1': 'Asha Verma', 'user-2': 'Ravi Kumar'},
            'days': [
              {
                'workDate': '2026-09-21',
                'report': {
                  'id': 'r-0',
                  'status': 'submitted',
                  'version': 2,
                  'revision': 1,
                  'origin': 'chat',
                },
                'job': null,
              },
              today,
            ],
          },
        };
      }
      if (view == 'candidates') {
        return {
          'dwrChat': {'people': []},
        };
      }
      return {
        'dwrChat': {'messages': []},
      };
    }
    if (document == documentNodeQueryApprovalQueue) {
      return {
        'approvalQueue': {'items': [], 'limit': 100},
      };
    }
    if (document == documentNodeQueryProfileRequests) {
      return typed({'profileRequests': []});
    }
    if (document == documentNodeQueryEmployees) {
      return typed({
        'employees': {'nodes': [], 'endCursor': null, 'hasNextPage': false},
      });
    }
    if (document == documentNodeQueryHrRecords) {
      return {
        'hrRecords': {
          'records': [],
          'canCreate': true,
          'employees': [],
          'ownEmployeeId': 'emp-1',
        },
      };
    }
    if (document == documentNodeQueryPayroll) {
      return {
        'payroll': {'results': [], 'structures': []},
      };
    }
    if (document == documentNodeQueryEmployeeDetails) {
      return typed({
        'employeeDetails': {'reporting': [], 'shift': null},
      });
    }
    throw const ApiFailure('NOT_FOUND', 'Unknown fixture');
  }

  @override
  Future<Map<String, dynamic>> requestProfileChange(
    SiteScope scope,
    Map<String, dynamic> body,
  ) async {
    writes.add({
      'site': scope.siteId,
      'operation': 'request_profile',
      'input': body,
    });
    return {'id': 'req-2', 'status': 'pending'};
  }

  @override
  Future<Uint8List?> profilePhoto(SiteScope scope, String path) async => null;

  @override
  Future<Map<String, dynamic>> scopedWrite(
    SiteScope s,
    DocumentNode document,
    Map<String, dynamic> variables,
  ) async {
    writes.add({'site': s.siteId, ...variables});
    return {
      'operate': {'status': 'accepted'},
      'dwrCommand': {
        'id': 'r-1',
        'version': 1,
        'status': 'draft',
        'message': {'id': 'm-new', 'version': 1},
        'reportLocked': false,
      },
      'hrCommand': {'id': 'h-1'},
      ...typed({
        'saveFoundation': {'id': 'req-1', 'version': 5, 'status': 'pending'},
      }),
    };
  }
}

/// Runtime with no vault, location or timers.
class FakeRuntime extends OperationRuntime {
  FakeRuntime(super.api);
  @override
  Future<void> bindTrackingScope(SiteScope? scope) async {}
  @override
  Future<void> connect(
    SiteScope scope,
    Json snapshot,
    List<String> capabilities,
  ) async {
    context = {
      'organizationId': scope.organizationId,
      'actorId': scope.actorId,
      'siteId': scope.siteId,
      'siteName': snapshot['siteName'],
      'me': snapshot['me'],
      'policy': snapshot['policy'],
      'geofence': snapshot['geofence'],
      'sessions': (snapshot['sessions'] as List)
          .where((s) => s['employee_id'] == snapshot['me'])
          .toList(),
      'capabilities': capabilities,
    };
    notifyListeners();
  }

  @override
  Future<void> sync({bool force = false}) async {}
  @override
  Future<bool> restoreOffline() async => false;
  @override
  Future<void> close() async {}
  @override
  Future<void> stopTracking() async {
    await dutyTracker.stop();
    notifyListeners();
  }

  @override
  Future<void> clear() async {
    context = null;
    queue = [];
    notifyListeners();
  }
}
