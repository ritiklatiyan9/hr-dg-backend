class Input$UpdateProfileInput {
  factory Input$UpdateProfileInput({
    required String employeeId,
    required String phone,
    required int expectedVersion,
  }) => Input$UpdateProfileInput._({
    r'employeeId': employeeId,
    r'phone': phone,
    r'expectedVersion': expectedVersion,
  });

  Input$UpdateProfileInput._(this._$data);

  factory Input$UpdateProfileInput.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$employeeId = data['employeeId'];
    result$data['employeeId'] = (l$employeeId as String);
    final l$phone = data['phone'];
    result$data['phone'] = (l$phone as String);
    final l$expectedVersion = data['expectedVersion'];
    result$data['expectedVersion'] = (l$expectedVersion as int);
    return Input$UpdateProfileInput._(result$data);
  }

  Map<String, dynamic> _$data;

  String get employeeId => (_$data['employeeId'] as String);

  String get phone => (_$data['phone'] as String);

  int get expectedVersion => (_$data['expectedVersion'] as int);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$employeeId = employeeId;
    result$data['employeeId'] = l$employeeId;
    final l$phone = phone;
    result$data['phone'] = l$phone;
    final l$expectedVersion = expectedVersion;
    result$data['expectedVersion'] = l$expectedVersion;
    return result$data;
  }

  CopyWith$Input$UpdateProfileInput<Input$UpdateProfileInput> get copyWith =>
      CopyWith$Input$UpdateProfileInput(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Input$UpdateProfileInput ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$employeeId = employeeId;
    final lOther$employeeId = other.employeeId;
    if (l$employeeId != lOther$employeeId) {
      return false;
    }
    final l$phone = phone;
    final lOther$phone = other.phone;
    if (l$phone != lOther$phone) {
      return false;
    }
    final l$expectedVersion = expectedVersion;
    final lOther$expectedVersion = other.expectedVersion;
    if (l$expectedVersion != lOther$expectedVersion) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$employeeId = employeeId;
    final l$phone = phone;
    final l$expectedVersion = expectedVersion;
    return Object.hashAll([l$employeeId, l$phone, l$expectedVersion]);
  }
}

abstract class CopyWith$Input$UpdateProfileInput<TRes> {
  factory CopyWith$Input$UpdateProfileInput(
    Input$UpdateProfileInput instance,
    TRes Function(Input$UpdateProfileInput) then,
  ) = _CopyWithImpl$Input$UpdateProfileInput;

  factory CopyWith$Input$UpdateProfileInput.stub(TRes res) =
      _CopyWithStubImpl$Input$UpdateProfileInput;

  TRes call({String? employeeId, String? phone, int? expectedVersion});
}

class _CopyWithImpl$Input$UpdateProfileInput<TRes>
    implements CopyWith$Input$UpdateProfileInput<TRes> {
  _CopyWithImpl$Input$UpdateProfileInput(this._instance, this._then);

  final Input$UpdateProfileInput _instance;

  final TRes Function(Input$UpdateProfileInput) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? employeeId = _undefined,
    Object? phone = _undefined,
    Object? expectedVersion = _undefined,
  }) => _then(
    Input$UpdateProfileInput._({
      ..._instance._$data,
      if (employeeId != _undefined && employeeId != null)
        'employeeId': (employeeId as String),
      if (phone != _undefined && phone != null) 'phone': (phone as String),
      if (expectedVersion != _undefined && expectedVersion != null)
        'expectedVersion': (expectedVersion as int),
    }),
  );
}

class _CopyWithStubImpl$Input$UpdateProfileInput<TRes>
    implements CopyWith$Input$UpdateProfileInput<TRes> {
  _CopyWithStubImpl$Input$UpdateProfileInput(this._res);

  TRes _res;

  call({String? employeeId, String? phone, int? expectedVersion}) => _res;
}

class Input$AccessRuleInput {
  factory Input$AccessRuleInput({
    required String key,
    required String effect,
    required String scope,
  }) => Input$AccessRuleInput._({
    r'key': key,
    r'effect': effect,
    r'scope': scope,
  });

  Input$AccessRuleInput._(this._$data);

  factory Input$AccessRuleInput.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$key = data['key'];
    result$data['key'] = (l$key as String);
    final l$effect = data['effect'];
    result$data['effect'] = (l$effect as String);
    final l$scope = data['scope'];
    result$data['scope'] = (l$scope as String);
    return Input$AccessRuleInput._(result$data);
  }

  Map<String, dynamic> _$data;

  String get key => (_$data['key'] as String);

  String get effect => (_$data['effect'] as String);

  String get scope => (_$data['scope'] as String);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$key = key;
    result$data['key'] = l$key;
    final l$effect = effect;
    result$data['effect'] = l$effect;
    final l$scope = scope;
    result$data['scope'] = l$scope;
    return result$data;
  }

  CopyWith$Input$AccessRuleInput<Input$AccessRuleInput> get copyWith =>
      CopyWith$Input$AccessRuleInput(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Input$AccessRuleInput || runtimeType != other.runtimeType) {
      return false;
    }
    final l$key = key;
    final lOther$key = other.key;
    if (l$key != lOther$key) {
      return false;
    }
    final l$effect = effect;
    final lOther$effect = other.effect;
    if (l$effect != lOther$effect) {
      return false;
    }
    final l$scope = scope;
    final lOther$scope = other.scope;
    if (l$scope != lOther$scope) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$key = key;
    final l$effect = effect;
    final l$scope = scope;
    return Object.hashAll([l$key, l$effect, l$scope]);
  }
}

abstract class CopyWith$Input$AccessRuleInput<TRes> {
  factory CopyWith$Input$AccessRuleInput(
    Input$AccessRuleInput instance,
    TRes Function(Input$AccessRuleInput) then,
  ) = _CopyWithImpl$Input$AccessRuleInput;

  factory CopyWith$Input$AccessRuleInput.stub(TRes res) =
      _CopyWithStubImpl$Input$AccessRuleInput;

  TRes call({String? key, String? effect, String? scope});
}

class _CopyWithImpl$Input$AccessRuleInput<TRes>
    implements CopyWith$Input$AccessRuleInput<TRes> {
  _CopyWithImpl$Input$AccessRuleInput(this._instance, this._then);

  final Input$AccessRuleInput _instance;

  final TRes Function(Input$AccessRuleInput) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? key = _undefined,
    Object? effect = _undefined,
    Object? scope = _undefined,
  }) => _then(
    Input$AccessRuleInput._({
      ..._instance._$data,
      if (key != _undefined && key != null) 'key': (key as String),
      if (effect != _undefined && effect != null) 'effect': (effect as String),
      if (scope != _undefined && scope != null) 'scope': (scope as String),
    }),
  );
}

class _CopyWithStubImpl$Input$AccessRuleInput<TRes>
    implements CopyWith$Input$AccessRuleInput<TRes> {
  _CopyWithStubImpl$Input$AccessRuleInput(this._res);

  TRes _res;

  call({String? key, String? effect, String? scope}) => _res;
}

class Input$DelegationInput {
  factory Input$DelegationInput({required String key, required String scope}) =>
      Input$DelegationInput._({r'key': key, r'scope': scope});

  Input$DelegationInput._(this._$data);

