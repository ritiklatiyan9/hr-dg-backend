// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline.dart';

// ignore_for_file: type=lint
class $UiPreferencesTable extends UiPreferences
    with TableInfo<$UiPreferencesTable, UiPreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UiPreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ui_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<UiPreference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  UiPreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UiPreference(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $UiPreferencesTable createAlias(String alias) {
    return $UiPreferencesTable(attachedDatabase, alias);
  }
}

class UiPreference extends DataClass implements Insertable<UiPreference> {
  final String key;
  final String value;
  const UiPreference({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  UiPreferencesCompanion toCompanion(bool nullToAbsent) {
    return UiPreferencesCompanion(key: Value(key), value: Value(value));
  }

  factory UiPreference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UiPreference(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  UiPreference copyWith({String? key, String? value}) =>
      UiPreference(key: key ?? this.key, value: value ?? this.value);
  UiPreference copyWithCompanion(UiPreferencesCompanion data) {
    return UiPreference(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UiPreference(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UiPreference &&
          other.key == this.key &&
          other.value == this.value);
}

class UiPreferencesCompanion extends UpdateCompanion<UiPreference> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const UiPreferencesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UiPreferencesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<UiPreference> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UiPreferencesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return UiPreferencesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UiPreferencesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$OfflineDatabase extends GeneratedDatabase {
  _$OfflineDatabase(QueryExecutor e) : super(e);
  $OfflineDatabaseManager get managers => $OfflineDatabaseManager(this);
  late final $UiPreferencesTable uiPreferences = $UiPreferencesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [uiPreferences];
}

typedef $$UiPreferencesTableCreateCompanionBuilder =
    UiPreferencesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$UiPreferencesTableUpdateCompanionBuilder =
    UiPreferencesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$UiPreferencesTableFilterComposer
    extends Composer<_$OfflineDatabase, $UiPreferencesTable> {
  $$UiPreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UiPreferencesTableOrderingComposer
    extends Composer<_$OfflineDatabase, $UiPreferencesTable> {
  $$UiPreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UiPreferencesTableAnnotationComposer
    extends Composer<_$OfflineDatabase, $UiPreferencesTable> {
  $$UiPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$UiPreferencesTableTableManager
    extends
        RootTableManager<
          _$OfflineDatabase,
          $UiPreferencesTable,
          UiPreference,
          $$UiPreferencesTableFilterComposer,
          $$UiPreferencesTableOrderingComposer,
          $$UiPreferencesTableAnnotationComposer,
          $$UiPreferencesTableCreateCompanionBuilder,
          $$UiPreferencesTableUpdateCompanionBuilder,
          (
            UiPreference,
            BaseReferences<
              _$OfflineDatabase,
              $UiPreferencesTable,
              UiPreference
            >,
          ),
          UiPreference,
          PrefetchHooks Function()
        > {
  $$UiPreferencesTableTableManager(
    _$OfflineDatabase db,
    $UiPreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UiPreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UiPreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UiPreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  UiPreferencesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => UiPreferencesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UiPreferencesTable, UiPreference>(table),
                  BaseReferences<
                    _$OfflineDatabase,
                    $UiPreferencesTable,
                    UiPreference
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UiPreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$OfflineDatabase,
      $UiPreferencesTable,
      UiPreference,
      $$UiPreferencesTableFilterComposer,
      $$UiPreferencesTableOrderingComposer,
      $$UiPreferencesTableAnnotationComposer,
      $$UiPreferencesTableCreateCompanionBuilder,
      $$UiPreferencesTableUpdateCompanionBuilder,
      (
        UiPreference,
        BaseReferences<_$OfflineDatabase, $UiPreferencesTable, UiPreference>,
      ),
      UiPreference,
      PrefetchHooks Function()
    >;

class $OfflineDatabaseManager {
  final _$OfflineDatabase _db;
  $OfflineDatabaseManager(this._db);
  $$UiPreferencesTableTableManager get uiPreferences =>
      $$UiPreferencesTableTableManager(_db, _db.uiPreferences);
}
