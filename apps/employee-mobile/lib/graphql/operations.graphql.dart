import 'dart:async';

import 'package:gql/ast.dart';
import 'package:graphql/client.dart' as graphql;

import 'schema.graphql.dart';

class Fragment$PersonalFields {
  Fragment$PersonalFields({
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.personalEmail,
    this.address,
    this.permanentAddress,
    this.emergencyName,
    this.emergencyRelation,
    this.emergencyPhone,
    this.$__typename = 'EmployeePersonal',
  });

  factory Fragment$PersonalFields.fromJson(Map<String, dynamic> json) {
    final l$dateOfBirth = json['dateOfBirth'];
    final l$gender = json['gender'];
    final l$bloodGroup = json['bloodGroup'];
    final l$personalEmail = json['personalEmail'];
    final l$address = json['address'];
    final l$permanentAddress = json['permanentAddress'];
    final l$emergencyName = json['emergencyName'];
    final l$emergencyRelation = json['emergencyRelation'];
    final l$emergencyPhone = json['emergencyPhone'];
    final l$$__typename = json['__typename'];
    return Fragment$PersonalFields(
      dateOfBirth: (l$dateOfBirth as String?),
      gender: (l$gender as String?),
      bloodGroup: (l$bloodGroup as String?),
      personalEmail: (l$personalEmail as String?),
      address: (l$address as String?),
      permanentAddress: (l$permanentAddress as String?),
      emergencyName: (l$emergencyName as String?),
      emergencyRelation: (l$emergencyRelation as String?),
      emergencyPhone: (l$emergencyPhone as String?),
      $__typename: (l$$__typename as String),
    );
  }

  final String? dateOfBirth;

  final String? gender;

  final String? bloodGroup;

  final String? personalEmail;

  final String? address;

  final String? permanentAddress;

  final String? emergencyName;

  final String? emergencyRelation;

  final String? emergencyPhone;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$dateOfBirth = dateOfBirth;
    _resultData['dateOfBirth'] = l$dateOfBirth;
    final l$gender = gender;
    _resultData['gender'] = l$gender;
    final l$bloodGroup = bloodGroup;
    _resultData['bloodGroup'] = l$bloodGroup;
    final l$personalEmail = personalEmail;
    _resultData['personalEmail'] = l$personalEmail;
    final l$address = address;
    _resultData['address'] = l$address;
    final l$permanentAddress = permanentAddress;
    _resultData['permanentAddress'] = l$permanentAddress;
    final l$emergencyName = emergencyName;
    _resultData['emergencyName'] = l$emergencyName;
    final l$emergencyRelation = emergencyRelation;
    _resultData['emergencyRelation'] = l$emergencyRelation;
    final l$emergencyPhone = emergencyPhone;
    _resultData['emergencyPhone'] = l$emergencyPhone;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$dateOfBirth = dateOfBirth;
    final l$gender = gender;
    final l$bloodGroup = bloodGroup;
    final l$personalEmail = personalEmail;
    final l$address = address;
    final l$permanentAddress = permanentAddress;
    final l$emergencyName = emergencyName;
    final l$emergencyRelation = emergencyRelation;
    final l$emergencyPhone = emergencyPhone;
    final l$$__typename = $__typename;
    return Object.hashAll([
      l$dateOfBirth,
      l$gender,
      l$bloodGroup,
      l$personalEmail,
      l$address,
      l$permanentAddress,
      l$emergencyName,
      l$emergencyRelation,
      l$emergencyPhone,
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Fragment$PersonalFields || runtimeType != other.runtimeType) {
      return false;
    }
    final l$dateOfBirth = dateOfBirth;
    final lOther$dateOfBirth = other.dateOfBirth;
    if (l$dateOfBirth != lOther$dateOfBirth) {
      return false;
    }
    final l$gender = gender;
    final lOther$gender = other.gender;
    if (l$gender != lOther$gender) {
      return false;
    }
    final l$bloodGroup = bloodGroup;
    final lOther$bloodGroup = other.bloodGroup;
    if (l$bloodGroup != lOther$bloodGroup) {
      return false;
    }
    final l$personalEmail = personalEmail;
    final lOther$personalEmail = other.personalEmail;
    if (l$personalEmail != lOther$personalEmail) {
      return false;
    }
    final l$address = address;
    final lOther$address = other.address;
    if (l$address != lOther$address) {
      return false;
    }
    final l$permanentAddress = permanentAddress;
    final lOther$permanentAddress = other.permanentAddress;
    if (l$permanentAddress != lOther$permanentAddress) {
      return false;
    }
    final l$emergencyName = emergencyName;
    final lOther$emergencyName = other.emergencyName;
    if (l$emergencyName != lOther$emergencyName) {
      return false;
    }
    final l$emergencyRelation = emergencyRelation;
    final lOther$emergencyRelation = other.emergencyRelation;
    if (l$emergencyRelation != lOther$emergencyRelation) {
      return false;
    }
    final l$emergencyPhone = emergencyPhone;
    final lOther$emergencyPhone = other.emergencyPhone;
    if (l$emergencyPhone != lOther$emergencyPhone) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Fragment$PersonalFields on Fragment$PersonalFields {
  CopyWith$Fragment$PersonalFields<Fragment$PersonalFields> get copyWith =>
      CopyWith$Fragment$PersonalFields(this, (i) => i);
}

abstract class CopyWith$Fragment$PersonalFields<TRes> {
  factory CopyWith$Fragment$PersonalFields(
    Fragment$PersonalFields instance,
    TRes Function(Fragment$PersonalFields) then,
  ) = _CopyWithImpl$Fragment$PersonalFields;

  factory CopyWith$Fragment$PersonalFields.stub(TRes res) =
      _CopyWithStubImpl$Fragment$PersonalFields;

  TRes call({
    String? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? personalEmail,
    String? address,
    String? permanentAddress,
    String? emergencyName,
    String? emergencyRelation,
    String? emergencyPhone,
    String? $__typename,
  });
}

class _CopyWithImpl$Fragment$PersonalFields<TRes>
    implements CopyWith$Fragment$PersonalFields<TRes> {
  _CopyWithImpl$Fragment$PersonalFields(this._instance, this._then);

  final Fragment$PersonalFields _instance;

  final TRes Function(Fragment$PersonalFields) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? dateOfBirth = _undefined,
    Object? gender = _undefined,
    Object? bloodGroup = _undefined,
    Object? personalEmail = _undefined,
    Object? address = _undefined,
    Object? permanentAddress = _undefined,
    Object? emergencyName = _undefined,
    Object? emergencyRelation = _undefined,
    Object? emergencyPhone = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Fragment$PersonalFields(
      dateOfBirth: dateOfBirth == _undefined
          ? _instance.dateOfBirth
          : (dateOfBirth as String?),
      gender: gender == _undefined ? _instance.gender : (gender as String?),
      bloodGroup: bloodGroup == _undefined
          ? _instance.bloodGroup
          : (bloodGroup as String?),
      personalEmail: personalEmail == _undefined
          ? _instance.personalEmail
          : (personalEmail as String?),
      address: address == _undefined ? _instance.address : (address as String?),
      permanentAddress: permanentAddress == _undefined
          ? _instance.permanentAddress
          : (permanentAddress as String?),
      emergencyName: emergencyName == _undefined
          ? _instance.emergencyName
          : (emergencyName as String?),
      emergencyRelation: emergencyRelation == _undefined
          ? _instance.emergencyRelation
          : (emergencyRelation as String?),
      emergencyPhone: emergencyPhone == _undefined
          ? _instance.emergencyPhone
          : (emergencyPhone as String?),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Fragment$PersonalFields<TRes>
    implements CopyWith$Fragment$PersonalFields<TRes> {
  _CopyWithStubImpl$Fragment$PersonalFields(this._res);

  TRes _res;

  call({
    String? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? personalEmail,
    String? address,
    String? permanentAddress,
    String? emergencyName,
    String? emergencyRelation,
    String? emergencyPhone,
    String? $__typename,
  }) => _res;
}

const fragmentDefinitionPersonalFields = FragmentDefinitionNode(
  name: NameNode(value: 'PersonalFields'),
  typeCondition: TypeConditionNode(
    on: NamedTypeNode(
      name: NameNode(value: 'EmployeePersonal'),
      isNonNull: false,
    ),
  ),
  directives: [],
  selectionSet: SelectionSetNode(
    selections: [
      FieldNode(
        name: NameNode(value: 'dateOfBirth'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'gender'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'bloodGroup'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'personalEmail'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'address'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'permanentAddress'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'emergencyName'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'emergencyRelation'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'emergencyPhone'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: '__typename'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
    ],
  ),
);
const documentNodeFragmentPersonalFields = DocumentNode(
  definitions: [fragmentDefinitionPersonalFields],
);

extension ClientExtension$Fragment$PersonalFields on graphql.GraphQLClient {
  void writeFragment$PersonalFields({
    required Fragment$PersonalFields data,
    required Map<String, dynamic> idFields,
    bool broadcast = true,
  }) => this.writeFragment(
    graphql.FragmentRequest(
      idFields: idFields,
      fragment: const graphql.Fragment(
        fragmentName: 'PersonalFields',
        document: documentNodeFragmentPersonalFields,
      ),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Fragment$PersonalFields? readFragment$PersonalFields({
    required Map<String, dynamic> idFields,
    bool optimistic = true,
  }) {
    final result = this.readFragment(
      graphql.FragmentRequest(
        idFields: idFields,
        fragment: const graphql.Fragment(
          fragmentName: 'PersonalFields',
          document: documentNodeFragmentPersonalFields,
        ),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Fragment$PersonalFields.fromJson(result);
  }
}

class Fragment$EmployeeFields {
  Fragment$EmployeeFields({
    this.userId,
    required this.allowedActions,
    required this.permittedFields,
    this.salary,
    this.bank,
    this.identity,
    required this.id,
    required this.employeeCode,
    required this.displayName,
    this.workEmail,
    this.phone,
    this.personal,
    this.photoUpdatedAt,
    this.jobTitle,
    this.department,
    required this.version,
    required this.isSelf,
    required this.employment,
    required this.assignments,
    this.$__typename = 'Employee',
  });

  factory Fragment$EmployeeFields.fromJson(Map<String, dynamic> json) {
    final l$userId = json['userId'];
    final l$allowedActions = json['allowedActions'];
    final l$permittedFields = json['permittedFields'];
    final l$salary = json['salary'];
    final l$bank = json['bank'];
    final l$identity = json['identity'];
    final l$id = json['id'];
    final l$employeeCode = json['employeeCode'];
    final l$displayName = json['displayName'];
    final l$workEmail = json['workEmail'];
    final l$phone = json['phone'];
    final l$personal = json['personal'];
    final l$photoUpdatedAt = json['photoUpdatedAt'];
    final l$jobTitle = json['jobTitle'];
    final l$department = json['department'];
    final l$version = json['version'];
    final l$isSelf = json['isSelf'];
    final l$employment = json['employment'];
    final l$assignments = json['assignments'];
    final l$$__typename = json['__typename'];
    return Fragment$EmployeeFields(
      userId: (l$userId as String?),
      allowedActions: (l$allowedActions as List<dynamic>)
          .map((e) => (e as String))
          .toList(),
      permittedFields: (l$permittedFields as List<dynamic>)
          .map((e) => (e as String))
          .toList(),
      salary: (l$salary as String?),
      bank: (l$bank as String?),
      identity: (l$identity as String?),
      id: (l$id as String),
      employeeCode: (l$employeeCode as String),
      displayName: (l$displayName as String),
      workEmail: (l$workEmail as String?),
      phone: (l$phone as String?),
      personal: l$personal == null
          ? null
          : Fragment$PersonalFields.fromJson(
              (l$personal as Map<String, dynamic>),
            ),
      photoUpdatedAt: (l$photoUpdatedAt as String?),
      jobTitle: (l$jobTitle as String?),
      department: (l$department as String?),
      version: (l$version as int),
      isSelf: (l$isSelf as bool),
      employment: (l$employment as List<dynamic>)
          .map(
            (e) => Fragment$EmployeeFields$employment.fromJson(
              (e as Map<String, dynamic>),
            ),
          )
          .toList(),
      assignments: (l$assignments as List<dynamic>)
          .map(
            (e) => Fragment$EmployeeFields$assignments.fromJson(
              (e as Map<String, dynamic>),
            ),
          )
          .toList(),
      $__typename: (l$$__typename as String),
    );
  }

  final String? userId;

  final List<String> allowedActions;

  final List<String> permittedFields;

  final String? salary;

  final String? bank;

  final String? identity;

  final String id;

  final String employeeCode;

  final String displayName;

  final String? workEmail;

  final String? phone;

  final Fragment$PersonalFields? personal;

  final String? photoUpdatedAt;

  final String? jobTitle;

  final String? department;

  final int version;

  final bool isSelf;

  final List<Fragment$EmployeeFields$employment> employment;

  final List<Fragment$EmployeeFields$assignments> assignments;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$userId = userId;
    _resultData['userId'] = l$userId;
    final l$allowedActions = allowedActions;
    _resultData['allowedActions'] = l$allowedActions.map((e) => e).toList();
    final l$permittedFields = permittedFields;
    _resultData['permittedFields'] = l$permittedFields.map((e) => e).toList();
    final l$salary = salary;
    _resultData['salary'] = l$salary;
    final l$bank = bank;
    _resultData['bank'] = l$bank;
    final l$identity = identity;
    _resultData['identity'] = l$identity;
    final l$id = id;
    _resultData['id'] = l$id;
    final l$employeeCode = employeeCode;
    _resultData['employeeCode'] = l$employeeCode;
    final l$displayName = displayName;
    _resultData['displayName'] = l$displayName;
    final l$workEmail = workEmail;
    _resultData['workEmail'] = l$workEmail;
    final l$phone = phone;
    _resultData['phone'] = l$phone;
    final l$personal = personal;
    _resultData['personal'] = l$personal?.toJson();
    final l$photoUpdatedAt = photoUpdatedAt;
    _resultData['photoUpdatedAt'] = l$photoUpdatedAt;
    final l$jobTitle = jobTitle;
    _resultData['jobTitle'] = l$jobTitle;
    final l$department = department;
    _resultData['department'] = l$department;
    final l$version = version;
    _resultData['version'] = l$version;
    final l$isSelf = isSelf;
    _resultData['isSelf'] = l$isSelf;
    final l$employment = employment;
    _resultData['employment'] = l$employment.map((e) => e.toJson()).toList();
    final l$assignments = assignments;
    _resultData['assignments'] = l$assignments.map((e) => e.toJson()).toList();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$userId = userId;
    final l$allowedActions = allowedActions;
    final l$permittedFields = permittedFields;
    final l$salary = salary;
    final l$bank = bank;
    final l$identity = identity;
    final l$id = id;
    final l$employeeCode = employeeCode;
    final l$displayName = displayName;
    final l$workEmail = workEmail;
    final l$phone = phone;
    final l$personal = personal;
    final l$photoUpdatedAt = photoUpdatedAt;
    final l$jobTitle = jobTitle;
    final l$department = department;
    final l$version = version;
    final l$isSelf = isSelf;
    final l$employment = employment;
    final l$assignments = assignments;
    final l$$__typename = $__typename;
    return Object.hashAll([
      l$userId,
      Object.hashAll(l$allowedActions.map((v) => v)),
      Object.hashAll(l$permittedFields.map((v) => v)),
      l$salary,
      l$bank,
      l$identity,
      l$id,
      l$employeeCode,
      l$displayName,
      l$workEmail,
      l$phone,
      l$personal,
      l$photoUpdatedAt,
      l$jobTitle,
      l$department,
      l$version,
      l$isSelf,
      Object.hashAll(l$employment.map((v) => v)),
      Object.hashAll(l$assignments.map((v) => v)),
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Fragment$EmployeeFields || runtimeType != other.runtimeType) {
      return false;
    }
    final l$userId = userId;
    final lOther$userId = other.userId;
    if (l$userId != lOther$userId) {
      return false;
    }
    final l$allowedActions = allowedActions;
    final lOther$allowedActions = other.allowedActions;
    if (l$allowedActions.length != lOther$allowedActions.length) {
      return false;
    }
    for (int i = 0; i < l$allowedActions.length; i++) {
      final l$allowedActions$entry = l$allowedActions[i];
      final lOther$allowedActions$entry = lOther$allowedActions[i];
      if (l$allowedActions$entry != lOther$allowedActions$entry) {
        return false;
      }
    }
    final l$permittedFields = permittedFields;
    final lOther$permittedFields = other.permittedFields;
    if (l$permittedFields.length != lOther$permittedFields.length) {
      return false;
    }
    for (int i = 0; i < l$permittedFields.length; i++) {
      final l$permittedFields$entry = l$permittedFields[i];
      final lOther$permittedFields$entry = lOther$permittedFields[i];
      if (l$permittedFields$entry != lOther$permittedFields$entry) {
        return false;
      }
    }
    final l$salary = salary;
    final lOther$salary = other.salary;
    if (l$salary != lOther$salary) {
      return false;
    }
    final l$bank = bank;
    final lOther$bank = other.bank;
    if (l$bank != lOther$bank) {
      return false;
    }
    final l$identity = identity;
    final lOther$identity = other.identity;
    if (l$identity != lOther$identity) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$employeeCode = employeeCode;
    final lOther$employeeCode = other.employeeCode;
    if (l$employeeCode != lOther$employeeCode) {
      return false;
    }
    final l$displayName = displayName;
    final lOther$displayName = other.displayName;
    if (l$displayName != lOther$displayName) {
      return false;
    }
    final l$workEmail = workEmail;
    final lOther$workEmail = other.workEmail;
    if (l$workEmail != lOther$workEmail) {
      return false;
    }
    final l$phone = phone;
    final lOther$phone = other.phone;
    if (l$phone != lOther$phone) {
      return false;
    }
    final l$personal = personal;
    final lOther$personal = other.personal;
    if (l$personal != lOther$personal) {
      return false;
    }
    final l$photoUpdatedAt = photoUpdatedAt;
    final lOther$photoUpdatedAt = other.photoUpdatedAt;
    if (l$photoUpdatedAt != lOther$photoUpdatedAt) {
      return false;
    }
    final l$jobTitle = jobTitle;
    final lOther$jobTitle = other.jobTitle;
    if (l$jobTitle != lOther$jobTitle) {
      return false;
    }
    final l$department = department;
    final lOther$department = other.department;
    if (l$department != lOther$department) {
      return false;
    }
    final l$version = version;
    final lOther$version = other.version;
    if (l$version != lOther$version) {
      return false;
    }
    final l$isSelf = isSelf;
    final lOther$isSelf = other.isSelf;
    if (l$isSelf != lOther$isSelf) {
      return false;
    }
    final l$employment = employment;
    final lOther$employment = other.employment;
    if (l$employment.length != lOther$employment.length) {
      return false;
    }
    for (int i = 0; i < l$employment.length; i++) {
      final l$employment$entry = l$employment[i];
      final lOther$employment$entry = lOther$employment[i];
      if (l$employment$entry != lOther$employment$entry) {
        return false;
      }
    }
    final l$assignments = assignments;
    final lOther$assignments = other.assignments;
    if (l$assignments.length != lOther$assignments.length) {
      return false;
    }
    for (int i = 0; i < l$assignments.length; i++) {
      final l$assignments$entry = l$assignments[i];
      final lOther$assignments$entry = lOther$assignments[i];
      if (l$assignments$entry != lOther$assignments$entry) {
        return false;
      }
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Fragment$EmployeeFields on Fragment$EmployeeFields {
  CopyWith$Fragment$EmployeeFields<Fragment$EmployeeFields> get copyWith =>
      CopyWith$Fragment$EmployeeFields(this, (i) => i);
}

abstract class CopyWith$Fragment$EmployeeFields<TRes> {
  factory CopyWith$Fragment$EmployeeFields(
    Fragment$EmployeeFields instance,
    TRes Function(Fragment$EmployeeFields) then,
  ) = _CopyWithImpl$Fragment$EmployeeFields;

  factory CopyWith$Fragment$EmployeeFields.stub(TRes res) =
      _CopyWithStubImpl$Fragment$EmployeeFields;

  TRes call({
    String? userId,
    List<String>? allowedActions,
    List<String>? permittedFields,
    String? salary,
    String? bank,
    String? identity,
    String? id,
    String? employeeCode,
    String? displayName,
    String? workEmail,
    String? phone,
    Fragment$PersonalFields? personal,
    String? photoUpdatedAt,
    String? jobTitle,
    String? department,
    int? version,
    bool? isSelf,
    List<Fragment$EmployeeFields$employment>? employment,
    List<Fragment$EmployeeFields$assignments>? assignments,
    String? $__typename,
  });
  CopyWith$Fragment$PersonalFields<TRes> get personal;
  TRes employment(
    Iterable<Fragment$EmployeeFields$employment> Function(
      Iterable<
        CopyWith$Fragment$EmployeeFields$employment<
          Fragment$EmployeeFields$employment
        >
      >,
    )
    _fn,
  );
  TRes assignments(
    Iterable<Fragment$EmployeeFields$assignments> Function(
      Iterable<
        CopyWith$Fragment$EmployeeFields$assignments<
          Fragment$EmployeeFields$assignments
        >
      >,
    )
    _fn,
  );
}

class _CopyWithImpl$Fragment$EmployeeFields<TRes>
    implements CopyWith$Fragment$EmployeeFields<TRes> {
  _CopyWithImpl$Fragment$EmployeeFields(this._instance, this._then);

  final Fragment$EmployeeFields _instance;

  final TRes Function(Fragment$EmployeeFields) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? userId = _undefined,
    Object? allowedActions = _undefined,
    Object? permittedFields = _undefined,
    Object? salary = _undefined,
    Object? bank = _undefined,
    Object? identity = _undefined,
    Object? id = _undefined,
    Object? employeeCode = _undefined,
    Object? displayName = _undefined,
    Object? workEmail = _undefined,
    Object? phone = _undefined,
    Object? personal = _undefined,
    Object? photoUpdatedAt = _undefined,
    Object? jobTitle = _undefined,
    Object? department = _undefined,
    Object? version = _undefined,
    Object? isSelf = _undefined,
    Object? employment = _undefined,
    Object? assignments = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Fragment$EmployeeFields(
      userId: userId == _undefined ? _instance.userId : (userId as String?),
      allowedActions: allowedActions == _undefined || allowedActions == null
          ? _instance.allowedActions
          : (allowedActions as List<String>),
      permittedFields: permittedFields == _undefined || permittedFields == null
          ? _instance.permittedFields
          : (permittedFields as List<String>),
      salary: salary == _undefined ? _instance.salary : (salary as String?),
      bank: bank == _undefined ? _instance.bank : (bank as String?),
      identity: identity == _undefined
          ? _instance.identity
          : (identity as String?),
      id: id == _undefined || id == null ? _instance.id : (id as String),
      employeeCode: employeeCode == _undefined || employeeCode == null
          ? _instance.employeeCode
          : (employeeCode as String),
      displayName: displayName == _undefined || displayName == null
          ? _instance.displayName
          : (displayName as String),
      workEmail: workEmail == _undefined
          ? _instance.workEmail
          : (workEmail as String?),
      phone: phone == _undefined ? _instance.phone : (phone as String?),
      personal: personal == _undefined
          ? _instance.personal
          : (personal as Fragment$PersonalFields?),
      photoUpdatedAt: photoUpdatedAt == _undefined
          ? _instance.photoUpdatedAt
          : (photoUpdatedAt as String?),
      jobTitle: jobTitle == _undefined
          ? _instance.jobTitle
          : (jobTitle as String?),
      department: department == _undefined
          ? _instance.department
          : (department as String?),
      version: version == _undefined || version == null
          ? _instance.version
          : (version as int),
      isSelf: isSelf == _undefined || isSelf == null
          ? _instance.isSelf
          : (isSelf as bool),
      employment: employment == _undefined || employment == null
          ? _instance.employment
          : (employment as List<Fragment$EmployeeFields$employment>),
      assignments: assignments == _undefined || assignments == null
          ? _instance.assignments
          : (assignments as List<Fragment$EmployeeFields$assignments>),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Fragment$PersonalFields<TRes> get personal {
    final local$personal = _instance.personal;
    return local$personal == null
        ? CopyWith$Fragment$PersonalFields.stub(_then(_instance))
        : CopyWith$Fragment$PersonalFields(
            local$personal,
            (e) => call(personal: e),
          );
  }

  TRes employment(
    Iterable<Fragment$EmployeeFields$employment> Function(
      Iterable<
        CopyWith$Fragment$EmployeeFields$employment<
          Fragment$EmployeeFields$employment
        >
      >,
    )
    _fn,
  ) => call(
    employment: _fn(
      _instance.employment.map(
        (e) => CopyWith$Fragment$EmployeeFields$employment(e, (i) => i),
      ),
    ).toList(),
  );

  TRes assignments(
    Iterable<Fragment$EmployeeFields$assignments> Function(
      Iterable<
        CopyWith$Fragment$EmployeeFields$assignments<
          Fragment$EmployeeFields$assignments
        >
      >,
    )
    _fn,
  ) => call(
    assignments: _fn(
      _instance.assignments.map(
        (e) => CopyWith$Fragment$EmployeeFields$assignments(e, (i) => i),
      ),
    ).toList(),
  );
}

class _CopyWithStubImpl$Fragment$EmployeeFields<TRes>
    implements CopyWith$Fragment$EmployeeFields<TRes> {
  _CopyWithStubImpl$Fragment$EmployeeFields(this._res);

  TRes _res;

  call({
    String? userId,
    List<String>? allowedActions,
    List<String>? permittedFields,
    String? salary,
    String? bank,
    String? identity,
    String? id,
    String? employeeCode,
    String? displayName,
    String? workEmail,
    String? phone,
    Fragment$PersonalFields? personal,
    String? photoUpdatedAt,
    String? jobTitle,
    String? department,
    int? version,
    bool? isSelf,
    List<Fragment$EmployeeFields$employment>? employment,
    List<Fragment$EmployeeFields$assignments>? assignments,
    String? $__typename,
  }) => _res;

  CopyWith$Fragment$PersonalFields<TRes> get personal =>
      CopyWith$Fragment$PersonalFields.stub(_res);

  employment(_fn) => _res;

  assignments(_fn) => _res;
}

const fragmentDefinitionEmployeeFields = FragmentDefinitionNode(
  name: NameNode(value: 'EmployeeFields'),
  typeCondition: TypeConditionNode(
    on: NamedTypeNode(name: NameNode(value: 'Employee'), isNonNull: false),
  ),
  directives: [],
  selectionSet: SelectionSetNode(
    selections: [
      FieldNode(
        name: NameNode(value: 'userId'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'allowedActions'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'permittedFields'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'salary'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'bank'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'identity'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'id'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'employeeCode'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'displayName'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'workEmail'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'phone'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'personal'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: SelectionSetNode(
          selections: [
            FragmentSpreadNode(
              name: NameNode(value: 'PersonalFields'),
              directives: [],
            ),
            FieldNode(
              name: NameNode(value: '__typename'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null,
            ),
          ],
        ),
      ),
      FieldNode(
        name: NameNode(value: 'photoUpdatedAt'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'jobTitle'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'department'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'version'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'isSelf'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'employment'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: SelectionSetNode(
          selections: [
            FieldNode(
              name: NameNode(value: 'id'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null,
            ),
            FieldNode(
              name: NameNode(value: 'startsOn'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null,
            ),
            FieldNode(
              name: NameNode(value: 'endsOn'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null,
            ),
            FieldNode(
              name: NameNode(value: 'legalEmployer'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: SelectionSetNode(
                selections: [
                  FieldNode(
                    name: NameNode(value: 'id'),
                    alias: null,
                    arguments: [],
                    directives: [],
                    selectionSet: null,
                  ),
                  FieldNode(
                    name: NameNode(value: 'name'),
                    alias: null,
                    arguments: [],
                    directives: [],
                    selectionSet: null,
                  ),
                  FieldNode(
                    name: NameNode(value: '__typename'),
                    alias: null,
                    arguments: [],
                    directives: [],
                    selectionSet: null,
                  ),
                ],
              ),
            ),
            FieldNode(
              name: NameNode(value: '__typename'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null,
            ),
          ],
        ),
      ),
      FieldNode(
        name: NameNode(value: 'assignments'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: SelectionSetNode(
          selections: [
            FieldNode(
              name: NameNode(value: 'id'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null,
            ),
            FieldNode(
              name: NameNode(value: 'startsOn'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null,
            ),
            FieldNode(
              name: NameNode(value: 'endsOn'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null,
            ),
            FieldNode(
              name: NameNode(value: 'site'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: SelectionSetNode(
                selections: [
                  FieldNode(
                    name: NameNode(value: 'id'),
                    alias: null,
                    arguments: [],
                    directives: [],
                    selectionSet: null,
                  ),
                  FieldNode(
                    name: NameNode(value: 'name'),
                    alias: null,
                    arguments: [],
                    directives: [],
                    selectionSet: null,
                  ),
                  FieldNode(
                    name: NameNode(value: 'timezone'),
                    alias: null,
                    arguments: [],
                    directives: [],
                    selectionSet: null,
                  ),
                  FieldNode(
                    name: NameNode(value: '__typename'),
                    alias: null,
                    arguments: [],
                    directives: [],
                    selectionSet: null,
                  ),
                ],
              ),
            ),
            FieldNode(
              name: NameNode(value: '__typename'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null,
            ),
          ],
        ),
      ),
      FieldNode(
        name: NameNode(value: '__typename'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
    ],
  ),
);
const documentNodeFragmentEmployeeFields = DocumentNode(
  definitions: [
    fragmentDefinitionEmployeeFields,
    fragmentDefinitionPersonalFields,
  ],
);

extension ClientExtension$Fragment$EmployeeFields on graphql.GraphQLClient {
  void writeFragment$EmployeeFields({
    required Fragment$EmployeeFields data,
    required Map<String, dynamic> idFields,
    bool broadcast = true,
  }) => this.writeFragment(
    graphql.FragmentRequest(
      idFields: idFields,
      fragment: const graphql.Fragment(
        fragmentName: 'EmployeeFields',
        document: documentNodeFragmentEmployeeFields,
      ),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Fragment$EmployeeFields? readFragment$EmployeeFields({
    required Map<String, dynamic> idFields,
    bool optimistic = true,
  }) {
    final result = this.readFragment(
      graphql.FragmentRequest(
        idFields: idFields,
        fragment: const graphql.Fragment(
          fragmentName: 'EmployeeFields',
          document: documentNodeFragmentEmployeeFields,
        ),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Fragment$EmployeeFields.fromJson(result);
  }
}

class Fragment$EmployeeFields$employment {
  Fragment$EmployeeFields$employment({
    required this.id,
    required this.startsOn,
    this.endsOn,
    required this.legalEmployer,
    this.$__typename = 'Employment',
  });

  factory Fragment$EmployeeFields$employment.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$id = json['id'];
    final l$startsOn = json['startsOn'];
    final l$endsOn = json['endsOn'];
    final l$legalEmployer = json['legalEmployer'];
    final l$$__typename = json['__typename'];
    return Fragment$EmployeeFields$employment(
      id: (l$id as String),
      startsOn: (l$startsOn as String),
      endsOn: (l$endsOn as String?),
      legalEmployer: Fragment$EmployeeFields$employment$legalEmployer.fromJson(
        (l$legalEmployer as Map<String, dynamic>),
      ),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String startsOn;

  final String? endsOn;

  final Fragment$EmployeeFields$employment$legalEmployer legalEmployer;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$startsOn = startsOn;
    _resultData['startsOn'] = l$startsOn;
    final l$endsOn = endsOn;
    _resultData['endsOn'] = l$endsOn;
    final l$legalEmployer = legalEmployer;
    _resultData['legalEmployer'] = l$legalEmployer.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$startsOn = startsOn;
    final l$endsOn = endsOn;
    final l$legalEmployer = legalEmployer;
    final l$$__typename = $__typename;
    return Object.hashAll([
      l$id,
      l$startsOn,
      l$endsOn,
      l$legalEmployer,
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Fragment$EmployeeFields$employment ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$startsOn = startsOn;
    final lOther$startsOn = other.startsOn;
    if (l$startsOn != lOther$startsOn) {
      return false;
    }
    final l$endsOn = endsOn;
    final lOther$endsOn = other.endsOn;
    if (l$endsOn != lOther$endsOn) {
      return false;
    }
    final l$legalEmployer = legalEmployer;
    final lOther$legalEmployer = other.legalEmployer;
    if (l$legalEmployer != lOther$legalEmployer) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Fragment$EmployeeFields$employment
    on Fragment$EmployeeFields$employment {
  CopyWith$Fragment$EmployeeFields$employment<
    Fragment$EmployeeFields$employment
  >
  get copyWith => CopyWith$Fragment$EmployeeFields$employment(this, (i) => i);
}

abstract class CopyWith$Fragment$EmployeeFields$employment<TRes> {
  factory CopyWith$Fragment$EmployeeFields$employment(
    Fragment$EmployeeFields$employment instance,
    TRes Function(Fragment$EmployeeFields$employment) then,
  ) = _CopyWithImpl$Fragment$EmployeeFields$employment;

  factory CopyWith$Fragment$EmployeeFields$employment.stub(TRes res) =
      _CopyWithStubImpl$Fragment$EmployeeFields$employment;

  TRes call({
    String? id,
    String? startsOn,
    String? endsOn,
    Fragment$EmployeeFields$employment$legalEmployer? legalEmployer,
    String? $__typename,
  });
  CopyWith$Fragment$EmployeeFields$employment$legalEmployer<TRes>
  get legalEmployer;
}

class _CopyWithImpl$Fragment$EmployeeFields$employment<TRes>
    implements CopyWith$Fragment$EmployeeFields$employment<TRes> {
  _CopyWithImpl$Fragment$EmployeeFields$employment(this._instance, this._then);

  final Fragment$EmployeeFields$employment _instance;

  final TRes Function(Fragment$EmployeeFields$employment) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? startsOn = _undefined,
    Object? endsOn = _undefined,
    Object? legalEmployer = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Fragment$EmployeeFields$employment(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      startsOn: startsOn == _undefined || startsOn == null
          ? _instance.startsOn
          : (startsOn as String),
      endsOn: endsOn == _undefined ? _instance.endsOn : (endsOn as String?),
      legalEmployer: legalEmployer == _undefined || legalEmployer == null
          ? _instance.legalEmployer
          : (legalEmployer as Fragment$EmployeeFields$employment$legalEmployer),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Fragment$EmployeeFields$employment$legalEmployer<TRes>
  get legalEmployer {
    final local$legalEmployer = _instance.legalEmployer;
    return CopyWith$Fragment$EmployeeFields$employment$legalEmployer(
      local$legalEmployer,
      (e) => call(legalEmployer: e),
    );
  }
}

class _CopyWithStubImpl$Fragment$EmployeeFields$employment<TRes>
    implements CopyWith$Fragment$EmployeeFields$employment<TRes> {
  _CopyWithStubImpl$Fragment$EmployeeFields$employment(this._res);

  TRes _res;

  call({
    String? id,
    String? startsOn,
    String? endsOn,
    Fragment$EmployeeFields$employment$legalEmployer? legalEmployer,
    String? $__typename,
  }) => _res;

  CopyWith$Fragment$EmployeeFields$employment$legalEmployer<TRes>
  get legalEmployer =>
      CopyWith$Fragment$EmployeeFields$employment$legalEmployer.stub(_res);
}

class Fragment$EmployeeFields$employment$legalEmployer {
  Fragment$EmployeeFields$employment$legalEmployer({
    required this.id,
    required this.name,
    this.$__typename = 'LegalEmployer',
  });

  factory Fragment$EmployeeFields$employment$legalEmployer.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$id = json['id'];
    final l$name = json['name'];
    final l$$__typename = json['__typename'];
    return Fragment$EmployeeFields$employment$legalEmployer(
      id: (l$id as String),
      name: (l$name as String),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String name;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$name = name;
    _resultData['name'] = l$name;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$name = name;
    final l$$__typename = $__typename;
    return Object.hashAll([l$id, l$name, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Fragment$EmployeeFields$employment$legalEmployer ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$name = name;
    final lOther$name = other.name;
    if (l$name != lOther$name) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Fragment$EmployeeFields$employment$legalEmployer
    on Fragment$EmployeeFields$employment$legalEmployer {
  CopyWith$Fragment$EmployeeFields$employment$legalEmployer<
    Fragment$EmployeeFields$employment$legalEmployer
  >
  get copyWith =>
      CopyWith$Fragment$EmployeeFields$employment$legalEmployer(this, (i) => i);
}

abstract class CopyWith$Fragment$EmployeeFields$employment$legalEmployer<TRes> {
  factory CopyWith$Fragment$EmployeeFields$employment$legalEmployer(
    Fragment$EmployeeFields$employment$legalEmployer instance,
    TRes Function(Fragment$EmployeeFields$employment$legalEmployer) then,
  ) = _CopyWithImpl$Fragment$EmployeeFields$employment$legalEmployer;

  factory CopyWith$Fragment$EmployeeFields$employment$legalEmployer.stub(
    TRes res,
  ) = _CopyWithStubImpl$Fragment$EmployeeFields$employment$legalEmployer;

  TRes call({String? id, String? name, String? $__typename});
}

class _CopyWithImpl$Fragment$EmployeeFields$employment$legalEmployer<TRes>
    implements CopyWith$Fragment$EmployeeFields$employment$legalEmployer<TRes> {
  _CopyWithImpl$Fragment$EmployeeFields$employment$legalEmployer(
    this._instance,
    this._then,
  );

  final Fragment$EmployeeFields$employment$legalEmployer _instance;

  final TRes Function(Fragment$EmployeeFields$employment$legalEmployer) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? name = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Fragment$EmployeeFields$employment$legalEmployer(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      name: name == _undefined || name == null
          ? _instance.name
          : (name as String),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Fragment$EmployeeFields$employment$legalEmployer<TRes>
    implements CopyWith$Fragment$EmployeeFields$employment$legalEmployer<TRes> {
  _CopyWithStubImpl$Fragment$EmployeeFields$employment$legalEmployer(this._res);

  TRes _res;

  call({String? id, String? name, String? $__typename}) => _res;
}

class Fragment$EmployeeFields$assignments {
  Fragment$EmployeeFields$assignments({
    required this.id,
    required this.startsOn,
    this.endsOn,
    required this.site,
    this.$__typename = 'SiteAssignment',
  });

  factory Fragment$EmployeeFields$assignments.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$id = json['id'];
    final l$startsOn = json['startsOn'];
    final l$endsOn = json['endsOn'];
    final l$site = json['site'];
    final l$$__typename = json['__typename'];
    return Fragment$EmployeeFields$assignments(
      id: (l$id as String),
      startsOn: (l$startsOn as String),
      endsOn: (l$endsOn as String?),
      site: Fragment$EmployeeFields$assignments$site.fromJson(
        (l$site as Map<String, dynamic>),
      ),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String startsOn;

  final String? endsOn;

  final Fragment$EmployeeFields$assignments$site site;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$startsOn = startsOn;
    _resultData['startsOn'] = l$startsOn;
    final l$endsOn = endsOn;
    _resultData['endsOn'] = l$endsOn;
    final l$site = site;
    _resultData['site'] = l$site.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$startsOn = startsOn;
    final l$endsOn = endsOn;
    final l$site = site;
    final l$$__typename = $__typename;
    return Object.hashAll([l$id, l$startsOn, l$endsOn, l$site, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Fragment$EmployeeFields$assignments ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$startsOn = startsOn;
    final lOther$startsOn = other.startsOn;
    if (l$startsOn != lOther$startsOn) {
      return false;
    }
    final l$endsOn = endsOn;
    final lOther$endsOn = other.endsOn;
    if (l$endsOn != lOther$endsOn) {
      return false;
    }
    final l$site = site;
    final lOther$site = other.site;
    if (l$site != lOther$site) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Fragment$EmployeeFields$assignments
    on Fragment$EmployeeFields$assignments {
  CopyWith$Fragment$EmployeeFields$assignments<
    Fragment$EmployeeFields$assignments
  >
  get copyWith => CopyWith$Fragment$EmployeeFields$assignments(this, (i) => i);
}

abstract class CopyWith$Fragment$EmployeeFields$assignments<TRes> {
  factory CopyWith$Fragment$EmployeeFields$assignments(
    Fragment$EmployeeFields$assignments instance,
    TRes Function(Fragment$EmployeeFields$assignments) then,
  ) = _CopyWithImpl$Fragment$EmployeeFields$assignments;

  factory CopyWith$Fragment$EmployeeFields$assignments.stub(TRes res) =
      _CopyWithStubImpl$Fragment$EmployeeFields$assignments;

  TRes call({
    String? id,
    String? startsOn,
    String? endsOn,
    Fragment$EmployeeFields$assignments$site? site,
    String? $__typename,
  });
  CopyWith$Fragment$EmployeeFields$assignments$site<TRes> get site;
}

class _CopyWithImpl$Fragment$EmployeeFields$assignments<TRes>
    implements CopyWith$Fragment$EmployeeFields$assignments<TRes> {
  _CopyWithImpl$Fragment$EmployeeFields$assignments(this._instance, this._then);

  final Fragment$EmployeeFields$assignments _instance;

  final TRes Function(Fragment$EmployeeFields$assignments) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? startsOn = _undefined,
    Object? endsOn = _undefined,
    Object? site = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Fragment$EmployeeFields$assignments(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      startsOn: startsOn == _undefined || startsOn == null
          ? _instance.startsOn
          : (startsOn as String),
      endsOn: endsOn == _undefined ? _instance.endsOn : (endsOn as String?),
      site: site == _undefined || site == null
          ? _instance.site
          : (site as Fragment$EmployeeFields$assignments$site),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Fragment$EmployeeFields$assignments$site<TRes> get site {
    final local$site = _instance.site;
    return CopyWith$Fragment$EmployeeFields$assignments$site(
      local$site,
      (e) => call(site: e),
    );
  }
}

class _CopyWithStubImpl$Fragment$EmployeeFields$assignments<TRes>
    implements CopyWith$Fragment$EmployeeFields$assignments<TRes> {
  _CopyWithStubImpl$Fragment$EmployeeFields$assignments(this._res);

  TRes _res;

  call({
    String? id,
    String? startsOn,
    String? endsOn,
    Fragment$EmployeeFields$assignments$site? site,
    String? $__typename,
  }) => _res;

  CopyWith$Fragment$EmployeeFields$assignments$site<TRes> get site =>
      CopyWith$Fragment$EmployeeFields$assignments$site.stub(_res);
}

class Fragment$EmployeeFields$assignments$site {
  Fragment$EmployeeFields$assignments$site({
    required this.id,
    required this.name,
    required this.timezone,
    this.$__typename = 'Site',
  });

  factory Fragment$EmployeeFields$assignments$site.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$id = json['id'];
    final l$name = json['name'];
    final l$timezone = json['timezone'];
    final l$$__typename = json['__typename'];
    return Fragment$EmployeeFields$assignments$site(
      id: (l$id as String),
      name: (l$name as String),
      timezone: (l$timezone as String),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String name;

  final String timezone;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$name = name;
    _resultData['name'] = l$name;
    final l$timezone = timezone;
    _resultData['timezone'] = l$timezone;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$name = name;
    final l$timezone = timezone;
    final l$$__typename = $__typename;
    return Object.hashAll([l$id, l$name, l$timezone, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Fragment$EmployeeFields$assignments$site ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$name = name;
    final lOther$name = other.name;
    if (l$name != lOther$name) {
      return false;
    }
    final l$timezone = timezone;
    final lOther$timezone = other.timezone;
    if (l$timezone != lOther$timezone) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Fragment$EmployeeFields$assignments$site
    on Fragment$EmployeeFields$assignments$site {
  CopyWith$Fragment$EmployeeFields$assignments$site<
    Fragment$EmployeeFields$assignments$site
  >
  get copyWith =>
      CopyWith$Fragment$EmployeeFields$assignments$site(this, (i) => i);
}

abstract class CopyWith$Fragment$EmployeeFields$assignments$site<TRes> {
  factory CopyWith$Fragment$EmployeeFields$assignments$site(
    Fragment$EmployeeFields$assignments$site instance,
    TRes Function(Fragment$EmployeeFields$assignments$site) then,
  ) = _CopyWithImpl$Fragment$EmployeeFields$assignments$site;

  factory CopyWith$Fragment$EmployeeFields$assignments$site.stub(TRes res) =
      _CopyWithStubImpl$Fragment$EmployeeFields$assignments$site;

  TRes call({String? id, String? name, String? timezone, String? $__typename});
}

class _CopyWithImpl$Fragment$EmployeeFields$assignments$site<TRes>
    implements CopyWith$Fragment$EmployeeFields$assignments$site<TRes> {
  _CopyWithImpl$Fragment$EmployeeFields$assignments$site(
    this._instance,
    this._then,
  );

  final Fragment$EmployeeFields$assignments$site _instance;

  final TRes Function(Fragment$EmployeeFields$assignments$site) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? name = _undefined,
    Object? timezone = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Fragment$EmployeeFields$assignments$site(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      name: name == _undefined || name == null
          ? _instance.name
          : (name as String),
      timezone: timezone == _undefined || timezone == null
          ? _instance.timezone
          : (timezone as String),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Fragment$EmployeeFields$assignments$site<TRes>
    implements CopyWith$Fragment$EmployeeFields$assignments$site<TRes> {
  _CopyWithStubImpl$Fragment$EmployeeFields$assignments$site(this._res);

  TRes _res;

  call({String? id, String? name, String? timezone, String? $__typename}) =>
      _res;
}

class Fragment$EmployeeAdminFields {
  Fragment$EmployeeAdminFields({
    this.status,
    this.login,
    this.$__typename = 'Employee',
  });

  factory Fragment$EmployeeAdminFields.fromJson(Map<String, dynamic> json) {
    final l$status = json['status'];
    final l$login = json['login'];
    final l$$__typename = json['__typename'];
    return Fragment$EmployeeAdminFields(
      status: (l$status as String?),
      login: l$login == null
          ? null
          : Fragment$EmployeeAdminFields$login.fromJson(
              (l$login as Map<String, dynamic>),
            ),
      $__typename: (l$$__typename as String),
    );
  }

  final String? status;

  final Fragment$EmployeeAdminFields$login? login;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$status = status;
    _resultData['status'] = l$status;
    final l$login = login;
    _resultData['login'] = l$login?.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$status = status;
    final l$login = login;
    final l$$__typename = $__typename;
    return Object.hashAll([l$status, l$login, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Fragment$EmployeeAdminFields ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$status = status;
    final lOther$status = other.status;
    if (l$status != lOther$status) {
      return false;
    }
    final l$login = login;
    final lOther$login = other.login;
    if (l$login != lOther$login) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Fragment$EmployeeAdminFields
    on Fragment$EmployeeAdminFields {
  CopyWith$Fragment$EmployeeAdminFields<Fragment$EmployeeAdminFields>
  get copyWith => CopyWith$Fragment$EmployeeAdminFields(this, (i) => i);
}

abstract class CopyWith$Fragment$EmployeeAdminFields<TRes> {
  factory CopyWith$Fragment$EmployeeAdminFields(
    Fragment$EmployeeAdminFields instance,
    TRes Function(Fragment$EmployeeAdminFields) then,
  ) = _CopyWithImpl$Fragment$EmployeeAdminFields;

  factory CopyWith$Fragment$EmployeeAdminFields.stub(TRes res) =
      _CopyWithStubImpl$Fragment$EmployeeAdminFields;

  TRes call({
    String? status,
    Fragment$EmployeeAdminFields$login? login,
    String? $__typename,
  });
  CopyWith$Fragment$EmployeeAdminFields$login<TRes> get login;
}

class _CopyWithImpl$Fragment$EmployeeAdminFields<TRes>
    implements CopyWith$Fragment$EmployeeAdminFields<TRes> {
  _CopyWithImpl$Fragment$EmployeeAdminFields(this._instance, this._then);

  final Fragment$EmployeeAdminFields _instance;

  final TRes Function(Fragment$EmployeeAdminFields) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? status = _undefined,
    Object? login = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Fragment$EmployeeAdminFields(
      status: status == _undefined ? _instance.status : (status as String?),
      login: login == _undefined
          ? _instance.login
          : (login as Fragment$EmployeeAdminFields$login?),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Fragment$EmployeeAdminFields$login<TRes> get login {
    final local$login = _instance.login;
    return local$login == null
        ? CopyWith$Fragment$EmployeeAdminFields$login.stub(_then(_instance))
        : CopyWith$Fragment$EmployeeAdminFields$login(
            local$login,
            (e) => call(login: e),
          );
  }
}

class _CopyWithStubImpl$Fragment$EmployeeAdminFields<TRes>
    implements CopyWith$Fragment$EmployeeAdminFields<TRes> {
  _CopyWithStubImpl$Fragment$EmployeeAdminFields(this._res);

  TRes _res;

  call({
    String? status,
    Fragment$EmployeeAdminFields$login? login,
    String? $__typename,
  }) => _res;

  CopyWith$Fragment$EmployeeAdminFields$login<TRes> get login =>
      CopyWith$Fragment$EmployeeAdminFields$login.stub(_res);
}

const fragmentDefinitionEmployeeAdminFields = FragmentDefinitionNode(
  name: NameNode(value: 'EmployeeAdminFields'),
  typeCondition: TypeConditionNode(
    on: NamedTypeNode(name: NameNode(value: 'Employee'), isNonNull: false),
  ),
  directives: [],
  selectionSet: SelectionSetNode(
    selections: [
      FieldNode(
        name: NameNode(value: 'status'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'login'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: SelectionSetNode(
          selections: [
            FieldNode(
              name: NameNode(value: 'status'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null,
            ),
            FieldNode(
              name: NameNode(value: 'loginId'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null,
            ),
            FieldNode(
              name: NameNode(value: 'lastSignInAt'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null,
            ),
            FieldNode(
              name: NameNode(value: 'devices'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null,
            ),
            FieldNode(
              name: NameNode(value: 'protected'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null,
            ),
            FieldNode(
              name: NameNode(value: '__typename'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null,
            ),
          ],
        ),
      ),
      FieldNode(
        name: NameNode(value: '__typename'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
    ],
  ),
);
const documentNodeFragmentEmployeeAdminFields = DocumentNode(
  definitions: [fragmentDefinitionEmployeeAdminFields],
);

extension ClientExtension$Fragment$EmployeeAdminFields
    on graphql.GraphQLClient {
  void writeFragment$EmployeeAdminFields({
    required Fragment$EmployeeAdminFields data,
    required Map<String, dynamic> idFields,
    bool broadcast = true,
  }) => this.writeFragment(
    graphql.FragmentRequest(
      idFields: idFields,
      fragment: const graphql.Fragment(
        fragmentName: 'EmployeeAdminFields',
        document: documentNodeFragmentEmployeeAdminFields,
      ),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Fragment$EmployeeAdminFields? readFragment$EmployeeAdminFields({
    required Map<String, dynamic> idFields,
    bool optimistic = true,
  }) {
    final result = this.readFragment(
      graphql.FragmentRequest(
        idFields: idFields,
        fragment: const graphql.Fragment(
          fragmentName: 'EmployeeAdminFields',
          document: documentNodeFragmentEmployeeAdminFields,
        ),
      ),
      optimistic: optimistic,
    );
    return result == null
        ? null
        : Fragment$EmployeeAdminFields.fromJson(result);
  }
}

class Fragment$EmployeeAdminFields$login {
  Fragment$EmployeeAdminFields$login({
    required this.status,
    this.loginId,
    this.lastSignInAt,
    required this.devices,
    required this.protected,
    this.$__typename = 'EmployeeLogin',
  });

  factory Fragment$EmployeeAdminFields$login.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$status = json['status'];
    final l$loginId = json['loginId'];
    final l$lastSignInAt = json['lastSignInAt'];
    final l$devices = json['devices'];
    final l$protected = json['protected'];
    final l$$__typename = json['__typename'];
    return Fragment$EmployeeAdminFields$login(
      status: (l$status as String),
      loginId: (l$loginId as String?),
      lastSignInAt: (l$lastSignInAt as String?),
      devices: (l$devices as int),
      protected: (l$protected as bool),
      $__typename: (l$$__typename as String),
    );
  }

  final String status;

  final String? loginId;

  final String? lastSignInAt;

  final int devices;

  final bool protected;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$status = status;
    _resultData['status'] = l$status;
    final l$loginId = loginId;
    _resultData['loginId'] = l$loginId;
    final l$lastSignInAt = lastSignInAt;
    _resultData['lastSignInAt'] = l$lastSignInAt;
    final l$devices = devices;
    _resultData['devices'] = l$devices;
    final l$protected = protected;
    _resultData['protected'] = l$protected;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$status = status;
    final l$loginId = loginId;
    final l$lastSignInAt = lastSignInAt;
    final l$devices = devices;
    final l$protected = protected;
    final l$$__typename = $__typename;
    return Object.hashAll([
      l$status,
      l$loginId,
      l$lastSignInAt,
      l$devices,
      l$protected,
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Fragment$EmployeeAdminFields$login ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$status = status;
    final lOther$status = other.status;
    if (l$status != lOther$status) {
      return false;
    }
    final l$loginId = loginId;
    final lOther$loginId = other.loginId;
    if (l$loginId != lOther$loginId) {
      return false;
    }
    final l$lastSignInAt = lastSignInAt;
    final lOther$lastSignInAt = other.lastSignInAt;
    if (l$lastSignInAt != lOther$lastSignInAt) {
      return false;
    }
    final l$devices = devices;
    final lOther$devices = other.devices;
    if (l$devices != lOther$devices) {
      return false;
    }
    final l$protected = protected;
    final lOther$protected = other.protected;
    if (l$protected != lOther$protected) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Fragment$EmployeeAdminFields$login
    on Fragment$EmployeeAdminFields$login {
  CopyWith$Fragment$EmployeeAdminFields$login<
    Fragment$EmployeeAdminFields$login
  >
  get copyWith => CopyWith$Fragment$EmployeeAdminFields$login(this, (i) => i);
}

abstract class CopyWith$Fragment$EmployeeAdminFields$login<TRes> {
  factory CopyWith$Fragment$EmployeeAdminFields$login(
    Fragment$EmployeeAdminFields$login instance,
    TRes Function(Fragment$EmployeeAdminFields$login) then,
  ) = _CopyWithImpl$Fragment$EmployeeAdminFields$login;

  factory CopyWith$Fragment$EmployeeAdminFields$login.stub(TRes res) =
      _CopyWithStubImpl$Fragment$EmployeeAdminFields$login;

  TRes call({
    String? status,
    String? loginId,
    String? lastSignInAt,
    int? devices,
    bool? protected,
    String? $__typename,
  });
}

class _CopyWithImpl$Fragment$EmployeeAdminFields$login<TRes>
    implements CopyWith$Fragment$EmployeeAdminFields$login<TRes> {
  _CopyWithImpl$Fragment$EmployeeAdminFields$login(this._instance, this._then);

  final Fragment$EmployeeAdminFields$login _instance;

  final TRes Function(Fragment$EmployeeAdminFields$login) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? status = _undefined,
    Object? loginId = _undefined,
    Object? lastSignInAt = _undefined,
    Object? devices = _undefined,
    Object? protected = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Fragment$EmployeeAdminFields$login(
      status: status == _undefined || status == null
          ? _instance.status
          : (status as String),
      loginId: loginId == _undefined ? _instance.loginId : (loginId as String?),
      lastSignInAt: lastSignInAt == _undefined
          ? _instance.lastSignInAt
          : (lastSignInAt as String?),
      devices: devices == _undefined || devices == null
          ? _instance.devices
          : (devices as int),
      protected: protected == _undefined || protected == null
          ? _instance.protected
          : (protected as bool),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Fragment$EmployeeAdminFields$login<TRes>
    implements CopyWith$Fragment$EmployeeAdminFields$login<TRes> {
  _CopyWithStubImpl$Fragment$EmployeeAdminFields$login(this._res);

  TRes _res;

  call({
    String? status,
    String? loginId,
    String? lastSignInAt,
    int? devices,
    bool? protected,
    String? $__typename,
  }) => _res;
}

class Fragment$DecisionFields {
  Fragment$DecisionFields({
    required this.allowed,
    required this.scope,
    required this.rule,
    this.available,
    this.$__typename = 'AccessDecision',
  });

  factory Fragment$DecisionFields.fromJson(Map<String, dynamic> json) {
    final l$allowed = json['allowed'];
    final l$scope = json['scope'];
    final l$rule = json['rule'];
    final l$available = json['available'];
    final l$$__typename = json['__typename'];
    return Fragment$DecisionFields(
      allowed: (l$allowed as bool),
      scope: (l$scope as String),
      rule: (l$rule as String),
      available: (l$available as bool?),
      $__typename: (l$$__typename as String),
    );
  }

  final bool allowed;

  final String scope;

  final String rule;

  final bool? available;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$allowed = allowed;
    _resultData['allowed'] = l$allowed;
    final l$scope = scope;
    _resultData['scope'] = l$scope;
    final l$rule = rule;
    _resultData['rule'] = l$rule;
    final l$available = available;
    _resultData['available'] = l$available;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$allowed = allowed;
    final l$scope = scope;
    final l$rule = rule;
    final l$available = available;
    final l$$__typename = $__typename;
    return Object.hashAll([
      l$allowed,
      l$scope,
      l$rule,
      l$available,
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Fragment$DecisionFields || runtimeType != other.runtimeType) {
      return false;
    }
    final l$allowed = allowed;
    final lOther$allowed = other.allowed;
    if (l$allowed != lOther$allowed) {
      return false;
    }
    final l$scope = scope;
    final lOther$scope = other.scope;
    if (l$scope != lOther$scope) {
      return false;
    }
    final l$rule = rule;
    final lOther$rule = other.rule;
    if (l$rule != lOther$rule) {
      return false;
    }
    final l$available = available;
    final lOther$available = other.available;
    if (l$available != lOther$available) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Fragment$DecisionFields on Fragment$DecisionFields {
  CopyWith$Fragment$DecisionFields<Fragment$DecisionFields> get copyWith =>
      CopyWith$Fragment$DecisionFields(this, (i) => i);
}

abstract class CopyWith$Fragment$DecisionFields<TRes> {
  factory CopyWith$Fragment$DecisionFields(
    Fragment$DecisionFields instance,
    TRes Function(Fragment$DecisionFields) then,
  ) = _CopyWithImpl$Fragment$DecisionFields;

  factory CopyWith$Fragment$DecisionFields.stub(TRes res) =
      _CopyWithStubImpl$Fragment$DecisionFields;

  TRes call({
    bool? allowed,
    String? scope,
    String? rule,
    bool? available,
    String? $__typename,
  });
}

class _CopyWithImpl$Fragment$DecisionFields<TRes>
    implements CopyWith$Fragment$DecisionFields<TRes> {
  _CopyWithImpl$Fragment$DecisionFields(this._instance, this._then);

  final Fragment$DecisionFields _instance;

  final TRes Function(Fragment$DecisionFields) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? allowed = _undefined,
    Object? scope = _undefined,
    Object? rule = _undefined,
    Object? available = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Fragment$DecisionFields(
      allowed: allowed == _undefined || allowed == null
          ? _instance.allowed
          : (allowed as bool),
      scope: scope == _undefined || scope == null
          ? _instance.scope
          : (scope as String),
      rule: rule == _undefined || rule == null
          ? _instance.rule
          : (rule as String),
      available: available == _undefined
          ? _instance.available
          : (available as bool?),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Fragment$DecisionFields<TRes>
    implements CopyWith$Fragment$DecisionFields<TRes> {
  _CopyWithStubImpl$Fragment$DecisionFields(this._res);

  TRes _res;

  call({
    bool? allowed,
    String? scope,
    String? rule,
    bool? available,
    String? $__typename,
  }) => _res;
}

const fragmentDefinitionDecisionFields = FragmentDefinitionNode(
  name: NameNode(value: 'DecisionFields'),
  typeCondition: TypeConditionNode(
    on: NamedTypeNode(
      name: NameNode(value: 'AccessDecision'),
      isNonNull: false,
    ),
  ),
  directives: [],
  selectionSet: SelectionSetNode(
    selections: [
      FieldNode(
        name: NameNode(value: 'allowed'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'scope'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'rule'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'available'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: '__typename'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
    ],
  ),
);
const documentNodeFragmentDecisionFields = DocumentNode(
  definitions: [fragmentDefinitionDecisionFields],
);

extension ClientExtension$Fragment$DecisionFields on graphql.GraphQLClient {
  void writeFragment$DecisionFields({
    required Fragment$DecisionFields data,
    required Map<String, dynamic> idFields,
    bool broadcast = true,
  }) => this.writeFragment(
    graphql.FragmentRequest(
      idFields: idFields,
      fragment: const graphql.Fragment(
        fragmentName: 'DecisionFields',
        document: documentNodeFragmentDecisionFields,
      ),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Fragment$DecisionFields? readFragment$DecisionFields({
    required Map<String, dynamic> idFields,
    bool optimistic = true,
  }) {
    final result = this.readFragment(
      graphql.FragmentRequest(
        idFields: idFields,
        fragment: const graphql.Fragment(
          fragmentName: 'DecisionFields',
          document: documentNodeFragmentDecisionFields,
        ),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Fragment$DecisionFields.fromJson(result);
  }
}

class Fragment$ChangeFields {
  Fragment$ChangeFields({
    required this.key,
    required this.before,
    required this.after,
    this.$__typename = 'PermissionChange',
  });

  factory Fragment$ChangeFields.fromJson(Map<String, dynamic> json) {
    final l$key = json['key'];
    final l$before = json['before'];
    final l$after = json['after'];
    final l$$__typename = json['__typename'];
    return Fragment$ChangeFields(
      key: (l$key as String),
      before: Fragment$DecisionFields.fromJson(
        (l$before as Map<String, dynamic>),
      ),
      after: Fragment$DecisionFields.fromJson(
        (l$after as Map<String, dynamic>),
      ),
      $__typename: (l$$__typename as String),
    );
  }

  final String key;

  final Fragment$DecisionFields before;

  final Fragment$DecisionFields after;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$key = key;
    _resultData['key'] = l$key;
    final l$before = before;
    _resultData['before'] = l$before.toJson();
    final l$after = after;
    _resultData['after'] = l$after.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$key = key;
    final l$before = before;
    final l$after = after;
    final l$$__typename = $__typename;
    return Object.hashAll([l$key, l$before, l$after, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Fragment$ChangeFields || runtimeType != other.runtimeType) {
      return false;
    }
    final l$key = key;
    final lOther$key = other.key;
    if (l$key != lOther$key) {
      return false;
    }
    final l$before = before;
    final lOther$before = other.before;
    if (l$before != lOther$before) {
      return false;
    }
    final l$after = after;
    final lOther$after = other.after;
    if (l$after != lOther$after) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Fragment$ChangeFields on Fragment$ChangeFields {
  CopyWith$Fragment$ChangeFields<Fragment$ChangeFields> get copyWith =>
      CopyWith$Fragment$ChangeFields(this, (i) => i);
}

abstract class CopyWith$Fragment$ChangeFields<TRes> {
  factory CopyWith$Fragment$ChangeFields(
    Fragment$ChangeFields instance,
    TRes Function(Fragment$ChangeFields) then,
  ) = _CopyWithImpl$Fragment$ChangeFields;

  factory CopyWith$Fragment$ChangeFields.stub(TRes res) =
      _CopyWithStubImpl$Fragment$ChangeFields;

  TRes call({
    String? key,
    Fragment$DecisionFields? before,
    Fragment$DecisionFields? after,
    String? $__typename,
  });
  CopyWith$Fragment$DecisionFields<TRes> get before;
  CopyWith$Fragment$DecisionFields<TRes> get after;
}

class _CopyWithImpl$Fragment$ChangeFields<TRes>
    implements CopyWith$Fragment$ChangeFields<TRes> {
  _CopyWithImpl$Fragment$ChangeFields(this._instance, this._then);

  final Fragment$ChangeFields _instance;

  final TRes Function(Fragment$ChangeFields) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? key = _undefined,
    Object? before = _undefined,
    Object? after = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Fragment$ChangeFields(
      key: key == _undefined || key == null ? _instance.key : (key as String),
      before: before == _undefined || before == null
          ? _instance.before
          : (before as Fragment$DecisionFields),
      after: after == _undefined || after == null
          ? _instance.after
          : (after as Fragment$DecisionFields),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Fragment$DecisionFields<TRes> get before {
    final local$before = _instance.before;
    return CopyWith$Fragment$DecisionFields(
      local$before,
      (e) => call(before: e),
    );
  }

  CopyWith$Fragment$DecisionFields<TRes> get after {
    final local$after = _instance.after;
    return CopyWith$Fragment$DecisionFields(local$after, (e) => call(after: e));
  }
}

class _CopyWithStubImpl$Fragment$ChangeFields<TRes>
    implements CopyWith$Fragment$ChangeFields<TRes> {
  _CopyWithStubImpl$Fragment$ChangeFields(this._res);

  TRes _res;

  call({
    String? key,
    Fragment$DecisionFields? before,
    Fragment$DecisionFields? after,
    String? $__typename,
  }) => _res;

  CopyWith$Fragment$DecisionFields<TRes> get before =>
      CopyWith$Fragment$DecisionFields.stub(_res);

  CopyWith$Fragment$DecisionFields<TRes> get after =>
      CopyWith$Fragment$DecisionFields.stub(_res);
}

const fragmentDefinitionChangeFields = FragmentDefinitionNode(
  name: NameNode(value: 'ChangeFields'),
  typeCondition: TypeConditionNode(
    on: NamedTypeNode(
      name: NameNode(value: 'PermissionChange'),
      isNonNull: false,
    ),
  ),
  directives: [],
  selectionSet: SelectionSetNode(
    selections: [
      FieldNode(
        name: NameNode(value: 'key'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'before'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: SelectionSetNode(
          selections: [
            FragmentSpreadNode(
              name: NameNode(value: 'DecisionFields'),
              directives: [],
            ),
            FieldNode(
              name: NameNode(value: '__typename'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null,
            ),
          ],
        ),
      ),
      FieldNode(
        name: NameNode(value: 'after'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: SelectionSetNode(
          selections: [
            FragmentSpreadNode(
              name: NameNode(value: 'DecisionFields'),
              directives: [],
            ),
            FieldNode(
              name: NameNode(value: '__typename'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null,
            ),
          ],
        ),
      ),
      FieldNode(
        name: NameNode(value: '__typename'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
    ],
  ),
);
const documentNodeFragmentChangeFields = DocumentNode(
  definitions: [
    fragmentDefinitionChangeFields,
    fragmentDefinitionDecisionFields,
  ],
);

extension ClientExtension$Fragment$ChangeFields on graphql.GraphQLClient {
  void writeFragment$ChangeFields({
    required Fragment$ChangeFields data,
    required Map<String, dynamic> idFields,
    bool broadcast = true,
  }) => this.writeFragment(
    graphql.FragmentRequest(
      idFields: idFields,
      fragment: const graphql.Fragment(
        fragmentName: 'ChangeFields',
        document: documentNodeFragmentChangeFields,
      ),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Fragment$ChangeFields? readFragment$ChangeFields({
    required Map<String, dynamic> idFields,
    bool optimistic = true,
  }) {
    final result = this.readFragment(
      graphql.FragmentRequest(
        idFields: idFields,
        fragment: const graphql.Fragment(
          fragmentName: 'ChangeFields',
          document: documentNodeFragmentChangeFields,
        ),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Fragment$ChangeFields.fromJson(result);
  }
}

class Query$Bootstrap {
  Query$Bootstrap({required this.bootstrap, this.$__typename = 'Query'});

  factory Query$Bootstrap.fromJson(Map<String, dynamic> json) {
    final l$bootstrap = json['bootstrap'];
    final l$$__typename = json['__typename'];
    return Query$Bootstrap(
      bootstrap: Query$Bootstrap$bootstrap.fromJson(
        (l$bootstrap as Map<String, dynamic>),
      ),
      $__typename: (l$$__typename as String),
    );
  }

  final Query$Bootstrap$bootstrap bootstrap;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$bootstrap = bootstrap;
    _resultData['bootstrap'] = l$bootstrap.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$bootstrap = bootstrap;
    final l$$__typename = $__typename;
    return Object.hashAll([l$bootstrap, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$Bootstrap || runtimeType != other.runtimeType) {
      return false;
    }
    final l$bootstrap = bootstrap;
    final lOther$bootstrap = other.bootstrap;
    if (l$bootstrap != lOther$bootstrap) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$Bootstrap on Query$Bootstrap {
  CopyWith$Query$Bootstrap<Query$Bootstrap> get copyWith =>
      CopyWith$Query$Bootstrap(this, (i) => i);
}

abstract class CopyWith$Query$Bootstrap<TRes> {
  factory CopyWith$Query$Bootstrap(
    Query$Bootstrap instance,
    TRes Function(Query$Bootstrap) then,
  ) = _CopyWithImpl$Query$Bootstrap;

  factory CopyWith$Query$Bootstrap.stub(TRes res) =
      _CopyWithStubImpl$Query$Bootstrap;

  TRes call({Query$Bootstrap$bootstrap? bootstrap, String? $__typename});
  CopyWith$Query$Bootstrap$bootstrap<TRes> get bootstrap;
}

class _CopyWithImpl$Query$Bootstrap<TRes>
    implements CopyWith$Query$Bootstrap<TRes> {
  _CopyWithImpl$Query$Bootstrap(this._instance, this._then);

  final Query$Bootstrap _instance;

  final TRes Function(Query$Bootstrap) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? bootstrap = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$Bootstrap(
      bootstrap: bootstrap == _undefined || bootstrap == null
          ? _instance.bootstrap
          : (bootstrap as Query$Bootstrap$bootstrap),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Query$Bootstrap$bootstrap<TRes> get bootstrap {
    final local$bootstrap = _instance.bootstrap;
    return CopyWith$Query$Bootstrap$bootstrap(
      local$bootstrap,
      (e) => call(bootstrap: e),
    );
  }
}

class _CopyWithStubImpl$Query$Bootstrap<TRes>
    implements CopyWith$Query$Bootstrap<TRes> {
  _CopyWithStubImpl$Query$Bootstrap(this._res);

  TRes _res;

  call({Query$Bootstrap$bootstrap? bootstrap, String? $__typename}) => _res;

  CopyWith$Query$Bootstrap$bootstrap<TRes> get bootstrap =>
      CopyWith$Query$Bootstrap$bootstrap.stub(_res);
}

const documentNodeQueryBootstrap = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'Bootstrap'),
      variableDefinitions: [],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'bootstrap'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: SelectionSetNode(
              selections: [
                FieldNode(
                  name: NameNode(value: 'organization'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FieldNode(
                        name: NameNode(value: 'id'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'name'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: '__typename'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                    ],
                  ),
                ),
                FieldNode(
                  name: NameNode(value: 'actor'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FieldNode(
                        name: NameNode(value: 'id'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'permissionVersion'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: '__typename'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                    ],
                  ),
                ),
                FieldNode(
                  name: NameNode(value: 'sites'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FieldNode(
                        name: NameNode(value: 'id'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'name'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'timezone'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: '__typename'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                    ],
                  ),
                ),
                FieldNode(
                  name: NameNode(value: '__typename'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
              ],
            ),
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Query$Bootstrap _parserFn$Query$Bootstrap(Map<String, dynamic> data) =>
    Query$Bootstrap.fromJson(data);
typedef OnQueryComplete$Query$Bootstrap = FutureOr<void> Function(
  Map<String, dynamic>?,
  Query$Bootstrap?,
);

class Options$Query$Bootstrap extends graphql.QueryOptions<Query$Bootstrap> {
  Options$Query$Bootstrap({
    String? operationName,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$Bootstrap? typedOptimisticResult,
    Duration? pollInterval,
    graphql.Context? context,
    OnQueryComplete$Query$Bootstrap? onComplete,
    graphql.OnQueryError? onError,
  }) : onCompleteWithParsed = onComplete,
       super(
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         pollInterval: pollInterval,
         context: context,
         onComplete: onComplete == null
             ? null
             : (data) => onComplete(
                 data,
                 data == null ? null : _parserFn$Query$Bootstrap(data),
               ),
         onError: onError,
         document: documentNodeQueryBootstrap,
         parserFn: _parserFn$Query$Bootstrap,
       );

  final OnQueryComplete$Query$Bootstrap? onCompleteWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onComplete == null
        ? super.properties
        : super.properties.where((property) => property != onComplete),
    onCompleteWithParsed,
  ];
}

class WatchOptions$Query$Bootstrap
    extends graphql.WatchQueryOptions<Query$Bootstrap> {
  WatchOptions$Query$Bootstrap({
    String? operationName,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$Bootstrap? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeQueryBootstrap,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Query$Bootstrap,
       );
}

class FetchMoreOptions$Query$Bootstrap extends graphql.FetchMoreOptions {
  FetchMoreOptions$Query$Bootstrap({required graphql.UpdateQuery updateQuery})
    : super(updateQuery: updateQuery, document: documentNodeQueryBootstrap);
}

extension ClientExtension$Query$Bootstrap on graphql.GraphQLClient {
  Future<graphql.QueryResult<Query$Bootstrap>> query$Bootstrap([
    Options$Query$Bootstrap? options,
  ]) async => await this.query(options ?? Options$Query$Bootstrap());

  graphql.ObservableQuery<Query$Bootstrap> watchQuery$Bootstrap([
    WatchOptions$Query$Bootstrap? options,
  ]) => this.watchQuery(options ?? WatchOptions$Query$Bootstrap());

  void writeQuery$Bootstrap({
    required Query$Bootstrap data,
    bool broadcast = true,
  }) => this.writeQuery(
    graphql.Request(
      operation: graphql.Operation(document: documentNodeQueryBootstrap),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Query$Bootstrap? readQuery$Bootstrap({bool optimistic = true}) {
    final result = this.readQuery(
      graphql.Request(
        operation: graphql.Operation(document: documentNodeQueryBootstrap),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Query$Bootstrap.fromJson(result);
  }
}

class Query$Bootstrap$bootstrap {
  Query$Bootstrap$bootstrap({
    required this.organization,
    required this.actor,
    required this.sites,
    this.$__typename = 'Bootstrap',
  });

  factory Query$Bootstrap$bootstrap.fromJson(Map<String, dynamic> json) {
    final l$organization = json['organization'];
    final l$actor = json['actor'];
    final l$sites = json['sites'];
    final l$$__typename = json['__typename'];
    return Query$Bootstrap$bootstrap(
      organization: Query$Bootstrap$bootstrap$organization.fromJson(
        (l$organization as Map<String, dynamic>),
      ),
      actor: Query$Bootstrap$bootstrap$actor.fromJson(
        (l$actor as Map<String, dynamic>),
      ),
      sites: (l$sites as List<dynamic>)
          .map(
            (e) => Query$Bootstrap$bootstrap$sites.fromJson(
              (e as Map<String, dynamic>),
            ),
          )
          .toList(),
      $__typename: (l$$__typename as String),
    );
  }

  final Query$Bootstrap$bootstrap$organization organization;

  final Query$Bootstrap$bootstrap$actor actor;

  final List<Query$Bootstrap$bootstrap$sites> sites;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$organization = organization;
    _resultData['organization'] = l$organization.toJson();
    final l$actor = actor;
    _resultData['actor'] = l$actor.toJson();
    final l$sites = sites;
    _resultData['sites'] = l$sites.map((e) => e.toJson()).toList();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$organization = organization;
    final l$actor = actor;
    final l$sites = sites;
    final l$$__typename = $__typename;
    return Object.hashAll([
      l$organization,
      l$actor,
      Object.hashAll(l$sites.map((v) => v)),
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$Bootstrap$bootstrap ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$organization = organization;
    final lOther$organization = other.organization;
    if (l$organization != lOther$organization) {
      return false;
    }
    final l$actor = actor;
    final lOther$actor = other.actor;
    if (l$actor != lOther$actor) {
      return false;
    }
    final l$sites = sites;
    final lOther$sites = other.sites;
    if (l$sites.length != lOther$sites.length) {
      return false;
    }
    for (int i = 0; i < l$sites.length; i++) {
      final l$sites$entry = l$sites[i];
      final lOther$sites$entry = lOther$sites[i];
      if (l$sites$entry != lOther$sites$entry) {
        return false;
      }
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$Bootstrap$bootstrap
    on Query$Bootstrap$bootstrap {
  CopyWith$Query$Bootstrap$bootstrap<Query$Bootstrap$bootstrap> get copyWith =>
      CopyWith$Query$Bootstrap$bootstrap(this, (i) => i);
}

abstract class CopyWith$Query$Bootstrap$bootstrap<TRes> {
  factory CopyWith$Query$Bootstrap$bootstrap(
    Query$Bootstrap$bootstrap instance,
    TRes Function(Query$Bootstrap$bootstrap) then,
  ) = _CopyWithImpl$Query$Bootstrap$bootstrap;

  factory CopyWith$Query$Bootstrap$bootstrap.stub(TRes res) =
      _CopyWithStubImpl$Query$Bootstrap$bootstrap;

  TRes call({
    Query$Bootstrap$bootstrap$organization? organization,
    Query$Bootstrap$bootstrap$actor? actor,
    List<Query$Bootstrap$bootstrap$sites>? sites,
    String? $__typename,
  });
  CopyWith$Query$Bootstrap$bootstrap$organization<TRes> get organization;
  CopyWith$Query$Bootstrap$bootstrap$actor<TRes> get actor;
  TRes sites(
    Iterable<Query$Bootstrap$bootstrap$sites> Function(
      Iterable<
        CopyWith$Query$Bootstrap$bootstrap$sites<
          Query$Bootstrap$bootstrap$sites
        >
      >,
    )
    _fn,
  );
}

class _CopyWithImpl$Query$Bootstrap$bootstrap<TRes>
    implements CopyWith$Query$Bootstrap$bootstrap<TRes> {
  _CopyWithImpl$Query$Bootstrap$bootstrap(this._instance, this._then);

  final Query$Bootstrap$bootstrap _instance;

  final TRes Function(Query$Bootstrap$bootstrap) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? organization = _undefined,
    Object? actor = _undefined,
    Object? sites = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$Bootstrap$bootstrap(
      organization: organization == _undefined || organization == null
          ? _instance.organization
          : (organization as Query$Bootstrap$bootstrap$organization),
      actor: actor == _undefined || actor == null
          ? _instance.actor
          : (actor as Query$Bootstrap$bootstrap$actor),
      sites: sites == _undefined || sites == null
          ? _instance.sites
          : (sites as List<Query$Bootstrap$bootstrap$sites>),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Query$Bootstrap$bootstrap$organization<TRes> get organization {
    final local$organization = _instance.organization;
    return CopyWith$Query$Bootstrap$bootstrap$organization(
      local$organization,
      (e) => call(organization: e),
    );
  }

  CopyWith$Query$Bootstrap$bootstrap$actor<TRes> get actor {
    final local$actor = _instance.actor;
    return CopyWith$Query$Bootstrap$bootstrap$actor(
      local$actor,
      (e) => call(actor: e),
    );
  }

  TRes sites(
    Iterable<Query$Bootstrap$bootstrap$sites> Function(
      Iterable<
        CopyWith$Query$Bootstrap$bootstrap$sites<
          Query$Bootstrap$bootstrap$sites
        >
      >,
    )
    _fn,
  ) => call(
    sites: _fn(
      _instance.sites.map(
        (e) => CopyWith$Query$Bootstrap$bootstrap$sites(e, (i) => i),
      ),
    ).toList(),
  );
}

class _CopyWithStubImpl$Query$Bootstrap$bootstrap<TRes>
    implements CopyWith$Query$Bootstrap$bootstrap<TRes> {
  _CopyWithStubImpl$Query$Bootstrap$bootstrap(this._res);

  TRes _res;

  call({
    Query$Bootstrap$bootstrap$organization? organization,
    Query$Bootstrap$bootstrap$actor? actor,
    List<Query$Bootstrap$bootstrap$sites>? sites,
    String? $__typename,
  }) => _res;

  CopyWith$Query$Bootstrap$bootstrap$organization<TRes> get organization =>
      CopyWith$Query$Bootstrap$bootstrap$organization.stub(_res);

  CopyWith$Query$Bootstrap$bootstrap$actor<TRes> get actor =>
      CopyWith$Query$Bootstrap$bootstrap$actor.stub(_res);

  sites(_fn) => _res;
}

class Query$Bootstrap$bootstrap$organization {
  Query$Bootstrap$bootstrap$organization({
    required this.id,
    required this.name,
    this.$__typename = 'Organization',
  });

  factory Query$Bootstrap$bootstrap$organization.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$id = json['id'];
    final l$name = json['name'];
    final l$$__typename = json['__typename'];
    return Query$Bootstrap$bootstrap$organization(
      id: (l$id as String),
      name: (l$name as String),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String name;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$name = name;
    _resultData['name'] = l$name;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$name = name;
    final l$$__typename = $__typename;
    return Object.hashAll([l$id, l$name, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$Bootstrap$bootstrap$organization ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$name = name;
    final lOther$name = other.name;
    if (l$name != lOther$name) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$Bootstrap$bootstrap$organization
    on Query$Bootstrap$bootstrap$organization {
  CopyWith$Query$Bootstrap$bootstrap$organization<
    Query$Bootstrap$bootstrap$organization
  >
  get copyWith =>
      CopyWith$Query$Bootstrap$bootstrap$organization(this, (i) => i);
}

abstract class CopyWith$Query$Bootstrap$bootstrap$organization<TRes> {
  factory CopyWith$Query$Bootstrap$bootstrap$organization(
    Query$Bootstrap$bootstrap$organization instance,
    TRes Function(Query$Bootstrap$bootstrap$organization) then,
  ) = _CopyWithImpl$Query$Bootstrap$bootstrap$organization;

  factory CopyWith$Query$Bootstrap$bootstrap$organization.stub(TRes res) =
      _CopyWithStubImpl$Query$Bootstrap$bootstrap$organization;

  TRes call({String? id, String? name, String? $__typename});
}

class _CopyWithImpl$Query$Bootstrap$bootstrap$organization<TRes>
    implements CopyWith$Query$Bootstrap$bootstrap$organization<TRes> {
  _CopyWithImpl$Query$Bootstrap$bootstrap$organization(
    this._instance,
    this._then,
  );

  final Query$Bootstrap$bootstrap$organization _instance;

  final TRes Function(Query$Bootstrap$bootstrap$organization) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? name = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$Bootstrap$bootstrap$organization(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      name: name == _undefined || name == null
          ? _instance.name
          : (name as String),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$Bootstrap$bootstrap$organization<TRes>
    implements CopyWith$Query$Bootstrap$bootstrap$organization<TRes> {
  _CopyWithStubImpl$Query$Bootstrap$bootstrap$organization(this._res);

  TRes _res;

  call({String? id, String? name, String? $__typename}) => _res;
}

class Query$Bootstrap$bootstrap$actor {
  Query$Bootstrap$bootstrap$actor({
    required this.id,
    required this.permissionVersion,
    this.$__typename = 'Actor',
  });

  factory Query$Bootstrap$bootstrap$actor.fromJson(Map<String, dynamic> json) {
    final l$id = json['id'];
    final l$permissionVersion = json['permissionVersion'];
    final l$$__typename = json['__typename'];
    return Query$Bootstrap$bootstrap$actor(
      id: (l$id as String),
      permissionVersion: (l$permissionVersion as int),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final int permissionVersion;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$permissionVersion = permissionVersion;
    _resultData['permissionVersion'] = l$permissionVersion;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$permissionVersion = permissionVersion;
    final l$$__typename = $__typename;
    return Object.hashAll([l$id, l$permissionVersion, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$Bootstrap$bootstrap$actor ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$permissionVersion = permissionVersion;
    final lOther$permissionVersion = other.permissionVersion;
    if (l$permissionVersion != lOther$permissionVersion) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$Bootstrap$bootstrap$actor
    on Query$Bootstrap$bootstrap$actor {
  CopyWith$Query$Bootstrap$bootstrap$actor<Query$Bootstrap$bootstrap$actor>
  get copyWith => CopyWith$Query$Bootstrap$bootstrap$actor(this, (i) => i);
}

abstract class CopyWith$Query$Bootstrap$bootstrap$actor<TRes> {
  factory CopyWith$Query$Bootstrap$bootstrap$actor(
    Query$Bootstrap$bootstrap$actor instance,
    TRes Function(Query$Bootstrap$bootstrap$actor) then,
  ) = _CopyWithImpl$Query$Bootstrap$bootstrap$actor;

  factory CopyWith$Query$Bootstrap$bootstrap$actor.stub(TRes res) =
      _CopyWithStubImpl$Query$Bootstrap$bootstrap$actor;

  TRes call({String? id, int? permissionVersion, String? $__typename});
}

class _CopyWithImpl$Query$Bootstrap$bootstrap$actor<TRes>
    implements CopyWith$Query$Bootstrap$bootstrap$actor<TRes> {
  _CopyWithImpl$Query$Bootstrap$bootstrap$actor(this._instance, this._then);

  final Query$Bootstrap$bootstrap$actor _instance;

  final TRes Function(Query$Bootstrap$bootstrap$actor) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? permissionVersion = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$Bootstrap$bootstrap$actor(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      permissionVersion:
          permissionVersion == _undefined || permissionVersion == null
          ? _instance.permissionVersion
          : (permissionVersion as int),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$Bootstrap$bootstrap$actor<TRes>
    implements CopyWith$Query$Bootstrap$bootstrap$actor<TRes> {
  _CopyWithStubImpl$Query$Bootstrap$bootstrap$actor(this._res);

  TRes _res;

  call({String? id, int? permissionVersion, String? $__typename}) => _res;
}

class Query$Bootstrap$bootstrap$sites {
  Query$Bootstrap$bootstrap$sites({
    required this.id,
    required this.name,
    required this.timezone,
    this.$__typename = 'Site',
  });

  factory Query$Bootstrap$bootstrap$sites.fromJson(Map<String, dynamic> json) {
    final l$id = json['id'];
    final l$name = json['name'];
    final l$timezone = json['timezone'];
    final l$$__typename = json['__typename'];
    return Query$Bootstrap$bootstrap$sites(
      id: (l$id as String),
      name: (l$name as String),
      timezone: (l$timezone as String),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String name;

  final String timezone;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$name = name;
    _resultData['name'] = l$name;
    final l$timezone = timezone;
    _resultData['timezone'] = l$timezone;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$name = name;
    final l$timezone = timezone;
    final l$$__typename = $__typename;
    return Object.hashAll([l$id, l$name, l$timezone, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$Bootstrap$bootstrap$sites ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$name = name;
    final lOther$name = other.name;
    if (l$name != lOther$name) {
      return false;
    }
    final l$timezone = timezone;
    final lOther$timezone = other.timezone;
    if (l$timezone != lOther$timezone) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$Bootstrap$bootstrap$sites
    on Query$Bootstrap$bootstrap$sites {
  CopyWith$Query$Bootstrap$bootstrap$sites<Query$Bootstrap$bootstrap$sites>
  get copyWith => CopyWith$Query$Bootstrap$bootstrap$sites(this, (i) => i);
}

abstract class CopyWith$Query$Bootstrap$bootstrap$sites<TRes> {
  factory CopyWith$Query$Bootstrap$bootstrap$sites(
    Query$Bootstrap$bootstrap$sites instance,
    TRes Function(Query$Bootstrap$bootstrap$sites) then,
  ) = _CopyWithImpl$Query$Bootstrap$bootstrap$sites;

  factory CopyWith$Query$Bootstrap$bootstrap$sites.stub(TRes res) =
      _CopyWithStubImpl$Query$Bootstrap$bootstrap$sites;

  TRes call({String? id, String? name, String? timezone, String? $__typename});
}

class _CopyWithImpl$Query$Bootstrap$bootstrap$sites<TRes>
    implements CopyWith$Query$Bootstrap$bootstrap$sites<TRes> {
  _CopyWithImpl$Query$Bootstrap$bootstrap$sites(this._instance, this._then);

  final Query$Bootstrap$bootstrap$sites _instance;

  final TRes Function(Query$Bootstrap$bootstrap$sites) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? name = _undefined,
    Object? timezone = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$Bootstrap$bootstrap$sites(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      name: name == _undefined || name == null
          ? _instance.name
          : (name as String),
      timezone: timezone == _undefined || timezone == null
          ? _instance.timezone
          : (timezone as String),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$Bootstrap$bootstrap$sites<TRes>
    implements CopyWith$Query$Bootstrap$bootstrap$sites<TRes> {
  _CopyWithStubImpl$Query$Bootstrap$bootstrap$sites(this._res);

  TRes _res;

  call({String? id, String? name, String? timezone, String? $__typename}) =>
      _res;
}

class Variables$Query$SiteScope {
  factory Variables$Query$SiteScope({required String siteId}) =>
      Variables$Query$SiteScope._({r'siteId': siteId});

  Variables$Query$SiteScope._(this._$data);

  factory Variables$Query$SiteScope.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    return Variables$Query$SiteScope._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    return result$data;
  }

  CopyWith$Variables$Query$SiteScope<Variables$Query$SiteScope> get copyWith =>
      CopyWith$Variables$Query$SiteScope(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$SiteScope ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    return Object.hashAll([l$siteId]);
  }
}

abstract class CopyWith$Variables$Query$SiteScope<TRes> {
  factory CopyWith$Variables$Query$SiteScope(
    Variables$Query$SiteScope instance,
    TRes Function(Variables$Query$SiteScope) then,
  ) = _CopyWithImpl$Variables$Query$SiteScope;

  factory CopyWith$Variables$Query$SiteScope.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$SiteScope;

  TRes call({String? siteId});
}

class _CopyWithImpl$Variables$Query$SiteScope<TRes>
    implements CopyWith$Variables$Query$SiteScope<TRes> {
  _CopyWithImpl$Variables$Query$SiteScope(this._instance, this._then);

  final Variables$Query$SiteScope _instance;

  final TRes Function(Variables$Query$SiteScope) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? siteId = _undefined}) => _then(
    Variables$Query$SiteScope._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
    }),
  );
}

class _CopyWithStubImpl$Variables$Query$SiteScope<TRes>
    implements CopyWith$Variables$Query$SiteScope<TRes> {
  _CopyWithStubImpl$Variables$Query$SiteScope(this._res);

  TRes _res;

  call({String? siteId}) => _res;
}

class Query$SiteScope {
  Query$SiteScope({required this.scope, this.$__typename = 'Query'});

  factory Query$SiteScope.fromJson(Map<String, dynamic> json) {
    final l$scope = json['scope'];
    final l$$__typename = json['__typename'];
    return Query$SiteScope(
      scope: Query$SiteScope$scope.fromJson((l$scope as Map<String, dynamic>)),
      $__typename: (l$$__typename as String),
    );
  }

  final Query$SiteScope$scope scope;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$scope = scope;
    _resultData['scope'] = l$scope.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$scope = scope;
    final l$$__typename = $__typename;
    return Object.hashAll([l$scope, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$SiteScope || runtimeType != other.runtimeType) {
      return false;
    }
    final l$scope = scope;
    final lOther$scope = other.scope;
    if (l$scope != lOther$scope) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$SiteScope on Query$SiteScope {
  CopyWith$Query$SiteScope<Query$SiteScope> get copyWith =>
      CopyWith$Query$SiteScope(this, (i) => i);
}

abstract class CopyWith$Query$SiteScope<TRes> {
  factory CopyWith$Query$SiteScope(
    Query$SiteScope instance,
    TRes Function(Query$SiteScope) then,
  ) = _CopyWithImpl$Query$SiteScope;

  factory CopyWith$Query$SiteScope.stub(TRes res) =
      _CopyWithStubImpl$Query$SiteScope;

  TRes call({Query$SiteScope$scope? scope, String? $__typename});
  CopyWith$Query$SiteScope$scope<TRes> get scope;
}

class _CopyWithImpl$Query$SiteScope<TRes>
    implements CopyWith$Query$SiteScope<TRes> {
  _CopyWithImpl$Query$SiteScope(this._instance, this._then);

  final Query$SiteScope _instance;

  final TRes Function(Query$SiteScope) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? scope = _undefined, Object? $__typename = _undefined}) =>
      _then(
        Query$SiteScope(
          scope: scope == _undefined || scope == null
              ? _instance.scope
              : (scope as Query$SiteScope$scope),
          $__typename: $__typename == _undefined || $__typename == null
              ? _instance.$__typename
              : ($__typename as String),
        ),
      );

  CopyWith$Query$SiteScope$scope<TRes> get scope {
    final local$scope = _instance.scope;
    return CopyWith$Query$SiteScope$scope(local$scope, (e) => call(scope: e));
  }
}

class _CopyWithStubImpl$Query$SiteScope<TRes>
    implements CopyWith$Query$SiteScope<TRes> {
  _CopyWithStubImpl$Query$SiteScope(this._res);

  TRes _res;

  call({Query$SiteScope$scope? scope, String? $__typename}) => _res;

  CopyWith$Query$SiteScope$scope<TRes> get scope =>
      CopyWith$Query$SiteScope$scope.stub(_res);
}

const documentNodeQuerySiteScope = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'SiteScope'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'scope'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
            ],
            directives: [],
            selectionSet: SelectionSetNode(
              selections: [
                FieldNode(
                  name: NameNode(value: 'site'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FieldNode(
                        name: NameNode(value: 'id'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'name'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'timezone'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: '__typename'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                    ],
                  ),
                ),
                FieldNode(
                  name: NameNode(value: 'modules'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FieldNode(
                        name: NameNode(value: 'id'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'name'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'hindi'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'group'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'phase'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'available'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'actions'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'fields'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'dependencies'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: '__typename'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                    ],
                  ),
                ),
                FieldNode(
                  name: NameNode(value: 'decisions'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FieldNode(
                        name: NameNode(value: 'key'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'decision'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: SelectionSetNode(
                          selections: [
                            FragmentSpreadNode(
                              name: NameNode(value: 'DecisionFields'),
                              directives: [],
                            ),
                            FieldNode(
                              name: NameNode(value: '__typename'),
                              alias: null,
                              arguments: [],
                              directives: [],
                              selectionSet: null,
                            ),
                          ],
                        ),
                      ),
                      FieldNode(
                        name: NameNode(value: '__typename'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                    ],
                  ),
                ),
                FieldNode(
                  name: NameNode(value: 'capabilities'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'workDate'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: '__typename'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
              ],
            ),
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
    fragmentDefinitionDecisionFields,
  ],
);
Query$SiteScope _parserFn$Query$SiteScope(Map<String, dynamic> data) =>
    Query$SiteScope.fromJson(data);
typedef OnQueryComplete$Query$SiteScope = FutureOr<void> Function(
  Map<String, dynamic>?,
  Query$SiteScope?,
);

class Options$Query$SiteScope extends graphql.QueryOptions<Query$SiteScope> {
  Options$Query$SiteScope({
    String? operationName,
    required Variables$Query$SiteScope variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$SiteScope? typedOptimisticResult,
    Duration? pollInterval,
    graphql.Context? context,
    OnQueryComplete$Query$SiteScope? onComplete,
    graphql.OnQueryError? onError,
  }) : onCompleteWithParsed = onComplete,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         pollInterval: pollInterval,
         context: context,
         onComplete: onComplete == null
             ? null
             : (data) => onComplete(
                 data,
                 data == null ? null : _parserFn$Query$SiteScope(data),
               ),
         onError: onError,
         document: documentNodeQuerySiteScope,
         parserFn: _parserFn$Query$SiteScope,
       );

  final OnQueryComplete$Query$SiteScope? onCompleteWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onComplete == null
        ? super.properties
        : super.properties.where((property) => property != onComplete),
    onCompleteWithParsed,
  ];
}

class WatchOptions$Query$SiteScope
    extends graphql.WatchQueryOptions<Query$SiteScope> {
  WatchOptions$Query$SiteScope({
    String? operationName,
    required Variables$Query$SiteScope variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$SiteScope? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeQuerySiteScope,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Query$SiteScope,
       );
}

class FetchMoreOptions$Query$SiteScope extends graphql.FetchMoreOptions {
  FetchMoreOptions$Query$SiteScope({
    required graphql.UpdateQuery updateQuery,
    required Variables$Query$SiteScope variables,
  }) : super(
         updateQuery: updateQuery,
         variables: variables.toJson(),
         document: documentNodeQuerySiteScope,
       );
}

extension ClientExtension$Query$SiteScope on graphql.GraphQLClient {
  Future<graphql.QueryResult<Query$SiteScope>> query$SiteScope(
    Options$Query$SiteScope options,
  ) async => await this.query(options);

  graphql.ObservableQuery<Query$SiteScope> watchQuery$SiteScope(
    WatchOptions$Query$SiteScope options,
  ) => this.watchQuery(options);

  void writeQuery$SiteScope({
    required Query$SiteScope data,
    required Variables$Query$SiteScope variables,
    bool broadcast = true,
  }) => this.writeQuery(
    graphql.Request(
      operation: graphql.Operation(document: documentNodeQuerySiteScope),
      variables: variables.toJson(),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Query$SiteScope? readQuery$SiteScope({
    required Variables$Query$SiteScope variables,
    bool optimistic = true,
  }) {
    final result = this.readQuery(
      graphql.Request(
        operation: graphql.Operation(document: documentNodeQuerySiteScope),
        variables: variables.toJson(),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Query$SiteScope.fromJson(result);
  }
}

class Query$SiteScope$scope {
  Query$SiteScope$scope({
    required this.site,
    required this.modules,
    required this.decisions,
    required this.capabilities,
    required this.workDate,
    this.$__typename = 'Scope',
  });

  factory Query$SiteScope$scope.fromJson(Map<String, dynamic> json) {
    final l$site = json['site'];
    final l$modules = json['modules'];
    final l$decisions = json['decisions'];
    final l$capabilities = json['capabilities'];
    final l$workDate = json['workDate'];
    final l$$__typename = json['__typename'];
    return Query$SiteScope$scope(
      site: Query$SiteScope$scope$site.fromJson(
        (l$site as Map<String, dynamic>),
      ),
      modules: (l$modules as List<dynamic>)
          .map(
            (e) => Query$SiteScope$scope$modules.fromJson(
              (e as Map<String, dynamic>),
            ),
          )
          .toList(),
      decisions: (l$decisions as List<dynamic>)
          .map(
            (e) => Query$SiteScope$scope$decisions.fromJson(
              (e as Map<String, dynamic>),
            ),
          )
          .toList(),
      capabilities: (l$capabilities as List<dynamic>)
          .map((e) => (e as String))
          .toList(),
      workDate: (l$workDate as String),
      $__typename: (l$$__typename as String),
    );
  }

  final Query$SiteScope$scope$site site;

  final List<Query$SiteScope$scope$modules> modules;

  final List<Query$SiteScope$scope$decisions> decisions;

  final List<String> capabilities;

  final String workDate;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$site = site;
    _resultData['site'] = l$site.toJson();
    final l$modules = modules;
    _resultData['modules'] = l$modules.map((e) => e.toJson()).toList();
    final l$decisions = decisions;
    _resultData['decisions'] = l$decisions.map((e) => e.toJson()).toList();
    final l$capabilities = capabilities;
    _resultData['capabilities'] = l$capabilities.map((e) => e).toList();
    final l$workDate = workDate;
    _resultData['workDate'] = l$workDate;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$site = site;
    final l$modules = modules;
    final l$decisions = decisions;
    final l$capabilities = capabilities;
    final l$workDate = workDate;
    final l$$__typename = $__typename;
    return Object.hashAll([
      l$site,
      Object.hashAll(l$modules.map((v) => v)),
      Object.hashAll(l$decisions.map((v) => v)),
      Object.hashAll(l$capabilities.map((v) => v)),
      l$workDate,
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$SiteScope$scope || runtimeType != other.runtimeType) {
      return false;
    }
    final l$site = site;
    final lOther$site = other.site;
    if (l$site != lOther$site) {
      return false;
    }
    final l$modules = modules;
    final lOther$modules = other.modules;
    if (l$modules.length != lOther$modules.length) {
      return false;
    }
    for (int i = 0; i < l$modules.length; i++) {
      final l$modules$entry = l$modules[i];
      final lOther$modules$entry = lOther$modules[i];
      if (l$modules$entry != lOther$modules$entry) {
        return false;
      }
    }
    final l$decisions = decisions;
    final lOther$decisions = other.decisions;
    if (l$decisions.length != lOther$decisions.length) {
      return false;
    }
    for (int i = 0; i < l$decisions.length; i++) {
      final l$decisions$entry = l$decisions[i];
      final lOther$decisions$entry = lOther$decisions[i];
      if (l$decisions$entry != lOther$decisions$entry) {
        return false;
      }
    }
    final l$capabilities = capabilities;
    final lOther$capabilities = other.capabilities;
    if (l$capabilities.length != lOther$capabilities.length) {
      return false;
    }
    for (int i = 0; i < l$capabilities.length; i++) {
      final l$capabilities$entry = l$capabilities[i];
      final lOther$capabilities$entry = lOther$capabilities[i];
      if (l$capabilities$entry != lOther$capabilities$entry) {
        return false;
      }
    }
    final l$workDate = workDate;
    final lOther$workDate = other.workDate;
    if (l$workDate != lOther$workDate) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$SiteScope$scope on Query$SiteScope$scope {
  CopyWith$Query$SiteScope$scope<Query$SiteScope$scope> get copyWith =>
      CopyWith$Query$SiteScope$scope(this, (i) => i);
}

abstract class CopyWith$Query$SiteScope$scope<TRes> {
  factory CopyWith$Query$SiteScope$scope(
    Query$SiteScope$scope instance,
    TRes Function(Query$SiteScope$scope) then,
  ) = _CopyWithImpl$Query$SiteScope$scope;

  factory CopyWith$Query$SiteScope$scope.stub(TRes res) =
      _CopyWithStubImpl$Query$SiteScope$scope;

  TRes call({
    Query$SiteScope$scope$site? site,
    List<Query$SiteScope$scope$modules>? modules,
    List<Query$SiteScope$scope$decisions>? decisions,
    List<String>? capabilities,
    String? workDate,
    String? $__typename,
  });
  CopyWith$Query$SiteScope$scope$site<TRes> get site;
  TRes modules(
    Iterable<Query$SiteScope$scope$modules> Function(
      Iterable<
        CopyWith$Query$SiteScope$scope$modules<Query$SiteScope$scope$modules>
      >,
    )
    _fn,
  );
  TRes decisions(
    Iterable<Query$SiteScope$scope$decisions> Function(
      Iterable<
        CopyWith$Query$SiteScope$scope$decisions<
          Query$SiteScope$scope$decisions
        >
      >,
    )
    _fn,
  );
}

class _CopyWithImpl$Query$SiteScope$scope<TRes>
    implements CopyWith$Query$SiteScope$scope<TRes> {
  _CopyWithImpl$Query$SiteScope$scope(this._instance, this._then);

  final Query$SiteScope$scope _instance;

  final TRes Function(Query$SiteScope$scope) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? site = _undefined,
    Object? modules = _undefined,
    Object? decisions = _undefined,
    Object? capabilities = _undefined,
    Object? workDate = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$SiteScope$scope(
      site: site == _undefined || site == null
          ? _instance.site
          : (site as Query$SiteScope$scope$site),
      modules: modules == _undefined || modules == null
          ? _instance.modules
          : (modules as List<Query$SiteScope$scope$modules>),
      decisions: decisions == _undefined || decisions == null
          ? _instance.decisions
          : (decisions as List<Query$SiteScope$scope$decisions>),
      capabilities: capabilities == _undefined || capabilities == null
          ? _instance.capabilities
          : (capabilities as List<String>),
      workDate: workDate == _undefined || workDate == null
          ? _instance.workDate
          : (workDate as String),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Query$SiteScope$scope$site<TRes> get site {
    final local$site = _instance.site;
    return CopyWith$Query$SiteScope$scope$site(
      local$site,
      (e) => call(site: e),
    );
  }

  TRes modules(
    Iterable<Query$SiteScope$scope$modules> Function(
      Iterable<
        CopyWith$Query$SiteScope$scope$modules<Query$SiteScope$scope$modules>
      >,
    )
    _fn,
  ) => call(
    modules: _fn(
      _instance.modules.map(
        (e) => CopyWith$Query$SiteScope$scope$modules(e, (i) => i),
      ),
    ).toList(),
  );

  TRes decisions(
    Iterable<Query$SiteScope$scope$decisions> Function(
      Iterable<
        CopyWith$Query$SiteScope$scope$decisions<
          Query$SiteScope$scope$decisions
        >
      >,
    )
    _fn,
  ) => call(
    decisions: _fn(
      _instance.decisions.map(
        (e) => CopyWith$Query$SiteScope$scope$decisions(e, (i) => i),
      ),
    ).toList(),
  );
}

class _CopyWithStubImpl$Query$SiteScope$scope<TRes>
    implements CopyWith$Query$SiteScope$scope<TRes> {
  _CopyWithStubImpl$Query$SiteScope$scope(this._res);

  TRes _res;

  call({
    Query$SiteScope$scope$site? site,
    List<Query$SiteScope$scope$modules>? modules,
    List<Query$SiteScope$scope$decisions>? decisions,
    List<String>? capabilities,
    String? workDate,
    String? $__typename,
  }) => _res;

  CopyWith$Query$SiteScope$scope$site<TRes> get site =>
      CopyWith$Query$SiteScope$scope$site.stub(_res);

  modules(_fn) => _res;

  decisions(_fn) => _res;
}

class Query$SiteScope$scope$site {
  Query$SiteScope$scope$site({
    required this.id,
    required this.name,
    required this.timezone,
    this.$__typename = 'Site',
  });

  factory Query$SiteScope$scope$site.fromJson(Map<String, dynamic> json) {
    final l$id = json['id'];
    final l$name = json['name'];
    final l$timezone = json['timezone'];
    final l$$__typename = json['__typename'];
    return Query$SiteScope$scope$site(
      id: (l$id as String),
      name: (l$name as String),
      timezone: (l$timezone as String),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String name;

  final String timezone;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$name = name;
    _resultData['name'] = l$name;
    final l$timezone = timezone;
    _resultData['timezone'] = l$timezone;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$name = name;
    final l$timezone = timezone;
    final l$$__typename = $__typename;
    return Object.hashAll([l$id, l$name, l$timezone, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$SiteScope$scope$site ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$name = name;
    final lOther$name = other.name;
    if (l$name != lOther$name) {
      return false;
    }
    final l$timezone = timezone;
    final lOther$timezone = other.timezone;
    if (l$timezone != lOther$timezone) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$SiteScope$scope$site
    on Query$SiteScope$scope$site {
  CopyWith$Query$SiteScope$scope$site<Query$SiteScope$scope$site>
  get copyWith => CopyWith$Query$SiteScope$scope$site(this, (i) => i);
}

abstract class CopyWith$Query$SiteScope$scope$site<TRes> {
  factory CopyWith$Query$SiteScope$scope$site(
    Query$SiteScope$scope$site instance,
    TRes Function(Query$SiteScope$scope$site) then,
  ) = _CopyWithImpl$Query$SiteScope$scope$site;

  factory CopyWith$Query$SiteScope$scope$site.stub(TRes res) =
      _CopyWithStubImpl$Query$SiteScope$scope$site;

  TRes call({String? id, String? name, String? timezone, String? $__typename});
}

class _CopyWithImpl$Query$SiteScope$scope$site<TRes>
    implements CopyWith$Query$SiteScope$scope$site<TRes> {
  _CopyWithImpl$Query$SiteScope$scope$site(this._instance, this._then);

  final Query$SiteScope$scope$site _instance;

  final TRes Function(Query$SiteScope$scope$site) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? name = _undefined,
    Object? timezone = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$SiteScope$scope$site(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      name: name == _undefined || name == null
          ? _instance.name
          : (name as String),
      timezone: timezone == _undefined || timezone == null
          ? _instance.timezone
          : (timezone as String),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$SiteScope$scope$site<TRes>
    implements CopyWith$Query$SiteScope$scope$site<TRes> {
  _CopyWithStubImpl$Query$SiteScope$scope$site(this._res);

  TRes _res;

  call({String? id, String? name, String? timezone, String? $__typename}) =>
      _res;
}

class Query$SiteScope$scope$modules {
  Query$SiteScope$scope$modules({
    required this.id,
    required this.name,
    required this.hindi,
    required this.group,
    required this.phase,
    required this.available,
    required this.actions,
    required this.fields,
    required this.dependencies,
    this.$__typename = 'ProductModule',
  });

  factory Query$SiteScope$scope$modules.fromJson(Map<String, dynamic> json) {
    final l$id = json['id'];
    final l$name = json['name'];
    final l$hindi = json['hindi'];
    final l$group = json['group'];
    final l$phase = json['phase'];
    final l$available = json['available'];
    final l$actions = json['actions'];
    final l$fields = json['fields'];
    final l$dependencies = json['dependencies'];
    final l$$__typename = json['__typename'];
    return Query$SiteScope$scope$modules(
      id: (l$id as String),
      name: (l$name as String),
      hindi: (l$hindi as String),
      group: (l$group as String),
      phase: (l$phase as int),
      available: (l$available as bool),
      actions: (l$actions as List<dynamic>).map((e) => (e as String)).toList(),
      fields: (l$fields as List<dynamic>).map((e) => (e as String)).toList(),
      dependencies: (l$dependencies as List<dynamic>)
          .map((e) => (e as String))
          .toList(),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String name;

  final String hindi;

  final String group;

  final int phase;

  final bool available;

  final List<String> actions;

  final List<String> fields;

  final List<String> dependencies;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$name = name;
    _resultData['name'] = l$name;
    final l$hindi = hindi;
    _resultData['hindi'] = l$hindi;
    final l$group = group;
    _resultData['group'] = l$group;
    final l$phase = phase;
    _resultData['phase'] = l$phase;
    final l$available = available;
    _resultData['available'] = l$available;
    final l$actions = actions;
    _resultData['actions'] = l$actions.map((e) => e).toList();
    final l$fields = fields;
    _resultData['fields'] = l$fields.map((e) => e).toList();
    final l$dependencies = dependencies;
    _resultData['dependencies'] = l$dependencies.map((e) => e).toList();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$name = name;
    final l$hindi = hindi;
    final l$group = group;
    final l$phase = phase;
    final l$available = available;
    final l$actions = actions;
    final l$fields = fields;
    final l$dependencies = dependencies;
    final l$$__typename = $__typename;
    return Object.hashAll([
      l$id,
      l$name,
      l$hindi,
      l$group,
      l$phase,
      l$available,
      Object.hashAll(l$actions.map((v) => v)),
      Object.hashAll(l$fields.map((v) => v)),
      Object.hashAll(l$dependencies.map((v) => v)),
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$SiteScope$scope$modules ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$name = name;
    final lOther$name = other.name;
    if (l$name != lOther$name) {
      return false;
    }
    final l$hindi = hindi;
    final lOther$hindi = other.hindi;
    if (l$hindi != lOther$hindi) {
      return false;
    }
    final l$group = group;
    final lOther$group = other.group;
    if (l$group != lOther$group) {
      return false;
    }
    final l$phase = phase;
    final lOther$phase = other.phase;
    if (l$phase != lOther$phase) {
      return false;
    }
    final l$available = available;
    final lOther$available = other.available;
    if (l$available != lOther$available) {
      return false;
    }
    final l$actions = actions;
    final lOther$actions = other.actions;
    if (l$actions.length != lOther$actions.length) {
      return false;
    }
    for (int i = 0; i < l$actions.length; i++) {
      final l$actions$entry = l$actions[i];
      final lOther$actions$entry = lOther$actions[i];
      if (l$actions$entry != lOther$actions$entry) {
        return false;
      }
    }
    final l$fields = fields;
    final lOther$fields = other.fields;
    if (l$fields.length != lOther$fields.length) {
      return false;
    }
    for (int i = 0; i < l$fields.length; i++) {
      final l$fields$entry = l$fields[i];
      final lOther$fields$entry = lOther$fields[i];
      if (l$fields$entry != lOther$fields$entry) {
        return false;
      }
    }
    final l$dependencies = dependencies;
    final lOther$dependencies = other.dependencies;
    if (l$dependencies.length != lOther$dependencies.length) {
      return false;
    }
    for (int i = 0; i < l$dependencies.length; i++) {
      final l$dependencies$entry = l$dependencies[i];
      final lOther$dependencies$entry = lOther$dependencies[i];
      if (l$dependencies$entry != lOther$dependencies$entry) {
        return false;
      }
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$SiteScope$scope$modules
    on Query$SiteScope$scope$modules {
  CopyWith$Query$SiteScope$scope$modules<Query$SiteScope$scope$modules>
  get copyWith => CopyWith$Query$SiteScope$scope$modules(this, (i) => i);
}

abstract class CopyWith$Query$SiteScope$scope$modules<TRes> {
  factory CopyWith$Query$SiteScope$scope$modules(
    Query$SiteScope$scope$modules instance,
    TRes Function(Query$SiteScope$scope$modules) then,
  ) = _CopyWithImpl$Query$SiteScope$scope$modules;

  factory CopyWith$Query$SiteScope$scope$modules.stub(TRes res) =
      _CopyWithStubImpl$Query$SiteScope$scope$modules;

  TRes call({
    String? id,
    String? name,
    String? hindi,
    String? group,
    int? phase,
    bool? available,
    List<String>? actions,
    List<String>? fields,
    List<String>? dependencies,
    String? $__typename,
  });
}

class _CopyWithImpl$Query$SiteScope$scope$modules<TRes>
    implements CopyWith$Query$SiteScope$scope$modules<TRes> {
  _CopyWithImpl$Query$SiteScope$scope$modules(this._instance, this._then);

  final Query$SiteScope$scope$modules _instance;

  final TRes Function(Query$SiteScope$scope$modules) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? name = _undefined,
    Object? hindi = _undefined,
    Object? group = _undefined,
    Object? phase = _undefined,
    Object? available = _undefined,
    Object? actions = _undefined,
    Object? fields = _undefined,
    Object? dependencies = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$SiteScope$scope$modules(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      name: name == _undefined || name == null
          ? _instance.name
          : (name as String),
      hindi: hindi == _undefined || hindi == null
          ? _instance.hindi
          : (hindi as String),
      group: group == _undefined || group == null
          ? _instance.group
          : (group as String),
      phase: phase == _undefined || phase == null
          ? _instance.phase
          : (phase as int),
      available: available == _undefined || available == null
          ? _instance.available
          : (available as bool),
      actions: actions == _undefined || actions == null
          ? _instance.actions
          : (actions as List<String>),
      fields: fields == _undefined || fields == null
          ? _instance.fields
          : (fields as List<String>),
      dependencies: dependencies == _undefined || dependencies == null
          ? _instance.dependencies
          : (dependencies as List<String>),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$SiteScope$scope$modules<TRes>
    implements CopyWith$Query$SiteScope$scope$modules<TRes> {
  _CopyWithStubImpl$Query$SiteScope$scope$modules(this._res);

  TRes _res;

  call({
    String? id,
    String? name,
    String? hindi,
    String? group,
    int? phase,
    bool? available,
    List<String>? actions,
    List<String>? fields,
    List<String>? dependencies,
    String? $__typename,
  }) => _res;
}

class Query$SiteScope$scope$decisions {
  Query$SiteScope$scope$decisions({
    required this.key,
    required this.decision,
    this.$__typename = 'EffectivePermission',
  });

  factory Query$SiteScope$scope$decisions.fromJson(Map<String, dynamic> json) {
    final l$key = json['key'];
    final l$decision = json['decision'];
    final l$$__typename = json['__typename'];
    return Query$SiteScope$scope$decisions(
      key: (l$key as String),
      decision: Fragment$DecisionFields.fromJson(
        (l$decision as Map<String, dynamic>),
      ),
      $__typename: (l$$__typename as String),
    );
  }

  final String key;

  final Fragment$DecisionFields decision;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$key = key;
    _resultData['key'] = l$key;
    final l$decision = decision;
    _resultData['decision'] = l$decision.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$key = key;
    final l$decision = decision;
    final l$$__typename = $__typename;
    return Object.hashAll([l$key, l$decision, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$SiteScope$scope$decisions ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$key = key;
    final lOther$key = other.key;
    if (l$key != lOther$key) {
      return false;
    }
    final l$decision = decision;
    final lOther$decision = other.decision;
    if (l$decision != lOther$decision) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$SiteScope$scope$decisions
    on Query$SiteScope$scope$decisions {
  CopyWith$Query$SiteScope$scope$decisions<Query$SiteScope$scope$decisions>
  get copyWith => CopyWith$Query$SiteScope$scope$decisions(this, (i) => i);
}

abstract class CopyWith$Query$SiteScope$scope$decisions<TRes> {
  factory CopyWith$Query$SiteScope$scope$decisions(
    Query$SiteScope$scope$decisions instance,
    TRes Function(Query$SiteScope$scope$decisions) then,
  ) = _CopyWithImpl$Query$SiteScope$scope$decisions;

  factory CopyWith$Query$SiteScope$scope$decisions.stub(TRes res) =
      _CopyWithStubImpl$Query$SiteScope$scope$decisions;

  TRes call({
    String? key,
    Fragment$DecisionFields? decision,
    String? $__typename,
  });
  CopyWith$Fragment$DecisionFields<TRes> get decision;
}

class _CopyWithImpl$Query$SiteScope$scope$decisions<TRes>
    implements CopyWith$Query$SiteScope$scope$decisions<TRes> {
  _CopyWithImpl$Query$SiteScope$scope$decisions(this._instance, this._then);

  final Query$SiteScope$scope$decisions _instance;

  final TRes Function(Query$SiteScope$scope$decisions) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? key = _undefined,
    Object? decision = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$SiteScope$scope$decisions(
      key: key == _undefined || key == null ? _instance.key : (key as String),
      decision: decision == _undefined || decision == null
          ? _instance.decision
          : (decision as Fragment$DecisionFields),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Fragment$DecisionFields<TRes> get decision {
    final local$decision = _instance.decision;
    return CopyWith$Fragment$DecisionFields(
      local$decision,
      (e) => call(decision: e),
    );
  }
}

class _CopyWithStubImpl$Query$SiteScope$scope$decisions<TRes>
    implements CopyWith$Query$SiteScope$scope$decisions<TRes> {
  _CopyWithStubImpl$Query$SiteScope$scope$decisions(this._res);

  TRes _res;

  call({String? key, Fragment$DecisionFields? decision, String? $__typename}) =>
      _res;

  CopyWith$Fragment$DecisionFields<TRes> get decision =>
      CopyWith$Fragment$DecisionFields.stub(_res);
}

class Variables$Query$Employees {
  factory Variables$Query$Employees({
    required String siteId,
    int? first,
    String? after,
    String? search,
    String? department,
    String? status,
  }) => Variables$Query$Employees._({
    r'siteId': siteId,
    if (first != null) r'first': first,
    if (after != null) r'after': after,
    if (search != null) r'search': search,
    if (department != null) r'department': department,
    if (status != null) r'status': status,
  });

  Variables$Query$Employees._(this._$data);

  factory Variables$Query$Employees.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    if (data.containsKey('first')) {
      final l$first = data['first'];
      result$data['first'] = (l$first as int?);
    }
    if (data.containsKey('after')) {
      final l$after = data['after'];
      result$data['after'] = (l$after as String?);
    }
    if (data.containsKey('search')) {
      final l$search = data['search'];
      result$data['search'] = (l$search as String?);
    }
    if (data.containsKey('department')) {
      final l$department = data['department'];
      result$data['department'] = (l$department as String?);
    }
    if (data.containsKey('status')) {
      final l$status = data['status'];
      result$data['status'] = (l$status as String?);
    }
    return Variables$Query$Employees._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  int? get first => (_$data['first'] as int?);

  String? get after => (_$data['after'] as String?);

  String? get search => (_$data['search'] as String?);

  String? get department => (_$data['department'] as String?);

  String? get status => (_$data['status'] as String?);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    if (_$data.containsKey('first')) {
      final l$first = first;
      result$data['first'] = l$first;
    }
    if (_$data.containsKey('after')) {
      final l$after = after;
      result$data['after'] = l$after;
    }
    if (_$data.containsKey('search')) {
      final l$search = search;
      result$data['search'] = l$search;
    }
    if (_$data.containsKey('department')) {
      final l$department = department;
      result$data['department'] = l$department;
    }
    if (_$data.containsKey('status')) {
      final l$status = status;
      result$data['status'] = l$status;
    }
    return result$data;
  }

  CopyWith$Variables$Query$Employees<Variables$Query$Employees> get copyWith =>
      CopyWith$Variables$Query$Employees(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$Employees ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    final l$first = first;
    final lOther$first = other.first;
    if (_$data.containsKey('first') != other._$data.containsKey('first')) {
      return false;
    }
    if (l$first != lOther$first) {
      return false;
    }
    final l$after = after;
    final lOther$after = other.after;
    if (_$data.containsKey('after') != other._$data.containsKey('after')) {
      return false;
    }
    if (l$after != lOther$after) {
      return false;
    }
    final l$search = search;
    final lOther$search = other.search;
    if (_$data.containsKey('search') != other._$data.containsKey('search')) {
      return false;
    }
    if (l$search != lOther$search) {
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
    final l$status = status;
    final lOther$status = other.status;
    if (_$data.containsKey('status') != other._$data.containsKey('status')) {
      return false;
    }
    if (l$status != lOther$status) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    final l$first = first;
    final l$after = after;
    final l$search = search;
    final l$department = department;
    final l$status = status;
    return Object.hashAll([
      l$siteId,
      _$data.containsKey('first') ? l$first : const {},
      _$data.containsKey('after') ? l$after : const {},
      _$data.containsKey('search') ? l$search : const {},
      _$data.containsKey('department') ? l$department : const {},
      _$data.containsKey('status') ? l$status : const {},
    ]);
  }
}

abstract class CopyWith$Variables$Query$Employees<TRes> {
  factory CopyWith$Variables$Query$Employees(
    Variables$Query$Employees instance,
    TRes Function(Variables$Query$Employees) then,
  ) = _CopyWithImpl$Variables$Query$Employees;

  factory CopyWith$Variables$Query$Employees.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$Employees;

  TRes call({
    String? siteId,
    int? first,
    String? after,
    String? search,
    String? department,
    String? status,
  });
}

class _CopyWithImpl$Variables$Query$Employees<TRes>
    implements CopyWith$Variables$Query$Employees<TRes> {
  _CopyWithImpl$Variables$Query$Employees(this._instance, this._then);

  final Variables$Query$Employees _instance;

  final TRes Function(Variables$Query$Employees) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? siteId = _undefined,
    Object? first = _undefined,
    Object? after = _undefined,
    Object? search = _undefined,
    Object? department = _undefined,
    Object? status = _undefined,
  }) => _then(
    Variables$Query$Employees._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
      if (first != _undefined) 'first': (first as int?),
      if (after != _undefined) 'after': (after as String?),
      if (search != _undefined) 'search': (search as String?),
      if (department != _undefined) 'department': (department as String?),
      if (status != _undefined) 'status': (status as String?),
    }),
  );
}

class _CopyWithStubImpl$Variables$Query$Employees<TRes>
    implements CopyWith$Variables$Query$Employees<TRes> {
  _CopyWithStubImpl$Variables$Query$Employees(this._res);

  TRes _res;

  call({
    String? siteId,
    int? first,
    String? after,
    String? search,
    String? department,
    String? status,
  }) => _res;
}

class Query$Employees {
  Query$Employees({required this.employees, this.$__typename = 'Query'});

  factory Query$Employees.fromJson(Map<String, dynamic> json) {
    final l$employees = json['employees'];
    final l$$__typename = json['__typename'];
    return Query$Employees(
      employees: Query$Employees$employees.fromJson(
        (l$employees as Map<String, dynamic>),
      ),
      $__typename: (l$$__typename as String),
    );
  }

  final Query$Employees$employees employees;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$employees = employees;
    _resultData['employees'] = l$employees.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$employees = employees;
    final l$$__typename = $__typename;
    return Object.hashAll([l$employees, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$Employees || runtimeType != other.runtimeType) {
      return false;
    }
    final l$employees = employees;
    final lOther$employees = other.employees;
    if (l$employees != lOther$employees) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$Employees on Query$Employees {
  CopyWith$Query$Employees<Query$Employees> get copyWith =>
      CopyWith$Query$Employees(this, (i) => i);
}

abstract class CopyWith$Query$Employees<TRes> {
  factory CopyWith$Query$Employees(
    Query$Employees instance,
    TRes Function(Query$Employees) then,
  ) = _CopyWithImpl$Query$Employees;

  factory CopyWith$Query$Employees.stub(TRes res) =
      _CopyWithStubImpl$Query$Employees;

  TRes call({Query$Employees$employees? employees, String? $__typename});
  CopyWith$Query$Employees$employees<TRes> get employees;
}

class _CopyWithImpl$Query$Employees<TRes>
    implements CopyWith$Query$Employees<TRes> {
  _CopyWithImpl$Query$Employees(this._instance, this._then);

  final Query$Employees _instance;

  final TRes Function(Query$Employees) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? employees = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$Employees(
      employees: employees == _undefined || employees == null
          ? _instance.employees
          : (employees as Query$Employees$employees),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Query$Employees$employees<TRes> get employees {
    final local$employees = _instance.employees;
    return CopyWith$Query$Employees$employees(
      local$employees,
      (e) => call(employees: e),
    );
  }
}

class _CopyWithStubImpl$Query$Employees<TRes>
    implements CopyWith$Query$Employees<TRes> {
  _CopyWithStubImpl$Query$Employees(this._res);

  TRes _res;

  call({Query$Employees$employees? employees, String? $__typename}) => _res;

  CopyWith$Query$Employees$employees<TRes> get employees =>
      CopyWith$Query$Employees$employees.stub(_res);
}

const documentNodeQueryEmployees = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'Employees'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'first')),
          type: NamedTypeNode(name: NameNode(value: 'Int'), isNonNull: false),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'after')),
          type: NamedTypeNode(
            name: NameNode(value: 'String'),
            isNonNull: false,
          ),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'search')),
          type: NamedTypeNode(
            name: NameNode(value: 'String'),
            isNonNull: false,
          ),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'department')),
          type: NamedTypeNode(
            name: NameNode(value: 'String'),
            isNonNull: false,
          ),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'status')),
          type: NamedTypeNode(
            name: NameNode(value: 'String'),
            isNonNull: false,
          ),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'employees'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'first'),
                value: VariableNode(name: NameNode(value: 'first')),
              ),
              ArgumentNode(
                name: NameNode(value: 'after'),
                value: VariableNode(name: NameNode(value: 'after')),
              ),
              ArgumentNode(
                name: NameNode(value: 'search'),
                value: VariableNode(name: NameNode(value: 'search')),
              ),
              ArgumentNode(
                name: NameNode(value: 'department'),
                value: VariableNode(name: NameNode(value: 'department')),
              ),
              ArgumentNode(
                name: NameNode(value: 'status'),
                value: VariableNode(name: NameNode(value: 'status')),
              ),
            ],
            directives: [],
            selectionSet: SelectionSetNode(
              selections: [
                FieldNode(
                  name: NameNode(value: 'nodes'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FragmentSpreadNode(
                        name: NameNode(value: 'EmployeeFields'),
                        directives: [],
                      ),
                      FragmentSpreadNode(
                        name: NameNode(value: 'EmployeeAdminFields'),
                        directives: [],
                      ),
                      FieldNode(
                        name: NameNode(value: '__typename'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                    ],
                  ),
                ),
                FieldNode(
                  name: NameNode(value: 'endCursor'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'hasNextPage'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: '__typename'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
              ],
            ),
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
    fragmentDefinitionEmployeeFields,
    fragmentDefinitionPersonalFields,
    fragmentDefinitionEmployeeAdminFields,
  ],
);
Query$Employees _parserFn$Query$Employees(Map<String, dynamic> data) =>
    Query$Employees.fromJson(data);
typedef OnQueryComplete$Query$Employees = FutureOr<void> Function(
  Map<String, dynamic>?,
  Query$Employees?,
);

class Options$Query$Employees extends graphql.QueryOptions<Query$Employees> {
  Options$Query$Employees({
    String? operationName,
    required Variables$Query$Employees variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$Employees? typedOptimisticResult,
    Duration? pollInterval,
    graphql.Context? context,
    OnQueryComplete$Query$Employees? onComplete,
    graphql.OnQueryError? onError,
  }) : onCompleteWithParsed = onComplete,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         pollInterval: pollInterval,
         context: context,
         onComplete: onComplete == null
             ? null
             : (data) => onComplete(
                 data,
                 data == null ? null : _parserFn$Query$Employees(data),
               ),
         onError: onError,
         document: documentNodeQueryEmployees,
         parserFn: _parserFn$Query$Employees,
       );

  final OnQueryComplete$Query$Employees? onCompleteWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onComplete == null
        ? super.properties
        : super.properties.where((property) => property != onComplete),
    onCompleteWithParsed,
  ];
}

class WatchOptions$Query$Employees
    extends graphql.WatchQueryOptions<Query$Employees> {
  WatchOptions$Query$Employees({
    String? operationName,
    required Variables$Query$Employees variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$Employees? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeQueryEmployees,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Query$Employees,
       );
}

class FetchMoreOptions$Query$Employees extends graphql.FetchMoreOptions {
  FetchMoreOptions$Query$Employees({
    required graphql.UpdateQuery updateQuery,
    required Variables$Query$Employees variables,
  }) : super(
         updateQuery: updateQuery,
         variables: variables.toJson(),
         document: documentNodeQueryEmployees,
       );
}

extension ClientExtension$Query$Employees on graphql.GraphQLClient {
  Future<graphql.QueryResult<Query$Employees>> query$Employees(
    Options$Query$Employees options,
  ) async => await this.query(options);

  graphql.ObservableQuery<Query$Employees> watchQuery$Employees(
    WatchOptions$Query$Employees options,
  ) => this.watchQuery(options);

  void writeQuery$Employees({
    required Query$Employees data,
    required Variables$Query$Employees variables,
    bool broadcast = true,
  }) => this.writeQuery(
    graphql.Request(
      operation: graphql.Operation(document: documentNodeQueryEmployees),
      variables: variables.toJson(),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Query$Employees? readQuery$Employees({
    required Variables$Query$Employees variables,
    bool optimistic = true,
  }) {
    final result = this.readQuery(
      graphql.Request(
        operation: graphql.Operation(document: documentNodeQueryEmployees),
        variables: variables.toJson(),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Query$Employees.fromJson(result);
  }
}

class Query$Employees$employees {
  Query$Employees$employees({
    required this.nodes,
    this.endCursor,
    required this.hasNextPage,
    this.$__typename = 'EmployeePage',
  });

  factory Query$Employees$employees.fromJson(Map<String, dynamic> json) {
    final l$nodes = json['nodes'];
    final l$endCursor = json['endCursor'];
    final l$hasNextPage = json['hasNextPage'];
    final l$$__typename = json['__typename'];
    return Query$Employees$employees(
      nodes: (l$nodes as List<dynamic>)
          .map(
            (e) => Query$Employees$employees$nodes.fromJson(
              (e as Map<String, dynamic>),
            ),
          )
          .toList(),
      endCursor: (l$endCursor as String?),
      hasNextPage: (l$hasNextPage as bool),
      $__typename: (l$$__typename as String),
    );
  }

  final List<Query$Employees$employees$nodes> nodes;

  final String? endCursor;

  final bool hasNextPage;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$nodes = nodes;
    _resultData['nodes'] = l$nodes.map((e) => e.toJson()).toList();
    final l$endCursor = endCursor;
    _resultData['endCursor'] = l$endCursor;
    final l$hasNextPage = hasNextPage;
    _resultData['hasNextPage'] = l$hasNextPage;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$nodes = nodes;
    final l$endCursor = endCursor;
    final l$hasNextPage = hasNextPage;
    final l$$__typename = $__typename;
    return Object.hashAll([
      Object.hashAll(l$nodes.map((v) => v)),
      l$endCursor,
      l$hasNextPage,
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$Employees$employees ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$nodes = nodes;
    final lOther$nodes = other.nodes;
    if (l$nodes.length != lOther$nodes.length) {
      return false;
    }
    for (int i = 0; i < l$nodes.length; i++) {
      final l$nodes$entry = l$nodes[i];
      final lOther$nodes$entry = lOther$nodes[i];
      if (l$nodes$entry != lOther$nodes$entry) {
        return false;
      }
    }
    final l$endCursor = endCursor;
    final lOther$endCursor = other.endCursor;
    if (l$endCursor != lOther$endCursor) {
      return false;
    }
    final l$hasNextPage = hasNextPage;
    final lOther$hasNextPage = other.hasNextPage;
    if (l$hasNextPage != lOther$hasNextPage) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$Employees$employees
    on Query$Employees$employees {
  CopyWith$Query$Employees$employees<Query$Employees$employees> get copyWith =>
      CopyWith$Query$Employees$employees(this, (i) => i);
}

abstract class CopyWith$Query$Employees$employees<TRes> {
  factory CopyWith$Query$Employees$employees(
    Query$Employees$employees instance,
    TRes Function(Query$Employees$employees) then,
  ) = _CopyWithImpl$Query$Employees$employees;

  factory CopyWith$Query$Employees$employees.stub(TRes res) =
      _CopyWithStubImpl$Query$Employees$employees;

  TRes call({
    List<Query$Employees$employees$nodes>? nodes,
    String? endCursor,
    bool? hasNextPage,
    String? $__typename,
  });
  TRes nodes(
    Iterable<Query$Employees$employees$nodes> Function(
      Iterable<
        CopyWith$Query$Employees$employees$nodes<
          Query$Employees$employees$nodes
        >
      >,
    )
    _fn,
  );
}

class _CopyWithImpl$Query$Employees$employees<TRes>
    implements CopyWith$Query$Employees$employees<TRes> {
  _CopyWithImpl$Query$Employees$employees(this._instance, this._then);

  final Query$Employees$employees _instance;

  final TRes Function(Query$Employees$employees) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? nodes = _undefined,
    Object? endCursor = _undefined,
    Object? hasNextPage = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$Employees$employees(
      nodes: nodes == _undefined || nodes == null
          ? _instance.nodes
          : (nodes as List<Query$Employees$employees$nodes>),
      endCursor: endCursor == _undefined
          ? _instance.endCursor
          : (endCursor as String?),
      hasNextPage: hasNextPage == _undefined || hasNextPage == null
          ? _instance.hasNextPage
          : (hasNextPage as bool),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  TRes nodes(
    Iterable<Query$Employees$employees$nodes> Function(
      Iterable<
        CopyWith$Query$Employees$employees$nodes<
          Query$Employees$employees$nodes
        >
      >,
    )
    _fn,
  ) => call(
    nodes: _fn(
      _instance.nodes.map(
        (e) => CopyWith$Query$Employees$employees$nodes(e, (i) => i),
      ),
    ).toList(),
  );
}

class _CopyWithStubImpl$Query$Employees$employees<TRes>
    implements CopyWith$Query$Employees$employees<TRes> {
  _CopyWithStubImpl$Query$Employees$employees(this._res);

  TRes _res;

  call({
    List<Query$Employees$employees$nodes>? nodes,
    String? endCursor,
    bool? hasNextPage,
    String? $__typename,
  }) => _res;

  nodes(_fn) => _res;
}

class Query$Employees$employees$nodes
    implements Fragment$EmployeeFields, Fragment$EmployeeAdminFields {
  Query$Employees$employees$nodes({
    this.userId,
    required this.allowedActions,
    required this.permittedFields,
    this.salary,
    this.bank,
    this.identity,
    required this.id,
    required this.employeeCode,
    required this.displayName,
    this.workEmail,
    this.phone,
    this.personal,
    this.photoUpdatedAt,
    this.jobTitle,
    this.department,
    required this.version,
    required this.isSelf,
    required this.employment,
    required this.assignments,
    this.$__typename = 'Employee',
    this.status,
    this.login,
  });

  factory Query$Employees$employees$nodes.fromJson(Map<String, dynamic> json) {
    final l$userId = json['userId'];
    final l$allowedActions = json['allowedActions'];
    final l$permittedFields = json['permittedFields'];
    final l$salary = json['salary'];
    final l$bank = json['bank'];
    final l$identity = json['identity'];
    final l$id = json['id'];
    final l$employeeCode = json['employeeCode'];
    final l$displayName = json['displayName'];
    final l$workEmail = json['workEmail'];
    final l$phone = json['phone'];
    final l$personal = json['personal'];
    final l$photoUpdatedAt = json['photoUpdatedAt'];
    final l$jobTitle = json['jobTitle'];
    final l$department = json['department'];
    final l$version = json['version'];
    final l$isSelf = json['isSelf'];
    final l$employment = json['employment'];
    final l$assignments = json['assignments'];
    final l$$__typename = json['__typename'];
    final l$status = json['status'];
    final l$login = json['login'];
    return Query$Employees$employees$nodes(
      userId: (l$userId as String?),
      allowedActions: (l$allowedActions as List<dynamic>)
          .map((e) => (e as String))
          .toList(),
      permittedFields: (l$permittedFields as List<dynamic>)
          .map((e) => (e as String))
          .toList(),
      salary: (l$salary as String?),
      bank: (l$bank as String?),
      identity: (l$identity as String?),
      id: (l$id as String),
      employeeCode: (l$employeeCode as String),
      displayName: (l$displayName as String),
      workEmail: (l$workEmail as String?),
      phone: (l$phone as String?),
      personal: l$personal == null
          ? null
          : Fragment$PersonalFields.fromJson(
              (l$personal as Map<String, dynamic>),
            ),
      photoUpdatedAt: (l$photoUpdatedAt as String?),
      jobTitle: (l$jobTitle as String?),
      department: (l$department as String?),
      version: (l$version as int),
      isSelf: (l$isSelf as bool),
      employment: (l$employment as List<dynamic>)
          .map(
            (e) => Query$Employees$employees$nodes$employment.fromJson(
              (e as Map<String, dynamic>),
            ),
          )
          .toList(),
      assignments: (l$assignments as List<dynamic>)
          .map(
            (e) => Query$Employees$employees$nodes$assignments.fromJson(
              (e as Map<String, dynamic>),
            ),
          )
          .toList(),
      $__typename: (l$$__typename as String),
      status: (l$status as String?),
      login: l$login == null
          ? null
          : Query$Employees$employees$nodes$login.fromJson(
              (l$login as Map<String, dynamic>),
            ),
    );
  }

  final String? userId;

  final List<String> allowedActions;

  final List<String> permittedFields;

  final String? salary;

  final String? bank;

  final String? identity;

  final String id;

  final String employeeCode;

  final String displayName;

  final String? workEmail;

  final String? phone;

  final Fragment$PersonalFields? personal;

  final String? photoUpdatedAt;

  final String? jobTitle;

  final String? department;

  final int version;

  final bool isSelf;

  final List<Query$Employees$employees$nodes$employment> employment;

  final List<Query$Employees$employees$nodes$assignments> assignments;

  final String $__typename;

  final String? status;

  final Query$Employees$employees$nodes$login? login;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$userId = userId;
    _resultData['userId'] = l$userId;
    final l$allowedActions = allowedActions;
    _resultData['allowedActions'] = l$allowedActions.map((e) => e).toList();
    final l$permittedFields = permittedFields;
    _resultData['permittedFields'] = l$permittedFields.map((e) => e).toList();
    final l$salary = salary;
    _resultData['salary'] = l$salary;
    final l$bank = bank;
    _resultData['bank'] = l$bank;
    final l$identity = identity;
    _resultData['identity'] = l$identity;
    final l$id = id;
    _resultData['id'] = l$id;
    final l$employeeCode = employeeCode;
    _resultData['employeeCode'] = l$employeeCode;
    final l$displayName = displayName;
    _resultData['displayName'] = l$displayName;
    final l$workEmail = workEmail;
    _resultData['workEmail'] = l$workEmail;
    final l$phone = phone;
    _resultData['phone'] = l$phone;
    final l$personal = personal;
    _resultData['personal'] = l$personal?.toJson();
    final l$photoUpdatedAt = photoUpdatedAt;
    _resultData['photoUpdatedAt'] = l$photoUpdatedAt;
    final l$jobTitle = jobTitle;
    _resultData['jobTitle'] = l$jobTitle;
    final l$department = department;
    _resultData['department'] = l$department;
    final l$version = version;
    _resultData['version'] = l$version;
    final l$isSelf = isSelf;
    _resultData['isSelf'] = l$isSelf;
    final l$employment = employment;
    _resultData['employment'] = l$employment.map((e) => e.toJson()).toList();
    final l$assignments = assignments;
    _resultData['assignments'] = l$assignments.map((e) => e.toJson()).toList();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    final l$status = status;
    _resultData['status'] = l$status;
    final l$login = login;
    _resultData['login'] = l$login?.toJson();
    return _resultData;
  }

  @override
  int get hashCode {
    final l$userId = userId;
    final l$allowedActions = allowedActions;
    final l$permittedFields = permittedFields;
    final l$salary = salary;
    final l$bank = bank;
    final l$identity = identity;
    final l$id = id;
    final l$employeeCode = employeeCode;
    final l$displayName = displayName;
    final l$workEmail = workEmail;
    final l$phone = phone;
    final l$personal = personal;
    final l$photoUpdatedAt = photoUpdatedAt;
    final l$jobTitle = jobTitle;
    final l$department = department;
    final l$version = version;
    final l$isSelf = isSelf;
    final l$employment = employment;
    final l$assignments = assignments;
    final l$$__typename = $__typename;
    final l$status = status;
    final l$login = login;
    return Object.hashAll([
      l$userId,
      Object.hashAll(l$allowedActions.map((v) => v)),
      Object.hashAll(l$permittedFields.map((v) => v)),
      l$salary,
      l$bank,
      l$identity,
      l$id,
      l$employeeCode,
      l$displayName,
      l$workEmail,
      l$phone,
      l$personal,
      l$photoUpdatedAt,
      l$jobTitle,
      l$department,
      l$version,
      l$isSelf,
      Object.hashAll(l$employment.map((v) => v)),
      Object.hashAll(l$assignments.map((v) => v)),
      l$$__typename,
      l$status,
      l$login,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$Employees$employees$nodes ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$userId = userId;
    final lOther$userId = other.userId;
    if (l$userId != lOther$userId) {
      return false;
    }
    final l$allowedActions = allowedActions;
    final lOther$allowedActions = other.allowedActions;
    if (l$allowedActions.length != lOther$allowedActions.length) {
      return false;
    }
    for (int i = 0; i < l$allowedActions.length; i++) {
      final l$allowedActions$entry = l$allowedActions[i];
      final lOther$allowedActions$entry = lOther$allowedActions[i];
      if (l$allowedActions$entry != lOther$allowedActions$entry) {
        return false;
      }
    }
    final l$permittedFields = permittedFields;
    final lOther$permittedFields = other.permittedFields;
    if (l$permittedFields.length != lOther$permittedFields.length) {
      return false;
    }
    for (int i = 0; i < l$permittedFields.length; i++) {
      final l$permittedFields$entry = l$permittedFields[i];
      final lOther$permittedFields$entry = lOther$permittedFields[i];
      if (l$permittedFields$entry != lOther$permittedFields$entry) {
        return false;
      }
    }
    final l$salary = salary;
    final lOther$salary = other.salary;
    if (l$salary != lOther$salary) {
      return false;
    }
    final l$bank = bank;
    final lOther$bank = other.bank;
    if (l$bank != lOther$bank) {
      return false;
    }
    final l$identity = identity;
    final lOther$identity = other.identity;
    if (l$identity != lOther$identity) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$employeeCode = employeeCode;
    final lOther$employeeCode = other.employeeCode;
    if (l$employeeCode != lOther$employeeCode) {
      return false;
    }
    final l$displayName = displayName;
    final lOther$displayName = other.displayName;
    if (l$displayName != lOther$displayName) {
      return false;
    }
    final l$workEmail = workEmail;
    final lOther$workEmail = other.workEmail;
    if (l$workEmail != lOther$workEmail) {
      return false;
    }
    final l$phone = phone;
    final lOther$phone = other.phone;
    if (l$phone != lOther$phone) {
      return false;
    }
    final l$personal = personal;
    final lOther$personal = other.personal;
    if (l$personal != lOther$personal) {
      return false;
    }
    final l$photoUpdatedAt = photoUpdatedAt;
    final lOther$photoUpdatedAt = other.photoUpdatedAt;
    if (l$photoUpdatedAt != lOther$photoUpdatedAt) {
      return false;
    }
    final l$jobTitle = jobTitle;
    final lOther$jobTitle = other.jobTitle;
    if (l$jobTitle != lOther$jobTitle) {
      return false;
    }
    final l$department = department;
    final lOther$department = other.department;
    if (l$department != lOther$department) {
      return false;
    }
    final l$version = version;
    final lOther$version = other.version;
    if (l$version != lOther$version) {
      return false;
    }
    final l$isSelf = isSelf;
    final lOther$isSelf = other.isSelf;
    if (l$isSelf != lOther$isSelf) {
      return false;
    }
    final l$employment = employment;
    final lOther$employment = other.employment;
    if (l$employment.length != lOther$employment.length) {
      return false;
    }
    for (int i = 0; i < l$employment.length; i++) {
      final l$employment$entry = l$employment[i];
      final lOther$employment$entry = lOther$employment[i];
      if (l$employment$entry != lOther$employment$entry) {
        return false;
      }
    }
    final l$assignments = assignments;
    final lOther$assignments = other.assignments;
    if (l$assignments.length != lOther$assignments.length) {
      return false;
    }
    for (int i = 0; i < l$assignments.length; i++) {
      final l$assignments$entry = l$assignments[i];
      final lOther$assignments$entry = lOther$assignments[i];
      if (l$assignments$entry != lOther$assignments$entry) {
        return false;
      }
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    final l$status = status;
    final lOther$status = other.status;
    if (l$status != lOther$status) {
      return false;
    }
    final l$login = login;
    final lOther$login = other.login;
    if (l$login != lOther$login) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$Employees$employees$nodes
    on Query$Employees$employees$nodes {
  CopyWith$Query$Employees$employees$nodes<Query$Employees$employees$nodes>
  get copyWith => CopyWith$Query$Employees$employees$nodes(this, (i) => i);
}

abstract class CopyWith$Query$Employees$employees$nodes<TRes> {
  factory CopyWith$Query$Employees$employees$nodes(
    Query$Employees$employees$nodes instance,
    TRes Function(Query$Employees$employees$nodes) then,
  ) = _CopyWithImpl$Query$Employees$employees$nodes;

  factory CopyWith$Query$Employees$employees$nodes.stub(TRes res) =
      _CopyWithStubImpl$Query$Employees$employees$nodes;

  TRes call({
    String? userId,
    List<String>? allowedActions,
    List<String>? permittedFields,
    String? salary,
    String? bank,
    String? identity,
    String? id,
    String? employeeCode,
    String? displayName,
    String? workEmail,
    String? phone,
    Fragment$PersonalFields? personal,
    String? photoUpdatedAt,
    String? jobTitle,
    String? department,
    int? version,
    bool? isSelf,
    List<Query$Employees$employees$nodes$employment>? employment,
    List<Query$Employees$employees$nodes$assignments>? assignments,
    String? $__typename,
    String? status,
    Query$Employees$employees$nodes$login? login,
  });
  CopyWith$Fragment$PersonalFields<TRes> get personal;
  TRes employment(
    Iterable<Query$Employees$employees$nodes$employment> Function(
      Iterable<
        CopyWith$Query$Employees$employees$nodes$employment<
          Query$Employees$employees$nodes$employment
        >
      >,
    )
    _fn,
  );
  TRes assignments(
    Iterable<Query$Employees$employees$nodes$assignments> Function(
      Iterable<
        CopyWith$Query$Employees$employees$nodes$assignments<
          Query$Employees$employees$nodes$assignments
        >
      >,
    )
    _fn,
  );
  CopyWith$Query$Employees$employees$nodes$login<TRes> get login;
}

class _CopyWithImpl$Query$Employees$employees$nodes<TRes>
    implements CopyWith$Query$Employees$employees$nodes<TRes> {
  _CopyWithImpl$Query$Employees$employees$nodes(this._instance, this._then);

  final Query$Employees$employees$nodes _instance;

  final TRes Function(Query$Employees$employees$nodes) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? userId = _undefined,
    Object? allowedActions = _undefined,
    Object? permittedFields = _undefined,
    Object? salary = _undefined,
    Object? bank = _undefined,
    Object? identity = _undefined,
    Object? id = _undefined,
    Object? employeeCode = _undefined,
    Object? displayName = _undefined,
    Object? workEmail = _undefined,
    Object? phone = _undefined,
    Object? personal = _undefined,
    Object? photoUpdatedAt = _undefined,
    Object? jobTitle = _undefined,
    Object? department = _undefined,
    Object? version = _undefined,
    Object? isSelf = _undefined,
    Object? employment = _undefined,
    Object? assignments = _undefined,
    Object? $__typename = _undefined,
    Object? status = _undefined,
    Object? login = _undefined,
  }) => _then(
    Query$Employees$employees$nodes(
      userId: userId == _undefined ? _instance.userId : (userId as String?),
      allowedActions: allowedActions == _undefined || allowedActions == null
          ? _instance.allowedActions
          : (allowedActions as List<String>),
      permittedFields: permittedFields == _undefined || permittedFields == null
          ? _instance.permittedFields
          : (permittedFields as List<String>),
      salary: salary == _undefined ? _instance.salary : (salary as String?),
      bank: bank == _undefined ? _instance.bank : (bank as String?),
      identity: identity == _undefined
          ? _instance.identity
          : (identity as String?),
      id: id == _undefined || id == null ? _instance.id : (id as String),
      employeeCode: employeeCode == _undefined || employeeCode == null
          ? _instance.employeeCode
          : (employeeCode as String),
      displayName: displayName == _undefined || displayName == null
          ? _instance.displayName
          : (displayName as String),
      workEmail: workEmail == _undefined
          ? _instance.workEmail
          : (workEmail as String?),
      phone: phone == _undefined ? _instance.phone : (phone as String?),
      personal: personal == _undefined
          ? _instance.personal
          : (personal as Fragment$PersonalFields?),
      photoUpdatedAt: photoUpdatedAt == _undefined
          ? _instance.photoUpdatedAt
          : (photoUpdatedAt as String?),
      jobTitle: jobTitle == _undefined
          ? _instance.jobTitle
          : (jobTitle as String?),
      department: department == _undefined
          ? _instance.department
          : (department as String?),
      version: version == _undefined || version == null
          ? _instance.version
          : (version as int),
      isSelf: isSelf == _undefined || isSelf == null
          ? _instance.isSelf
          : (isSelf as bool),
      employment: employment == _undefined || employment == null
          ? _instance.employment
          : (employment as List<Query$Employees$employees$nodes$employment>),
      assignments: assignments == _undefined || assignments == null
          ? _instance.assignments
          : (assignments as List<Query$Employees$employees$nodes$assignments>),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
      status: status == _undefined ? _instance.status : (status as String?),
      login: login == _undefined
          ? _instance.login
          : (login as Query$Employees$employees$nodes$login?),
    ),
  );

  CopyWith$Fragment$PersonalFields<TRes> get personal {
    final local$personal = _instance.personal;
    return local$personal == null
        ? CopyWith$Fragment$PersonalFields.stub(_then(_instance))
        : CopyWith$Fragment$PersonalFields(
            local$personal,
            (e) => call(personal: e),
          );
  }

  TRes employment(
    Iterable<Query$Employees$employees$nodes$employment> Function(
      Iterable<
        CopyWith$Query$Employees$employees$nodes$employment<
          Query$Employees$employees$nodes$employment
        >
      >,
    )
    _fn,
  ) => call(
    employment: _fn(
      _instance.employment.map(
        (e) => CopyWith$Query$Employees$employees$nodes$employment(e, (i) => i),
      ),
    ).toList(),
  );

  TRes assignments(
    Iterable<Query$Employees$employees$nodes$assignments> Function(
      Iterable<
        CopyWith$Query$Employees$employees$nodes$assignments<
          Query$Employees$employees$nodes$assignments
        >
      >,
    )
    _fn,
  ) => call(
    assignments: _fn(
      _instance.assignments.map(
        (e) =>
            CopyWith$Query$Employees$employees$nodes$assignments(e, (i) => i),
      ),
    ).toList(),
  );

  CopyWith$Query$Employees$employees$nodes$login<TRes> get login {
    final local$login = _instance.login;
    return local$login == null
        ? CopyWith$Query$Employees$employees$nodes$login.stub(_then(_instance))
        : CopyWith$Query$Employees$employees$nodes$login(
            local$login,
            (e) => call(login: e),
          );
  }
}

class _CopyWithStubImpl$Query$Employees$employees$nodes<TRes>
    implements CopyWith$Query$Employees$employees$nodes<TRes> {
  _CopyWithStubImpl$Query$Employees$employees$nodes(this._res);

  TRes _res;

  call({
    String? userId,
    List<String>? allowedActions,
    List<String>? permittedFields,
    String? salary,
    String? bank,
    String? identity,
    String? id,
    String? employeeCode,
    String? displayName,
    String? workEmail,
    String? phone,
    Fragment$PersonalFields? personal,
    String? photoUpdatedAt,
    String? jobTitle,
    String? department,
    int? version,
    bool? isSelf,
    List<Query$Employees$employees$nodes$employment>? employment,
    List<Query$Employees$employees$nodes$assignments>? assignments,
    String? $__typename,
    String? status,
    Query$Employees$employees$nodes$login? login,
  }) => _res;

  CopyWith$Fragment$PersonalFields<TRes> get personal =>
      CopyWith$Fragment$PersonalFields.stub(_res);

  employment(_fn) => _res;

  assignments(_fn) => _res;

  CopyWith$Query$Employees$employees$nodes$login<TRes> get login =>
      CopyWith$Query$Employees$employees$nodes$login.stub(_res);
}

class Query$Employees$employees$nodes$employment
    implements Fragment$EmployeeFields$employment {
  Query$Employees$employees$nodes$employment({
    required this.id,
    required this.startsOn,
    this.endsOn,
    required this.legalEmployer,
    this.$__typename = 'Employment',
  });

  factory Query$Employees$employees$nodes$employment.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$id = json['id'];
    final l$startsOn = json['startsOn'];
    final l$endsOn = json['endsOn'];
    final l$legalEmployer = json['legalEmployer'];
    final l$$__typename = json['__typename'];
    return Query$Employees$employees$nodes$employment(
      id: (l$id as String),
      startsOn: (l$startsOn as String),
      endsOn: (l$endsOn as String?),
      legalEmployer:
          Query$Employees$employees$nodes$employment$legalEmployer.fromJson(
            (l$legalEmployer as Map<String, dynamic>),
          ),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String startsOn;

  final String? endsOn;

  final Query$Employees$employees$nodes$employment$legalEmployer legalEmployer;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$startsOn = startsOn;
    _resultData['startsOn'] = l$startsOn;
    final l$endsOn = endsOn;
    _resultData['endsOn'] = l$endsOn;
    final l$legalEmployer = legalEmployer;
    _resultData['legalEmployer'] = l$legalEmployer.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$startsOn = startsOn;
    final l$endsOn = endsOn;
    final l$legalEmployer = legalEmployer;
    final l$$__typename = $__typename;
    return Object.hashAll([
      l$id,
      l$startsOn,
      l$endsOn,
      l$legalEmployer,
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$Employees$employees$nodes$employment ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$startsOn = startsOn;
    final lOther$startsOn = other.startsOn;
    if (l$startsOn != lOther$startsOn) {
      return false;
    }
    final l$endsOn = endsOn;
    final lOther$endsOn = other.endsOn;
    if (l$endsOn != lOther$endsOn) {
      return false;
    }
    final l$legalEmployer = legalEmployer;
    final lOther$legalEmployer = other.legalEmployer;
    if (l$legalEmployer != lOther$legalEmployer) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$Employees$employees$nodes$employment
    on Query$Employees$employees$nodes$employment {
  CopyWith$Query$Employees$employees$nodes$employment<
    Query$Employees$employees$nodes$employment
  >
  get copyWith =>
      CopyWith$Query$Employees$employees$nodes$employment(this, (i) => i);
}

abstract class CopyWith$Query$Employees$employees$nodes$employment<TRes> {
  factory CopyWith$Query$Employees$employees$nodes$employment(
    Query$Employees$employees$nodes$employment instance,
    TRes Function(Query$Employees$employees$nodes$employment) then,
  ) = _CopyWithImpl$Query$Employees$employees$nodes$employment;

  factory CopyWith$Query$Employees$employees$nodes$employment.stub(TRes res) =
      _CopyWithStubImpl$Query$Employees$employees$nodes$employment;

  TRes call({
    String? id,
    String? startsOn,
    String? endsOn,
    Query$Employees$employees$nodes$employment$legalEmployer? legalEmployer,
    String? $__typename,
  });
  CopyWith$Query$Employees$employees$nodes$employment$legalEmployer<TRes>
  get legalEmployer;
}

class _CopyWithImpl$Query$Employees$employees$nodes$employment<TRes>
    implements CopyWith$Query$Employees$employees$nodes$employment<TRes> {
  _CopyWithImpl$Query$Employees$employees$nodes$employment(
    this._instance,
    this._then,
  );

  final Query$Employees$employees$nodes$employment _instance;

  final TRes Function(Query$Employees$employees$nodes$employment) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? startsOn = _undefined,
    Object? endsOn = _undefined,
    Object? legalEmployer = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$Employees$employees$nodes$employment(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      startsOn: startsOn == _undefined || startsOn == null
          ? _instance.startsOn
          : (startsOn as String),
      endsOn: endsOn == _undefined ? _instance.endsOn : (endsOn as String?),
      legalEmployer: legalEmployer == _undefined || legalEmployer == null
          ? _instance.legalEmployer
          : (legalEmployer
                as Query$Employees$employees$nodes$employment$legalEmployer),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Query$Employees$employees$nodes$employment$legalEmployer<TRes>
  get legalEmployer {
    final local$legalEmployer = _instance.legalEmployer;
    return CopyWith$Query$Employees$employees$nodes$employment$legalEmployer(
      local$legalEmployer,
      (e) => call(legalEmployer: e),
    );
  }
}

class _CopyWithStubImpl$Query$Employees$employees$nodes$employment<TRes>
    implements CopyWith$Query$Employees$employees$nodes$employment<TRes> {
  _CopyWithStubImpl$Query$Employees$employees$nodes$employment(this._res);

  TRes _res;

  call({
    String? id,
    String? startsOn,
    String? endsOn,
    Query$Employees$employees$nodes$employment$legalEmployer? legalEmployer,
    String? $__typename,
  }) => _res;

  CopyWith$Query$Employees$employees$nodes$employment$legalEmployer<TRes>
  get legalEmployer =>
      CopyWith$Query$Employees$employees$nodes$employment$legalEmployer.stub(
        _res,
      );
}

class Query$Employees$employees$nodes$employment$legalEmployer
    implements Fragment$EmployeeFields$employment$legalEmployer {
  Query$Employees$employees$nodes$employment$legalEmployer({
    required this.id,
    required this.name,
    this.$__typename = 'LegalEmployer',
  });

  factory Query$Employees$employees$nodes$employment$legalEmployer.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$id = json['id'];
    final l$name = json['name'];
    final l$$__typename = json['__typename'];
    return Query$Employees$employees$nodes$employment$legalEmployer(
      id: (l$id as String),
      name: (l$name as String),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String name;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$name = name;
    _resultData['name'] = l$name;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$name = name;
    final l$$__typename = $__typename;
    return Object.hashAll([l$id, l$name, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$Employees$employees$nodes$employment$legalEmployer ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$name = name;
    final lOther$name = other.name;
    if (l$name != lOther$name) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$Employees$employees$nodes$employment$legalEmployer
    on Query$Employees$employees$nodes$employment$legalEmployer {
  CopyWith$Query$Employees$employees$nodes$employment$legalEmployer<
    Query$Employees$employees$nodes$employment$legalEmployer
  >
  get copyWith =>
      CopyWith$Query$Employees$employees$nodes$employment$legalEmployer(
        this,
        (i) => i,
      );
}

abstract class CopyWith$Query$Employees$employees$nodes$employment$legalEmployer<
  TRes
> {
  factory CopyWith$Query$Employees$employees$nodes$employment$legalEmployer(
    Query$Employees$employees$nodes$employment$legalEmployer instance,
    TRes Function(Query$Employees$employees$nodes$employment$legalEmployer)
    then,
  ) = _CopyWithImpl$Query$Employees$employees$nodes$employment$legalEmployer;

  factory CopyWith$Query$Employees$employees$nodes$employment$legalEmployer.stub(
    TRes res,
  ) = _CopyWithStubImpl$Query$Employees$employees$nodes$employment$legalEmployer;

  TRes call({String? id, String? name, String? $__typename});
}

class _CopyWithImpl$Query$Employees$employees$nodes$employment$legalEmployer<
  TRes
>
    implements
        CopyWith$Query$Employees$employees$nodes$employment$legalEmployer<
          TRes
        > {
  _CopyWithImpl$Query$Employees$employees$nodes$employment$legalEmployer(
    this._instance,
    this._then,
  );

  final Query$Employees$employees$nodes$employment$legalEmployer _instance;

  final TRes Function(Query$Employees$employees$nodes$employment$legalEmployer)
  _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? name = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$Employees$employees$nodes$employment$legalEmployer(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      name: name == _undefined || name == null
          ? _instance.name
          : (name as String),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$Employees$employees$nodes$employment$legalEmployer<
  TRes
>
    implements
        CopyWith$Query$Employees$employees$nodes$employment$legalEmployer<
          TRes
        > {
  _CopyWithStubImpl$Query$Employees$employees$nodes$employment$legalEmployer(
    this._res,
  );

  TRes _res;

  call({String? id, String? name, String? $__typename}) => _res;
}

class Query$Employees$employees$nodes$assignments
    implements Fragment$EmployeeFields$assignments {
  Query$Employees$employees$nodes$assignments({
    required this.id,
    required this.startsOn,
    this.endsOn,
    required this.site,
    this.$__typename = 'SiteAssignment',
  });

  factory Query$Employees$employees$nodes$assignments.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$id = json['id'];
    final l$startsOn = json['startsOn'];
    final l$endsOn = json['endsOn'];
    final l$site = json['site'];
    final l$$__typename = json['__typename'];
    return Query$Employees$employees$nodes$assignments(
      id: (l$id as String),
      startsOn: (l$startsOn as String),
      endsOn: (l$endsOn as String?),
      site: Query$Employees$employees$nodes$assignments$site.fromJson(
        (l$site as Map<String, dynamic>),
      ),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String startsOn;

  final String? endsOn;

  final Query$Employees$employees$nodes$assignments$site site;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$startsOn = startsOn;
    _resultData['startsOn'] = l$startsOn;
    final l$endsOn = endsOn;
    _resultData['endsOn'] = l$endsOn;
    final l$site = site;
    _resultData['site'] = l$site.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$startsOn = startsOn;
    final l$endsOn = endsOn;
    final l$site = site;
    final l$$__typename = $__typename;
    return Object.hashAll([l$id, l$startsOn, l$endsOn, l$site, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$Employees$employees$nodes$assignments ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$startsOn = startsOn;
    final lOther$startsOn = other.startsOn;
    if (l$startsOn != lOther$startsOn) {
      return false;
    }
    final l$endsOn = endsOn;
    final lOther$endsOn = other.endsOn;
    if (l$endsOn != lOther$endsOn) {
      return false;
    }
    final l$site = site;
    final lOther$site = other.site;
    if (l$site != lOther$site) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$Employees$employees$nodes$assignments
    on Query$Employees$employees$nodes$assignments {
  CopyWith$Query$Employees$employees$nodes$assignments<
    Query$Employees$employees$nodes$assignments
  >
  get copyWith =>
      CopyWith$Query$Employees$employees$nodes$assignments(this, (i) => i);
}

abstract class CopyWith$Query$Employees$employees$nodes$assignments<TRes> {
  factory CopyWith$Query$Employees$employees$nodes$assignments(
    Query$Employees$employees$nodes$assignments instance,
    TRes Function(Query$Employees$employees$nodes$assignments) then,
  ) = _CopyWithImpl$Query$Employees$employees$nodes$assignments;

  factory CopyWith$Query$Employees$employees$nodes$assignments.stub(TRes res) =
      _CopyWithStubImpl$Query$Employees$employees$nodes$assignments;

  TRes call({
    String? id,
    String? startsOn,
    String? endsOn,
    Query$Employees$employees$nodes$assignments$site? site,
    String? $__typename,
  });
  CopyWith$Query$Employees$employees$nodes$assignments$site<TRes> get site;
}

class _CopyWithImpl$Query$Employees$employees$nodes$assignments<TRes>
    implements CopyWith$Query$Employees$employees$nodes$assignments<TRes> {
  _CopyWithImpl$Query$Employees$employees$nodes$assignments(
    this._instance,
    this._then,
  );

  final Query$Employees$employees$nodes$assignments _instance;

  final TRes Function(Query$Employees$employees$nodes$assignments) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? startsOn = _undefined,
    Object? endsOn = _undefined,
    Object? site = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$Employees$employees$nodes$assignments(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      startsOn: startsOn == _undefined || startsOn == null
          ? _instance.startsOn
          : (startsOn as String),
      endsOn: endsOn == _undefined ? _instance.endsOn : (endsOn as String?),
      site: site == _undefined || site == null
          ? _instance.site
          : (site as Query$Employees$employees$nodes$assignments$site),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Query$Employees$employees$nodes$assignments$site<TRes> get site {
    final local$site = _instance.site;
    return CopyWith$Query$Employees$employees$nodes$assignments$site(
      local$site,
      (e) => call(site: e),
    );
  }
}

class _CopyWithStubImpl$Query$Employees$employees$nodes$assignments<TRes>
    implements CopyWith$Query$Employees$employees$nodes$assignments<TRes> {
  _CopyWithStubImpl$Query$Employees$employees$nodes$assignments(this._res);

  TRes _res;

  call({
    String? id,
    String? startsOn,
    String? endsOn,
    Query$Employees$employees$nodes$assignments$site? site,
    String? $__typename,
  }) => _res;

  CopyWith$Query$Employees$employees$nodes$assignments$site<TRes> get site =>
      CopyWith$Query$Employees$employees$nodes$assignments$site.stub(_res);
}

class Query$Employees$employees$nodes$assignments$site
    implements Fragment$EmployeeFields$assignments$site {
  Query$Employees$employees$nodes$assignments$site({
    required this.id,
    required this.name,
    required this.timezone,
    this.$__typename = 'Site',
  });

  factory Query$Employees$employees$nodes$assignments$site.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$id = json['id'];
    final l$name = json['name'];
    final l$timezone = json['timezone'];
    final l$$__typename = json['__typename'];
    return Query$Employees$employees$nodes$assignments$site(
      id: (l$id as String),
      name: (l$name as String),
      timezone: (l$timezone as String),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String name;

  final String timezone;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$name = name;
    _resultData['name'] = l$name;
    final l$timezone = timezone;
    _resultData['timezone'] = l$timezone;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$name = name;
    final l$timezone = timezone;
    final l$$__typename = $__typename;
    return Object.hashAll([l$id, l$name, l$timezone, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$Employees$employees$nodes$assignments$site ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$name = name;
    final lOther$name = other.name;
    if (l$name != lOther$name) {
      return false;
    }
    final l$timezone = timezone;
    final lOther$timezone = other.timezone;
    if (l$timezone != lOther$timezone) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$Employees$employees$nodes$assignments$site
    on Query$Employees$employees$nodes$assignments$site {
  CopyWith$Query$Employees$employees$nodes$assignments$site<
    Query$Employees$employees$nodes$assignments$site
  >
  get copyWith =>
      CopyWith$Query$Employees$employees$nodes$assignments$site(this, (i) => i);
}

abstract class CopyWith$Query$Employees$employees$nodes$assignments$site<TRes> {
  factory CopyWith$Query$Employees$employees$nodes$assignments$site(
    Query$Employees$employees$nodes$assignments$site instance,
    TRes Function(Query$Employees$employees$nodes$assignments$site) then,
  ) = _CopyWithImpl$Query$Employees$employees$nodes$assignments$site;

  factory CopyWith$Query$Employees$employees$nodes$assignments$site.stub(
    TRes res,
  ) = _CopyWithStubImpl$Query$Employees$employees$nodes$assignments$site;

  TRes call({String? id, String? name, String? timezone, String? $__typename});
}

class _CopyWithImpl$Query$Employees$employees$nodes$assignments$site<TRes>
    implements CopyWith$Query$Employees$employees$nodes$assignments$site<TRes> {
  _CopyWithImpl$Query$Employees$employees$nodes$assignments$site(
    this._instance,
    this._then,
  );

  final Query$Employees$employees$nodes$assignments$site _instance;

  final TRes Function(Query$Employees$employees$nodes$assignments$site) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? name = _undefined,
    Object? timezone = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$Employees$employees$nodes$assignments$site(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      name: name == _undefined || name == null
          ? _instance.name
          : (name as String),
      timezone: timezone == _undefined || timezone == null
          ? _instance.timezone
          : (timezone as String),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$Employees$employees$nodes$assignments$site<TRes>
    implements CopyWith$Query$Employees$employees$nodes$assignments$site<TRes> {
  _CopyWithStubImpl$Query$Employees$employees$nodes$assignments$site(this._res);

  TRes _res;

  call({String? id, String? name, String? timezone, String? $__typename}) =>
      _res;
}

class Query$Employees$employees$nodes$login
    implements Fragment$EmployeeAdminFields$login {
  Query$Employees$employees$nodes$login({
    required this.status,
    this.loginId,
    this.lastSignInAt,
    required this.devices,
    required this.protected,
    this.$__typename = 'EmployeeLogin',
  });

  factory Query$Employees$employees$nodes$login.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$status = json['status'];
    final l$loginId = json['loginId'];
    final l$lastSignInAt = json['lastSignInAt'];
    final l$devices = json['devices'];
    final l$protected = json['protected'];
    final l$$__typename = json['__typename'];
    return Query$Employees$employees$nodes$login(
      status: (l$status as String),
      loginId: (l$loginId as String?),
      lastSignInAt: (l$lastSignInAt as String?),
      devices: (l$devices as int),
      protected: (l$protected as bool),
      $__typename: (l$$__typename as String),
    );
  }

  final String status;

  final String? loginId;

  final String? lastSignInAt;

  final int devices;

  final bool protected;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$status = status;
    _resultData['status'] = l$status;
    final l$loginId = loginId;
    _resultData['loginId'] = l$loginId;
    final l$lastSignInAt = lastSignInAt;
    _resultData['lastSignInAt'] = l$lastSignInAt;
    final l$devices = devices;
    _resultData['devices'] = l$devices;
    final l$protected = protected;
    _resultData['protected'] = l$protected;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$status = status;
    final l$loginId = loginId;
    final l$lastSignInAt = lastSignInAt;
    final l$devices = devices;
    final l$protected = protected;
    final l$$__typename = $__typename;
    return Object.hashAll([
      l$status,
      l$loginId,
      l$lastSignInAt,
      l$devices,
      l$protected,
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$Employees$employees$nodes$login ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$status = status;
    final lOther$status = other.status;
    if (l$status != lOther$status) {
      return false;
    }
    final l$loginId = loginId;
    final lOther$loginId = other.loginId;
    if (l$loginId != lOther$loginId) {
      return false;
    }
    final l$lastSignInAt = lastSignInAt;
    final lOther$lastSignInAt = other.lastSignInAt;
    if (l$lastSignInAt != lOther$lastSignInAt) {
      return false;
    }
    final l$devices = devices;
    final lOther$devices = other.devices;
    if (l$devices != lOther$devices) {
      return false;
    }
    final l$protected = protected;
    final lOther$protected = other.protected;
    if (l$protected != lOther$protected) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$Employees$employees$nodes$login
    on Query$Employees$employees$nodes$login {
  CopyWith$Query$Employees$employees$nodes$login<
    Query$Employees$employees$nodes$login
  >
  get copyWith =>
      CopyWith$Query$Employees$employees$nodes$login(this, (i) => i);
}

abstract class CopyWith$Query$Employees$employees$nodes$login<TRes> {
  factory CopyWith$Query$Employees$employees$nodes$login(
    Query$Employees$employees$nodes$login instance,
    TRes Function(Query$Employees$employees$nodes$login) then,
  ) = _CopyWithImpl$Query$Employees$employees$nodes$login;

  factory CopyWith$Query$Employees$employees$nodes$login.stub(TRes res) =
      _CopyWithStubImpl$Query$Employees$employees$nodes$login;

  TRes call({
    String? status,
    String? loginId,
    String? lastSignInAt,
    int? devices,
    bool? protected,
    String? $__typename,
  });
}

class _CopyWithImpl$Query$Employees$employees$nodes$login<TRes>
    implements CopyWith$Query$Employees$employees$nodes$login<TRes> {
  _CopyWithImpl$Query$Employees$employees$nodes$login(
    this._instance,
    this._then,
  );

  final Query$Employees$employees$nodes$login _instance;

  final TRes Function(Query$Employees$employees$nodes$login) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? status = _undefined,
    Object? loginId = _undefined,
    Object? lastSignInAt = _undefined,
    Object? devices = _undefined,
    Object? protected = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$Employees$employees$nodes$login(
      status: status == _undefined || status == null
          ? _instance.status
          : (status as String),
      loginId: loginId == _undefined ? _instance.loginId : (loginId as String?),
      lastSignInAt: lastSignInAt == _undefined
          ? _instance.lastSignInAt
          : (lastSignInAt as String?),
      devices: devices == _undefined || devices == null
          ? _instance.devices
          : (devices as int),
      protected: protected == _undefined || protected == null
          ? _instance.protected
          : (protected as bool),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$Employees$employees$nodes$login<TRes>
    implements CopyWith$Query$Employees$employees$nodes$login<TRes> {
  _CopyWithStubImpl$Query$Employees$employees$nodes$login(this._res);

  TRes _res;

  call({
    String? status,
    String? loginId,
    String? lastSignInAt,
    int? devices,
    bool? protected,
    String? $__typename,
  }) => _res;
}

class Variables$Query$EmployeeRecord {
  factory Variables$Query$EmployeeRecord({
    required String siteId,
    required String id,
  }) => Variables$Query$EmployeeRecord._({r'siteId': siteId, r'id': id});

  Variables$Query$EmployeeRecord._(this._$data);

  factory Variables$Query$EmployeeRecord.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    final l$id = data['id'];
    result$data['id'] = (l$id as String);
    return Variables$Query$EmployeeRecord._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  String get id => (_$data['id'] as String);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    final l$id = id;
    result$data['id'] = l$id;
    return result$data;
  }

  CopyWith$Variables$Query$EmployeeRecord<Variables$Query$EmployeeRecord>
  get copyWith => CopyWith$Variables$Query$EmployeeRecord(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$EmployeeRecord ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    final l$id = id;
    return Object.hashAll([l$siteId, l$id]);
  }
}

abstract class CopyWith$Variables$Query$EmployeeRecord<TRes> {
  factory CopyWith$Variables$Query$EmployeeRecord(
    Variables$Query$EmployeeRecord instance,
    TRes Function(Variables$Query$EmployeeRecord) then,
  ) = _CopyWithImpl$Variables$Query$EmployeeRecord;

  factory CopyWith$Variables$Query$EmployeeRecord.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$EmployeeRecord;

  TRes call({String? siteId, String? id});
}

class _CopyWithImpl$Variables$Query$EmployeeRecord<TRes>
    implements CopyWith$Variables$Query$EmployeeRecord<TRes> {
  _CopyWithImpl$Variables$Query$EmployeeRecord(this._instance, this._then);

  final Variables$Query$EmployeeRecord _instance;

  final TRes Function(Variables$Query$EmployeeRecord) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? siteId = _undefined, Object? id = _undefined}) => _then(
    Variables$Query$EmployeeRecord._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
      if (id != _undefined && id != null) 'id': (id as String),
    }),
  );
}

class _CopyWithStubImpl$Variables$Query$EmployeeRecord<TRes>
    implements CopyWith$Variables$Query$EmployeeRecord<TRes> {
  _CopyWithStubImpl$Variables$Query$EmployeeRecord(this._res);

  TRes _res;

  call({String? siteId, String? id}) => _res;
}

class Query$EmployeeRecord {
  Query$EmployeeRecord({this.employee, this.$__typename = 'Query'});

  factory Query$EmployeeRecord.fromJson(Map<String, dynamic> json) {
    final l$employee = json['employee'];
    final l$$__typename = json['__typename'];
    return Query$EmployeeRecord(
      employee: l$employee == null
          ? null
          : Query$EmployeeRecord$employee.fromJson(
              (l$employee as Map<String, dynamic>),
            ),
      $__typename: (l$$__typename as String),
    );
  }

  final Query$EmployeeRecord$employee? employee;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$employee = employee;
    _resultData['employee'] = l$employee?.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$employee = employee;
    final l$$__typename = $__typename;
    return Object.hashAll([l$employee, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$EmployeeRecord || runtimeType != other.runtimeType) {
      return false;
    }
    final l$employee = employee;
    final lOther$employee = other.employee;
    if (l$employee != lOther$employee) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$EmployeeRecord on Query$EmployeeRecord {
  CopyWith$Query$EmployeeRecord<Query$EmployeeRecord> get copyWith =>
      CopyWith$Query$EmployeeRecord(this, (i) => i);
}

abstract class CopyWith$Query$EmployeeRecord<TRes> {
  factory CopyWith$Query$EmployeeRecord(
    Query$EmployeeRecord instance,
    TRes Function(Query$EmployeeRecord) then,
  ) = _CopyWithImpl$Query$EmployeeRecord;

  factory CopyWith$Query$EmployeeRecord.stub(TRes res) =
      _CopyWithStubImpl$Query$EmployeeRecord;

  TRes call({Query$EmployeeRecord$employee? employee, String? $__typename});
  CopyWith$Query$EmployeeRecord$employee<TRes> get employee;
}

class _CopyWithImpl$Query$EmployeeRecord<TRes>
    implements CopyWith$Query$EmployeeRecord<TRes> {
  _CopyWithImpl$Query$EmployeeRecord(this._instance, this._then);

  final Query$EmployeeRecord _instance;

  final TRes Function(Query$EmployeeRecord) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? employee = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$EmployeeRecord(
      employee: employee == _undefined
          ? _instance.employee
          : (employee as Query$EmployeeRecord$employee?),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Query$EmployeeRecord$employee<TRes> get employee {
    final local$employee = _instance.employee;
    return local$employee == null
        ? CopyWith$Query$EmployeeRecord$employee.stub(_then(_instance))
        : CopyWith$Query$EmployeeRecord$employee(
            local$employee,
            (e) => call(employee: e),
          );
  }
}

class _CopyWithStubImpl$Query$EmployeeRecord<TRes>
    implements CopyWith$Query$EmployeeRecord<TRes> {
  _CopyWithStubImpl$Query$EmployeeRecord(this._res);

  TRes _res;

  call({Query$EmployeeRecord$employee? employee, String? $__typename}) => _res;

  CopyWith$Query$EmployeeRecord$employee<TRes> get employee =>
      CopyWith$Query$EmployeeRecord$employee.stub(_res);
}

const documentNodeQueryEmployeeRecord = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'EmployeeRecord'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'id')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'employee'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'id'),
                value: VariableNode(name: NameNode(value: 'id')),
              ),
            ],
            directives: [],
            selectionSet: SelectionSetNode(
              selections: [
                FragmentSpreadNode(
                  name: NameNode(value: 'EmployeeFields'),
                  directives: [],
                ),
                FragmentSpreadNode(
                  name: NameNode(value: 'EmployeeAdminFields'),
                  directives: [],
                ),
                FieldNode(
                  name: NameNode(value: '__typename'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
              ],
            ),
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
    fragmentDefinitionEmployeeFields,
    fragmentDefinitionPersonalFields,
    fragmentDefinitionEmployeeAdminFields,
  ],
);
Query$EmployeeRecord _parserFn$Query$EmployeeRecord(
  Map<String, dynamic> data,
) => Query$EmployeeRecord.fromJson(data);
typedef OnQueryComplete$Query$EmployeeRecord = FutureOr<void> Function(
  Map<String, dynamic>?,
  Query$EmployeeRecord?,
);

class Options$Query$EmployeeRecord
    extends graphql.QueryOptions<Query$EmployeeRecord> {
  Options$Query$EmployeeRecord({
    String? operationName,
    required Variables$Query$EmployeeRecord variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$EmployeeRecord? typedOptimisticResult,
    Duration? pollInterval,
    graphql.Context? context,
    OnQueryComplete$Query$EmployeeRecord? onComplete,
    graphql.OnQueryError? onError,
  }) : onCompleteWithParsed = onComplete,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         pollInterval: pollInterval,
         context: context,
         onComplete: onComplete == null
             ? null
             : (data) => onComplete(
                 data,
                 data == null ? null : _parserFn$Query$EmployeeRecord(data),
               ),
         onError: onError,
         document: documentNodeQueryEmployeeRecord,
         parserFn: _parserFn$Query$EmployeeRecord,
       );

  final OnQueryComplete$Query$EmployeeRecord? onCompleteWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onComplete == null
        ? super.properties
        : super.properties.where((property) => property != onComplete),
    onCompleteWithParsed,
  ];
}

class WatchOptions$Query$EmployeeRecord
    extends graphql.WatchQueryOptions<Query$EmployeeRecord> {
  WatchOptions$Query$EmployeeRecord({
    String? operationName,
    required Variables$Query$EmployeeRecord variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$EmployeeRecord? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeQueryEmployeeRecord,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Query$EmployeeRecord,
       );
}

class FetchMoreOptions$Query$EmployeeRecord extends graphql.FetchMoreOptions {
  FetchMoreOptions$Query$EmployeeRecord({
    required graphql.UpdateQuery updateQuery,
    required Variables$Query$EmployeeRecord variables,
  }) : super(
         updateQuery: updateQuery,
         variables: variables.toJson(),
         document: documentNodeQueryEmployeeRecord,
       );
}

extension ClientExtension$Query$EmployeeRecord on graphql.GraphQLClient {
  Future<graphql.QueryResult<Query$EmployeeRecord>> query$EmployeeRecord(
    Options$Query$EmployeeRecord options,
  ) async => await this.query(options);

  graphql.ObservableQuery<Query$EmployeeRecord> watchQuery$EmployeeRecord(
    WatchOptions$Query$EmployeeRecord options,
  ) => this.watchQuery(options);

  void writeQuery$EmployeeRecord({
    required Query$EmployeeRecord data,
    required Variables$Query$EmployeeRecord variables,
    bool broadcast = true,
  }) => this.writeQuery(
    graphql.Request(
      operation: graphql.Operation(document: documentNodeQueryEmployeeRecord),
      variables: variables.toJson(),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Query$EmployeeRecord? readQuery$EmployeeRecord({
    required Variables$Query$EmployeeRecord variables,
    bool optimistic = true,
  }) {
    final result = this.readQuery(
      graphql.Request(
        operation: graphql.Operation(document: documentNodeQueryEmployeeRecord),
        variables: variables.toJson(),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Query$EmployeeRecord.fromJson(result);
  }
}

class Query$EmployeeRecord$employee
    implements Fragment$EmployeeFields, Fragment$EmployeeAdminFields {
  Query$EmployeeRecord$employee({
    this.userId,
    required this.allowedActions,
    required this.permittedFields,
    this.salary,
    this.bank,
    this.identity,
    required this.id,
    required this.employeeCode,
    required this.displayName,
    this.workEmail,
    this.phone,
    this.personal,
    this.photoUpdatedAt,
    this.jobTitle,
    this.department,
    required this.version,
    required this.isSelf,
    required this.employment,
    required this.assignments,
    this.$__typename = 'Employee',
    this.status,
    this.login,
  });

  factory Query$EmployeeRecord$employee.fromJson(Map<String, dynamic> json) {
    final l$userId = json['userId'];
    final l$allowedActions = json['allowedActions'];
    final l$permittedFields = json['permittedFields'];
    final l$salary = json['salary'];
    final l$bank = json['bank'];
    final l$identity = json['identity'];
    final l$id = json['id'];
    final l$employeeCode = json['employeeCode'];
    final l$displayName = json['displayName'];
    final l$workEmail = json['workEmail'];
    final l$phone = json['phone'];
    final l$personal = json['personal'];
    final l$photoUpdatedAt = json['photoUpdatedAt'];
    final l$jobTitle = json['jobTitle'];
    final l$department = json['department'];
    final l$version = json['version'];
    final l$isSelf = json['isSelf'];
    final l$employment = json['employment'];
    final l$assignments = json['assignments'];
    final l$$__typename = json['__typename'];
    final l$status = json['status'];
    final l$login = json['login'];
    return Query$EmployeeRecord$employee(
      userId: (l$userId as String?),
      allowedActions: (l$allowedActions as List<dynamic>)
          .map((e) => (e as String))
          .toList(),
      permittedFields: (l$permittedFields as List<dynamic>)
          .map((e) => (e as String))
          .toList(),
      salary: (l$salary as String?),
      bank: (l$bank as String?),
      identity: (l$identity as String?),
      id: (l$id as String),
      employeeCode: (l$employeeCode as String),
      displayName: (l$displayName as String),
      workEmail: (l$workEmail as String?),
      phone: (l$phone as String?),
      personal: l$personal == null
          ? null
          : Fragment$PersonalFields.fromJson(
              (l$personal as Map<String, dynamic>),
            ),
      photoUpdatedAt: (l$photoUpdatedAt as String?),
      jobTitle: (l$jobTitle as String?),
      department: (l$department as String?),
      version: (l$version as int),
      isSelf: (l$isSelf as bool),
      employment: (l$employment as List<dynamic>)
          .map(
            (e) => Query$EmployeeRecord$employee$employment.fromJson(
              (e as Map<String, dynamic>),
            ),
          )
          .toList(),
      assignments: (l$assignments as List<dynamic>)
          .map(
            (e) => Query$EmployeeRecord$employee$assignments.fromJson(
              (e as Map<String, dynamic>),
            ),
          )
          .toList(),
      $__typename: (l$$__typename as String),
      status: (l$status as String?),
      login: l$login == null
          ? null
          : Query$EmployeeRecord$employee$login.fromJson(
              (l$login as Map<String, dynamic>),
            ),
    );
  }

  final String? userId;

  final List<String> allowedActions;

  final List<String> permittedFields;

  final String? salary;

  final String? bank;

  final String? identity;

  final String id;

  final String employeeCode;

  final String displayName;

  final String? workEmail;

  final String? phone;

  final Fragment$PersonalFields? personal;

  final String? photoUpdatedAt;

  final String? jobTitle;

  final String? department;

  final int version;

  final bool isSelf;

  final List<Query$EmployeeRecord$employee$employment> employment;

  final List<Query$EmployeeRecord$employee$assignments> assignments;

  final String $__typename;

  final String? status;

  final Query$EmployeeRecord$employee$login? login;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$userId = userId;
    _resultData['userId'] = l$userId;
    final l$allowedActions = allowedActions;
    _resultData['allowedActions'] = l$allowedActions.map((e) => e).toList();
    final l$permittedFields = permittedFields;
    _resultData['permittedFields'] = l$permittedFields.map((e) => e).toList();
    final l$salary = salary;
    _resultData['salary'] = l$salary;
    final l$bank = bank;
    _resultData['bank'] = l$bank;
    final l$identity = identity;
    _resultData['identity'] = l$identity;
    final l$id = id;
    _resultData['id'] = l$id;
    final l$employeeCode = employeeCode;
    _resultData['employeeCode'] = l$employeeCode;
    final l$displayName = displayName;
    _resultData['displayName'] = l$displayName;
    final l$workEmail = workEmail;
    _resultData['workEmail'] = l$workEmail;
    final l$phone = phone;
    _resultData['phone'] = l$phone;
    final l$personal = personal;
    _resultData['personal'] = l$personal?.toJson();
    final l$photoUpdatedAt = photoUpdatedAt;
    _resultData['photoUpdatedAt'] = l$photoUpdatedAt;
    final l$jobTitle = jobTitle;
    _resultData['jobTitle'] = l$jobTitle;
    final l$department = department;
    _resultData['department'] = l$department;
    final l$version = version;
    _resultData['version'] = l$version;
    final l$isSelf = isSelf;
    _resultData['isSelf'] = l$isSelf;
    final l$employment = employment;
    _resultData['employment'] = l$employment.map((e) => e.toJson()).toList();
    final l$assignments = assignments;
    _resultData['assignments'] = l$assignments.map((e) => e.toJson()).toList();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    final l$status = status;
    _resultData['status'] = l$status;
    final l$login = login;
    _resultData['login'] = l$login?.toJson();
    return _resultData;
  }

  @override
  int get hashCode {
    final l$userId = userId;
    final l$allowedActions = allowedActions;
    final l$permittedFields = permittedFields;
    final l$salary = salary;
    final l$bank = bank;
    final l$identity = identity;
    final l$id = id;
    final l$employeeCode = employeeCode;
    final l$displayName = displayName;
    final l$workEmail = workEmail;
    final l$phone = phone;
    final l$personal = personal;
    final l$photoUpdatedAt = photoUpdatedAt;
    final l$jobTitle = jobTitle;
    final l$department = department;
    final l$version = version;
    final l$isSelf = isSelf;
    final l$employment = employment;
    final l$assignments = assignments;
    final l$$__typename = $__typename;
    final l$status = status;
    final l$login = login;
    return Object.hashAll([
      l$userId,
      Object.hashAll(l$allowedActions.map((v) => v)),
      Object.hashAll(l$permittedFields.map((v) => v)),
      l$salary,
      l$bank,
      l$identity,
      l$id,
      l$employeeCode,
      l$displayName,
      l$workEmail,
      l$phone,
      l$personal,
      l$photoUpdatedAt,
      l$jobTitle,
      l$department,
      l$version,
      l$isSelf,
      Object.hashAll(l$employment.map((v) => v)),
      Object.hashAll(l$assignments.map((v) => v)),
      l$$__typename,
      l$status,
      l$login,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$EmployeeRecord$employee ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$userId = userId;
    final lOther$userId = other.userId;
    if (l$userId != lOther$userId) {
      return false;
    }
    final l$allowedActions = allowedActions;
    final lOther$allowedActions = other.allowedActions;
    if (l$allowedActions.length != lOther$allowedActions.length) {
      return false;
    }
    for (int i = 0; i < l$allowedActions.length; i++) {
      final l$allowedActions$entry = l$allowedActions[i];
      final lOther$allowedActions$entry = lOther$allowedActions[i];
      if (l$allowedActions$entry != lOther$allowedActions$entry) {
        return false;
      }
    }
    final l$permittedFields = permittedFields;
    final lOther$permittedFields = other.permittedFields;
    if (l$permittedFields.length != lOther$permittedFields.length) {
      return false;
    }
    for (int i = 0; i < l$permittedFields.length; i++) {
      final l$permittedFields$entry = l$permittedFields[i];
      final lOther$permittedFields$entry = lOther$permittedFields[i];
      if (l$permittedFields$entry != lOther$permittedFields$entry) {
        return false;
      }
    }
    final l$salary = salary;
    final lOther$salary = other.salary;
    if (l$salary != lOther$salary) {
      return false;
    }
    final l$bank = bank;
    final lOther$bank = other.bank;
    if (l$bank != lOther$bank) {
      return false;
    }
    final l$identity = identity;
    final lOther$identity = other.identity;
    if (l$identity != lOther$identity) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$employeeCode = employeeCode;
    final lOther$employeeCode = other.employeeCode;
    if (l$employeeCode != lOther$employeeCode) {
      return false;
    }
    final l$displayName = displayName;
    final lOther$displayName = other.displayName;
    if (l$displayName != lOther$displayName) {
      return false;
    }
    final l$workEmail = workEmail;
    final lOther$workEmail = other.workEmail;
    if (l$workEmail != lOther$workEmail) {
      return false;
    }
    final l$phone = phone;
    final lOther$phone = other.phone;
    if (l$phone != lOther$phone) {
      return false;
    }
    final l$personal = personal;
    final lOther$personal = other.personal;
    if (l$personal != lOther$personal) {
      return false;
    }
    final l$photoUpdatedAt = photoUpdatedAt;
    final lOther$photoUpdatedAt = other.photoUpdatedAt;
    if (l$photoUpdatedAt != lOther$photoUpdatedAt) {
      return false;
    }
    final l$jobTitle = jobTitle;
    final lOther$jobTitle = other.jobTitle;
    if (l$jobTitle != lOther$jobTitle) {
      return false;
    }
    final l$department = department;
    final lOther$department = other.department;
    if (l$department != lOther$department) {
      return false;
    }
    final l$version = version;
    final lOther$version = other.version;
    if (l$version != lOther$version) {
      return false;
    }
    final l$isSelf = isSelf;
    final lOther$isSelf = other.isSelf;
    if (l$isSelf != lOther$isSelf) {
      return false;
    }
    final l$employment = employment;
    final lOther$employment = other.employment;
    if (l$employment.length != lOther$employment.length) {
      return false;
    }
    for (int i = 0; i < l$employment.length; i++) {
      final l$employment$entry = l$employment[i];
      final lOther$employment$entry = lOther$employment[i];
      if (l$employment$entry != lOther$employment$entry) {
        return false;
      }
    }
    final l$assignments = assignments;
    final lOther$assignments = other.assignments;
    if (l$assignments.length != lOther$assignments.length) {
      return false;
    }
    for (int i = 0; i < l$assignments.length; i++) {
      final l$assignments$entry = l$assignments[i];
      final lOther$assignments$entry = lOther$assignments[i];
      if (l$assignments$entry != lOther$assignments$entry) {
        return false;
      }
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    final l$status = status;
    final lOther$status = other.status;
    if (l$status != lOther$status) {
      return false;
    }
    final l$login = login;
    final lOther$login = other.login;
    if (l$login != lOther$login) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$EmployeeRecord$employee
    on Query$EmployeeRecord$employee {
  CopyWith$Query$EmployeeRecord$employee<Query$EmployeeRecord$employee>
  get copyWith => CopyWith$Query$EmployeeRecord$employee(this, (i) => i);
}

abstract class CopyWith$Query$EmployeeRecord$employee<TRes> {
  factory CopyWith$Query$EmployeeRecord$employee(
    Query$EmployeeRecord$employee instance,
    TRes Function(Query$EmployeeRecord$employee) then,
  ) = _CopyWithImpl$Query$EmployeeRecord$employee;

  factory CopyWith$Query$EmployeeRecord$employee.stub(TRes res) =
      _CopyWithStubImpl$Query$EmployeeRecord$employee;

  TRes call({
    String? userId,
    List<String>? allowedActions,
    List<String>? permittedFields,
    String? salary,
    String? bank,
    String? identity,
    String? id,
    String? employeeCode,
    String? displayName,
    String? workEmail,
    String? phone,
    Fragment$PersonalFields? personal,
    String? photoUpdatedAt,
    String? jobTitle,
    String? department,
    int? version,
    bool? isSelf,
    List<Query$EmployeeRecord$employee$employment>? employment,
    List<Query$EmployeeRecord$employee$assignments>? assignments,
    String? $__typename,
    String? status,
    Query$EmployeeRecord$employee$login? login,
  });
  CopyWith$Fragment$PersonalFields<TRes> get personal;
  TRes employment(
    Iterable<Query$EmployeeRecord$employee$employment> Function(
      Iterable<
        CopyWith$Query$EmployeeRecord$employee$employment<
          Query$EmployeeRecord$employee$employment
        >
      >,
    )
    _fn,
  );
  TRes assignments(
    Iterable<Query$EmployeeRecord$employee$assignments> Function(
      Iterable<
        CopyWith$Query$EmployeeRecord$employee$assignments<
          Query$EmployeeRecord$employee$assignments
        >
      >,
    )
    _fn,
  );
  CopyWith$Query$EmployeeRecord$employee$login<TRes> get login;
}

class _CopyWithImpl$Query$EmployeeRecord$employee<TRes>
    implements CopyWith$Query$EmployeeRecord$employee<TRes> {
  _CopyWithImpl$Query$EmployeeRecord$employee(this._instance, this._then);

  final Query$EmployeeRecord$employee _instance;

  final TRes Function(Query$EmployeeRecord$employee) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? userId = _undefined,
    Object? allowedActions = _undefined,
    Object? permittedFields = _undefined,
    Object? salary = _undefined,
    Object? bank = _undefined,
    Object? identity = _undefined,
    Object? id = _undefined,
    Object? employeeCode = _undefined,
    Object? displayName = _undefined,
    Object? workEmail = _undefined,
    Object? phone = _undefined,
    Object? personal = _undefined,
    Object? photoUpdatedAt = _undefined,
    Object? jobTitle = _undefined,
    Object? department = _undefined,
    Object? version = _undefined,
    Object? isSelf = _undefined,
    Object? employment = _undefined,
    Object? assignments = _undefined,
    Object? $__typename = _undefined,
    Object? status = _undefined,
    Object? login = _undefined,
  }) => _then(
    Query$EmployeeRecord$employee(
      userId: userId == _undefined ? _instance.userId : (userId as String?),
      allowedActions: allowedActions == _undefined || allowedActions == null
          ? _instance.allowedActions
          : (allowedActions as List<String>),
      permittedFields: permittedFields == _undefined || permittedFields == null
          ? _instance.permittedFields
          : (permittedFields as List<String>),
      salary: salary == _undefined ? _instance.salary : (salary as String?),
      bank: bank == _undefined ? _instance.bank : (bank as String?),
      identity: identity == _undefined
          ? _instance.identity
          : (identity as String?),
      id: id == _undefined || id == null ? _instance.id : (id as String),
      employeeCode: employeeCode == _undefined || employeeCode == null
          ? _instance.employeeCode
          : (employeeCode as String),
      displayName: displayName == _undefined || displayName == null
          ? _instance.displayName
          : (displayName as String),
      workEmail: workEmail == _undefined
          ? _instance.workEmail
          : (workEmail as String?),
      phone: phone == _undefined ? _instance.phone : (phone as String?),
      personal: personal == _undefined
          ? _instance.personal
          : (personal as Fragment$PersonalFields?),
      photoUpdatedAt: photoUpdatedAt == _undefined
          ? _instance.photoUpdatedAt
          : (photoUpdatedAt as String?),
      jobTitle: jobTitle == _undefined
          ? _instance.jobTitle
          : (jobTitle as String?),
      department: department == _undefined
          ? _instance.department
          : (department as String?),
      version: version == _undefined || version == null
          ? _instance.version
          : (version as int),
      isSelf: isSelf == _undefined || isSelf == null
          ? _instance.isSelf
          : (isSelf as bool),
      employment: employment == _undefined || employment == null
          ? _instance.employment
          : (employment as List<Query$EmployeeRecord$employee$employment>),
      assignments: assignments == _undefined || assignments == null
          ? _instance.assignments
          : (assignments as List<Query$EmployeeRecord$employee$assignments>),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
      status: status == _undefined ? _instance.status : (status as String?),
      login: login == _undefined
          ? _instance.login
          : (login as Query$EmployeeRecord$employee$login?),
    ),
  );

  CopyWith$Fragment$PersonalFields<TRes> get personal {
    final local$personal = _instance.personal;
    return local$personal == null
        ? CopyWith$Fragment$PersonalFields.stub(_then(_instance))
        : CopyWith$Fragment$PersonalFields(
            local$personal,
            (e) => call(personal: e),
          );
  }

  TRes employment(
    Iterable<Query$EmployeeRecord$employee$employment> Function(
      Iterable<
        CopyWith$Query$EmployeeRecord$employee$employment<
          Query$EmployeeRecord$employee$employment
        >
      >,
    )
    _fn,
  ) => call(
    employment: _fn(
      _instance.employment.map(
        (e) => CopyWith$Query$EmployeeRecord$employee$employment(e, (i) => i),
      ),
    ).toList(),
  );

  TRes assignments(
    Iterable<Query$EmployeeRecord$employee$assignments> Function(
      Iterable<
        CopyWith$Query$EmployeeRecord$employee$assignments<
          Query$EmployeeRecord$employee$assignments
        >
      >,
    )
    _fn,
  ) => call(
    assignments: _fn(
      _instance.assignments.map(
        (e) => CopyWith$Query$EmployeeRecord$employee$assignments(e, (i) => i),
      ),
    ).toList(),
  );

  CopyWith$Query$EmployeeRecord$employee$login<TRes> get login {
    final local$login = _instance.login;
    return local$login == null
        ? CopyWith$Query$EmployeeRecord$employee$login.stub(_then(_instance))
        : CopyWith$Query$EmployeeRecord$employee$login(
            local$login,
            (e) => call(login: e),
          );
  }
}

class _CopyWithStubImpl$Query$EmployeeRecord$employee<TRes>
    implements CopyWith$Query$EmployeeRecord$employee<TRes> {
  _CopyWithStubImpl$Query$EmployeeRecord$employee(this._res);

  TRes _res;

  call({
    String? userId,
    List<String>? allowedActions,
    List<String>? permittedFields,
    String? salary,
    String? bank,
    String? identity,
    String? id,
    String? employeeCode,
    String? displayName,
    String? workEmail,
    String? phone,
    Fragment$PersonalFields? personal,
    String? photoUpdatedAt,
    String? jobTitle,
    String? department,
    int? version,
    bool? isSelf,
    List<Query$EmployeeRecord$employee$employment>? employment,
    List<Query$EmployeeRecord$employee$assignments>? assignments,
    String? $__typename,
    String? status,
    Query$EmployeeRecord$employee$login? login,
  }) => _res;

  CopyWith$Fragment$PersonalFields<TRes> get personal =>
      CopyWith$Fragment$PersonalFields.stub(_res);

  employment(_fn) => _res;

  assignments(_fn) => _res;

  CopyWith$Query$EmployeeRecord$employee$login<TRes> get login =>
      CopyWith$Query$EmployeeRecord$employee$login.stub(_res);
}

class Query$EmployeeRecord$employee$employment
    implements Fragment$EmployeeFields$employment {
  Query$EmployeeRecord$employee$employment({
    required this.id,
    required this.startsOn,
    this.endsOn,
    required this.legalEmployer,
    this.$__typename = 'Employment',
  });

  factory Query$EmployeeRecord$employee$employment.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$id = json['id'];
    final l$startsOn = json['startsOn'];
    final l$endsOn = json['endsOn'];
    final l$legalEmployer = json['legalEmployer'];
    final l$$__typename = json['__typename'];
    return Query$EmployeeRecord$employee$employment(
      id: (l$id as String),
      startsOn: (l$startsOn as String),
      endsOn: (l$endsOn as String?),
      legalEmployer:
          Query$EmployeeRecord$employee$employment$legalEmployer.fromJson(
            (l$legalEmployer as Map<String, dynamic>),
          ),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String startsOn;

  final String? endsOn;

  final Query$EmployeeRecord$employee$employment$legalEmployer legalEmployer;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$startsOn = startsOn;
    _resultData['startsOn'] = l$startsOn;
    final l$endsOn = endsOn;
    _resultData['endsOn'] = l$endsOn;
    final l$legalEmployer = legalEmployer;
    _resultData['legalEmployer'] = l$legalEmployer.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$startsOn = startsOn;
    final l$endsOn = endsOn;
    final l$legalEmployer = legalEmployer;
    final l$$__typename = $__typename;
    return Object.hashAll([
      l$id,
      l$startsOn,
      l$endsOn,
      l$legalEmployer,
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$EmployeeRecord$employee$employment ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$startsOn = startsOn;
    final lOther$startsOn = other.startsOn;
    if (l$startsOn != lOther$startsOn) {
      return false;
    }
    final l$endsOn = endsOn;
    final lOther$endsOn = other.endsOn;
    if (l$endsOn != lOther$endsOn) {
      return false;
    }
    final l$legalEmployer = legalEmployer;
    final lOther$legalEmployer = other.legalEmployer;
    if (l$legalEmployer != lOther$legalEmployer) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$EmployeeRecord$employee$employment
    on Query$EmployeeRecord$employee$employment {
  CopyWith$Query$EmployeeRecord$employee$employment<
    Query$EmployeeRecord$employee$employment
  >
  get copyWith =>
      CopyWith$Query$EmployeeRecord$employee$employment(this, (i) => i);
}

abstract class CopyWith$Query$EmployeeRecord$employee$employment<TRes> {
  factory CopyWith$Query$EmployeeRecord$employee$employment(
    Query$EmployeeRecord$employee$employment instance,
    TRes Function(Query$EmployeeRecord$employee$employment) then,
  ) = _CopyWithImpl$Query$EmployeeRecord$employee$employment;

  factory CopyWith$Query$EmployeeRecord$employee$employment.stub(TRes res) =
      _CopyWithStubImpl$Query$EmployeeRecord$employee$employment;

  TRes call({
    String? id,
    String? startsOn,
    String? endsOn,
    Query$EmployeeRecord$employee$employment$legalEmployer? legalEmployer,
    String? $__typename,
  });
  CopyWith$Query$EmployeeRecord$employee$employment$legalEmployer<TRes>
  get legalEmployer;
}

class _CopyWithImpl$Query$EmployeeRecord$employee$employment<TRes>
    implements CopyWith$Query$EmployeeRecord$employee$employment<TRes> {
  _CopyWithImpl$Query$EmployeeRecord$employee$employment(
    this._instance,
    this._then,
  );

  final Query$EmployeeRecord$employee$employment _instance;

  final TRes Function(Query$EmployeeRecord$employee$employment) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? startsOn = _undefined,
    Object? endsOn = _undefined,
    Object? legalEmployer = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$EmployeeRecord$employee$employment(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      startsOn: startsOn == _undefined || startsOn == null
          ? _instance.startsOn
          : (startsOn as String),
      endsOn: endsOn == _undefined ? _instance.endsOn : (endsOn as String?),
      legalEmployer: legalEmployer == _undefined || legalEmployer == null
          ? _instance.legalEmployer
          : (legalEmployer
                as Query$EmployeeRecord$employee$employment$legalEmployer),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Query$EmployeeRecord$employee$employment$legalEmployer<TRes>
  get legalEmployer {
    final local$legalEmployer = _instance.legalEmployer;
    return CopyWith$Query$EmployeeRecord$employee$employment$legalEmployer(
      local$legalEmployer,
      (e) => call(legalEmployer: e),
    );
  }
}

class _CopyWithStubImpl$Query$EmployeeRecord$employee$employment<TRes>
    implements CopyWith$Query$EmployeeRecord$employee$employment<TRes> {
  _CopyWithStubImpl$Query$EmployeeRecord$employee$employment(this._res);

  TRes _res;

  call({
    String? id,
    String? startsOn,
    String? endsOn,
    Query$EmployeeRecord$employee$employment$legalEmployer? legalEmployer,
    String? $__typename,
  }) => _res;

  CopyWith$Query$EmployeeRecord$employee$employment$legalEmployer<TRes>
  get legalEmployer =>
      CopyWith$Query$EmployeeRecord$employee$employment$legalEmployer.stub(
        _res,
      );
}

class Query$EmployeeRecord$employee$employment$legalEmployer
    implements Fragment$EmployeeFields$employment$legalEmployer {
  Query$EmployeeRecord$employee$employment$legalEmployer({
    required this.id,
    required this.name,
    this.$__typename = 'LegalEmployer',
  });

  factory Query$EmployeeRecord$employee$employment$legalEmployer.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$id = json['id'];
    final l$name = json['name'];
    final l$$__typename = json['__typename'];
    return Query$EmployeeRecord$employee$employment$legalEmployer(
      id: (l$id as String),
      name: (l$name as String),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String name;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$name = name;
    _resultData['name'] = l$name;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$name = name;
    final l$$__typename = $__typename;
    return Object.hashAll([l$id, l$name, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$EmployeeRecord$employee$employment$legalEmployer ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$name = name;
    final lOther$name = other.name;
    if (l$name != lOther$name) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$EmployeeRecord$employee$employment$legalEmployer
    on Query$EmployeeRecord$employee$employment$legalEmployer {
  CopyWith$Query$EmployeeRecord$employee$employment$legalEmployer<
    Query$EmployeeRecord$employee$employment$legalEmployer
  >
  get copyWith =>
      CopyWith$Query$EmployeeRecord$employee$employment$legalEmployer(
        this,
        (i) => i,
      );
}

abstract class CopyWith$Query$EmployeeRecord$employee$employment$legalEmployer<
  TRes
> {
  factory CopyWith$Query$EmployeeRecord$employee$employment$legalEmployer(
    Query$EmployeeRecord$employee$employment$legalEmployer instance,
    TRes Function(Query$EmployeeRecord$employee$employment$legalEmployer) then,
  ) = _CopyWithImpl$Query$EmployeeRecord$employee$employment$legalEmployer;

  factory CopyWith$Query$EmployeeRecord$employee$employment$legalEmployer.stub(
    TRes res,
  ) = _CopyWithStubImpl$Query$EmployeeRecord$employee$employment$legalEmployer;

  TRes call({String? id, String? name, String? $__typename});
}

class _CopyWithImpl$Query$EmployeeRecord$employee$employment$legalEmployer<TRes>
    implements
        CopyWith$Query$EmployeeRecord$employee$employment$legalEmployer<TRes> {
  _CopyWithImpl$Query$EmployeeRecord$employee$employment$legalEmployer(
    this._instance,
    this._then,
  );

  final Query$EmployeeRecord$employee$employment$legalEmployer _instance;

  final TRes Function(Query$EmployeeRecord$employee$employment$legalEmployer)
  _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? name = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$EmployeeRecord$employee$employment$legalEmployer(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      name: name == _undefined || name == null
          ? _instance.name
          : (name as String),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$EmployeeRecord$employee$employment$legalEmployer<
  TRes
>
    implements
        CopyWith$Query$EmployeeRecord$employee$employment$legalEmployer<TRes> {
  _CopyWithStubImpl$Query$EmployeeRecord$employee$employment$legalEmployer(
    this._res,
  );

  TRes _res;

  call({String? id, String? name, String? $__typename}) => _res;
}

class Query$EmployeeRecord$employee$assignments
    implements Fragment$EmployeeFields$assignments {
  Query$EmployeeRecord$employee$assignments({
    required this.id,
    required this.startsOn,
    this.endsOn,
    required this.site,
    this.$__typename = 'SiteAssignment',
  });

  factory Query$EmployeeRecord$employee$assignments.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$id = json['id'];
    final l$startsOn = json['startsOn'];
    final l$endsOn = json['endsOn'];
    final l$site = json['site'];
    final l$$__typename = json['__typename'];
    return Query$EmployeeRecord$employee$assignments(
      id: (l$id as String),
      startsOn: (l$startsOn as String),
      endsOn: (l$endsOn as String?),
      site: Query$EmployeeRecord$employee$assignments$site.fromJson(
        (l$site as Map<String, dynamic>),
      ),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String startsOn;

  final String? endsOn;

  final Query$EmployeeRecord$employee$assignments$site site;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$startsOn = startsOn;
    _resultData['startsOn'] = l$startsOn;
    final l$endsOn = endsOn;
    _resultData['endsOn'] = l$endsOn;
    final l$site = site;
    _resultData['site'] = l$site.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$startsOn = startsOn;
    final l$endsOn = endsOn;
    final l$site = site;
    final l$$__typename = $__typename;
    return Object.hashAll([l$id, l$startsOn, l$endsOn, l$site, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$EmployeeRecord$employee$assignments ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$startsOn = startsOn;
    final lOther$startsOn = other.startsOn;
    if (l$startsOn != lOther$startsOn) {
      return false;
    }
    final l$endsOn = endsOn;
    final lOther$endsOn = other.endsOn;
    if (l$endsOn != lOther$endsOn) {
      return false;
    }
    final l$site = site;
    final lOther$site = other.site;
    if (l$site != lOther$site) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$EmployeeRecord$employee$assignments
    on Query$EmployeeRecord$employee$assignments {
  CopyWith$Query$EmployeeRecord$employee$assignments<
    Query$EmployeeRecord$employee$assignments
  >
  get copyWith =>
      CopyWith$Query$EmployeeRecord$employee$assignments(this, (i) => i);
}

abstract class CopyWith$Query$EmployeeRecord$employee$assignments<TRes> {
  factory CopyWith$Query$EmployeeRecord$employee$assignments(
    Query$EmployeeRecord$employee$assignments instance,
    TRes Function(Query$EmployeeRecord$employee$assignments) then,
  ) = _CopyWithImpl$Query$EmployeeRecord$employee$assignments;

  factory CopyWith$Query$EmployeeRecord$employee$assignments.stub(TRes res) =
      _CopyWithStubImpl$Query$EmployeeRecord$employee$assignments;

  TRes call({
    String? id,
    String? startsOn,
    String? endsOn,
    Query$EmployeeRecord$employee$assignments$site? site,
    String? $__typename,
  });
  CopyWith$Query$EmployeeRecord$employee$assignments$site<TRes> get site;
}

class _CopyWithImpl$Query$EmployeeRecord$employee$assignments<TRes>
    implements CopyWith$Query$EmployeeRecord$employee$assignments<TRes> {
  _CopyWithImpl$Query$EmployeeRecord$employee$assignments(
    this._instance,
    this._then,
  );

  final Query$EmployeeRecord$employee$assignments _instance;

  final TRes Function(Query$EmployeeRecord$employee$assignments) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? startsOn = _undefined,
    Object? endsOn = _undefined,
    Object? site = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$EmployeeRecord$employee$assignments(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      startsOn: startsOn == _undefined || startsOn == null
          ? _instance.startsOn
          : (startsOn as String),
      endsOn: endsOn == _undefined ? _instance.endsOn : (endsOn as String?),
      site: site == _undefined || site == null
          ? _instance.site
          : (site as Query$EmployeeRecord$employee$assignments$site),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Query$EmployeeRecord$employee$assignments$site<TRes> get site {
    final local$site = _instance.site;
    return CopyWith$Query$EmployeeRecord$employee$assignments$site(
      local$site,
      (e) => call(site: e),
    );
  }
}

class _CopyWithStubImpl$Query$EmployeeRecord$employee$assignments<TRes>
    implements CopyWith$Query$EmployeeRecord$employee$assignments<TRes> {
  _CopyWithStubImpl$Query$EmployeeRecord$employee$assignments(this._res);

  TRes _res;

  call({
    String? id,
    String? startsOn,
    String? endsOn,
    Query$EmployeeRecord$employee$assignments$site? site,
    String? $__typename,
  }) => _res;

  CopyWith$Query$EmployeeRecord$employee$assignments$site<TRes> get site =>
      CopyWith$Query$EmployeeRecord$employee$assignments$site.stub(_res);
}

class Query$EmployeeRecord$employee$assignments$site
    implements Fragment$EmployeeFields$assignments$site {
  Query$EmployeeRecord$employee$assignments$site({
    required this.id,
    required this.name,
    required this.timezone,
    this.$__typename = 'Site',
  });

  factory Query$EmployeeRecord$employee$assignments$site.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$id = json['id'];
    final l$name = json['name'];
    final l$timezone = json['timezone'];
    final l$$__typename = json['__typename'];
    return Query$EmployeeRecord$employee$assignments$site(
      id: (l$id as String),
      name: (l$name as String),
      timezone: (l$timezone as String),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String name;

  final String timezone;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$name = name;
    _resultData['name'] = l$name;
    final l$timezone = timezone;
    _resultData['timezone'] = l$timezone;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$name = name;
    final l$timezone = timezone;
    final l$$__typename = $__typename;
    return Object.hashAll([l$id, l$name, l$timezone, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$EmployeeRecord$employee$assignments$site ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$name = name;
    final lOther$name = other.name;
    if (l$name != lOther$name) {
      return false;
    }
    final l$timezone = timezone;
    final lOther$timezone = other.timezone;
    if (l$timezone != lOther$timezone) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$EmployeeRecord$employee$assignments$site
    on Query$EmployeeRecord$employee$assignments$site {
  CopyWith$Query$EmployeeRecord$employee$assignments$site<
    Query$EmployeeRecord$employee$assignments$site
  >
  get copyWith =>
      CopyWith$Query$EmployeeRecord$employee$assignments$site(this, (i) => i);
}

abstract class CopyWith$Query$EmployeeRecord$employee$assignments$site<TRes> {
  factory CopyWith$Query$EmployeeRecord$employee$assignments$site(
    Query$EmployeeRecord$employee$assignments$site instance,
    TRes Function(Query$EmployeeRecord$employee$assignments$site) then,
  ) = _CopyWithImpl$Query$EmployeeRecord$employee$assignments$site;

  factory CopyWith$Query$EmployeeRecord$employee$assignments$site.stub(
    TRes res,
  ) = _CopyWithStubImpl$Query$EmployeeRecord$employee$assignments$site;

  TRes call({String? id, String? name, String? timezone, String? $__typename});
}

class _CopyWithImpl$Query$EmployeeRecord$employee$assignments$site<TRes>
    implements CopyWith$Query$EmployeeRecord$employee$assignments$site<TRes> {
  _CopyWithImpl$Query$EmployeeRecord$employee$assignments$site(
    this._instance,
    this._then,
  );

  final Query$EmployeeRecord$employee$assignments$site _instance;

  final TRes Function(Query$EmployeeRecord$employee$assignments$site) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? name = _undefined,
    Object? timezone = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$EmployeeRecord$employee$assignments$site(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      name: name == _undefined || name == null
          ? _instance.name
          : (name as String),
      timezone: timezone == _undefined || timezone == null
          ? _instance.timezone
          : (timezone as String),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$EmployeeRecord$employee$assignments$site<TRes>
    implements CopyWith$Query$EmployeeRecord$employee$assignments$site<TRes> {
  _CopyWithStubImpl$Query$EmployeeRecord$employee$assignments$site(this._res);

  TRes _res;

  call({String? id, String? name, String? timezone, String? $__typename}) =>
      _res;
}

class Query$EmployeeRecord$employee$login
    implements Fragment$EmployeeAdminFields$login {
  Query$EmployeeRecord$employee$login({
    required this.status,
    this.loginId,
    this.lastSignInAt,
    required this.devices,
    required this.protected,
    this.$__typename = 'EmployeeLogin',
  });

  factory Query$EmployeeRecord$employee$login.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$status = json['status'];
    final l$loginId = json['loginId'];
    final l$lastSignInAt = json['lastSignInAt'];
    final l$devices = json['devices'];
    final l$protected = json['protected'];
    final l$$__typename = json['__typename'];
    return Query$EmployeeRecord$employee$login(
      status: (l$status as String),
      loginId: (l$loginId as String?),
      lastSignInAt: (l$lastSignInAt as String?),
      devices: (l$devices as int),
      protected: (l$protected as bool),
      $__typename: (l$$__typename as String),
    );
  }

  final String status;

  final String? loginId;

  final String? lastSignInAt;

  final int devices;

  final bool protected;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$status = status;
    _resultData['status'] = l$status;
    final l$loginId = loginId;
    _resultData['loginId'] = l$loginId;
    final l$lastSignInAt = lastSignInAt;
    _resultData['lastSignInAt'] = l$lastSignInAt;
    final l$devices = devices;
    _resultData['devices'] = l$devices;
    final l$protected = protected;
    _resultData['protected'] = l$protected;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$status = status;
    final l$loginId = loginId;
    final l$lastSignInAt = lastSignInAt;
    final l$devices = devices;
    final l$protected = protected;
    final l$$__typename = $__typename;
    return Object.hashAll([
      l$status,
      l$loginId,
      l$lastSignInAt,
      l$devices,
      l$protected,
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$EmployeeRecord$employee$login ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$status = status;
    final lOther$status = other.status;
    if (l$status != lOther$status) {
      return false;
    }
    final l$loginId = loginId;
    final lOther$loginId = other.loginId;
    if (l$loginId != lOther$loginId) {
      return false;
    }
    final l$lastSignInAt = lastSignInAt;
    final lOther$lastSignInAt = other.lastSignInAt;
    if (l$lastSignInAt != lOther$lastSignInAt) {
      return false;
    }
    final l$devices = devices;
    final lOther$devices = other.devices;
    if (l$devices != lOther$devices) {
      return false;
    }
    final l$protected = protected;
    final lOther$protected = other.protected;
    if (l$protected != lOther$protected) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$EmployeeRecord$employee$login
    on Query$EmployeeRecord$employee$login {
  CopyWith$Query$EmployeeRecord$employee$login<
    Query$EmployeeRecord$employee$login
  >
  get copyWith => CopyWith$Query$EmployeeRecord$employee$login(this, (i) => i);
}

abstract class CopyWith$Query$EmployeeRecord$employee$login<TRes> {
  factory CopyWith$Query$EmployeeRecord$employee$login(
    Query$EmployeeRecord$employee$login instance,
    TRes Function(Query$EmployeeRecord$employee$login) then,
  ) = _CopyWithImpl$Query$EmployeeRecord$employee$login;

  factory CopyWith$Query$EmployeeRecord$employee$login.stub(TRes res) =
      _CopyWithStubImpl$Query$EmployeeRecord$employee$login;

  TRes call({
    String? status,
    String? loginId,
    String? lastSignInAt,
    int? devices,
    bool? protected,
    String? $__typename,
  });
}

class _CopyWithImpl$Query$EmployeeRecord$employee$login<TRes>
    implements CopyWith$Query$EmployeeRecord$employee$login<TRes> {
  _CopyWithImpl$Query$EmployeeRecord$employee$login(this._instance, this._then);

  final Query$EmployeeRecord$employee$login _instance;

  final TRes Function(Query$EmployeeRecord$employee$login) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? status = _undefined,
    Object? loginId = _undefined,
    Object? lastSignInAt = _undefined,
    Object? devices = _undefined,
    Object? protected = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$EmployeeRecord$employee$login(
      status: status == _undefined || status == null
          ? _instance.status
          : (status as String),
      loginId: loginId == _undefined ? _instance.loginId : (loginId as String?),
      lastSignInAt: lastSignInAt == _undefined
          ? _instance.lastSignInAt
          : (lastSignInAt as String?),
      devices: devices == _undefined || devices == null
          ? _instance.devices
          : (devices as int),
      protected: protected == _undefined || protected == null
          ? _instance.protected
          : (protected as bool),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$EmployeeRecord$employee$login<TRes>
    implements CopyWith$Query$EmployeeRecord$employee$login<TRes> {
  _CopyWithStubImpl$Query$EmployeeRecord$employee$login(this._res);

  TRes _res;

  call({
    String? status,
    String? loginId,
    String? lastSignInAt,
    int? devices,
    bool? protected,
    String? $__typename,
  }) => _res;
}

class Variables$Query$MyProfile {
  factory Variables$Query$MyProfile({required String siteId}) =>
      Variables$Query$MyProfile._({r'siteId': siteId});

  Variables$Query$MyProfile._(this._$data);

  factory Variables$Query$MyProfile.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    return Variables$Query$MyProfile._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    return result$data;
  }

  CopyWith$Variables$Query$MyProfile<Variables$Query$MyProfile> get copyWith =>
      CopyWith$Variables$Query$MyProfile(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$MyProfile ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    return Object.hashAll([l$siteId]);
  }
}

abstract class CopyWith$Variables$Query$MyProfile<TRes> {
  factory CopyWith$Variables$Query$MyProfile(
    Variables$Query$MyProfile instance,
    TRes Function(Variables$Query$MyProfile) then,
  ) = _CopyWithImpl$Variables$Query$MyProfile;

  factory CopyWith$Variables$Query$MyProfile.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$MyProfile;

  TRes call({String? siteId});
}

class _CopyWithImpl$Variables$Query$MyProfile<TRes>
    implements CopyWith$Variables$Query$MyProfile<TRes> {
  _CopyWithImpl$Variables$Query$MyProfile(this._instance, this._then);

  final Variables$Query$MyProfile _instance;

  final TRes Function(Variables$Query$MyProfile) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? siteId = _undefined}) => _then(
    Variables$Query$MyProfile._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
    }),
  );
}

class _CopyWithStubImpl$Variables$Query$MyProfile<TRes>
    implements CopyWith$Variables$Query$MyProfile<TRes> {
  _CopyWithStubImpl$Variables$Query$MyProfile(this._res);

  TRes _res;

  call({String? siteId}) => _res;
}

class Query$MyProfile {
  Query$MyProfile({this.myProfile, this.$__typename = 'Query'});

  factory Query$MyProfile.fromJson(Map<String, dynamic> json) {
    final l$myProfile = json['myProfile'];
    final l$$__typename = json['__typename'];
    return Query$MyProfile(
      myProfile: l$myProfile == null
          ? null
          : Fragment$EmployeeFields.fromJson(
              (l$myProfile as Map<String, dynamic>),
            ),
      $__typename: (l$$__typename as String),
    );
  }

  final Fragment$EmployeeFields? myProfile;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$myProfile = myProfile;
    _resultData['myProfile'] = l$myProfile?.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$myProfile = myProfile;
    final l$$__typename = $__typename;
    return Object.hashAll([l$myProfile, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$MyProfile || runtimeType != other.runtimeType) {
      return false;
    }
    final l$myProfile = myProfile;
    final lOther$myProfile = other.myProfile;
    if (l$myProfile != lOther$myProfile) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$MyProfile on Query$MyProfile {
  CopyWith$Query$MyProfile<Query$MyProfile> get copyWith =>
      CopyWith$Query$MyProfile(this, (i) => i);
}

abstract class CopyWith$Query$MyProfile<TRes> {
  factory CopyWith$Query$MyProfile(
    Query$MyProfile instance,
    TRes Function(Query$MyProfile) then,
  ) = _CopyWithImpl$Query$MyProfile;

  factory CopyWith$Query$MyProfile.stub(TRes res) =
      _CopyWithStubImpl$Query$MyProfile;

  TRes call({Fragment$EmployeeFields? myProfile, String? $__typename});
  CopyWith$Fragment$EmployeeFields<TRes> get myProfile;
}

class _CopyWithImpl$Query$MyProfile<TRes>
    implements CopyWith$Query$MyProfile<TRes> {
  _CopyWithImpl$Query$MyProfile(this._instance, this._then);

  final Query$MyProfile _instance;

  final TRes Function(Query$MyProfile) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? myProfile = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$MyProfile(
      myProfile: myProfile == _undefined
          ? _instance.myProfile
          : (myProfile as Fragment$EmployeeFields?),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Fragment$EmployeeFields<TRes> get myProfile {
    final local$myProfile = _instance.myProfile;
    return local$myProfile == null
        ? CopyWith$Fragment$EmployeeFields.stub(_then(_instance))
        : CopyWith$Fragment$EmployeeFields(
            local$myProfile,
            (e) => call(myProfile: e),
          );
  }
}

class _CopyWithStubImpl$Query$MyProfile<TRes>
    implements CopyWith$Query$MyProfile<TRes> {
  _CopyWithStubImpl$Query$MyProfile(this._res);

  TRes _res;

  call({Fragment$EmployeeFields? myProfile, String? $__typename}) => _res;

  CopyWith$Fragment$EmployeeFields<TRes> get myProfile =>
      CopyWith$Fragment$EmployeeFields.stub(_res);
}

const documentNodeQueryMyProfile = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'MyProfile'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'myProfile'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
            ],
            directives: [],
            selectionSet: SelectionSetNode(
              selections: [
                FragmentSpreadNode(
                  name: NameNode(value: 'EmployeeFields'),
                  directives: [],
                ),
                FieldNode(
                  name: NameNode(value: '__typename'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
              ],
            ),
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
    fragmentDefinitionEmployeeFields,
    fragmentDefinitionPersonalFields,
  ],
);
Query$MyProfile _parserFn$Query$MyProfile(Map<String, dynamic> data) =>
    Query$MyProfile.fromJson(data);
typedef OnQueryComplete$Query$MyProfile = FutureOr<void> Function(
  Map<String, dynamic>?,
  Query$MyProfile?,
);

class Options$Query$MyProfile extends graphql.QueryOptions<Query$MyProfile> {
  Options$Query$MyProfile({
    String? operationName,
    required Variables$Query$MyProfile variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$MyProfile? typedOptimisticResult,
    Duration? pollInterval,
    graphql.Context? context,
    OnQueryComplete$Query$MyProfile? onComplete,
    graphql.OnQueryError? onError,
  }) : onCompleteWithParsed = onComplete,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         pollInterval: pollInterval,
         context: context,
         onComplete: onComplete == null
             ? null
             : (data) => onComplete(
                 data,
                 data == null ? null : _parserFn$Query$MyProfile(data),
               ),
         onError: onError,
         document: documentNodeQueryMyProfile,
         parserFn: _parserFn$Query$MyProfile,
       );

  final OnQueryComplete$Query$MyProfile? onCompleteWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onComplete == null
        ? super.properties
        : super.properties.where((property) => property != onComplete),
    onCompleteWithParsed,
  ];
}

class WatchOptions$Query$MyProfile
    extends graphql.WatchQueryOptions<Query$MyProfile> {
  WatchOptions$Query$MyProfile({
    String? operationName,
    required Variables$Query$MyProfile variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$MyProfile? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeQueryMyProfile,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Query$MyProfile,
       );
}

class FetchMoreOptions$Query$MyProfile extends graphql.FetchMoreOptions {
  FetchMoreOptions$Query$MyProfile({
    required graphql.UpdateQuery updateQuery,
    required Variables$Query$MyProfile variables,
  }) : super(
         updateQuery: updateQuery,
         variables: variables.toJson(),
         document: documentNodeQueryMyProfile,
       );
}

extension ClientExtension$Query$MyProfile on graphql.GraphQLClient {
  Future<graphql.QueryResult<Query$MyProfile>> query$MyProfile(
    Options$Query$MyProfile options,
  ) async => await this.query(options);

  graphql.ObservableQuery<Query$MyProfile> watchQuery$MyProfile(
    WatchOptions$Query$MyProfile options,
  ) => this.watchQuery(options);

  void writeQuery$MyProfile({
    required Query$MyProfile data,
    required Variables$Query$MyProfile variables,
    bool broadcast = true,
  }) => this.writeQuery(
    graphql.Request(
      operation: graphql.Operation(document: documentNodeQueryMyProfile),
      variables: variables.toJson(),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Query$MyProfile? readQuery$MyProfile({
    required Variables$Query$MyProfile variables,
    bool optimistic = true,
  }) {
    final result = this.readQuery(
      graphql.Request(
        operation: graphql.Operation(document: documentNodeQueryMyProfile),
        variables: variables.toJson(),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Query$MyProfile.fromJson(result);
  }
}

class Variables$Mutation$UpdateProfile {
  factory Variables$Mutation$UpdateProfile({
    required String siteId,
    required Input$UpdateProfileInput input,
  }) =>
      Variables$Mutation$UpdateProfile._({r'siteId': siteId, r'input': input});

  Variables$Mutation$UpdateProfile._(this._$data);

  factory Variables$Mutation$UpdateProfile.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    final l$input = data['input'];
    result$data['input'] = Input$UpdateProfileInput.fromJson(
      (l$input as Map<String, dynamic>),
    );
    return Variables$Mutation$UpdateProfile._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  Input$UpdateProfileInput get input =>
      (_$data['input'] as Input$UpdateProfileInput);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    final l$input = input;
    result$data['input'] = l$input.toJson();
    return result$data;
  }

  CopyWith$Variables$Mutation$UpdateProfile<Variables$Mutation$UpdateProfile>
  get copyWith => CopyWith$Variables$Mutation$UpdateProfile(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Mutation$UpdateProfile ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    final l$input = input;
    final lOther$input = other.input;
    if (l$input != lOther$input) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    final l$input = input;
    return Object.hashAll([l$siteId, l$input]);
  }
}

abstract class CopyWith$Variables$Mutation$UpdateProfile<TRes> {
  factory CopyWith$Variables$Mutation$UpdateProfile(
    Variables$Mutation$UpdateProfile instance,
    TRes Function(Variables$Mutation$UpdateProfile) then,
  ) = _CopyWithImpl$Variables$Mutation$UpdateProfile;

  factory CopyWith$Variables$Mutation$UpdateProfile.stub(TRes res) =
      _CopyWithStubImpl$Variables$Mutation$UpdateProfile;

  TRes call({String? siteId, Input$UpdateProfileInput? input});
}

class _CopyWithImpl$Variables$Mutation$UpdateProfile<TRes>
    implements CopyWith$Variables$Mutation$UpdateProfile<TRes> {
  _CopyWithImpl$Variables$Mutation$UpdateProfile(this._instance, this._then);

  final Variables$Mutation$UpdateProfile _instance;

  final TRes Function(Variables$Mutation$UpdateProfile) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? siteId = _undefined, Object? input = _undefined}) => _then(
    Variables$Mutation$UpdateProfile._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
      if (input != _undefined && input != null)
        'input': (input as Input$UpdateProfileInput),
    }),
  );
}

class _CopyWithStubImpl$Variables$Mutation$UpdateProfile<TRes>
    implements CopyWith$Variables$Mutation$UpdateProfile<TRes> {
  _CopyWithStubImpl$Variables$Mutation$UpdateProfile(this._res);

  TRes _res;

  call({String? siteId, Input$UpdateProfileInput? input}) => _res;
}

class Mutation$UpdateProfile {
  Mutation$UpdateProfile({
    required this.updateProfile,
    this.$__typename = 'Mutation',
  });

  factory Mutation$UpdateProfile.fromJson(Map<String, dynamic> json) {
    final l$updateProfile = json['updateProfile'];
    final l$$__typename = json['__typename'];
    return Mutation$UpdateProfile(
      updateProfile: Fragment$EmployeeFields.fromJson(
        (l$updateProfile as Map<String, dynamic>),
      ),
      $__typename: (l$$__typename as String),
    );
  }

  final Fragment$EmployeeFields updateProfile;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$updateProfile = updateProfile;
    _resultData['updateProfile'] = l$updateProfile.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$updateProfile = updateProfile;
    final l$$__typename = $__typename;
    return Object.hashAll([l$updateProfile, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Mutation$UpdateProfile || runtimeType != other.runtimeType) {
      return false;
    }
    final l$updateProfile = updateProfile;
    final lOther$updateProfile = other.updateProfile;
    if (l$updateProfile != lOther$updateProfile) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Mutation$UpdateProfile on Mutation$UpdateProfile {
  CopyWith$Mutation$UpdateProfile<Mutation$UpdateProfile> get copyWith =>
      CopyWith$Mutation$UpdateProfile(this, (i) => i);
}

abstract class CopyWith$Mutation$UpdateProfile<TRes> {
  factory CopyWith$Mutation$UpdateProfile(
    Mutation$UpdateProfile instance,
    TRes Function(Mutation$UpdateProfile) then,
  ) = _CopyWithImpl$Mutation$UpdateProfile;

  factory CopyWith$Mutation$UpdateProfile.stub(TRes res) =
      _CopyWithStubImpl$Mutation$UpdateProfile;

  TRes call({Fragment$EmployeeFields? updateProfile, String? $__typename});
  CopyWith$Fragment$EmployeeFields<TRes> get updateProfile;
}

class _CopyWithImpl$Mutation$UpdateProfile<TRes>
    implements CopyWith$Mutation$UpdateProfile<TRes> {
  _CopyWithImpl$Mutation$UpdateProfile(this._instance, this._then);

  final Mutation$UpdateProfile _instance;

  final TRes Function(Mutation$UpdateProfile) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? updateProfile = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Mutation$UpdateProfile(
      updateProfile: updateProfile == _undefined || updateProfile == null
          ? _instance.updateProfile
          : (updateProfile as Fragment$EmployeeFields),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Fragment$EmployeeFields<TRes> get updateProfile {
    final local$updateProfile = _instance.updateProfile;
    return CopyWith$Fragment$EmployeeFields(
      local$updateProfile,
      (e) => call(updateProfile: e),
    );
  }
}

class _CopyWithStubImpl$Mutation$UpdateProfile<TRes>
    implements CopyWith$Mutation$UpdateProfile<TRes> {
  _CopyWithStubImpl$Mutation$UpdateProfile(this._res);

  TRes _res;

  call({Fragment$EmployeeFields? updateProfile, String? $__typename}) => _res;

  CopyWith$Fragment$EmployeeFields<TRes> get updateProfile =>
      CopyWith$Fragment$EmployeeFields.stub(_res);
}

const documentNodeMutationUpdateProfile = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.mutation,
      name: NameNode(value: 'UpdateProfile'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'input')),
          type: NamedTypeNode(
            name: NameNode(value: 'UpdateProfileInput'),
            isNonNull: true,
          ),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'updateProfile'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'input'),
                value: VariableNode(name: NameNode(value: 'input')),
              ),
            ],
            directives: [],
            selectionSet: SelectionSetNode(
              selections: [
                FragmentSpreadNode(
                  name: NameNode(value: 'EmployeeFields'),
                  directives: [],
                ),
                FieldNode(
                  name: NameNode(value: '__typename'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
              ],
            ),
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
    fragmentDefinitionEmployeeFields,
    fragmentDefinitionPersonalFields,
  ],
);
Mutation$UpdateProfile _parserFn$Mutation$UpdateProfile(
  Map<String, dynamic> data,
) => Mutation$UpdateProfile.fromJson(data);
typedef OnMutationCompleted$Mutation$UpdateProfile = FutureOr<void> Function(
  Map<String, dynamic>?,
  Mutation$UpdateProfile?,
);

class Options$Mutation$UpdateProfile
    extends graphql.MutationOptions<Mutation$UpdateProfile> {
  Options$Mutation$UpdateProfile({
    String? operationName,
    required Variables$Mutation$UpdateProfile variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Mutation$UpdateProfile? typedOptimisticResult,
    graphql.Context? context,
    OnMutationCompleted$Mutation$UpdateProfile? onCompleted,
    graphql.OnMutationUpdate<Mutation$UpdateProfile>? update,
    graphql.OnError? onError,
  }) : onCompletedWithParsed = onCompleted,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         onCompleted: onCompleted == null
             ? null
             : (data) => onCompleted(
                 data,
                 data == null ? null : _parserFn$Mutation$UpdateProfile(data),
               ),
         update: update,
         onError: onError,
         document: documentNodeMutationUpdateProfile,
         parserFn: _parserFn$Mutation$UpdateProfile,
       );

  final OnMutationCompleted$Mutation$UpdateProfile? onCompletedWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onCompleted == null
        ? super.properties
        : super.properties.where((property) => property != onCompleted),
    onCompletedWithParsed,
  ];
}

class WatchOptions$Mutation$UpdateProfile
    extends graphql.WatchQueryOptions<Mutation$UpdateProfile> {
  WatchOptions$Mutation$UpdateProfile({
    String? operationName,
    required Variables$Mutation$UpdateProfile variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Mutation$UpdateProfile? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeMutationUpdateProfile,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Mutation$UpdateProfile,
       );
}

extension ClientExtension$Mutation$UpdateProfile on graphql.GraphQLClient {
  Future<graphql.QueryResult<Mutation$UpdateProfile>> mutate$UpdateProfile(
    Options$Mutation$UpdateProfile options,
  ) async => await this.mutate(options);

  graphql.ObservableQuery<Mutation$UpdateProfile> watchMutation$UpdateProfile(
    WatchOptions$Mutation$UpdateProfile options,
  ) => this.watchMutation(options);
}

class Variables$Query$AccessUsers {
  factory Variables$Query$AccessUsers({
    required String siteId,
    String? search,
  }) => Variables$Query$AccessUsers._({
    r'siteId': siteId,
    if (search != null) r'search': search,
  });

  Variables$Query$AccessUsers._(this._$data);

  factory Variables$Query$AccessUsers.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    if (data.containsKey('search')) {
      final l$search = data['search'];
      result$data['search'] = (l$search as String?);
    }
    return Variables$Query$AccessUsers._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  String? get search => (_$data['search'] as String?);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    if (_$data.containsKey('search')) {
      final l$search = search;
      result$data['search'] = l$search;
    }
    return result$data;
  }

  CopyWith$Variables$Query$AccessUsers<Variables$Query$AccessUsers>
  get copyWith => CopyWith$Variables$Query$AccessUsers(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$AccessUsers ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    final l$search = search;
    final lOther$search = other.search;
    if (_$data.containsKey('search') != other._$data.containsKey('search')) {
      return false;
    }
    if (l$search != lOther$search) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    final l$search = search;
    return Object.hashAll([
      l$siteId,
      _$data.containsKey('search') ? l$search : const {},
    ]);
  }
}

abstract class CopyWith$Variables$Query$AccessUsers<TRes> {
  factory CopyWith$Variables$Query$AccessUsers(
    Variables$Query$AccessUsers instance,
    TRes Function(Variables$Query$AccessUsers) then,
  ) = _CopyWithImpl$Variables$Query$AccessUsers;

  factory CopyWith$Variables$Query$AccessUsers.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$AccessUsers;

  TRes call({String? siteId, String? search});
}

class _CopyWithImpl$Variables$Query$AccessUsers<TRes>
    implements CopyWith$Variables$Query$AccessUsers<TRes> {
  _CopyWithImpl$Variables$Query$AccessUsers(this._instance, this._then);

  final Variables$Query$AccessUsers _instance;

  final TRes Function(Variables$Query$AccessUsers) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? siteId = _undefined, Object? search = _undefined}) =>
      _then(
        Variables$Query$AccessUsers._({
          ..._instance._$data,
          if (siteId != _undefined && siteId != null)
            'siteId': (siteId as String),
          if (search != _undefined) 'search': (search as String?),
        }),
      );
}

class _CopyWithStubImpl$Variables$Query$AccessUsers<TRes>
    implements CopyWith$Variables$Query$AccessUsers<TRes> {
  _CopyWithStubImpl$Variables$Query$AccessUsers(this._res);

  TRes _res;

  call({String? siteId, String? search}) => _res;
}

class Query$AccessUsers {
  Query$AccessUsers({required this.accessUsers, this.$__typename = 'Query'});

  factory Query$AccessUsers.fromJson(Map<String, dynamic> json) {
    final l$accessUsers = json['accessUsers'];
    final l$$__typename = json['__typename'];
    return Query$AccessUsers(
      accessUsers: Query$AccessUsers$accessUsers.fromJson(
        (l$accessUsers as Map<String, dynamic>),
      ),
      $__typename: (l$$__typename as String),
    );
  }

  final Query$AccessUsers$accessUsers accessUsers;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$accessUsers = accessUsers;
    _resultData['accessUsers'] = l$accessUsers.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$accessUsers = accessUsers;
    final l$$__typename = $__typename;
    return Object.hashAll([l$accessUsers, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$AccessUsers || runtimeType != other.runtimeType) {
      return false;
    }
    final l$accessUsers = accessUsers;
    final lOther$accessUsers = other.accessUsers;
    if (l$accessUsers != lOther$accessUsers) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$AccessUsers on Query$AccessUsers {
  CopyWith$Query$AccessUsers<Query$AccessUsers> get copyWith =>
      CopyWith$Query$AccessUsers(this, (i) => i);
}

abstract class CopyWith$Query$AccessUsers<TRes> {
  factory CopyWith$Query$AccessUsers(
    Query$AccessUsers instance,
    TRes Function(Query$AccessUsers) then,
  ) = _CopyWithImpl$Query$AccessUsers;

  factory CopyWith$Query$AccessUsers.stub(TRes res) =
      _CopyWithStubImpl$Query$AccessUsers;

  TRes call({Query$AccessUsers$accessUsers? accessUsers, String? $__typename});
  CopyWith$Query$AccessUsers$accessUsers<TRes> get accessUsers;
}

class _CopyWithImpl$Query$AccessUsers<TRes>
    implements CopyWith$Query$AccessUsers<TRes> {
  _CopyWithImpl$Query$AccessUsers(this._instance, this._then);

  final Query$AccessUsers _instance;

  final TRes Function(Query$AccessUsers) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? accessUsers = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$AccessUsers(
      accessUsers: accessUsers == _undefined || accessUsers == null
          ? _instance.accessUsers
          : (accessUsers as Query$AccessUsers$accessUsers),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Query$AccessUsers$accessUsers<TRes> get accessUsers {
    final local$accessUsers = _instance.accessUsers;
    return CopyWith$Query$AccessUsers$accessUsers(
      local$accessUsers,
      (e) => call(accessUsers: e),
    );
  }
}

class _CopyWithStubImpl$Query$AccessUsers<TRes>
    implements CopyWith$Query$AccessUsers<TRes> {
  _CopyWithStubImpl$Query$AccessUsers(this._res);

  TRes _res;

  call({Query$AccessUsers$accessUsers? accessUsers, String? $__typename}) =>
      _res;

  CopyWith$Query$AccessUsers$accessUsers<TRes> get accessUsers =>
      CopyWith$Query$AccessUsers$accessUsers.stub(_res);
}

const documentNodeQueryAccessUsers = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'AccessUsers'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'search')),
          type: NamedTypeNode(
            name: NameNode(value: 'String'),
            isNonNull: false,
          ),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'accessUsers'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'search'),
                value: VariableNode(name: NameNode(value: 'search')),
              ),
            ],
            directives: [],
            selectionSet: SelectionSetNode(
              selections: [
                FieldNode(
                  name: NameNode(value: 'users'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FieldNode(
                        name: NameNode(value: 'id'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'name'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'email'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'active'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'version'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'protected'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: '__typename'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                    ],
                  ),
                ),
                FieldNode(
                  name: NameNode(value: 'isSuperAdmin'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'canManage'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: '__typename'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
              ],
            ),
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Query$AccessUsers _parserFn$Query$AccessUsers(Map<String, dynamic> data) =>
    Query$AccessUsers.fromJson(data);
typedef OnQueryComplete$Query$AccessUsers = FutureOr<void> Function(
  Map<String, dynamic>?,
  Query$AccessUsers?,
);

class Options$Query$AccessUsers
    extends graphql.QueryOptions<Query$AccessUsers> {
  Options$Query$AccessUsers({
    String? operationName,
    required Variables$Query$AccessUsers variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$AccessUsers? typedOptimisticResult,
    Duration? pollInterval,
    graphql.Context? context,
    OnQueryComplete$Query$AccessUsers? onComplete,
    graphql.OnQueryError? onError,
  }) : onCompleteWithParsed = onComplete,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         pollInterval: pollInterval,
         context: context,
         onComplete: onComplete == null
             ? null
             : (data) => onComplete(
                 data,
                 data == null ? null : _parserFn$Query$AccessUsers(data),
               ),
         onError: onError,
         document: documentNodeQueryAccessUsers,
         parserFn: _parserFn$Query$AccessUsers,
       );

  final OnQueryComplete$Query$AccessUsers? onCompleteWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onComplete == null
        ? super.properties
        : super.properties.where((property) => property != onComplete),
    onCompleteWithParsed,
  ];
}

class WatchOptions$Query$AccessUsers
    extends graphql.WatchQueryOptions<Query$AccessUsers> {
  WatchOptions$Query$AccessUsers({
    String? operationName,
    required Variables$Query$AccessUsers variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$AccessUsers? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeQueryAccessUsers,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Query$AccessUsers,
       );
}

class FetchMoreOptions$Query$AccessUsers extends graphql.FetchMoreOptions {
  FetchMoreOptions$Query$AccessUsers({
    required graphql.UpdateQuery updateQuery,
    required Variables$Query$AccessUsers variables,
  }) : super(
         updateQuery: updateQuery,
         variables: variables.toJson(),
         document: documentNodeQueryAccessUsers,
       );
}

extension ClientExtension$Query$AccessUsers on graphql.GraphQLClient {
  Future<graphql.QueryResult<Query$AccessUsers>> query$AccessUsers(
    Options$Query$AccessUsers options,
  ) async => await this.query(options);

  graphql.ObservableQuery<Query$AccessUsers> watchQuery$AccessUsers(
    WatchOptions$Query$AccessUsers options,
  ) => this.watchQuery(options);

  void writeQuery$AccessUsers({
    required Query$AccessUsers data,
    required Variables$Query$AccessUsers variables,
    bool broadcast = true,
  }) => this.writeQuery(
    graphql.Request(
      operation: graphql.Operation(document: documentNodeQueryAccessUsers),
      variables: variables.toJson(),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Query$AccessUsers? readQuery$AccessUsers({
    required Variables$Query$AccessUsers variables,
    bool optimistic = true,
  }) {
    final result = this.readQuery(
      graphql.Request(
        operation: graphql.Operation(document: documentNodeQueryAccessUsers),
        variables: variables.toJson(),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Query$AccessUsers.fromJson(result);
  }
}

class Query$AccessUsers$accessUsers {
  Query$AccessUsers$accessUsers({
    required this.users,
    required this.isSuperAdmin,
    required this.canManage,
    this.$__typename = 'AccessUsers',
  });

  factory Query$AccessUsers$accessUsers.fromJson(Map<String, dynamic> json) {
    final l$users = json['users'];
    final l$isSuperAdmin = json['isSuperAdmin'];
    final l$canManage = json['canManage'];
    final l$$__typename = json['__typename'];
    return Query$AccessUsers$accessUsers(
      users: (l$users as List<dynamic>)
          .map(
            (e) => Query$AccessUsers$accessUsers$users.fromJson(
              (e as Map<String, dynamic>),
            ),
          )
          .toList(),
      isSuperAdmin: (l$isSuperAdmin as bool),
      canManage: (l$canManage as bool),
      $__typename: (l$$__typename as String),
    );
  }

  final List<Query$AccessUsers$accessUsers$users> users;

  final bool isSuperAdmin;

  final bool canManage;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$users = users;
    _resultData['users'] = l$users.map((e) => e.toJson()).toList();
    final l$isSuperAdmin = isSuperAdmin;
    _resultData['isSuperAdmin'] = l$isSuperAdmin;
    final l$canManage = canManage;
    _resultData['canManage'] = l$canManage;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$users = users;
    final l$isSuperAdmin = isSuperAdmin;
    final l$canManage = canManage;
    final l$$__typename = $__typename;
    return Object.hashAll([
      Object.hashAll(l$users.map((v) => v)),
      l$isSuperAdmin,
      l$canManage,
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$AccessUsers$accessUsers ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$users = users;
    final lOther$users = other.users;
    if (l$users.length != lOther$users.length) {
      return false;
    }
    for (int i = 0; i < l$users.length; i++) {
      final l$users$entry = l$users[i];
      final lOther$users$entry = lOther$users[i];
      if (l$users$entry != lOther$users$entry) {
        return false;
      }
    }
    final l$isSuperAdmin = isSuperAdmin;
    final lOther$isSuperAdmin = other.isSuperAdmin;
    if (l$isSuperAdmin != lOther$isSuperAdmin) {
      return false;
    }
    final l$canManage = canManage;
    final lOther$canManage = other.canManage;
    if (l$canManage != lOther$canManage) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$AccessUsers$accessUsers
    on Query$AccessUsers$accessUsers {
  CopyWith$Query$AccessUsers$accessUsers<Query$AccessUsers$accessUsers>
  get copyWith => CopyWith$Query$AccessUsers$accessUsers(this, (i) => i);
}

abstract class CopyWith$Query$AccessUsers$accessUsers<TRes> {
  factory CopyWith$Query$AccessUsers$accessUsers(
    Query$AccessUsers$accessUsers instance,
    TRes Function(Query$AccessUsers$accessUsers) then,
  ) = _CopyWithImpl$Query$AccessUsers$accessUsers;

  factory CopyWith$Query$AccessUsers$accessUsers.stub(TRes res) =
      _CopyWithStubImpl$Query$AccessUsers$accessUsers;

  TRes call({
    List<Query$AccessUsers$accessUsers$users>? users,
    bool? isSuperAdmin,
    bool? canManage,
    String? $__typename,
  });
  TRes users(
    Iterable<Query$AccessUsers$accessUsers$users> Function(
      Iterable<
        CopyWith$Query$AccessUsers$accessUsers$users<
          Query$AccessUsers$accessUsers$users
        >
      >,
    )
    _fn,
  );
}

class _CopyWithImpl$Query$AccessUsers$accessUsers<TRes>
    implements CopyWith$Query$AccessUsers$accessUsers<TRes> {
  _CopyWithImpl$Query$AccessUsers$accessUsers(this._instance, this._then);

  final Query$AccessUsers$accessUsers _instance;

  final TRes Function(Query$AccessUsers$accessUsers) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? users = _undefined,
    Object? isSuperAdmin = _undefined,
    Object? canManage = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$AccessUsers$accessUsers(
      users: users == _undefined || users == null
          ? _instance.users
          : (users as List<Query$AccessUsers$accessUsers$users>),
      isSuperAdmin: isSuperAdmin == _undefined || isSuperAdmin == null
          ? _instance.isSuperAdmin
          : (isSuperAdmin as bool),
      canManage: canManage == _undefined || canManage == null
          ? _instance.canManage
          : (canManage as bool),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  TRes users(
    Iterable<Query$AccessUsers$accessUsers$users> Function(
      Iterable<
        CopyWith$Query$AccessUsers$accessUsers$users<
          Query$AccessUsers$accessUsers$users
        >
      >,
    )
    _fn,
  ) => call(
    users: _fn(
      _instance.users.map(
        (e) => CopyWith$Query$AccessUsers$accessUsers$users(e, (i) => i),
      ),
    ).toList(),
  );
}

class _CopyWithStubImpl$Query$AccessUsers$accessUsers<TRes>
    implements CopyWith$Query$AccessUsers$accessUsers<TRes> {
  _CopyWithStubImpl$Query$AccessUsers$accessUsers(this._res);

  TRes _res;

  call({
    List<Query$AccessUsers$accessUsers$users>? users,
    bool? isSuperAdmin,
    bool? canManage,
    String? $__typename,
  }) => _res;

  users(_fn) => _res;
}

class Query$AccessUsers$accessUsers$users {
  Query$AccessUsers$accessUsers$users({
    required this.id,
    required this.name,
    required this.email,
    required this.active,
    required this.version,
    required this.protected,
    this.$__typename = 'AccessUser',
  });

  factory Query$AccessUsers$accessUsers$users.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$id = json['id'];
    final l$name = json['name'];
    final l$email = json['email'];
    final l$active = json['active'];
    final l$version = json['version'];
    final l$protected = json['protected'];
    final l$$__typename = json['__typename'];
    return Query$AccessUsers$accessUsers$users(
      id: (l$id as String),
      name: (l$name as String),
      email: (l$email as String),
      active: (l$active as bool),
      version: (l$version as int),
      protected: (l$protected as bool),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String name;

  final String email;

  final bool active;

  final int version;

  final bool protected;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$name = name;
    _resultData['name'] = l$name;
    final l$email = email;
    _resultData['email'] = l$email;
    final l$active = active;
    _resultData['active'] = l$active;
    final l$version = version;
    _resultData['version'] = l$version;
    final l$protected = protected;
    _resultData['protected'] = l$protected;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$name = name;
    final l$email = email;
    final l$active = active;
    final l$version = version;
    final l$protected = protected;
    final l$$__typename = $__typename;
    return Object.hashAll([
      l$id,
      l$name,
      l$email,
      l$active,
      l$version,
      l$protected,
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$AccessUsers$accessUsers$users ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$name = name;
    final lOther$name = other.name;
    if (l$name != lOther$name) {
      return false;
    }
    final l$email = email;
    final lOther$email = other.email;
    if (l$email != lOther$email) {
      return false;
    }
    final l$active = active;
    final lOther$active = other.active;
    if (l$active != lOther$active) {
      return false;
    }
    final l$version = version;
    final lOther$version = other.version;
    if (l$version != lOther$version) {
      return false;
    }
    final l$protected = protected;
    final lOther$protected = other.protected;
    if (l$protected != lOther$protected) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$AccessUsers$accessUsers$users
    on Query$AccessUsers$accessUsers$users {
  CopyWith$Query$AccessUsers$accessUsers$users<
    Query$AccessUsers$accessUsers$users
  >
  get copyWith => CopyWith$Query$AccessUsers$accessUsers$users(this, (i) => i);
}

abstract class CopyWith$Query$AccessUsers$accessUsers$users<TRes> {
  factory CopyWith$Query$AccessUsers$accessUsers$users(
    Query$AccessUsers$accessUsers$users instance,
    TRes Function(Query$AccessUsers$accessUsers$users) then,
  ) = _CopyWithImpl$Query$AccessUsers$accessUsers$users;

  factory CopyWith$Query$AccessUsers$accessUsers$users.stub(TRes res) =
      _CopyWithStubImpl$Query$AccessUsers$accessUsers$users;

  TRes call({
    String? id,
    String? name,
    String? email,
    bool? active,
    int? version,
    bool? protected,
    String? $__typename,
  });
}

class _CopyWithImpl$Query$AccessUsers$accessUsers$users<TRes>
    implements CopyWith$Query$AccessUsers$accessUsers$users<TRes> {
  _CopyWithImpl$Query$AccessUsers$accessUsers$users(this._instance, this._then);

  final Query$AccessUsers$accessUsers$users _instance;

  final TRes Function(Query$AccessUsers$accessUsers$users) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? name = _undefined,
    Object? email = _undefined,
    Object? active = _undefined,
    Object? version = _undefined,
    Object? protected = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$AccessUsers$accessUsers$users(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      name: name == _undefined || name == null
          ? _instance.name
          : (name as String),
      email: email == _undefined || email == null
          ? _instance.email
          : (email as String),
      active: active == _undefined || active == null
          ? _instance.active
          : (active as bool),
      version: version == _undefined || version == null
          ? _instance.version
          : (version as int),
      protected: protected == _undefined || protected == null
          ? _instance.protected
          : (protected as bool),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$AccessUsers$accessUsers$users<TRes>
    implements CopyWith$Query$AccessUsers$accessUsers$users<TRes> {
  _CopyWithStubImpl$Query$AccessUsers$accessUsers$users(this._res);

  TRes _res;

  call({
    String? id,
    String? name,
    String? email,
    bool? active,
    int? version,
    bool? protected,
    String? $__typename,
  }) => _res;
}

class Variables$Query$UserAccess {
  factory Variables$Query$UserAccess({
    required String siteId,
    required String userId,
  }) => Variables$Query$UserAccess._({r'siteId': siteId, r'userId': userId});

  Variables$Query$UserAccess._(this._$data);

  factory Variables$Query$UserAccess.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    final l$userId = data['userId'];
    result$data['userId'] = (l$userId as String);
    return Variables$Query$UserAccess._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  String get userId => (_$data['userId'] as String);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    final l$userId = userId;
    result$data['userId'] = l$userId;
    return result$data;
  }

  CopyWith$Variables$Query$UserAccess<Variables$Query$UserAccess>
  get copyWith => CopyWith$Variables$Query$UserAccess(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$UserAccess ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    final l$userId = userId;
    final lOther$userId = other.userId;
    if (l$userId != lOther$userId) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    final l$userId = userId;
    return Object.hashAll([l$siteId, l$userId]);
  }
}

abstract class CopyWith$Variables$Query$UserAccess<TRes> {
  factory CopyWith$Variables$Query$UserAccess(
    Variables$Query$UserAccess instance,
    TRes Function(Variables$Query$UserAccess) then,
  ) = _CopyWithImpl$Variables$Query$UserAccess;

  factory CopyWith$Variables$Query$UserAccess.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$UserAccess;

  TRes call({String? siteId, String? userId});
}

class _CopyWithImpl$Variables$Query$UserAccess<TRes>
    implements CopyWith$Variables$Query$UserAccess<TRes> {
  _CopyWithImpl$Variables$Query$UserAccess(this._instance, this._then);

  final Variables$Query$UserAccess _instance;

  final TRes Function(Variables$Query$UserAccess) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? siteId = _undefined,
    Object? userId = _undefined,
  }) => _then(
    Variables$Query$UserAccess._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
      if (userId != _undefined && userId != null) 'userId': (userId as String),
    }),
  );
}

class _CopyWithStubImpl$Variables$Query$UserAccess<TRes>
    implements CopyWith$Variables$Query$UserAccess<TRes> {
  _CopyWithStubImpl$Variables$Query$UserAccess(this._res);

  TRes _res;

  call({String? siteId, String? userId}) => _res;
}

class Query$UserAccess {
  Query$UserAccess({required this.userAccess, this.$__typename = 'Query'});

  factory Query$UserAccess.fromJson(Map<String, dynamic> json) {
    final l$userAccess = json['userAccess'];
    final l$$__typename = json['__typename'];
    return Query$UserAccess(
      userAccess: Query$UserAccess$userAccess.fromJson(
        (l$userAccess as Map<String, dynamic>),
      ),
      $__typename: (l$$__typename as String),
    );
  }

  final Query$UserAccess$userAccess userAccess;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$userAccess = userAccess;
    _resultData['userAccess'] = l$userAccess.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$userAccess = userAccess;
    final l$$__typename = $__typename;
    return Object.hashAll([l$userAccess, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$UserAccess || runtimeType != other.runtimeType) {
      return false;
    }
    final l$userAccess = userAccess;
    final lOther$userAccess = other.userAccess;
    if (l$userAccess != lOther$userAccess) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$UserAccess on Query$UserAccess {
  CopyWith$Query$UserAccess<Query$UserAccess> get copyWith =>
      CopyWith$Query$UserAccess(this, (i) => i);
}

abstract class CopyWith$Query$UserAccess<TRes> {
  factory CopyWith$Query$UserAccess(
    Query$UserAccess instance,
    TRes Function(Query$UserAccess) then,
  ) = _CopyWithImpl$Query$UserAccess;

  factory CopyWith$Query$UserAccess.stub(TRes res) =
      _CopyWithStubImpl$Query$UserAccess;

  TRes call({Query$UserAccess$userAccess? userAccess, String? $__typename});
  CopyWith$Query$UserAccess$userAccess<TRes> get userAccess;
}

class _CopyWithImpl$Query$UserAccess<TRes>
    implements CopyWith$Query$UserAccess<TRes> {
  _CopyWithImpl$Query$UserAccess(this._instance, this._then);

  final Query$UserAccess _instance;

  final TRes Function(Query$UserAccess) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? userAccess = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$UserAccess(
      userAccess: userAccess == _undefined || userAccess == null
          ? _instance.userAccess
          : (userAccess as Query$UserAccess$userAccess),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Query$UserAccess$userAccess<TRes> get userAccess {
    final local$userAccess = _instance.userAccess;
    return CopyWith$Query$UserAccess$userAccess(
      local$userAccess,
      (e) => call(userAccess: e),
    );
  }
}

class _CopyWithStubImpl$Query$UserAccess<TRes>
    implements CopyWith$Query$UserAccess<TRes> {
  _CopyWithStubImpl$Query$UserAccess(this._res);

  TRes _res;

  call({Query$UserAccess$userAccess? userAccess, String? $__typename}) => _res;

  CopyWith$Query$UserAccess$userAccess<TRes> get userAccess =>
      CopyWith$Query$UserAccess$userAccess.stub(_res);
}

const documentNodeQueryUserAccess = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'UserAccess'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'userId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'userAccess'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'userId'),
                value: VariableNode(name: NameNode(value: 'userId')),
              ),
            ],
            directives: [],
            selectionSet: SelectionSetNode(
              selections: [
                FieldNode(
                  name: NameNode(value: 'id'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'name'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'email'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'active'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'role'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'version'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'protected'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'sites'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FieldNode(
                        name: NameNode(value: 'id'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'name'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'active'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: '__typename'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                    ],
                  ),
                ),
                FieldNode(
                  name: NameNode(value: 'rules'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FieldNode(
                        name: NameNode(value: 'key'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'effect'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'scope'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: '__typename'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                    ],
                  ),
                ),
                FieldNode(
                  name: NameNode(value: 'delegations'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FieldNode(
                        name: NameNode(value: 'key'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'scope'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: '__typename'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                    ],
                  ),
                ),
                FieldNode(
                  name: NameNode(value: 'effective'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FieldNode(
                        name: NameNode(value: 'key'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'decision'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: SelectionSetNode(
                          selections: [
                            FragmentSpreadNode(
                              name: NameNode(value: 'DecisionFields'),
                              directives: [],
                            ),
                            FieldNode(
                              name: NameNode(value: '__typename'),
                              alias: null,
                              arguments: [],
                              directives: [],
                              selectionSet: null,
                            ),
                          ],
                        ),
                      ),
                      FieldNode(
                        name: NameNode(value: '__typename'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                    ],
                  ),
                ),
                FieldNode(
                  name: NameNode(value: 'audit'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FieldNode(
                        name: NameNode(value: 'id'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'actorId'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'createdAt'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'reason'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'version'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'changes'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: SelectionSetNode(
                          selections: [
                            FragmentSpreadNode(
                              name: NameNode(value: 'ChangeFields'),
                              directives: [],
                            ),
                            FieldNode(
                              name: NameNode(value: '__typename'),
                              alias: null,
                              arguments: [],
                              directives: [],
                              selectionSet: null,
                            ),
                          ],
                        ),
                      ),
                      FieldNode(
                        name: NameNode(value: '__typename'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                    ],
                  ),
                ),
                FieldNode(
                  name: NameNode(value: '__typename'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
              ],
            ),
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
    fragmentDefinitionDecisionFields,
    fragmentDefinitionChangeFields,
  ],
);
Query$UserAccess _parserFn$Query$UserAccess(Map<String, dynamic> data) =>
    Query$UserAccess.fromJson(data);
typedef OnQueryComplete$Query$UserAccess = FutureOr<void> Function(
  Map<String, dynamic>?,
  Query$UserAccess?,
);

class Options$Query$UserAccess extends graphql.QueryOptions<Query$UserAccess> {
  Options$Query$UserAccess({
    String? operationName,
    required Variables$Query$UserAccess variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$UserAccess? typedOptimisticResult,
    Duration? pollInterval,
    graphql.Context? context,
    OnQueryComplete$Query$UserAccess? onComplete,
    graphql.OnQueryError? onError,
  }) : onCompleteWithParsed = onComplete,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         pollInterval: pollInterval,
         context: context,
         onComplete: onComplete == null
             ? null
             : (data) => onComplete(
                 data,
                 data == null ? null : _parserFn$Query$UserAccess(data),
               ),
         onError: onError,
         document: documentNodeQueryUserAccess,
         parserFn: _parserFn$Query$UserAccess,
       );

  final OnQueryComplete$Query$UserAccess? onCompleteWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onComplete == null
        ? super.properties
        : super.properties.where((property) => property != onComplete),
    onCompleteWithParsed,
  ];
}

class WatchOptions$Query$UserAccess
    extends graphql.WatchQueryOptions<Query$UserAccess> {
  WatchOptions$Query$UserAccess({
    String? operationName,
    required Variables$Query$UserAccess variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$UserAccess? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeQueryUserAccess,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Query$UserAccess,
       );
}

class FetchMoreOptions$Query$UserAccess extends graphql.FetchMoreOptions {
  FetchMoreOptions$Query$UserAccess({
    required graphql.UpdateQuery updateQuery,
    required Variables$Query$UserAccess variables,
  }) : super(
         updateQuery: updateQuery,
         variables: variables.toJson(),
         document: documentNodeQueryUserAccess,
       );
}

extension ClientExtension$Query$UserAccess on graphql.GraphQLClient {
  Future<graphql.QueryResult<Query$UserAccess>> query$UserAccess(
    Options$Query$UserAccess options,
  ) async => await this.query(options);

  graphql.ObservableQuery<Query$UserAccess> watchQuery$UserAccess(
    WatchOptions$Query$UserAccess options,
  ) => this.watchQuery(options);

  void writeQuery$UserAccess({
    required Query$UserAccess data,
    required Variables$Query$UserAccess variables,
    bool broadcast = true,
  }) => this.writeQuery(
    graphql.Request(
      operation: graphql.Operation(document: documentNodeQueryUserAccess),
      variables: variables.toJson(),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Query$UserAccess? readQuery$UserAccess({
    required Variables$Query$UserAccess variables,
    bool optimistic = true,
  }) {
    final result = this.readQuery(
      graphql.Request(
        operation: graphql.Operation(document: documentNodeQueryUserAccess),
        variables: variables.toJson(),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Query$UserAccess.fromJson(result);
  }
}

class Query$UserAccess$userAccess {
  Query$UserAccess$userAccess({
    required this.id,
    required this.name,
    required this.email,
    required this.active,
    required this.role,
    required this.version,
    required this.protected,
    required this.sites,
    required this.rules,
    required this.delegations,
    required this.effective,
    required this.audit,
    this.$__typename = 'UserAccess',
  });

  factory Query$UserAccess$userAccess.fromJson(Map<String, dynamic> json) {
    final l$id = json['id'];
    final l$name = json['name'];
    final l$email = json['email'];
    final l$active = json['active'];
    final l$role = json['role'];
    final l$version = json['version'];
    final l$protected = json['protected'];
    final l$sites = json['sites'];
    final l$rules = json['rules'];
    final l$delegations = json['delegations'];
    final l$effective = json['effective'];
    final l$audit = json['audit'];
    final l$$__typename = json['__typename'];
    return Query$UserAccess$userAccess(
      id: (l$id as String),
      name: (l$name as String),
      email: (l$email as String),
      active: (l$active as bool),
      role: (l$role as String),
      version: (l$version as int),
      protected: (l$protected as bool),
      sites: (l$sites as List<dynamic>)
          .map(
            (e) => Query$UserAccess$userAccess$sites.fromJson(
              (e as Map<String, dynamic>),
            ),
          )
          .toList(),
      rules: (l$rules as List<dynamic>)
          .map(
            (e) => Query$UserAccess$userAccess$rules.fromJson(
              (e as Map<String, dynamic>),
            ),
          )
          .toList(),
      delegations: (l$delegations as List<dynamic>)
          .map(
            (e) => Query$UserAccess$userAccess$delegations.fromJson(
              (e as Map<String, dynamic>),
            ),
          )
          .toList(),
      effective: (l$effective as List<dynamic>)
          .map(
            (e) => Query$UserAccess$userAccess$effective.fromJson(
              (e as Map<String, dynamic>),
            ),
          )
          .toList(),
      audit: (l$audit as List<dynamic>)
          .map(
            (e) => Query$UserAccess$userAccess$audit.fromJson(
              (e as Map<String, dynamic>),
            ),
          )
          .toList(),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String name;

  final String email;

  final bool active;

  final String role;

  final int version;

  final bool protected;

  final List<Query$UserAccess$userAccess$sites> sites;

  final List<Query$UserAccess$userAccess$rules> rules;

  final List<Query$UserAccess$userAccess$delegations> delegations;

  final List<Query$UserAccess$userAccess$effective> effective;

  final List<Query$UserAccess$userAccess$audit> audit;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$name = name;
    _resultData['name'] = l$name;
    final l$email = email;
    _resultData['email'] = l$email;
    final l$active = active;
    _resultData['active'] = l$active;
    final l$role = role;
    _resultData['role'] = l$role;
    final l$version = version;
    _resultData['version'] = l$version;
    final l$protected = protected;
    _resultData['protected'] = l$protected;
    final l$sites = sites;
    _resultData['sites'] = l$sites.map((e) => e.toJson()).toList();
    final l$rules = rules;
    _resultData['rules'] = l$rules.map((e) => e.toJson()).toList();
    final l$delegations = delegations;
    _resultData['delegations'] = l$delegations.map((e) => e.toJson()).toList();
    final l$effective = effective;
    _resultData['effective'] = l$effective.map((e) => e.toJson()).toList();
    final l$audit = audit;
    _resultData['audit'] = l$audit.map((e) => e.toJson()).toList();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$name = name;
    final l$email = email;
    final l$active = active;
    final l$role = role;
    final l$version = version;
    final l$protected = protected;
    final l$sites = sites;
    final l$rules = rules;
    final l$delegations = delegations;
    final l$effective = effective;
    final l$audit = audit;
    final l$$__typename = $__typename;
    return Object.hashAll([
      l$id,
      l$name,
      l$email,
      l$active,
      l$role,
      l$version,
      l$protected,
      Object.hashAll(l$sites.map((v) => v)),
      Object.hashAll(l$rules.map((v) => v)),
      Object.hashAll(l$delegations.map((v) => v)),
      Object.hashAll(l$effective.map((v) => v)),
      Object.hashAll(l$audit.map((v) => v)),
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$UserAccess$userAccess ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$name = name;
    final lOther$name = other.name;
    if (l$name != lOther$name) {
      return false;
    }
    final l$email = email;
    final lOther$email = other.email;
    if (l$email != lOther$email) {
      return false;
    }
    final l$active = active;
    final lOther$active = other.active;
    if (l$active != lOther$active) {
      return false;
    }
    final l$role = role;
    final lOther$role = other.role;
    if (l$role != lOther$role) {
      return false;
    }
    final l$version = version;
    final lOther$version = other.version;
    if (l$version != lOther$version) {
      return false;
    }
    final l$protected = protected;
    final lOther$protected = other.protected;
    if (l$protected != lOther$protected) {
      return false;
    }
    final l$sites = sites;
    final lOther$sites = other.sites;
    if (l$sites.length != lOther$sites.length) {
      return false;
    }
    for (int i = 0; i < l$sites.length; i++) {
      final l$sites$entry = l$sites[i];
      final lOther$sites$entry = lOther$sites[i];
      if (l$sites$entry != lOther$sites$entry) {
        return false;
      }
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
    final l$effective = effective;
    final lOther$effective = other.effective;
    if (l$effective.length != lOther$effective.length) {
      return false;
    }
    for (int i = 0; i < l$effective.length; i++) {
      final l$effective$entry = l$effective[i];
      final lOther$effective$entry = lOther$effective[i];
      if (l$effective$entry != lOther$effective$entry) {
        return false;
      }
    }
    final l$audit = audit;
    final lOther$audit = other.audit;
    if (l$audit.length != lOther$audit.length) {
      return false;
    }
    for (int i = 0; i < l$audit.length; i++) {
      final l$audit$entry = l$audit[i];
      final lOther$audit$entry = lOther$audit[i];
      if (l$audit$entry != lOther$audit$entry) {
        return false;
      }
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$UserAccess$userAccess
    on Query$UserAccess$userAccess {
  CopyWith$Query$UserAccess$userAccess<Query$UserAccess$userAccess>
  get copyWith => CopyWith$Query$UserAccess$userAccess(this, (i) => i);
}

abstract class CopyWith$Query$UserAccess$userAccess<TRes> {
  factory CopyWith$Query$UserAccess$userAccess(
    Query$UserAccess$userAccess instance,
    TRes Function(Query$UserAccess$userAccess) then,
  ) = _CopyWithImpl$Query$UserAccess$userAccess;

  factory CopyWith$Query$UserAccess$userAccess.stub(TRes res) =
      _CopyWithStubImpl$Query$UserAccess$userAccess;

  TRes call({
    String? id,
    String? name,
    String? email,
    bool? active,
    String? role,
    int? version,
    bool? protected,
    List<Query$UserAccess$userAccess$sites>? sites,
    List<Query$UserAccess$userAccess$rules>? rules,
    List<Query$UserAccess$userAccess$delegations>? delegations,
    List<Query$UserAccess$userAccess$effective>? effective,
    List<Query$UserAccess$userAccess$audit>? audit,
    String? $__typename,
  });
  TRes sites(
    Iterable<Query$UserAccess$userAccess$sites> Function(
      Iterable<
        CopyWith$Query$UserAccess$userAccess$sites<
          Query$UserAccess$userAccess$sites
        >
      >,
    )
    _fn,
  );
  TRes rules(
    Iterable<Query$UserAccess$userAccess$rules> Function(
      Iterable<
        CopyWith$Query$UserAccess$userAccess$rules<
          Query$UserAccess$userAccess$rules
        >
      >,
    )
    _fn,
  );
  TRes delegations(
    Iterable<Query$UserAccess$userAccess$delegations> Function(
      Iterable<
        CopyWith$Query$UserAccess$userAccess$delegations<
          Query$UserAccess$userAccess$delegations
        >
      >,
    )
    _fn,
  );
  TRes effective(
    Iterable<Query$UserAccess$userAccess$effective> Function(
      Iterable<
        CopyWith$Query$UserAccess$userAccess$effective<
          Query$UserAccess$userAccess$effective
        >
      >,
    )
    _fn,
  );
  TRes audit(
    Iterable<Query$UserAccess$userAccess$audit> Function(
      Iterable<
        CopyWith$Query$UserAccess$userAccess$audit<
          Query$UserAccess$userAccess$audit
        >
      >,
    )
    _fn,
  );
}

class _CopyWithImpl$Query$UserAccess$userAccess<TRes>
    implements CopyWith$Query$UserAccess$userAccess<TRes> {
  _CopyWithImpl$Query$UserAccess$userAccess(this._instance, this._then);

  final Query$UserAccess$userAccess _instance;

  final TRes Function(Query$UserAccess$userAccess) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? name = _undefined,
    Object? email = _undefined,
    Object? active = _undefined,
    Object? role = _undefined,
    Object? version = _undefined,
    Object? protected = _undefined,
    Object? sites = _undefined,
    Object? rules = _undefined,
    Object? delegations = _undefined,
    Object? effective = _undefined,
    Object? audit = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$UserAccess$userAccess(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      name: name == _undefined || name == null
          ? _instance.name
          : (name as String),
      email: email == _undefined || email == null
          ? _instance.email
          : (email as String),
      active: active == _undefined || active == null
          ? _instance.active
          : (active as bool),
      role: role == _undefined || role == null
          ? _instance.role
          : (role as String),
      version: version == _undefined || version == null
          ? _instance.version
          : (version as int),
      protected: protected == _undefined || protected == null
          ? _instance.protected
          : (protected as bool),
      sites: sites == _undefined || sites == null
          ? _instance.sites
          : (sites as List<Query$UserAccess$userAccess$sites>),
      rules: rules == _undefined || rules == null
          ? _instance.rules
          : (rules as List<Query$UserAccess$userAccess$rules>),
      delegations: delegations == _undefined || delegations == null
          ? _instance.delegations
          : (delegations as List<Query$UserAccess$userAccess$delegations>),
      effective: effective == _undefined || effective == null
          ? _instance.effective
          : (effective as List<Query$UserAccess$userAccess$effective>),
      audit: audit == _undefined || audit == null
          ? _instance.audit
          : (audit as List<Query$UserAccess$userAccess$audit>),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  TRes sites(
    Iterable<Query$UserAccess$userAccess$sites> Function(
      Iterable<
        CopyWith$Query$UserAccess$userAccess$sites<
          Query$UserAccess$userAccess$sites
        >
      >,
    )
    _fn,
  ) => call(
    sites: _fn(
      _instance.sites.map(
        (e) => CopyWith$Query$UserAccess$userAccess$sites(e, (i) => i),
      ),
    ).toList(),
  );

  TRes rules(
    Iterable<Query$UserAccess$userAccess$rules> Function(
      Iterable<
        CopyWith$Query$UserAccess$userAccess$rules<
          Query$UserAccess$userAccess$rules
        >
      >,
    )
    _fn,
  ) => call(
    rules: _fn(
      _instance.rules.map(
        (e) => CopyWith$Query$UserAccess$userAccess$rules(e, (i) => i),
      ),
    ).toList(),
  );

  TRes delegations(
    Iterable<Query$UserAccess$userAccess$delegations> Function(
      Iterable<
        CopyWith$Query$UserAccess$userAccess$delegations<
          Query$UserAccess$userAccess$delegations
        >
      >,
    )
    _fn,
  ) => call(
    delegations: _fn(
      _instance.delegations.map(
        (e) => CopyWith$Query$UserAccess$userAccess$delegations(e, (i) => i),
      ),
    ).toList(),
  );

  TRes effective(
    Iterable<Query$UserAccess$userAccess$effective> Function(
      Iterable<
        CopyWith$Query$UserAccess$userAccess$effective<
          Query$UserAccess$userAccess$effective
        >
      >,
    )
    _fn,
  ) => call(
    effective: _fn(
      _instance.effective.map(
        (e) => CopyWith$Query$UserAccess$userAccess$effective(e, (i) => i),
      ),
    ).toList(),
  );

  TRes audit(
    Iterable<Query$UserAccess$userAccess$audit> Function(
      Iterable<
        CopyWith$Query$UserAccess$userAccess$audit<
          Query$UserAccess$userAccess$audit
        >
      >,
    )
    _fn,
  ) => call(
    audit: _fn(
      _instance.audit.map(
        (e) => CopyWith$Query$UserAccess$userAccess$audit(e, (i) => i),
      ),
    ).toList(),
  );
}

class _CopyWithStubImpl$Query$UserAccess$userAccess<TRes>
    implements CopyWith$Query$UserAccess$userAccess<TRes> {
  _CopyWithStubImpl$Query$UserAccess$userAccess(this._res);

  TRes _res;

  call({
    String? id,
    String? name,
    String? email,
    bool? active,
    String? role,
    int? version,
    bool? protected,
    List<Query$UserAccess$userAccess$sites>? sites,
    List<Query$UserAccess$userAccess$rules>? rules,
    List<Query$UserAccess$userAccess$delegations>? delegations,
    List<Query$UserAccess$userAccess$effective>? effective,
    List<Query$UserAccess$userAccess$audit>? audit,
    String? $__typename,
  }) => _res;

  sites(_fn) => _res;

  rules(_fn) => _res;

  delegations(_fn) => _res;

  effective(_fn) => _res;

  audit(_fn) => _res;
}

class Query$UserAccess$userAccess$sites {
  Query$UserAccess$userAccess$sites({
    required this.id,
    required this.name,
    required this.active,
    this.$__typename = 'UserSite',
  });

  factory Query$UserAccess$userAccess$sites.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$id = json['id'];
    final l$name = json['name'];
    final l$active = json['active'];
    final l$$__typename = json['__typename'];
    return Query$UserAccess$userAccess$sites(
      id: (l$id as String),
      name: (l$name as String),
      active: (l$active as bool),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String name;

  final bool active;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$name = name;
    _resultData['name'] = l$name;
    final l$active = active;
    _resultData['active'] = l$active;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$name = name;
    final l$active = active;
    final l$$__typename = $__typename;
    return Object.hashAll([l$id, l$name, l$active, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$UserAccess$userAccess$sites ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$name = name;
    final lOther$name = other.name;
    if (l$name != lOther$name) {
      return false;
    }
    final l$active = active;
    final lOther$active = other.active;
    if (l$active != lOther$active) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$UserAccess$userAccess$sites
    on Query$UserAccess$userAccess$sites {
  CopyWith$Query$UserAccess$userAccess$sites<Query$UserAccess$userAccess$sites>
  get copyWith => CopyWith$Query$UserAccess$userAccess$sites(this, (i) => i);
}

abstract class CopyWith$Query$UserAccess$userAccess$sites<TRes> {
  factory CopyWith$Query$UserAccess$userAccess$sites(
    Query$UserAccess$userAccess$sites instance,
    TRes Function(Query$UserAccess$userAccess$sites) then,
  ) = _CopyWithImpl$Query$UserAccess$userAccess$sites;

  factory CopyWith$Query$UserAccess$userAccess$sites.stub(TRes res) =
      _CopyWithStubImpl$Query$UserAccess$userAccess$sites;

  TRes call({String? id, String? name, bool? active, String? $__typename});
}

class _CopyWithImpl$Query$UserAccess$userAccess$sites<TRes>
    implements CopyWith$Query$UserAccess$userAccess$sites<TRes> {
  _CopyWithImpl$Query$UserAccess$userAccess$sites(this._instance, this._then);

  final Query$UserAccess$userAccess$sites _instance;

  final TRes Function(Query$UserAccess$userAccess$sites) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? name = _undefined,
    Object? active = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$UserAccess$userAccess$sites(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      name: name == _undefined || name == null
          ? _instance.name
          : (name as String),
      active: active == _undefined || active == null
          ? _instance.active
          : (active as bool),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$UserAccess$userAccess$sites<TRes>
    implements CopyWith$Query$UserAccess$userAccess$sites<TRes> {
  _CopyWithStubImpl$Query$UserAccess$userAccess$sites(this._res);

  TRes _res;

  call({String? id, String? name, bool? active, String? $__typename}) => _res;
}

class Query$UserAccess$userAccess$rules {
  Query$UserAccess$userAccess$rules({
    required this.key,
    required this.effect,
    required this.scope,
    this.$__typename = 'AccessRule',
  });

  factory Query$UserAccess$userAccess$rules.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$key = json['key'];
    final l$effect = json['effect'];
    final l$scope = json['scope'];
    final l$$__typename = json['__typename'];
    return Query$UserAccess$userAccess$rules(
      key: (l$key as String),
      effect: (l$effect as String),
      scope: (l$scope as String),
      $__typename: (l$$__typename as String),
    );
  }

  final String key;

  final String effect;

  final String scope;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$key = key;
    _resultData['key'] = l$key;
    final l$effect = effect;
    _resultData['effect'] = l$effect;
    final l$scope = scope;
    _resultData['scope'] = l$scope;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$key = key;
    final l$effect = effect;
    final l$scope = scope;
    final l$$__typename = $__typename;
    return Object.hashAll([l$key, l$effect, l$scope, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$UserAccess$userAccess$rules ||
        runtimeType != other.runtimeType) {
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
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$UserAccess$userAccess$rules
    on Query$UserAccess$userAccess$rules {
  CopyWith$Query$UserAccess$userAccess$rules<Query$UserAccess$userAccess$rules>
  get copyWith => CopyWith$Query$UserAccess$userAccess$rules(this, (i) => i);
}

abstract class CopyWith$Query$UserAccess$userAccess$rules<TRes> {
  factory CopyWith$Query$UserAccess$userAccess$rules(
    Query$UserAccess$userAccess$rules instance,
    TRes Function(Query$UserAccess$userAccess$rules) then,
  ) = _CopyWithImpl$Query$UserAccess$userAccess$rules;

  factory CopyWith$Query$UserAccess$userAccess$rules.stub(TRes res) =
      _CopyWithStubImpl$Query$UserAccess$userAccess$rules;

  TRes call({String? key, String? effect, String? scope, String? $__typename});
}

class _CopyWithImpl$Query$UserAccess$userAccess$rules<TRes>
    implements CopyWith$Query$UserAccess$userAccess$rules<TRes> {
  _CopyWithImpl$Query$UserAccess$userAccess$rules(this._instance, this._then);

  final Query$UserAccess$userAccess$rules _instance;

  final TRes Function(Query$UserAccess$userAccess$rules) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? key = _undefined,
    Object? effect = _undefined,
    Object? scope = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$UserAccess$userAccess$rules(
      key: key == _undefined || key == null ? _instance.key : (key as String),
      effect: effect == _undefined || effect == null
          ? _instance.effect
          : (effect as String),
      scope: scope == _undefined || scope == null
          ? _instance.scope
          : (scope as String),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$UserAccess$userAccess$rules<TRes>
    implements CopyWith$Query$UserAccess$userAccess$rules<TRes> {
  _CopyWithStubImpl$Query$UserAccess$userAccess$rules(this._res);

  TRes _res;

  call({String? key, String? effect, String? scope, String? $__typename}) =>
      _res;
}

class Query$UserAccess$userAccess$delegations {
  Query$UserAccess$userAccess$delegations({
    required this.key,
    required this.scope,
    this.$__typename = 'Delegation',
  });

  factory Query$UserAccess$userAccess$delegations.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$key = json['key'];
    final l$scope = json['scope'];
    final l$$__typename = json['__typename'];
    return Query$UserAccess$userAccess$delegations(
      key: (l$key as String),
      scope: (l$scope as String),
      $__typename: (l$$__typename as String),
    );
  }

  final String key;

  final String scope;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$key = key;
    _resultData['key'] = l$key;
    final l$scope = scope;
    _resultData['scope'] = l$scope;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$key = key;
    final l$scope = scope;
    final l$$__typename = $__typename;
    return Object.hashAll([l$key, l$scope, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$UserAccess$userAccess$delegations ||
        runtimeType != other.runtimeType) {
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
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$UserAccess$userAccess$delegations
    on Query$UserAccess$userAccess$delegations {
  CopyWith$Query$UserAccess$userAccess$delegations<
    Query$UserAccess$userAccess$delegations
  >
  get copyWith =>
      CopyWith$Query$UserAccess$userAccess$delegations(this, (i) => i);
}

abstract class CopyWith$Query$UserAccess$userAccess$delegations<TRes> {
  factory CopyWith$Query$UserAccess$userAccess$delegations(
    Query$UserAccess$userAccess$delegations instance,
    TRes Function(Query$UserAccess$userAccess$delegations) then,
  ) = _CopyWithImpl$Query$UserAccess$userAccess$delegations;

  factory CopyWith$Query$UserAccess$userAccess$delegations.stub(TRes res) =
      _CopyWithStubImpl$Query$UserAccess$userAccess$delegations;

  TRes call({String? key, String? scope, String? $__typename});
}

class _CopyWithImpl$Query$UserAccess$userAccess$delegations<TRes>
    implements CopyWith$Query$UserAccess$userAccess$delegations<TRes> {
  _CopyWithImpl$Query$UserAccess$userAccess$delegations(
    this._instance,
    this._then,
  );

  final Query$UserAccess$userAccess$delegations _instance;

  final TRes Function(Query$UserAccess$userAccess$delegations) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? key = _undefined,
    Object? scope = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$UserAccess$userAccess$delegations(
      key: key == _undefined || key == null ? _instance.key : (key as String),
      scope: scope == _undefined || scope == null
          ? _instance.scope
          : (scope as String),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$UserAccess$userAccess$delegations<TRes>
    implements CopyWith$Query$UserAccess$userAccess$delegations<TRes> {
  _CopyWithStubImpl$Query$UserAccess$userAccess$delegations(this._res);

  TRes _res;

  call({String? key, String? scope, String? $__typename}) => _res;
}

class Query$UserAccess$userAccess$effective {
  Query$UserAccess$userAccess$effective({
    required this.key,
    required this.decision,
    this.$__typename = 'EffectivePermission',
  });

  factory Query$UserAccess$userAccess$effective.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$key = json['key'];
    final l$decision = json['decision'];
    final l$$__typename = json['__typename'];
    return Query$UserAccess$userAccess$effective(
      key: (l$key as String),
      decision: Fragment$DecisionFields.fromJson(
        (l$decision as Map<String, dynamic>),
      ),
      $__typename: (l$$__typename as String),
    );
  }

  final String key;

  final Fragment$DecisionFields decision;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$key = key;
    _resultData['key'] = l$key;
    final l$decision = decision;
    _resultData['decision'] = l$decision.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$key = key;
    final l$decision = decision;
    final l$$__typename = $__typename;
    return Object.hashAll([l$key, l$decision, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$UserAccess$userAccess$effective ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$key = key;
    final lOther$key = other.key;
    if (l$key != lOther$key) {
      return false;
    }
    final l$decision = decision;
    final lOther$decision = other.decision;
    if (l$decision != lOther$decision) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$UserAccess$userAccess$effective
    on Query$UserAccess$userAccess$effective {
  CopyWith$Query$UserAccess$userAccess$effective<
    Query$UserAccess$userAccess$effective
  >
  get copyWith =>
      CopyWith$Query$UserAccess$userAccess$effective(this, (i) => i);
}

abstract class CopyWith$Query$UserAccess$userAccess$effective<TRes> {
  factory CopyWith$Query$UserAccess$userAccess$effective(
    Query$UserAccess$userAccess$effective instance,
    TRes Function(Query$UserAccess$userAccess$effective) then,
  ) = _CopyWithImpl$Query$UserAccess$userAccess$effective;

  factory CopyWith$Query$UserAccess$userAccess$effective.stub(TRes res) =
      _CopyWithStubImpl$Query$UserAccess$userAccess$effective;

  TRes call({
    String? key,
    Fragment$DecisionFields? decision,
    String? $__typename,
  });
  CopyWith$Fragment$DecisionFields<TRes> get decision;
}

class _CopyWithImpl$Query$UserAccess$userAccess$effective<TRes>
    implements CopyWith$Query$UserAccess$userAccess$effective<TRes> {
  _CopyWithImpl$Query$UserAccess$userAccess$effective(
    this._instance,
    this._then,
  );

  final Query$UserAccess$userAccess$effective _instance;

  final TRes Function(Query$UserAccess$userAccess$effective) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? key = _undefined,
    Object? decision = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$UserAccess$userAccess$effective(
      key: key == _undefined || key == null ? _instance.key : (key as String),
      decision: decision == _undefined || decision == null
          ? _instance.decision
          : (decision as Fragment$DecisionFields),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Fragment$DecisionFields<TRes> get decision {
    final local$decision = _instance.decision;
    return CopyWith$Fragment$DecisionFields(
      local$decision,
      (e) => call(decision: e),
    );
  }
}

class _CopyWithStubImpl$Query$UserAccess$userAccess$effective<TRes>
    implements CopyWith$Query$UserAccess$userAccess$effective<TRes> {
  _CopyWithStubImpl$Query$UserAccess$userAccess$effective(this._res);

  TRes _res;

  call({String? key, Fragment$DecisionFields? decision, String? $__typename}) =>
      _res;

  CopyWith$Fragment$DecisionFields<TRes> get decision =>
      CopyWith$Fragment$DecisionFields.stub(_res);
}

class Query$UserAccess$userAccess$audit {
  Query$UserAccess$userAccess$audit({
    required this.id,
    required this.actorId,
    required this.createdAt,
    required this.reason,
    required this.version,
    required this.changes,
    this.$__typename = 'AccessAudit',
  });

  factory Query$UserAccess$userAccess$audit.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$id = json['id'];
    final l$actorId = json['actorId'];
    final l$createdAt = json['createdAt'];
    final l$reason = json['reason'];
    final l$version = json['version'];
    final l$changes = json['changes'];
    final l$$__typename = json['__typename'];
    return Query$UserAccess$userAccess$audit(
      id: (l$id as String),
      actorId: (l$actorId as String),
      createdAt: (l$createdAt as String),
      reason: (l$reason as String),
      version: (l$version as int),
      changes: (l$changes as List<dynamic>)
          .map(
            (e) => Fragment$ChangeFields.fromJson((e as Map<String, dynamic>)),
          )
          .toList(),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String actorId;

  final String createdAt;

  final String reason;

  final int version;

  final List<Fragment$ChangeFields> changes;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$actorId = actorId;
    _resultData['actorId'] = l$actorId;
    final l$createdAt = createdAt;
    _resultData['createdAt'] = l$createdAt;
    final l$reason = reason;
    _resultData['reason'] = l$reason;
    final l$version = version;
    _resultData['version'] = l$version;
    final l$changes = changes;
    _resultData['changes'] = l$changes.map((e) => e.toJson()).toList();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$actorId = actorId;
    final l$createdAt = createdAt;
    final l$reason = reason;
    final l$version = version;
    final l$changes = changes;
    final l$$__typename = $__typename;
    return Object.hashAll([
      l$id,
      l$actorId,
      l$createdAt,
      l$reason,
      l$version,
      Object.hashAll(l$changes.map((v) => v)),
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$UserAccess$userAccess$audit ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$actorId = actorId;
    final lOther$actorId = other.actorId;
    if (l$actorId != lOther$actorId) {
      return false;
    }
    final l$createdAt = createdAt;
    final lOther$createdAt = other.createdAt;
    if (l$createdAt != lOther$createdAt) {
      return false;
    }
    final l$reason = reason;
    final lOther$reason = other.reason;
    if (l$reason != lOther$reason) {
      return false;
    }
    final l$version = version;
    final lOther$version = other.version;
    if (l$version != lOther$version) {
      return false;
    }
    final l$changes = changes;
    final lOther$changes = other.changes;
    if (l$changes.length != lOther$changes.length) {
      return false;
    }
    for (int i = 0; i < l$changes.length; i++) {
      final l$changes$entry = l$changes[i];
      final lOther$changes$entry = lOther$changes[i];
      if (l$changes$entry != lOther$changes$entry) {
        return false;
      }
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$UserAccess$userAccess$audit
    on Query$UserAccess$userAccess$audit {
  CopyWith$Query$UserAccess$userAccess$audit<Query$UserAccess$userAccess$audit>
  get copyWith => CopyWith$Query$UserAccess$userAccess$audit(this, (i) => i);
}

abstract class CopyWith$Query$UserAccess$userAccess$audit<TRes> {
  factory CopyWith$Query$UserAccess$userAccess$audit(
    Query$UserAccess$userAccess$audit instance,
    TRes Function(Query$UserAccess$userAccess$audit) then,
  ) = _CopyWithImpl$Query$UserAccess$userAccess$audit;

  factory CopyWith$Query$UserAccess$userAccess$audit.stub(TRes res) =
      _CopyWithStubImpl$Query$UserAccess$userAccess$audit;

  TRes call({
    String? id,
    String? actorId,
    String? createdAt,
    String? reason,
    int? version,
    List<Fragment$ChangeFields>? changes,
    String? $__typename,
  });
  TRes changes(
    Iterable<Fragment$ChangeFields> Function(
      Iterable<CopyWith$Fragment$ChangeFields<Fragment$ChangeFields>>,
    )
    _fn,
  );
}

class _CopyWithImpl$Query$UserAccess$userAccess$audit<TRes>
    implements CopyWith$Query$UserAccess$userAccess$audit<TRes> {
  _CopyWithImpl$Query$UserAccess$userAccess$audit(this._instance, this._then);

  final Query$UserAccess$userAccess$audit _instance;

  final TRes Function(Query$UserAccess$userAccess$audit) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? actorId = _undefined,
    Object? createdAt = _undefined,
    Object? reason = _undefined,
    Object? version = _undefined,
    Object? changes = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$UserAccess$userAccess$audit(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      actorId: actorId == _undefined || actorId == null
          ? _instance.actorId
          : (actorId as String),
      createdAt: createdAt == _undefined || createdAt == null
          ? _instance.createdAt
          : (createdAt as String),
      reason: reason == _undefined || reason == null
          ? _instance.reason
          : (reason as String),
      version: version == _undefined || version == null
          ? _instance.version
          : (version as int),
      changes: changes == _undefined || changes == null
          ? _instance.changes
          : (changes as List<Fragment$ChangeFields>),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  TRes changes(
    Iterable<Fragment$ChangeFields> Function(
      Iterable<CopyWith$Fragment$ChangeFields<Fragment$ChangeFields>>,
    )
    _fn,
  ) => call(
    changes: _fn(
      _instance.changes.map((e) => CopyWith$Fragment$ChangeFields(e, (i) => i)),
    ).toList(),
  );
}

class _CopyWithStubImpl$Query$UserAccess$userAccess$audit<TRes>
    implements CopyWith$Query$UserAccess$userAccess$audit<TRes> {
  _CopyWithStubImpl$Query$UserAccess$userAccess$audit(this._res);

  TRes _res;

  call({
    String? id,
    String? actorId,
    String? createdAt,
    String? reason,
    int? version,
    List<Fragment$ChangeFields>? changes,
    String? $__typename,
  }) => _res;

  changes(_fn) => _res;
}

class Variables$Mutation$PreviewAccess {
  factory Variables$Mutation$PreviewAccess({
    required String siteId,
    required String userId,
    required Input$AccessChangeInput input,
  }) => Variables$Mutation$PreviewAccess._({
    r'siteId': siteId,
    r'userId': userId,
    r'input': input,
  });

  Variables$Mutation$PreviewAccess._(this._$data);

  factory Variables$Mutation$PreviewAccess.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    final l$userId = data['userId'];
    result$data['userId'] = (l$userId as String);
    final l$input = data['input'];
    result$data['input'] = Input$AccessChangeInput.fromJson(
      (l$input as Map<String, dynamic>),
    );
    return Variables$Mutation$PreviewAccess._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  String get userId => (_$data['userId'] as String);

  Input$AccessChangeInput get input =>
      (_$data['input'] as Input$AccessChangeInput);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    final l$userId = userId;
    result$data['userId'] = l$userId;
    final l$input = input;
    result$data['input'] = l$input.toJson();
    return result$data;
  }

  CopyWith$Variables$Mutation$PreviewAccess<Variables$Mutation$PreviewAccess>
  get copyWith => CopyWith$Variables$Mutation$PreviewAccess(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Mutation$PreviewAccess ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    final l$userId = userId;
    final lOther$userId = other.userId;
    if (l$userId != lOther$userId) {
      return false;
    }
    final l$input = input;
    final lOther$input = other.input;
    if (l$input != lOther$input) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    final l$userId = userId;
    final l$input = input;
    return Object.hashAll([l$siteId, l$userId, l$input]);
  }
}

abstract class CopyWith$Variables$Mutation$PreviewAccess<TRes> {
  factory CopyWith$Variables$Mutation$PreviewAccess(
    Variables$Mutation$PreviewAccess instance,
    TRes Function(Variables$Mutation$PreviewAccess) then,
  ) = _CopyWithImpl$Variables$Mutation$PreviewAccess;

  factory CopyWith$Variables$Mutation$PreviewAccess.stub(TRes res) =
      _CopyWithStubImpl$Variables$Mutation$PreviewAccess;

  TRes call({String? siteId, String? userId, Input$AccessChangeInput? input});
}

class _CopyWithImpl$Variables$Mutation$PreviewAccess<TRes>
    implements CopyWith$Variables$Mutation$PreviewAccess<TRes> {
  _CopyWithImpl$Variables$Mutation$PreviewAccess(this._instance, this._then);

  final Variables$Mutation$PreviewAccess _instance;

  final TRes Function(Variables$Mutation$PreviewAccess) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? siteId = _undefined,
    Object? userId = _undefined,
    Object? input = _undefined,
  }) => _then(
    Variables$Mutation$PreviewAccess._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
      if (userId != _undefined && userId != null) 'userId': (userId as String),
      if (input != _undefined && input != null)
        'input': (input as Input$AccessChangeInput),
    }),
  );
}

class _CopyWithStubImpl$Variables$Mutation$PreviewAccess<TRes>
    implements CopyWith$Variables$Mutation$PreviewAccess<TRes> {
  _CopyWithStubImpl$Variables$Mutation$PreviewAccess(this._res);

  TRes _res;

  call({String? siteId, String? userId, Input$AccessChangeInput? input}) =>
      _res;
}

class Mutation$PreviewAccess {
  Mutation$PreviewAccess({
    required this.previewAccess,
    this.$__typename = 'Mutation',
  });

  factory Mutation$PreviewAccess.fromJson(Map<String, dynamic> json) {
    final l$previewAccess = json['previewAccess'];
    final l$$__typename = json['__typename'];
    return Mutation$PreviewAccess(
      previewAccess: Mutation$PreviewAccess$previewAccess.fromJson(
        (l$previewAccess as Map<String, dynamic>),
      ),
      $__typename: (l$$__typename as String),
    );
  }

  final Mutation$PreviewAccess$previewAccess previewAccess;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$previewAccess = previewAccess;
    _resultData['previewAccess'] = l$previewAccess.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$previewAccess = previewAccess;
    final l$$__typename = $__typename;
    return Object.hashAll([l$previewAccess, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Mutation$PreviewAccess || runtimeType != other.runtimeType) {
      return false;
    }
    final l$previewAccess = previewAccess;
    final lOther$previewAccess = other.previewAccess;
    if (l$previewAccess != lOther$previewAccess) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Mutation$PreviewAccess on Mutation$PreviewAccess {
  CopyWith$Mutation$PreviewAccess<Mutation$PreviewAccess> get copyWith =>
      CopyWith$Mutation$PreviewAccess(this, (i) => i);
}

abstract class CopyWith$Mutation$PreviewAccess<TRes> {
  factory CopyWith$Mutation$PreviewAccess(
    Mutation$PreviewAccess instance,
    TRes Function(Mutation$PreviewAccess) then,
  ) = _CopyWithImpl$Mutation$PreviewAccess;

  factory CopyWith$Mutation$PreviewAccess.stub(TRes res) =
      _CopyWithStubImpl$Mutation$PreviewAccess;

  TRes call({
    Mutation$PreviewAccess$previewAccess? previewAccess,
    String? $__typename,
  });
  CopyWith$Mutation$PreviewAccess$previewAccess<TRes> get previewAccess;
}

class _CopyWithImpl$Mutation$PreviewAccess<TRes>
    implements CopyWith$Mutation$PreviewAccess<TRes> {
  _CopyWithImpl$Mutation$PreviewAccess(this._instance, this._then);

  final Mutation$PreviewAccess _instance;

  final TRes Function(Mutation$PreviewAccess) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? previewAccess = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Mutation$PreviewAccess(
      previewAccess: previewAccess == _undefined || previewAccess == null
          ? _instance.previewAccess
          : (previewAccess as Mutation$PreviewAccess$previewAccess),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Mutation$PreviewAccess$previewAccess<TRes> get previewAccess {
    final local$previewAccess = _instance.previewAccess;
    return CopyWith$Mutation$PreviewAccess$previewAccess(
      local$previewAccess,
      (e) => call(previewAccess: e),
    );
  }
}

class _CopyWithStubImpl$Mutation$PreviewAccess<TRes>
    implements CopyWith$Mutation$PreviewAccess<TRes> {
  _CopyWithStubImpl$Mutation$PreviewAccess(this._res);

  TRes _res;

  call({
    Mutation$PreviewAccess$previewAccess? previewAccess,
    String? $__typename,
  }) => _res;

  CopyWith$Mutation$PreviewAccess$previewAccess<TRes> get previewAccess =>
      CopyWith$Mutation$PreviewAccess$previewAccess.stub(_res);
}

const documentNodeMutationPreviewAccess = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.mutation,
      name: NameNode(value: 'PreviewAccess'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'userId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'input')),
          type: NamedTypeNode(
            name: NameNode(value: 'AccessChangeInput'),
            isNonNull: true,
          ),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'previewAccess'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'userId'),
                value: VariableNode(name: NameNode(value: 'userId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'input'),
                value: VariableNode(name: NameNode(value: 'input')),
              ),
            ],
            directives: [],
            selectionSet: SelectionSetNode(
              selections: [
                FieldNode(
                  name: NameNode(value: 'version'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'changes'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FragmentSpreadNode(
                        name: NameNode(value: 'ChangeFields'),
                        directives: [],
                      ),
                      FieldNode(
                        name: NameNode(value: '__typename'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                    ],
                  ),
                ),
                FieldNode(
                  name: NameNode(value: '__typename'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
              ],
            ),
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
    fragmentDefinitionChangeFields,
    fragmentDefinitionDecisionFields,
  ],
);
Mutation$PreviewAccess _parserFn$Mutation$PreviewAccess(
  Map<String, dynamic> data,
) => Mutation$PreviewAccess.fromJson(data);
typedef OnMutationCompleted$Mutation$PreviewAccess = FutureOr<void> Function(
  Map<String, dynamic>?,
  Mutation$PreviewAccess?,
);

class Options$Mutation$PreviewAccess
    extends graphql.MutationOptions<Mutation$PreviewAccess> {
  Options$Mutation$PreviewAccess({
    String? operationName,
    required Variables$Mutation$PreviewAccess variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Mutation$PreviewAccess? typedOptimisticResult,
    graphql.Context? context,
    OnMutationCompleted$Mutation$PreviewAccess? onCompleted,
    graphql.OnMutationUpdate<Mutation$PreviewAccess>? update,
    graphql.OnError? onError,
  }) : onCompletedWithParsed = onCompleted,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         onCompleted: onCompleted == null
             ? null
             : (data) => onCompleted(
                 data,
                 data == null ? null : _parserFn$Mutation$PreviewAccess(data),
               ),
         update: update,
         onError: onError,
         document: documentNodeMutationPreviewAccess,
         parserFn: _parserFn$Mutation$PreviewAccess,
       );

  final OnMutationCompleted$Mutation$PreviewAccess? onCompletedWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onCompleted == null
        ? super.properties
        : super.properties.where((property) => property != onCompleted),
    onCompletedWithParsed,
  ];
}

class WatchOptions$Mutation$PreviewAccess
    extends graphql.WatchQueryOptions<Mutation$PreviewAccess> {
  WatchOptions$Mutation$PreviewAccess({
    String? operationName,
    required Variables$Mutation$PreviewAccess variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Mutation$PreviewAccess? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeMutationPreviewAccess,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Mutation$PreviewAccess,
       );
}

extension ClientExtension$Mutation$PreviewAccess on graphql.GraphQLClient {
  Future<graphql.QueryResult<Mutation$PreviewAccess>> mutate$PreviewAccess(
    Options$Mutation$PreviewAccess options,
  ) async => await this.mutate(options);

  graphql.ObservableQuery<Mutation$PreviewAccess> watchMutation$PreviewAccess(
    WatchOptions$Mutation$PreviewAccess options,
  ) => this.watchMutation(options);
}

class Mutation$PreviewAccess$previewAccess {
  Mutation$PreviewAccess$previewAccess({
    required this.version,
    required this.changes,
    this.$__typename = 'AccessChangeResult',
  });

  factory Mutation$PreviewAccess$previewAccess.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$version = json['version'];
    final l$changes = json['changes'];
    final l$$__typename = json['__typename'];
    return Mutation$PreviewAccess$previewAccess(
      version: (l$version as int),
      changes: (l$changes as List<dynamic>)
          .map(
            (e) => Fragment$ChangeFields.fromJson((e as Map<String, dynamic>)),
          )
          .toList(),
      $__typename: (l$$__typename as String),
    );
  }

  final int version;

  final List<Fragment$ChangeFields> changes;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$version = version;
    _resultData['version'] = l$version;
    final l$changes = changes;
    _resultData['changes'] = l$changes.map((e) => e.toJson()).toList();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$version = version;
    final l$changes = changes;
    final l$$__typename = $__typename;
    return Object.hashAll([
      l$version,
      Object.hashAll(l$changes.map((v) => v)),
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Mutation$PreviewAccess$previewAccess ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$version = version;
    final lOther$version = other.version;
    if (l$version != lOther$version) {
      return false;
    }
    final l$changes = changes;
    final lOther$changes = other.changes;
    if (l$changes.length != lOther$changes.length) {
      return false;
    }
    for (int i = 0; i < l$changes.length; i++) {
      final l$changes$entry = l$changes[i];
      final lOther$changes$entry = lOther$changes[i];
      if (l$changes$entry != lOther$changes$entry) {
        return false;
      }
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Mutation$PreviewAccess$previewAccess
    on Mutation$PreviewAccess$previewAccess {
  CopyWith$Mutation$PreviewAccess$previewAccess<
    Mutation$PreviewAccess$previewAccess
  >
  get copyWith => CopyWith$Mutation$PreviewAccess$previewAccess(this, (i) => i);
}

abstract class CopyWith$Mutation$PreviewAccess$previewAccess<TRes> {
  factory CopyWith$Mutation$PreviewAccess$previewAccess(
    Mutation$PreviewAccess$previewAccess instance,
    TRes Function(Mutation$PreviewAccess$previewAccess) then,
  ) = _CopyWithImpl$Mutation$PreviewAccess$previewAccess;

  factory CopyWith$Mutation$PreviewAccess$previewAccess.stub(TRes res) =
      _CopyWithStubImpl$Mutation$PreviewAccess$previewAccess;

  TRes call({
    int? version,
    List<Fragment$ChangeFields>? changes,
    String? $__typename,
  });
  TRes changes(
    Iterable<Fragment$ChangeFields> Function(
      Iterable<CopyWith$Fragment$ChangeFields<Fragment$ChangeFields>>,
    )
    _fn,
  );
}

class _CopyWithImpl$Mutation$PreviewAccess$previewAccess<TRes>
    implements CopyWith$Mutation$PreviewAccess$previewAccess<TRes> {
  _CopyWithImpl$Mutation$PreviewAccess$previewAccess(
    this._instance,
    this._then,
  );

  final Mutation$PreviewAccess$previewAccess _instance;

  final TRes Function(Mutation$PreviewAccess$previewAccess) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? version = _undefined,
    Object? changes = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Mutation$PreviewAccess$previewAccess(
      version: version == _undefined || version == null
          ? _instance.version
          : (version as int),
      changes: changes == _undefined || changes == null
          ? _instance.changes
          : (changes as List<Fragment$ChangeFields>),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  TRes changes(
    Iterable<Fragment$ChangeFields> Function(
      Iterable<CopyWith$Fragment$ChangeFields<Fragment$ChangeFields>>,
    )
    _fn,
  ) => call(
    changes: _fn(
      _instance.changes.map((e) => CopyWith$Fragment$ChangeFields(e, (i) => i)),
    ).toList(),
  );
}

class _CopyWithStubImpl$Mutation$PreviewAccess$previewAccess<TRes>
    implements CopyWith$Mutation$PreviewAccess$previewAccess<TRes> {
  _CopyWithStubImpl$Mutation$PreviewAccess$previewAccess(this._res);

  TRes _res;

  call({
    int? version,
    List<Fragment$ChangeFields>? changes,
    String? $__typename,
  }) => _res;

  changes(_fn) => _res;
}

class Variables$Mutation$SaveAccess {
  factory Variables$Mutation$SaveAccess({
    required String siteId,
    required String userId,
    required Input$AccessChangeInput input,
  }) => Variables$Mutation$SaveAccess._({
    r'siteId': siteId,
    r'userId': userId,
    r'input': input,
  });

  Variables$Mutation$SaveAccess._(this._$data);

  factory Variables$Mutation$SaveAccess.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    final l$userId = data['userId'];
    result$data['userId'] = (l$userId as String);
    final l$input = data['input'];
    result$data['input'] = Input$AccessChangeInput.fromJson(
      (l$input as Map<String, dynamic>),
    );
    return Variables$Mutation$SaveAccess._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  String get userId => (_$data['userId'] as String);

  Input$AccessChangeInput get input =>
      (_$data['input'] as Input$AccessChangeInput);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    final l$userId = userId;
    result$data['userId'] = l$userId;
    final l$input = input;
    result$data['input'] = l$input.toJson();
    return result$data;
  }

  CopyWith$Variables$Mutation$SaveAccess<Variables$Mutation$SaveAccess>
  get copyWith => CopyWith$Variables$Mutation$SaveAccess(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Mutation$SaveAccess ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    final l$userId = userId;
    final lOther$userId = other.userId;
    if (l$userId != lOther$userId) {
      return false;
    }
    final l$input = input;
    final lOther$input = other.input;
    if (l$input != lOther$input) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    final l$userId = userId;
    final l$input = input;
    return Object.hashAll([l$siteId, l$userId, l$input]);
  }
}

abstract class CopyWith$Variables$Mutation$SaveAccess<TRes> {
  factory CopyWith$Variables$Mutation$SaveAccess(
    Variables$Mutation$SaveAccess instance,
    TRes Function(Variables$Mutation$SaveAccess) then,
  ) = _CopyWithImpl$Variables$Mutation$SaveAccess;

  factory CopyWith$Variables$Mutation$SaveAccess.stub(TRes res) =
      _CopyWithStubImpl$Variables$Mutation$SaveAccess;

  TRes call({String? siteId, String? userId, Input$AccessChangeInput? input});
}

class _CopyWithImpl$Variables$Mutation$SaveAccess<TRes>
    implements CopyWith$Variables$Mutation$SaveAccess<TRes> {
  _CopyWithImpl$Variables$Mutation$SaveAccess(this._instance, this._then);

  final Variables$Mutation$SaveAccess _instance;

  final TRes Function(Variables$Mutation$SaveAccess) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? siteId = _undefined,
    Object? userId = _undefined,
    Object? input = _undefined,
  }) => _then(
    Variables$Mutation$SaveAccess._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
      if (userId != _undefined && userId != null) 'userId': (userId as String),
      if (input != _undefined && input != null)
        'input': (input as Input$AccessChangeInput),
    }),
  );
}

class _CopyWithStubImpl$Variables$Mutation$SaveAccess<TRes>
    implements CopyWith$Variables$Mutation$SaveAccess<TRes> {
  _CopyWithStubImpl$Variables$Mutation$SaveAccess(this._res);

  TRes _res;

  call({String? siteId, String? userId, Input$AccessChangeInput? input}) =>
      _res;
}

class Mutation$SaveAccess {
  Mutation$SaveAccess({
    required this.saveAccess,
    this.$__typename = 'Mutation',
  });

  factory Mutation$SaveAccess.fromJson(Map<String, dynamic> json) {
    final l$saveAccess = json['saveAccess'];
    final l$$__typename = json['__typename'];
    return Mutation$SaveAccess(
      saveAccess: Mutation$SaveAccess$saveAccess.fromJson(
        (l$saveAccess as Map<String, dynamic>),
      ),
      $__typename: (l$$__typename as String),
    );
  }

  final Mutation$SaveAccess$saveAccess saveAccess;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$saveAccess = saveAccess;
    _resultData['saveAccess'] = l$saveAccess.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$saveAccess = saveAccess;
    final l$$__typename = $__typename;
    return Object.hashAll([l$saveAccess, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Mutation$SaveAccess || runtimeType != other.runtimeType) {
      return false;
    }
    final l$saveAccess = saveAccess;
    final lOther$saveAccess = other.saveAccess;
    if (l$saveAccess != lOther$saveAccess) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Mutation$SaveAccess on Mutation$SaveAccess {
  CopyWith$Mutation$SaveAccess<Mutation$SaveAccess> get copyWith =>
      CopyWith$Mutation$SaveAccess(this, (i) => i);
}

abstract class CopyWith$Mutation$SaveAccess<TRes> {
  factory CopyWith$Mutation$SaveAccess(
    Mutation$SaveAccess instance,
    TRes Function(Mutation$SaveAccess) then,
  ) = _CopyWithImpl$Mutation$SaveAccess;

  factory CopyWith$Mutation$SaveAccess.stub(TRes res) =
      _CopyWithStubImpl$Mutation$SaveAccess;

  TRes call({Mutation$SaveAccess$saveAccess? saveAccess, String? $__typename});
  CopyWith$Mutation$SaveAccess$saveAccess<TRes> get saveAccess;
}

class _CopyWithImpl$Mutation$SaveAccess<TRes>
    implements CopyWith$Mutation$SaveAccess<TRes> {
  _CopyWithImpl$Mutation$SaveAccess(this._instance, this._then);

  final Mutation$SaveAccess _instance;

  final TRes Function(Mutation$SaveAccess) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? saveAccess = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Mutation$SaveAccess(
      saveAccess: saveAccess == _undefined || saveAccess == null
          ? _instance.saveAccess
          : (saveAccess as Mutation$SaveAccess$saveAccess),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Mutation$SaveAccess$saveAccess<TRes> get saveAccess {
    final local$saveAccess = _instance.saveAccess;
    return CopyWith$Mutation$SaveAccess$saveAccess(
      local$saveAccess,
      (e) => call(saveAccess: e),
    );
  }
}

class _CopyWithStubImpl$Mutation$SaveAccess<TRes>
    implements CopyWith$Mutation$SaveAccess<TRes> {
  _CopyWithStubImpl$Mutation$SaveAccess(this._res);

  TRes _res;

  call({Mutation$SaveAccess$saveAccess? saveAccess, String? $__typename}) =>
      _res;

  CopyWith$Mutation$SaveAccess$saveAccess<TRes> get saveAccess =>
      CopyWith$Mutation$SaveAccess$saveAccess.stub(_res);
}

const documentNodeMutationSaveAccess = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.mutation,
      name: NameNode(value: 'SaveAccess'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'userId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'input')),
          type: NamedTypeNode(
            name: NameNode(value: 'AccessChangeInput'),
            isNonNull: true,
          ),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'saveAccess'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'userId'),
                value: VariableNode(name: NameNode(value: 'userId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'input'),
                value: VariableNode(name: NameNode(value: 'input')),
              ),
            ],
            directives: [],
            selectionSet: SelectionSetNode(
              selections: [
                FieldNode(
                  name: NameNode(value: 'version'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'changes'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FragmentSpreadNode(
                        name: NameNode(value: 'ChangeFields'),
                        directives: [],
                      ),
                      FieldNode(
                        name: NameNode(value: '__typename'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                    ],
                  ),
                ),
                FieldNode(
                  name: NameNode(value: '__typename'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
              ],
            ),
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
    fragmentDefinitionChangeFields,
    fragmentDefinitionDecisionFields,
  ],
);
Mutation$SaveAccess _parserFn$Mutation$SaveAccess(Map<String, dynamic> data) =>
    Mutation$SaveAccess.fromJson(data);
typedef OnMutationCompleted$Mutation$SaveAccess = FutureOr<void> Function(
  Map<String, dynamic>?,
  Mutation$SaveAccess?,
);

class Options$Mutation$SaveAccess
    extends graphql.MutationOptions<Mutation$SaveAccess> {
  Options$Mutation$SaveAccess({
    String? operationName,
    required Variables$Mutation$SaveAccess variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Mutation$SaveAccess? typedOptimisticResult,
    graphql.Context? context,
    OnMutationCompleted$Mutation$SaveAccess? onCompleted,
    graphql.OnMutationUpdate<Mutation$SaveAccess>? update,
    graphql.OnError? onError,
  }) : onCompletedWithParsed = onCompleted,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         onCompleted: onCompleted == null
             ? null
             : (data) => onCompleted(
                 data,
                 data == null ? null : _parserFn$Mutation$SaveAccess(data),
               ),
         update: update,
         onError: onError,
         document: documentNodeMutationSaveAccess,
         parserFn: _parserFn$Mutation$SaveAccess,
       );

  final OnMutationCompleted$Mutation$SaveAccess? onCompletedWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onCompleted == null
        ? super.properties
        : super.properties.where((property) => property != onCompleted),
    onCompletedWithParsed,
  ];
}

class WatchOptions$Mutation$SaveAccess
    extends graphql.WatchQueryOptions<Mutation$SaveAccess> {
  WatchOptions$Mutation$SaveAccess({
    String? operationName,
    required Variables$Mutation$SaveAccess variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Mutation$SaveAccess? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeMutationSaveAccess,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Mutation$SaveAccess,
       );
}

extension ClientExtension$Mutation$SaveAccess on graphql.GraphQLClient {
  Future<graphql.QueryResult<Mutation$SaveAccess>> mutate$SaveAccess(
    Options$Mutation$SaveAccess options,
  ) async => await this.mutate(options);

  graphql.ObservableQuery<Mutation$SaveAccess> watchMutation$SaveAccess(
    WatchOptions$Mutation$SaveAccess options,
  ) => this.watchMutation(options);
}

class Mutation$SaveAccess$saveAccess {
  Mutation$SaveAccess$saveAccess({
    required this.version,
    required this.changes,
    this.$__typename = 'AccessChangeResult',
  });

  factory Mutation$SaveAccess$saveAccess.fromJson(Map<String, dynamic> json) {
    final l$version = json['version'];
    final l$changes = json['changes'];
    final l$$__typename = json['__typename'];
    return Mutation$SaveAccess$saveAccess(
      version: (l$version as int),
      changes: (l$changes as List<dynamic>)
          .map(
            (e) => Fragment$ChangeFields.fromJson((e as Map<String, dynamic>)),
          )
          .toList(),
      $__typename: (l$$__typename as String),
    );
  }

  final int version;

  final List<Fragment$ChangeFields> changes;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$version = version;
    _resultData['version'] = l$version;
    final l$changes = changes;
    _resultData['changes'] = l$changes.map((e) => e.toJson()).toList();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$version = version;
    final l$changes = changes;
    final l$$__typename = $__typename;
    return Object.hashAll([
      l$version,
      Object.hashAll(l$changes.map((v) => v)),
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Mutation$SaveAccess$saveAccess ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$version = version;
    final lOther$version = other.version;
    if (l$version != lOther$version) {
      return false;
    }
    final l$changes = changes;
    final lOther$changes = other.changes;
    if (l$changes.length != lOther$changes.length) {
      return false;
    }
    for (int i = 0; i < l$changes.length; i++) {
      final l$changes$entry = l$changes[i];
      final lOther$changes$entry = lOther$changes[i];
      if (l$changes$entry != lOther$changes$entry) {
        return false;
      }
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Mutation$SaveAccess$saveAccess
    on Mutation$SaveAccess$saveAccess {
  CopyWith$Mutation$SaveAccess$saveAccess<Mutation$SaveAccess$saveAccess>
  get copyWith => CopyWith$Mutation$SaveAccess$saveAccess(this, (i) => i);
}

abstract class CopyWith$Mutation$SaveAccess$saveAccess<TRes> {
  factory CopyWith$Mutation$SaveAccess$saveAccess(
    Mutation$SaveAccess$saveAccess instance,
    TRes Function(Mutation$SaveAccess$saveAccess) then,
  ) = _CopyWithImpl$Mutation$SaveAccess$saveAccess;

  factory CopyWith$Mutation$SaveAccess$saveAccess.stub(TRes res) =
      _CopyWithStubImpl$Mutation$SaveAccess$saveAccess;

  TRes call({
    int? version,
    List<Fragment$ChangeFields>? changes,
    String? $__typename,
  });
  TRes changes(
    Iterable<Fragment$ChangeFields> Function(
      Iterable<CopyWith$Fragment$ChangeFields<Fragment$ChangeFields>>,
    )
    _fn,
  );
}

class _CopyWithImpl$Mutation$SaveAccess$saveAccess<TRes>
    implements CopyWith$Mutation$SaveAccess$saveAccess<TRes> {
  _CopyWithImpl$Mutation$SaveAccess$saveAccess(this._instance, this._then);

  final Mutation$SaveAccess$saveAccess _instance;

  final TRes Function(Mutation$SaveAccess$saveAccess) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? version = _undefined,
    Object? changes = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Mutation$SaveAccess$saveAccess(
      version: version == _undefined || version == null
          ? _instance.version
          : (version as int),
      changes: changes == _undefined || changes == null
          ? _instance.changes
          : (changes as List<Fragment$ChangeFields>),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  TRes changes(
    Iterable<Fragment$ChangeFields> Function(
      Iterable<CopyWith$Fragment$ChangeFields<Fragment$ChangeFields>>,
    )
    _fn,
  ) => call(
    changes: _fn(
      _instance.changes.map((e) => CopyWith$Fragment$ChangeFields(e, (i) => i)),
    ).toList(),
  );
}

class _CopyWithStubImpl$Mutation$SaveAccess$saveAccess<TRes>
    implements CopyWith$Mutation$SaveAccess$saveAccess<TRes> {
  _CopyWithStubImpl$Mutation$SaveAccess$saveAccess(this._res);

  TRes _res;

  call({
    int? version,
    List<Fragment$ChangeFields>? changes,
    String? $__typename,
  }) => _res;

  changes(_fn) => _res;
}

class Variables$Query$Foundation {
  factory Variables$Query$Foundation({required String siteId}) =>
      Variables$Query$Foundation._({r'siteId': siteId});

  Variables$Query$Foundation._(this._$data);

  factory Variables$Query$Foundation.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    return Variables$Query$Foundation._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    return result$data;
  }

  CopyWith$Variables$Query$Foundation<Variables$Query$Foundation>
  get copyWith => CopyWith$Variables$Query$Foundation(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$Foundation ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    return Object.hashAll([l$siteId]);
  }
}

abstract class CopyWith$Variables$Query$Foundation<TRes> {
  factory CopyWith$Variables$Query$Foundation(
    Variables$Query$Foundation instance,
    TRes Function(Variables$Query$Foundation) then,
  ) = _CopyWithImpl$Variables$Query$Foundation;

  factory CopyWith$Variables$Query$Foundation.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$Foundation;

  TRes call({String? siteId});
}

class _CopyWithImpl$Variables$Query$Foundation<TRes>
    implements CopyWith$Variables$Query$Foundation<TRes> {
  _CopyWithImpl$Variables$Query$Foundation(this._instance, this._then);

  final Variables$Query$Foundation _instance;

  final TRes Function(Variables$Query$Foundation) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? siteId = _undefined}) => _then(
    Variables$Query$Foundation._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
    }),
  );
}

class _CopyWithStubImpl$Variables$Query$Foundation<TRes>
    implements CopyWith$Variables$Query$Foundation<TRes> {
  _CopyWithStubImpl$Variables$Query$Foundation(this._res);

  TRes _res;

  call({String? siteId}) => _res;
}

class Query$Foundation {
  Query$Foundation({required this.foundation, this.$__typename = 'Query'});

  factory Query$Foundation.fromJson(Map<String, dynamic> json) {
    final l$foundation = json['foundation'];
    final l$$__typename = json['__typename'];
    return Query$Foundation(
      foundation: Query$Foundation$foundation.fromJson(
        (l$foundation as Map<String, dynamic>),
      ),
      $__typename: (l$$__typename as String),
    );
  }

  final Query$Foundation$foundation foundation;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$foundation = foundation;
    _resultData['foundation'] = l$foundation.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$foundation = foundation;
    final l$$__typename = $__typename;
    return Object.hashAll([l$foundation, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$Foundation || runtimeType != other.runtimeType) {
      return false;
    }
    final l$foundation = foundation;
    final lOther$foundation = other.foundation;
    if (l$foundation != lOther$foundation) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$Foundation on Query$Foundation {
  CopyWith$Query$Foundation<Query$Foundation> get copyWith =>
      CopyWith$Query$Foundation(this, (i) => i);
}

abstract class CopyWith$Query$Foundation<TRes> {
  factory CopyWith$Query$Foundation(
    Query$Foundation instance,
    TRes Function(Query$Foundation) then,
  ) = _CopyWithImpl$Query$Foundation;

  factory CopyWith$Query$Foundation.stub(TRes res) =
      _CopyWithStubImpl$Query$Foundation;

  TRes call({Query$Foundation$foundation? foundation, String? $__typename});
  CopyWith$Query$Foundation$foundation<TRes> get foundation;
}

class _CopyWithImpl$Query$Foundation<TRes>
    implements CopyWith$Query$Foundation<TRes> {
  _CopyWithImpl$Query$Foundation(this._instance, this._then);

  final Query$Foundation _instance;

  final TRes Function(Query$Foundation) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? foundation = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$Foundation(
      foundation: foundation == _undefined || foundation == null
          ? _instance.foundation
          : (foundation as Query$Foundation$foundation),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Query$Foundation$foundation<TRes> get foundation {
    final local$foundation = _instance.foundation;
    return CopyWith$Query$Foundation$foundation(
      local$foundation,
      (e) => call(foundation: e),
    );
  }
}

class _CopyWithStubImpl$Query$Foundation<TRes>
    implements CopyWith$Query$Foundation<TRes> {
  _CopyWithStubImpl$Query$Foundation(this._res);

  TRes _res;

  call({Query$Foundation$foundation? foundation, String? $__typename}) => _res;

  CopyWith$Query$Foundation$foundation<TRes> get foundation =>
      CopyWith$Query$Foundation$foundation.stub(_res);
}

const documentNodeQueryFoundation = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'Foundation'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'foundation'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
            ],
            directives: [],
            selectionSet: SelectionSetNode(
              selections: [
                FieldNode(
                  name: NameNode(value: 'settings'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FieldNode(
                        name: NameNode(value: 'id'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'name'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'timezone'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'weekStart'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'contactEmail'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'version'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: '__typename'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                    ],
                  ),
                ),
                FieldNode(
                  name: NameNode(value: 'references'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FieldNode(
                        name: NameNode(value: 'id'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'kind'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'name'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'active'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'version'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'startTime'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'endTime'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'date'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: '__typename'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                    ],
                  ),
                ),
                FieldNode(
                  name: NameNode(value: 'employers'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FieldNode(
                        name: NameNode(value: 'id'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'name'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: '__typename'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                    ],
                  ),
                ),
                FieldNode(
                  name: NameNode(value: 'managers'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FieldNode(
                        name: NameNode(value: 'id'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'name'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: '__typename'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                    ],
                  ),
                ),
                FieldNode(
                  name: NameNode(value: 'drafts'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FieldNode(
                        name: NameNode(value: 'id'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'displayName'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'employeeCode'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'workEmail'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'department'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'designation'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'startsOn'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'status'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'version'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'authorId'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'createdAt'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: '__typename'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                    ],
                  ),
                ),
                FieldNode(
                  name: NameNode(value: '__typename'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
              ],
            ),
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Query$Foundation _parserFn$Query$Foundation(Map<String, dynamic> data) =>
    Query$Foundation.fromJson(data);
typedef OnQueryComplete$Query$Foundation = FutureOr<void> Function(
  Map<String, dynamic>?,
  Query$Foundation?,
);

class Options$Query$Foundation extends graphql.QueryOptions<Query$Foundation> {
  Options$Query$Foundation({
    String? operationName,
    required Variables$Query$Foundation variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$Foundation? typedOptimisticResult,
    Duration? pollInterval,
    graphql.Context? context,
    OnQueryComplete$Query$Foundation? onComplete,
    graphql.OnQueryError? onError,
  }) : onCompleteWithParsed = onComplete,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         pollInterval: pollInterval,
         context: context,
         onComplete: onComplete == null
             ? null
             : (data) => onComplete(
                 data,
                 data == null ? null : _parserFn$Query$Foundation(data),
               ),
         onError: onError,
         document: documentNodeQueryFoundation,
         parserFn: _parserFn$Query$Foundation,
       );

  final OnQueryComplete$Query$Foundation? onCompleteWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onComplete == null
        ? super.properties
        : super.properties.where((property) => property != onComplete),
    onCompleteWithParsed,
  ];
}

class WatchOptions$Query$Foundation
    extends graphql.WatchQueryOptions<Query$Foundation> {
  WatchOptions$Query$Foundation({
    String? operationName,
    required Variables$Query$Foundation variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$Foundation? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeQueryFoundation,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Query$Foundation,
       );
}

class FetchMoreOptions$Query$Foundation extends graphql.FetchMoreOptions {
  FetchMoreOptions$Query$Foundation({
    required graphql.UpdateQuery updateQuery,
    required Variables$Query$Foundation variables,
  }) : super(
         updateQuery: updateQuery,
         variables: variables.toJson(),
         document: documentNodeQueryFoundation,
       );
}

extension ClientExtension$Query$Foundation on graphql.GraphQLClient {
  Future<graphql.QueryResult<Query$Foundation>> query$Foundation(
    Options$Query$Foundation options,
  ) async => await this.query(options);

  graphql.ObservableQuery<Query$Foundation> watchQuery$Foundation(
    WatchOptions$Query$Foundation options,
  ) => this.watchQuery(options);

  void writeQuery$Foundation({
    required Query$Foundation data,
    required Variables$Query$Foundation variables,
    bool broadcast = true,
  }) => this.writeQuery(
    graphql.Request(
      operation: graphql.Operation(document: documentNodeQueryFoundation),
      variables: variables.toJson(),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Query$Foundation? readQuery$Foundation({
    required Variables$Query$Foundation variables,
    bool optimistic = true,
  }) {
    final result = this.readQuery(
      graphql.Request(
        operation: graphql.Operation(document: documentNodeQueryFoundation),
        variables: variables.toJson(),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Query$Foundation.fromJson(result);
  }
}

class Query$Foundation$foundation {
  Query$Foundation$foundation({
    required this.settings,
    required this.references,
    required this.employers,
    required this.managers,
    required this.drafts,
    this.$__typename = 'FoundationData',
  });

  factory Query$Foundation$foundation.fromJson(Map<String, dynamic> json) {
    final l$settings = json['settings'];
    final l$references = json['references'];
    final l$employers = json['employers'];
    final l$managers = json['managers'];
    final l$drafts = json['drafts'];
    final l$$__typename = json['__typename'];
    return Query$Foundation$foundation(
      settings: Query$Foundation$foundation$settings.fromJson(
        (l$settings as Map<String, dynamic>),
      ),
      references: (l$references as List<dynamic>)
          .map(
            (e) => Query$Foundation$foundation$references.fromJson(
              (e as Map<String, dynamic>),
            ),
          )
          .toList(),
      employers: (l$employers as List<dynamic>)
          .map(
            (e) => Query$Foundation$foundation$employers.fromJson(
              (e as Map<String, dynamic>),
            ),
          )
          .toList(),
      managers: (l$managers as List<dynamic>)
          .map(
            (e) => Query$Foundation$foundation$managers.fromJson(
              (e as Map<String, dynamic>),
            ),
          )
          .toList(),
      drafts: (l$drafts as List<dynamic>)
          .map(
            (e) => Query$Foundation$foundation$drafts.fromJson(
              (e as Map<String, dynamic>),
            ),
          )
          .toList(),
      $__typename: (l$$__typename as String),
    );
  }

  final Query$Foundation$foundation$settings settings;

  final List<Query$Foundation$foundation$references> references;

  final List<Query$Foundation$foundation$employers> employers;

  final List<Query$Foundation$foundation$managers> managers;

  final List<Query$Foundation$foundation$drafts> drafts;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$settings = settings;
    _resultData['settings'] = l$settings.toJson();
    final l$references = references;
    _resultData['references'] = l$references.map((e) => e.toJson()).toList();
    final l$employers = employers;
    _resultData['employers'] = l$employers.map((e) => e.toJson()).toList();
    final l$managers = managers;
    _resultData['managers'] = l$managers.map((e) => e.toJson()).toList();
    final l$drafts = drafts;
    _resultData['drafts'] = l$drafts.map((e) => e.toJson()).toList();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$settings = settings;
    final l$references = references;
    final l$employers = employers;
    final l$managers = managers;
    final l$drafts = drafts;
    final l$$__typename = $__typename;
    return Object.hashAll([
      l$settings,
      Object.hashAll(l$references.map((v) => v)),
      Object.hashAll(l$employers.map((v) => v)),
      Object.hashAll(l$managers.map((v) => v)),
      Object.hashAll(l$drafts.map((v) => v)),
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$Foundation$foundation ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$settings = settings;
    final lOther$settings = other.settings;
    if (l$settings != lOther$settings) {
      return false;
    }
    final l$references = references;
    final lOther$references = other.references;
    if (l$references.length != lOther$references.length) {
      return false;
    }
    for (int i = 0; i < l$references.length; i++) {
      final l$references$entry = l$references[i];
      final lOther$references$entry = lOther$references[i];
      if (l$references$entry != lOther$references$entry) {
        return false;
      }
    }
    final l$employers = employers;
    final lOther$employers = other.employers;
    if (l$employers.length != lOther$employers.length) {
      return false;
    }
    for (int i = 0; i < l$employers.length; i++) {
      final l$employers$entry = l$employers[i];
      final lOther$employers$entry = lOther$employers[i];
      if (l$employers$entry != lOther$employers$entry) {
        return false;
      }
    }
    final l$managers = managers;
    final lOther$managers = other.managers;
    if (l$managers.length != lOther$managers.length) {
      return false;
    }
    for (int i = 0; i < l$managers.length; i++) {
      final l$managers$entry = l$managers[i];
      final lOther$managers$entry = lOther$managers[i];
      if (l$managers$entry != lOther$managers$entry) {
        return false;
      }
    }
    final l$drafts = drafts;
    final lOther$drafts = other.drafts;
    if (l$drafts.length != lOther$drafts.length) {
      return false;
    }
    for (int i = 0; i < l$drafts.length; i++) {
      final l$drafts$entry = l$drafts[i];
      final lOther$drafts$entry = lOther$drafts[i];
      if (l$drafts$entry != lOther$drafts$entry) {
        return false;
      }
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$Foundation$foundation
    on Query$Foundation$foundation {
  CopyWith$Query$Foundation$foundation<Query$Foundation$foundation>
  get copyWith => CopyWith$Query$Foundation$foundation(this, (i) => i);
}

abstract class CopyWith$Query$Foundation$foundation<TRes> {
  factory CopyWith$Query$Foundation$foundation(
    Query$Foundation$foundation instance,
    TRes Function(Query$Foundation$foundation) then,
  ) = _CopyWithImpl$Query$Foundation$foundation;

  factory CopyWith$Query$Foundation$foundation.stub(TRes res) =
      _CopyWithStubImpl$Query$Foundation$foundation;

  TRes call({
    Query$Foundation$foundation$settings? settings,
    List<Query$Foundation$foundation$references>? references,
    List<Query$Foundation$foundation$employers>? employers,
    List<Query$Foundation$foundation$managers>? managers,
    List<Query$Foundation$foundation$drafts>? drafts,
    String? $__typename,
  });
  CopyWith$Query$Foundation$foundation$settings<TRes> get settings;
  TRes references(
    Iterable<Query$Foundation$foundation$references> Function(
      Iterable<
        CopyWith$Query$Foundation$foundation$references<
          Query$Foundation$foundation$references
        >
      >,
    )
    _fn,
  );
  TRes employers(
    Iterable<Query$Foundation$foundation$employers> Function(
      Iterable<
        CopyWith$Query$Foundation$foundation$employers<
          Query$Foundation$foundation$employers
        >
      >,
    )
    _fn,
  );
  TRes managers(
    Iterable<Query$Foundation$foundation$managers> Function(
      Iterable<
        CopyWith$Query$Foundation$foundation$managers<
          Query$Foundation$foundation$managers
        >
      >,
    )
    _fn,
  );
  TRes drafts(
    Iterable<Query$Foundation$foundation$drafts> Function(
      Iterable<
        CopyWith$Query$Foundation$foundation$drafts<
          Query$Foundation$foundation$drafts
        >
      >,
    )
    _fn,
  );
}

class _CopyWithImpl$Query$Foundation$foundation<TRes>
    implements CopyWith$Query$Foundation$foundation<TRes> {
  _CopyWithImpl$Query$Foundation$foundation(this._instance, this._then);

  final Query$Foundation$foundation _instance;

  final TRes Function(Query$Foundation$foundation) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? settings = _undefined,
    Object? references = _undefined,
    Object? employers = _undefined,
    Object? managers = _undefined,
    Object? drafts = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$Foundation$foundation(
      settings: settings == _undefined || settings == null
          ? _instance.settings
          : (settings as Query$Foundation$foundation$settings),
      references: references == _undefined || references == null
          ? _instance.references
          : (references as List<Query$Foundation$foundation$references>),
      employers: employers == _undefined || employers == null
          ? _instance.employers
          : (employers as List<Query$Foundation$foundation$employers>),
      managers: managers == _undefined || managers == null
          ? _instance.managers
          : (managers as List<Query$Foundation$foundation$managers>),
      drafts: drafts == _undefined || drafts == null
          ? _instance.drafts
          : (drafts as List<Query$Foundation$foundation$drafts>),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Query$Foundation$foundation$settings<TRes> get settings {
    final local$settings = _instance.settings;
    return CopyWith$Query$Foundation$foundation$settings(
      local$settings,
      (e) => call(settings: e),
    );
  }

  TRes references(
    Iterable<Query$Foundation$foundation$references> Function(
      Iterable<
        CopyWith$Query$Foundation$foundation$references<
          Query$Foundation$foundation$references
        >
      >,
    )
    _fn,
  ) => call(
    references: _fn(
      _instance.references.map(
        (e) => CopyWith$Query$Foundation$foundation$references(e, (i) => i),
      ),
    ).toList(),
  );

  TRes employers(
    Iterable<Query$Foundation$foundation$employers> Function(
      Iterable<
        CopyWith$Query$Foundation$foundation$employers<
          Query$Foundation$foundation$employers
        >
      >,
    )
    _fn,
  ) => call(
    employers: _fn(
      _instance.employers.map(
        (e) => CopyWith$Query$Foundation$foundation$employers(e, (i) => i),
      ),
    ).toList(),
  );

  TRes managers(
    Iterable<Query$Foundation$foundation$managers> Function(
      Iterable<
        CopyWith$Query$Foundation$foundation$managers<
          Query$Foundation$foundation$managers
        >
      >,
    )
    _fn,
  ) => call(
    managers: _fn(
      _instance.managers.map(
        (e) => CopyWith$Query$Foundation$foundation$managers(e, (i) => i),
      ),
    ).toList(),
  );

  TRes drafts(
    Iterable<Query$Foundation$foundation$drafts> Function(
      Iterable<
        CopyWith$Query$Foundation$foundation$drafts<
          Query$Foundation$foundation$drafts
        >
      >,
    )
    _fn,
  ) => call(
    drafts: _fn(
      _instance.drafts.map(
        (e) => CopyWith$Query$Foundation$foundation$drafts(e, (i) => i),
      ),
    ).toList(),
  );
}

class _CopyWithStubImpl$Query$Foundation$foundation<TRes>
    implements CopyWith$Query$Foundation$foundation<TRes> {
  _CopyWithStubImpl$Query$Foundation$foundation(this._res);

  TRes _res;

  call({
    Query$Foundation$foundation$settings? settings,
    List<Query$Foundation$foundation$references>? references,
    List<Query$Foundation$foundation$employers>? employers,
    List<Query$Foundation$foundation$managers>? managers,
    List<Query$Foundation$foundation$drafts>? drafts,
    String? $__typename,
  }) => _res;

  CopyWith$Query$Foundation$foundation$settings<TRes> get settings =>
      CopyWith$Query$Foundation$foundation$settings.stub(_res);

  references(_fn) => _res;

  employers(_fn) => _res;

  managers(_fn) => _res;

  drafts(_fn) => _res;
}

class Query$Foundation$foundation$settings {
  Query$Foundation$foundation$settings({
    required this.id,
    required this.name,
    required this.timezone,
    required this.weekStart,
    required this.contactEmail,
    required this.version,
    this.$__typename = 'SiteSettings',
  });

  factory Query$Foundation$foundation$settings.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$id = json['id'];
    final l$name = json['name'];
    final l$timezone = json['timezone'];
    final l$weekStart = json['weekStart'];
    final l$contactEmail = json['contactEmail'];
    final l$version = json['version'];
    final l$$__typename = json['__typename'];
    return Query$Foundation$foundation$settings(
      id: (l$id as String),
      name: (l$name as String),
      timezone: (l$timezone as String),
      weekStart: (l$weekStart as int),
      contactEmail: (l$contactEmail as String),
      version: (l$version as int),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String name;

  final String timezone;

  final int weekStart;

  final String contactEmail;

  final int version;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$name = name;
    _resultData['name'] = l$name;
    final l$timezone = timezone;
    _resultData['timezone'] = l$timezone;
    final l$weekStart = weekStart;
    _resultData['weekStart'] = l$weekStart;
    final l$contactEmail = contactEmail;
    _resultData['contactEmail'] = l$contactEmail;
    final l$version = version;
    _resultData['version'] = l$version;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$name = name;
    final l$timezone = timezone;
    final l$weekStart = weekStart;
    final l$contactEmail = contactEmail;
    final l$version = version;
    final l$$__typename = $__typename;
    return Object.hashAll([
      l$id,
      l$name,
      l$timezone,
      l$weekStart,
      l$contactEmail,
      l$version,
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$Foundation$foundation$settings ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$name = name;
    final lOther$name = other.name;
    if (l$name != lOther$name) {
      return false;
    }
    final l$timezone = timezone;
    final lOther$timezone = other.timezone;
    if (l$timezone != lOther$timezone) {
      return false;
    }
    final l$weekStart = weekStart;
    final lOther$weekStart = other.weekStart;
    if (l$weekStart != lOther$weekStart) {
      return false;
    }
    final l$contactEmail = contactEmail;
    final lOther$contactEmail = other.contactEmail;
    if (l$contactEmail != lOther$contactEmail) {
      return false;
    }
    final l$version = version;
    final lOther$version = other.version;
    if (l$version != lOther$version) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$Foundation$foundation$settings
    on Query$Foundation$foundation$settings {
  CopyWith$Query$Foundation$foundation$settings<
    Query$Foundation$foundation$settings
  >
  get copyWith => CopyWith$Query$Foundation$foundation$settings(this, (i) => i);
}

abstract class CopyWith$Query$Foundation$foundation$settings<TRes> {
  factory CopyWith$Query$Foundation$foundation$settings(
    Query$Foundation$foundation$settings instance,
    TRes Function(Query$Foundation$foundation$settings) then,
  ) = _CopyWithImpl$Query$Foundation$foundation$settings;

  factory CopyWith$Query$Foundation$foundation$settings.stub(TRes res) =
      _CopyWithStubImpl$Query$Foundation$foundation$settings;

  TRes call({
    String? id,
    String? name,
    String? timezone,
    int? weekStart,
    String? contactEmail,
    int? version,
    String? $__typename,
  });
}

class _CopyWithImpl$Query$Foundation$foundation$settings<TRes>
    implements CopyWith$Query$Foundation$foundation$settings<TRes> {
  _CopyWithImpl$Query$Foundation$foundation$settings(
    this._instance,
    this._then,
  );

  final Query$Foundation$foundation$settings _instance;

  final TRes Function(Query$Foundation$foundation$settings) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? name = _undefined,
    Object? timezone = _undefined,
    Object? weekStart = _undefined,
    Object? contactEmail = _undefined,
    Object? version = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$Foundation$foundation$settings(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      name: name == _undefined || name == null
          ? _instance.name
          : (name as String),
      timezone: timezone == _undefined || timezone == null
          ? _instance.timezone
          : (timezone as String),
      weekStart: weekStart == _undefined || weekStart == null
          ? _instance.weekStart
          : (weekStart as int),
      contactEmail: contactEmail == _undefined || contactEmail == null
          ? _instance.contactEmail
          : (contactEmail as String),
      version: version == _undefined || version == null
          ? _instance.version
          : (version as int),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$Foundation$foundation$settings<TRes>
    implements CopyWith$Query$Foundation$foundation$settings<TRes> {
  _CopyWithStubImpl$Query$Foundation$foundation$settings(this._res);

  TRes _res;

  call({
    String? id,
    String? name,
    String? timezone,
    int? weekStart,
    String? contactEmail,
    int? version,
    String? $__typename,
  }) => _res;
}

class Query$Foundation$foundation$references {
  Query$Foundation$foundation$references({
    required this.id,
    required this.kind,
    required this.name,
    required this.active,
    required this.version,
    this.startTime,
    this.endTime,
    this.date,
    this.$__typename = 'ReferenceItem',
  });

  factory Query$Foundation$foundation$references.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$id = json['id'];
    final l$kind = json['kind'];
    final l$name = json['name'];
    final l$active = json['active'];
    final l$version = json['version'];
    final l$startTime = json['startTime'];
    final l$endTime = json['endTime'];
    final l$date = json['date'];
    final l$$__typename = json['__typename'];
    return Query$Foundation$foundation$references(
      id: (l$id as String),
      kind: (l$kind as String),
      name: (l$name as String),
      active: (l$active as bool),
      version: (l$version as int),
      startTime: (l$startTime as String?),
      endTime: (l$endTime as String?),
      date: (l$date as String?),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String kind;

  final String name;

  final bool active;

  final int version;

  final String? startTime;

  final String? endTime;

  final String? date;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$kind = kind;
    _resultData['kind'] = l$kind;
    final l$name = name;
    _resultData['name'] = l$name;
    final l$active = active;
    _resultData['active'] = l$active;
    final l$version = version;
    _resultData['version'] = l$version;
    final l$startTime = startTime;
    _resultData['startTime'] = l$startTime;
    final l$endTime = endTime;
    _resultData['endTime'] = l$endTime;
    final l$date = date;
    _resultData['date'] = l$date;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$kind = kind;
    final l$name = name;
    final l$active = active;
    final l$version = version;
    final l$startTime = startTime;
    final l$endTime = endTime;
    final l$date = date;
    final l$$__typename = $__typename;
    return Object.hashAll([
      l$id,
      l$kind,
      l$name,
      l$active,
      l$version,
      l$startTime,
      l$endTime,
      l$date,
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$Foundation$foundation$references ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$kind = kind;
    final lOther$kind = other.kind;
    if (l$kind != lOther$kind) {
      return false;
    }
    final l$name = name;
    final lOther$name = other.name;
    if (l$name != lOther$name) {
      return false;
    }
    final l$active = active;
    final lOther$active = other.active;
    if (l$active != lOther$active) {
      return false;
    }
    final l$version = version;
    final lOther$version = other.version;
    if (l$version != lOther$version) {
      return false;
    }
    final l$startTime = startTime;
    final lOther$startTime = other.startTime;
    if (l$startTime != lOther$startTime) {
      return false;
    }
    final l$endTime = endTime;
    final lOther$endTime = other.endTime;
    if (l$endTime != lOther$endTime) {
      return false;
    }
    final l$date = date;
    final lOther$date = other.date;
    if (l$date != lOther$date) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$Foundation$foundation$references
    on Query$Foundation$foundation$references {
  CopyWith$Query$Foundation$foundation$references<
    Query$Foundation$foundation$references
  >
  get copyWith =>
      CopyWith$Query$Foundation$foundation$references(this, (i) => i);
}

abstract class CopyWith$Query$Foundation$foundation$references<TRes> {
  factory CopyWith$Query$Foundation$foundation$references(
    Query$Foundation$foundation$references instance,
    TRes Function(Query$Foundation$foundation$references) then,
  ) = _CopyWithImpl$Query$Foundation$foundation$references;

  factory CopyWith$Query$Foundation$foundation$references.stub(TRes res) =
      _CopyWithStubImpl$Query$Foundation$foundation$references;

  TRes call({
    String? id,
    String? kind,
    String? name,
    bool? active,
    int? version,
    String? startTime,
    String? endTime,
    String? date,
    String? $__typename,
  });
}

class _CopyWithImpl$Query$Foundation$foundation$references<TRes>
    implements CopyWith$Query$Foundation$foundation$references<TRes> {
  _CopyWithImpl$Query$Foundation$foundation$references(
    this._instance,
    this._then,
  );

  final Query$Foundation$foundation$references _instance;

  final TRes Function(Query$Foundation$foundation$references) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? kind = _undefined,
    Object? name = _undefined,
    Object? active = _undefined,
    Object? version = _undefined,
    Object? startTime = _undefined,
    Object? endTime = _undefined,
    Object? date = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$Foundation$foundation$references(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      kind: kind == _undefined || kind == null
          ? _instance.kind
          : (kind as String),
      name: name == _undefined || name == null
          ? _instance.name
          : (name as String),
      active: active == _undefined || active == null
          ? _instance.active
          : (active as bool),
      version: version == _undefined || version == null
          ? _instance.version
          : (version as int),
      startTime: startTime == _undefined
          ? _instance.startTime
          : (startTime as String?),
      endTime: endTime == _undefined ? _instance.endTime : (endTime as String?),
      date: date == _undefined ? _instance.date : (date as String?),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$Foundation$foundation$references<TRes>
    implements CopyWith$Query$Foundation$foundation$references<TRes> {
  _CopyWithStubImpl$Query$Foundation$foundation$references(this._res);

  TRes _res;

  call({
    String? id,
    String? kind,
    String? name,
    bool? active,
    int? version,
    String? startTime,
    String? endTime,
    String? date,
    String? $__typename,
  }) => _res;
}

class Query$Foundation$foundation$employers {
  Query$Foundation$foundation$employers({
    required this.id,
    required this.name,
    this.$__typename = 'LegalEmployer',
  });

  factory Query$Foundation$foundation$employers.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$id = json['id'];
    final l$name = json['name'];
    final l$$__typename = json['__typename'];
    return Query$Foundation$foundation$employers(
      id: (l$id as String),
      name: (l$name as String),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String name;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$name = name;
    _resultData['name'] = l$name;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$name = name;
    final l$$__typename = $__typename;
    return Object.hashAll([l$id, l$name, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$Foundation$foundation$employers ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$name = name;
    final lOther$name = other.name;
    if (l$name != lOther$name) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$Foundation$foundation$employers
    on Query$Foundation$foundation$employers {
  CopyWith$Query$Foundation$foundation$employers<
    Query$Foundation$foundation$employers
  >
  get copyWith =>
      CopyWith$Query$Foundation$foundation$employers(this, (i) => i);
}

abstract class CopyWith$Query$Foundation$foundation$employers<TRes> {
  factory CopyWith$Query$Foundation$foundation$employers(
    Query$Foundation$foundation$employers instance,
    TRes Function(Query$Foundation$foundation$employers) then,
  ) = _CopyWithImpl$Query$Foundation$foundation$employers;

  factory CopyWith$Query$Foundation$foundation$employers.stub(TRes res) =
      _CopyWithStubImpl$Query$Foundation$foundation$employers;

  TRes call({String? id, String? name, String? $__typename});
}

class _CopyWithImpl$Query$Foundation$foundation$employers<TRes>
    implements CopyWith$Query$Foundation$foundation$employers<TRes> {
  _CopyWithImpl$Query$Foundation$foundation$employers(
    this._instance,
    this._then,
  );

  final Query$Foundation$foundation$employers _instance;

  final TRes Function(Query$Foundation$foundation$employers) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? name = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$Foundation$foundation$employers(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      name: name == _undefined || name == null
          ? _instance.name
          : (name as String),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$Foundation$foundation$employers<TRes>
    implements CopyWith$Query$Foundation$foundation$employers<TRes> {
  _CopyWithStubImpl$Query$Foundation$foundation$employers(this._res);

  TRes _res;

  call({String? id, String? name, String? $__typename}) => _res;
}

class Query$Foundation$foundation$managers {
  Query$Foundation$foundation$managers({
    required this.id,
    required this.name,
    this.$__typename = 'ManagerOption',
  });

  factory Query$Foundation$foundation$managers.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$id = json['id'];
    final l$name = json['name'];
    final l$$__typename = json['__typename'];
    return Query$Foundation$foundation$managers(
      id: (l$id as String),
      name: (l$name as String),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String name;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$name = name;
    _resultData['name'] = l$name;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$name = name;
    final l$$__typename = $__typename;
    return Object.hashAll([l$id, l$name, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$Foundation$foundation$managers ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$name = name;
    final lOther$name = other.name;
    if (l$name != lOther$name) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$Foundation$foundation$managers
    on Query$Foundation$foundation$managers {
  CopyWith$Query$Foundation$foundation$managers<
    Query$Foundation$foundation$managers
  >
  get copyWith => CopyWith$Query$Foundation$foundation$managers(this, (i) => i);
}

abstract class CopyWith$Query$Foundation$foundation$managers<TRes> {
  factory CopyWith$Query$Foundation$foundation$managers(
    Query$Foundation$foundation$managers instance,
    TRes Function(Query$Foundation$foundation$managers) then,
  ) = _CopyWithImpl$Query$Foundation$foundation$managers;

  factory CopyWith$Query$Foundation$foundation$managers.stub(TRes res) =
      _CopyWithStubImpl$Query$Foundation$foundation$managers;

  TRes call({String? id, String? name, String? $__typename});
}

class _CopyWithImpl$Query$Foundation$foundation$managers<TRes>
    implements CopyWith$Query$Foundation$foundation$managers<TRes> {
  _CopyWithImpl$Query$Foundation$foundation$managers(
    this._instance,
    this._then,
  );

  final Query$Foundation$foundation$managers _instance;

  final TRes Function(Query$Foundation$foundation$managers) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? name = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$Foundation$foundation$managers(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      name: name == _undefined || name == null
          ? _instance.name
          : (name as String),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$Foundation$foundation$managers<TRes>
    implements CopyWith$Query$Foundation$foundation$managers<TRes> {
  _CopyWithStubImpl$Query$Foundation$foundation$managers(this._res);

  TRes _res;

  call({String? id, String? name, String? $__typename}) => _res;
}

class Query$Foundation$foundation$drafts {
  Query$Foundation$foundation$drafts({
    required this.id,
    required this.displayName,
    required this.employeeCode,
    required this.workEmail,
    required this.department,
    required this.designation,
    required this.startsOn,
    required this.status,
    required this.version,
    required this.authorId,
    required this.createdAt,
    this.$__typename = 'EmployeeDraft',
  });

  factory Query$Foundation$foundation$drafts.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$id = json['id'];
    final l$displayName = json['displayName'];
    final l$employeeCode = json['employeeCode'];
    final l$workEmail = json['workEmail'];
    final l$department = json['department'];
    final l$designation = json['designation'];
    final l$startsOn = json['startsOn'];
    final l$status = json['status'];
    final l$version = json['version'];
    final l$authorId = json['authorId'];
    final l$createdAt = json['createdAt'];
    final l$$__typename = json['__typename'];
    return Query$Foundation$foundation$drafts(
      id: (l$id as String),
      displayName: (l$displayName as String),
      employeeCode: (l$employeeCode as String),
      workEmail: (l$workEmail as String),
      department: (l$department as String),
      designation: (l$designation as String),
      startsOn: (l$startsOn as String),
      status: (l$status as String),
      version: (l$version as int),
      authorId: (l$authorId as String),
      createdAt: (l$createdAt as String),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String displayName;

  final String employeeCode;

  final String workEmail;

  final String department;

  final String designation;

  final String startsOn;

  final String status;

  final int version;

  final String authorId;

  final String createdAt;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$displayName = displayName;
    _resultData['displayName'] = l$displayName;
    final l$employeeCode = employeeCode;
    _resultData['employeeCode'] = l$employeeCode;
    final l$workEmail = workEmail;
    _resultData['workEmail'] = l$workEmail;
    final l$department = department;
    _resultData['department'] = l$department;
    final l$designation = designation;
    _resultData['designation'] = l$designation;
    final l$startsOn = startsOn;
    _resultData['startsOn'] = l$startsOn;
    final l$status = status;
    _resultData['status'] = l$status;
    final l$version = version;
    _resultData['version'] = l$version;
    final l$authorId = authorId;
    _resultData['authorId'] = l$authorId;
    final l$createdAt = createdAt;
    _resultData['createdAt'] = l$createdAt;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$displayName = displayName;
    final l$employeeCode = employeeCode;
    final l$workEmail = workEmail;
    final l$department = department;
    final l$designation = designation;
    final l$startsOn = startsOn;
    final l$status = status;
    final l$version = version;
    final l$authorId = authorId;
    final l$createdAt = createdAt;
    final l$$__typename = $__typename;
    return Object.hashAll([
      l$id,
      l$displayName,
      l$employeeCode,
      l$workEmail,
      l$department,
      l$designation,
      l$startsOn,
      l$status,
      l$version,
      l$authorId,
      l$createdAt,
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$Foundation$foundation$drafts ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$displayName = displayName;
    final lOther$displayName = other.displayName;
    if (l$displayName != lOther$displayName) {
      return false;
    }
    final l$employeeCode = employeeCode;
    final lOther$employeeCode = other.employeeCode;
    if (l$employeeCode != lOther$employeeCode) {
      return false;
    }
    final l$workEmail = workEmail;
    final lOther$workEmail = other.workEmail;
    if (l$workEmail != lOther$workEmail) {
      return false;
    }
    final l$department = department;
    final lOther$department = other.department;
    if (l$department != lOther$department) {
      return false;
    }
    final l$designation = designation;
    final lOther$designation = other.designation;
    if (l$designation != lOther$designation) {
      return false;
    }
    final l$startsOn = startsOn;
    final lOther$startsOn = other.startsOn;
    if (l$startsOn != lOther$startsOn) {
      return false;
    }
    final l$status = status;
    final lOther$status = other.status;
    if (l$status != lOther$status) {
      return false;
    }
    final l$version = version;
    final lOther$version = other.version;
    if (l$version != lOther$version) {
      return false;
    }
    final l$authorId = authorId;
    final lOther$authorId = other.authorId;
    if (l$authorId != lOther$authorId) {
      return false;
    }
    final l$createdAt = createdAt;
    final lOther$createdAt = other.createdAt;
    if (l$createdAt != lOther$createdAt) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$Foundation$foundation$drafts
    on Query$Foundation$foundation$drafts {
  CopyWith$Query$Foundation$foundation$drafts<
    Query$Foundation$foundation$drafts
  >
  get copyWith => CopyWith$Query$Foundation$foundation$drafts(this, (i) => i);
}

abstract class CopyWith$Query$Foundation$foundation$drafts<TRes> {
  factory CopyWith$Query$Foundation$foundation$drafts(
    Query$Foundation$foundation$drafts instance,
    TRes Function(Query$Foundation$foundation$drafts) then,
  ) = _CopyWithImpl$Query$Foundation$foundation$drafts;

  factory CopyWith$Query$Foundation$foundation$drafts.stub(TRes res) =
      _CopyWithStubImpl$Query$Foundation$foundation$drafts;

  TRes call({
    String? id,
    String? displayName,
    String? employeeCode,
    String? workEmail,
    String? department,
    String? designation,
    String? startsOn,
    String? status,
    int? version,
    String? authorId,
    String? createdAt,
    String? $__typename,
  });
}

class _CopyWithImpl$Query$Foundation$foundation$drafts<TRes>
    implements CopyWith$Query$Foundation$foundation$drafts<TRes> {
  _CopyWithImpl$Query$Foundation$foundation$drafts(this._instance, this._then);

  final Query$Foundation$foundation$drafts _instance;

  final TRes Function(Query$Foundation$foundation$drafts) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? displayName = _undefined,
    Object? employeeCode = _undefined,
    Object? workEmail = _undefined,
    Object? department = _undefined,
    Object? designation = _undefined,
    Object? startsOn = _undefined,
    Object? status = _undefined,
    Object? version = _undefined,
    Object? authorId = _undefined,
    Object? createdAt = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$Foundation$foundation$drafts(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      displayName: displayName == _undefined || displayName == null
          ? _instance.displayName
          : (displayName as String),
      employeeCode: employeeCode == _undefined || employeeCode == null
          ? _instance.employeeCode
          : (employeeCode as String),
      workEmail: workEmail == _undefined || workEmail == null
          ? _instance.workEmail
          : (workEmail as String),
      department: department == _undefined || department == null
          ? _instance.department
          : (department as String),
      designation: designation == _undefined || designation == null
          ? _instance.designation
          : (designation as String),
      startsOn: startsOn == _undefined || startsOn == null
          ? _instance.startsOn
          : (startsOn as String),
      status: status == _undefined || status == null
          ? _instance.status
          : (status as String),
      version: version == _undefined || version == null
          ? _instance.version
          : (version as int),
      authorId: authorId == _undefined || authorId == null
          ? _instance.authorId
          : (authorId as String),
      createdAt: createdAt == _undefined || createdAt == null
          ? _instance.createdAt
          : (createdAt as String),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$Foundation$foundation$drafts<TRes>
    implements CopyWith$Query$Foundation$foundation$drafts<TRes> {
  _CopyWithStubImpl$Query$Foundation$foundation$drafts(this._res);

  TRes _res;

  call({
    String? id,
    String? displayName,
    String? employeeCode,
    String? workEmail,
    String? department,
    String? designation,
    String? startsOn,
    String? status,
    int? version,
    String? authorId,
    String? createdAt,
    String? $__typename,
  }) => _res;
}

class Variables$Query$ProfileRequests {
  factory Variables$Query$ProfileRequests({required String siteId}) =>
      Variables$Query$ProfileRequests._({r'siteId': siteId});

  Variables$Query$ProfileRequests._(this._$data);

  factory Variables$Query$ProfileRequests.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    return Variables$Query$ProfileRequests._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    return result$data;
  }

  CopyWith$Variables$Query$ProfileRequests<Variables$Query$ProfileRequests>
  get copyWith => CopyWith$Variables$Query$ProfileRequests(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$ProfileRequests ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    return Object.hashAll([l$siteId]);
  }
}

abstract class CopyWith$Variables$Query$ProfileRequests<TRes> {
  factory CopyWith$Variables$Query$ProfileRequests(
    Variables$Query$ProfileRequests instance,
    TRes Function(Variables$Query$ProfileRequests) then,
  ) = _CopyWithImpl$Variables$Query$ProfileRequests;

  factory CopyWith$Variables$Query$ProfileRequests.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$ProfileRequests;

  TRes call({String? siteId});
}

class _CopyWithImpl$Variables$Query$ProfileRequests<TRes>
    implements CopyWith$Variables$Query$ProfileRequests<TRes> {
  _CopyWithImpl$Variables$Query$ProfileRequests(this._instance, this._then);

  final Variables$Query$ProfileRequests _instance;

  final TRes Function(Variables$Query$ProfileRequests) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? siteId = _undefined}) => _then(
    Variables$Query$ProfileRequests._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
    }),
  );
}

class _CopyWithStubImpl$Variables$Query$ProfileRequests<TRes>
    implements CopyWith$Variables$Query$ProfileRequests<TRes> {
  _CopyWithStubImpl$Variables$Query$ProfileRequests(this._res);

  TRes _res;

  call({String? siteId}) => _res;
}

class Query$ProfileRequests {
  Query$ProfileRequests({
    required this.profileRequests,
    this.$__typename = 'Query',
  });

  factory Query$ProfileRequests.fromJson(Map<String, dynamic> json) {
    final l$profileRequests = json['profileRequests'];
    final l$$__typename = json['__typename'];
    return Query$ProfileRequests(
      profileRequests: (l$profileRequests as List<dynamic>)
          .map(
            (e) => Query$ProfileRequests$profileRequests.fromJson(
              (e as Map<String, dynamic>),
            ),
          )
          .toList(),
      $__typename: (l$$__typename as String),
    );
  }

  final List<Query$ProfileRequests$profileRequests> profileRequests;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$profileRequests = profileRequests;
    _resultData['profileRequests'] = l$profileRequests
        .map((e) => e.toJson())
        .toList();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$profileRequests = profileRequests;
    final l$$__typename = $__typename;
    return Object.hashAll([
      Object.hashAll(l$profileRequests.map((v) => v)),
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$ProfileRequests || runtimeType != other.runtimeType) {
      return false;
    }
    final l$profileRequests = profileRequests;
    final lOther$profileRequests = other.profileRequests;
    if (l$profileRequests.length != lOther$profileRequests.length) {
      return false;
    }
    for (int i = 0; i < l$profileRequests.length; i++) {
      final l$profileRequests$entry = l$profileRequests[i];
      final lOther$profileRequests$entry = lOther$profileRequests[i];
      if (l$profileRequests$entry != lOther$profileRequests$entry) {
        return false;
      }
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$ProfileRequests on Query$ProfileRequests {
  CopyWith$Query$ProfileRequests<Query$ProfileRequests> get copyWith =>
      CopyWith$Query$ProfileRequests(this, (i) => i);
}

abstract class CopyWith$Query$ProfileRequests<TRes> {
  factory CopyWith$Query$ProfileRequests(
    Query$ProfileRequests instance,
    TRes Function(Query$ProfileRequests) then,
  ) = _CopyWithImpl$Query$ProfileRequests;

  factory CopyWith$Query$ProfileRequests.stub(TRes res) =
      _CopyWithStubImpl$Query$ProfileRequests;

  TRes call({
    List<Query$ProfileRequests$profileRequests>? profileRequests,
    String? $__typename,
  });
  TRes profileRequests(
    Iterable<Query$ProfileRequests$profileRequests> Function(
      Iterable<
        CopyWith$Query$ProfileRequests$profileRequests<
          Query$ProfileRequests$profileRequests
        >
      >,
    )
    _fn,
  );
}

class _CopyWithImpl$Query$ProfileRequests<TRes>
    implements CopyWith$Query$ProfileRequests<TRes> {
  _CopyWithImpl$Query$ProfileRequests(this._instance, this._then);

  final Query$ProfileRequests _instance;

  final TRes Function(Query$ProfileRequests) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? profileRequests = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$ProfileRequests(
      profileRequests: profileRequests == _undefined || profileRequests == null
          ? _instance.profileRequests
          : (profileRequests as List<Query$ProfileRequests$profileRequests>),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  TRes profileRequests(
    Iterable<Query$ProfileRequests$profileRequests> Function(
      Iterable<
        CopyWith$Query$ProfileRequests$profileRequests<
          Query$ProfileRequests$profileRequests
        >
      >,
    )
    _fn,
  ) => call(
    profileRequests: _fn(
      _instance.profileRequests.map(
        (e) => CopyWith$Query$ProfileRequests$profileRequests(e, (i) => i),
      ),
    ).toList(),
  );
}

class _CopyWithStubImpl$Query$ProfileRequests<TRes>
    implements CopyWith$Query$ProfileRequests<TRes> {
  _CopyWithStubImpl$Query$ProfileRequests(this._res);

  TRes _res;

  call({
    List<Query$ProfileRequests$profileRequests>? profileRequests,
    String? $__typename,
  }) => _res;

  profileRequests(_fn) => _res;
}

const documentNodeQueryProfileRequests = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'ProfileRequests'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'profileRequests'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
            ],
            directives: [],
            selectionSet: SelectionSetNode(
              selections: [
                FieldNode(
                  name: NameNode(value: 'id'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'employeeId'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'employeeName'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'phone'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'reason'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'status'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'version'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'createdAt'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'reviewNote'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'isSelf'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'details'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FragmentSpreadNode(
                        name: NameNode(value: 'PersonalFields'),
                        directives: [],
                      ),
                      FieldNode(
                        name: NameNode(value: '__typename'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                    ],
                  ),
                ),
                FieldNode(
                  name: NameNode(value: 'hasPhoto'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'currentPhone'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'currentDetails'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FragmentSpreadNode(
                        name: NameNode(value: 'PersonalFields'),
                        directives: [],
                      ),
                      FieldNode(
                        name: NameNode(value: '__typename'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                    ],
                  ),
                ),
                FieldNode(
                  name: NameNode(value: '__typename'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
              ],
            ),
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
    fragmentDefinitionPersonalFields,
  ],
);
Query$ProfileRequests _parserFn$Query$ProfileRequests(
  Map<String, dynamic> data,
) => Query$ProfileRequests.fromJson(data);
typedef OnQueryComplete$Query$ProfileRequests = FutureOr<void> Function(
  Map<String, dynamic>?,
  Query$ProfileRequests?,
);

class Options$Query$ProfileRequests
    extends graphql.QueryOptions<Query$ProfileRequests> {
  Options$Query$ProfileRequests({
    String? operationName,
    required Variables$Query$ProfileRequests variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$ProfileRequests? typedOptimisticResult,
    Duration? pollInterval,
    graphql.Context? context,
    OnQueryComplete$Query$ProfileRequests? onComplete,
    graphql.OnQueryError? onError,
  }) : onCompleteWithParsed = onComplete,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         pollInterval: pollInterval,
         context: context,
         onComplete: onComplete == null
             ? null
             : (data) => onComplete(
                 data,
                 data == null ? null : _parserFn$Query$ProfileRequests(data),
               ),
         onError: onError,
         document: documentNodeQueryProfileRequests,
         parserFn: _parserFn$Query$ProfileRequests,
       );

  final OnQueryComplete$Query$ProfileRequests? onCompleteWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onComplete == null
        ? super.properties
        : super.properties.where((property) => property != onComplete),
    onCompleteWithParsed,
  ];
}

class WatchOptions$Query$ProfileRequests
    extends graphql.WatchQueryOptions<Query$ProfileRequests> {
  WatchOptions$Query$ProfileRequests({
    String? operationName,
    required Variables$Query$ProfileRequests variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$ProfileRequests? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeQueryProfileRequests,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Query$ProfileRequests,
       );
}

class FetchMoreOptions$Query$ProfileRequests extends graphql.FetchMoreOptions {
  FetchMoreOptions$Query$ProfileRequests({
    required graphql.UpdateQuery updateQuery,
    required Variables$Query$ProfileRequests variables,
  }) : super(
         updateQuery: updateQuery,
         variables: variables.toJson(),
         document: documentNodeQueryProfileRequests,
       );
}

extension ClientExtension$Query$ProfileRequests on graphql.GraphQLClient {
  Future<graphql.QueryResult<Query$ProfileRequests>> query$ProfileRequests(
    Options$Query$ProfileRequests options,
  ) async => await this.query(options);

  graphql.ObservableQuery<Query$ProfileRequests> watchQuery$ProfileRequests(
    WatchOptions$Query$ProfileRequests options,
  ) => this.watchQuery(options);

  void writeQuery$ProfileRequests({
    required Query$ProfileRequests data,
    required Variables$Query$ProfileRequests variables,
    bool broadcast = true,
  }) => this.writeQuery(
    graphql.Request(
      operation: graphql.Operation(document: documentNodeQueryProfileRequests),
      variables: variables.toJson(),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Query$ProfileRequests? readQuery$ProfileRequests({
    required Variables$Query$ProfileRequests variables,
    bool optimistic = true,
  }) {
    final result = this.readQuery(
      graphql.Request(
        operation: graphql.Operation(
          document: documentNodeQueryProfileRequests,
        ),
        variables: variables.toJson(),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Query$ProfileRequests.fromJson(result);
  }
}

class Query$ProfileRequests$profileRequests {
  Query$ProfileRequests$profileRequests({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.phone,
    required this.reason,
    required this.status,
    required this.version,
    required this.createdAt,
    this.reviewNote,
    required this.isSelf,
    this.details,
    required this.hasPhoto,
    this.currentPhone,
    this.currentDetails,
    this.$__typename = 'ProfileRequest',
  });

  factory Query$ProfileRequests$profileRequests.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$id = json['id'];
    final l$employeeId = json['employeeId'];
    final l$employeeName = json['employeeName'];
    final l$phone = json['phone'];
    final l$reason = json['reason'];
    final l$status = json['status'];
    final l$version = json['version'];
    final l$createdAt = json['createdAt'];
    final l$reviewNote = json['reviewNote'];
    final l$isSelf = json['isSelf'];
    final l$details = json['details'];
    final l$hasPhoto = json['hasPhoto'];
    final l$currentPhone = json['currentPhone'];
    final l$currentDetails = json['currentDetails'];
    final l$$__typename = json['__typename'];
    return Query$ProfileRequests$profileRequests(
      id: (l$id as String),
      employeeId: (l$employeeId as String),
      employeeName: (l$employeeName as String),
      phone: (l$phone as String),
      reason: (l$reason as String),
      status: (l$status as String),
      version: (l$version as int),
      createdAt: (l$createdAt as String),
      reviewNote: (l$reviewNote as String?),
      isSelf: (l$isSelf as bool),
      details: l$details == null
          ? null
          : Fragment$PersonalFields.fromJson(
              (l$details as Map<String, dynamic>),
            ),
      hasPhoto: (l$hasPhoto as bool),
      currentPhone: (l$currentPhone as String?),
      currentDetails: l$currentDetails == null
          ? null
          : Fragment$PersonalFields.fromJson(
              (l$currentDetails as Map<String, dynamic>),
            ),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String employeeId;

  final String employeeName;

  final String phone;

  final String reason;

  final String status;

  final int version;

  final String createdAt;

  final String? reviewNote;

  final bool isSelf;

  final Fragment$PersonalFields? details;

  final bool hasPhoto;

  final String? currentPhone;

  final Fragment$PersonalFields? currentDetails;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$employeeId = employeeId;
    _resultData['employeeId'] = l$employeeId;
    final l$employeeName = employeeName;
    _resultData['employeeName'] = l$employeeName;
    final l$phone = phone;
    _resultData['phone'] = l$phone;
    final l$reason = reason;
    _resultData['reason'] = l$reason;
    final l$status = status;
    _resultData['status'] = l$status;
    final l$version = version;
    _resultData['version'] = l$version;
    final l$createdAt = createdAt;
    _resultData['createdAt'] = l$createdAt;
    final l$reviewNote = reviewNote;
    _resultData['reviewNote'] = l$reviewNote;
    final l$isSelf = isSelf;
    _resultData['isSelf'] = l$isSelf;
    final l$details = details;
    _resultData['details'] = l$details?.toJson();
    final l$hasPhoto = hasPhoto;
    _resultData['hasPhoto'] = l$hasPhoto;
    final l$currentPhone = currentPhone;
    _resultData['currentPhone'] = l$currentPhone;
    final l$currentDetails = currentDetails;
    _resultData['currentDetails'] = l$currentDetails?.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$employeeId = employeeId;
    final l$employeeName = employeeName;
    final l$phone = phone;
    final l$reason = reason;
    final l$status = status;
    final l$version = version;
    final l$createdAt = createdAt;
    final l$reviewNote = reviewNote;
    final l$isSelf = isSelf;
    final l$details = details;
    final l$hasPhoto = hasPhoto;
    final l$currentPhone = currentPhone;
    final l$currentDetails = currentDetails;
    final l$$__typename = $__typename;
    return Object.hashAll([
      l$id,
      l$employeeId,
      l$employeeName,
      l$phone,
      l$reason,
      l$status,
      l$version,
      l$createdAt,
      l$reviewNote,
      l$isSelf,
      l$details,
      l$hasPhoto,
      l$currentPhone,
      l$currentDetails,
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$ProfileRequests$profileRequests ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$employeeId = employeeId;
    final lOther$employeeId = other.employeeId;
    if (l$employeeId != lOther$employeeId) {
      return false;
    }
    final l$employeeName = employeeName;
    final lOther$employeeName = other.employeeName;
    if (l$employeeName != lOther$employeeName) {
      return false;
    }
    final l$phone = phone;
    final lOther$phone = other.phone;
    if (l$phone != lOther$phone) {
      return false;
    }
    final l$reason = reason;
    final lOther$reason = other.reason;
    if (l$reason != lOther$reason) {
      return false;
    }
    final l$status = status;
    final lOther$status = other.status;
    if (l$status != lOther$status) {
      return false;
    }
    final l$version = version;
    final lOther$version = other.version;
    if (l$version != lOther$version) {
      return false;
    }
    final l$createdAt = createdAt;
    final lOther$createdAt = other.createdAt;
    if (l$createdAt != lOther$createdAt) {
      return false;
    }
    final l$reviewNote = reviewNote;
    final lOther$reviewNote = other.reviewNote;
    if (l$reviewNote != lOther$reviewNote) {
      return false;
    }
    final l$isSelf = isSelf;
    final lOther$isSelf = other.isSelf;
    if (l$isSelf != lOther$isSelf) {
      return false;
    }
    final l$details = details;
    final lOther$details = other.details;
    if (l$details != lOther$details) {
      return false;
    }
    final l$hasPhoto = hasPhoto;
    final lOther$hasPhoto = other.hasPhoto;
    if (l$hasPhoto != lOther$hasPhoto) {
      return false;
    }
    final l$currentPhone = currentPhone;
    final lOther$currentPhone = other.currentPhone;
    if (l$currentPhone != lOther$currentPhone) {
      return false;
    }
    final l$currentDetails = currentDetails;
    final lOther$currentDetails = other.currentDetails;
    if (l$currentDetails != lOther$currentDetails) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$ProfileRequests$profileRequests
    on Query$ProfileRequests$profileRequests {
  CopyWith$Query$ProfileRequests$profileRequests<
    Query$ProfileRequests$profileRequests
  >
  get copyWith =>
      CopyWith$Query$ProfileRequests$profileRequests(this, (i) => i);
}

abstract class CopyWith$Query$ProfileRequests$profileRequests<TRes> {
  factory CopyWith$Query$ProfileRequests$profileRequests(
    Query$ProfileRequests$profileRequests instance,
    TRes Function(Query$ProfileRequests$profileRequests) then,
  ) = _CopyWithImpl$Query$ProfileRequests$profileRequests;

  factory CopyWith$Query$ProfileRequests$profileRequests.stub(TRes res) =
      _CopyWithStubImpl$Query$ProfileRequests$profileRequests;

  TRes call({
    String? id,
    String? employeeId,
    String? employeeName,
    String? phone,
    String? reason,
    String? status,
    int? version,
    String? createdAt,
    String? reviewNote,
    bool? isSelf,
    Fragment$PersonalFields? details,
    bool? hasPhoto,
    String? currentPhone,
    Fragment$PersonalFields? currentDetails,
    String? $__typename,
  });
  CopyWith$Fragment$PersonalFields<TRes> get details;
  CopyWith$Fragment$PersonalFields<TRes> get currentDetails;
}

class _CopyWithImpl$Query$ProfileRequests$profileRequests<TRes>
    implements CopyWith$Query$ProfileRequests$profileRequests<TRes> {
  _CopyWithImpl$Query$ProfileRequests$profileRequests(
    this._instance,
    this._then,
  );

  final Query$ProfileRequests$profileRequests _instance;

  final TRes Function(Query$ProfileRequests$profileRequests) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? employeeId = _undefined,
    Object? employeeName = _undefined,
    Object? phone = _undefined,
    Object? reason = _undefined,
    Object? status = _undefined,
    Object? version = _undefined,
    Object? createdAt = _undefined,
    Object? reviewNote = _undefined,
    Object? isSelf = _undefined,
    Object? details = _undefined,
    Object? hasPhoto = _undefined,
    Object? currentPhone = _undefined,
    Object? currentDetails = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$ProfileRequests$profileRequests(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      employeeId: employeeId == _undefined || employeeId == null
          ? _instance.employeeId
          : (employeeId as String),
      employeeName: employeeName == _undefined || employeeName == null
          ? _instance.employeeName
          : (employeeName as String),
      phone: phone == _undefined || phone == null
          ? _instance.phone
          : (phone as String),
      reason: reason == _undefined || reason == null
          ? _instance.reason
          : (reason as String),
      status: status == _undefined || status == null
          ? _instance.status
          : (status as String),
      version: version == _undefined || version == null
          ? _instance.version
          : (version as int),
      createdAt: createdAt == _undefined || createdAt == null
          ? _instance.createdAt
          : (createdAt as String),
      reviewNote: reviewNote == _undefined
          ? _instance.reviewNote
          : (reviewNote as String?),
      isSelf: isSelf == _undefined || isSelf == null
          ? _instance.isSelf
          : (isSelf as bool),
      details: details == _undefined
          ? _instance.details
          : (details as Fragment$PersonalFields?),
      hasPhoto: hasPhoto == _undefined || hasPhoto == null
          ? _instance.hasPhoto
          : (hasPhoto as bool),
      currentPhone: currentPhone == _undefined
          ? _instance.currentPhone
          : (currentPhone as String?),
      currentDetails: currentDetails == _undefined
          ? _instance.currentDetails
          : (currentDetails as Fragment$PersonalFields?),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Fragment$PersonalFields<TRes> get details {
    final local$details = _instance.details;
    return local$details == null
        ? CopyWith$Fragment$PersonalFields.stub(_then(_instance))
        : CopyWith$Fragment$PersonalFields(
            local$details,
            (e) => call(details: e),
          );
  }

  CopyWith$Fragment$PersonalFields<TRes> get currentDetails {
    final local$currentDetails = _instance.currentDetails;
    return local$currentDetails == null
        ? CopyWith$Fragment$PersonalFields.stub(_then(_instance))
        : CopyWith$Fragment$PersonalFields(
            local$currentDetails,
            (e) => call(currentDetails: e),
          );
  }
}

class _CopyWithStubImpl$Query$ProfileRequests$profileRequests<TRes>
    implements CopyWith$Query$ProfileRequests$profileRequests<TRes> {
  _CopyWithStubImpl$Query$ProfileRequests$profileRequests(this._res);

  TRes _res;

  call({
    String? id,
    String? employeeId,
    String? employeeName,
    String? phone,
    String? reason,
    String? status,
    int? version,
    String? createdAt,
    String? reviewNote,
    bool? isSelf,
    Fragment$PersonalFields? details,
    bool? hasPhoto,
    String? currentPhone,
    Fragment$PersonalFields? currentDetails,
    String? $__typename,
  }) => _res;

  CopyWith$Fragment$PersonalFields<TRes> get details =>
      CopyWith$Fragment$PersonalFields.stub(_res);

  CopyWith$Fragment$PersonalFields<TRes> get currentDetails =>
      CopyWith$Fragment$PersonalFields.stub(_res);
}

class Variables$Query$EmployeeDetails {
  factory Variables$Query$EmployeeDetails({
    required String siteId,
    required String employeeId,
  }) => Variables$Query$EmployeeDetails._({
    r'siteId': siteId,
    r'employeeId': employeeId,
  });

  Variables$Query$EmployeeDetails._(this._$data);

  factory Variables$Query$EmployeeDetails.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    final l$employeeId = data['employeeId'];
    result$data['employeeId'] = (l$employeeId as String);
    return Variables$Query$EmployeeDetails._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  String get employeeId => (_$data['employeeId'] as String);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    final l$employeeId = employeeId;
    result$data['employeeId'] = l$employeeId;
    return result$data;
  }

  CopyWith$Variables$Query$EmployeeDetails<Variables$Query$EmployeeDetails>
  get copyWith => CopyWith$Variables$Query$EmployeeDetails(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$EmployeeDetails ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    final l$employeeId = employeeId;
    final lOther$employeeId = other.employeeId;
    if (l$employeeId != lOther$employeeId) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    final l$employeeId = employeeId;
    return Object.hashAll([l$siteId, l$employeeId]);
  }
}

abstract class CopyWith$Variables$Query$EmployeeDetails<TRes> {
  factory CopyWith$Variables$Query$EmployeeDetails(
    Variables$Query$EmployeeDetails instance,
    TRes Function(Variables$Query$EmployeeDetails) then,
  ) = _CopyWithImpl$Variables$Query$EmployeeDetails;

  factory CopyWith$Variables$Query$EmployeeDetails.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$EmployeeDetails;

  TRes call({String? siteId, String? employeeId});
}

class _CopyWithImpl$Variables$Query$EmployeeDetails<TRes>
    implements CopyWith$Variables$Query$EmployeeDetails<TRes> {
  _CopyWithImpl$Variables$Query$EmployeeDetails(this._instance, this._then);

  final Variables$Query$EmployeeDetails _instance;

  final TRes Function(Variables$Query$EmployeeDetails) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? siteId = _undefined, Object? employeeId = _undefined}) =>
      _then(
        Variables$Query$EmployeeDetails._({
          ..._instance._$data,
          if (siteId != _undefined && siteId != null)
            'siteId': (siteId as String),
          if (employeeId != _undefined && employeeId != null)
            'employeeId': (employeeId as String),
        }),
      );
}

class _CopyWithStubImpl$Variables$Query$EmployeeDetails<TRes>
    implements CopyWith$Variables$Query$EmployeeDetails<TRes> {
  _CopyWithStubImpl$Variables$Query$EmployeeDetails(this._res);

  TRes _res;

  call({String? siteId, String? employeeId}) => _res;
}

class Query$EmployeeDetails {
  Query$EmployeeDetails({
    required this.employeeDetails,
    this.$__typename = 'Query',
  });

  factory Query$EmployeeDetails.fromJson(Map<String, dynamic> json) {
    final l$employeeDetails = json['employeeDetails'];
    final l$$__typename = json['__typename'];
    return Query$EmployeeDetails(
      employeeDetails: Query$EmployeeDetails$employeeDetails.fromJson(
        (l$employeeDetails as Map<String, dynamic>),
      ),
      $__typename: (l$$__typename as String),
    );
  }

  final Query$EmployeeDetails$employeeDetails employeeDetails;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$employeeDetails = employeeDetails;
    _resultData['employeeDetails'] = l$employeeDetails.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$employeeDetails = employeeDetails;
    final l$$__typename = $__typename;
    return Object.hashAll([l$employeeDetails, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$EmployeeDetails || runtimeType != other.runtimeType) {
      return false;
    }
    final l$employeeDetails = employeeDetails;
    final lOther$employeeDetails = other.employeeDetails;
    if (l$employeeDetails != lOther$employeeDetails) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$EmployeeDetails on Query$EmployeeDetails {
  CopyWith$Query$EmployeeDetails<Query$EmployeeDetails> get copyWith =>
      CopyWith$Query$EmployeeDetails(this, (i) => i);
}

abstract class CopyWith$Query$EmployeeDetails<TRes> {
  factory CopyWith$Query$EmployeeDetails(
    Query$EmployeeDetails instance,
    TRes Function(Query$EmployeeDetails) then,
  ) = _CopyWithImpl$Query$EmployeeDetails;

  factory CopyWith$Query$EmployeeDetails.stub(TRes res) =
      _CopyWithStubImpl$Query$EmployeeDetails;

  TRes call({
    Query$EmployeeDetails$employeeDetails? employeeDetails,
    String? $__typename,
  });
  CopyWith$Query$EmployeeDetails$employeeDetails<TRes> get employeeDetails;
}

class _CopyWithImpl$Query$EmployeeDetails<TRes>
    implements CopyWith$Query$EmployeeDetails<TRes> {
  _CopyWithImpl$Query$EmployeeDetails(this._instance, this._then);

  final Query$EmployeeDetails _instance;

  final TRes Function(Query$EmployeeDetails) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? employeeDetails = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$EmployeeDetails(
      employeeDetails: employeeDetails == _undefined || employeeDetails == null
          ? _instance.employeeDetails
          : (employeeDetails as Query$EmployeeDetails$employeeDetails),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Query$EmployeeDetails$employeeDetails<TRes> get employeeDetails {
    final local$employeeDetails = _instance.employeeDetails;
    return CopyWith$Query$EmployeeDetails$employeeDetails(
      local$employeeDetails,
      (e) => call(employeeDetails: e),
    );
  }
}

class _CopyWithStubImpl$Query$EmployeeDetails<TRes>
    implements CopyWith$Query$EmployeeDetails<TRes> {
  _CopyWithStubImpl$Query$EmployeeDetails(this._res);

  TRes _res;

  call({
    Query$EmployeeDetails$employeeDetails? employeeDetails,
    String? $__typename,
  }) => _res;

  CopyWith$Query$EmployeeDetails$employeeDetails<TRes> get employeeDetails =>
      CopyWith$Query$EmployeeDetails$employeeDetails.stub(_res);
}

const documentNodeQueryEmployeeDetails = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'EmployeeDetails'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'employeeId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'employeeDetails'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'employeeId'),
                value: VariableNode(name: NameNode(value: 'employeeId')),
              ),
            ],
            directives: [],
            selectionSet: SelectionSetNode(
              selections: [
                FieldNode(
                  name: NameNode(value: 'reporting'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FieldNode(
                        name: NameNode(value: 'id'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'managerId'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'managerName'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'startsOn'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'endsOn'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: '__typename'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                    ],
                  ),
                ),
                FieldNode(
                  name: NameNode(value: 'shift'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FieldNode(
                        name: NameNode(value: 'id'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'name'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'startTime'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'endTime'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: '__typename'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                    ],
                  ),
                ),
                FieldNode(
                  name: NameNode(value: '__typename'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
              ],
            ),
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Query$EmployeeDetails _parserFn$Query$EmployeeDetails(
  Map<String, dynamic> data,
) => Query$EmployeeDetails.fromJson(data);
typedef OnQueryComplete$Query$EmployeeDetails = FutureOr<void> Function(
  Map<String, dynamic>?,
  Query$EmployeeDetails?,
);

class Options$Query$EmployeeDetails
    extends graphql.QueryOptions<Query$EmployeeDetails> {
  Options$Query$EmployeeDetails({
    String? operationName,
    required Variables$Query$EmployeeDetails variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$EmployeeDetails? typedOptimisticResult,
    Duration? pollInterval,
    graphql.Context? context,
    OnQueryComplete$Query$EmployeeDetails? onComplete,
    graphql.OnQueryError? onError,
  }) : onCompleteWithParsed = onComplete,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         pollInterval: pollInterval,
         context: context,
         onComplete: onComplete == null
             ? null
             : (data) => onComplete(
                 data,
                 data == null ? null : _parserFn$Query$EmployeeDetails(data),
               ),
         onError: onError,
         document: documentNodeQueryEmployeeDetails,
         parserFn: _parserFn$Query$EmployeeDetails,
       );

  final OnQueryComplete$Query$EmployeeDetails? onCompleteWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onComplete == null
        ? super.properties
        : super.properties.where((property) => property != onComplete),
    onCompleteWithParsed,
  ];
}

class WatchOptions$Query$EmployeeDetails
    extends graphql.WatchQueryOptions<Query$EmployeeDetails> {
  WatchOptions$Query$EmployeeDetails({
    String? operationName,
    required Variables$Query$EmployeeDetails variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$EmployeeDetails? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeQueryEmployeeDetails,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Query$EmployeeDetails,
       );
}

class FetchMoreOptions$Query$EmployeeDetails extends graphql.FetchMoreOptions {
  FetchMoreOptions$Query$EmployeeDetails({
    required graphql.UpdateQuery updateQuery,
    required Variables$Query$EmployeeDetails variables,
  }) : super(
         updateQuery: updateQuery,
         variables: variables.toJson(),
         document: documentNodeQueryEmployeeDetails,
       );
}

extension ClientExtension$Query$EmployeeDetails on graphql.GraphQLClient {
  Future<graphql.QueryResult<Query$EmployeeDetails>> query$EmployeeDetails(
    Options$Query$EmployeeDetails options,
  ) async => await this.query(options);

  graphql.ObservableQuery<Query$EmployeeDetails> watchQuery$EmployeeDetails(
    WatchOptions$Query$EmployeeDetails options,
  ) => this.watchQuery(options);

  void writeQuery$EmployeeDetails({
    required Query$EmployeeDetails data,
    required Variables$Query$EmployeeDetails variables,
    bool broadcast = true,
  }) => this.writeQuery(
    graphql.Request(
      operation: graphql.Operation(document: documentNodeQueryEmployeeDetails),
      variables: variables.toJson(),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Query$EmployeeDetails? readQuery$EmployeeDetails({
    required Variables$Query$EmployeeDetails variables,
    bool optimistic = true,
  }) {
    final result = this.readQuery(
      graphql.Request(
        operation: graphql.Operation(
          document: documentNodeQueryEmployeeDetails,
        ),
        variables: variables.toJson(),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Query$EmployeeDetails.fromJson(result);
  }
}

class Query$EmployeeDetails$employeeDetails {
  Query$EmployeeDetails$employeeDetails({
    required this.reporting,
    this.shift,
    this.$__typename = 'EmployeeDetails',
  });

  factory Query$EmployeeDetails$employeeDetails.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$reporting = json['reporting'];
    final l$shift = json['shift'];
    final l$$__typename = json['__typename'];
    return Query$EmployeeDetails$employeeDetails(
      reporting: (l$reporting as List<dynamic>)
          .map(
            (e) => Query$EmployeeDetails$employeeDetails$reporting.fromJson(
              (e as Map<String, dynamic>),
            ),
          )
          .toList(),
      shift: l$shift == null
          ? null
          : Query$EmployeeDetails$employeeDetails$shift.fromJson(
              (l$shift as Map<String, dynamic>),
            ),
      $__typename: (l$$__typename as String),
    );
  }

  final List<Query$EmployeeDetails$employeeDetails$reporting> reporting;

  final Query$EmployeeDetails$employeeDetails$shift? shift;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$reporting = reporting;
    _resultData['reporting'] = l$reporting.map((e) => e.toJson()).toList();
    final l$shift = shift;
    _resultData['shift'] = l$shift?.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$reporting = reporting;
    final l$shift = shift;
    final l$$__typename = $__typename;
    return Object.hashAll([
      Object.hashAll(l$reporting.map((v) => v)),
      l$shift,
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$EmployeeDetails$employeeDetails ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$reporting = reporting;
    final lOther$reporting = other.reporting;
    if (l$reporting.length != lOther$reporting.length) {
      return false;
    }
    for (int i = 0; i < l$reporting.length; i++) {
      final l$reporting$entry = l$reporting[i];
      final lOther$reporting$entry = lOther$reporting[i];
      if (l$reporting$entry != lOther$reporting$entry) {
        return false;
      }
    }
    final l$shift = shift;
    final lOther$shift = other.shift;
    if (l$shift != lOther$shift) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$EmployeeDetails$employeeDetails
    on Query$EmployeeDetails$employeeDetails {
  CopyWith$Query$EmployeeDetails$employeeDetails<
    Query$EmployeeDetails$employeeDetails
  >
  get copyWith =>
      CopyWith$Query$EmployeeDetails$employeeDetails(this, (i) => i);
}

abstract class CopyWith$Query$EmployeeDetails$employeeDetails<TRes> {
  factory CopyWith$Query$EmployeeDetails$employeeDetails(
    Query$EmployeeDetails$employeeDetails instance,
    TRes Function(Query$EmployeeDetails$employeeDetails) then,
  ) = _CopyWithImpl$Query$EmployeeDetails$employeeDetails;

  factory CopyWith$Query$EmployeeDetails$employeeDetails.stub(TRes res) =
      _CopyWithStubImpl$Query$EmployeeDetails$employeeDetails;

  TRes call({
    List<Query$EmployeeDetails$employeeDetails$reporting>? reporting,
    Query$EmployeeDetails$employeeDetails$shift? shift,
    String? $__typename,
  });
  TRes reporting(
    Iterable<Query$EmployeeDetails$employeeDetails$reporting> Function(
      Iterable<
        CopyWith$Query$EmployeeDetails$employeeDetails$reporting<
          Query$EmployeeDetails$employeeDetails$reporting
        >
      >,
    )
    _fn,
  );
  CopyWith$Query$EmployeeDetails$employeeDetails$shift<TRes> get shift;
}

class _CopyWithImpl$Query$EmployeeDetails$employeeDetails<TRes>
    implements CopyWith$Query$EmployeeDetails$employeeDetails<TRes> {
  _CopyWithImpl$Query$EmployeeDetails$employeeDetails(
    this._instance,
    this._then,
  );

  final Query$EmployeeDetails$employeeDetails _instance;

  final TRes Function(Query$EmployeeDetails$employeeDetails) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? reporting = _undefined,
    Object? shift = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$EmployeeDetails$employeeDetails(
      reporting: reporting == _undefined || reporting == null
          ? _instance.reporting
          : (reporting
                as List<Query$EmployeeDetails$employeeDetails$reporting>),
      shift: shift == _undefined
          ? _instance.shift
          : (shift as Query$EmployeeDetails$employeeDetails$shift?),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  TRes reporting(
    Iterable<Query$EmployeeDetails$employeeDetails$reporting> Function(
      Iterable<
        CopyWith$Query$EmployeeDetails$employeeDetails$reporting<
          Query$EmployeeDetails$employeeDetails$reporting
        >
      >,
    )
    _fn,
  ) => call(
    reporting: _fn(
      _instance.reporting.map(
        (e) => CopyWith$Query$EmployeeDetails$employeeDetails$reporting(
          e,
          (i) => i,
        ),
      ),
    ).toList(),
  );

  CopyWith$Query$EmployeeDetails$employeeDetails$shift<TRes> get shift {
    final local$shift = _instance.shift;
    return local$shift == null
        ? CopyWith$Query$EmployeeDetails$employeeDetails$shift.stub(
            _then(_instance),
          )
        : CopyWith$Query$EmployeeDetails$employeeDetails$shift(
            local$shift,
            (e) => call(shift: e),
          );
  }
}

class _CopyWithStubImpl$Query$EmployeeDetails$employeeDetails<TRes>
    implements CopyWith$Query$EmployeeDetails$employeeDetails<TRes> {
  _CopyWithStubImpl$Query$EmployeeDetails$employeeDetails(this._res);

  TRes _res;

  call({
    List<Query$EmployeeDetails$employeeDetails$reporting>? reporting,
    Query$EmployeeDetails$employeeDetails$shift? shift,
    String? $__typename,
  }) => _res;

  reporting(_fn) => _res;

  CopyWith$Query$EmployeeDetails$employeeDetails$shift<TRes> get shift =>
      CopyWith$Query$EmployeeDetails$employeeDetails$shift.stub(_res);
}

class Query$EmployeeDetails$employeeDetails$reporting {
  Query$EmployeeDetails$employeeDetails$reporting({
    required this.id,
    required this.managerId,
    required this.managerName,
    required this.startsOn,
    this.endsOn,
    this.$__typename = 'ReportingAssignment',
  });

  factory Query$EmployeeDetails$employeeDetails$reporting.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$id = json['id'];
    final l$managerId = json['managerId'];
    final l$managerName = json['managerName'];
    final l$startsOn = json['startsOn'];
    final l$endsOn = json['endsOn'];
    final l$$__typename = json['__typename'];
    return Query$EmployeeDetails$employeeDetails$reporting(
      id: (l$id as String),
      managerId: (l$managerId as String),
      managerName: (l$managerName as String),
      startsOn: (l$startsOn as String),
      endsOn: (l$endsOn as String?),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String managerId;

  final String managerName;

  final String startsOn;

  final String? endsOn;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$managerId = managerId;
    _resultData['managerId'] = l$managerId;
    final l$managerName = managerName;
    _resultData['managerName'] = l$managerName;
    final l$startsOn = startsOn;
    _resultData['startsOn'] = l$startsOn;
    final l$endsOn = endsOn;
    _resultData['endsOn'] = l$endsOn;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$managerId = managerId;
    final l$managerName = managerName;
    final l$startsOn = startsOn;
    final l$endsOn = endsOn;
    final l$$__typename = $__typename;
    return Object.hashAll([
      l$id,
      l$managerId,
      l$managerName,
      l$startsOn,
      l$endsOn,
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$EmployeeDetails$employeeDetails$reporting ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$managerId = managerId;
    final lOther$managerId = other.managerId;
    if (l$managerId != lOther$managerId) {
      return false;
    }
    final l$managerName = managerName;
    final lOther$managerName = other.managerName;
    if (l$managerName != lOther$managerName) {
      return false;
    }
    final l$startsOn = startsOn;
    final lOther$startsOn = other.startsOn;
    if (l$startsOn != lOther$startsOn) {
      return false;
    }
    final l$endsOn = endsOn;
    final lOther$endsOn = other.endsOn;
    if (l$endsOn != lOther$endsOn) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$EmployeeDetails$employeeDetails$reporting
    on Query$EmployeeDetails$employeeDetails$reporting {
  CopyWith$Query$EmployeeDetails$employeeDetails$reporting<
    Query$EmployeeDetails$employeeDetails$reporting
  >
  get copyWith =>
      CopyWith$Query$EmployeeDetails$employeeDetails$reporting(this, (i) => i);
}

abstract class CopyWith$Query$EmployeeDetails$employeeDetails$reporting<TRes> {
  factory CopyWith$Query$EmployeeDetails$employeeDetails$reporting(
    Query$EmployeeDetails$employeeDetails$reporting instance,
    TRes Function(Query$EmployeeDetails$employeeDetails$reporting) then,
  ) = _CopyWithImpl$Query$EmployeeDetails$employeeDetails$reporting;

  factory CopyWith$Query$EmployeeDetails$employeeDetails$reporting.stub(
    TRes res,
  ) = _CopyWithStubImpl$Query$EmployeeDetails$employeeDetails$reporting;

  TRes call({
    String? id,
    String? managerId,
    String? managerName,
    String? startsOn,
    String? endsOn,
    String? $__typename,
  });
}

class _CopyWithImpl$Query$EmployeeDetails$employeeDetails$reporting<TRes>
    implements CopyWith$Query$EmployeeDetails$employeeDetails$reporting<TRes> {
  _CopyWithImpl$Query$EmployeeDetails$employeeDetails$reporting(
    this._instance,
    this._then,
  );

  final Query$EmployeeDetails$employeeDetails$reporting _instance;

  final TRes Function(Query$EmployeeDetails$employeeDetails$reporting) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? managerId = _undefined,
    Object? managerName = _undefined,
    Object? startsOn = _undefined,
    Object? endsOn = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$EmployeeDetails$employeeDetails$reporting(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      managerId: managerId == _undefined || managerId == null
          ? _instance.managerId
          : (managerId as String),
      managerName: managerName == _undefined || managerName == null
          ? _instance.managerName
          : (managerName as String),
      startsOn: startsOn == _undefined || startsOn == null
          ? _instance.startsOn
          : (startsOn as String),
      endsOn: endsOn == _undefined ? _instance.endsOn : (endsOn as String?),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$EmployeeDetails$employeeDetails$reporting<TRes>
    implements CopyWith$Query$EmployeeDetails$employeeDetails$reporting<TRes> {
  _CopyWithStubImpl$Query$EmployeeDetails$employeeDetails$reporting(this._res);

  TRes _res;

  call({
    String? id,
    String? managerId,
    String? managerName,
    String? startsOn,
    String? endsOn,
    String? $__typename,
  }) => _res;
}

class Query$EmployeeDetails$employeeDetails$shift {
  Query$EmployeeDetails$employeeDetails$shift({
    required this.id,
    required this.name,
    this.startTime,
    this.endTime,
    this.$__typename = 'EmployeeShift',
  });

  factory Query$EmployeeDetails$employeeDetails$shift.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$id = json['id'];
    final l$name = json['name'];
    final l$startTime = json['startTime'];
    final l$endTime = json['endTime'];
    final l$$__typename = json['__typename'];
    return Query$EmployeeDetails$employeeDetails$shift(
      id: (l$id as String),
      name: (l$name as String),
      startTime: (l$startTime as String?),
      endTime: (l$endTime as String?),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String name;

  final String? startTime;

  final String? endTime;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$name = name;
    _resultData['name'] = l$name;
    final l$startTime = startTime;
    _resultData['startTime'] = l$startTime;
    final l$endTime = endTime;
    _resultData['endTime'] = l$endTime;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$name = name;
    final l$startTime = startTime;
    final l$endTime = endTime;
    final l$$__typename = $__typename;
    return Object.hashAll([
      l$id,
      l$name,
      l$startTime,
      l$endTime,
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$EmployeeDetails$employeeDetails$shift ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$name = name;
    final lOther$name = other.name;
    if (l$name != lOther$name) {
      return false;
    }
    final l$startTime = startTime;
    final lOther$startTime = other.startTime;
    if (l$startTime != lOther$startTime) {
      return false;
    }
    final l$endTime = endTime;
    final lOther$endTime = other.endTime;
    if (l$endTime != lOther$endTime) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$EmployeeDetails$employeeDetails$shift
    on Query$EmployeeDetails$employeeDetails$shift {
  CopyWith$Query$EmployeeDetails$employeeDetails$shift<
    Query$EmployeeDetails$employeeDetails$shift
  >
  get copyWith =>
      CopyWith$Query$EmployeeDetails$employeeDetails$shift(this, (i) => i);
}

abstract class CopyWith$Query$EmployeeDetails$employeeDetails$shift<TRes> {
  factory CopyWith$Query$EmployeeDetails$employeeDetails$shift(
    Query$EmployeeDetails$employeeDetails$shift instance,
    TRes Function(Query$EmployeeDetails$employeeDetails$shift) then,
  ) = _CopyWithImpl$Query$EmployeeDetails$employeeDetails$shift;

  factory CopyWith$Query$EmployeeDetails$employeeDetails$shift.stub(TRes res) =
      _CopyWithStubImpl$Query$EmployeeDetails$employeeDetails$shift;

  TRes call({
    String? id,
    String? name,
    String? startTime,
    String? endTime,
    String? $__typename,
  });
}

class _CopyWithImpl$Query$EmployeeDetails$employeeDetails$shift<TRes>
    implements CopyWith$Query$EmployeeDetails$employeeDetails$shift<TRes> {
  _CopyWithImpl$Query$EmployeeDetails$employeeDetails$shift(
    this._instance,
    this._then,
  );

  final Query$EmployeeDetails$employeeDetails$shift _instance;

  final TRes Function(Query$EmployeeDetails$employeeDetails$shift) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? name = _undefined,
    Object? startTime = _undefined,
    Object? endTime = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$EmployeeDetails$employeeDetails$shift(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      name: name == _undefined || name == null
          ? _instance.name
          : (name as String),
      startTime: startTime == _undefined
          ? _instance.startTime
          : (startTime as String?),
      endTime: endTime == _undefined ? _instance.endTime : (endTime as String?),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$EmployeeDetails$employeeDetails$shift<TRes>
    implements CopyWith$Query$EmployeeDetails$employeeDetails$shift<TRes> {
  _CopyWithStubImpl$Query$EmployeeDetails$employeeDetails$shift(this._res);

  TRes _res;

  call({
    String? id,
    String? name,
    String? startTime,
    String? endTime,
    String? $__typename,
  }) => _res;
}

class Variables$Mutation$SaveFoundation {
  factory Variables$Mutation$SaveFoundation({
    required String siteId,
    required String operation,
    required Input$FoundationInput input,
  }) => Variables$Mutation$SaveFoundation._({
    r'siteId': siteId,
    r'operation': operation,
    r'input': input,
  });

  Variables$Mutation$SaveFoundation._(this._$data);

  factory Variables$Mutation$SaveFoundation.fromJson(
    Map<String, dynamic> data,
  ) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    final l$operation = data['operation'];
    result$data['operation'] = (l$operation as String);
    final l$input = data['input'];
    result$data['input'] = Input$FoundationInput.fromJson(
      (l$input as Map<String, dynamic>),
    );
    return Variables$Mutation$SaveFoundation._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  String get operation => (_$data['operation'] as String);

  Input$FoundationInput get input => (_$data['input'] as Input$FoundationInput);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    final l$operation = operation;
    result$data['operation'] = l$operation;
    final l$input = input;
    result$data['input'] = l$input.toJson();
    return result$data;
  }

  CopyWith$Variables$Mutation$SaveFoundation<Variables$Mutation$SaveFoundation>
  get copyWith => CopyWith$Variables$Mutation$SaveFoundation(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Mutation$SaveFoundation ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    final l$operation = operation;
    final lOther$operation = other.operation;
    if (l$operation != lOther$operation) {
      return false;
    }
    final l$input = input;
    final lOther$input = other.input;
    if (l$input != lOther$input) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    final l$operation = operation;
    final l$input = input;
    return Object.hashAll([l$siteId, l$operation, l$input]);
  }
}

abstract class CopyWith$Variables$Mutation$SaveFoundation<TRes> {
  factory CopyWith$Variables$Mutation$SaveFoundation(
    Variables$Mutation$SaveFoundation instance,
    TRes Function(Variables$Mutation$SaveFoundation) then,
  ) = _CopyWithImpl$Variables$Mutation$SaveFoundation;

  factory CopyWith$Variables$Mutation$SaveFoundation.stub(TRes res) =
      _CopyWithStubImpl$Variables$Mutation$SaveFoundation;

  TRes call({String? siteId, String? operation, Input$FoundationInput? input});
}

class _CopyWithImpl$Variables$Mutation$SaveFoundation<TRes>
    implements CopyWith$Variables$Mutation$SaveFoundation<TRes> {
  _CopyWithImpl$Variables$Mutation$SaveFoundation(this._instance, this._then);

  final Variables$Mutation$SaveFoundation _instance;

  final TRes Function(Variables$Mutation$SaveFoundation) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? siteId = _undefined,
    Object? operation = _undefined,
    Object? input = _undefined,
  }) => _then(
    Variables$Mutation$SaveFoundation._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
      if (operation != _undefined && operation != null)
        'operation': (operation as String),
      if (input != _undefined && input != null)
        'input': (input as Input$FoundationInput),
    }),
  );
}

class _CopyWithStubImpl$Variables$Mutation$SaveFoundation<TRes>
    implements CopyWith$Variables$Mutation$SaveFoundation<TRes> {
  _CopyWithStubImpl$Variables$Mutation$SaveFoundation(this._res);

  TRes _res;

  call({String? siteId, String? operation, Input$FoundationInput? input}) =>
      _res;
}

class Mutation$SaveFoundation {
  Mutation$SaveFoundation({
    required this.saveFoundation,
    this.$__typename = 'Mutation',
  });

  factory Mutation$SaveFoundation.fromJson(Map<String, dynamic> json) {
    final l$saveFoundation = json['saveFoundation'];
    final l$$__typename = json['__typename'];
    return Mutation$SaveFoundation(
      saveFoundation: Mutation$SaveFoundation$saveFoundation.fromJson(
        (l$saveFoundation as Map<String, dynamic>),
      ),
      $__typename: (l$$__typename as String),
    );
  }

  final Mutation$SaveFoundation$saveFoundation saveFoundation;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$saveFoundation = saveFoundation;
    _resultData['saveFoundation'] = l$saveFoundation.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$saveFoundation = saveFoundation;
    final l$$__typename = $__typename;
    return Object.hashAll([l$saveFoundation, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Mutation$SaveFoundation || runtimeType != other.runtimeType) {
      return false;
    }
    final l$saveFoundation = saveFoundation;
    final lOther$saveFoundation = other.saveFoundation;
    if (l$saveFoundation != lOther$saveFoundation) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Mutation$SaveFoundation on Mutation$SaveFoundation {
  CopyWith$Mutation$SaveFoundation<Mutation$SaveFoundation> get copyWith =>
      CopyWith$Mutation$SaveFoundation(this, (i) => i);
}

abstract class CopyWith$Mutation$SaveFoundation<TRes> {
  factory CopyWith$Mutation$SaveFoundation(
    Mutation$SaveFoundation instance,
    TRes Function(Mutation$SaveFoundation) then,
  ) = _CopyWithImpl$Mutation$SaveFoundation;

  factory CopyWith$Mutation$SaveFoundation.stub(TRes res) =
      _CopyWithStubImpl$Mutation$SaveFoundation;

  TRes call({
    Mutation$SaveFoundation$saveFoundation? saveFoundation,
    String? $__typename,
  });
  CopyWith$Mutation$SaveFoundation$saveFoundation<TRes> get saveFoundation;
}

class _CopyWithImpl$Mutation$SaveFoundation<TRes>
    implements CopyWith$Mutation$SaveFoundation<TRes> {
  _CopyWithImpl$Mutation$SaveFoundation(this._instance, this._then);

  final Mutation$SaveFoundation _instance;

  final TRes Function(Mutation$SaveFoundation) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? saveFoundation = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Mutation$SaveFoundation(
      saveFoundation: saveFoundation == _undefined || saveFoundation == null
          ? _instance.saveFoundation
          : (saveFoundation as Mutation$SaveFoundation$saveFoundation),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Mutation$SaveFoundation$saveFoundation<TRes> get saveFoundation {
    final local$saveFoundation = _instance.saveFoundation;
    return CopyWith$Mutation$SaveFoundation$saveFoundation(
      local$saveFoundation,
      (e) => call(saveFoundation: e),
    );
  }
}

class _CopyWithStubImpl$Mutation$SaveFoundation<TRes>
    implements CopyWith$Mutation$SaveFoundation<TRes> {
  _CopyWithStubImpl$Mutation$SaveFoundation(this._res);

  TRes _res;

  call({
    Mutation$SaveFoundation$saveFoundation? saveFoundation,
    String? $__typename,
  }) => _res;

  CopyWith$Mutation$SaveFoundation$saveFoundation<TRes> get saveFoundation =>
      CopyWith$Mutation$SaveFoundation$saveFoundation.stub(_res);
}

const documentNodeMutationSaveFoundation = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.mutation,
      name: NameNode(value: 'SaveFoundation'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'operation')),
          type: NamedTypeNode(name: NameNode(value: 'String'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'input')),
          type: NamedTypeNode(
            name: NameNode(value: 'FoundationInput'),
            isNonNull: true,
          ),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'saveFoundation'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'operation'),
                value: VariableNode(name: NameNode(value: 'operation')),
              ),
              ArgumentNode(
                name: NameNode(value: 'input'),
                value: VariableNode(name: NameNode(value: 'input')),
              ),
            ],
            directives: [],
            selectionSet: SelectionSetNode(
              selections: [
                FieldNode(
                  name: NameNode(value: 'id'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'version'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'status'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: '__typename'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
              ],
            ),
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Mutation$SaveFoundation _parserFn$Mutation$SaveFoundation(
  Map<String, dynamic> data,
) => Mutation$SaveFoundation.fromJson(data);
typedef OnMutationCompleted$Mutation$SaveFoundation = FutureOr<void> Function(
  Map<String, dynamic>?,
  Mutation$SaveFoundation?,
);

class Options$Mutation$SaveFoundation
    extends graphql.MutationOptions<Mutation$SaveFoundation> {
  Options$Mutation$SaveFoundation({
    String? operationName,
    required Variables$Mutation$SaveFoundation variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Mutation$SaveFoundation? typedOptimisticResult,
    graphql.Context? context,
    OnMutationCompleted$Mutation$SaveFoundation? onCompleted,
    graphql.OnMutationUpdate<Mutation$SaveFoundation>? update,
    graphql.OnError? onError,
  }) : onCompletedWithParsed = onCompleted,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         onCompleted: onCompleted == null
             ? null
             : (data) => onCompleted(
                 data,
                 data == null ? null : _parserFn$Mutation$SaveFoundation(data),
               ),
         update: update,
         onError: onError,
         document: documentNodeMutationSaveFoundation,
         parserFn: _parserFn$Mutation$SaveFoundation,
       );

  final OnMutationCompleted$Mutation$SaveFoundation? onCompletedWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onCompleted == null
        ? super.properties
        : super.properties.where((property) => property != onCompleted),
    onCompletedWithParsed,
  ];
}

class WatchOptions$Mutation$SaveFoundation
    extends graphql.WatchQueryOptions<Mutation$SaveFoundation> {
  WatchOptions$Mutation$SaveFoundation({
    String? operationName,
    required Variables$Mutation$SaveFoundation variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Mutation$SaveFoundation? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeMutationSaveFoundation,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Mutation$SaveFoundation,
       );
}

extension ClientExtension$Mutation$SaveFoundation on graphql.GraphQLClient {
  Future<graphql.QueryResult<Mutation$SaveFoundation>> mutate$SaveFoundation(
    Options$Mutation$SaveFoundation options,
  ) async => await this.mutate(options);

  graphql.ObservableQuery<Mutation$SaveFoundation> watchMutation$SaveFoundation(
    WatchOptions$Mutation$SaveFoundation options,
  ) => this.watchMutation(options);
}

class Mutation$SaveFoundation$saveFoundation {
  Mutation$SaveFoundation$saveFoundation({
    this.id,
    this.version,
    this.status,
    this.$__typename = 'FoundationResult',
  });

  factory Mutation$SaveFoundation$saveFoundation.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$id = json['id'];
    final l$version = json['version'];
    final l$status = json['status'];
    final l$$__typename = json['__typename'];
    return Mutation$SaveFoundation$saveFoundation(
      id: (l$id as String?),
      version: (l$version as int?),
      status: (l$status as String?),
      $__typename: (l$$__typename as String),
    );
  }

  final String? id;

  final int? version;

  final String? status;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$version = version;
    _resultData['version'] = l$version;
    final l$status = status;
    _resultData['status'] = l$status;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$version = version;
    final l$status = status;
    final l$$__typename = $__typename;
    return Object.hashAll([l$id, l$version, l$status, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Mutation$SaveFoundation$saveFoundation ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$version = version;
    final lOther$version = other.version;
    if (l$version != lOther$version) {
      return false;
    }
    final l$status = status;
    final lOther$status = other.status;
    if (l$status != lOther$status) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Mutation$SaveFoundation$saveFoundation
    on Mutation$SaveFoundation$saveFoundation {
  CopyWith$Mutation$SaveFoundation$saveFoundation<
    Mutation$SaveFoundation$saveFoundation
  >
  get copyWith =>
      CopyWith$Mutation$SaveFoundation$saveFoundation(this, (i) => i);
}

abstract class CopyWith$Mutation$SaveFoundation$saveFoundation<TRes> {
  factory CopyWith$Mutation$SaveFoundation$saveFoundation(
    Mutation$SaveFoundation$saveFoundation instance,
    TRes Function(Mutation$SaveFoundation$saveFoundation) then,
  ) = _CopyWithImpl$Mutation$SaveFoundation$saveFoundation;

  factory CopyWith$Mutation$SaveFoundation$saveFoundation.stub(TRes res) =
      _CopyWithStubImpl$Mutation$SaveFoundation$saveFoundation;

  TRes call({String? id, int? version, String? status, String? $__typename});
}

class _CopyWithImpl$Mutation$SaveFoundation$saveFoundation<TRes>
    implements CopyWith$Mutation$SaveFoundation$saveFoundation<TRes> {
  _CopyWithImpl$Mutation$SaveFoundation$saveFoundation(
    this._instance,
    this._then,
  );

  final Mutation$SaveFoundation$saveFoundation _instance;

  final TRes Function(Mutation$SaveFoundation$saveFoundation) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? version = _undefined,
    Object? status = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Mutation$SaveFoundation$saveFoundation(
      id: id == _undefined ? _instance.id : (id as String?),
      version: version == _undefined ? _instance.version : (version as int?),
      status: status == _undefined ? _instance.status : (status as String?),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Mutation$SaveFoundation$saveFoundation<TRes>
    implements CopyWith$Mutation$SaveFoundation$saveFoundation<TRes> {
  _CopyWithStubImpl$Mutation$SaveFoundation$saveFoundation(this._res);

  TRes _res;

  call({String? id, int? version, String? status, String? $__typename}) => _res;
}

class Variables$Query$OrganizationReport {
  factory Variables$Query$OrganizationReport({required String siteId}) =>
      Variables$Query$OrganizationReport._({r'siteId': siteId});

  Variables$Query$OrganizationReport._(this._$data);

  factory Variables$Query$OrganizationReport.fromJson(
    Map<String, dynamic> data,
  ) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    return Variables$Query$OrganizationReport._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    return result$data;
  }

  CopyWith$Variables$Query$OrganizationReport<
    Variables$Query$OrganizationReport
  >
  get copyWith => CopyWith$Variables$Query$OrganizationReport(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$OrganizationReport ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    return Object.hashAll([l$siteId]);
  }
}

abstract class CopyWith$Variables$Query$OrganizationReport<TRes> {
  factory CopyWith$Variables$Query$OrganizationReport(
    Variables$Query$OrganizationReport instance,
    TRes Function(Variables$Query$OrganizationReport) then,
  ) = _CopyWithImpl$Variables$Query$OrganizationReport;

  factory CopyWith$Variables$Query$OrganizationReport.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$OrganizationReport;

  TRes call({String? siteId});
}

class _CopyWithImpl$Variables$Query$OrganizationReport<TRes>
    implements CopyWith$Variables$Query$OrganizationReport<TRes> {
  _CopyWithImpl$Variables$Query$OrganizationReport(this._instance, this._then);

  final Variables$Query$OrganizationReport _instance;

  final TRes Function(Variables$Query$OrganizationReport) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? siteId = _undefined}) => _then(
    Variables$Query$OrganizationReport._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
    }),
  );
}

class _CopyWithStubImpl$Variables$Query$OrganizationReport<TRes>
    implements CopyWith$Variables$Query$OrganizationReport<TRes> {
  _CopyWithStubImpl$Variables$Query$OrganizationReport(this._res);

  TRes _res;

  call({String? siteId}) => _res;
}

class Query$OrganizationReport {
  Query$OrganizationReport({
    required this.organizationReport,
    this.$__typename = 'Query',
  });

  factory Query$OrganizationReport.fromJson(Map<String, dynamic> json) {
    final l$organizationReport = json['organizationReport'];
    final l$$__typename = json['__typename'];
    return Query$OrganizationReport(
      organizationReport: Query$OrganizationReport$organizationReport.fromJson(
        (l$organizationReport as Map<String, dynamic>),
      ),
      $__typename: (l$$__typename as String),
    );
  }

  final Query$OrganizationReport$organizationReport organizationReport;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$organizationReport = organizationReport;
    _resultData['organizationReport'] = l$organizationReport.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$organizationReport = organizationReport;
    final l$$__typename = $__typename;
    return Object.hashAll([l$organizationReport, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$OrganizationReport ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$organizationReport = organizationReport;
    final lOther$organizationReport = other.organizationReport;
    if (l$organizationReport != lOther$organizationReport) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$OrganizationReport
    on Query$OrganizationReport {
  CopyWith$Query$OrganizationReport<Query$OrganizationReport> get copyWith =>
      CopyWith$Query$OrganizationReport(this, (i) => i);
}

abstract class CopyWith$Query$OrganizationReport<TRes> {
  factory CopyWith$Query$OrganizationReport(
    Query$OrganizationReport instance,
    TRes Function(Query$OrganizationReport) then,
  ) = _CopyWithImpl$Query$OrganizationReport;

  factory CopyWith$Query$OrganizationReport.stub(TRes res) =
      _CopyWithStubImpl$Query$OrganizationReport;

  TRes call({
    Query$OrganizationReport$organizationReport? organizationReport,
    String? $__typename,
  });
  CopyWith$Query$OrganizationReport$organizationReport<TRes>
  get organizationReport;
}

class _CopyWithImpl$Query$OrganizationReport<TRes>
    implements CopyWith$Query$OrganizationReport<TRes> {
  _CopyWithImpl$Query$OrganizationReport(this._instance, this._then);

  final Query$OrganizationReport _instance;

  final TRes Function(Query$OrganizationReport) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? organizationReport = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$OrganizationReport(
      organizationReport:
          organizationReport == _undefined || organizationReport == null
          ? _instance.organizationReport
          : (organizationReport as Query$OrganizationReport$organizationReport),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Query$OrganizationReport$organizationReport<TRes>
  get organizationReport {
    final local$organizationReport = _instance.organizationReport;
    return CopyWith$Query$OrganizationReport$organizationReport(
      local$organizationReport,
      (e) => call(organizationReport: e),
    );
  }
}

class _CopyWithStubImpl$Query$OrganizationReport<TRes>
    implements CopyWith$Query$OrganizationReport<TRes> {
  _CopyWithStubImpl$Query$OrganizationReport(this._res);

  TRes _res;

  call({
    Query$OrganizationReport$organizationReport? organizationReport,
    String? $__typename,
  }) => _res;

  CopyWith$Query$OrganizationReport$organizationReport<TRes>
  get organizationReport =>
      CopyWith$Query$OrganizationReport$organizationReport.stub(_res);
}

const documentNodeQueryOrganizationReport = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'OrganizationReport'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'organizationReport'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
            ],
            directives: [],
            selectionSet: SelectionSetNode(
              selections: [
                FieldNode(
                  name: NameNode(value: 'readOnly'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'rule'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'sites'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FieldNode(
                        name: NameNode(value: 'id'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'name'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'timezone'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'employees'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: '__typename'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                    ],
                  ),
                ),
                FieldNode(
                  name: NameNode(value: '__typename'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
              ],
            ),
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Query$OrganizationReport _parserFn$Query$OrganizationReport(
  Map<String, dynamic> data,
) => Query$OrganizationReport.fromJson(data);
typedef OnQueryComplete$Query$OrganizationReport = FutureOr<void> Function(
  Map<String, dynamic>?,
  Query$OrganizationReport?,
);

class Options$Query$OrganizationReport
    extends graphql.QueryOptions<Query$OrganizationReport> {
  Options$Query$OrganizationReport({
    String? operationName,
    required Variables$Query$OrganizationReport variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$OrganizationReport? typedOptimisticResult,
    Duration? pollInterval,
    graphql.Context? context,
    OnQueryComplete$Query$OrganizationReport? onComplete,
    graphql.OnQueryError? onError,
  }) : onCompleteWithParsed = onComplete,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         pollInterval: pollInterval,
         context: context,
         onComplete: onComplete == null
             ? null
             : (data) => onComplete(
                 data,
                 data == null ? null : _parserFn$Query$OrganizationReport(data),
               ),
         onError: onError,
         document: documentNodeQueryOrganizationReport,
         parserFn: _parserFn$Query$OrganizationReport,
       );

  final OnQueryComplete$Query$OrganizationReport? onCompleteWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onComplete == null
        ? super.properties
        : super.properties.where((property) => property != onComplete),
    onCompleteWithParsed,
  ];
}

class WatchOptions$Query$OrganizationReport
    extends graphql.WatchQueryOptions<Query$OrganizationReport> {
  WatchOptions$Query$OrganizationReport({
    String? operationName,
    required Variables$Query$OrganizationReport variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$OrganizationReport? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeQueryOrganizationReport,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Query$OrganizationReport,
       );
}

class FetchMoreOptions$Query$OrganizationReport
    extends graphql.FetchMoreOptions {
  FetchMoreOptions$Query$OrganizationReport({
    required graphql.UpdateQuery updateQuery,
    required Variables$Query$OrganizationReport variables,
  }) : super(
         updateQuery: updateQuery,
         variables: variables.toJson(),
         document: documentNodeQueryOrganizationReport,
       );
}

extension ClientExtension$Query$OrganizationReport on graphql.GraphQLClient {
  Future<graphql.QueryResult<Query$OrganizationReport>>
  query$OrganizationReport(Options$Query$OrganizationReport options) async =>
      await this.query(options);

  graphql.ObservableQuery<Query$OrganizationReport>
  watchQuery$OrganizationReport(
    WatchOptions$Query$OrganizationReport options,
  ) => this.watchQuery(options);

  void writeQuery$OrganizationReport({
    required Query$OrganizationReport data,
    required Variables$Query$OrganizationReport variables,
    bool broadcast = true,
  }) => this.writeQuery(
    graphql.Request(
      operation: graphql.Operation(
        document: documentNodeQueryOrganizationReport,
      ),
      variables: variables.toJson(),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Query$OrganizationReport? readQuery$OrganizationReport({
    required Variables$Query$OrganizationReport variables,
    bool optimistic = true,
  }) {
    final result = this.readQuery(
      graphql.Request(
        operation: graphql.Operation(
          document: documentNodeQueryOrganizationReport,
        ),
        variables: variables.toJson(),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Query$OrganizationReport.fromJson(result);
  }
}

class Query$OrganizationReport$organizationReport {
  Query$OrganizationReport$organizationReport({
    required this.readOnly,
    required this.rule,
    required this.sites,
    this.$__typename = 'OrganizationReport',
  });

  factory Query$OrganizationReport$organizationReport.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$readOnly = json['readOnly'];
    final l$rule = json['rule'];
    final l$sites = json['sites'];
    final l$$__typename = json['__typename'];
    return Query$OrganizationReport$organizationReport(
      readOnly: (l$readOnly as bool),
      rule: (l$rule as String),
      sites: (l$sites as List<dynamic>)
          .map(
            (e) => Query$OrganizationReport$organizationReport$sites.fromJson(
              (e as Map<String, dynamic>),
            ),
          )
          .toList(),
      $__typename: (l$$__typename as String),
    );
  }

  final bool readOnly;

  final String rule;

  final List<Query$OrganizationReport$organizationReport$sites> sites;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$readOnly = readOnly;
    _resultData['readOnly'] = l$readOnly;
    final l$rule = rule;
    _resultData['rule'] = l$rule;
    final l$sites = sites;
    _resultData['sites'] = l$sites.map((e) => e.toJson()).toList();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$readOnly = readOnly;
    final l$rule = rule;
    final l$sites = sites;
    final l$$__typename = $__typename;
    return Object.hashAll([
      l$readOnly,
      l$rule,
      Object.hashAll(l$sites.map((v) => v)),
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$OrganizationReport$organizationReport ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$readOnly = readOnly;
    final lOther$readOnly = other.readOnly;
    if (l$readOnly != lOther$readOnly) {
      return false;
    }
    final l$rule = rule;
    final lOther$rule = other.rule;
    if (l$rule != lOther$rule) {
      return false;
    }
    final l$sites = sites;
    final lOther$sites = other.sites;
    if (l$sites.length != lOther$sites.length) {
      return false;
    }
    for (int i = 0; i < l$sites.length; i++) {
      final l$sites$entry = l$sites[i];
      final lOther$sites$entry = lOther$sites[i];
      if (l$sites$entry != lOther$sites$entry) {
        return false;
      }
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$OrganizationReport$organizationReport
    on Query$OrganizationReport$organizationReport {
  CopyWith$Query$OrganizationReport$organizationReport<
    Query$OrganizationReport$organizationReport
  >
  get copyWith =>
      CopyWith$Query$OrganizationReport$organizationReport(this, (i) => i);
}

abstract class CopyWith$Query$OrganizationReport$organizationReport<TRes> {
  factory CopyWith$Query$OrganizationReport$organizationReport(
    Query$OrganizationReport$organizationReport instance,
    TRes Function(Query$OrganizationReport$organizationReport) then,
  ) = _CopyWithImpl$Query$OrganizationReport$organizationReport;

  factory CopyWith$Query$OrganizationReport$organizationReport.stub(TRes res) =
      _CopyWithStubImpl$Query$OrganizationReport$organizationReport;

  TRes call({
    bool? readOnly,
    String? rule,
    List<Query$OrganizationReport$organizationReport$sites>? sites,
    String? $__typename,
  });
  TRes sites(
    Iterable<Query$OrganizationReport$organizationReport$sites> Function(
      Iterable<
        CopyWith$Query$OrganizationReport$organizationReport$sites<
          Query$OrganizationReport$organizationReport$sites
        >
      >,
    )
    _fn,
  );
}

class _CopyWithImpl$Query$OrganizationReport$organizationReport<TRes>
    implements CopyWith$Query$OrganizationReport$organizationReport<TRes> {
  _CopyWithImpl$Query$OrganizationReport$organizationReport(
    this._instance,
    this._then,
  );

  final Query$OrganizationReport$organizationReport _instance;

  final TRes Function(Query$OrganizationReport$organizationReport) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? readOnly = _undefined,
    Object? rule = _undefined,
    Object? sites = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$OrganizationReport$organizationReport(
      readOnly: readOnly == _undefined || readOnly == null
          ? _instance.readOnly
          : (readOnly as bool),
      rule: rule == _undefined || rule == null
          ? _instance.rule
          : (rule as String),
      sites: sites == _undefined || sites == null
          ? _instance.sites
          : (sites as List<Query$OrganizationReport$organizationReport$sites>),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  TRes sites(
    Iterable<Query$OrganizationReport$organizationReport$sites> Function(
      Iterable<
        CopyWith$Query$OrganizationReport$organizationReport$sites<
          Query$OrganizationReport$organizationReport$sites
        >
      >,
    )
    _fn,
  ) => call(
    sites: _fn(
      _instance.sites.map(
        (e) => CopyWith$Query$OrganizationReport$organizationReport$sites(
          e,
          (i) => i,
        ),
      ),
    ).toList(),
  );
}

class _CopyWithStubImpl$Query$OrganizationReport$organizationReport<TRes>
    implements CopyWith$Query$OrganizationReport$organizationReport<TRes> {
  _CopyWithStubImpl$Query$OrganizationReport$organizationReport(this._res);

  TRes _res;

  call({
    bool? readOnly,
    String? rule,
    List<Query$OrganizationReport$organizationReport$sites>? sites,
    String? $__typename,
  }) => _res;

  sites(_fn) => _res;
}

class Query$OrganizationReport$organizationReport$sites {
  Query$OrganizationReport$organizationReport$sites({
    required this.id,
    required this.name,
    required this.timezone,
    required this.employees,
    this.$__typename = 'SiteReport',
  });

  factory Query$OrganizationReport$organizationReport$sites.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$id = json['id'];
    final l$name = json['name'];
    final l$timezone = json['timezone'];
    final l$employees = json['employees'];
    final l$$__typename = json['__typename'];
    return Query$OrganizationReport$organizationReport$sites(
      id: (l$id as String),
      name: (l$name as String),
      timezone: (l$timezone as String),
      employees: (l$employees as int),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String name;

  final String timezone;

  final int employees;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$name = name;
    _resultData['name'] = l$name;
    final l$timezone = timezone;
    _resultData['timezone'] = l$timezone;
    final l$employees = employees;
    _resultData['employees'] = l$employees;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$name = name;
    final l$timezone = timezone;
    final l$employees = employees;
    final l$$__typename = $__typename;
    return Object.hashAll([
      l$id,
      l$name,
      l$timezone,
      l$employees,
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$OrganizationReport$organizationReport$sites ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$name = name;
    final lOther$name = other.name;
    if (l$name != lOther$name) {
      return false;
    }
    final l$timezone = timezone;
    final lOther$timezone = other.timezone;
    if (l$timezone != lOther$timezone) {
      return false;
    }
    final l$employees = employees;
    final lOther$employees = other.employees;
    if (l$employees != lOther$employees) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$OrganizationReport$organizationReport$sites
    on Query$OrganizationReport$organizationReport$sites {
  CopyWith$Query$OrganizationReport$organizationReport$sites<
    Query$OrganizationReport$organizationReport$sites
  >
  get copyWith => CopyWith$Query$OrganizationReport$organizationReport$sites(
    this,
    (i) => i,
  );
}

abstract class CopyWith$Query$OrganizationReport$organizationReport$sites<
  TRes
> {
  factory CopyWith$Query$OrganizationReport$organizationReport$sites(
    Query$OrganizationReport$organizationReport$sites instance,
    TRes Function(Query$OrganizationReport$organizationReport$sites) then,
  ) = _CopyWithImpl$Query$OrganizationReport$organizationReport$sites;

  factory CopyWith$Query$OrganizationReport$organizationReport$sites.stub(
    TRes res,
  ) = _CopyWithStubImpl$Query$OrganizationReport$organizationReport$sites;

  TRes call({
    String? id,
    String? name,
    String? timezone,
    int? employees,
    String? $__typename,
  });
}

class _CopyWithImpl$Query$OrganizationReport$organizationReport$sites<TRes>
    implements
        CopyWith$Query$OrganizationReport$organizationReport$sites<TRes> {
  _CopyWithImpl$Query$OrganizationReport$organizationReport$sites(
    this._instance,
    this._then,
  );

  final Query$OrganizationReport$organizationReport$sites _instance;

  final TRes Function(Query$OrganizationReport$organizationReport$sites) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? name = _undefined,
    Object? timezone = _undefined,
    Object? employees = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$OrganizationReport$organizationReport$sites(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      name: name == _undefined || name == null
          ? _instance.name
          : (name as String),
      timezone: timezone == _undefined || timezone == null
          ? _instance.timezone
          : (timezone as String),
      employees: employees == _undefined || employees == null
          ? _instance.employees
          : (employees as int),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$OrganizationReport$organizationReport$sites<TRes>
    implements
        CopyWith$Query$OrganizationReport$organizationReport$sites<TRes> {
  _CopyWithStubImpl$Query$OrganizationReport$organizationReport$sites(
    this._res,
  );

  TRes _res;

  call({
    String? id,
    String? name,
    String? timezone,
    int? employees,
    String? $__typename,
  }) => _res;
}

class Variables$Query$AuditHistory {
  factory Variables$Query$AuditHistory({required String siteId}) =>
      Variables$Query$AuditHistory._({r'siteId': siteId});

  Variables$Query$AuditHistory._(this._$data);

  factory Variables$Query$AuditHistory.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    return Variables$Query$AuditHistory._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    return result$data;
  }

  CopyWith$Variables$Query$AuditHistory<Variables$Query$AuditHistory>
  get copyWith => CopyWith$Variables$Query$AuditHistory(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$AuditHistory ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    return Object.hashAll([l$siteId]);
  }
}

abstract class CopyWith$Variables$Query$AuditHistory<TRes> {
  factory CopyWith$Variables$Query$AuditHistory(
    Variables$Query$AuditHistory instance,
    TRes Function(Variables$Query$AuditHistory) then,
  ) = _CopyWithImpl$Variables$Query$AuditHistory;

  factory CopyWith$Variables$Query$AuditHistory.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$AuditHistory;

  TRes call({String? siteId});
}

class _CopyWithImpl$Variables$Query$AuditHistory<TRes>
    implements CopyWith$Variables$Query$AuditHistory<TRes> {
  _CopyWithImpl$Variables$Query$AuditHistory(this._instance, this._then);

  final Variables$Query$AuditHistory _instance;

  final TRes Function(Variables$Query$AuditHistory) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? siteId = _undefined}) => _then(
    Variables$Query$AuditHistory._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
    }),
  );
}

class _CopyWithStubImpl$Variables$Query$AuditHistory<TRes>
    implements CopyWith$Variables$Query$AuditHistory<TRes> {
  _CopyWithStubImpl$Variables$Query$AuditHistory(this._res);

  TRes _res;

  call({String? siteId}) => _res;
}

class Query$AuditHistory {
  Query$AuditHistory({required this.auditHistory, this.$__typename = 'Query'});

  factory Query$AuditHistory.fromJson(Map<String, dynamic> json) {
    final l$auditHistory = json['auditHistory'];
    final l$$__typename = json['__typename'];
    return Query$AuditHistory(
      auditHistory: (l$auditHistory as List<dynamic>)
          .map(
            (e) => Query$AuditHistory$auditHistory.fromJson(
              (e as Map<String, dynamic>),
            ),
          )
          .toList(),
      $__typename: (l$$__typename as String),
    );
  }

  final List<Query$AuditHistory$auditHistory> auditHistory;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$auditHistory = auditHistory;
    _resultData['auditHistory'] = l$auditHistory
        .map((e) => e.toJson())
        .toList();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$auditHistory = auditHistory;
    final l$$__typename = $__typename;
    return Object.hashAll([
      Object.hashAll(l$auditHistory.map((v) => v)),
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$AuditHistory || runtimeType != other.runtimeType) {
      return false;
    }
    final l$auditHistory = auditHistory;
    final lOther$auditHistory = other.auditHistory;
    if (l$auditHistory.length != lOther$auditHistory.length) {
      return false;
    }
    for (int i = 0; i < l$auditHistory.length; i++) {
      final l$auditHistory$entry = l$auditHistory[i];
      final lOther$auditHistory$entry = lOther$auditHistory[i];
      if (l$auditHistory$entry != lOther$auditHistory$entry) {
        return false;
      }
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$AuditHistory on Query$AuditHistory {
  CopyWith$Query$AuditHistory<Query$AuditHistory> get copyWith =>
      CopyWith$Query$AuditHistory(this, (i) => i);
}

abstract class CopyWith$Query$AuditHistory<TRes> {
  factory CopyWith$Query$AuditHistory(
    Query$AuditHistory instance,
    TRes Function(Query$AuditHistory) then,
  ) = _CopyWithImpl$Query$AuditHistory;

  factory CopyWith$Query$AuditHistory.stub(TRes res) =
      _CopyWithStubImpl$Query$AuditHistory;

  TRes call({
    List<Query$AuditHistory$auditHistory>? auditHistory,
    String? $__typename,
  });
  TRes auditHistory(
    Iterable<Query$AuditHistory$auditHistory> Function(
      Iterable<
        CopyWith$Query$AuditHistory$auditHistory<
          Query$AuditHistory$auditHistory
        >
      >,
    )
    _fn,
  );
}

class _CopyWithImpl$Query$AuditHistory<TRes>
    implements CopyWith$Query$AuditHistory<TRes> {
  _CopyWithImpl$Query$AuditHistory(this._instance, this._then);

  final Query$AuditHistory _instance;

  final TRes Function(Query$AuditHistory) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? auditHistory = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$AuditHistory(
      auditHistory: auditHistory == _undefined || auditHistory == null
          ? _instance.auditHistory
          : (auditHistory as List<Query$AuditHistory$auditHistory>),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  TRes auditHistory(
    Iterable<Query$AuditHistory$auditHistory> Function(
      Iterable<
        CopyWith$Query$AuditHistory$auditHistory<
          Query$AuditHistory$auditHistory
        >
      >,
    )
    _fn,
  ) => call(
    auditHistory: _fn(
      _instance.auditHistory.map(
        (e) => CopyWith$Query$AuditHistory$auditHistory(e, (i) => i),
      ),
    ).toList(),
  );
}

class _CopyWithStubImpl$Query$AuditHistory<TRes>
    implements CopyWith$Query$AuditHistory<TRes> {
  _CopyWithStubImpl$Query$AuditHistory(this._res);

  TRes _res;

  call({
    List<Query$AuditHistory$auditHistory>? auditHistory,
    String? $__typename,
  }) => _res;

  auditHistory(_fn) => _res;
}

const documentNodeQueryAuditHistory = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'AuditHistory'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'auditHistory'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
            ],
            directives: [],
            selectionSet: SelectionSetNode(
              selections: [
                FieldNode(
                  name: NameNode(value: 'id'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'actorId'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'action'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'entityId'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'createdAt'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'reason'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: '__typename'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
              ],
            ),
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Query$AuditHistory _parserFn$Query$AuditHistory(Map<String, dynamic> data) =>
    Query$AuditHistory.fromJson(data);
typedef OnQueryComplete$Query$AuditHistory = FutureOr<void> Function(
  Map<String, dynamic>?,
  Query$AuditHistory?,
);

class Options$Query$AuditHistory
    extends graphql.QueryOptions<Query$AuditHistory> {
  Options$Query$AuditHistory({
    String? operationName,
    required Variables$Query$AuditHistory variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$AuditHistory? typedOptimisticResult,
    Duration? pollInterval,
    graphql.Context? context,
    OnQueryComplete$Query$AuditHistory? onComplete,
    graphql.OnQueryError? onError,
  }) : onCompleteWithParsed = onComplete,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         pollInterval: pollInterval,
         context: context,
         onComplete: onComplete == null
             ? null
             : (data) => onComplete(
                 data,
                 data == null ? null : _parserFn$Query$AuditHistory(data),
               ),
         onError: onError,
         document: documentNodeQueryAuditHistory,
         parserFn: _parserFn$Query$AuditHistory,
       );

  final OnQueryComplete$Query$AuditHistory? onCompleteWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onComplete == null
        ? super.properties
        : super.properties.where((property) => property != onComplete),
    onCompleteWithParsed,
  ];
}

class WatchOptions$Query$AuditHistory
    extends graphql.WatchQueryOptions<Query$AuditHistory> {
  WatchOptions$Query$AuditHistory({
    String? operationName,
    required Variables$Query$AuditHistory variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$AuditHistory? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeQueryAuditHistory,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Query$AuditHistory,
       );
}

class FetchMoreOptions$Query$AuditHistory extends graphql.FetchMoreOptions {
  FetchMoreOptions$Query$AuditHistory({
    required graphql.UpdateQuery updateQuery,
    required Variables$Query$AuditHistory variables,
  }) : super(
         updateQuery: updateQuery,
         variables: variables.toJson(),
         document: documentNodeQueryAuditHistory,
       );
}

extension ClientExtension$Query$AuditHistory on graphql.GraphQLClient {
  Future<graphql.QueryResult<Query$AuditHistory>> query$AuditHistory(
    Options$Query$AuditHistory options,
  ) async => await this.query(options);

  graphql.ObservableQuery<Query$AuditHistory> watchQuery$AuditHistory(
    WatchOptions$Query$AuditHistory options,
  ) => this.watchQuery(options);

  void writeQuery$AuditHistory({
    required Query$AuditHistory data,
    required Variables$Query$AuditHistory variables,
    bool broadcast = true,
  }) => this.writeQuery(
    graphql.Request(
      operation: graphql.Operation(document: documentNodeQueryAuditHistory),
      variables: variables.toJson(),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Query$AuditHistory? readQuery$AuditHistory({
    required Variables$Query$AuditHistory variables,
    bool optimistic = true,
  }) {
    final result = this.readQuery(
      graphql.Request(
        operation: graphql.Operation(document: documentNodeQueryAuditHistory),
        variables: variables.toJson(),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Query$AuditHistory.fromJson(result);
  }
}

class Query$AuditHistory$auditHistory {
  Query$AuditHistory$auditHistory({
    required this.id,
    required this.actorId,
    required this.action,
    required this.entityId,
    required this.createdAt,
    this.reason,
    this.$__typename = 'AuditEntry',
  });

  factory Query$AuditHistory$auditHistory.fromJson(Map<String, dynamic> json) {
    final l$id = json['id'];
    final l$actorId = json['actorId'];
    final l$action = json['action'];
    final l$entityId = json['entityId'];
    final l$createdAt = json['createdAt'];
    final l$reason = json['reason'];
    final l$$__typename = json['__typename'];
    return Query$AuditHistory$auditHistory(
      id: (l$id as String),
      actorId: (l$actorId as String),
      action: (l$action as String),
      entityId: (l$entityId as String),
      createdAt: (l$createdAt as String),
      reason: (l$reason as String?),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String actorId;

  final String action;

  final String entityId;

  final String createdAt;

  final String? reason;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$actorId = actorId;
    _resultData['actorId'] = l$actorId;
    final l$action = action;
    _resultData['action'] = l$action;
    final l$entityId = entityId;
    _resultData['entityId'] = l$entityId;
    final l$createdAt = createdAt;
    _resultData['createdAt'] = l$createdAt;
    final l$reason = reason;
    _resultData['reason'] = l$reason;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$actorId = actorId;
    final l$action = action;
    final l$entityId = entityId;
    final l$createdAt = createdAt;
    final l$reason = reason;
    final l$$__typename = $__typename;
    return Object.hashAll([
      l$id,
      l$actorId,
      l$action,
      l$entityId,
      l$createdAt,
      l$reason,
      l$$__typename,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$AuditHistory$auditHistory ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$actorId = actorId;
    final lOther$actorId = other.actorId;
    if (l$actorId != lOther$actorId) {
      return false;
    }
    final l$action = action;
    final lOther$action = other.action;
    if (l$action != lOther$action) {
      return false;
    }
    final l$entityId = entityId;
    final lOther$entityId = other.entityId;
    if (l$entityId != lOther$entityId) {
      return false;
    }
    final l$createdAt = createdAt;
    final lOther$createdAt = other.createdAt;
    if (l$createdAt != lOther$createdAt) {
      return false;
    }
    final l$reason = reason;
    final lOther$reason = other.reason;
    if (l$reason != lOther$reason) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$AuditHistory$auditHistory
    on Query$AuditHistory$auditHistory {
  CopyWith$Query$AuditHistory$auditHistory<Query$AuditHistory$auditHistory>
  get copyWith => CopyWith$Query$AuditHistory$auditHistory(this, (i) => i);
}

abstract class CopyWith$Query$AuditHistory$auditHistory<TRes> {
  factory CopyWith$Query$AuditHistory$auditHistory(
    Query$AuditHistory$auditHistory instance,
    TRes Function(Query$AuditHistory$auditHistory) then,
  ) = _CopyWithImpl$Query$AuditHistory$auditHistory;

  factory CopyWith$Query$AuditHistory$auditHistory.stub(TRes res) =
      _CopyWithStubImpl$Query$AuditHistory$auditHistory;

  TRes call({
    String? id,
    String? actorId,
    String? action,
    String? entityId,
    String? createdAt,
    String? reason,
    String? $__typename,
  });
}

class _CopyWithImpl$Query$AuditHistory$auditHistory<TRes>
    implements CopyWith$Query$AuditHistory$auditHistory<TRes> {
  _CopyWithImpl$Query$AuditHistory$auditHistory(this._instance, this._then);

  final Query$AuditHistory$auditHistory _instance;

  final TRes Function(Query$AuditHistory$auditHistory) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? actorId = _undefined,
    Object? action = _undefined,
    Object? entityId = _undefined,
    Object? createdAt = _undefined,
    Object? reason = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$AuditHistory$auditHistory(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      actorId: actorId == _undefined || actorId == null
          ? _instance.actorId
          : (actorId as String),
      action: action == _undefined || action == null
          ? _instance.action
          : (action as String),
      entityId: entityId == _undefined || entityId == null
          ? _instance.entityId
          : (entityId as String),
      createdAt: createdAt == _undefined || createdAt == null
          ? _instance.createdAt
          : (createdAt as String),
      reason: reason == _undefined ? _instance.reason : (reason as String?),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$AuditHistory$auditHistory<TRes>
    implements CopyWith$Query$AuditHistory$auditHistory<TRes> {
  _CopyWithStubImpl$Query$AuditHistory$auditHistory(this._res);

  TRes _res;

  call({
    String? id,
    String? actorId,
    String? action,
    String? entityId,
    String? createdAt,
    String? reason,
    String? $__typename,
  }) => _res;
}

class Variables$Mutation$QueueExport {
  factory Variables$Mutation$QueueExport({
    required String siteId,
    required List<String> fields,
  }) =>
      Variables$Mutation$QueueExport._({r'siteId': siteId, r'fields': fields});

  Variables$Mutation$QueueExport._(this._$data);

  factory Variables$Mutation$QueueExport.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    final l$fields = data['fields'];
    result$data['fields'] = (l$fields as List<dynamic>)
        .map((e) => (e as String))
        .toList();
    return Variables$Mutation$QueueExport._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  List<String> get fields => (_$data['fields'] as List<String>);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    final l$fields = fields;
    result$data['fields'] = l$fields.map((e) => e).toList();
    return result$data;
  }

  CopyWith$Variables$Mutation$QueueExport<Variables$Mutation$QueueExport>
  get copyWith => CopyWith$Variables$Mutation$QueueExport(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Mutation$QueueExport ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    final l$fields = fields;
    final lOther$fields = other.fields;
    if (l$fields.length != lOther$fields.length) {
      return false;
    }
    for (int i = 0; i < l$fields.length; i++) {
      final l$fields$entry = l$fields[i];
      final lOther$fields$entry = lOther$fields[i];
      if (l$fields$entry != lOther$fields$entry) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    final l$fields = fields;
    return Object.hashAll([l$siteId, Object.hashAll(l$fields.map((v) => v))]);
  }
}

abstract class CopyWith$Variables$Mutation$QueueExport<TRes> {
  factory CopyWith$Variables$Mutation$QueueExport(
    Variables$Mutation$QueueExport instance,
    TRes Function(Variables$Mutation$QueueExport) then,
  ) = _CopyWithImpl$Variables$Mutation$QueueExport;

  factory CopyWith$Variables$Mutation$QueueExport.stub(TRes res) =
      _CopyWithStubImpl$Variables$Mutation$QueueExport;

  TRes call({String? siteId, List<String>? fields});
}

class _CopyWithImpl$Variables$Mutation$QueueExport<TRes>
    implements CopyWith$Variables$Mutation$QueueExport<TRes> {
  _CopyWithImpl$Variables$Mutation$QueueExport(this._instance, this._then);

  final Variables$Mutation$QueueExport _instance;

  final TRes Function(Variables$Mutation$QueueExport) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? siteId = _undefined, Object? fields = _undefined}) =>
      _then(
        Variables$Mutation$QueueExport._({
          ..._instance._$data,
          if (siteId != _undefined && siteId != null)
            'siteId': (siteId as String),
          if (fields != _undefined && fields != null)
            'fields': (fields as List<String>),
        }),
      );
}

class _CopyWithStubImpl$Variables$Mutation$QueueExport<TRes>
    implements CopyWith$Variables$Mutation$QueueExport<TRes> {
  _CopyWithStubImpl$Variables$Mutation$QueueExport(this._res);

  TRes _res;

  call({String? siteId, List<String>? fields}) => _res;
}

class Mutation$QueueExport {
  Mutation$QueueExport({
    required this.queueExport,
    this.$__typename = 'Mutation',
  });

  factory Mutation$QueueExport.fromJson(Map<String, dynamic> json) {
    final l$queueExport = json['queueExport'];
    final l$$__typename = json['__typename'];
    return Mutation$QueueExport(
      queueExport: Mutation$QueueExport$queueExport.fromJson(
        (l$queueExport as Map<String, dynamic>),
      ),
      $__typename: (l$$__typename as String),
    );
  }

  final Mutation$QueueExport$queueExport queueExport;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$queueExport = queueExport;
    _resultData['queueExport'] = l$queueExport.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$queueExport = queueExport;
    final l$$__typename = $__typename;
    return Object.hashAll([l$queueExport, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Mutation$QueueExport || runtimeType != other.runtimeType) {
      return false;
    }
    final l$queueExport = queueExport;
    final lOther$queueExport = other.queueExport;
    if (l$queueExport != lOther$queueExport) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Mutation$QueueExport on Mutation$QueueExport {
  CopyWith$Mutation$QueueExport<Mutation$QueueExport> get copyWith =>
      CopyWith$Mutation$QueueExport(this, (i) => i);
}

abstract class CopyWith$Mutation$QueueExport<TRes> {
  factory CopyWith$Mutation$QueueExport(
    Mutation$QueueExport instance,
    TRes Function(Mutation$QueueExport) then,
  ) = _CopyWithImpl$Mutation$QueueExport;

  factory CopyWith$Mutation$QueueExport.stub(TRes res) =
      _CopyWithStubImpl$Mutation$QueueExport;

  TRes call({
    Mutation$QueueExport$queueExport? queueExport,
    String? $__typename,
  });
  CopyWith$Mutation$QueueExport$queueExport<TRes> get queueExport;
}

class _CopyWithImpl$Mutation$QueueExport<TRes>
    implements CopyWith$Mutation$QueueExport<TRes> {
  _CopyWithImpl$Mutation$QueueExport(this._instance, this._then);

  final Mutation$QueueExport _instance;

  final TRes Function(Mutation$QueueExport) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? queueExport = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Mutation$QueueExport(
      queueExport: queueExport == _undefined || queueExport == null
          ? _instance.queueExport
          : (queueExport as Mutation$QueueExport$queueExport),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Mutation$QueueExport$queueExport<TRes> get queueExport {
    final local$queueExport = _instance.queueExport;
    return CopyWith$Mutation$QueueExport$queueExport(
      local$queueExport,
      (e) => call(queueExport: e),
    );
  }
}

class _CopyWithStubImpl$Mutation$QueueExport<TRes>
    implements CopyWith$Mutation$QueueExport<TRes> {
  _CopyWithStubImpl$Mutation$QueueExport(this._res);

  TRes _res;

  call({Mutation$QueueExport$queueExport? queueExport, String? $__typename}) =>
      _res;

  CopyWith$Mutation$QueueExport$queueExport<TRes> get queueExport =>
      CopyWith$Mutation$QueueExport$queueExport.stub(_res);
}

const documentNodeMutationQueueExport = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.mutation,
      name: NameNode(value: 'QueueExport'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'fields')),
          type: ListTypeNode(
            type: NamedTypeNode(
              name: NameNode(value: 'String'),
              isNonNull: true,
            ),
            isNonNull: true,
          ),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'queueExport'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'fields'),
                value: VariableNode(name: NameNode(value: 'fields')),
              ),
            ],
            directives: [],
            selectionSet: SelectionSetNode(
              selections: [
                FieldNode(
                  name: NameNode(value: 'id'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'status'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: '__typename'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
              ],
            ),
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Mutation$QueueExport _parserFn$Mutation$QueueExport(
  Map<String, dynamic> data,
) => Mutation$QueueExport.fromJson(data);
typedef OnMutationCompleted$Mutation$QueueExport = FutureOr<void> Function(
  Map<String, dynamic>?,
  Mutation$QueueExport?,
);

class Options$Mutation$QueueExport
    extends graphql.MutationOptions<Mutation$QueueExport> {
  Options$Mutation$QueueExport({
    String? operationName,
    required Variables$Mutation$QueueExport variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Mutation$QueueExport? typedOptimisticResult,
    graphql.Context? context,
    OnMutationCompleted$Mutation$QueueExport? onCompleted,
    graphql.OnMutationUpdate<Mutation$QueueExport>? update,
    graphql.OnError? onError,
  }) : onCompletedWithParsed = onCompleted,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         onCompleted: onCompleted == null
             ? null
             : (data) => onCompleted(
                 data,
                 data == null ? null : _parserFn$Mutation$QueueExport(data),
               ),
         update: update,
         onError: onError,
         document: documentNodeMutationQueueExport,
         parserFn: _parserFn$Mutation$QueueExport,
       );

  final OnMutationCompleted$Mutation$QueueExport? onCompletedWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onCompleted == null
        ? super.properties
        : super.properties.where((property) => property != onCompleted),
    onCompletedWithParsed,
  ];
}

class WatchOptions$Mutation$QueueExport
    extends graphql.WatchQueryOptions<Mutation$QueueExport> {
  WatchOptions$Mutation$QueueExport({
    String? operationName,
    required Variables$Mutation$QueueExport variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Mutation$QueueExport? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeMutationQueueExport,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Mutation$QueueExport,
       );
}

extension ClientExtension$Mutation$QueueExport on graphql.GraphQLClient {
  Future<graphql.QueryResult<Mutation$QueueExport>> mutate$QueueExport(
    Options$Mutation$QueueExport options,
  ) async => await this.mutate(options);

  graphql.ObservableQuery<Mutation$QueueExport> watchMutation$QueueExport(
    WatchOptions$Mutation$QueueExport options,
  ) => this.watchMutation(options);
}

class Mutation$QueueExport$queueExport {
  Mutation$QueueExport$queueExport({
    required this.id,
    required this.status,
    this.$__typename = 'ExportJob',
  });

  factory Mutation$QueueExport$queueExport.fromJson(Map<String, dynamic> json) {
    final l$id = json['id'];
    final l$status = json['status'];
    final l$$__typename = json['__typename'];
    return Mutation$QueueExport$queueExport(
      id: (l$id as String),
      status: (l$status as String),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String status;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$status = status;
    _resultData['status'] = l$status;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$status = status;
    final l$$__typename = $__typename;
    return Object.hashAll([l$id, l$status, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Mutation$QueueExport$queueExport ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$status = status;
    final lOther$status = other.status;
    if (l$status != lOther$status) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Mutation$QueueExport$queueExport
    on Mutation$QueueExport$queueExport {
  CopyWith$Mutation$QueueExport$queueExport<Mutation$QueueExport$queueExport>
  get copyWith => CopyWith$Mutation$QueueExport$queueExport(this, (i) => i);
}

abstract class CopyWith$Mutation$QueueExport$queueExport<TRes> {
  factory CopyWith$Mutation$QueueExport$queueExport(
    Mutation$QueueExport$queueExport instance,
    TRes Function(Mutation$QueueExport$queueExport) then,
  ) = _CopyWithImpl$Mutation$QueueExport$queueExport;

  factory CopyWith$Mutation$QueueExport$queueExport.stub(TRes res) =
      _CopyWithStubImpl$Mutation$QueueExport$queueExport;

  TRes call({String? id, String? status, String? $__typename});
}

class _CopyWithImpl$Mutation$QueueExport$queueExport<TRes>
    implements CopyWith$Mutation$QueueExport$queueExport<TRes> {
  _CopyWithImpl$Mutation$QueueExport$queueExport(this._instance, this._then);

  final Mutation$QueueExport$queueExport _instance;

  final TRes Function(Mutation$QueueExport$queueExport) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? status = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Mutation$QueueExport$queueExport(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      status: status == _undefined || status == null
          ? _instance.status
          : (status as String),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Mutation$QueueExport$queueExport<TRes>
    implements CopyWith$Mutation$QueueExport$queueExport<TRes> {
  _CopyWithStubImpl$Mutation$QueueExport$queueExport(this._res);

  TRes _res;

  call({String? id, String? status, String? $__typename}) => _res;
}

class Variables$Query$ExportJob {
  factory Variables$Query$ExportJob({
    required String siteId,
    required String id,
  }) => Variables$Query$ExportJob._({r'siteId': siteId, r'id': id});

  Variables$Query$ExportJob._(this._$data);

  factory Variables$Query$ExportJob.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    final l$id = data['id'];
    result$data['id'] = (l$id as String);
    return Variables$Query$ExportJob._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  String get id => (_$data['id'] as String);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    final l$id = id;
    result$data['id'] = l$id;
    return result$data;
  }

  CopyWith$Variables$Query$ExportJob<Variables$Query$ExportJob> get copyWith =>
      CopyWith$Variables$Query$ExportJob(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$ExportJob ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    final l$id = id;
    return Object.hashAll([l$siteId, l$id]);
  }
}

abstract class CopyWith$Variables$Query$ExportJob<TRes> {
  factory CopyWith$Variables$Query$ExportJob(
    Variables$Query$ExportJob instance,
    TRes Function(Variables$Query$ExportJob) then,
  ) = _CopyWithImpl$Variables$Query$ExportJob;

  factory CopyWith$Variables$Query$ExportJob.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$ExportJob;

  TRes call({String? siteId, String? id});
}

class _CopyWithImpl$Variables$Query$ExportJob<TRes>
    implements CopyWith$Variables$Query$ExportJob<TRes> {
  _CopyWithImpl$Variables$Query$ExportJob(this._instance, this._then);

  final Variables$Query$ExportJob _instance;

  final TRes Function(Variables$Query$ExportJob) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? siteId = _undefined, Object? id = _undefined}) => _then(
    Variables$Query$ExportJob._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
      if (id != _undefined && id != null) 'id': (id as String),
    }),
  );
}

class _CopyWithStubImpl$Variables$Query$ExportJob<TRes>
    implements CopyWith$Variables$Query$ExportJob<TRes> {
  _CopyWithStubImpl$Variables$Query$ExportJob(this._res);

  TRes _res;

  call({String? siteId, String? id}) => _res;
}

class Query$ExportJob {
  Query$ExportJob({required this.exportJob, this.$__typename = 'Query'});

  factory Query$ExportJob.fromJson(Map<String, dynamic> json) {
    final l$exportJob = json['exportJob'];
    final l$$__typename = json['__typename'];
    return Query$ExportJob(
      exportJob: Query$ExportJob$exportJob.fromJson(
        (l$exportJob as Map<String, dynamic>),
      ),
      $__typename: (l$$__typename as String),
    );
  }

  final Query$ExportJob$exportJob exportJob;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$exportJob = exportJob;
    _resultData['exportJob'] = l$exportJob.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$exportJob = exportJob;
    final l$$__typename = $__typename;
    return Object.hashAll([l$exportJob, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$ExportJob || runtimeType != other.runtimeType) {
      return false;
    }
    final l$exportJob = exportJob;
    final lOther$exportJob = other.exportJob;
    if (l$exportJob != lOther$exportJob) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$ExportJob on Query$ExportJob {
  CopyWith$Query$ExportJob<Query$ExportJob> get copyWith =>
      CopyWith$Query$ExportJob(this, (i) => i);
}

abstract class CopyWith$Query$ExportJob<TRes> {
  factory CopyWith$Query$ExportJob(
    Query$ExportJob instance,
    TRes Function(Query$ExportJob) then,
  ) = _CopyWithImpl$Query$ExportJob;

  factory CopyWith$Query$ExportJob.stub(TRes res) =
      _CopyWithStubImpl$Query$ExportJob;

  TRes call({Query$ExportJob$exportJob? exportJob, String? $__typename});
  CopyWith$Query$ExportJob$exportJob<TRes> get exportJob;
}

class _CopyWithImpl$Query$ExportJob<TRes>
    implements CopyWith$Query$ExportJob<TRes> {
  _CopyWithImpl$Query$ExportJob(this._instance, this._then);

  final Query$ExportJob _instance;

  final TRes Function(Query$ExportJob) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? exportJob = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$ExportJob(
      exportJob: exportJob == _undefined || exportJob == null
          ? _instance.exportJob
          : (exportJob as Query$ExportJob$exportJob),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Query$ExportJob$exportJob<TRes> get exportJob {
    final local$exportJob = _instance.exportJob;
    return CopyWith$Query$ExportJob$exportJob(
      local$exportJob,
      (e) => call(exportJob: e),
    );
  }
}

class _CopyWithStubImpl$Query$ExportJob<TRes>
    implements CopyWith$Query$ExportJob<TRes> {
  _CopyWithStubImpl$Query$ExportJob(this._res);

  TRes _res;

  call({Query$ExportJob$exportJob? exportJob, String? $__typename}) => _res;

  CopyWith$Query$ExportJob$exportJob<TRes> get exportJob =>
      CopyWith$Query$ExportJob$exportJob.stub(_res);
}

const documentNodeQueryExportJob = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'ExportJob'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'id')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'exportJob'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'id'),
                value: VariableNode(name: NameNode(value: 'id')),
              ),
            ],
            directives: [],
            selectionSet: SelectionSetNode(
              selections: [
                FieldNode(
                  name: NameNode(value: 'id'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'status'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'expiresAt'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: '__typename'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
              ],
            ),
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Query$ExportJob _parserFn$Query$ExportJob(Map<String, dynamic> data) =>
    Query$ExportJob.fromJson(data);
typedef OnQueryComplete$Query$ExportJob = FutureOr<void> Function(
  Map<String, dynamic>?,
  Query$ExportJob?,
);

class Options$Query$ExportJob extends graphql.QueryOptions<Query$ExportJob> {
  Options$Query$ExportJob({
    String? operationName,
    required Variables$Query$ExportJob variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$ExportJob? typedOptimisticResult,
    Duration? pollInterval,
    graphql.Context? context,
    OnQueryComplete$Query$ExportJob? onComplete,
    graphql.OnQueryError? onError,
  }) : onCompleteWithParsed = onComplete,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         pollInterval: pollInterval,
         context: context,
         onComplete: onComplete == null
             ? null
             : (data) => onComplete(
                 data,
                 data == null ? null : _parserFn$Query$ExportJob(data),
               ),
         onError: onError,
         document: documentNodeQueryExportJob,
         parserFn: _parserFn$Query$ExportJob,
       );

  final OnQueryComplete$Query$ExportJob? onCompleteWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onComplete == null
        ? super.properties
        : super.properties.where((property) => property != onComplete),
    onCompleteWithParsed,
  ];
}

class WatchOptions$Query$ExportJob
    extends graphql.WatchQueryOptions<Query$ExportJob> {
  WatchOptions$Query$ExportJob({
    String? operationName,
    required Variables$Query$ExportJob variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$ExportJob? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeQueryExportJob,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Query$ExportJob,
       );
}

class FetchMoreOptions$Query$ExportJob extends graphql.FetchMoreOptions {
  FetchMoreOptions$Query$ExportJob({
    required graphql.UpdateQuery updateQuery,
    required Variables$Query$ExportJob variables,
  }) : super(
         updateQuery: updateQuery,
         variables: variables.toJson(),
         document: documentNodeQueryExportJob,
       );
}

extension ClientExtension$Query$ExportJob on graphql.GraphQLClient {
  Future<graphql.QueryResult<Query$ExportJob>> query$ExportJob(
    Options$Query$ExportJob options,
  ) async => await this.query(options);

  graphql.ObservableQuery<Query$ExportJob> watchQuery$ExportJob(
    WatchOptions$Query$ExportJob options,
  ) => this.watchQuery(options);

  void writeQuery$ExportJob({
    required Query$ExportJob data,
    required Variables$Query$ExportJob variables,
    bool broadcast = true,
  }) => this.writeQuery(
    graphql.Request(
      operation: graphql.Operation(document: documentNodeQueryExportJob),
      variables: variables.toJson(),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Query$ExportJob? readQuery$ExportJob({
    required Variables$Query$ExportJob variables,
    bool optimistic = true,
  }) {
    final result = this.readQuery(
      graphql.Request(
        operation: graphql.Operation(document: documentNodeQueryExportJob),
        variables: variables.toJson(),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Query$ExportJob.fromJson(result);
  }
}

class Query$ExportJob$exportJob {
  Query$ExportJob$exportJob({
    required this.id,
    required this.status,
    this.expiresAt,
    this.$__typename = 'ExportJob',
  });

  factory Query$ExportJob$exportJob.fromJson(Map<String, dynamic> json) {
    final l$id = json['id'];
    final l$status = json['status'];
    final l$expiresAt = json['expiresAt'];
    final l$$__typename = json['__typename'];
    return Query$ExportJob$exportJob(
      id: (l$id as String),
      status: (l$status as String),
      expiresAt: (l$expiresAt as String?),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final String status;

  final String? expiresAt;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$status = status;
    _resultData['status'] = l$status;
    final l$expiresAt = expiresAt;
    _resultData['expiresAt'] = l$expiresAt;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$status = status;
    final l$expiresAt = expiresAt;
    final l$$__typename = $__typename;
    return Object.hashAll([l$id, l$status, l$expiresAt, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$ExportJob$exportJob ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$status = status;
    final lOther$status = other.status;
    if (l$status != lOther$status) {
      return false;
    }
    final l$expiresAt = expiresAt;
    final lOther$expiresAt = other.expiresAt;
    if (l$expiresAt != lOther$expiresAt) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$ExportJob$exportJob
    on Query$ExportJob$exportJob {
  CopyWith$Query$ExportJob$exportJob<Query$ExportJob$exportJob> get copyWith =>
      CopyWith$Query$ExportJob$exportJob(this, (i) => i);
}

abstract class CopyWith$Query$ExportJob$exportJob<TRes> {
  factory CopyWith$Query$ExportJob$exportJob(
    Query$ExportJob$exportJob instance,
    TRes Function(Query$ExportJob$exportJob) then,
  ) = _CopyWithImpl$Query$ExportJob$exportJob;

  factory CopyWith$Query$ExportJob$exportJob.stub(TRes res) =
      _CopyWithStubImpl$Query$ExportJob$exportJob;

  TRes call({
    String? id,
    String? status,
    String? expiresAt,
    String? $__typename,
  });
}

class _CopyWithImpl$Query$ExportJob$exportJob<TRes>
    implements CopyWith$Query$ExportJob$exportJob<TRes> {
  _CopyWithImpl$Query$ExportJob$exportJob(this._instance, this._then);

  final Query$ExportJob$exportJob _instance;

  final TRes Function(Query$ExportJob$exportJob) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? status = _undefined,
    Object? expiresAt = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$ExportJob$exportJob(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      status: status == _undefined || status == null
          ? _instance.status
          : (status as String),
      expiresAt: expiresAt == _undefined
          ? _instance.expiresAt
          : (expiresAt as String?),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$ExportJob$exportJob<TRes>
    implements CopyWith$Query$ExportJob$exportJob<TRes> {
  _CopyWithStubImpl$Query$ExportJob$exportJob(this._res);

  TRes _res;

  call({String? id, String? status, String? expiresAt, String? $__typename}) =>
      _res;
}

class Variables$Query$Operations {
  factory Variables$Query$Operations({required String siteId}) =>
      Variables$Query$Operations._({r'siteId': siteId});

  Variables$Query$Operations._(this._$data);

  factory Variables$Query$Operations.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    return Variables$Query$Operations._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    return result$data;
  }

  CopyWith$Variables$Query$Operations<Variables$Query$Operations>
  get copyWith => CopyWith$Variables$Query$Operations(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$Operations ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    return Object.hashAll([l$siteId]);
  }
}

abstract class CopyWith$Variables$Query$Operations<TRes> {
  factory CopyWith$Variables$Query$Operations(
    Variables$Query$Operations instance,
    TRes Function(Variables$Query$Operations) then,
  ) = _CopyWithImpl$Variables$Query$Operations;

  factory CopyWith$Variables$Query$Operations.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$Operations;

  TRes call({String? siteId});
}

class _CopyWithImpl$Variables$Query$Operations<TRes>
    implements CopyWith$Variables$Query$Operations<TRes> {
  _CopyWithImpl$Variables$Query$Operations(this._instance, this._then);

  final Variables$Query$Operations _instance;

  final TRes Function(Variables$Query$Operations) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? siteId = _undefined}) => _then(
    Variables$Query$Operations._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
    }),
  );
}

class _CopyWithStubImpl$Variables$Query$Operations<TRes>
    implements CopyWith$Variables$Query$Operations<TRes> {
  _CopyWithStubImpl$Variables$Query$Operations(this._res);

  TRes _res;

  call({String? siteId}) => _res;
}

class Query$Operations {
  Query$Operations({required this.operations, this.$__typename = 'Query'});

  factory Query$Operations.fromJson(Map<String, dynamic> json) {
    final l$operations = json['operations'];
    final l$$__typename = json['__typename'];
    return Query$Operations(
      operations: (l$operations as dynamic),
      $__typename: (l$$__typename as String),
    );
  }

  final dynamic operations;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$operations = operations;
    _resultData['operations'] = l$operations;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$operations = operations;
    final l$$__typename = $__typename;
    return Object.hashAll([l$operations, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$Operations || runtimeType != other.runtimeType) {
      return false;
    }
    final l$operations = operations;
    final lOther$operations = other.operations;
    if (l$operations != lOther$operations) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$Operations on Query$Operations {
  CopyWith$Query$Operations<Query$Operations> get copyWith =>
      CopyWith$Query$Operations(this, (i) => i);
}

abstract class CopyWith$Query$Operations<TRes> {
  factory CopyWith$Query$Operations(
    Query$Operations instance,
    TRes Function(Query$Operations) then,
  ) = _CopyWithImpl$Query$Operations;

  factory CopyWith$Query$Operations.stub(TRes res) =
      _CopyWithStubImpl$Query$Operations;

  TRes call({dynamic? operations, String? $__typename});
}

class _CopyWithImpl$Query$Operations<TRes>
    implements CopyWith$Query$Operations<TRes> {
  _CopyWithImpl$Query$Operations(this._instance, this._then);

  final Query$Operations _instance;

  final TRes Function(Query$Operations) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? operations = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$Operations(
      operations: operations == _undefined || operations == null
          ? _instance.operations
          : (operations as dynamic),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$Operations<TRes>
    implements CopyWith$Query$Operations<TRes> {
  _CopyWithStubImpl$Query$Operations(this._res);

  TRes _res;

  call({dynamic? operations, String? $__typename}) => _res;
}

const documentNodeQueryOperations = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'Operations'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'operations'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
            ],
            directives: [],
            selectionSet: null,
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Query$Operations _parserFn$Query$Operations(Map<String, dynamic> data) =>
    Query$Operations.fromJson(data);
typedef OnQueryComplete$Query$Operations = FutureOr<void> Function(
  Map<String, dynamic>?,
  Query$Operations?,
);

class Options$Query$Operations extends graphql.QueryOptions<Query$Operations> {
  Options$Query$Operations({
    String? operationName,
    required Variables$Query$Operations variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$Operations? typedOptimisticResult,
    Duration? pollInterval,
    graphql.Context? context,
    OnQueryComplete$Query$Operations? onComplete,
    graphql.OnQueryError? onError,
  }) : onCompleteWithParsed = onComplete,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         pollInterval: pollInterval,
         context: context,
         onComplete: onComplete == null
             ? null
             : (data) => onComplete(
                 data,
                 data == null ? null : _parserFn$Query$Operations(data),
               ),
         onError: onError,
         document: documentNodeQueryOperations,
         parserFn: _parserFn$Query$Operations,
       );

  final OnQueryComplete$Query$Operations? onCompleteWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onComplete == null
        ? super.properties
        : super.properties.where((property) => property != onComplete),
    onCompleteWithParsed,
  ];
}

class WatchOptions$Query$Operations
    extends graphql.WatchQueryOptions<Query$Operations> {
  WatchOptions$Query$Operations({
    String? operationName,
    required Variables$Query$Operations variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$Operations? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeQueryOperations,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Query$Operations,
       );
}

class FetchMoreOptions$Query$Operations extends graphql.FetchMoreOptions {
  FetchMoreOptions$Query$Operations({
    required graphql.UpdateQuery updateQuery,
    required Variables$Query$Operations variables,
  }) : super(
         updateQuery: updateQuery,
         variables: variables.toJson(),
         document: documentNodeQueryOperations,
       );
}

extension ClientExtension$Query$Operations on graphql.GraphQLClient {
  Future<graphql.QueryResult<Query$Operations>> query$Operations(
    Options$Query$Operations options,
  ) async => await this.query(options);

  graphql.ObservableQuery<Query$Operations> watchQuery$Operations(
    WatchOptions$Query$Operations options,
  ) => this.watchQuery(options);

  void writeQuery$Operations({
    required Query$Operations data,
    required Variables$Query$Operations variables,
    bool broadcast = true,
  }) => this.writeQuery(
    graphql.Request(
      operation: graphql.Operation(document: documentNodeQueryOperations),
      variables: variables.toJson(),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Query$Operations? readQuery$Operations({
    required Variables$Query$Operations variables,
    bool optimistic = true,
  }) {
    final result = this.readQuery(
      graphql.Request(
        operation: graphql.Operation(document: documentNodeQueryOperations),
        variables: variables.toJson(),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Query$Operations.fromJson(result);
  }
}

class Variables$Query$AttendanceReview {
  factory Variables$Query$AttendanceReview({
    required String siteId,
    required String workDate,
  }) => Variables$Query$AttendanceReview._({
    r'siteId': siteId,
    r'workDate': workDate,
  });

  Variables$Query$AttendanceReview._(this._$data);

  factory Variables$Query$AttendanceReview.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    final l$workDate = data['workDate'];
    result$data['workDate'] = (l$workDate as String);
    return Variables$Query$AttendanceReview._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  String get workDate => (_$data['workDate'] as String);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    final l$workDate = workDate;
    result$data['workDate'] = l$workDate;
    return result$data;
  }

  CopyWith$Variables$Query$AttendanceReview<Variables$Query$AttendanceReview>
  get copyWith => CopyWith$Variables$Query$AttendanceReview(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$AttendanceReview ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    final l$workDate = workDate;
    final lOther$workDate = other.workDate;
    if (l$workDate != lOther$workDate) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    final l$workDate = workDate;
    return Object.hashAll([l$siteId, l$workDate]);
  }
}

abstract class CopyWith$Variables$Query$AttendanceReview<TRes> {
  factory CopyWith$Variables$Query$AttendanceReview(
    Variables$Query$AttendanceReview instance,
    TRes Function(Variables$Query$AttendanceReview) then,
  ) = _CopyWithImpl$Variables$Query$AttendanceReview;

  factory CopyWith$Variables$Query$AttendanceReview.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$AttendanceReview;

  TRes call({String? siteId, String? workDate});
}

class _CopyWithImpl$Variables$Query$AttendanceReview<TRes>
    implements CopyWith$Variables$Query$AttendanceReview<TRes> {
  _CopyWithImpl$Variables$Query$AttendanceReview(this._instance, this._then);

  final Variables$Query$AttendanceReview _instance;

  final TRes Function(Variables$Query$AttendanceReview) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? siteId = _undefined, Object? workDate = _undefined}) =>
      _then(
        Variables$Query$AttendanceReview._({
          ..._instance._$data,
          if (siteId != _undefined && siteId != null)
            'siteId': (siteId as String),
          if (workDate != _undefined && workDate != null)
            'workDate': (workDate as String),
        }),
      );
}

class _CopyWithStubImpl$Variables$Query$AttendanceReview<TRes>
    implements CopyWith$Variables$Query$AttendanceReview<TRes> {
  _CopyWithStubImpl$Variables$Query$AttendanceReview(this._res);

  TRes _res;

  call({String? siteId, String? workDate}) => _res;
}

class Query$AttendanceReview {
  Query$AttendanceReview({
    required this.attendanceReview,
    this.$__typename = 'Query',
  });

  factory Query$AttendanceReview.fromJson(Map<String, dynamic> json) {
    final l$attendanceReview = json['attendanceReview'];
    final l$$__typename = json['__typename'];
    return Query$AttendanceReview(
      attendanceReview: (l$attendanceReview as dynamic),
      $__typename: (l$$__typename as String),
    );
  }

  final dynamic attendanceReview;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$attendanceReview = attendanceReview;
    _resultData['attendanceReview'] = l$attendanceReview;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$attendanceReview = attendanceReview;
    final l$$__typename = $__typename;
    return Object.hashAll([l$attendanceReview, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$AttendanceReview || runtimeType != other.runtimeType) {
      return false;
    }
    final l$attendanceReview = attendanceReview;
    final lOther$attendanceReview = other.attendanceReview;
    if (l$attendanceReview != lOther$attendanceReview) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$AttendanceReview on Query$AttendanceReview {
  CopyWith$Query$AttendanceReview<Query$AttendanceReview> get copyWith =>
      CopyWith$Query$AttendanceReview(this, (i) => i);
}

abstract class CopyWith$Query$AttendanceReview<TRes> {
  factory CopyWith$Query$AttendanceReview(
    Query$AttendanceReview instance,
    TRes Function(Query$AttendanceReview) then,
  ) = _CopyWithImpl$Query$AttendanceReview;

  factory CopyWith$Query$AttendanceReview.stub(TRes res) =
      _CopyWithStubImpl$Query$AttendanceReview;

  TRes call({dynamic? attendanceReview, String? $__typename});
}

class _CopyWithImpl$Query$AttendanceReview<TRes>
    implements CopyWith$Query$AttendanceReview<TRes> {
  _CopyWithImpl$Query$AttendanceReview(this._instance, this._then);

  final Query$AttendanceReview _instance;

  final TRes Function(Query$AttendanceReview) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? attendanceReview = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$AttendanceReview(
      attendanceReview:
          attendanceReview == _undefined || attendanceReview == null
          ? _instance.attendanceReview
          : (attendanceReview as dynamic),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$AttendanceReview<TRes>
    implements CopyWith$Query$AttendanceReview<TRes> {
  _CopyWithStubImpl$Query$AttendanceReview(this._res);

  TRes _res;

  call({dynamic? attendanceReview, String? $__typename}) => _res;
}

const documentNodeQueryAttendanceReview = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'AttendanceReview'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'workDate')),
          type: NamedTypeNode(name: NameNode(value: 'String'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'attendanceReview'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'workDate'),
                value: VariableNode(name: NameNode(value: 'workDate')),
              ),
            ],
            directives: [],
            selectionSet: null,
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Query$AttendanceReview _parserFn$Query$AttendanceReview(
  Map<String, dynamic> data,
) => Query$AttendanceReview.fromJson(data);
typedef OnQueryComplete$Query$AttendanceReview = FutureOr<void> Function(
  Map<String, dynamic>?,
  Query$AttendanceReview?,
);

class Options$Query$AttendanceReview
    extends graphql.QueryOptions<Query$AttendanceReview> {
  Options$Query$AttendanceReview({
    String? operationName,
    required Variables$Query$AttendanceReview variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$AttendanceReview? typedOptimisticResult,
    Duration? pollInterval,
    graphql.Context? context,
    OnQueryComplete$Query$AttendanceReview? onComplete,
    graphql.OnQueryError? onError,
  }) : onCompleteWithParsed = onComplete,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         pollInterval: pollInterval,
         context: context,
         onComplete: onComplete == null
             ? null
             : (data) => onComplete(
                 data,
                 data == null ? null : _parserFn$Query$AttendanceReview(data),
               ),
         onError: onError,
         document: documentNodeQueryAttendanceReview,
         parserFn: _parserFn$Query$AttendanceReview,
       );

  final OnQueryComplete$Query$AttendanceReview? onCompleteWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onComplete == null
        ? super.properties
        : super.properties.where((property) => property != onComplete),
    onCompleteWithParsed,
  ];
}

class WatchOptions$Query$AttendanceReview
    extends graphql.WatchQueryOptions<Query$AttendanceReview> {
  WatchOptions$Query$AttendanceReview({
    String? operationName,
    required Variables$Query$AttendanceReview variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$AttendanceReview? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeQueryAttendanceReview,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Query$AttendanceReview,
       );
}

class FetchMoreOptions$Query$AttendanceReview extends graphql.FetchMoreOptions {
  FetchMoreOptions$Query$AttendanceReview({
    required graphql.UpdateQuery updateQuery,
    required Variables$Query$AttendanceReview variables,
  }) : super(
         updateQuery: updateQuery,
         variables: variables.toJson(),
         document: documentNodeQueryAttendanceReview,
       );
}

extension ClientExtension$Query$AttendanceReview on graphql.GraphQLClient {
  Future<graphql.QueryResult<Query$AttendanceReview>> query$AttendanceReview(
    Options$Query$AttendanceReview options,
  ) async => await this.query(options);

  graphql.ObservableQuery<Query$AttendanceReview> watchQuery$AttendanceReview(
    WatchOptions$Query$AttendanceReview options,
  ) => this.watchQuery(options);

  void writeQuery$AttendanceReview({
    required Query$AttendanceReview data,
    required Variables$Query$AttendanceReview variables,
    bool broadcast = true,
  }) => this.writeQuery(
    graphql.Request(
      operation: graphql.Operation(document: documentNodeQueryAttendanceReview),
      variables: variables.toJson(),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Query$AttendanceReview? readQuery$AttendanceReview({
    required Variables$Query$AttendanceReview variables,
    bool optimistic = true,
  }) {
    final result = this.readQuery(
      graphql.Request(
        operation: graphql.Operation(
          document: documentNodeQueryAttendanceReview,
        ),
        variables: variables.toJson(),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Query$AttendanceReview.fromJson(result);
  }
}

class Variables$Mutation$Operate {
  factory Variables$Mutation$Operate({
    required String siteId,
    required String operation,
    required dynamic input,
  }) => Variables$Mutation$Operate._({
    r'siteId': siteId,
    r'operation': operation,
    r'input': input,
  });

  Variables$Mutation$Operate._(this._$data);

  factory Variables$Mutation$Operate.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    final l$operation = data['operation'];
    result$data['operation'] = (l$operation as String);
    final l$input = data['input'];
    result$data['input'] = (l$input as dynamic);
    return Variables$Mutation$Operate._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  String get operation => (_$data['operation'] as String);

  dynamic get input => (_$data['input'] as dynamic);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    final l$operation = operation;
    result$data['operation'] = l$operation;
    final l$input = input;
    result$data['input'] = l$input;
    return result$data;
  }

  CopyWith$Variables$Mutation$Operate<Variables$Mutation$Operate>
  get copyWith => CopyWith$Variables$Mutation$Operate(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Mutation$Operate ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    final l$operation = operation;
    final lOther$operation = other.operation;
    if (l$operation != lOther$operation) {
      return false;
    }
    final l$input = input;
    final lOther$input = other.input;
    if (l$input != lOther$input) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    final l$operation = operation;
    final l$input = input;
    return Object.hashAll([l$siteId, l$operation, l$input]);
  }
}

abstract class CopyWith$Variables$Mutation$Operate<TRes> {
  factory CopyWith$Variables$Mutation$Operate(
    Variables$Mutation$Operate instance,
    TRes Function(Variables$Mutation$Operate) then,
  ) = _CopyWithImpl$Variables$Mutation$Operate;

  factory CopyWith$Variables$Mutation$Operate.stub(TRes res) =
      _CopyWithStubImpl$Variables$Mutation$Operate;

  TRes call({String? siteId, String? operation, dynamic? input});
}

class _CopyWithImpl$Variables$Mutation$Operate<TRes>
    implements CopyWith$Variables$Mutation$Operate<TRes> {
  _CopyWithImpl$Variables$Mutation$Operate(this._instance, this._then);

  final Variables$Mutation$Operate _instance;

  final TRes Function(Variables$Mutation$Operate) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? siteId = _undefined,
    Object? operation = _undefined,
    Object? input = _undefined,
  }) => _then(
    Variables$Mutation$Operate._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
      if (operation != _undefined && operation != null)
        'operation': (operation as String),
      if (input != _undefined && input != null) 'input': (input as dynamic),
    }),
  );
}

class _CopyWithStubImpl$Variables$Mutation$Operate<TRes>
    implements CopyWith$Variables$Mutation$Operate<TRes> {
  _CopyWithStubImpl$Variables$Mutation$Operate(this._res);

  TRes _res;

  call({String? siteId, String? operation, dynamic? input}) => _res;
}

class Mutation$Operate {
  Mutation$Operate({required this.operate, this.$__typename = 'Mutation'});

  factory Mutation$Operate.fromJson(Map<String, dynamic> json) {
    final l$operate = json['operate'];
    final l$$__typename = json['__typename'];
    return Mutation$Operate(
      operate: (l$operate as dynamic),
      $__typename: (l$$__typename as String),
    );
  }

  final dynamic operate;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$operate = operate;
    _resultData['operate'] = l$operate;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$operate = operate;
    final l$$__typename = $__typename;
    return Object.hashAll([l$operate, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Mutation$Operate || runtimeType != other.runtimeType) {
      return false;
    }
    final l$operate = operate;
    final lOther$operate = other.operate;
    if (l$operate != lOther$operate) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Mutation$Operate on Mutation$Operate {
  CopyWith$Mutation$Operate<Mutation$Operate> get copyWith =>
      CopyWith$Mutation$Operate(this, (i) => i);
}

abstract class CopyWith$Mutation$Operate<TRes> {
  factory CopyWith$Mutation$Operate(
    Mutation$Operate instance,
    TRes Function(Mutation$Operate) then,
  ) = _CopyWithImpl$Mutation$Operate;

  factory CopyWith$Mutation$Operate.stub(TRes res) =
      _CopyWithStubImpl$Mutation$Operate;

  TRes call({dynamic? operate, String? $__typename});
}

class _CopyWithImpl$Mutation$Operate<TRes>
    implements CopyWith$Mutation$Operate<TRes> {
  _CopyWithImpl$Mutation$Operate(this._instance, this._then);

  final Mutation$Operate _instance;

  final TRes Function(Mutation$Operate) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? operate = _undefined, Object? $__typename = _undefined}) =>
      _then(
        Mutation$Operate(
          operate: operate == _undefined || operate == null
              ? _instance.operate
              : (operate as dynamic),
          $__typename: $__typename == _undefined || $__typename == null
              ? _instance.$__typename
              : ($__typename as String),
        ),
      );
}

class _CopyWithStubImpl$Mutation$Operate<TRes>
    implements CopyWith$Mutation$Operate<TRes> {
  _CopyWithStubImpl$Mutation$Operate(this._res);

  TRes _res;

  call({dynamic? operate, String? $__typename}) => _res;
}

const documentNodeMutationOperate = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.mutation,
      name: NameNode(value: 'Operate'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'operation')),
          type: NamedTypeNode(name: NameNode(value: 'String'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'input')),
          type: NamedTypeNode(name: NameNode(value: 'JSON'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'operate'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'operation'),
                value: VariableNode(name: NameNode(value: 'operation')),
              ),
              ArgumentNode(
                name: NameNode(value: 'input'),
                value: VariableNode(name: NameNode(value: 'input')),
              ),
            ],
            directives: [],
            selectionSet: null,
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Mutation$Operate _parserFn$Mutation$Operate(Map<String, dynamic> data) =>
    Mutation$Operate.fromJson(data);
typedef OnMutationCompleted$Mutation$Operate = FutureOr<void> Function(
  Map<String, dynamic>?,
  Mutation$Operate?,
);

class Options$Mutation$Operate
    extends graphql.MutationOptions<Mutation$Operate> {
  Options$Mutation$Operate({
    String? operationName,
    required Variables$Mutation$Operate variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Mutation$Operate? typedOptimisticResult,
    graphql.Context? context,
    OnMutationCompleted$Mutation$Operate? onCompleted,
    graphql.OnMutationUpdate<Mutation$Operate>? update,
    graphql.OnError? onError,
  }) : onCompletedWithParsed = onCompleted,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         onCompleted: onCompleted == null
             ? null
             : (data) => onCompleted(
                 data,
                 data == null ? null : _parserFn$Mutation$Operate(data),
               ),
         update: update,
         onError: onError,
         document: documentNodeMutationOperate,
         parserFn: _parserFn$Mutation$Operate,
       );

  final OnMutationCompleted$Mutation$Operate? onCompletedWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onCompleted == null
        ? super.properties
        : super.properties.where((property) => property != onCompleted),
    onCompletedWithParsed,
  ];
}

class WatchOptions$Mutation$Operate
    extends graphql.WatchQueryOptions<Mutation$Operate> {
  WatchOptions$Mutation$Operate({
    String? operationName,
    required Variables$Mutation$Operate variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Mutation$Operate? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeMutationOperate,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Mutation$Operate,
       );
}

extension ClientExtension$Mutation$Operate on graphql.GraphQLClient {
  Future<graphql.QueryResult<Mutation$Operate>> mutate$Operate(
    Options$Mutation$Operate options,
  ) async => await this.mutate(options);

  graphql.ObservableQuery<Mutation$Operate> watchMutation$Operate(
    WatchOptions$Mutation$Operate options,
  ) => this.watchMutation(options);
}

class Variables$Query$Dwr {
  factory Variables$Query$Dwr({required String siteId, String? workDate}) =>
      Variables$Query$Dwr._({
        r'siteId': siteId,
        if (workDate != null) r'workDate': workDate,
      });

  Variables$Query$Dwr._(this._$data);

  factory Variables$Query$Dwr.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    if (data.containsKey('workDate')) {
      final l$workDate = data['workDate'];
      result$data['workDate'] = (l$workDate as String?);
    }
    return Variables$Query$Dwr._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  String? get workDate => (_$data['workDate'] as String?);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    if (_$data.containsKey('workDate')) {
      final l$workDate = workDate;
      result$data['workDate'] = l$workDate;
    }
    return result$data;
  }

  CopyWith$Variables$Query$Dwr<Variables$Query$Dwr> get copyWith =>
      CopyWith$Variables$Query$Dwr(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$Dwr || runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    final l$workDate = workDate;
    final lOther$workDate = other.workDate;
    if (_$data.containsKey('workDate') !=
        other._$data.containsKey('workDate')) {
      return false;
    }
    if (l$workDate != lOther$workDate) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    final l$workDate = workDate;
    return Object.hashAll([
      l$siteId,
      _$data.containsKey('workDate') ? l$workDate : const {},
    ]);
  }
}

abstract class CopyWith$Variables$Query$Dwr<TRes> {
  factory CopyWith$Variables$Query$Dwr(
    Variables$Query$Dwr instance,
    TRes Function(Variables$Query$Dwr) then,
  ) = _CopyWithImpl$Variables$Query$Dwr;

  factory CopyWith$Variables$Query$Dwr.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$Dwr;

  TRes call({String? siteId, String? workDate});
}

class _CopyWithImpl$Variables$Query$Dwr<TRes>
    implements CopyWith$Variables$Query$Dwr<TRes> {
  _CopyWithImpl$Variables$Query$Dwr(this._instance, this._then);

  final Variables$Query$Dwr _instance;

  final TRes Function(Variables$Query$Dwr) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? siteId = _undefined, Object? workDate = _undefined}) =>
      _then(
        Variables$Query$Dwr._({
          ..._instance._$data,
          if (siteId != _undefined && siteId != null)
            'siteId': (siteId as String),
          if (workDate != _undefined) 'workDate': (workDate as String?),
        }),
      );
}

class _CopyWithStubImpl$Variables$Query$Dwr<TRes>
    implements CopyWith$Variables$Query$Dwr<TRes> {
  _CopyWithStubImpl$Variables$Query$Dwr(this._res);

  TRes _res;

  call({String? siteId, String? workDate}) => _res;
}

class Query$Dwr {
  Query$Dwr({required this.dwr, this.$__typename = 'Query'});

  factory Query$Dwr.fromJson(Map<String, dynamic> json) {
    final l$dwr = json['dwr'];
    final l$$__typename = json['__typename'];
    return Query$Dwr(
      dwr: (l$dwr as dynamic),
      $__typename: (l$$__typename as String),
    );
  }

  final dynamic dwr;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$dwr = dwr;
    _resultData['dwr'] = l$dwr;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$dwr = dwr;
    final l$$__typename = $__typename;
    return Object.hashAll([l$dwr, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$Dwr || runtimeType != other.runtimeType) {
      return false;
    }
    final l$dwr = dwr;
    final lOther$dwr = other.dwr;
    if (l$dwr != lOther$dwr) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$Dwr on Query$Dwr {
  CopyWith$Query$Dwr<Query$Dwr> get copyWith =>
      CopyWith$Query$Dwr(this, (i) => i);
}

abstract class CopyWith$Query$Dwr<TRes> {
  factory CopyWith$Query$Dwr(
    Query$Dwr instance,
    TRes Function(Query$Dwr) then,
  ) = _CopyWithImpl$Query$Dwr;

  factory CopyWith$Query$Dwr.stub(TRes res) = _CopyWithStubImpl$Query$Dwr;

  TRes call({dynamic? dwr, String? $__typename});
}

class _CopyWithImpl$Query$Dwr<TRes> implements CopyWith$Query$Dwr<TRes> {
  _CopyWithImpl$Query$Dwr(this._instance, this._then);

  final Query$Dwr _instance;

  final TRes Function(Query$Dwr) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? dwr = _undefined, Object? $__typename = _undefined}) =>
      _then(
        Query$Dwr(
          dwr: dwr == _undefined || dwr == null
              ? _instance.dwr
              : (dwr as dynamic),
          $__typename: $__typename == _undefined || $__typename == null
              ? _instance.$__typename
              : ($__typename as String),
        ),
      );
}

class _CopyWithStubImpl$Query$Dwr<TRes> implements CopyWith$Query$Dwr<TRes> {
  _CopyWithStubImpl$Query$Dwr(this._res);

  TRes _res;

  call({dynamic? dwr, String? $__typename}) => _res;
}

const documentNodeQueryDwr = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'Dwr'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'workDate')),
          type: NamedTypeNode(
            name: NameNode(value: 'String'),
            isNonNull: false,
          ),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'dwr'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'workDate'),
                value: VariableNode(name: NameNode(value: 'workDate')),
              ),
            ],
            directives: [],
            selectionSet: null,
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Query$Dwr _parserFn$Query$Dwr(Map<String, dynamic> data) =>
    Query$Dwr.fromJson(data);
typedef OnQueryComplete$Query$Dwr = FutureOr<void> Function(
  Map<String, dynamic>?,
  Query$Dwr?,
);

class Options$Query$Dwr extends graphql.QueryOptions<Query$Dwr> {
  Options$Query$Dwr({
    String? operationName,
    required Variables$Query$Dwr variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$Dwr? typedOptimisticResult,
    Duration? pollInterval,
    graphql.Context? context,
    OnQueryComplete$Query$Dwr? onComplete,
    graphql.OnQueryError? onError,
  }) : onCompleteWithParsed = onComplete,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         pollInterval: pollInterval,
         context: context,
         onComplete: onComplete == null
             ? null
             : (data) => onComplete(
                 data,
                 data == null ? null : _parserFn$Query$Dwr(data),
               ),
         onError: onError,
         document: documentNodeQueryDwr,
         parserFn: _parserFn$Query$Dwr,
       );

  final OnQueryComplete$Query$Dwr? onCompleteWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onComplete == null
        ? super.properties
        : super.properties.where((property) => property != onComplete),
    onCompleteWithParsed,
  ];
}

class WatchOptions$Query$Dwr extends graphql.WatchQueryOptions<Query$Dwr> {
  WatchOptions$Query$Dwr({
    String? operationName,
    required Variables$Query$Dwr variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$Dwr? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeQueryDwr,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Query$Dwr,
       );
}

class FetchMoreOptions$Query$Dwr extends graphql.FetchMoreOptions {
  FetchMoreOptions$Query$Dwr({
    required graphql.UpdateQuery updateQuery,
    required Variables$Query$Dwr variables,
  }) : super(
         updateQuery: updateQuery,
         variables: variables.toJson(),
         document: documentNodeQueryDwr,
       );
}

extension ClientExtension$Query$Dwr on graphql.GraphQLClient {
  Future<graphql.QueryResult<Query$Dwr>> query$Dwr(
    Options$Query$Dwr options,
  ) async => await this.query(options);

  graphql.ObservableQuery<Query$Dwr> watchQuery$Dwr(
    WatchOptions$Query$Dwr options,
  ) => this.watchQuery(options);

  void writeQuery$Dwr({
    required Query$Dwr data,
    required Variables$Query$Dwr variables,
    bool broadcast = true,
  }) => this.writeQuery(
    graphql.Request(
      operation: graphql.Operation(document: documentNodeQueryDwr),
      variables: variables.toJson(),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Query$Dwr? readQuery$Dwr({
    required Variables$Query$Dwr variables,
    bool optimistic = true,
  }) {
    final result = this.readQuery(
      graphql.Request(
        operation: graphql.Operation(document: documentNodeQueryDwr),
        variables: variables.toJson(),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Query$Dwr.fromJson(result);
  }
}

class Variables$Query$DwrChat {
  factory Variables$Query$DwrChat({
    required String siteId,
    required dynamic input,
  }) => Variables$Query$DwrChat._({r'siteId': siteId, r'input': input});

  Variables$Query$DwrChat._(this._$data);

  factory Variables$Query$DwrChat.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    final l$input = data['input'];
    result$data['input'] = (l$input as dynamic);
    return Variables$Query$DwrChat._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  dynamic get input => (_$data['input'] as dynamic);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    final l$input = input;
    result$data['input'] = l$input;
    return result$data;
  }

  CopyWith$Variables$Query$DwrChat<Variables$Query$DwrChat> get copyWith =>
      CopyWith$Variables$Query$DwrChat(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$DwrChat || runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    final l$input = input;
    final lOther$input = other.input;
    if (l$input != lOther$input) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    final l$input = input;
    return Object.hashAll([l$siteId, l$input]);
  }
}

abstract class CopyWith$Variables$Query$DwrChat<TRes> {
  factory CopyWith$Variables$Query$DwrChat(
    Variables$Query$DwrChat instance,
    TRes Function(Variables$Query$DwrChat) then,
  ) = _CopyWithImpl$Variables$Query$DwrChat;

  factory CopyWith$Variables$Query$DwrChat.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$DwrChat;

  TRes call({String? siteId, dynamic? input});
}

class _CopyWithImpl$Variables$Query$DwrChat<TRes>
    implements CopyWith$Variables$Query$DwrChat<TRes> {
  _CopyWithImpl$Variables$Query$DwrChat(this._instance, this._then);

  final Variables$Query$DwrChat _instance;

  final TRes Function(Variables$Query$DwrChat) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? siteId = _undefined, Object? input = _undefined}) => _then(
    Variables$Query$DwrChat._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
      if (input != _undefined && input != null) 'input': (input as dynamic),
    }),
  );
}

class _CopyWithStubImpl$Variables$Query$DwrChat<TRes>
    implements CopyWith$Variables$Query$DwrChat<TRes> {
  _CopyWithStubImpl$Variables$Query$DwrChat(this._res);

  TRes _res;

  call({String? siteId, dynamic? input}) => _res;
}

class Query$DwrChat {
  Query$DwrChat({required this.dwrChat, this.$__typename = 'Query'});

  factory Query$DwrChat.fromJson(Map<String, dynamic> json) {
    final l$dwrChat = json['dwrChat'];
    final l$$__typename = json['__typename'];
    return Query$DwrChat(
      dwrChat: (l$dwrChat as dynamic),
      $__typename: (l$$__typename as String),
    );
  }

  final dynamic dwrChat;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$dwrChat = dwrChat;
    _resultData['dwrChat'] = l$dwrChat;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$dwrChat = dwrChat;
    final l$$__typename = $__typename;
    return Object.hashAll([l$dwrChat, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$DwrChat || runtimeType != other.runtimeType) {
      return false;
    }
    final l$dwrChat = dwrChat;
    final lOther$dwrChat = other.dwrChat;
    if (l$dwrChat != lOther$dwrChat) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$DwrChat on Query$DwrChat {
  CopyWith$Query$DwrChat<Query$DwrChat> get copyWith =>
      CopyWith$Query$DwrChat(this, (i) => i);
}

abstract class CopyWith$Query$DwrChat<TRes> {
  factory CopyWith$Query$DwrChat(
    Query$DwrChat instance,
    TRes Function(Query$DwrChat) then,
  ) = _CopyWithImpl$Query$DwrChat;

  factory CopyWith$Query$DwrChat.stub(TRes res) =
      _CopyWithStubImpl$Query$DwrChat;

  TRes call({dynamic? dwrChat, String? $__typename});
}

class _CopyWithImpl$Query$DwrChat<TRes>
    implements CopyWith$Query$DwrChat<TRes> {
  _CopyWithImpl$Query$DwrChat(this._instance, this._then);

  final Query$DwrChat _instance;

  final TRes Function(Query$DwrChat) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? dwrChat = _undefined, Object? $__typename = _undefined}) =>
      _then(
        Query$DwrChat(
          dwrChat: dwrChat == _undefined || dwrChat == null
              ? _instance.dwrChat
              : (dwrChat as dynamic),
          $__typename: $__typename == _undefined || $__typename == null
              ? _instance.$__typename
              : ($__typename as String),
        ),
      );
}

class _CopyWithStubImpl$Query$DwrChat<TRes>
    implements CopyWith$Query$DwrChat<TRes> {
  _CopyWithStubImpl$Query$DwrChat(this._res);

  TRes _res;

  call({dynamic? dwrChat, String? $__typename}) => _res;
}

const documentNodeQueryDwrChat = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'DwrChat'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'input')),
          type: NamedTypeNode(name: NameNode(value: 'JSON'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'dwrChat'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'input'),
                value: VariableNode(name: NameNode(value: 'input')),
              ),
            ],
            directives: [],
            selectionSet: null,
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Query$DwrChat _parserFn$Query$DwrChat(Map<String, dynamic> data) =>
    Query$DwrChat.fromJson(data);
typedef OnQueryComplete$Query$DwrChat = FutureOr<void> Function(
  Map<String, dynamic>?,
  Query$DwrChat?,
);

class Options$Query$DwrChat extends graphql.QueryOptions<Query$DwrChat> {
  Options$Query$DwrChat({
    String? operationName,
    required Variables$Query$DwrChat variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$DwrChat? typedOptimisticResult,
    Duration? pollInterval,
    graphql.Context? context,
    OnQueryComplete$Query$DwrChat? onComplete,
    graphql.OnQueryError? onError,
  }) : onCompleteWithParsed = onComplete,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         pollInterval: pollInterval,
         context: context,
         onComplete: onComplete == null
             ? null
             : (data) => onComplete(
                 data,
                 data == null ? null : _parserFn$Query$DwrChat(data),
               ),
         onError: onError,
         document: documentNodeQueryDwrChat,
         parserFn: _parserFn$Query$DwrChat,
       );

  final OnQueryComplete$Query$DwrChat? onCompleteWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onComplete == null
        ? super.properties
        : super.properties.where((property) => property != onComplete),
    onCompleteWithParsed,
  ];
}

class WatchOptions$Query$DwrChat
    extends graphql.WatchQueryOptions<Query$DwrChat> {
  WatchOptions$Query$DwrChat({
    String? operationName,
    required Variables$Query$DwrChat variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$DwrChat? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeQueryDwrChat,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Query$DwrChat,
       );
}

class FetchMoreOptions$Query$DwrChat extends graphql.FetchMoreOptions {
  FetchMoreOptions$Query$DwrChat({
    required graphql.UpdateQuery updateQuery,
    required Variables$Query$DwrChat variables,
  }) : super(
         updateQuery: updateQuery,
         variables: variables.toJson(),
         document: documentNodeQueryDwrChat,
       );
}

extension ClientExtension$Query$DwrChat on graphql.GraphQLClient {
  Future<graphql.QueryResult<Query$DwrChat>> query$DwrChat(
    Options$Query$DwrChat options,
  ) async => await this.query(options);

  graphql.ObservableQuery<Query$DwrChat> watchQuery$DwrChat(
    WatchOptions$Query$DwrChat options,
  ) => this.watchQuery(options);

  void writeQuery$DwrChat({
    required Query$DwrChat data,
    required Variables$Query$DwrChat variables,
    bool broadcast = true,
  }) => this.writeQuery(
    graphql.Request(
      operation: graphql.Operation(document: documentNodeQueryDwrChat),
      variables: variables.toJson(),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Query$DwrChat? readQuery$DwrChat({
    required Variables$Query$DwrChat variables,
    bool optimistic = true,
  }) {
    final result = this.readQuery(
      graphql.Request(
        operation: graphql.Operation(document: documentNodeQueryDwrChat),
        variables: variables.toJson(),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Query$DwrChat.fromJson(result);
  }
}

class Variables$Mutation$DwrCommand {
  factory Variables$Mutation$DwrCommand({
    required String siteId,
    required String operation,
    required dynamic input,
  }) => Variables$Mutation$DwrCommand._({
    r'siteId': siteId,
    r'operation': operation,
    r'input': input,
  });

  Variables$Mutation$DwrCommand._(this._$data);

  factory Variables$Mutation$DwrCommand.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    final l$operation = data['operation'];
    result$data['operation'] = (l$operation as String);
    final l$input = data['input'];
    result$data['input'] = (l$input as dynamic);
    return Variables$Mutation$DwrCommand._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  String get operation => (_$data['operation'] as String);

  dynamic get input => (_$data['input'] as dynamic);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    final l$operation = operation;
    result$data['operation'] = l$operation;
    final l$input = input;
    result$data['input'] = l$input;
    return result$data;
  }

  CopyWith$Variables$Mutation$DwrCommand<Variables$Mutation$DwrCommand>
  get copyWith => CopyWith$Variables$Mutation$DwrCommand(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Mutation$DwrCommand ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    final l$operation = operation;
    final lOther$operation = other.operation;
    if (l$operation != lOther$operation) {
      return false;
    }
    final l$input = input;
    final lOther$input = other.input;
    if (l$input != lOther$input) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    final l$operation = operation;
    final l$input = input;
    return Object.hashAll([l$siteId, l$operation, l$input]);
  }
}

abstract class CopyWith$Variables$Mutation$DwrCommand<TRes> {
  factory CopyWith$Variables$Mutation$DwrCommand(
    Variables$Mutation$DwrCommand instance,
    TRes Function(Variables$Mutation$DwrCommand) then,
  ) = _CopyWithImpl$Variables$Mutation$DwrCommand;

  factory CopyWith$Variables$Mutation$DwrCommand.stub(TRes res) =
      _CopyWithStubImpl$Variables$Mutation$DwrCommand;

  TRes call({String? siteId, String? operation, dynamic? input});
}

class _CopyWithImpl$Variables$Mutation$DwrCommand<TRes>
    implements CopyWith$Variables$Mutation$DwrCommand<TRes> {
  _CopyWithImpl$Variables$Mutation$DwrCommand(this._instance, this._then);

  final Variables$Mutation$DwrCommand _instance;

  final TRes Function(Variables$Mutation$DwrCommand) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? siteId = _undefined,
    Object? operation = _undefined,
    Object? input = _undefined,
  }) => _then(
    Variables$Mutation$DwrCommand._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
      if (operation != _undefined && operation != null)
        'operation': (operation as String),
      if (input != _undefined && input != null) 'input': (input as dynamic),
    }),
  );
}

class _CopyWithStubImpl$Variables$Mutation$DwrCommand<TRes>
    implements CopyWith$Variables$Mutation$DwrCommand<TRes> {
  _CopyWithStubImpl$Variables$Mutation$DwrCommand(this._res);

  TRes _res;

  call({String? siteId, String? operation, dynamic? input}) => _res;
}

class Mutation$DwrCommand {
  Mutation$DwrCommand({
    required this.dwrCommand,
    this.$__typename = 'Mutation',
  });

  factory Mutation$DwrCommand.fromJson(Map<String, dynamic> json) {
    final l$dwrCommand = json['dwrCommand'];
    final l$$__typename = json['__typename'];
    return Mutation$DwrCommand(
      dwrCommand: (l$dwrCommand as dynamic),
      $__typename: (l$$__typename as String),
    );
  }

  final dynamic dwrCommand;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$dwrCommand = dwrCommand;
    _resultData['dwrCommand'] = l$dwrCommand;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$dwrCommand = dwrCommand;
    final l$$__typename = $__typename;
    return Object.hashAll([l$dwrCommand, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Mutation$DwrCommand || runtimeType != other.runtimeType) {
      return false;
    }
    final l$dwrCommand = dwrCommand;
    final lOther$dwrCommand = other.dwrCommand;
    if (l$dwrCommand != lOther$dwrCommand) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Mutation$DwrCommand on Mutation$DwrCommand {
  CopyWith$Mutation$DwrCommand<Mutation$DwrCommand> get copyWith =>
      CopyWith$Mutation$DwrCommand(this, (i) => i);
}

abstract class CopyWith$Mutation$DwrCommand<TRes> {
  factory CopyWith$Mutation$DwrCommand(
    Mutation$DwrCommand instance,
    TRes Function(Mutation$DwrCommand) then,
  ) = _CopyWithImpl$Mutation$DwrCommand;

  factory CopyWith$Mutation$DwrCommand.stub(TRes res) =
      _CopyWithStubImpl$Mutation$DwrCommand;

  TRes call({dynamic? dwrCommand, String? $__typename});
}

class _CopyWithImpl$Mutation$DwrCommand<TRes>
    implements CopyWith$Mutation$DwrCommand<TRes> {
  _CopyWithImpl$Mutation$DwrCommand(this._instance, this._then);

  final Mutation$DwrCommand _instance;

  final TRes Function(Mutation$DwrCommand) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? dwrCommand = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Mutation$DwrCommand(
      dwrCommand: dwrCommand == _undefined || dwrCommand == null
          ? _instance.dwrCommand
          : (dwrCommand as dynamic),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Mutation$DwrCommand<TRes>
    implements CopyWith$Mutation$DwrCommand<TRes> {
  _CopyWithStubImpl$Mutation$DwrCommand(this._res);

  TRes _res;

  call({dynamic? dwrCommand, String? $__typename}) => _res;
}

const documentNodeMutationDwrCommand = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.mutation,
      name: NameNode(value: 'DwrCommand'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'operation')),
          type: NamedTypeNode(name: NameNode(value: 'String'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'input')),
          type: NamedTypeNode(name: NameNode(value: 'JSON'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'dwrCommand'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'operation'),
                value: VariableNode(name: NameNode(value: 'operation')),
              ),
              ArgumentNode(
                name: NameNode(value: 'input'),
                value: VariableNode(name: NameNode(value: 'input')),
              ),
            ],
            directives: [],
            selectionSet: null,
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Mutation$DwrCommand _parserFn$Mutation$DwrCommand(Map<String, dynamic> data) =>
    Mutation$DwrCommand.fromJson(data);
typedef OnMutationCompleted$Mutation$DwrCommand = FutureOr<void> Function(
  Map<String, dynamic>?,
  Mutation$DwrCommand?,
);

class Options$Mutation$DwrCommand
    extends graphql.MutationOptions<Mutation$DwrCommand> {
  Options$Mutation$DwrCommand({
    String? operationName,
    required Variables$Mutation$DwrCommand variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Mutation$DwrCommand? typedOptimisticResult,
    graphql.Context? context,
    OnMutationCompleted$Mutation$DwrCommand? onCompleted,
    graphql.OnMutationUpdate<Mutation$DwrCommand>? update,
    graphql.OnError? onError,
  }) : onCompletedWithParsed = onCompleted,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         onCompleted: onCompleted == null
             ? null
             : (data) => onCompleted(
                 data,
                 data == null ? null : _parserFn$Mutation$DwrCommand(data),
               ),
         update: update,
         onError: onError,
         document: documentNodeMutationDwrCommand,
         parserFn: _parserFn$Mutation$DwrCommand,
       );

  final OnMutationCompleted$Mutation$DwrCommand? onCompletedWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onCompleted == null
        ? super.properties
        : super.properties.where((property) => property != onCompleted),
    onCompletedWithParsed,
  ];
}

class WatchOptions$Mutation$DwrCommand
    extends graphql.WatchQueryOptions<Mutation$DwrCommand> {
  WatchOptions$Mutation$DwrCommand({
    String? operationName,
    required Variables$Mutation$DwrCommand variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Mutation$DwrCommand? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeMutationDwrCommand,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Mutation$DwrCommand,
       );
}

extension ClientExtension$Mutation$DwrCommand on graphql.GraphQLClient {
  Future<graphql.QueryResult<Mutation$DwrCommand>> mutate$DwrCommand(
    Options$Mutation$DwrCommand options,
  ) async => await this.mutate(options);

  graphql.ObservableQuery<Mutation$DwrCommand> watchMutation$DwrCommand(
    WatchOptions$Mutation$DwrCommand options,
  ) => this.watchMutation(options);
}

class Variables$Query$Payroll {
  factory Variables$Query$Payroll({required String siteId, dynamic? input}) =>
      Variables$Query$Payroll._({
        r'siteId': siteId,
        if (input != null) r'input': input,
      });

  Variables$Query$Payroll._(this._$data);

  factory Variables$Query$Payroll.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    if (data.containsKey('input')) {
      final l$input = data['input'];
      result$data['input'] = (l$input as dynamic?);
    }
    return Variables$Query$Payroll._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  dynamic? get input => (_$data['input'] as dynamic?);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    if (_$data.containsKey('input')) {
      final l$input = input;
      result$data['input'] = l$input;
    }
    return result$data;
  }

  CopyWith$Variables$Query$Payroll<Variables$Query$Payroll> get copyWith =>
      CopyWith$Variables$Query$Payroll(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$Payroll || runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    final l$input = input;
    final lOther$input = other.input;
    if (_$data.containsKey('input') != other._$data.containsKey('input')) {
      return false;
    }
    if (l$input != lOther$input) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    final l$input = input;
    return Object.hashAll([
      l$siteId,
      _$data.containsKey('input') ? l$input : const {},
    ]);
  }
}

abstract class CopyWith$Variables$Query$Payroll<TRes> {
  factory CopyWith$Variables$Query$Payroll(
    Variables$Query$Payroll instance,
    TRes Function(Variables$Query$Payroll) then,
  ) = _CopyWithImpl$Variables$Query$Payroll;

  factory CopyWith$Variables$Query$Payroll.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$Payroll;

  TRes call({String? siteId, dynamic? input});
}

class _CopyWithImpl$Variables$Query$Payroll<TRes>
    implements CopyWith$Variables$Query$Payroll<TRes> {
  _CopyWithImpl$Variables$Query$Payroll(this._instance, this._then);

  final Variables$Query$Payroll _instance;

  final TRes Function(Variables$Query$Payroll) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? siteId = _undefined, Object? input = _undefined}) => _then(
    Variables$Query$Payroll._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
      if (input != _undefined) 'input': (input as dynamic?),
    }),
  );
}

class _CopyWithStubImpl$Variables$Query$Payroll<TRes>
    implements CopyWith$Variables$Query$Payroll<TRes> {
  _CopyWithStubImpl$Variables$Query$Payroll(this._res);

  TRes _res;

  call({String? siteId, dynamic? input}) => _res;
}

class Query$Payroll {
  Query$Payroll({required this.payroll, this.$__typename = 'Query'});

  factory Query$Payroll.fromJson(Map<String, dynamic> json) {
    final l$payroll = json['payroll'];
    final l$$__typename = json['__typename'];
    return Query$Payroll(
      payroll: (l$payroll as dynamic),
      $__typename: (l$$__typename as String),
    );
  }

  final dynamic payroll;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$payroll = payroll;
    _resultData['payroll'] = l$payroll;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$payroll = payroll;
    final l$$__typename = $__typename;
    return Object.hashAll([l$payroll, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$Payroll || runtimeType != other.runtimeType) {
      return false;
    }
    final l$payroll = payroll;
    final lOther$payroll = other.payroll;
    if (l$payroll != lOther$payroll) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$Payroll on Query$Payroll {
  CopyWith$Query$Payroll<Query$Payroll> get copyWith =>
      CopyWith$Query$Payroll(this, (i) => i);
}

abstract class CopyWith$Query$Payroll<TRes> {
  factory CopyWith$Query$Payroll(
    Query$Payroll instance,
    TRes Function(Query$Payroll) then,
  ) = _CopyWithImpl$Query$Payroll;

  factory CopyWith$Query$Payroll.stub(TRes res) =
      _CopyWithStubImpl$Query$Payroll;

  TRes call({dynamic? payroll, String? $__typename});
}

class _CopyWithImpl$Query$Payroll<TRes>
    implements CopyWith$Query$Payroll<TRes> {
  _CopyWithImpl$Query$Payroll(this._instance, this._then);

  final Query$Payroll _instance;

  final TRes Function(Query$Payroll) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? payroll = _undefined, Object? $__typename = _undefined}) =>
      _then(
        Query$Payroll(
          payroll: payroll == _undefined || payroll == null
              ? _instance.payroll
              : (payroll as dynamic),
          $__typename: $__typename == _undefined || $__typename == null
              ? _instance.$__typename
              : ($__typename as String),
        ),
      );
}

class _CopyWithStubImpl$Query$Payroll<TRes>
    implements CopyWith$Query$Payroll<TRes> {
  _CopyWithStubImpl$Query$Payroll(this._res);

  TRes _res;

  call({dynamic? payroll, String? $__typename}) => _res;
}

const documentNodeQueryPayroll = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'Payroll'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'input')),
          type: NamedTypeNode(name: NameNode(value: 'JSON'), isNonNull: false),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'payroll'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'input'),
                value: VariableNode(name: NameNode(value: 'input')),
              ),
            ],
            directives: [],
            selectionSet: null,
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Query$Payroll _parserFn$Query$Payroll(Map<String, dynamic> data) =>
    Query$Payroll.fromJson(data);
typedef OnQueryComplete$Query$Payroll = FutureOr<void> Function(
  Map<String, dynamic>?,
  Query$Payroll?,
);

class Options$Query$Payroll extends graphql.QueryOptions<Query$Payroll> {
  Options$Query$Payroll({
    String? operationName,
    required Variables$Query$Payroll variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$Payroll? typedOptimisticResult,
    Duration? pollInterval,
    graphql.Context? context,
    OnQueryComplete$Query$Payroll? onComplete,
    graphql.OnQueryError? onError,
  }) : onCompleteWithParsed = onComplete,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         pollInterval: pollInterval,
         context: context,
         onComplete: onComplete == null
             ? null
             : (data) => onComplete(
                 data,
                 data == null ? null : _parserFn$Query$Payroll(data),
               ),
         onError: onError,
         document: documentNodeQueryPayroll,
         parserFn: _parserFn$Query$Payroll,
       );

  final OnQueryComplete$Query$Payroll? onCompleteWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onComplete == null
        ? super.properties
        : super.properties.where((property) => property != onComplete),
    onCompleteWithParsed,
  ];
}

class WatchOptions$Query$Payroll
    extends graphql.WatchQueryOptions<Query$Payroll> {
  WatchOptions$Query$Payroll({
    String? operationName,
    required Variables$Query$Payroll variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$Payroll? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeQueryPayroll,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Query$Payroll,
       );
}

class FetchMoreOptions$Query$Payroll extends graphql.FetchMoreOptions {
  FetchMoreOptions$Query$Payroll({
    required graphql.UpdateQuery updateQuery,
    required Variables$Query$Payroll variables,
  }) : super(
         updateQuery: updateQuery,
         variables: variables.toJson(),
         document: documentNodeQueryPayroll,
       );
}

extension ClientExtension$Query$Payroll on graphql.GraphQLClient {
  Future<graphql.QueryResult<Query$Payroll>> query$Payroll(
    Options$Query$Payroll options,
  ) async => await this.query(options);

  graphql.ObservableQuery<Query$Payroll> watchQuery$Payroll(
    WatchOptions$Query$Payroll options,
  ) => this.watchQuery(options);

  void writeQuery$Payroll({
    required Query$Payroll data,
    required Variables$Query$Payroll variables,
    bool broadcast = true,
  }) => this.writeQuery(
    graphql.Request(
      operation: graphql.Operation(document: documentNodeQueryPayroll),
      variables: variables.toJson(),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Query$Payroll? readQuery$Payroll({
    required Variables$Query$Payroll variables,
    bool optimistic = true,
  }) {
    final result = this.readQuery(
      graphql.Request(
        operation: graphql.Operation(document: documentNodeQueryPayroll),
        variables: variables.toJson(),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Query$Payroll.fromJson(result);
  }
}

class Variables$Query$HrRecords {
  factory Variables$Query$HrRecords({
    required String siteId,
    required String kind,
  }) => Variables$Query$HrRecords._({r'siteId': siteId, r'kind': kind});

  Variables$Query$HrRecords._(this._$data);

  factory Variables$Query$HrRecords.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    final l$kind = data['kind'];
    result$data['kind'] = (l$kind as String);
    return Variables$Query$HrRecords._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  String get kind => (_$data['kind'] as String);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    final l$kind = kind;
    result$data['kind'] = l$kind;
    return result$data;
  }

  CopyWith$Variables$Query$HrRecords<Variables$Query$HrRecords> get copyWith =>
      CopyWith$Variables$Query$HrRecords(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$HrRecords ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    final l$kind = kind;
    final lOther$kind = other.kind;
    if (l$kind != lOther$kind) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    final l$kind = kind;
    return Object.hashAll([l$siteId, l$kind]);
  }
}

abstract class CopyWith$Variables$Query$HrRecords<TRes> {
  factory CopyWith$Variables$Query$HrRecords(
    Variables$Query$HrRecords instance,
    TRes Function(Variables$Query$HrRecords) then,
  ) = _CopyWithImpl$Variables$Query$HrRecords;

  factory CopyWith$Variables$Query$HrRecords.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$HrRecords;

  TRes call({String? siteId, String? kind});
}

class _CopyWithImpl$Variables$Query$HrRecords<TRes>
    implements CopyWith$Variables$Query$HrRecords<TRes> {
  _CopyWithImpl$Variables$Query$HrRecords(this._instance, this._then);

  final Variables$Query$HrRecords _instance;

  final TRes Function(Variables$Query$HrRecords) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? siteId = _undefined, Object? kind = _undefined}) => _then(
    Variables$Query$HrRecords._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
      if (kind != _undefined && kind != null) 'kind': (kind as String),
    }),
  );
}

class _CopyWithStubImpl$Variables$Query$HrRecords<TRes>
    implements CopyWith$Variables$Query$HrRecords<TRes> {
  _CopyWithStubImpl$Variables$Query$HrRecords(this._res);

  TRes _res;

  call({String? siteId, String? kind}) => _res;
}

class Query$HrRecords {
  Query$HrRecords({required this.hrRecords, this.$__typename = 'Query'});

  factory Query$HrRecords.fromJson(Map<String, dynamic> json) {
    final l$hrRecords = json['hrRecords'];
    final l$$__typename = json['__typename'];
    return Query$HrRecords(
      hrRecords: (l$hrRecords as dynamic),
      $__typename: (l$$__typename as String),
    );
  }

  final dynamic hrRecords;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$hrRecords = hrRecords;
    _resultData['hrRecords'] = l$hrRecords;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$hrRecords = hrRecords;
    final l$$__typename = $__typename;
    return Object.hashAll([l$hrRecords, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$HrRecords || runtimeType != other.runtimeType) {
      return false;
    }
    final l$hrRecords = hrRecords;
    final lOther$hrRecords = other.hrRecords;
    if (l$hrRecords != lOther$hrRecords) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$HrRecords on Query$HrRecords {
  CopyWith$Query$HrRecords<Query$HrRecords> get copyWith =>
      CopyWith$Query$HrRecords(this, (i) => i);
}

abstract class CopyWith$Query$HrRecords<TRes> {
  factory CopyWith$Query$HrRecords(
    Query$HrRecords instance,
    TRes Function(Query$HrRecords) then,
  ) = _CopyWithImpl$Query$HrRecords;

  factory CopyWith$Query$HrRecords.stub(TRes res) =
      _CopyWithStubImpl$Query$HrRecords;

  TRes call({dynamic? hrRecords, String? $__typename});
}

class _CopyWithImpl$Query$HrRecords<TRes>
    implements CopyWith$Query$HrRecords<TRes> {
  _CopyWithImpl$Query$HrRecords(this._instance, this._then);

  final Query$HrRecords _instance;

  final TRes Function(Query$HrRecords) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? hrRecords = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$HrRecords(
      hrRecords: hrRecords == _undefined || hrRecords == null
          ? _instance.hrRecords
          : (hrRecords as dynamic),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$HrRecords<TRes>
    implements CopyWith$Query$HrRecords<TRes> {
  _CopyWithStubImpl$Query$HrRecords(this._res);

  TRes _res;

  call({dynamic? hrRecords, String? $__typename}) => _res;
}

const documentNodeQueryHrRecords = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'HrRecords'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'kind')),
          type: NamedTypeNode(name: NameNode(value: 'String'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'hrRecords'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'kind'),
                value: VariableNode(name: NameNode(value: 'kind')),
              ),
            ],
            directives: [],
            selectionSet: null,
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Query$HrRecords _parserFn$Query$HrRecords(Map<String, dynamic> data) =>
    Query$HrRecords.fromJson(data);
typedef OnQueryComplete$Query$HrRecords = FutureOr<void> Function(
  Map<String, dynamic>?,
  Query$HrRecords?,
);

class Options$Query$HrRecords extends graphql.QueryOptions<Query$HrRecords> {
  Options$Query$HrRecords({
    String? operationName,
    required Variables$Query$HrRecords variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$HrRecords? typedOptimisticResult,
    Duration? pollInterval,
    graphql.Context? context,
    OnQueryComplete$Query$HrRecords? onComplete,
    graphql.OnQueryError? onError,
  }) : onCompleteWithParsed = onComplete,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         pollInterval: pollInterval,
         context: context,
         onComplete: onComplete == null
             ? null
             : (data) => onComplete(
                 data,
                 data == null ? null : _parserFn$Query$HrRecords(data),
               ),
         onError: onError,
         document: documentNodeQueryHrRecords,
         parserFn: _parserFn$Query$HrRecords,
       );

  final OnQueryComplete$Query$HrRecords? onCompleteWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onComplete == null
        ? super.properties
        : super.properties.where((property) => property != onComplete),
    onCompleteWithParsed,
  ];
}

class WatchOptions$Query$HrRecords
    extends graphql.WatchQueryOptions<Query$HrRecords> {
  WatchOptions$Query$HrRecords({
    String? operationName,
    required Variables$Query$HrRecords variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$HrRecords? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeQueryHrRecords,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Query$HrRecords,
       );
}

class FetchMoreOptions$Query$HrRecords extends graphql.FetchMoreOptions {
  FetchMoreOptions$Query$HrRecords({
    required graphql.UpdateQuery updateQuery,
    required Variables$Query$HrRecords variables,
  }) : super(
         updateQuery: updateQuery,
         variables: variables.toJson(),
         document: documentNodeQueryHrRecords,
       );
}

extension ClientExtension$Query$HrRecords on graphql.GraphQLClient {
  Future<graphql.QueryResult<Query$HrRecords>> query$HrRecords(
    Options$Query$HrRecords options,
  ) async => await this.query(options);

  graphql.ObservableQuery<Query$HrRecords> watchQuery$HrRecords(
    WatchOptions$Query$HrRecords options,
  ) => this.watchQuery(options);

  void writeQuery$HrRecords({
    required Query$HrRecords data,
    required Variables$Query$HrRecords variables,
    bool broadcast = true,
  }) => this.writeQuery(
    graphql.Request(
      operation: graphql.Operation(document: documentNodeQueryHrRecords),
      variables: variables.toJson(),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Query$HrRecords? readQuery$HrRecords({
    required Variables$Query$HrRecords variables,
    bool optimistic = true,
  }) {
    final result = this.readQuery(
      graphql.Request(
        operation: graphql.Operation(document: documentNodeQueryHrRecords),
        variables: variables.toJson(),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Query$HrRecords.fromJson(result);
  }
}

class Variables$Mutation$PayrollCommand {
  factory Variables$Mutation$PayrollCommand({
    required String siteId,
    required String operation,
    required dynamic input,
  }) => Variables$Mutation$PayrollCommand._({
    r'siteId': siteId,
    r'operation': operation,
    r'input': input,
  });

  Variables$Mutation$PayrollCommand._(this._$data);

  factory Variables$Mutation$PayrollCommand.fromJson(
    Map<String, dynamic> data,
  ) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    final l$operation = data['operation'];
    result$data['operation'] = (l$operation as String);
    final l$input = data['input'];
    result$data['input'] = (l$input as dynamic);
    return Variables$Mutation$PayrollCommand._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  String get operation => (_$data['operation'] as String);

  dynamic get input => (_$data['input'] as dynamic);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    final l$operation = operation;
    result$data['operation'] = l$operation;
    final l$input = input;
    result$data['input'] = l$input;
    return result$data;
  }

  CopyWith$Variables$Mutation$PayrollCommand<Variables$Mutation$PayrollCommand>
  get copyWith => CopyWith$Variables$Mutation$PayrollCommand(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Mutation$PayrollCommand ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    final l$operation = operation;
    final lOther$operation = other.operation;
    if (l$operation != lOther$operation) {
      return false;
    }
    final l$input = input;
    final lOther$input = other.input;
    if (l$input != lOther$input) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    final l$operation = operation;
    final l$input = input;
    return Object.hashAll([l$siteId, l$operation, l$input]);
  }
}

abstract class CopyWith$Variables$Mutation$PayrollCommand<TRes> {
  factory CopyWith$Variables$Mutation$PayrollCommand(
    Variables$Mutation$PayrollCommand instance,
    TRes Function(Variables$Mutation$PayrollCommand) then,
  ) = _CopyWithImpl$Variables$Mutation$PayrollCommand;

  factory CopyWith$Variables$Mutation$PayrollCommand.stub(TRes res) =
      _CopyWithStubImpl$Variables$Mutation$PayrollCommand;

  TRes call({String? siteId, String? operation, dynamic? input});
}

class _CopyWithImpl$Variables$Mutation$PayrollCommand<TRes>
    implements CopyWith$Variables$Mutation$PayrollCommand<TRes> {
  _CopyWithImpl$Variables$Mutation$PayrollCommand(this._instance, this._then);

  final Variables$Mutation$PayrollCommand _instance;

  final TRes Function(Variables$Mutation$PayrollCommand) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? siteId = _undefined,
    Object? operation = _undefined,
    Object? input = _undefined,
  }) => _then(
    Variables$Mutation$PayrollCommand._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
      if (operation != _undefined && operation != null)
        'operation': (operation as String),
      if (input != _undefined && input != null) 'input': (input as dynamic),
    }),
  );
}

class _CopyWithStubImpl$Variables$Mutation$PayrollCommand<TRes>
    implements CopyWith$Variables$Mutation$PayrollCommand<TRes> {
  _CopyWithStubImpl$Variables$Mutation$PayrollCommand(this._res);

  TRes _res;

  call({String? siteId, String? operation, dynamic? input}) => _res;
}

class Mutation$PayrollCommand {
  Mutation$PayrollCommand({
    required this.payrollCommand,
    this.$__typename = 'Mutation',
  });

  factory Mutation$PayrollCommand.fromJson(Map<String, dynamic> json) {
    final l$payrollCommand = json['payrollCommand'];
    final l$$__typename = json['__typename'];
    return Mutation$PayrollCommand(
      payrollCommand: (l$payrollCommand as dynamic),
      $__typename: (l$$__typename as String),
    );
  }

  final dynamic payrollCommand;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$payrollCommand = payrollCommand;
    _resultData['payrollCommand'] = l$payrollCommand;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$payrollCommand = payrollCommand;
    final l$$__typename = $__typename;
    return Object.hashAll([l$payrollCommand, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Mutation$PayrollCommand || runtimeType != other.runtimeType) {
      return false;
    }
    final l$payrollCommand = payrollCommand;
    final lOther$payrollCommand = other.payrollCommand;
    if (l$payrollCommand != lOther$payrollCommand) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Mutation$PayrollCommand on Mutation$PayrollCommand {
  CopyWith$Mutation$PayrollCommand<Mutation$PayrollCommand> get copyWith =>
      CopyWith$Mutation$PayrollCommand(this, (i) => i);
}

abstract class CopyWith$Mutation$PayrollCommand<TRes> {
  factory CopyWith$Mutation$PayrollCommand(
    Mutation$PayrollCommand instance,
    TRes Function(Mutation$PayrollCommand) then,
  ) = _CopyWithImpl$Mutation$PayrollCommand;

  factory CopyWith$Mutation$PayrollCommand.stub(TRes res) =
      _CopyWithStubImpl$Mutation$PayrollCommand;

  TRes call({dynamic? payrollCommand, String? $__typename});
}

class _CopyWithImpl$Mutation$PayrollCommand<TRes>
    implements CopyWith$Mutation$PayrollCommand<TRes> {
  _CopyWithImpl$Mutation$PayrollCommand(this._instance, this._then);

  final Mutation$PayrollCommand _instance;

  final TRes Function(Mutation$PayrollCommand) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? payrollCommand = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Mutation$PayrollCommand(
      payrollCommand: payrollCommand == _undefined || payrollCommand == null
          ? _instance.payrollCommand
          : (payrollCommand as dynamic),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Mutation$PayrollCommand<TRes>
    implements CopyWith$Mutation$PayrollCommand<TRes> {
  _CopyWithStubImpl$Mutation$PayrollCommand(this._res);

  TRes _res;

  call({dynamic? payrollCommand, String? $__typename}) => _res;
}

const documentNodeMutationPayrollCommand = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.mutation,
      name: NameNode(value: 'PayrollCommand'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'operation')),
          type: NamedTypeNode(name: NameNode(value: 'String'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'input')),
          type: NamedTypeNode(name: NameNode(value: 'JSON'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'payrollCommand'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'operation'),
                value: VariableNode(name: NameNode(value: 'operation')),
              ),
              ArgumentNode(
                name: NameNode(value: 'input'),
                value: VariableNode(name: NameNode(value: 'input')),
              ),
            ],
            directives: [],
            selectionSet: null,
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Mutation$PayrollCommand _parserFn$Mutation$PayrollCommand(
  Map<String, dynamic> data,
) => Mutation$PayrollCommand.fromJson(data);
typedef OnMutationCompleted$Mutation$PayrollCommand = FutureOr<void> Function(
  Map<String, dynamic>?,
  Mutation$PayrollCommand?,
);

class Options$Mutation$PayrollCommand
    extends graphql.MutationOptions<Mutation$PayrollCommand> {
  Options$Mutation$PayrollCommand({
    String? operationName,
    required Variables$Mutation$PayrollCommand variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Mutation$PayrollCommand? typedOptimisticResult,
    graphql.Context? context,
    OnMutationCompleted$Mutation$PayrollCommand? onCompleted,
    graphql.OnMutationUpdate<Mutation$PayrollCommand>? update,
    graphql.OnError? onError,
  }) : onCompletedWithParsed = onCompleted,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         onCompleted: onCompleted == null
             ? null
             : (data) => onCompleted(
                 data,
                 data == null ? null : _parserFn$Mutation$PayrollCommand(data),
               ),
         update: update,
         onError: onError,
         document: documentNodeMutationPayrollCommand,
         parserFn: _parserFn$Mutation$PayrollCommand,
       );

  final OnMutationCompleted$Mutation$PayrollCommand? onCompletedWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onCompleted == null
        ? super.properties
        : super.properties.where((property) => property != onCompleted),
    onCompletedWithParsed,
  ];
}

class WatchOptions$Mutation$PayrollCommand
    extends graphql.WatchQueryOptions<Mutation$PayrollCommand> {
  WatchOptions$Mutation$PayrollCommand({
    String? operationName,
    required Variables$Mutation$PayrollCommand variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Mutation$PayrollCommand? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeMutationPayrollCommand,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Mutation$PayrollCommand,
       );
}

extension ClientExtension$Mutation$PayrollCommand on graphql.GraphQLClient {
  Future<graphql.QueryResult<Mutation$PayrollCommand>> mutate$PayrollCommand(
    Options$Mutation$PayrollCommand options,
  ) async => await this.mutate(options);

  graphql.ObservableQuery<Mutation$PayrollCommand> watchMutation$PayrollCommand(
    WatchOptions$Mutation$PayrollCommand options,
  ) => this.watchMutation(options);
}

class Variables$Mutation$HrCommand {
  factory Variables$Mutation$HrCommand({
    required String siteId,
    required String operation,
    required dynamic input,
  }) => Variables$Mutation$HrCommand._({
    r'siteId': siteId,
    r'operation': operation,
    r'input': input,
  });

  Variables$Mutation$HrCommand._(this._$data);

  factory Variables$Mutation$HrCommand.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    final l$operation = data['operation'];
    result$data['operation'] = (l$operation as String);
    final l$input = data['input'];
    result$data['input'] = (l$input as dynamic);
    return Variables$Mutation$HrCommand._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  String get operation => (_$data['operation'] as String);

  dynamic get input => (_$data['input'] as dynamic);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    final l$operation = operation;
    result$data['operation'] = l$operation;
    final l$input = input;
    result$data['input'] = l$input;
    return result$data;
  }

  CopyWith$Variables$Mutation$HrCommand<Variables$Mutation$HrCommand>
  get copyWith => CopyWith$Variables$Mutation$HrCommand(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Mutation$HrCommand ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    final l$operation = operation;
    final lOther$operation = other.operation;
    if (l$operation != lOther$operation) {
      return false;
    }
    final l$input = input;
    final lOther$input = other.input;
    if (l$input != lOther$input) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    final l$operation = operation;
    final l$input = input;
    return Object.hashAll([l$siteId, l$operation, l$input]);
  }
}

abstract class CopyWith$Variables$Mutation$HrCommand<TRes> {
  factory CopyWith$Variables$Mutation$HrCommand(
    Variables$Mutation$HrCommand instance,
    TRes Function(Variables$Mutation$HrCommand) then,
  ) = _CopyWithImpl$Variables$Mutation$HrCommand;

  factory CopyWith$Variables$Mutation$HrCommand.stub(TRes res) =
      _CopyWithStubImpl$Variables$Mutation$HrCommand;

  TRes call({String? siteId, String? operation, dynamic? input});
}

class _CopyWithImpl$Variables$Mutation$HrCommand<TRes>
    implements CopyWith$Variables$Mutation$HrCommand<TRes> {
  _CopyWithImpl$Variables$Mutation$HrCommand(this._instance, this._then);

  final Variables$Mutation$HrCommand _instance;

  final TRes Function(Variables$Mutation$HrCommand) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? siteId = _undefined,
    Object? operation = _undefined,
    Object? input = _undefined,
  }) => _then(
    Variables$Mutation$HrCommand._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
      if (operation != _undefined && operation != null)
        'operation': (operation as String),
      if (input != _undefined && input != null) 'input': (input as dynamic),
    }),
  );
}

class _CopyWithStubImpl$Variables$Mutation$HrCommand<TRes>
    implements CopyWith$Variables$Mutation$HrCommand<TRes> {
  _CopyWithStubImpl$Variables$Mutation$HrCommand(this._res);

  TRes _res;

  call({String? siteId, String? operation, dynamic? input}) => _res;
}

class Mutation$HrCommand {
  Mutation$HrCommand({required this.hrCommand, this.$__typename = 'Mutation'});

  factory Mutation$HrCommand.fromJson(Map<String, dynamic> json) {
    final l$hrCommand = json['hrCommand'];
    final l$$__typename = json['__typename'];
    return Mutation$HrCommand(
      hrCommand: (l$hrCommand as dynamic),
      $__typename: (l$$__typename as String),
    );
  }

  final dynamic hrCommand;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$hrCommand = hrCommand;
    _resultData['hrCommand'] = l$hrCommand;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$hrCommand = hrCommand;
    final l$$__typename = $__typename;
    return Object.hashAll([l$hrCommand, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Mutation$HrCommand || runtimeType != other.runtimeType) {
      return false;
    }
    final l$hrCommand = hrCommand;
    final lOther$hrCommand = other.hrCommand;
    if (l$hrCommand != lOther$hrCommand) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Mutation$HrCommand on Mutation$HrCommand {
  CopyWith$Mutation$HrCommand<Mutation$HrCommand> get copyWith =>
      CopyWith$Mutation$HrCommand(this, (i) => i);
}

abstract class CopyWith$Mutation$HrCommand<TRes> {
  factory CopyWith$Mutation$HrCommand(
    Mutation$HrCommand instance,
    TRes Function(Mutation$HrCommand) then,
  ) = _CopyWithImpl$Mutation$HrCommand;

  factory CopyWith$Mutation$HrCommand.stub(TRes res) =
      _CopyWithStubImpl$Mutation$HrCommand;

  TRes call({dynamic? hrCommand, String? $__typename});
}

class _CopyWithImpl$Mutation$HrCommand<TRes>
    implements CopyWith$Mutation$HrCommand<TRes> {
  _CopyWithImpl$Mutation$HrCommand(this._instance, this._then);

  final Mutation$HrCommand _instance;

  final TRes Function(Mutation$HrCommand) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? hrCommand = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Mutation$HrCommand(
      hrCommand: hrCommand == _undefined || hrCommand == null
          ? _instance.hrCommand
          : (hrCommand as dynamic),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Mutation$HrCommand<TRes>
    implements CopyWith$Mutation$HrCommand<TRes> {
  _CopyWithStubImpl$Mutation$HrCommand(this._res);

  TRes _res;

  call({dynamic? hrCommand, String? $__typename}) => _res;
}

const documentNodeMutationHrCommand = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.mutation,
      name: NameNode(value: 'HrCommand'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'operation')),
          type: NamedTypeNode(name: NameNode(value: 'String'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'input')),
          type: NamedTypeNode(name: NameNode(value: 'JSON'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'hrCommand'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'operation'),
                value: VariableNode(name: NameNode(value: 'operation')),
              ),
              ArgumentNode(
                name: NameNode(value: 'input'),
                value: VariableNode(name: NameNode(value: 'input')),
              ),
            ],
            directives: [],
            selectionSet: null,
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Mutation$HrCommand _parserFn$Mutation$HrCommand(Map<String, dynamic> data) =>
    Mutation$HrCommand.fromJson(data);
typedef OnMutationCompleted$Mutation$HrCommand = FutureOr<void> Function(
  Map<String, dynamic>?,
  Mutation$HrCommand?,
);

class Options$Mutation$HrCommand
    extends graphql.MutationOptions<Mutation$HrCommand> {
  Options$Mutation$HrCommand({
    String? operationName,
    required Variables$Mutation$HrCommand variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Mutation$HrCommand? typedOptimisticResult,
    graphql.Context? context,
    OnMutationCompleted$Mutation$HrCommand? onCompleted,
    graphql.OnMutationUpdate<Mutation$HrCommand>? update,
    graphql.OnError? onError,
  }) : onCompletedWithParsed = onCompleted,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         onCompleted: onCompleted == null
             ? null
             : (data) => onCompleted(
                 data,
                 data == null ? null : _parserFn$Mutation$HrCommand(data),
               ),
         update: update,
         onError: onError,
         document: documentNodeMutationHrCommand,
         parserFn: _parserFn$Mutation$HrCommand,
       );

  final OnMutationCompleted$Mutation$HrCommand? onCompletedWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onCompleted == null
        ? super.properties
        : super.properties.where((property) => property != onCompleted),
    onCompletedWithParsed,
  ];
}

class WatchOptions$Mutation$HrCommand
    extends graphql.WatchQueryOptions<Mutation$HrCommand> {
  WatchOptions$Mutation$HrCommand({
    String? operationName,
    required Variables$Mutation$HrCommand variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Mutation$HrCommand? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeMutationHrCommand,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Mutation$HrCommand,
       );
}

extension ClientExtension$Mutation$HrCommand on graphql.GraphQLClient {
  Future<graphql.QueryResult<Mutation$HrCommand>> mutate$HrCommand(
    Options$Mutation$HrCommand options,
  ) async => await this.mutate(options);

  graphql.ObservableQuery<Mutation$HrCommand> watchMutation$HrCommand(
    WatchOptions$Mutation$HrCommand options,
  ) => this.watchMutation(options);
}

class Variables$Query$ApprovalQueue {
  factory Variables$Query$ApprovalQueue({required String siteId}) =>
      Variables$Query$ApprovalQueue._({r'siteId': siteId});

  Variables$Query$ApprovalQueue._(this._$data);

  factory Variables$Query$ApprovalQueue.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    return Variables$Query$ApprovalQueue._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    return result$data;
  }

  CopyWith$Variables$Query$ApprovalQueue<Variables$Query$ApprovalQueue>
  get copyWith => CopyWith$Variables$Query$ApprovalQueue(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$ApprovalQueue ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    return Object.hashAll([l$siteId]);
  }
}

abstract class CopyWith$Variables$Query$ApprovalQueue<TRes> {
  factory CopyWith$Variables$Query$ApprovalQueue(
    Variables$Query$ApprovalQueue instance,
    TRes Function(Variables$Query$ApprovalQueue) then,
  ) = _CopyWithImpl$Variables$Query$ApprovalQueue;

  factory CopyWith$Variables$Query$ApprovalQueue.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$ApprovalQueue;

  TRes call({String? siteId});
}

class _CopyWithImpl$Variables$Query$ApprovalQueue<TRes>
    implements CopyWith$Variables$Query$ApprovalQueue<TRes> {
  _CopyWithImpl$Variables$Query$ApprovalQueue(this._instance, this._then);

  final Variables$Query$ApprovalQueue _instance;

  final TRes Function(Variables$Query$ApprovalQueue) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? siteId = _undefined}) => _then(
    Variables$Query$ApprovalQueue._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
    }),
  );
}

class _CopyWithStubImpl$Variables$Query$ApprovalQueue<TRes>
    implements CopyWith$Variables$Query$ApprovalQueue<TRes> {
  _CopyWithStubImpl$Variables$Query$ApprovalQueue(this._res);

  TRes _res;

  call({String? siteId}) => _res;
}

class Query$ApprovalQueue {
  Query$ApprovalQueue({
    required this.approvalQueue,
    this.$__typename = 'Query',
  });

  factory Query$ApprovalQueue.fromJson(Map<String, dynamic> json) {
    final l$approvalQueue = json['approvalQueue'];
    final l$$__typename = json['__typename'];
    return Query$ApprovalQueue(
      approvalQueue: (l$approvalQueue as dynamic),
      $__typename: (l$$__typename as String),
    );
  }

  final dynamic approvalQueue;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$approvalQueue = approvalQueue;
    _resultData['approvalQueue'] = l$approvalQueue;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$approvalQueue = approvalQueue;
    final l$$__typename = $__typename;
    return Object.hashAll([l$approvalQueue, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$ApprovalQueue || runtimeType != other.runtimeType) {
      return false;
    }
    final l$approvalQueue = approvalQueue;
    final lOther$approvalQueue = other.approvalQueue;
    if (l$approvalQueue != lOther$approvalQueue) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$ApprovalQueue on Query$ApprovalQueue {
  CopyWith$Query$ApprovalQueue<Query$ApprovalQueue> get copyWith =>
      CopyWith$Query$ApprovalQueue(this, (i) => i);
}

abstract class CopyWith$Query$ApprovalQueue<TRes> {
  factory CopyWith$Query$ApprovalQueue(
    Query$ApprovalQueue instance,
    TRes Function(Query$ApprovalQueue) then,
  ) = _CopyWithImpl$Query$ApprovalQueue;

  factory CopyWith$Query$ApprovalQueue.stub(TRes res) =
      _CopyWithStubImpl$Query$ApprovalQueue;

  TRes call({dynamic? approvalQueue, String? $__typename});
}

class _CopyWithImpl$Query$ApprovalQueue<TRes>
    implements CopyWith$Query$ApprovalQueue<TRes> {
  _CopyWithImpl$Query$ApprovalQueue(this._instance, this._then);

  final Query$ApprovalQueue _instance;

  final TRes Function(Query$ApprovalQueue) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? approvalQueue = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$ApprovalQueue(
      approvalQueue: approvalQueue == _undefined || approvalQueue == null
          ? _instance.approvalQueue
          : (approvalQueue as dynamic),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$ApprovalQueue<TRes>
    implements CopyWith$Query$ApprovalQueue<TRes> {
  _CopyWithStubImpl$Query$ApprovalQueue(this._res);

  TRes _res;

  call({dynamic? approvalQueue, String? $__typename}) => _res;
}

const documentNodeQueryApprovalQueue = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'ApprovalQueue'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'approvalQueue'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
            ],
            directives: [],
            selectionSet: null,
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Query$ApprovalQueue _parserFn$Query$ApprovalQueue(Map<String, dynamic> data) =>
    Query$ApprovalQueue.fromJson(data);
typedef OnQueryComplete$Query$ApprovalQueue = FutureOr<void> Function(
  Map<String, dynamic>?,
  Query$ApprovalQueue?,
);

class Options$Query$ApprovalQueue
    extends graphql.QueryOptions<Query$ApprovalQueue> {
  Options$Query$ApprovalQueue({
    String? operationName,
    required Variables$Query$ApprovalQueue variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$ApprovalQueue? typedOptimisticResult,
    Duration? pollInterval,
    graphql.Context? context,
    OnQueryComplete$Query$ApprovalQueue? onComplete,
    graphql.OnQueryError? onError,
  }) : onCompleteWithParsed = onComplete,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         pollInterval: pollInterval,
         context: context,
         onComplete: onComplete == null
             ? null
             : (data) => onComplete(
                 data,
                 data == null ? null : _parserFn$Query$ApprovalQueue(data),
               ),
         onError: onError,
         document: documentNodeQueryApprovalQueue,
         parserFn: _parserFn$Query$ApprovalQueue,
       );

  final OnQueryComplete$Query$ApprovalQueue? onCompleteWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onComplete == null
        ? super.properties
        : super.properties.where((property) => property != onComplete),
    onCompleteWithParsed,
  ];
}

class WatchOptions$Query$ApprovalQueue
    extends graphql.WatchQueryOptions<Query$ApprovalQueue> {
  WatchOptions$Query$ApprovalQueue({
    String? operationName,
    required Variables$Query$ApprovalQueue variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$ApprovalQueue? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeQueryApprovalQueue,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Query$ApprovalQueue,
       );
}

class FetchMoreOptions$Query$ApprovalQueue extends graphql.FetchMoreOptions {
  FetchMoreOptions$Query$ApprovalQueue({
    required graphql.UpdateQuery updateQuery,
    required Variables$Query$ApprovalQueue variables,
  }) : super(
         updateQuery: updateQuery,
         variables: variables.toJson(),
         document: documentNodeQueryApprovalQueue,
       );
}

extension ClientExtension$Query$ApprovalQueue on graphql.GraphQLClient {
  Future<graphql.QueryResult<Query$ApprovalQueue>> query$ApprovalQueue(
    Options$Query$ApprovalQueue options,
  ) async => await this.query(options);

  graphql.ObservableQuery<Query$ApprovalQueue> watchQuery$ApprovalQueue(
    WatchOptions$Query$ApprovalQueue options,
  ) => this.watchQuery(options);

  void writeQuery$ApprovalQueue({
    required Query$ApprovalQueue data,
    required Variables$Query$ApprovalQueue variables,
    bool broadcast = true,
  }) => this.writeQuery(
    graphql.Request(
      operation: graphql.Operation(document: documentNodeQueryApprovalQueue),
      variables: variables.toJson(),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Query$ApprovalQueue? readQuery$ApprovalQueue({
    required Variables$Query$ApprovalQueue variables,
    bool optimistic = true,
  }) {
    final result = this.readQuery(
      graphql.Request(
        operation: graphql.Operation(document: documentNodeQueryApprovalQueue),
        variables: variables.toJson(),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Query$ApprovalQueue.fromJson(result);
  }
}

class Variables$Query$Dashboard {
  factory Variables$Query$Dashboard({required String siteId}) =>
      Variables$Query$Dashboard._({r'siteId': siteId});

  Variables$Query$Dashboard._(this._$data);

  factory Variables$Query$Dashboard.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    return Variables$Query$Dashboard._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    return result$data;
  }

  CopyWith$Variables$Query$Dashboard<Variables$Query$Dashboard> get copyWith =>
      CopyWith$Variables$Query$Dashboard(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$Dashboard ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    return Object.hashAll([l$siteId]);
  }
}

abstract class CopyWith$Variables$Query$Dashboard<TRes> {
  factory CopyWith$Variables$Query$Dashboard(
    Variables$Query$Dashboard instance,
    TRes Function(Variables$Query$Dashboard) then,
  ) = _CopyWithImpl$Variables$Query$Dashboard;

  factory CopyWith$Variables$Query$Dashboard.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$Dashboard;

  TRes call({String? siteId});
}

class _CopyWithImpl$Variables$Query$Dashboard<TRes>
    implements CopyWith$Variables$Query$Dashboard<TRes> {
  _CopyWithImpl$Variables$Query$Dashboard(this._instance, this._then);

  final Variables$Query$Dashboard _instance;

  final TRes Function(Variables$Query$Dashboard) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? siteId = _undefined}) => _then(
    Variables$Query$Dashboard._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
    }),
  );
}

class _CopyWithStubImpl$Variables$Query$Dashboard<TRes>
    implements CopyWith$Variables$Query$Dashboard<TRes> {
  _CopyWithStubImpl$Variables$Query$Dashboard(this._res);

  TRes _res;

  call({String? siteId}) => _res;
}

class Query$Dashboard {
  Query$Dashboard({required this.dashboard, this.$__typename = 'Query'});

  factory Query$Dashboard.fromJson(Map<String, dynamic> json) {
    final l$dashboard = json['dashboard'];
    final l$$__typename = json['__typename'];
    return Query$Dashboard(
      dashboard: (l$dashboard as dynamic),
      $__typename: (l$$__typename as String),
    );
  }

  final dynamic dashboard;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$dashboard = dashboard;
    _resultData['dashboard'] = l$dashboard;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$dashboard = dashboard;
    final l$$__typename = $__typename;
    return Object.hashAll([l$dashboard, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$Dashboard || runtimeType != other.runtimeType) {
      return false;
    }
    final l$dashboard = dashboard;
    final lOther$dashboard = other.dashboard;
    if (l$dashboard != lOther$dashboard) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$Dashboard on Query$Dashboard {
  CopyWith$Query$Dashboard<Query$Dashboard> get copyWith =>
      CopyWith$Query$Dashboard(this, (i) => i);
}

abstract class CopyWith$Query$Dashboard<TRes> {
  factory CopyWith$Query$Dashboard(
    Query$Dashboard instance,
    TRes Function(Query$Dashboard) then,
  ) = _CopyWithImpl$Query$Dashboard;

  factory CopyWith$Query$Dashboard.stub(TRes res) =
      _CopyWithStubImpl$Query$Dashboard;

  TRes call({dynamic? dashboard, String? $__typename});
}

class _CopyWithImpl$Query$Dashboard<TRes>
    implements CopyWith$Query$Dashboard<TRes> {
  _CopyWithImpl$Query$Dashboard(this._instance, this._then);

  final Query$Dashboard _instance;

  final TRes Function(Query$Dashboard) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? dashboard = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$Dashboard(
      dashboard: dashboard == _undefined || dashboard == null
          ? _instance.dashboard
          : (dashboard as dynamic),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$Dashboard<TRes>
    implements CopyWith$Query$Dashboard<TRes> {
  _CopyWithStubImpl$Query$Dashboard(this._res);

  TRes _res;

  call({dynamic? dashboard, String? $__typename}) => _res;
}

const documentNodeQueryDashboard = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'Dashboard'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'dashboard'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
            ],
            directives: [],
            selectionSet: null,
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Query$Dashboard _parserFn$Query$Dashboard(Map<String, dynamic> data) =>
    Query$Dashboard.fromJson(data);
typedef OnQueryComplete$Query$Dashboard = FutureOr<void> Function(
  Map<String, dynamic>?,
  Query$Dashboard?,
);

class Options$Query$Dashboard extends graphql.QueryOptions<Query$Dashboard> {
  Options$Query$Dashboard({
    String? operationName,
    required Variables$Query$Dashboard variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$Dashboard? typedOptimisticResult,
    Duration? pollInterval,
    graphql.Context? context,
    OnQueryComplete$Query$Dashboard? onComplete,
    graphql.OnQueryError? onError,
  }) : onCompleteWithParsed = onComplete,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         pollInterval: pollInterval,
         context: context,
         onComplete: onComplete == null
             ? null
             : (data) => onComplete(
                 data,
                 data == null ? null : _parserFn$Query$Dashboard(data),
               ),
         onError: onError,
         document: documentNodeQueryDashboard,
         parserFn: _parserFn$Query$Dashboard,
       );

  final OnQueryComplete$Query$Dashboard? onCompleteWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onComplete == null
        ? super.properties
        : super.properties.where((property) => property != onComplete),
    onCompleteWithParsed,
  ];
}

class WatchOptions$Query$Dashboard
    extends graphql.WatchQueryOptions<Query$Dashboard> {
  WatchOptions$Query$Dashboard({
    String? operationName,
    required Variables$Query$Dashboard variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$Dashboard? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeQueryDashboard,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Query$Dashboard,
       );
}

class FetchMoreOptions$Query$Dashboard extends graphql.FetchMoreOptions {
  FetchMoreOptions$Query$Dashboard({
    required graphql.UpdateQuery updateQuery,
    required Variables$Query$Dashboard variables,
  }) : super(
         updateQuery: updateQuery,
         variables: variables.toJson(),
         document: documentNodeQueryDashboard,
       );
}

extension ClientExtension$Query$Dashboard on graphql.GraphQLClient {
  Future<graphql.QueryResult<Query$Dashboard>> query$Dashboard(
    Options$Query$Dashboard options,
  ) async => await this.query(options);

  graphql.ObservableQuery<Query$Dashboard> watchQuery$Dashboard(
    WatchOptions$Query$Dashboard options,
  ) => this.watchQuery(options);

  void writeQuery$Dashboard({
    required Query$Dashboard data,
    required Variables$Query$Dashboard variables,
    bool broadcast = true,
  }) => this.writeQuery(
    graphql.Request(
      operation: graphql.Operation(document: documentNodeQueryDashboard),
      variables: variables.toJson(),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Query$Dashboard? readQuery$Dashboard({
    required Variables$Query$Dashboard variables,
    bool optimistic = true,
  }) {
    final result = this.readQuery(
      graphql.Request(
        operation: graphql.Operation(document: documentNodeQueryDashboard),
        variables: variables.toJson(),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Query$Dashboard.fromJson(result);
  }
}

class Variables$Query$EmployeeLookup {
  factory Variables$Query$EmployeeLookup({
    required String siteId,
    required String search,
  }) =>
      Variables$Query$EmployeeLookup._({r'siteId': siteId, r'search': search});

  Variables$Query$EmployeeLookup._(this._$data);

  factory Variables$Query$EmployeeLookup.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    final l$search = data['search'];
    result$data['search'] = (l$search as String);
    return Variables$Query$EmployeeLookup._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  String get search => (_$data['search'] as String);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    final l$search = search;
    result$data['search'] = l$search;
    return result$data;
  }

  CopyWith$Variables$Query$EmployeeLookup<Variables$Query$EmployeeLookup>
  get copyWith => CopyWith$Variables$Query$EmployeeLookup(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$EmployeeLookup ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    final l$search = search;
    final lOther$search = other.search;
    if (l$search != lOther$search) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    final l$search = search;
    return Object.hashAll([l$siteId, l$search]);
  }
}

abstract class CopyWith$Variables$Query$EmployeeLookup<TRes> {
  factory CopyWith$Variables$Query$EmployeeLookup(
    Variables$Query$EmployeeLookup instance,
    TRes Function(Variables$Query$EmployeeLookup) then,
  ) = _CopyWithImpl$Variables$Query$EmployeeLookup;

  factory CopyWith$Variables$Query$EmployeeLookup.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$EmployeeLookup;

  TRes call({String? siteId, String? search});
}

class _CopyWithImpl$Variables$Query$EmployeeLookup<TRes>
    implements CopyWith$Variables$Query$EmployeeLookup<TRes> {
  _CopyWithImpl$Variables$Query$EmployeeLookup(this._instance, this._then);

  final Variables$Query$EmployeeLookup _instance;

  final TRes Function(Variables$Query$EmployeeLookup) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? siteId = _undefined,
    Object? search = _undefined,
  }) => _then(
    Variables$Query$EmployeeLookup._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
      if (search != _undefined && search != null) 'search': (search as String),
    }),
  );
}

class _CopyWithStubImpl$Variables$Query$EmployeeLookup<TRes>
    implements CopyWith$Variables$Query$EmployeeLookup<TRes> {
  _CopyWithStubImpl$Variables$Query$EmployeeLookup(this._res);

  TRes _res;

  call({String? siteId, String? search}) => _res;
}

class Query$EmployeeLookup {
  Query$EmployeeLookup({
    required this.employeeLookup,
    this.$__typename = 'Query',
  });

  factory Query$EmployeeLookup.fromJson(Map<String, dynamic> json) {
    final l$employeeLookup = json['employeeLookup'];
    final l$$__typename = json['__typename'];
    return Query$EmployeeLookup(
      employeeLookup: (l$employeeLookup as dynamic),
      $__typename: (l$$__typename as String),
    );
  }

  final dynamic employeeLookup;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$employeeLookup = employeeLookup;
    _resultData['employeeLookup'] = l$employeeLookup;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$employeeLookup = employeeLookup;
    final l$$__typename = $__typename;
    return Object.hashAll([l$employeeLookup, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$EmployeeLookup || runtimeType != other.runtimeType) {
      return false;
    }
    final l$employeeLookup = employeeLookup;
    final lOther$employeeLookup = other.employeeLookup;
    if (l$employeeLookup != lOther$employeeLookup) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$EmployeeLookup on Query$EmployeeLookup {
  CopyWith$Query$EmployeeLookup<Query$EmployeeLookup> get copyWith =>
      CopyWith$Query$EmployeeLookup(this, (i) => i);
}

abstract class CopyWith$Query$EmployeeLookup<TRes> {
  factory CopyWith$Query$EmployeeLookup(
    Query$EmployeeLookup instance,
    TRes Function(Query$EmployeeLookup) then,
  ) = _CopyWithImpl$Query$EmployeeLookup;

  factory CopyWith$Query$EmployeeLookup.stub(TRes res) =
      _CopyWithStubImpl$Query$EmployeeLookup;

  TRes call({dynamic? employeeLookup, String? $__typename});
}

class _CopyWithImpl$Query$EmployeeLookup<TRes>
    implements CopyWith$Query$EmployeeLookup<TRes> {
  _CopyWithImpl$Query$EmployeeLookup(this._instance, this._then);

  final Query$EmployeeLookup _instance;

  final TRes Function(Query$EmployeeLookup) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? employeeLookup = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$EmployeeLookup(
      employeeLookup: employeeLookup == _undefined || employeeLookup == null
          ? _instance.employeeLookup
          : (employeeLookup as dynamic),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$EmployeeLookup<TRes>
    implements CopyWith$Query$EmployeeLookup<TRes> {
  _CopyWithStubImpl$Query$EmployeeLookup(this._res);

  TRes _res;

  call({dynamic? employeeLookup, String? $__typename}) => _res;
}

const documentNodeQueryEmployeeLookup = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'EmployeeLookup'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'search')),
          type: NamedTypeNode(name: NameNode(value: 'String'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'employeeLookup'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'search'),
                value: VariableNode(name: NameNode(value: 'search')),
              ),
            ],
            directives: [],
            selectionSet: null,
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Query$EmployeeLookup _parserFn$Query$EmployeeLookup(
  Map<String, dynamic> data,
) => Query$EmployeeLookup.fromJson(data);
typedef OnQueryComplete$Query$EmployeeLookup = FutureOr<void> Function(
  Map<String, dynamic>?,
  Query$EmployeeLookup?,
);

class Options$Query$EmployeeLookup
    extends graphql.QueryOptions<Query$EmployeeLookup> {
  Options$Query$EmployeeLookup({
    String? operationName,
    required Variables$Query$EmployeeLookup variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$EmployeeLookup? typedOptimisticResult,
    Duration? pollInterval,
    graphql.Context? context,
    OnQueryComplete$Query$EmployeeLookup? onComplete,
    graphql.OnQueryError? onError,
  }) : onCompleteWithParsed = onComplete,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         pollInterval: pollInterval,
         context: context,
         onComplete: onComplete == null
             ? null
             : (data) => onComplete(
                 data,
                 data == null ? null : _parserFn$Query$EmployeeLookup(data),
               ),
         onError: onError,
         document: documentNodeQueryEmployeeLookup,
         parserFn: _parserFn$Query$EmployeeLookup,
       );

  final OnQueryComplete$Query$EmployeeLookup? onCompleteWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onComplete == null
        ? super.properties
        : super.properties.where((property) => property != onComplete),
    onCompleteWithParsed,
  ];
}

class WatchOptions$Query$EmployeeLookup
    extends graphql.WatchQueryOptions<Query$EmployeeLookup> {
  WatchOptions$Query$EmployeeLookup({
    String? operationName,
    required Variables$Query$EmployeeLookup variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$EmployeeLookup? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeQueryEmployeeLookup,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Query$EmployeeLookup,
       );
}

class FetchMoreOptions$Query$EmployeeLookup extends graphql.FetchMoreOptions {
  FetchMoreOptions$Query$EmployeeLookup({
    required graphql.UpdateQuery updateQuery,
    required Variables$Query$EmployeeLookup variables,
  }) : super(
         updateQuery: updateQuery,
         variables: variables.toJson(),
         document: documentNodeQueryEmployeeLookup,
       );
}

extension ClientExtension$Query$EmployeeLookup on graphql.GraphQLClient {
  Future<graphql.QueryResult<Query$EmployeeLookup>> query$EmployeeLookup(
    Options$Query$EmployeeLookup options,
  ) async => await this.query(options);

  graphql.ObservableQuery<Query$EmployeeLookup> watchQuery$EmployeeLookup(
    WatchOptions$Query$EmployeeLookup options,
  ) => this.watchQuery(options);

  void writeQuery$EmployeeLookup({
    required Query$EmployeeLookup data,
    required Variables$Query$EmployeeLookup variables,
    bool broadcast = true,
  }) => this.writeQuery(
    graphql.Request(
      operation: graphql.Operation(document: documentNodeQueryEmployeeLookup),
      variables: variables.toJson(),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Query$EmployeeLookup? readQuery$EmployeeLookup({
    required Variables$Query$EmployeeLookup variables,
    bool optimistic = true,
  }) {
    final result = this.readQuery(
      graphql.Request(
        operation: graphql.Operation(document: documentNodeQueryEmployeeLookup),
        variables: variables.toJson(),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Query$EmployeeLookup.fromJson(result);
  }
}

class Variables$Query$Analytics {
  factory Variables$Query$Analytics({
    required String siteId,
    required dynamic input,
  }) => Variables$Query$Analytics._({r'siteId': siteId, r'input': input});

  Variables$Query$Analytics._(this._$data);

  factory Variables$Query$Analytics.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    final l$input = data['input'];
    result$data['input'] = (l$input as dynamic);
    return Variables$Query$Analytics._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  dynamic get input => (_$data['input'] as dynamic);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    final l$input = input;
    result$data['input'] = l$input;
    return result$data;
  }

  CopyWith$Variables$Query$Analytics<Variables$Query$Analytics> get copyWith =>
      CopyWith$Variables$Query$Analytics(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$Analytics ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    final l$input = input;
    final lOther$input = other.input;
    if (l$input != lOther$input) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    final l$input = input;
    return Object.hashAll([l$siteId, l$input]);
  }
}

abstract class CopyWith$Variables$Query$Analytics<TRes> {
  factory CopyWith$Variables$Query$Analytics(
    Variables$Query$Analytics instance,
    TRes Function(Variables$Query$Analytics) then,
  ) = _CopyWithImpl$Variables$Query$Analytics;

  factory CopyWith$Variables$Query$Analytics.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$Analytics;

  TRes call({String? siteId, dynamic? input});
}

class _CopyWithImpl$Variables$Query$Analytics<TRes>
    implements CopyWith$Variables$Query$Analytics<TRes> {
  _CopyWithImpl$Variables$Query$Analytics(this._instance, this._then);

  final Variables$Query$Analytics _instance;

  final TRes Function(Variables$Query$Analytics) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? siteId = _undefined, Object? input = _undefined}) => _then(
    Variables$Query$Analytics._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
      if (input != _undefined && input != null) 'input': (input as dynamic),
    }),
  );
}

class _CopyWithStubImpl$Variables$Query$Analytics<TRes>
    implements CopyWith$Variables$Query$Analytics<TRes> {
  _CopyWithStubImpl$Variables$Query$Analytics(this._res);

  TRes _res;

  call({String? siteId, dynamic? input}) => _res;
}

class Query$Analytics {
  Query$Analytics({required this.analytics, this.$__typename = 'Query'});

  factory Query$Analytics.fromJson(Map<String, dynamic> json) {
    final l$analytics = json['analytics'];
    final l$$__typename = json['__typename'];
    return Query$Analytics(
      analytics: (l$analytics as dynamic),
      $__typename: (l$$__typename as String),
    );
  }

  final dynamic analytics;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$analytics = analytics;
    _resultData['analytics'] = l$analytics;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$analytics = analytics;
    final l$$__typename = $__typename;
    return Object.hashAll([l$analytics, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$Analytics || runtimeType != other.runtimeType) {
      return false;
    }
    final l$analytics = analytics;
    final lOther$analytics = other.analytics;
    if (l$analytics != lOther$analytics) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$Analytics on Query$Analytics {
  CopyWith$Query$Analytics<Query$Analytics> get copyWith =>
      CopyWith$Query$Analytics(this, (i) => i);
}

abstract class CopyWith$Query$Analytics<TRes> {
  factory CopyWith$Query$Analytics(
    Query$Analytics instance,
    TRes Function(Query$Analytics) then,
  ) = _CopyWithImpl$Query$Analytics;

  factory CopyWith$Query$Analytics.stub(TRes res) =
      _CopyWithStubImpl$Query$Analytics;

  TRes call({dynamic? analytics, String? $__typename});
}

class _CopyWithImpl$Query$Analytics<TRes>
    implements CopyWith$Query$Analytics<TRes> {
  _CopyWithImpl$Query$Analytics(this._instance, this._then);

  final Query$Analytics _instance;

  final TRes Function(Query$Analytics) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? analytics = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$Analytics(
      analytics: analytics == _undefined || analytics == null
          ? _instance.analytics
          : (analytics as dynamic),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$Analytics<TRes>
    implements CopyWith$Query$Analytics<TRes> {
  _CopyWithStubImpl$Query$Analytics(this._res);

  TRes _res;

  call({dynamic? analytics, String? $__typename}) => _res;
}

const documentNodeQueryAnalytics = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'Analytics'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'input')),
          type: NamedTypeNode(name: NameNode(value: 'JSON'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'analytics'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'input'),
                value: VariableNode(name: NameNode(value: 'input')),
              ),
            ],
            directives: [],
            selectionSet: null,
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Query$Analytics _parserFn$Query$Analytics(Map<String, dynamic> data) =>
    Query$Analytics.fromJson(data);
typedef OnQueryComplete$Query$Analytics = FutureOr<void> Function(
  Map<String, dynamic>?,
  Query$Analytics?,
);

class Options$Query$Analytics extends graphql.QueryOptions<Query$Analytics> {
  Options$Query$Analytics({
    String? operationName,
    required Variables$Query$Analytics variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$Analytics? typedOptimisticResult,
    Duration? pollInterval,
    graphql.Context? context,
    OnQueryComplete$Query$Analytics? onComplete,
    graphql.OnQueryError? onError,
  }) : onCompleteWithParsed = onComplete,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         pollInterval: pollInterval,
         context: context,
         onComplete: onComplete == null
             ? null
             : (data) => onComplete(
                 data,
                 data == null ? null : _parserFn$Query$Analytics(data),
               ),
         onError: onError,
         document: documentNodeQueryAnalytics,
         parserFn: _parserFn$Query$Analytics,
       );

  final OnQueryComplete$Query$Analytics? onCompleteWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onComplete == null
        ? super.properties
        : super.properties.where((property) => property != onComplete),
    onCompleteWithParsed,
  ];
}

class WatchOptions$Query$Analytics
    extends graphql.WatchQueryOptions<Query$Analytics> {
  WatchOptions$Query$Analytics({
    String? operationName,
    required Variables$Query$Analytics variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$Analytics? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeQueryAnalytics,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Query$Analytics,
       );
}

class FetchMoreOptions$Query$Analytics extends graphql.FetchMoreOptions {
  FetchMoreOptions$Query$Analytics({
    required graphql.UpdateQuery updateQuery,
    required Variables$Query$Analytics variables,
  }) : super(
         updateQuery: updateQuery,
         variables: variables.toJson(),
         document: documentNodeQueryAnalytics,
       );
}

extension ClientExtension$Query$Analytics on graphql.GraphQLClient {
  Future<graphql.QueryResult<Query$Analytics>> query$Analytics(
    Options$Query$Analytics options,
  ) async => await this.query(options);

  graphql.ObservableQuery<Query$Analytics> watchQuery$Analytics(
    WatchOptions$Query$Analytics options,
  ) => this.watchQuery(options);

  void writeQuery$Analytics({
    required Query$Analytics data,
    required Variables$Query$Analytics variables,
    bool broadcast = true,
  }) => this.writeQuery(
    graphql.Request(
      operation: graphql.Operation(document: documentNodeQueryAnalytics),
      variables: variables.toJson(),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Query$Analytics? readQuery$Analytics({
    required Variables$Query$Analytics variables,
    bool optimistic = true,
  }) {
    final result = this.readQuery(
      graphql.Request(
        operation: graphql.Operation(document: documentNodeQueryAnalytics),
        variables: variables.toJson(),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Query$Analytics.fromJson(result);
  }
}

class Variables$Mutation$ExplainAnalytics {
  factory Variables$Mutation$ExplainAnalytics({
    required String siteId,
    required dynamic input,
  }) => Variables$Mutation$ExplainAnalytics._({
    r'siteId': siteId,
    r'input': input,
  });

  Variables$Mutation$ExplainAnalytics._(this._$data);

  factory Variables$Mutation$ExplainAnalytics.fromJson(
    Map<String, dynamic> data,
  ) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    final l$input = data['input'];
    result$data['input'] = (l$input as dynamic);
    return Variables$Mutation$ExplainAnalytics._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  dynamic get input => (_$data['input'] as dynamic);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    final l$input = input;
    result$data['input'] = l$input;
    return result$data;
  }

  CopyWith$Variables$Mutation$ExplainAnalytics<
    Variables$Mutation$ExplainAnalytics
  >
  get copyWith => CopyWith$Variables$Mutation$ExplainAnalytics(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Mutation$ExplainAnalytics ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    final l$input = input;
    final lOther$input = other.input;
    if (l$input != lOther$input) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    final l$input = input;
    return Object.hashAll([l$siteId, l$input]);
  }
}

abstract class CopyWith$Variables$Mutation$ExplainAnalytics<TRes> {
  factory CopyWith$Variables$Mutation$ExplainAnalytics(
    Variables$Mutation$ExplainAnalytics instance,
    TRes Function(Variables$Mutation$ExplainAnalytics) then,
  ) = _CopyWithImpl$Variables$Mutation$ExplainAnalytics;

  factory CopyWith$Variables$Mutation$ExplainAnalytics.stub(TRes res) =
      _CopyWithStubImpl$Variables$Mutation$ExplainAnalytics;

  TRes call({String? siteId, dynamic? input});
}

class _CopyWithImpl$Variables$Mutation$ExplainAnalytics<TRes>
    implements CopyWith$Variables$Mutation$ExplainAnalytics<TRes> {
  _CopyWithImpl$Variables$Mutation$ExplainAnalytics(this._instance, this._then);

  final Variables$Mutation$ExplainAnalytics _instance;

  final TRes Function(Variables$Mutation$ExplainAnalytics) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? siteId = _undefined, Object? input = _undefined}) => _then(
    Variables$Mutation$ExplainAnalytics._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
      if (input != _undefined && input != null) 'input': (input as dynamic),
    }),
  );
}

class _CopyWithStubImpl$Variables$Mutation$ExplainAnalytics<TRes>
    implements CopyWith$Variables$Mutation$ExplainAnalytics<TRes> {
  _CopyWithStubImpl$Variables$Mutation$ExplainAnalytics(this._res);

  TRes _res;

  call({String? siteId, dynamic? input}) => _res;
}

class Mutation$ExplainAnalytics {
  Mutation$ExplainAnalytics({
    required this.explainAnalytics,
    this.$__typename = 'Mutation',
  });

  factory Mutation$ExplainAnalytics.fromJson(Map<String, dynamic> json) {
    final l$explainAnalytics = json['explainAnalytics'];
    final l$$__typename = json['__typename'];
    return Mutation$ExplainAnalytics(
      explainAnalytics: (l$explainAnalytics as dynamic),
      $__typename: (l$$__typename as String),
    );
  }

  final dynamic explainAnalytics;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$explainAnalytics = explainAnalytics;
    _resultData['explainAnalytics'] = l$explainAnalytics;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$explainAnalytics = explainAnalytics;
    final l$$__typename = $__typename;
    return Object.hashAll([l$explainAnalytics, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Mutation$ExplainAnalytics ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$explainAnalytics = explainAnalytics;
    final lOther$explainAnalytics = other.explainAnalytics;
    if (l$explainAnalytics != lOther$explainAnalytics) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Mutation$ExplainAnalytics
    on Mutation$ExplainAnalytics {
  CopyWith$Mutation$ExplainAnalytics<Mutation$ExplainAnalytics> get copyWith =>
      CopyWith$Mutation$ExplainAnalytics(this, (i) => i);
}

abstract class CopyWith$Mutation$ExplainAnalytics<TRes> {
  factory CopyWith$Mutation$ExplainAnalytics(
    Mutation$ExplainAnalytics instance,
    TRes Function(Mutation$ExplainAnalytics) then,
  ) = _CopyWithImpl$Mutation$ExplainAnalytics;

  factory CopyWith$Mutation$ExplainAnalytics.stub(TRes res) =
      _CopyWithStubImpl$Mutation$ExplainAnalytics;

  TRes call({dynamic? explainAnalytics, String? $__typename});
}

class _CopyWithImpl$Mutation$ExplainAnalytics<TRes>
    implements CopyWith$Mutation$ExplainAnalytics<TRes> {
  _CopyWithImpl$Mutation$ExplainAnalytics(this._instance, this._then);

  final Mutation$ExplainAnalytics _instance;

  final TRes Function(Mutation$ExplainAnalytics) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? explainAnalytics = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Mutation$ExplainAnalytics(
      explainAnalytics:
          explainAnalytics == _undefined || explainAnalytics == null
          ? _instance.explainAnalytics
          : (explainAnalytics as dynamic),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Mutation$ExplainAnalytics<TRes>
    implements CopyWith$Mutation$ExplainAnalytics<TRes> {
  _CopyWithStubImpl$Mutation$ExplainAnalytics(this._res);

  TRes _res;

  call({dynamic? explainAnalytics, String? $__typename}) => _res;
}

const documentNodeMutationExplainAnalytics = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.mutation,
      name: NameNode(value: 'ExplainAnalytics'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'input')),
          type: NamedTypeNode(name: NameNode(value: 'JSON'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'explainAnalytics'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'input'),
                value: VariableNode(name: NameNode(value: 'input')),
              ),
            ],
            directives: [],
            selectionSet: null,
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Mutation$ExplainAnalytics _parserFn$Mutation$ExplainAnalytics(
  Map<String, dynamic> data,
) => Mutation$ExplainAnalytics.fromJson(data);
typedef OnMutationCompleted$Mutation$ExplainAnalytics = FutureOr<void> Function(
  Map<String, dynamic>?,
  Mutation$ExplainAnalytics?,
);

class Options$Mutation$ExplainAnalytics
    extends graphql.MutationOptions<Mutation$ExplainAnalytics> {
  Options$Mutation$ExplainAnalytics({
    String? operationName,
    required Variables$Mutation$ExplainAnalytics variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Mutation$ExplainAnalytics? typedOptimisticResult,
    graphql.Context? context,
    OnMutationCompleted$Mutation$ExplainAnalytics? onCompleted,
    graphql.OnMutationUpdate<Mutation$ExplainAnalytics>? update,
    graphql.OnError? onError,
  }) : onCompletedWithParsed = onCompleted,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         onCompleted: onCompleted == null
             ? null
             : (data) => onCompleted(
                 data,
                 data == null
                     ? null
                     : _parserFn$Mutation$ExplainAnalytics(data),
               ),
         update: update,
         onError: onError,
         document: documentNodeMutationExplainAnalytics,
         parserFn: _parserFn$Mutation$ExplainAnalytics,
       );

  final OnMutationCompleted$Mutation$ExplainAnalytics? onCompletedWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onCompleted == null
        ? super.properties
        : super.properties.where((property) => property != onCompleted),
    onCompletedWithParsed,
  ];
}

class WatchOptions$Mutation$ExplainAnalytics
    extends graphql.WatchQueryOptions<Mutation$ExplainAnalytics> {
  WatchOptions$Mutation$ExplainAnalytics({
    String? operationName,
    required Variables$Mutation$ExplainAnalytics variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Mutation$ExplainAnalytics? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeMutationExplainAnalytics,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Mutation$ExplainAnalytics,
       );
}

extension ClientExtension$Mutation$ExplainAnalytics on graphql.GraphQLClient {
  Future<graphql.QueryResult<Mutation$ExplainAnalytics>>
  mutate$ExplainAnalytics(Options$Mutation$ExplainAnalytics options) async =>
      await this.mutate(options);

  graphql.ObservableQuery<Mutation$ExplainAnalytics>
  watchMutation$ExplainAnalytics(
    WatchOptions$Mutation$ExplainAnalytics options,
  ) => this.watchMutation(options);
}

class Variables$Query$TrackingContext {
  factory Variables$Query$TrackingContext({required String siteId}) =>
      Variables$Query$TrackingContext._({r'siteId': siteId});

  Variables$Query$TrackingContext._(this._$data);

  factory Variables$Query$TrackingContext.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    return Variables$Query$TrackingContext._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    return result$data;
  }

  CopyWith$Variables$Query$TrackingContext<Variables$Query$TrackingContext>
  get copyWith => CopyWith$Variables$Query$TrackingContext(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$TrackingContext ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    return Object.hashAll([l$siteId]);
  }
}

abstract class CopyWith$Variables$Query$TrackingContext<TRes> {
  factory CopyWith$Variables$Query$TrackingContext(
    Variables$Query$TrackingContext instance,
    TRes Function(Variables$Query$TrackingContext) then,
  ) = _CopyWithImpl$Variables$Query$TrackingContext;

  factory CopyWith$Variables$Query$TrackingContext.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$TrackingContext;

  TRes call({String? siteId});
}

class _CopyWithImpl$Variables$Query$TrackingContext<TRes>
    implements CopyWith$Variables$Query$TrackingContext<TRes> {
  _CopyWithImpl$Variables$Query$TrackingContext(this._instance, this._then);

  final Variables$Query$TrackingContext _instance;

  final TRes Function(Variables$Query$TrackingContext) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? siteId = _undefined}) => _then(
    Variables$Query$TrackingContext._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
    }),
  );
}

class _CopyWithStubImpl$Variables$Query$TrackingContext<TRes>
    implements CopyWith$Variables$Query$TrackingContext<TRes> {
  _CopyWithStubImpl$Variables$Query$TrackingContext(this._res);

  TRes _res;

  call({String? siteId}) => _res;
}

class Query$TrackingContext {
  Query$TrackingContext({
    required this.trackingContext,
    this.$__typename = 'Query',
  });

  factory Query$TrackingContext.fromJson(Map<String, dynamic> json) {
    final l$trackingContext = json['trackingContext'];
    final l$$__typename = json['__typename'];
    return Query$TrackingContext(
      trackingContext: (l$trackingContext as dynamic),
      $__typename: (l$$__typename as String),
    );
  }

  final dynamic trackingContext;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$trackingContext = trackingContext;
    _resultData['trackingContext'] = l$trackingContext;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$trackingContext = trackingContext;
    final l$$__typename = $__typename;
    return Object.hashAll([l$trackingContext, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$TrackingContext || runtimeType != other.runtimeType) {
      return false;
    }
    final l$trackingContext = trackingContext;
    final lOther$trackingContext = other.trackingContext;
    if (l$trackingContext != lOther$trackingContext) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$TrackingContext on Query$TrackingContext {
  CopyWith$Query$TrackingContext<Query$TrackingContext> get copyWith =>
      CopyWith$Query$TrackingContext(this, (i) => i);
}

abstract class CopyWith$Query$TrackingContext<TRes> {
  factory CopyWith$Query$TrackingContext(
    Query$TrackingContext instance,
    TRes Function(Query$TrackingContext) then,
  ) = _CopyWithImpl$Query$TrackingContext;

  factory CopyWith$Query$TrackingContext.stub(TRes res) =
      _CopyWithStubImpl$Query$TrackingContext;

  TRes call({dynamic? trackingContext, String? $__typename});
}

class _CopyWithImpl$Query$TrackingContext<TRes>
    implements CopyWith$Query$TrackingContext<TRes> {
  _CopyWithImpl$Query$TrackingContext(this._instance, this._then);

  final Query$TrackingContext _instance;

  final TRes Function(Query$TrackingContext) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? trackingContext = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$TrackingContext(
      trackingContext: trackingContext == _undefined || trackingContext == null
          ? _instance.trackingContext
          : (trackingContext as dynamic),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$TrackingContext<TRes>
    implements CopyWith$Query$TrackingContext<TRes> {
  _CopyWithStubImpl$Query$TrackingContext(this._res);

  TRes _res;

  call({dynamic? trackingContext, String? $__typename}) => _res;
}

const documentNodeQueryTrackingContext = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'TrackingContext'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'trackingContext'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
            ],
            directives: [],
            selectionSet: null,
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Query$TrackingContext _parserFn$Query$TrackingContext(
  Map<String, dynamic> data,
) => Query$TrackingContext.fromJson(data);
typedef OnQueryComplete$Query$TrackingContext = FutureOr<void> Function(
  Map<String, dynamic>?,
  Query$TrackingContext?,
);

class Options$Query$TrackingContext
    extends graphql.QueryOptions<Query$TrackingContext> {
  Options$Query$TrackingContext({
    String? operationName,
    required Variables$Query$TrackingContext variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$TrackingContext? typedOptimisticResult,
    Duration? pollInterval,
    graphql.Context? context,
    OnQueryComplete$Query$TrackingContext? onComplete,
    graphql.OnQueryError? onError,
  }) : onCompleteWithParsed = onComplete,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         pollInterval: pollInterval,
         context: context,
         onComplete: onComplete == null
             ? null
             : (data) => onComplete(
                 data,
                 data == null ? null : _parserFn$Query$TrackingContext(data),
               ),
         onError: onError,
         document: documentNodeQueryTrackingContext,
         parserFn: _parserFn$Query$TrackingContext,
       );

  final OnQueryComplete$Query$TrackingContext? onCompleteWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onComplete == null
        ? super.properties
        : super.properties.where((property) => property != onComplete),
    onCompleteWithParsed,
  ];
}

class WatchOptions$Query$TrackingContext
    extends graphql.WatchQueryOptions<Query$TrackingContext> {
  WatchOptions$Query$TrackingContext({
    String? operationName,
    required Variables$Query$TrackingContext variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$TrackingContext? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeQueryTrackingContext,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Query$TrackingContext,
       );
}

class FetchMoreOptions$Query$TrackingContext extends graphql.FetchMoreOptions {
  FetchMoreOptions$Query$TrackingContext({
    required graphql.UpdateQuery updateQuery,
    required Variables$Query$TrackingContext variables,
  }) : super(
         updateQuery: updateQuery,
         variables: variables.toJson(),
         document: documentNodeQueryTrackingContext,
       );
}

extension ClientExtension$Query$TrackingContext on graphql.GraphQLClient {
  Future<graphql.QueryResult<Query$TrackingContext>> query$TrackingContext(
    Options$Query$TrackingContext options,
  ) async => await this.query(options);

  graphql.ObservableQuery<Query$TrackingContext> watchQuery$TrackingContext(
    WatchOptions$Query$TrackingContext options,
  ) => this.watchQuery(options);

  void writeQuery$TrackingContext({
    required Query$TrackingContext data,
    required Variables$Query$TrackingContext variables,
    bool broadcast = true,
  }) => this.writeQuery(
    graphql.Request(
      operation: graphql.Operation(document: documentNodeQueryTrackingContext),
      variables: variables.toJson(),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Query$TrackingContext? readQuery$TrackingContext({
    required Variables$Query$TrackingContext variables,
    bool optimistic = true,
  }) {
    final result = this.readQuery(
      graphql.Request(
        operation: graphql.Operation(
          document: documentNodeQueryTrackingContext,
        ),
        variables: variables.toJson(),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Query$TrackingContext.fromJson(result);
  }
}

class Variables$Query$TrackingMonitor {
  factory Variables$Query$TrackingMonitor({
    required String siteId,
    required dynamic input,
  }) => Variables$Query$TrackingMonitor._({r'siteId': siteId, r'input': input});

  Variables$Query$TrackingMonitor._(this._$data);

  factory Variables$Query$TrackingMonitor.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    final l$input = data['input'];
    result$data['input'] = (l$input as dynamic);
    return Variables$Query$TrackingMonitor._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  dynamic get input => (_$data['input'] as dynamic);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    final l$input = input;
    result$data['input'] = l$input;
    return result$data;
  }

  CopyWith$Variables$Query$TrackingMonitor<Variables$Query$TrackingMonitor>
  get copyWith => CopyWith$Variables$Query$TrackingMonitor(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$TrackingMonitor ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    final l$input = input;
    final lOther$input = other.input;
    if (l$input != lOther$input) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    final l$input = input;
    return Object.hashAll([l$siteId, l$input]);
  }
}

abstract class CopyWith$Variables$Query$TrackingMonitor<TRes> {
  factory CopyWith$Variables$Query$TrackingMonitor(
    Variables$Query$TrackingMonitor instance,
    TRes Function(Variables$Query$TrackingMonitor) then,
  ) = _CopyWithImpl$Variables$Query$TrackingMonitor;

  factory CopyWith$Variables$Query$TrackingMonitor.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$TrackingMonitor;

  TRes call({String? siteId, dynamic? input});
}

class _CopyWithImpl$Variables$Query$TrackingMonitor<TRes>
    implements CopyWith$Variables$Query$TrackingMonitor<TRes> {
  _CopyWithImpl$Variables$Query$TrackingMonitor(this._instance, this._then);

  final Variables$Query$TrackingMonitor _instance;

  final TRes Function(Variables$Query$TrackingMonitor) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? siteId = _undefined, Object? input = _undefined}) => _then(
    Variables$Query$TrackingMonitor._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
      if (input != _undefined && input != null) 'input': (input as dynamic),
    }),
  );
}

class _CopyWithStubImpl$Variables$Query$TrackingMonitor<TRes>
    implements CopyWith$Variables$Query$TrackingMonitor<TRes> {
  _CopyWithStubImpl$Variables$Query$TrackingMonitor(this._res);

  TRes _res;

  call({String? siteId, dynamic? input}) => _res;
}

class Query$TrackingMonitor {
  Query$TrackingMonitor({
    required this.trackingMonitor,
    this.$__typename = 'Query',
  });

  factory Query$TrackingMonitor.fromJson(Map<String, dynamic> json) {
    final l$trackingMonitor = json['trackingMonitor'];
    final l$$__typename = json['__typename'];
    return Query$TrackingMonitor(
      trackingMonitor: (l$trackingMonitor as dynamic),
      $__typename: (l$$__typename as String),
    );
  }

  final dynamic trackingMonitor;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$trackingMonitor = trackingMonitor;
    _resultData['trackingMonitor'] = l$trackingMonitor;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$trackingMonitor = trackingMonitor;
    final l$$__typename = $__typename;
    return Object.hashAll([l$trackingMonitor, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$TrackingMonitor || runtimeType != other.runtimeType) {
      return false;
    }
    final l$trackingMonitor = trackingMonitor;
    final lOther$trackingMonitor = other.trackingMonitor;
    if (l$trackingMonitor != lOther$trackingMonitor) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$TrackingMonitor on Query$TrackingMonitor {
  CopyWith$Query$TrackingMonitor<Query$TrackingMonitor> get copyWith =>
      CopyWith$Query$TrackingMonitor(this, (i) => i);
}

abstract class CopyWith$Query$TrackingMonitor<TRes> {
  factory CopyWith$Query$TrackingMonitor(
    Query$TrackingMonitor instance,
    TRes Function(Query$TrackingMonitor) then,
  ) = _CopyWithImpl$Query$TrackingMonitor;

  factory CopyWith$Query$TrackingMonitor.stub(TRes res) =
      _CopyWithStubImpl$Query$TrackingMonitor;

  TRes call({dynamic? trackingMonitor, String? $__typename});
}

class _CopyWithImpl$Query$TrackingMonitor<TRes>
    implements CopyWith$Query$TrackingMonitor<TRes> {
  _CopyWithImpl$Query$TrackingMonitor(this._instance, this._then);

  final Query$TrackingMonitor _instance;

  final TRes Function(Query$TrackingMonitor) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? trackingMonitor = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$TrackingMonitor(
      trackingMonitor: trackingMonitor == _undefined || trackingMonitor == null
          ? _instance.trackingMonitor
          : (trackingMonitor as dynamic),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$TrackingMonitor<TRes>
    implements CopyWith$Query$TrackingMonitor<TRes> {
  _CopyWithStubImpl$Query$TrackingMonitor(this._res);

  TRes _res;

  call({dynamic? trackingMonitor, String? $__typename}) => _res;
}

const documentNodeQueryTrackingMonitor = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'TrackingMonitor'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'input')),
          type: NamedTypeNode(name: NameNode(value: 'JSON'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'trackingMonitor'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'input'),
                value: VariableNode(name: NameNode(value: 'input')),
              ),
            ],
            directives: [],
            selectionSet: null,
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Query$TrackingMonitor _parserFn$Query$TrackingMonitor(
  Map<String, dynamic> data,
) => Query$TrackingMonitor.fromJson(data);
typedef OnQueryComplete$Query$TrackingMonitor = FutureOr<void> Function(
  Map<String, dynamic>?,
  Query$TrackingMonitor?,
);

class Options$Query$TrackingMonitor
    extends graphql.QueryOptions<Query$TrackingMonitor> {
  Options$Query$TrackingMonitor({
    String? operationName,
    required Variables$Query$TrackingMonitor variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$TrackingMonitor? typedOptimisticResult,
    Duration? pollInterval,
    graphql.Context? context,
    OnQueryComplete$Query$TrackingMonitor? onComplete,
    graphql.OnQueryError? onError,
  }) : onCompleteWithParsed = onComplete,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         pollInterval: pollInterval,
         context: context,
         onComplete: onComplete == null
             ? null
             : (data) => onComplete(
                 data,
                 data == null ? null : _parserFn$Query$TrackingMonitor(data),
               ),
         onError: onError,
         document: documentNodeQueryTrackingMonitor,
         parserFn: _parserFn$Query$TrackingMonitor,
       );

  final OnQueryComplete$Query$TrackingMonitor? onCompleteWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onComplete == null
        ? super.properties
        : super.properties.where((property) => property != onComplete),
    onCompleteWithParsed,
  ];
}

class WatchOptions$Query$TrackingMonitor
    extends graphql.WatchQueryOptions<Query$TrackingMonitor> {
  WatchOptions$Query$TrackingMonitor({
    String? operationName,
    required Variables$Query$TrackingMonitor variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$TrackingMonitor? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeQueryTrackingMonitor,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Query$TrackingMonitor,
       );
}

class FetchMoreOptions$Query$TrackingMonitor extends graphql.FetchMoreOptions {
  FetchMoreOptions$Query$TrackingMonitor({
    required graphql.UpdateQuery updateQuery,
    required Variables$Query$TrackingMonitor variables,
  }) : super(
         updateQuery: updateQuery,
         variables: variables.toJson(),
         document: documentNodeQueryTrackingMonitor,
       );
}

extension ClientExtension$Query$TrackingMonitor on graphql.GraphQLClient {
  Future<graphql.QueryResult<Query$TrackingMonitor>> query$TrackingMonitor(
    Options$Query$TrackingMonitor options,
  ) async => await this.query(options);

  graphql.ObservableQuery<Query$TrackingMonitor> watchQuery$TrackingMonitor(
    WatchOptions$Query$TrackingMonitor options,
  ) => this.watchQuery(options);

  void writeQuery$TrackingMonitor({
    required Query$TrackingMonitor data,
    required Variables$Query$TrackingMonitor variables,
    bool broadcast = true,
  }) => this.writeQuery(
    graphql.Request(
      operation: graphql.Operation(document: documentNodeQueryTrackingMonitor),
      variables: variables.toJson(),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Query$TrackingMonitor? readQuery$TrackingMonitor({
    required Variables$Query$TrackingMonitor variables,
    bool optimistic = true,
  }) {
    final result = this.readQuery(
      graphql.Request(
        operation: graphql.Operation(
          document: documentNodeQueryTrackingMonitor,
        ),
        variables: variables.toJson(),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Query$TrackingMonitor.fromJson(result);
  }
}

class Variables$Query$RoleMatrix {
  factory Variables$Query$RoleMatrix({required String siteId}) =>
      Variables$Query$RoleMatrix._({r'siteId': siteId});

  Variables$Query$RoleMatrix._(this._$data);

  factory Variables$Query$RoleMatrix.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    return Variables$Query$RoleMatrix._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    return result$data;
  }

  CopyWith$Variables$Query$RoleMatrix<Variables$Query$RoleMatrix>
  get copyWith => CopyWith$Variables$Query$RoleMatrix(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$RoleMatrix ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    return Object.hashAll([l$siteId]);
  }
}

abstract class CopyWith$Variables$Query$RoleMatrix<TRes> {
  factory CopyWith$Variables$Query$RoleMatrix(
    Variables$Query$RoleMatrix instance,
    TRes Function(Variables$Query$RoleMatrix) then,
  ) = _CopyWithImpl$Variables$Query$RoleMatrix;

  factory CopyWith$Variables$Query$RoleMatrix.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$RoleMatrix;

  TRes call({String? siteId});
}

class _CopyWithImpl$Variables$Query$RoleMatrix<TRes>
    implements CopyWith$Variables$Query$RoleMatrix<TRes> {
  _CopyWithImpl$Variables$Query$RoleMatrix(this._instance, this._then);

  final Variables$Query$RoleMatrix _instance;

  final TRes Function(Variables$Query$RoleMatrix) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? siteId = _undefined}) => _then(
    Variables$Query$RoleMatrix._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
    }),
  );
}

class _CopyWithStubImpl$Variables$Query$RoleMatrix<TRes>
    implements CopyWith$Variables$Query$RoleMatrix<TRes> {
  _CopyWithStubImpl$Variables$Query$RoleMatrix(this._res);

  TRes _res;

  call({String? siteId}) => _res;
}

class Query$RoleMatrix {
  Query$RoleMatrix({required this.roleMatrix, this.$__typename = 'Query'});

  factory Query$RoleMatrix.fromJson(Map<String, dynamic> json) {
    final l$roleMatrix = json['roleMatrix'];
    final l$$__typename = json['__typename'];
    return Query$RoleMatrix(
      roleMatrix: (l$roleMatrix as dynamic),
      $__typename: (l$$__typename as String),
    );
  }

  final dynamic roleMatrix;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$roleMatrix = roleMatrix;
    _resultData['roleMatrix'] = l$roleMatrix;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$roleMatrix = roleMatrix;
    final l$$__typename = $__typename;
    return Object.hashAll([l$roleMatrix, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$RoleMatrix || runtimeType != other.runtimeType) {
      return false;
    }
    final l$roleMatrix = roleMatrix;
    final lOther$roleMatrix = other.roleMatrix;
    if (l$roleMatrix != lOther$roleMatrix) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$RoleMatrix on Query$RoleMatrix {
  CopyWith$Query$RoleMatrix<Query$RoleMatrix> get copyWith =>
      CopyWith$Query$RoleMatrix(this, (i) => i);
}

abstract class CopyWith$Query$RoleMatrix<TRes> {
  factory CopyWith$Query$RoleMatrix(
    Query$RoleMatrix instance,
    TRes Function(Query$RoleMatrix) then,
  ) = _CopyWithImpl$Query$RoleMatrix;

  factory CopyWith$Query$RoleMatrix.stub(TRes res) =
      _CopyWithStubImpl$Query$RoleMatrix;

  TRes call({dynamic? roleMatrix, String? $__typename});
}

class _CopyWithImpl$Query$RoleMatrix<TRes>
    implements CopyWith$Query$RoleMatrix<TRes> {
  _CopyWithImpl$Query$RoleMatrix(this._instance, this._then);

  final Query$RoleMatrix _instance;

  final TRes Function(Query$RoleMatrix) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? roleMatrix = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$RoleMatrix(
      roleMatrix: roleMatrix == _undefined || roleMatrix == null
          ? _instance.roleMatrix
          : (roleMatrix as dynamic),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$RoleMatrix<TRes>
    implements CopyWith$Query$RoleMatrix<TRes> {
  _CopyWithStubImpl$Query$RoleMatrix(this._res);

  TRes _res;

  call({dynamic? roleMatrix, String? $__typename}) => _res;
}

const documentNodeQueryRoleMatrix = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'RoleMatrix'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'roleMatrix'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
            ],
            directives: [],
            selectionSet: null,
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Query$RoleMatrix _parserFn$Query$RoleMatrix(Map<String, dynamic> data) =>
    Query$RoleMatrix.fromJson(data);
typedef OnQueryComplete$Query$RoleMatrix = FutureOr<void> Function(
  Map<String, dynamic>?,
  Query$RoleMatrix?,
);

class Options$Query$RoleMatrix extends graphql.QueryOptions<Query$RoleMatrix> {
  Options$Query$RoleMatrix({
    String? operationName,
    required Variables$Query$RoleMatrix variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$RoleMatrix? typedOptimisticResult,
    Duration? pollInterval,
    graphql.Context? context,
    OnQueryComplete$Query$RoleMatrix? onComplete,
    graphql.OnQueryError? onError,
  }) : onCompleteWithParsed = onComplete,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         pollInterval: pollInterval,
         context: context,
         onComplete: onComplete == null
             ? null
             : (data) => onComplete(
                 data,
                 data == null ? null : _parserFn$Query$RoleMatrix(data),
               ),
         onError: onError,
         document: documentNodeQueryRoleMatrix,
         parserFn: _parserFn$Query$RoleMatrix,
       );

  final OnQueryComplete$Query$RoleMatrix? onCompleteWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onComplete == null
        ? super.properties
        : super.properties.where((property) => property != onComplete),
    onCompleteWithParsed,
  ];
}

class WatchOptions$Query$RoleMatrix
    extends graphql.WatchQueryOptions<Query$RoleMatrix> {
  WatchOptions$Query$RoleMatrix({
    String? operationName,
    required Variables$Query$RoleMatrix variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$RoleMatrix? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeQueryRoleMatrix,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Query$RoleMatrix,
       );
}

class FetchMoreOptions$Query$RoleMatrix extends graphql.FetchMoreOptions {
  FetchMoreOptions$Query$RoleMatrix({
    required graphql.UpdateQuery updateQuery,
    required Variables$Query$RoleMatrix variables,
  }) : super(
         updateQuery: updateQuery,
         variables: variables.toJson(),
         document: documentNodeQueryRoleMatrix,
       );
}

extension ClientExtension$Query$RoleMatrix on graphql.GraphQLClient {
  Future<graphql.QueryResult<Query$RoleMatrix>> query$RoleMatrix(
    Options$Query$RoleMatrix options,
  ) async => await this.query(options);

  graphql.ObservableQuery<Query$RoleMatrix> watchQuery$RoleMatrix(
    WatchOptions$Query$RoleMatrix options,
  ) => this.watchQuery(options);

  void writeQuery$RoleMatrix({
    required Query$RoleMatrix data,
    required Variables$Query$RoleMatrix variables,
    bool broadcast = true,
  }) => this.writeQuery(
    graphql.Request(
      operation: graphql.Operation(document: documentNodeQueryRoleMatrix),
      variables: variables.toJson(),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Query$RoleMatrix? readQuery$RoleMatrix({
    required Variables$Query$RoleMatrix variables,
    bool optimistic = true,
  }) {
    final result = this.readQuery(
      graphql.Request(
        operation: graphql.Operation(document: documentNodeQueryRoleMatrix),
        variables: variables.toJson(),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Query$RoleMatrix.fromJson(result);
  }
}

class Variables$Mutation$TrackingCommand {
  factory Variables$Mutation$TrackingCommand({
    required String siteId,
    required String operation,
    required dynamic input,
  }) => Variables$Mutation$TrackingCommand._({
    r'siteId': siteId,
    r'operation': operation,
    r'input': input,
  });

  Variables$Mutation$TrackingCommand._(this._$data);

  factory Variables$Mutation$TrackingCommand.fromJson(
    Map<String, dynamic> data,
  ) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    final l$operation = data['operation'];
    result$data['operation'] = (l$operation as String);
    final l$input = data['input'];
    result$data['input'] = (l$input as dynamic);
    return Variables$Mutation$TrackingCommand._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  String get operation => (_$data['operation'] as String);

  dynamic get input => (_$data['input'] as dynamic);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    final l$operation = operation;
    result$data['operation'] = l$operation;
    final l$input = input;
    result$data['input'] = l$input;
    return result$data;
  }

  CopyWith$Variables$Mutation$TrackingCommand<
    Variables$Mutation$TrackingCommand
  >
  get copyWith => CopyWith$Variables$Mutation$TrackingCommand(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Mutation$TrackingCommand ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    final l$operation = operation;
    final lOther$operation = other.operation;
    if (l$operation != lOther$operation) {
      return false;
    }
    final l$input = input;
    final lOther$input = other.input;
    if (l$input != lOther$input) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    final l$operation = operation;
    final l$input = input;
    return Object.hashAll([l$siteId, l$operation, l$input]);
  }
}

abstract class CopyWith$Variables$Mutation$TrackingCommand<TRes> {
  factory CopyWith$Variables$Mutation$TrackingCommand(
    Variables$Mutation$TrackingCommand instance,
    TRes Function(Variables$Mutation$TrackingCommand) then,
  ) = _CopyWithImpl$Variables$Mutation$TrackingCommand;

  factory CopyWith$Variables$Mutation$TrackingCommand.stub(TRes res) =
      _CopyWithStubImpl$Variables$Mutation$TrackingCommand;

  TRes call({String? siteId, String? operation, dynamic? input});
}

class _CopyWithImpl$Variables$Mutation$TrackingCommand<TRes>
    implements CopyWith$Variables$Mutation$TrackingCommand<TRes> {
  _CopyWithImpl$Variables$Mutation$TrackingCommand(this._instance, this._then);

  final Variables$Mutation$TrackingCommand _instance;

  final TRes Function(Variables$Mutation$TrackingCommand) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? siteId = _undefined,
    Object? operation = _undefined,
    Object? input = _undefined,
  }) => _then(
    Variables$Mutation$TrackingCommand._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
      if (operation != _undefined && operation != null)
        'operation': (operation as String),
      if (input != _undefined && input != null) 'input': (input as dynamic),
    }),
  );
}

class _CopyWithStubImpl$Variables$Mutation$TrackingCommand<TRes>
    implements CopyWith$Variables$Mutation$TrackingCommand<TRes> {
  _CopyWithStubImpl$Variables$Mutation$TrackingCommand(this._res);

  TRes _res;

  call({String? siteId, String? operation, dynamic? input}) => _res;
}

class Mutation$TrackingCommand {
  Mutation$TrackingCommand({
    required this.trackingCommand,
    this.$__typename = 'Mutation',
  });

  factory Mutation$TrackingCommand.fromJson(Map<String, dynamic> json) {
    final l$trackingCommand = json['trackingCommand'];
    final l$$__typename = json['__typename'];
    return Mutation$TrackingCommand(
      trackingCommand: (l$trackingCommand as dynamic),
      $__typename: (l$$__typename as String),
    );
  }

  final dynamic trackingCommand;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$trackingCommand = trackingCommand;
    _resultData['trackingCommand'] = l$trackingCommand;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$trackingCommand = trackingCommand;
    final l$$__typename = $__typename;
    return Object.hashAll([l$trackingCommand, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Mutation$TrackingCommand ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$trackingCommand = trackingCommand;
    final lOther$trackingCommand = other.trackingCommand;
    if (l$trackingCommand != lOther$trackingCommand) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Mutation$TrackingCommand
    on Mutation$TrackingCommand {
  CopyWith$Mutation$TrackingCommand<Mutation$TrackingCommand> get copyWith =>
      CopyWith$Mutation$TrackingCommand(this, (i) => i);
}

abstract class CopyWith$Mutation$TrackingCommand<TRes> {
  factory CopyWith$Mutation$TrackingCommand(
    Mutation$TrackingCommand instance,
    TRes Function(Mutation$TrackingCommand) then,
  ) = _CopyWithImpl$Mutation$TrackingCommand;

  factory CopyWith$Mutation$TrackingCommand.stub(TRes res) =
      _CopyWithStubImpl$Mutation$TrackingCommand;

  TRes call({dynamic? trackingCommand, String? $__typename});
}

class _CopyWithImpl$Mutation$TrackingCommand<TRes>
    implements CopyWith$Mutation$TrackingCommand<TRes> {
  _CopyWithImpl$Mutation$TrackingCommand(this._instance, this._then);

  final Mutation$TrackingCommand _instance;

  final TRes Function(Mutation$TrackingCommand) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? trackingCommand = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Mutation$TrackingCommand(
      trackingCommand: trackingCommand == _undefined || trackingCommand == null
          ? _instance.trackingCommand
          : (trackingCommand as dynamic),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Mutation$TrackingCommand<TRes>
    implements CopyWith$Mutation$TrackingCommand<TRes> {
  _CopyWithStubImpl$Mutation$TrackingCommand(this._res);

  TRes _res;

  call({dynamic? trackingCommand, String? $__typename}) => _res;
}

const documentNodeMutationTrackingCommand = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.mutation,
      name: NameNode(value: 'TrackingCommand'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'operation')),
          type: NamedTypeNode(name: NameNode(value: 'String'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'input')),
          type: NamedTypeNode(name: NameNode(value: 'JSON'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'trackingCommand'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'operation'),
                value: VariableNode(name: NameNode(value: 'operation')),
              ),
              ArgumentNode(
                name: NameNode(value: 'input'),
                value: VariableNode(name: NameNode(value: 'input')),
              ),
            ],
            directives: [],
            selectionSet: null,
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Mutation$TrackingCommand _parserFn$Mutation$TrackingCommand(
  Map<String, dynamic> data,
) => Mutation$TrackingCommand.fromJson(data);
typedef OnMutationCompleted$Mutation$TrackingCommand = FutureOr<void> Function(
  Map<String, dynamic>?,
  Mutation$TrackingCommand?,
);

class Options$Mutation$TrackingCommand
    extends graphql.MutationOptions<Mutation$TrackingCommand> {
  Options$Mutation$TrackingCommand({
    String? operationName,
    required Variables$Mutation$TrackingCommand variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Mutation$TrackingCommand? typedOptimisticResult,
    graphql.Context? context,
    OnMutationCompleted$Mutation$TrackingCommand? onCompleted,
    graphql.OnMutationUpdate<Mutation$TrackingCommand>? update,
    graphql.OnError? onError,
  }) : onCompletedWithParsed = onCompleted,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         onCompleted: onCompleted == null
             ? null
             : (data) => onCompleted(
                 data,
                 data == null ? null : _parserFn$Mutation$TrackingCommand(data),
               ),
         update: update,
         onError: onError,
         document: documentNodeMutationTrackingCommand,
         parserFn: _parserFn$Mutation$TrackingCommand,
       );

  final OnMutationCompleted$Mutation$TrackingCommand? onCompletedWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onCompleted == null
        ? super.properties
        : super.properties.where((property) => property != onCompleted),
    onCompletedWithParsed,
  ];
}

class WatchOptions$Mutation$TrackingCommand
    extends graphql.WatchQueryOptions<Mutation$TrackingCommand> {
  WatchOptions$Mutation$TrackingCommand({
    String? operationName,
    required Variables$Mutation$TrackingCommand variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Mutation$TrackingCommand? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeMutationTrackingCommand,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Mutation$TrackingCommand,
       );
}

extension ClientExtension$Mutation$TrackingCommand on graphql.GraphQLClient {
  Future<graphql.QueryResult<Mutation$TrackingCommand>> mutate$TrackingCommand(
    Options$Mutation$TrackingCommand options,
  ) async => await this.mutate(options);

  graphql.ObservableQuery<Mutation$TrackingCommand>
  watchMutation$TrackingCommand(
    WatchOptions$Mutation$TrackingCommand options,
  ) => this.watchMutation(options);
}

class Variables$Mutation$EmployeeLifecycle {
  factory Variables$Mutation$EmployeeLifecycle({
    required String siteId,
    required String operation,
    required Input$EmployeeLifecycleInput input,
  }) => Variables$Mutation$EmployeeLifecycle._({
    r'siteId': siteId,
    r'operation': operation,
    r'input': input,
  });

  Variables$Mutation$EmployeeLifecycle._(this._$data);

  factory Variables$Mutation$EmployeeLifecycle.fromJson(
    Map<String, dynamic> data,
  ) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    final l$operation = data['operation'];
    result$data['operation'] = (l$operation as String);
    final l$input = data['input'];
    result$data['input'] = Input$EmployeeLifecycleInput.fromJson(
      (l$input as Map<String, dynamic>),
    );
    return Variables$Mutation$EmployeeLifecycle._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  String get operation => (_$data['operation'] as String);

  Input$EmployeeLifecycleInput get input =>
      (_$data['input'] as Input$EmployeeLifecycleInput);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    final l$operation = operation;
    result$data['operation'] = l$operation;
    final l$input = input;
    result$data['input'] = l$input.toJson();
    return result$data;
  }

  CopyWith$Variables$Mutation$EmployeeLifecycle<
    Variables$Mutation$EmployeeLifecycle
  >
  get copyWith => CopyWith$Variables$Mutation$EmployeeLifecycle(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Mutation$EmployeeLifecycle ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    final l$operation = operation;
    final lOther$operation = other.operation;
    if (l$operation != lOther$operation) {
      return false;
    }
    final l$input = input;
    final lOther$input = other.input;
    if (l$input != lOther$input) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    final l$operation = operation;
    final l$input = input;
    return Object.hashAll([l$siteId, l$operation, l$input]);
  }
}

abstract class CopyWith$Variables$Mutation$EmployeeLifecycle<TRes> {
  factory CopyWith$Variables$Mutation$EmployeeLifecycle(
    Variables$Mutation$EmployeeLifecycle instance,
    TRes Function(Variables$Mutation$EmployeeLifecycle) then,
  ) = _CopyWithImpl$Variables$Mutation$EmployeeLifecycle;

  factory CopyWith$Variables$Mutation$EmployeeLifecycle.stub(TRes res) =
      _CopyWithStubImpl$Variables$Mutation$EmployeeLifecycle;

  TRes call({
    String? siteId,
    String? operation,
    Input$EmployeeLifecycleInput? input,
  });
}

class _CopyWithImpl$Variables$Mutation$EmployeeLifecycle<TRes>
    implements CopyWith$Variables$Mutation$EmployeeLifecycle<TRes> {
  _CopyWithImpl$Variables$Mutation$EmployeeLifecycle(
    this._instance,
    this._then,
  );

  final Variables$Mutation$EmployeeLifecycle _instance;

  final TRes Function(Variables$Mutation$EmployeeLifecycle) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? siteId = _undefined,
    Object? operation = _undefined,
    Object? input = _undefined,
  }) => _then(
    Variables$Mutation$EmployeeLifecycle._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
      if (operation != _undefined && operation != null)
        'operation': (operation as String),
      if (input != _undefined && input != null)
        'input': (input as Input$EmployeeLifecycleInput),
    }),
  );
}

class _CopyWithStubImpl$Variables$Mutation$EmployeeLifecycle<TRes>
    implements CopyWith$Variables$Mutation$EmployeeLifecycle<TRes> {
  _CopyWithStubImpl$Variables$Mutation$EmployeeLifecycle(this._res);

  TRes _res;

  call({
    String? siteId,
    String? operation,
    Input$EmployeeLifecycleInput? input,
  }) => _res;
}

class Mutation$EmployeeLifecycle {
  Mutation$EmployeeLifecycle({
    required this.employeeLifecycle,
    this.$__typename = 'Mutation',
  });

  factory Mutation$EmployeeLifecycle.fromJson(Map<String, dynamic> json) {
    final l$employeeLifecycle = json['employeeLifecycle'];
    final l$$__typename = json['__typename'];
    return Mutation$EmployeeLifecycle(
      employeeLifecycle: Mutation$EmployeeLifecycle$employeeLifecycle.fromJson(
        (l$employeeLifecycle as Map<String, dynamic>),
      ),
      $__typename: (l$$__typename as String),
    );
  }

  final Mutation$EmployeeLifecycle$employeeLifecycle employeeLifecycle;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$employeeLifecycle = employeeLifecycle;
    _resultData['employeeLifecycle'] = l$employeeLifecycle.toJson();
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$employeeLifecycle = employeeLifecycle;
    final l$$__typename = $__typename;
    return Object.hashAll([l$employeeLifecycle, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Mutation$EmployeeLifecycle ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$employeeLifecycle = employeeLifecycle;
    final lOther$employeeLifecycle = other.employeeLifecycle;
    if (l$employeeLifecycle != lOther$employeeLifecycle) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Mutation$EmployeeLifecycle
    on Mutation$EmployeeLifecycle {
  CopyWith$Mutation$EmployeeLifecycle<Mutation$EmployeeLifecycle>
  get copyWith => CopyWith$Mutation$EmployeeLifecycle(this, (i) => i);
}

abstract class CopyWith$Mutation$EmployeeLifecycle<TRes> {
  factory CopyWith$Mutation$EmployeeLifecycle(
    Mutation$EmployeeLifecycle instance,
    TRes Function(Mutation$EmployeeLifecycle) then,
  ) = _CopyWithImpl$Mutation$EmployeeLifecycle;

  factory CopyWith$Mutation$EmployeeLifecycle.stub(TRes res) =
      _CopyWithStubImpl$Mutation$EmployeeLifecycle;

  TRes call({
    Mutation$EmployeeLifecycle$employeeLifecycle? employeeLifecycle,
    String? $__typename,
  });
  CopyWith$Mutation$EmployeeLifecycle$employeeLifecycle<TRes>
  get employeeLifecycle;
}

class _CopyWithImpl$Mutation$EmployeeLifecycle<TRes>
    implements CopyWith$Mutation$EmployeeLifecycle<TRes> {
  _CopyWithImpl$Mutation$EmployeeLifecycle(this._instance, this._then);

  final Mutation$EmployeeLifecycle _instance;

  final TRes Function(Mutation$EmployeeLifecycle) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? employeeLifecycle = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Mutation$EmployeeLifecycle(
      employeeLifecycle:
          employeeLifecycle == _undefined || employeeLifecycle == null
          ? _instance.employeeLifecycle
          : (employeeLifecycle as Mutation$EmployeeLifecycle$employeeLifecycle),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );

  CopyWith$Mutation$EmployeeLifecycle$employeeLifecycle<TRes>
  get employeeLifecycle {
    final local$employeeLifecycle = _instance.employeeLifecycle;
    return CopyWith$Mutation$EmployeeLifecycle$employeeLifecycle(
      local$employeeLifecycle,
      (e) => call(employeeLifecycle: e),
    );
  }
}

class _CopyWithStubImpl$Mutation$EmployeeLifecycle<TRes>
    implements CopyWith$Mutation$EmployeeLifecycle<TRes> {
  _CopyWithStubImpl$Mutation$EmployeeLifecycle(this._res);

  TRes _res;

  call({
    Mutation$EmployeeLifecycle$employeeLifecycle? employeeLifecycle,
    String? $__typename,
  }) => _res;

  CopyWith$Mutation$EmployeeLifecycle$employeeLifecycle<TRes>
  get employeeLifecycle =>
      CopyWith$Mutation$EmployeeLifecycle$employeeLifecycle.stub(_res);
}

const documentNodeMutationEmployeeLifecycle = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.mutation,
      name: NameNode(value: 'EmployeeLifecycle'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'operation')),
          type: NamedTypeNode(name: NameNode(value: 'String'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'input')),
          type: NamedTypeNode(
            name: NameNode(value: 'EmployeeLifecycleInput'),
            isNonNull: true,
          ),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'employeeLifecycle'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'operation'),
                value: VariableNode(name: NameNode(value: 'operation')),
              ),
              ArgumentNode(
                name: NameNode(value: 'input'),
                value: VariableNode(name: NameNode(value: 'input')),
              ),
            ],
            directives: [],
            selectionSet: SelectionSetNode(
              selections: [
                FieldNode(
                  name: NameNode(value: 'id'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'version'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'password'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: '__typename'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
              ],
            ),
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Mutation$EmployeeLifecycle _parserFn$Mutation$EmployeeLifecycle(
  Map<String, dynamic> data,
) => Mutation$EmployeeLifecycle.fromJson(data);
typedef OnMutationCompleted$Mutation$EmployeeLifecycle =
    FutureOr<void> Function(Map<String, dynamic>?, Mutation$EmployeeLifecycle?);

class Options$Mutation$EmployeeLifecycle
    extends graphql.MutationOptions<Mutation$EmployeeLifecycle> {
  Options$Mutation$EmployeeLifecycle({
    String? operationName,
    required Variables$Mutation$EmployeeLifecycle variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Mutation$EmployeeLifecycle? typedOptimisticResult,
    graphql.Context? context,
    OnMutationCompleted$Mutation$EmployeeLifecycle? onCompleted,
    graphql.OnMutationUpdate<Mutation$EmployeeLifecycle>? update,
    graphql.OnError? onError,
  }) : onCompletedWithParsed = onCompleted,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         onCompleted: onCompleted == null
             ? null
             : (data) => onCompleted(
                 data,
                 data == null
                     ? null
                     : _parserFn$Mutation$EmployeeLifecycle(data),
               ),
         update: update,
         onError: onError,
         document: documentNodeMutationEmployeeLifecycle,
         parserFn: _parserFn$Mutation$EmployeeLifecycle,
       );

  final OnMutationCompleted$Mutation$EmployeeLifecycle? onCompletedWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onCompleted == null
        ? super.properties
        : super.properties.where((property) => property != onCompleted),
    onCompletedWithParsed,
  ];
}

class WatchOptions$Mutation$EmployeeLifecycle
    extends graphql.WatchQueryOptions<Mutation$EmployeeLifecycle> {
  WatchOptions$Mutation$EmployeeLifecycle({
    String? operationName,
    required Variables$Mutation$EmployeeLifecycle variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Mutation$EmployeeLifecycle? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeMutationEmployeeLifecycle,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Mutation$EmployeeLifecycle,
       );
}

extension ClientExtension$Mutation$EmployeeLifecycle on graphql.GraphQLClient {
  Future<graphql.QueryResult<Mutation$EmployeeLifecycle>>
  mutate$EmployeeLifecycle(Options$Mutation$EmployeeLifecycle options) async =>
      await this.mutate(options);

  graphql.ObservableQuery<Mutation$EmployeeLifecycle>
  watchMutation$EmployeeLifecycle(
    WatchOptions$Mutation$EmployeeLifecycle options,
  ) => this.watchMutation(options);
}

class Mutation$EmployeeLifecycle$employeeLifecycle {
  Mutation$EmployeeLifecycle$employeeLifecycle({
    required this.id,
    required this.version,
    this.password,
    this.$__typename = 'EmployeeLifecycleResult',
  });

  factory Mutation$EmployeeLifecycle$employeeLifecycle.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$id = json['id'];
    final l$version = json['version'];
    final l$password = json['password'];
    final l$$__typename = json['__typename'];
    return Mutation$EmployeeLifecycle$employeeLifecycle(
      id: (l$id as String),
      version: (l$version as int),
      password: (l$password as String?),
      $__typename: (l$$__typename as String),
    );
  }

  final String id;

  final int version;

  final String? password;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$version = version;
    _resultData['version'] = l$version;
    final l$password = password;
    _resultData['password'] = l$password;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$version = version;
    final l$password = password;
    final l$$__typename = $__typename;
    return Object.hashAll([l$id, l$version, l$password, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Mutation$EmployeeLifecycle$employeeLifecycle ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$version = version;
    final lOther$version = other.version;
    if (l$version != lOther$version) {
      return false;
    }
    final l$password = password;
    final lOther$password = other.password;
    if (l$password != lOther$password) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Mutation$EmployeeLifecycle$employeeLifecycle
    on Mutation$EmployeeLifecycle$employeeLifecycle {
  CopyWith$Mutation$EmployeeLifecycle$employeeLifecycle<
    Mutation$EmployeeLifecycle$employeeLifecycle
  >
  get copyWith =>
      CopyWith$Mutation$EmployeeLifecycle$employeeLifecycle(this, (i) => i);
}

abstract class CopyWith$Mutation$EmployeeLifecycle$employeeLifecycle<TRes> {
  factory CopyWith$Mutation$EmployeeLifecycle$employeeLifecycle(
    Mutation$EmployeeLifecycle$employeeLifecycle instance,
    TRes Function(Mutation$EmployeeLifecycle$employeeLifecycle) then,
  ) = _CopyWithImpl$Mutation$EmployeeLifecycle$employeeLifecycle;

  factory CopyWith$Mutation$EmployeeLifecycle$employeeLifecycle.stub(TRes res) =
      _CopyWithStubImpl$Mutation$EmployeeLifecycle$employeeLifecycle;

  TRes call({String? id, int? version, String? password, String? $__typename});
}

class _CopyWithImpl$Mutation$EmployeeLifecycle$employeeLifecycle<TRes>
    implements CopyWith$Mutation$EmployeeLifecycle$employeeLifecycle<TRes> {
  _CopyWithImpl$Mutation$EmployeeLifecycle$employeeLifecycle(
    this._instance,
    this._then,
  );

  final Mutation$EmployeeLifecycle$employeeLifecycle _instance;

  final TRes Function(Mutation$EmployeeLifecycle$employeeLifecycle) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? version = _undefined,
    Object? password = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Mutation$EmployeeLifecycle$employeeLifecycle(
      id: id == _undefined || id == null ? _instance.id : (id as String),
      version: version == _undefined || version == null
          ? _instance.version
          : (version as int),
      password: password == _undefined
          ? _instance.password
          : (password as String?),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Mutation$EmployeeLifecycle$employeeLifecycle<TRes>
    implements CopyWith$Mutation$EmployeeLifecycle$employeeLifecycle<TRes> {
  _CopyWithStubImpl$Mutation$EmployeeLifecycle$employeeLifecycle(this._res);

  TRes _res;

  call({String? id, int? version, String? password, String? $__typename}) =>
      _res;
}

class Variables$Query$AttendanceDay {
  factory Variables$Query$AttendanceDay({
    required String siteId,
    required String workDate,
    String? employeeId,
    int? offset,
  }) => Variables$Query$AttendanceDay._({
    r'siteId': siteId,
    r'workDate': workDate,
    if (employeeId != null) r'employeeId': employeeId,
    if (offset != null) r'offset': offset,
  });

  Variables$Query$AttendanceDay._(this._$data);

  factory Variables$Query$AttendanceDay.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$siteId = data['siteId'];
    result$data['siteId'] = (l$siteId as String);
    final l$workDate = data['workDate'];
    result$data['workDate'] = (l$workDate as String);
    if (data.containsKey('employeeId')) {
      final l$employeeId = data['employeeId'];
      result$data['employeeId'] = (l$employeeId as String?);
    }
    if (data.containsKey('offset')) {
      final l$offset = data['offset'];
      result$data['offset'] = (l$offset as int?);
    }
    return Variables$Query$AttendanceDay._(result$data);
  }

  Map<String, dynamic> _$data;

  String get siteId => (_$data['siteId'] as String);

  String get workDate => (_$data['workDate'] as String);

  String? get employeeId => (_$data['employeeId'] as String?);

  int? get offset => (_$data['offset'] as int?);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$siteId = siteId;
    result$data['siteId'] = l$siteId;
    final l$workDate = workDate;
    result$data['workDate'] = l$workDate;
    if (_$data.containsKey('employeeId')) {
      final l$employeeId = employeeId;
      result$data['employeeId'] = l$employeeId;
    }
    if (_$data.containsKey('offset')) {
      final l$offset = offset;
      result$data['offset'] = l$offset;
    }
    return result$data;
  }

  CopyWith$Variables$Query$AttendanceDay<Variables$Query$AttendanceDay>
  get copyWith => CopyWith$Variables$Query$AttendanceDay(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$AttendanceDay ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$siteId = siteId;
    final lOther$siteId = other.siteId;
    if (l$siteId != lOther$siteId) {
      return false;
    }
    final l$workDate = workDate;
    final lOther$workDate = other.workDate;
    if (l$workDate != lOther$workDate) {
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
    final l$offset = offset;
    final lOther$offset = other.offset;
    if (_$data.containsKey('offset') != other._$data.containsKey('offset')) {
      return false;
    }
    if (l$offset != lOther$offset) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$siteId = siteId;
    final l$workDate = workDate;
    final l$employeeId = employeeId;
    final l$offset = offset;
    return Object.hashAll([
      l$siteId,
      l$workDate,
      _$data.containsKey('employeeId') ? l$employeeId : const {},
      _$data.containsKey('offset') ? l$offset : const {},
    ]);
  }
}

abstract class CopyWith$Variables$Query$AttendanceDay<TRes> {
  factory CopyWith$Variables$Query$AttendanceDay(
    Variables$Query$AttendanceDay instance,
    TRes Function(Variables$Query$AttendanceDay) then,
  ) = _CopyWithImpl$Variables$Query$AttendanceDay;

  factory CopyWith$Variables$Query$AttendanceDay.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$AttendanceDay;

  TRes call({
    String? siteId,
    String? workDate,
    String? employeeId,
    int? offset,
  });
}

class _CopyWithImpl$Variables$Query$AttendanceDay<TRes>
    implements CopyWith$Variables$Query$AttendanceDay<TRes> {
  _CopyWithImpl$Variables$Query$AttendanceDay(this._instance, this._then);

  final Variables$Query$AttendanceDay _instance;

  final TRes Function(Variables$Query$AttendanceDay) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? siteId = _undefined,
    Object? workDate = _undefined,
    Object? employeeId = _undefined,
    Object? offset = _undefined,
  }) => _then(
    Variables$Query$AttendanceDay._({
      ..._instance._$data,
      if (siteId != _undefined && siteId != null) 'siteId': (siteId as String),
      if (workDate != _undefined && workDate != null)
        'workDate': (workDate as String),
      if (employeeId != _undefined) 'employeeId': (employeeId as String?),
      if (offset != _undefined) 'offset': (offset as int?),
    }),
  );
}

class _CopyWithStubImpl$Variables$Query$AttendanceDay<TRes>
    implements CopyWith$Variables$Query$AttendanceDay<TRes> {
  _CopyWithStubImpl$Variables$Query$AttendanceDay(this._res);

  TRes _res;

  call({String? siteId, String? workDate, String? employeeId, int? offset}) =>
      _res;
}

class Query$AttendanceDay {
  Query$AttendanceDay({
    required this.attendanceDay,
    this.$__typename = 'Query',
  });

  factory Query$AttendanceDay.fromJson(Map<String, dynamic> json) {
    final l$attendanceDay = json['attendanceDay'];
    final l$$__typename = json['__typename'];
    return Query$AttendanceDay(
      attendanceDay: (l$attendanceDay as dynamic),
      $__typename: (l$$__typename as String),
    );
  }

  final dynamic attendanceDay;

  final String $__typename;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$attendanceDay = attendanceDay;
    _resultData['attendanceDay'] = l$attendanceDay;
    final l$$__typename = $__typename;
    _resultData['__typename'] = l$$__typename;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$attendanceDay = attendanceDay;
    final l$$__typename = $__typename;
    return Object.hashAll([l$attendanceDay, l$$__typename]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$AttendanceDay || runtimeType != other.runtimeType) {
      return false;
    }
    final l$attendanceDay = attendanceDay;
    final lOther$attendanceDay = other.attendanceDay;
    if (l$attendanceDay != lOther$attendanceDay) {
      return false;
    }
    final l$$__typename = $__typename;
    final lOther$$__typename = other.$__typename;
    if (l$$__typename != lOther$$__typename) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$AttendanceDay on Query$AttendanceDay {
  CopyWith$Query$AttendanceDay<Query$AttendanceDay> get copyWith =>
      CopyWith$Query$AttendanceDay(this, (i) => i);
}

abstract class CopyWith$Query$AttendanceDay<TRes> {
  factory CopyWith$Query$AttendanceDay(
    Query$AttendanceDay instance,
    TRes Function(Query$AttendanceDay) then,
  ) = _CopyWithImpl$Query$AttendanceDay;

  factory CopyWith$Query$AttendanceDay.stub(TRes res) =
      _CopyWithStubImpl$Query$AttendanceDay;

  TRes call({dynamic? attendanceDay, String? $__typename});
}

class _CopyWithImpl$Query$AttendanceDay<TRes>
    implements CopyWith$Query$AttendanceDay<TRes> {
  _CopyWithImpl$Query$AttendanceDay(this._instance, this._then);

  final Query$AttendanceDay _instance;

  final TRes Function(Query$AttendanceDay) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? attendanceDay = _undefined,
    Object? $__typename = _undefined,
  }) => _then(
    Query$AttendanceDay(
      attendanceDay: attendanceDay == _undefined || attendanceDay == null
          ? _instance.attendanceDay
          : (attendanceDay as dynamic),
      $__typename: $__typename == _undefined || $__typename == null
          ? _instance.$__typename
          : ($__typename as String),
    ),
  );
}

class _CopyWithStubImpl$Query$AttendanceDay<TRes>
    implements CopyWith$Query$AttendanceDay<TRes> {
  _CopyWithStubImpl$Query$AttendanceDay(this._res);

  TRes _res;

  call({dynamic? attendanceDay, String? $__typename}) => _res;
}

const documentNodeQueryAttendanceDay = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'AttendanceDay'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'siteId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'workDate')),
          type: NamedTypeNode(name: NameNode(value: 'String'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'employeeId')),
          type: NamedTypeNode(name: NameNode(value: 'ID'), isNonNull: false),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'offset')),
          type: NamedTypeNode(name: NameNode(value: 'Int'), isNonNull: false),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'attendanceDay'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'siteId'),
                value: VariableNode(name: NameNode(value: 'siteId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'workDate'),
                value: VariableNode(name: NameNode(value: 'workDate')),
              ),
              ArgumentNode(
                name: NameNode(value: 'employeeId'),
                value: VariableNode(name: NameNode(value: 'employeeId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'offset'),
                value: VariableNode(name: NameNode(value: 'offset')),
              ),
            ],
            directives: [],
            selectionSet: null,
          ),
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
        ],
      ),
    ),
  ],
);
Query$AttendanceDay _parserFn$Query$AttendanceDay(Map<String, dynamic> data) =>
    Query$AttendanceDay.fromJson(data);
typedef OnQueryComplete$Query$AttendanceDay = FutureOr<void> Function(
  Map<String, dynamic>?,
  Query$AttendanceDay?,
);

class Options$Query$AttendanceDay
    extends graphql.QueryOptions<Query$AttendanceDay> {
  Options$Query$AttendanceDay({
    String? operationName,
    required Variables$Query$AttendanceDay variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$AttendanceDay? typedOptimisticResult,
    Duration? pollInterval,
    graphql.Context? context,
    OnQueryComplete$Query$AttendanceDay? onComplete,
    graphql.OnQueryError? onError,
  }) : onCompleteWithParsed = onComplete,
       super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         pollInterval: pollInterval,
         context: context,
         onComplete: onComplete == null
             ? null
             : (data) => onComplete(
                 data,
                 data == null ? null : _parserFn$Query$AttendanceDay(data),
               ),
         onError: onError,
         document: documentNodeQueryAttendanceDay,
         parserFn: _parserFn$Query$AttendanceDay,
       );

  final OnQueryComplete$Query$AttendanceDay? onCompleteWithParsed;

  @override
  List<Object?> get properties => [
    ...super.onComplete == null
        ? super.properties
        : super.properties.where((property) => property != onComplete),
    onCompleteWithParsed,
  ];
}

class WatchOptions$Query$AttendanceDay
    extends graphql.WatchQueryOptions<Query$AttendanceDay> {
  WatchOptions$Query$AttendanceDay({
    String? operationName,
    required Variables$Query$AttendanceDay variables,
    graphql.FetchPolicy? fetchPolicy,
    graphql.ErrorPolicy? errorPolicy,
    graphql.CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Query$AttendanceDay? typedOptimisticResult,
    graphql.Context? context,
    Duration? pollInterval,
    bool? eagerlyFetchResults,
    bool carryForwardDataOnException = true,
    bool fetchResults = false,
  }) : super(
         variables: variables.toJson(),
         operationName: operationName,
         fetchPolicy: fetchPolicy,
         errorPolicy: errorPolicy,
         cacheRereadPolicy: cacheRereadPolicy,
         optimisticResult: optimisticResult ?? typedOptimisticResult?.toJson(),
         context: context,
         document: documentNodeQueryAttendanceDay,
         pollInterval: pollInterval,
         eagerlyFetchResults: eagerlyFetchResults,
         carryForwardDataOnException: carryForwardDataOnException,
         fetchResults: fetchResults,
         parserFn: _parserFn$Query$AttendanceDay,
       );
}

class FetchMoreOptions$Query$AttendanceDay extends graphql.FetchMoreOptions {
  FetchMoreOptions$Query$AttendanceDay({
    required graphql.UpdateQuery updateQuery,
    required Variables$Query$AttendanceDay variables,
  }) : super(
         updateQuery: updateQuery,
         variables: variables.toJson(),
         document: documentNodeQueryAttendanceDay,
       );
}

extension ClientExtension$Query$AttendanceDay on graphql.GraphQLClient {
  Future<graphql.QueryResult<Query$AttendanceDay>> query$AttendanceDay(
    Options$Query$AttendanceDay options,
  ) async => await this.query(options);

  graphql.ObservableQuery<Query$AttendanceDay> watchQuery$AttendanceDay(
    WatchOptions$Query$AttendanceDay options,
  ) => this.watchQuery(options);

  void writeQuery$AttendanceDay({
    required Query$AttendanceDay data,
    required Variables$Query$AttendanceDay variables,
    bool broadcast = true,
  }) => this.writeQuery(
    graphql.Request(
      operation: graphql.Operation(document: documentNodeQueryAttendanceDay),
      variables: variables.toJson(),
    ),
    data: data.toJson(),
    broadcast: broadcast,
  );

  Query$AttendanceDay? readQuery$AttendanceDay({
    required Variables$Query$AttendanceDay variables,
    bool optimistic = true,
  }) {
    final result = this.readQuery(
      graphql.Request(
        operation: graphql.Operation(document: documentNodeQueryAttendanceDay),
        variables: variables.toJson(),
      ),
      optimistic: optimistic,
    );
    return result == null ? null : Query$AttendanceDay.fromJson(result);
  }
}