  factory Input$DelegationInput.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$key = data['key'];
    result$data['key'] = (l$key as String);
    final l$scope = data['scope'];
    result$data['scope'] = (l$scope as String);
    return Input$DelegationInput._(result$data);
  }

  Map<String, dynamic> _$data;

  String get key => (_$data['key'] as String);

  String get scope => (_$data['scope'] as String);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$key = key;
    result$data['key'] = l$key;
    final l$scope = scope;
    result$data['scope'] = l$scope;
    return result$data;
  }

  CopyWith$Input$DelegationInput<Input$DelegationInput> get copyWith =>
      CopyWith$Input$DelegationInput(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Input$DelegationInput || runtimeType != other.runtimeType) {
      return false;
    }
    final l$key = key;
    final lOther$key = other.key;
    if (l$key != lOther$key) {
      return false;
    }
    final l$scope = scope;
    final lOther$scope = other.scope;
    if (l$scope != lOther$scope) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$key = key;
    final l$scope = scope;
    return Object.hashAll([l$key, l$scope]);
  }
}

abstract class CopyWith$Input$DelegationInput<TRes> {
  factory CopyWith$Input$DelegationInput(
    Input$DelegationInput instance,
    TRes Function(Input$DelegationInput) then,
  ) = _CopyWithImpl$Input$DelegationInput;

  factory CopyWith$Input$DelegationInput.stub(TRes res) =
      _CopyWithStubImpl$Input$DelegationInput;

  TRes call({String? key, String? scope});
}

class _CopyWithImpl$Input$DelegationInput<TRes>
    implements CopyWith$Input$DelegationInput<TRes> {
  _CopyWithImpl$Input$DelegationInput(this._instance, this._then);

  final Input$DelegationInput _instance;

  final TRes Function(Input$DelegationInput) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? key = _undefined, Object? scope = _undefined}) => _then(
    Input$DelegationInput._({
      ..._instance._$data,
      if (key != _undefined && key != null) 'key': (key as String),
      if (scope != _undefined && scope != null) 'scope': (scope as String),
    }),
  );
}

class _CopyWithStubImpl$Input$DelegationInput<TRes>
    implements CopyWith$Input$DelegationInput<TRes> {
  _CopyWithStubImpl$Input$DelegationInput(this._res);

  TRes _res;

  call({String? key, String? scope}) => _res;
}

class Input$AccessChangeInput {
  factory Input$AccessChangeInput({
    required int expectedVersion,
    required String role,
    required bool active,
    required List<Input$AccessRuleInput> rules,
    required List<Input$DelegationInput> delegations,
    String? reason,
  }) => Input$AccessChangeInput._({
    r'expectedVersion': expectedVersion,
    r'role': role,
    r'active': active,
    r'rules': rules,
    r'delegations': delegations,
    if (reason != null) r'reason': reason,
  });

  Input$AccessChangeInput._(this._$data);

  factory Input$AccessChangeInput.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$expectedVersion = data['expectedVersion'];
    result$data['expectedVersion'] = (l$expectedVersion as int);
    final l$role = data['role'];
    result$data['role'] = (l$role as String);
    final l$active = data['active'];
    result$data['active'] = (l$active as bool);
    final l$rules = data['rules'];
    result$data['rules'] = (l$rules as List<dynamic>)
        .map((e) => Input$AccessRuleInput.fromJson((e as Map<String, dynamic>)))
        .toList();
    final l$delegations = data['delegations'];
    result$data['delegations'] = (l$delegations as List<dynamic>)
        .map((e) => Input$DelegationInput.fromJson((e as Map<String, dynamic>)))
        .toList();
    if (data.containsKey('reason')) {
      final l$reason = data['reason'];
      result$data['reason'] = (l$reason as String?);
    }
    return Input$AccessChangeInput._(result$data);
  }

  Map<String, dynamic> _$data;

  int get expectedVersion => (_$data['expectedVersion'] as int);

  String get role => (_$data['role'] as String);

  bool get active => (_$data['active'] as bool);

  List<Input$AccessRuleInput> get rules =>
      (_$data['rules'] as List<Input$AccessRuleInput>);

  List<Input$DelegationInput> get delegations =>
      (_$data['delegations'] as List<Input$DelegationInput>);

  String? get reason => (_$data['reason'] as String?);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$expectedVersion = expectedVersion;
    result$data['expectedVersion'] = l$expectedVersion;
    final l$role = role;
    result$data['role'] = l$role;
    final l$active = active;
    result$data['active'] = l$active;
    final l$rules = rules;
    result$data['rules'] = l$rules.map((e) => e.toJson()).toList();
    final l$delegations = delegations;
    result$data['delegations'] = l$delegations.map((e) => e.toJson()).toList();
    if (_$data.containsKey('reason')) {
      final l$reason = reason;
      result$data['reason'] = l$reason;
    }
    return result$data;
  }

  CopyWith$Input$AccessChangeInput<Input$AccessChangeInput> get copyWith =>
      CopyWith$Input$AccessChangeInput(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Input$AccessChangeInput || runtimeType != other.runtimeType) {
      return false;
    }
    final l$expectedVersion = expectedVersion;
    final lOther$expectedVersion = other.expectedVersion;
    if (l$expectedVersion != lOther$expectedVersion) {
      return false;
    }
    final l$role = role;
    final lOther$role = other.role;
    if (l$role != lOther$role) {
      return false;
    }
    final l$active = active;
    final lOther$active = other.active;
    if (l$active != lOther$active) {
      return false;
    }
    final l$rules = rules;
    final lOther$rules = other.rules;
    if (l$rules.length != lOther$rules.length) {
      return false;
    }
    for (int i = 0; i < l$rules.length; i++) {
      final l$rules$entry = l$rules[i];
      final lOther$rules$entry = lOther$rules[i];
      if (l$rules$entry != lOther$rules$entry) {
        return false;
      }
    }
    final l$delegations = delegations;
    final lOther$delegations = other.delegations;
    if (l$delegations.length != lOther$delegations.length) {
      return false;
    }
    for (int i = 0; i < l$delegations.length; i++) {
      final l$delegations$entry = l$delegations[i];
      final lOther$delegations$entry = lOther$delegations[i];
      if (l$delegations$entry != lOther$delegations$entry) {
        return false;
      }
    }
    final l$reason = reason;
    final lOther$reason = other.reason;
    if (_$data.containsKey('reason') != other._$data.containsKey('reason')) {
      return false;
    }
    if (l$reason != lOther$reason) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$expectedVersion = expectedVersion;
    final l$role = role;
    final l$active = active;
    final l$rules = rules;
    final l$delegations = delegations;
    final l$reason = reason;
    return Object.hashAll([
      l$expectedVersion,
      l$role,
      l$active,
      Object.hashAll(l$rules.map((v) => v)),
      Object.hashAll(l$delegations.map((v) => v)),
      _$data.containsKey('reason') ? l$reason : const {},
    ]);
  }
}

abstract class CopyWith$Input$AccessChangeInput<TRes> {
  factory CopyWith$Input$AccessChangeInput(
    Input$AccessChangeInput instance,
    TRes Function(Input$AccessChangeInput) then,
  ) = _CopyWithImpl$Input$AccessChangeInput;

  factory CopyWith$Input$AccessChangeInput.stub(TRes res) =
      _CopyWithStubImpl$Input$AccessChangeInput;

  TRes call({
    int? expectedVersion,
    String? role,
    bool? active,
    List<Input$AccessRuleInput>? rules,
    List<Input$DelegationInput>? delegations,
    String? reason,
  });
  TRes rules(
    Iterable<Input$AccessRuleInput> Function(
      Iterable<CopyWith$Input$AccessRuleInput<Input$AccessRuleInput>>,
    )
    _fn,
  );
  TRes delegations(
    Iterable<Input$DelegationInput> Function(
      Iterable<CopyWith$Input$DelegationInput<Input$DelegationInput>>,
    )
    _fn,
  );
}

class _CopyWithImpl$Input$AccessChangeInput<TRes>
    implements CopyWith$Input$AccessChangeInput<TRes> {
  _CopyWithImpl$Input$AccessChangeInput(this._instance, this._then);

  final Input$AccessChangeInput _instance;

  final TRes Function(Input$AccessChangeInput) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? expectedVersion = _undefined,
    Object? role = _undefined,
    Object? active = _undefined,
    Object? rules = _undefined,
    Object? delegations = _undefined,
    Object? reason = _undefined,
  }) => _then(
    Input$AccessChangeInput._({
      ..._instance._$data,
      if (expectedVersion != _undefined && expectedVersion != null)
        'expectedVersion': (expectedVersion as int),
      if (role != _undefined && role != null) 'role': (role as String),
      if (active != _undefined && active != null) 'active': (active as bool),
      if (rules != _undefined && rules != null)
        'rules': (rules as List<Input$AccessRuleInput>),
      if (delegations != _undefined && delegations != null)
        'delegations': (delegations as List<Input$DelegationInput>),
      if (reason != _undefined) 'reason': (reason as String?),
    }),
  );

  TRes rules(
    Iterable<Input$AccessRuleInput> Function(
      Iterable<CopyWith$Input$AccessRuleInput<Input$AccessRuleInput>>,
    )
    _fn,
  ) => call(
    rules: _fn(
      _instance.rules.map((e) => CopyWith$Input$AccessRuleInput(e, (i) => i)),
    ).toList(),
  );

  TRes delegations(
    Iterable<Input$DelegationInput> Function(
      Iterable<CopyWith$Input$DelegationInput<Input$DelegationInput>>,
    )
    _fn,
  ) => call(
    delegations: _fn(
      _instance.delegations.map(
        (e) => CopyWith$Input$DelegationInput(e, (i) => i),
      ),
    ).toList(),
  );
}

class _CopyWithStubImpl$Input$AccessChangeInput<TRes>
    implements CopyWith$Input$AccessChangeInput<TRes> {
  _CopyWithStubImpl$Input$AccessChangeInput(this._res);

  TRes _res;

  call({
    int? expectedVersion,
    String? role,
    bool? active,
    List<Input$AccessRuleInput>? rules,
    List<Input$DelegationInput>? delegations,
    String? reason,
  }) => _res;

  rules(_fn) => _res;

  delegations(_fn) => _res;
}

class Input$FoundationInput {
  factory Input$FoundationInput({
    String? id,
    String? employeeId,
    int? expectedVersion,
    String? employeeCode,
    String? displayName,
    String? workEmail,
    String? department,
    String? designation,
    String? phone,
    String? legalEmployerId,
    String? startsOn,
    String? endsOn,
    String? sourceSiteId,
    String? assignmentId,
    String? managerId,
    String? shiftId,
    String? kind,
    String? name,
    String? startTime,
    String? endTime,
    String? date,
    bool? active,
    bool? approve,
    String? note,
    String? reason,
    String? timezone,
    int? weekStart,
    String? contactEmail,
    String? moduleId,
    bool? enabled,
    String? draftId,
  }) => Input$FoundationInput._({
    if (id != null) r'id': id,
    if (employeeId != null) r'employeeId': employeeId,
    if (expectedVersion != null) r'expectedVersion': expectedVersion,
    if (employeeCode != null) r'employeeCode': employeeCode,
    if (displayName != null) r'displayName': displayName,
    if (workEmail != null) r'workEmail': workEmail,
    if (department != null) r'department': department,
    if (designation != null) r'designation': designation,
    if (phone != null) r'phone': phone,
    if (legalEmployerId != null) r'legalEmployerId': legalEmployerId,
    if (startsOn != null) r'startsOn': startsOn,
    if (endsOn != null) r'endsOn': endsOn,
    if (sourceSiteId != null) r'sourceSiteId': sourceSiteId,
    if (assignmentId != null) r'assignmentId': assignmentId,
    if (managerId != null) r'managerId': managerId,
    if (shiftId != null) r'shiftId': shiftId,
    if (kind != null) r'kind': kind,
    if (name != null) r'name': name,
    if (startTime != null) r'startTime': startTime,
    if (endTime != null) r'endTime': endTime,
    if (date != null) r'date': date,
    if (active != null) r'active': active,
    if (approve != null) r'approve': approve,
    if (note != null) r'note': note,
    if (reason != null) r'reason': reason,
    if (timezone != null) r'timezone': timezone,
    if (weekStart != null) r'weekStart': weekStart,
    if (contactEmail != null) r'contactEmail': contactEmail,
    if (moduleId != null) r'moduleId': moduleId,
    if (enabled != null) r'enabled': enabled,
    if (draftId != null) r'draftId': draftId,
  });

  Input$FoundationInput._(this._$data);

  factory Input$FoundationInput.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    if (data.containsKey('id')) {
      final l$id = data['id'];
      result$data['id'] = (l$id as String?);
    }
    if (data.containsKey('employeeId')) {
      final l$employeeId = data['employeeId'];
      result$data['employeeId'] = (l$employeeId as String?);
    }
    if (data.containsKey('expectedVersion')) {
      final l$expectedVersion = data['expectedVersion'];
      result$data['expectedVersion'] = (l$expectedVersion as int?);
    }
    if (data.containsKey('employeeCode')) {
      final l$employeeCode = data['employeeCode'];
      result$data['employeeCode'] = (l$employeeCode as String?);
    }
    if (data.containsKey('displayName')) {
      final l$displayName = data['displayName'];
      result$data['displayName'] = (l$displayName as String?);
    }
    if (data.containsKey('workEmail')) {
      final l$workEmail = data['workEmail'];
      result$data['workEmail'] = (l$workEmail as String?);
    }
    if (data.containsKey('department')) {
      final l$department = data['department'];
      result$data['department'] = (l$department as String?);
    }
    if (data.containsKey('designation')) {
      final l$designation = data['designation'];
      result$data['designation'] = (l$designation as String?);
    }
    if (data.containsKey('phone')) {
      final l$phone = data['phone'];
      result$data['phone'] = (l$phone as String?);
    }
    if (data.containsKey('legalEmployerId')) {
      final l$legalEmployerId = data['legalEmployerId'];
      result$data['legalEmployerId'] = (l$legalEmployerId as String?);
    }
    if (data.containsKey('startsOn')) {
      final l$startsOn = data['startsOn'];
      result$data['startsOn'] = (l$startsOn as String?);
    }
    if (data.containsKey('endsOn')) {
      final l$endsOn = data['endsOn'];
      result$data['endsOn'] = (l$endsOn as String?);
    }
    if (data.containsKey('sourceSiteId')) {
      final l$sourceSiteId = data['sourceSiteId'];
      result$data['sourceSiteId'] = (l$sourceSiteId as String?);
    }
    if (data.containsKey('assignmentId')) {
      final l$assignmentId = data['assignmentId'];
      result$data['assignmentId'] = (l$assignmentId as String?);
    }
    if (data.containsKey('managerId')) {
      final l$managerId = data['managerId'];
      result$data['managerId'] = (l$managerId as String?);
    }
    if (data.containsKey('shiftId')) {
      final l$shiftId = data['shiftId'];
      result$data['shiftId'] = (l$shiftId as String?);
    }
    if (data.containsKey('kind')) {
      final l$kind = data['kind'];
      result$data['kind'] = (l$kind as String?);
    }
    if (data.containsKey('name')) {
      final l$name = data['name'];
      result$data['name'] = (l$name as String?);
    }
    if (data.containsKey('startTime')) {
      final l$startTime = data['startTime'];
      result$data['startTime'] = (l$startTime as String?);
    }
    if (data.containsKey('endTime')) {
      final l$endTime = data['endTime'];
      result$data['endTime'] = (l$endTime as String?);
    }
    if (data.containsKey('date')) {
      final l$date = data['date'];
      result$data['date'] = (l$date as String?);
    }
    if (data.containsKey('active')) {
      final l$active = data['active'];
      result$data['active'] = (l$active as bool?);
    }
    if (data.containsKey('approve')) {
      final l$approve = data['approve'];
      result$data['approve'] = (l$approve as bool?);
    }
    if (data.containsKey('note')) {
      final l$note = data['note'];
      result$data['note'] = (l$note as String?);
    }
    if (data.containsKey('reason')) {
      final l$reason = data['reason'];
      result$data['reason'] = (l$reason as String?);
    }
    if (data.containsKey('timezone')) {
      final l$timezone = data['timezone'];
      result$data['timezone'] = (l$timezone as String?);
    }
    if (data.containsKey('weekStart')) {
      final l$weekStart = data['weekStart'];
      result$data['weekStart'] = (l$weekStart as int?);
    }
    if (data.containsKey('contactEmail')) {
      final l$contactEmail = data['contactEmail'];
      result$data['contactEmail'] = (l$contactEmail as String?);
    }
    if (data.containsKey('moduleId')) {
      final l$moduleId = data['moduleId'];
      result$data['moduleId'] = (l$moduleId as String?);
    }
    if (data.containsKey('enabled')) {
      final l$enabled = data['enabled'];
      result$data['enabled'] = (l$enabled as bool?);
    }
    if (data.containsKey('draftId')) {
      final l$draftId = data['draftId'];
      result$data['draftId'] = (l$draftId as String?);
    }
    return Input$FoundationInput._(result$data);
  }

  Map<String, dynamic> _$data;

  String? get id => (_$data['id'] as String?);

  String? get employeeId => (_$data['employeeId'] as String?);

  int? get expectedVersion => (_$data['expectedVersion'] as int?);

  String? get employeeCode => (_$data['employeeCode'] as String?);

  String? get displayName => (_$data['displayName'] as String?);

  String? get workEmail => (_$data['workEmail'] as String?);

  String? get department => (_$data['department'] as String?);

  String? get designation => (_$data['designation'] as String?);

  String? get phone => (_$data['phone'] as String?);

  String? get legalEmployerId => (_$data['legalEmployerId'] as String?);

  String? get startsOn => (_$data['startsOn'] as String?);

  String? get endsOn => (_$data['endsOn'] as String?);

  String? get sourceSiteId => (_$data['sourceSiteId'] as String?);

  String? get assignmentId => (_$data['assignmentId'] as String?);

  String? get managerId => (_$data['managerId'] as String?);

  String? get shiftId => (_$data['shiftId'] as String?);

  String? get kind => (_$data['kind'] as String?);

  String? get name => (_$data['name'] as String?);

  String? get startTime => (_$data['startTime'] as String?);

  String? get endTime => (_$data['endTime'] as String?);

  String? get date => (_$data['date'] as String?);

  bool? get active => (_$data['active'] as bool?);

  bool? get approve => (_$data['approve'] as bool?);

  String? get note => (_$data['note'] as String?);

  String? get reason => (_$data['reason'] as String?);

  String? get timezone => (_$data['timezone'] as String?);

  int? get weekStart => (_$data['weekStart'] as int?);

  String? get contactEmail => (_$data['contactEmail'] as String?);

  String? get moduleId => (_$data['moduleId'] as String?);

  bool? get enabled => (_$data['enabled'] as bool?);

  String? get draftId => (_$data['draftId'] as String?);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    if (_$data.containsKey('id')) {
      final l$id = id;
      result$data['id'] = l$id;
    }
    if (_$data.containsKey('employeeId')) {
      final l$employeeId = employeeId;
      result$data['employeeId'] = l$employeeId;
    }
    if (_$data.containsKey('expectedVersion')) {
      final l$expectedVersion = expectedVersion;
      result$data['expectedVersion'] = l$expectedVersion;
    }
    if (_$data.containsKey('employeeCode')) {
      final l$employeeCode = employeeCode;
      result$data['employeeCode'] = l$employeeCode;
    }
    if (_$data.containsKey('displayName')) {
      final l$displayName = displayName;
      result$data['displayName'] = l$displayName;
    }
    if (_$data.containsKey('workEmail')) {
      final l$workEmail = workEmail;
      result$data['workEmail'] = l$workEmail;
    }
    if (_$data.containsKey('department')) {
      final l$department = department;
      result$data['department'] = l$department;
    }
    if (_$data.containsKey('designation')) {
      final l$designation = designation;
      result$data['designation'] = l$designation;
    }
    if (_$data.containsKey('phone')) {
      final l$phone = phone;
      result$data['phone'] = l$phone;
    }
    if (_$data.containsKey('legalEmployerId')) {
      final l$legalEmployerId = legalEmployerId;
      result$data['legalEmployerId'] = l$legalEmployerId;
    }
    if (_$data.containsKey('startsOn')) {
      final l$startsOn = startsOn;
      result$data['startsOn'] = l$startsOn;
    }
    if (_$data.containsKey('endsOn')) {
      final l$endsOn = endsOn;
      result$data['endsOn'] = l$endsOn;
    }
    if (_$data.containsKey('sourceSiteId')) {
      final l$sourceSiteId = sourceSiteId;
      result$data['sourceSiteId'] = l$sourceSiteId;
    }
    if (_$data.containsKey('assignmentId')) {
      final l$assignmentId = assignmentId;
      result$data['assignmentId'] = l$assignmentId;
    }
    if (_$data.containsKey('managerId')) {
      final l$managerId = managerId;
      result$data['managerId'] = l$managerId;
    }
    if (_$data.containsKey('shiftId')) {
      final l$shiftId = shiftId;
      result$data['shiftId'] = l$shiftId;
    }
    if (_$data.containsKey('kind')) {
      final l$kind = kind;
      result$data['kind'] = l$kind;
    }
    if (_$data.containsKey('name')) {
      final l$name = name;
      result$data['name'] = l$name;
    }
    if (_$data.containsKey('startTime')) {
      final l$startTime = startTime;
      result$data['startTime'] = l$startTime;
    }
    if (_$data.containsKey('endTime')) {
      final l$endTime = endTime;
      result$data['endTime'] = l$endTime;
    }
    if (_$data.containsKey('date')) {
      final l$date = date;
      result$data['date'] = l$date;
    }
    if (_$data.containsKey('active')) {
      final l$active = active;
      result$data['active'] = l$active;
    }
    if (_$data.containsKey('approve')) {
      final l$approve = approve;
      result$data['approve'] = l$approve;
    }
    if (_$data.containsKey('note')) {
      final l$note = note;
      result$data['note'] = l$note;
    }
    if (_$data.containsKey('reason')) {
      final l$reason = reason;
      result$data['reason'] = l$reason;
    }
    if (_$data.containsKey('timezone')) {
      final l$timezone = timezone;
      result$data['timezone'] = l$timezone;
    }
    if (_$data.containsKey('weekStart')) {
      final l$weekStart = weekStart;
      result$data['weekStart'] = l$weekStart;
    }
    if (_$data.containsKey('contactEmail')) {
      final l$contactEmail = contactEmail;
      result$data['contactEmail'] = l$contactEmail;
    }
    if (_$data.containsKey('moduleId')) {
      final l$moduleId = moduleId;
      result$data['moduleId'] = l$moduleId;
    }
    if (_$data.containsKey('enabled')) {
      final l$enabled = enabled;
      result$data['enabled'] = l$enabled;
    }
    if (_$data.containsKey('draftId')) {
      final l$draftId = draftId;
      result$data['draftId'] = l$draftId;
    }
    return result$data;
  }

  CopyWith$Input$FoundationInput<Input$FoundationInput> get copyWith =>
      CopyWith$Input$FoundationInput(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Input$FoundationInput || runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (_$data.containsKey('id') != other._$data.containsKey('id')) {
      return false;
    }
    if (l$id != lOther$id) {
      return false;
    }
    final l$employeeId = employeeId;
    final lOther$employeeId = other.employeeId;
    if (_$data.containsKey('employeeId') !=
        other._$data.containsKey('employeeId')) {
      return false;
    }
    if (l$employeeId != lOther$employeeId) {
      return false;
    }
    final l$expectedVersion = expectedVersion;
    final lOther$expectedVersion = other.expectedVersion;
    if (_$data.containsKey('expectedVersion') !=
        other._$data.containsKey('expectedVersion')) {
      return false;
    }
    if (l$expectedVersion != lOther$expectedVersion) {
      return false;
    }
    final l$employeeCode = employeeCode;
    final lOther$employeeCode = other.employeeCode;
    if (_$data.containsKey('employeeCode') !=
        other._$data.containsKey('employeeCode')) {
      return false;
    }
    if (l$employeeCode != lOther$employeeCode) {
      return false;
    }
    final l$displayName = displayName;
    final lOther$displayName = other.displayName;
    if (_$data.containsKey('displayName') !=
        other._$data.containsKey('displayName')) {
      return false;
    }
    if (l$displayName != lOther$displayName) {
      return false;
    }
    final l$workEmail = workEmail;
    final lOther$workEmail = other.workEmail;
    if (_$data.containsKey('workEmail') !=
        other._$data.containsKey('workEmail')) {
      return false;
    }
    if (l$workEmail != lOther$workEmail) {
      return false;
    }
    final l$department = department;
    final lOther$department = other.department;
    if (_$data.containsKey('department') !=
        other._$data.containsKey('department')) {
      return false;
    }
    if (l$department != lOther$department) {
      return false;
    }
    final l$designation = designation;
    final lOther$designation = other.designation;
    if (_$data.containsKey('designation') !=
        other._$data.containsKey('designation')) {
      return false;
    }
    if (l$designation != lOther$designation) {
      return false;
    }
    final l$phone = phone;
    final lOther$phone = other.phone;
    if (_$data.containsKey('phone') != other._$data.containsKey('phone')) {
      return false;
    }
    if (l$phone != lOther$phone) {
      return false;
    }
    final l$legalEmployerId = legalEmployerId;
    final lOther$legalEmployerId = other.legalEmployerId;
    if (_$data.containsKey('legalEmployerId') !=
        other._$data.containsKey('legalEmployerId')) {
      return false;
    }
    if (l$legalEmployerId != lOther$legalEmployerId) {
      return false;
    }
    final l$startsOn = startsOn;
    final lOther$startsOn = other.startsOn;
    if (_$data.containsKey('startsOn') !=
        other._$data.containsKey('startsOn')) {
      return false;
    }
    if (l$startsOn != lOther$startsOn) {
      return false;
    }
    final l$endsOn = endsOn;
    final lOther$endsOn = other.endsOn;
    if (_$data.containsKey('endsOn') != other._$data.containsKey('endsOn')) {
      return false;
    }
    if (l$endsOn != lOther$endsOn) {
      return false;
    }
    final l$sourceSiteId = sourceSiteId;
    final lOther$sourceSiteId = other.sourceSiteId;
    if (_$data.containsKey('sourceSiteId') !=
        other._$data.containsKey('sourceSiteId')) {
      return false;
    }
    if (l$sourceSiteId != lOther$sourceSiteId) {
      return false;
    }
    final l$assignmentId = assignmentId;
    final lOther$assignmentId = other.assignmentId;
    if (_$data.containsKey('assignmentId') !=
        other._$data.containsKey('assignmentId')) {
      return false;
    }
    if (l$assignmentId != lOther$assignmentId) {
      return false;
    }
    final l$managerId = managerId;
    final lOther$managerId = other.managerId;
    if (_$data.containsKey('managerId') !=
        other._$data.containsKey('managerId')) {
      return false;
    }
    if (l$managerId != lOther$managerId) {
      return false;
    }
    final l$shiftId = shiftId;
    final lOther$shiftId = other.shiftId;
    if (_$data.containsKey('shiftId') != other._$data.containsKey('shiftId')) {
      return false;
    }
    if (l$shiftId != lOther$shiftId) {
      return false;
    }
    final l$kind = kind;
    final lOther$kind = other.kind;
    if (_$data.containsKey('kind') != other._$data.containsKey('kind')) {
      return false;
    }
    if (l$kind != lOther$kind) {
      return false;
    }
    final l$name = name;
    final lOther$name = other.name;
    if (_$data.containsKey('name') != other._$data.containsKey('name')) {
      return false;
    }
    if (l$name != lOther$name) {
      return false;
    }
    final l$startTime = startTime;
    final lOther$startTime = other.startTime;
    if (_$data.containsKey('startTime') !=
        other._$data.containsKey('startTime')) {
      return false;
    }
    if (l$startTime != lOther$startTime) {
      return false;
    }
    final l$endTime = endTime;
    final lOther$endTime = other.endTime;
    if (_$data.containsKey('endTime') != other._$data.containsKey('endTime')) {
      return false;
    }
    if (l$endTime != lOther$endTime) {
      return false;
    }
    final l$date = date;
    final lOther$date = other.date;
    if (_$data.containsKey('date') != other._$data.containsKey('date')) {
      return false;
    }
    if (l$date != lOther$date) {
      return false;
    }
    final l$active = active;
    final lOther$active = other.active;
    if (_$data.containsKey('active') != other._$data.containsKey('active')) {
      return false;
    }
    if (l$active != lOther$active) {
      return false;
    }
    final l$approve = approve;
    final lOther$approve = other.approve;
    if (_$data.containsKey('approve') != other._$data.containsKey('approve')) {
      return false;
    }
    if (l$approve != lOther$approve) {
      return false;
    }
    final l$note = note;
    final lOther$note = other.note;
    if (_$data.containsKey('note') != other._$data.containsKey('note')) {
      return false;
    }
    if (l$note != lOther$note) {
      return false;
    }
    final l$reason = reason;
    final lOther$reason = other.reason;
    if (_$data.containsKey('reason') != other._$data.containsKey('reason')) {
      return false;
    }
    if (l$reason != lOther$reason) {
      return false;
    }
    final l$timezone = timezone;
    final lOther$timezone = other.timezone;
    if (_$data.containsKey('timezone') !=
        other._$data.containsKey('timezone')) {
      return false;
    }
    if (l$timezone != lOther$timezone) {
      return false;
    }
    final l$weekStart = weekStart;
    final lOther$weekStart = other.weekStart;
    if (_$data.containsKey('weekStart') !=
        other._$data.containsKey('weekStart')) {
      return false;
    }
    if (l$weekStart != lOther$weekStart) {
      return false;
    }
    final l$contactEmail = contactEmail;
    final lOther$contactEmail = other.contactEmail;
    if (_$data.containsKey('contactEmail') !=
        other._$data.containsKey('contactEmail')) {
      return false;
    }
    if (l$contactEmail != lOther$contactEmail) {
      return false;
    }
    final l$moduleId = moduleId;
    final lOther$moduleId = other.moduleId;
    if (_$data.containsKey('moduleId') !=
        other._$data.containsKey('moduleId')) {
      return false;
    }
    if (l$moduleId != lOther$moduleId) {
      return false;
    }
    final l$enabled = enabled;
    final lOther$enabled = other.enabled;
    if (_$data.containsKey('enabled') != other._$data.containsKey('enabled')) {
      return false;
    }
    if (l$enabled != lOther$enabled) {
      return false;
    }
    final l$draftId = draftId;
    final lOther$draftId = other.draftId;
    if (_$data.containsKey('draftId') != other._$data.containsKey('draftId')) {
      return false;
    }
    if (l$draftId != lOther$draftId) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$employeeId = employeeId;
    final l$expectedVersion = expectedVersion;
    final l$employeeCode = employeeCode;
    final l$displayName = displayName;
    final l$workEmail = workEmail;
    final l$department = department;
    final l$designation = designation;
    final l$phone = phone;
    final l$legalEmployerId = legalEmployerId;
    final l$startsOn = startsOn;
    final l$endsOn = endsOn;
    final l$sourceSiteId = sourceSiteId;
    final l$assignmentId = assignmentId;
    final l$managerId = managerId;
    final l$shiftId = shiftId;
    final l$kind = kind;
    final l$name = name;
    final l$startTime = startTime;
    final l$endTime = endTime;
    final l$date = date;
    final l$active = active;
    final l$approve = approve;
    final l$note = note;
    final l$reason = reason;
    final l$timezone = timezone;
    final l$weekStart = weekStart;
    final l$contactEmail = contactEmail;
    final l$moduleId = moduleId;
    final l$enabled = enabled;
    final l$draftId = draftId;
    return Object.hashAll([
      _$data.containsKey('id') ? l$id : const {},
      _$data.containsKey('employeeId') ? l$employeeId : const {},
      _$data.containsKey('expectedVersion') ? l$expectedVersion : const {},
      _$data.containsKey('employeeCode') ? l$employeeCode : const {},
      _$data.containsKey('displayName') ? l$displayName : const {},
      _$data.containsKey('workEmail') ? l$workEmail : const {},
      _$data.containsKey('department') ? l$department : const {},
      _$data.containsKey('designation') ? l$designation : const {},
      _$data.containsKey('phone') ? l$phone : const {},
      _$data.containsKey('legalEmployerId') ? l$legalEmployerId : const {},
      _$data.containsKey('startsOn') ? l$startsOn : const {},
      _$data.containsKey('endsOn') ? l$endsOn : const {},
      _$data.containsKey('sourceSiteId') ? l$sourceSiteId : const {},
      _$data.containsKey('assignmentId') ? l$assignmentId : const {},
      _$data.containsKey('managerId') ? l$managerId : const {},
      _$data.containsKey('shiftId') ? l$shiftId : const {},
      _$data.containsKey('kind') ? l$kind : const {},
      _$data.containsKey('name') ? l$name : const {},
      _$data.containsKey('startTime') ? l$startTime : const {},
      _$data.containsKey('endTime') ? l$endTime : const {},
      _$data.containsKey('date') ? l$date : const {},
      _$data.containsKey('active') ? l$active : const {},
      _$data.containsKey('approve') ? l$approve : const {},
      _$data.containsKey('note') ? l$note : const {},
      _$data.containsKey('reason') ? l$reason : const {},
      _$data.containsKey('timezone') ? l$timezone : const {},
      _$data.containsKey('weekStart') ? l$weekStart : const {},
      _$data.containsKey('contactEmail') ? l$contactEmail : const {},
      _$data.containsKey('moduleId') ? l$moduleId : const {},
      _$data.containsKey('enabled') ? l$enabled : const {},
      _$data.containsKey('draftId') ? l$draftId : const {},
    ]);
  }
}

abstract class CopyWith$Input$FoundationInput<TRes> {
  factory CopyWith$Input$FoundationInput(
    Input$FoundationInput instance,
    TRes Function(Input$FoundationInput) then,
  ) = _CopyWithImpl$Input$FoundationInput;

  factory CopyWith$Input$FoundationInput.stub(TRes res) =
      _CopyWithStubImpl$Input$FoundationInput;

  TRes call({
    String? id,
    String? employeeId,
    int? expectedVersion,
    String? employeeCode,
    String? displayName,
    String? workEmail,
    String? department,
    String? designation,
    String? phone,
    String? legalEmployerId,
    String? startsOn,
    String? endsOn,
    String? sourceSiteId,
    String? assignmentId,
    String? managerId,
    String? shiftId,
    String? kind,
    String? name,
    String? startTime,
    String? endTime,
    String? date,
    bool? active,
    bool? approve,
    String? note,
    String? reason,
    String? timezone,
    int? weekStart,
    String? contactEmail,
    String? moduleId,
    bool? enabled,
    String? draftId,
  });
}

class _CopyWithImpl$Input$FoundationInput<TRes>
    implements CopyWith$Input$FoundationInput<TRes> {
  _CopyWithImpl$Input$FoundationInput(this._instance, this._then);

  final Input$FoundationInput _instance;

  final TRes Function(Input$FoundationInput) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? employeeId = _undefined,
    Object? expectedVersion = _undefined,
    Object? employeeCode = _undefined,
    Object? displayName = _undefined,
    Object? workEmail = _undefined,
    Object? department = _undefined,
    Object? designation = _undefined,
    Object? phone = _undefined,
    Object? legalEmployerId = _undefined,
    Object? startsOn = _undefined,
    Object? endsOn = _undefined,
    Object? sourceSiteId = _undefined,
    Object? assignmentId = _undefined,
    Object? managerId = _undefined,
    Object? shiftId = _undefined,
    Object? kind = _undefined,
    Object? name = _undefined,
    Object? startTime = _undefined,
    Object? endTime = _undefined,
    Object? date = _undefined,
    Object? active = _undefined,
    Object? approve = _undefined,
    Object? note = _undefined,
    Object? reason = _undefined,
    Object? timezone = _undefined,
    Object? weekStart = _undefined,
    Object? contactEmail = _undefined,
    Object? moduleId = _undefined,
    Object? enabled = _undefined,
    Object? draftId = _undefined,
  }) => _then(
    Input$FoundationInput._({
      ..._instance._$data,
      if (id != _undefined) 'id': (id as String?),
      if (employeeId != _undefined) 'employeeId': (employeeId as String?),
      if (expectedVersion != _undefined)
        'expectedVersion': (expectedVersion as int?),
      if (employeeCode != _undefined) 'employeeCode': (employeeCode as String?),
      if (displayName != _undefined) 'displayName': (displayName as String?),
      if (workEmail != _undefined) 'workEmail': (workEmail as String?),
      if (department != _undefined) 'department': (department as String?),
      if (designation != _undefined) 'designation': (designation as String?),
      if (phone != _undefined) 'phone': (phone as String?),
      if (legalEmployerId != _undefined)
        'legalEmployerId': (legalEmployerId as String?),
      if (startsOn != _undefined) 'startsOn': (startsOn as String?),
      if (endsOn != _undefined) 'endsOn': (endsOn as String?),
      if (sourceSiteId != _undefined) 'sourceSiteId': (sourceSiteId as String?),
      if (assignmentId != _undefined) 'assignmentId': (assignmentId as String?),
      if (managerId != _undefined) 'managerId': (managerId as String?),
      if (shiftId != _undefined) 'shiftId': (shiftId as String?),
      if (kind != _undefined) 'kind': (kind as String?),
      if (name != _undefined) 'name': (name as String?),
      if (startTime != _undefined) 'startTime': (startTime as String?),
      if (endTime != _undefined) 'endTime': (endTime as String?),
      if (date != _undefined) 'date': (date as String?),
      if (active != _undefined) 'active': (active as bool?),
      if (approve != _undefined) 'approve': (approve as bool?),
      if (note != _undefined) 'note': (note as String?),
      if (reason != _undefined) 'reason': (reason as String?),
      if (timezone != _undefined) 'timezone': (timezone as String?),
      if (weekStart != _undefined) 'weekStart': (weekStart as int?),
      if (contactEmail != _undefined) 'contactEmail': (contactEmail as String?),
      if (moduleId != _undefined) 'moduleId': (moduleId as String?),
      if (enabled != _undefined) 'enabled': (enabled as bool?),
      if (draftId != _undefined) 'draftId': (draftId as String?),
    }),
  );
}

class _CopyWithStubImpl$Input$FoundationInput<TRes>
    implements CopyWith$Input$FoundationInput<TRes> {
  _CopyWithStubImpl$Input$FoundationInput(this._res);

  TRes _res;

  call({
    String? id,
    String? employeeId,
    int? expectedVersion,
    String? employeeCode,
    String? displayName,
    String? workEmail,
    String? department,
    String? designation,
    String? phone,
    String? legalEmployerId,
    String? startsOn,
    String? endsOn,
    String? sourceSiteId,
    String? assignmentId,
    String? managerId,
    String? shiftId,
    String? kind,
    String? name,
    String? startTime,
    String? endTime,
    String? date,
    bool? active,
    bool? approve,
    String? note,
    String? reason,
    String? timezone,
    int? weekStart,
    String? contactEmail,
    String? moduleId,
    bool? enabled,
    String? draftId,
  }) => _res;
}

class Input$EmployeeLifecycleInput {
  factory Input$EmployeeLifecycleInput({
    required String employeeId,
    required int expectedVersion,
    String? legalEmployerId,
    String? startsOn,
    String? password,
  }) => Input$EmployeeLifecycleInput._({
    r'employeeId': employeeId,
    r'expectedVersion': expectedVersion,
    if (legalEmployerId != null) r'legalEmployerId': legalEmployerId,
    if (startsOn != null) r'startsOn': startsOn,
    if (password != null) r'password': password,
  });

  Input$EmployeeLifecycleInput._(this._$data);

  factory Input$EmployeeLifecycleInput.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$employeeId = data['employeeId'];
    result$data['employeeId'] = (l$employeeId as String);
    final l$expectedVersion = data['expectedVersion'];
    result$data['expectedVersion'] = (l$expectedVersion as int);
    if (data.containsKey('legalEmployerId')) {
      final l$legalEmployerId = data['legalEmployerId'];
      result$data['legalEmployerId'] = (l$legalEmployerId as String?);
    }
    if (data.containsKey('startsOn')) {
      final l$startsOn = data['startsOn'];
      result$data['startsOn'] = (l$startsOn as String?);
    }
    if (data.containsKey('password')) {
      final l$password = data['password'];
      result$data['password'] = (l$password as String?);
    }
    return Input$EmployeeLifecycleInput._(result$data);
  }

  Map<String, dynamic> _$data;

  String get employeeId => (_$data['employeeId'] as String);

  int get expectedVersion => (_$data['expectedVersion'] as int);

  String? get legalEmployerId => (_$data['legalEmployerId'] as String?);

  String? get startsOn => (_$data['startsOn'] as String?);

  String? get password => (_$data['password'] as String?);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$employeeId = employeeId;
    result$data['employeeId'] = l$employeeId;
    final l$expectedVersion = expectedVersion;
    result$data['expectedVersion'] = l$expectedVersion;
    if (_$data.containsKey('legalEmployerId')) {
      final l$legalEmployerId = legalEmployerId;
      result$data['legalEmployerId'] = l$legalEmployerId;
    }
    if (_$data.containsKey('startsOn')) {
      final l$startsOn = startsOn;
      result$data['startsOn'] = l$startsOn;
    }
    if (_$data.containsKey('password')) {
      final l$password = password;
      result$data['password'] = l$password;
    }
    return result$data;
  }

  CopyWith$Input$EmployeeLifecycleInput<Input$EmployeeLifecycleInput>
  get copyWith => CopyWith$Input$EmployeeLifecycleInput(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Input$EmployeeLifecycleInput ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$employeeId = employeeId;
    final lOther$employeeId = other.employeeId;
    if (l$employeeId != lOther$employeeId) {
      return false;
    }
    final l$expectedVersion = expectedVersion;
    final lOther$expectedVersion = other.expectedVersion;
    if (l$expectedVersion != lOther$expectedVersion) {
      return false;
    }
    final l$legalEmployerId = legalEmployerId;
    final lOther$legalEmployerId = other.legalEmployerId;
    if (_$data.containsKey('legalEmployerId') !=
        other._$data.containsKey('legalEmployerId')) {
      return false;
    }
    if (l$legalEmployerId != lOther$legalEmployerId) {
      return false;
    }
    final l$startsOn = startsOn;
    final lOther$startsOn = other.startsOn;
    if (_$data.containsKey('startsOn') !=
        other._$data.containsKey('startsOn')) {
      return false;
    }
    if (l$startsOn != lOther$startsOn) {
      return false;
    }
    final l$password = password;
    final lOther$password = other.password;
    if (_$data.containsKey('password') !=
        other._$data.containsKey('password')) {
      return false;
    }
    if (l$password != lOther$password) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$employeeId = employeeId;
    final l$expectedVersion = expectedVersion;
    final l$legalEmployerId = legalEmployerId;
    final l$startsOn = startsOn;
    final l$password = password;
    return Object.hashAll([
      l$employeeId,
      l$expectedVersion,
      _$data.containsKey('legalEmployerId') ? l$legalEmployerId : const {},
      _$data.containsKey('startsOn') ? l$startsOn : const {},
      _$data.containsKey('password') ? l$password : const {},
    ]);
  }
}

abstract class CopyWith$Input$EmployeeLifecycleInput<TRes> {
  factory CopyWith$Input$EmployeeLifecycleInput(
    Input$EmployeeLifecycleInput instance,
    TRes Function(Input$EmployeeLifecycleInput) then,
  ) = _CopyWithImpl$Input$EmployeeLifecycleInput;

  factory CopyWith$Input$EmployeeLifecycleInput.stub(TRes res) =
      _CopyWithStubImpl$Input$EmployeeLifecycleInput;

  TRes call({
    String? employeeId,
    int? expectedVersion,
    String? legalEmployerId,
    String? startsOn,
    String? password,
  });
}

class _CopyWithImpl$Input$EmployeeLifecycleInput<TRes>
    implements CopyWith$Input$EmployeeLifecycleInput<TRes> {
  _CopyWithImpl$Input$EmployeeLifecycleInput(this._instance, this._then);

  final Input$EmployeeLifecycleInput _instance;

  final TRes Function(Input$EmployeeLifecycleInput) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? employeeId = _undefined,
    Object? expectedVersion = _undefined,
    Object? legalEmployerId = _undefined,
    Object? startsOn = _undefined,
    Object? password = _undefined,
  }) => _then(
    Input$EmployeeLifecycleInput._({
      ..._instance._$data,
      if (employeeId != _undefined && employeeId != null)
        'employeeId': (employeeId as String),
      if (expectedVersion != _undefined && expectedVersion != null)
        'expectedVersion': (expectedVersion as int),
      if (legalEmployerId != _undefined)
        'legalEmployerId': (legalEmployerId as String?),
      if (startsOn != _undefined) 'startsOn': (startsOn as String?),
      if (password != _undefined) 'password': (password as String?),
    }),
  );
}

class _CopyWithStubImpl$Input$EmployeeLifecycleInput<TRes>
    implements CopyWith$Input$EmployeeLifecycleInput<TRes> {
  _CopyWithStubImpl$Input$EmployeeLifecycleInput(this._res);

  TRes _res;

  call({
    String? employeeId,
    int? expectedVersion,
    String? legalEmployerId,
    String? startsOn,
    String? password,
  }) => _res;
}

enum Enum$__TypeKind {
  SCALAR,
  OBJECT,
  INTERFACE,
  UNION,
  ENUM,
  INPUT_OBJECT,
  LIST,
  NON_NULL,
  $unknown;

  factory Enum$__TypeKind.fromJson(String value) =>
      fromJson$Enum$__TypeKind(value);

  String toJson() => toJson$Enum$__TypeKind(this);
}

String toJson$Enum$__TypeKind(Enum$__TypeKind e) {
  switch (e) {
    case Enum$__TypeKind.SCALAR:
      return r'SCALAR';
    case Enum$__TypeKind.OBJECT:
      return r'OBJECT';
    case Enum$__TypeKind.INTERFACE:
      return r'INTERFACE';
    case Enum$__TypeKind.UNION:
      return r'UNION';
    case Enum$__TypeKind.ENUM:
      return r'ENUM';
    case Enum$__TypeKind.INPUT_OBJECT:
      return r'INPUT_OBJECT';
    case Enum$__TypeKind.LIST:
      return r'LIST';
    case Enum$__TypeKind.NON_NULL:
      return r'NON_NULL';
    case Enum$__TypeKind.$unknown:
      return r'$unknown';
  }
}

Enum$__TypeKind fromJson$Enum$__TypeKind(String value) {
  switch (value) {
    case r'SCALAR':
      return Enum$__TypeKind.SCALAR;
    case r'OBJECT':
      return Enum$__TypeKind.OBJECT;
    case r'INTERFACE':
      return Enum$__TypeKind.INTERFACE;
    case r'UNION':
      return Enum$__TypeKind.UNION;
    case r'ENUM':
      return Enum$__TypeKind.ENUM;
    case r'INPUT_OBJECT':
      return Enum$__TypeKind.INPUT_OBJECT;
    case r'LIST':
      return Enum$__TypeKind.LIST;
    case r'NON_NULL':
      return Enum$__TypeKind.NON_NULL;
    default:
      return Enum$__TypeKind.$unknown;
  }
}

enum Enum$__DirectiveLocation {
  QUERY,
  MUTATION,
  SUBSCRIPTION,
  FIELD,
  FRAGMENT_DEFINITION,
  FRAGMENT_SPREAD,
  INLINE_FRAGMENT,
  VARIABLE_DEFINITION,
  SCHEMA,
  SCALAR,
  OBJECT,
  FIELD_DEFINITION,
  ARGUMENT_DEFINITION,
  INTERFACE,
  UNION,
  ENUM,
  ENUM_VALUE,
  INPUT_OBJECT,
  INPUT_FIELD_DEFINITION,
  $unknown;

  factory Enum$__DirectiveLocation.fromJson(String value) =>
      fromJson$Enum$__DirectiveLocation(value);

  String toJson() => toJson$Enum$__DirectiveLocation(this);
}

String toJson$Enum$__DirectiveLocation(Enum$__DirectiveLocation e) {
  switch (e) {
    case Enum$__DirectiveLocation.QUERY:
      return r'QUERY';
    case Enum$__DirectiveLocation.MUTATION:
      return r'MUTATION';
    case Enum$__DirectiveLocation.SUBSCRIPTION:
      return r'SUBSCRIPTION';
    case Enum$__DirectiveLocation.FIELD:
      return r'FIELD';
    case Enum$__DirectiveLocation.FRAGMENT_DEFINITION:
      return r'FRAGMENT_DEFINITION';
    case Enum$__DirectiveLocation.FRAGMENT_SPREAD:
      return r'FRAGMENT_SPREAD';
    case Enum$__DirectiveLocation.INLINE_FRAGMENT:
      return r'INLINE_FRAGMENT';
    case Enum$__DirectiveLocation.VARIABLE_DEFINITION:
      return r'VARIABLE_DEFINITION';
    case Enum$__DirectiveLocation.SCHEMA:
      return r'SCHEMA';
    case Enum$__DirectiveLocation.SCALAR:
      return r'SCALAR';
    case Enum$__DirectiveLocation.OBJECT:
      return r'OBJECT';
    case Enum$__DirectiveLocation.FIELD_DEFINITION:
      return r'FIELD_DEFINITION';
    case Enum$__DirectiveLocation.ARGUMENT_DEFINITION:
      return r'ARGUMENT_DEFINITION';
    case Enum$__DirectiveLocation.INTERFACE:
      return r'INTERFACE';
    case Enum$__DirectiveLocation.UNION:
      return r'UNION';
    case Enum$__DirectiveLocation.ENUM:
      return r'ENUM';
    case Enum$__DirectiveLocation.ENUM_VALUE:
      return r'ENUM_VALUE';
    case Enum$__DirectiveLocation.INPUT_OBJECT:
      return r'INPUT_OBJECT';
    case Enum$__DirectiveLocation.INPUT_FIELD_DEFINITION:
      return r'INPUT_FIELD_DEFINITION';
    case Enum$__DirectiveLocation.$unknown:
      return r'$unknown';
  }
}

Enum$__DirectiveLocation fromJson$Enum$__DirectiveLocation(String value) {
  switch (value) {
    case r'QUERY':
      return Enum$__DirectiveLocation.QUERY;
    case r'MUTATION':
      return Enum$__DirectiveLocation.MUTATION;
    case r'SUBSCRIPTION':
      return Enum$__DirectiveLocation.SUBSCRIPTION;
    case r'FIELD':
      return Enum$__DirectiveLocation.FIELD;
    case r'FRAGMENT_DEFINITION':
      return Enum$__DirectiveLocation.FRAGMENT_DEFINITION;
    case r'FRAGMENT_SPREAD':
      return Enum$__DirectiveLocation.FRAGMENT_SPREAD;
    case r'INLINE_FRAGMENT':
      return Enum$__DirectiveLocation.INLINE_FRAGMENT;
    case r'VARIABLE_DEFINITION':
      return Enum$__DirectiveLocation.VARIABLE_DEFINITION;
    case r'SCHEMA':
      return Enum$__DirectiveLocation.SCHEMA;
    case r'SCALAR':
      return Enum$__DirectiveLocation.SCALAR;
    case r'OBJECT':
      return Enum$__DirectiveLocation.OBJECT;
    case r'FIELD_DEFINITION':
      return Enum$__DirectiveLocation.FIELD_DEFINITION;
    case r'ARGUMENT_DEFINITION':
      return Enum$__DirectiveLocation.ARGUMENT_DEFINITION;
    case r'INTERFACE':
      return Enum$__DirectiveLocation.INTERFACE;
    case r'UNION':
      return Enum$__DirectiveLocation.UNION;
    case r'ENUM':
      return Enum$__DirectiveLocation.ENUM;
    case r'ENUM_VALUE':
      return Enum$__DirectiveLocation.ENUM_VALUE;
    case r'INPUT_OBJECT':
      return Enum$__DirectiveLocation.INPUT_OBJECT;
    case r'INPUT_FIELD_DEFINITION':
      return Enum$__DirectiveLocation.INPUT_FIELD_DEFINITION;
    default:
      return Enum$__DirectiveLocation.$unknown;
  }
}

const possibleTypesMap = <String, Set<String>>{};
