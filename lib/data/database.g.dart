// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SessionRowsTable extends SessionRows
    with TableInfo<$SessionRowsTable, SessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCurrentMeta = const VerificationMeta(
    'isCurrent',
  );
  @override
  late final GeneratedColumn<bool> isCurrent = GeneratedColumn<bool>(
    'is_current',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_current" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, isCurrent, data];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('is_current')) {
      context.handle(
        _isCurrentMeta,
        isCurrent.isAcceptableOrUnknown(data['is_current']!, _isCurrentMeta),
      );
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      isCurrent:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_current'],
          )!,
      data:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}data'],
          )!,
    );
  }

  @override
  $SessionRowsTable createAlias(String alias) {
    return $SessionRowsTable(attachedDatabase, alias);
  }
}

class SessionRow extends DataClass implements Insertable<SessionRow> {
  final String id;
  final bool isCurrent;
  final String data;
  const SessionRow({
    required this.id,
    required this.isCurrent,
    required this.data,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['is_current'] = Variable<bool>(isCurrent);
    map['data'] = Variable<String>(data);
    return map;
  }

  SessionRowsCompanion toCompanion(bool nullToAbsent) {
    return SessionRowsCompanion(
      id: Value(id),
      isCurrent: Value(isCurrent),
      data: Value(data),
    );
  }

  factory SessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRow(
      id: serializer.fromJson<String>(json['id']),
      isCurrent: serializer.fromJson<bool>(json['isCurrent']),
      data: serializer.fromJson<String>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'isCurrent': serializer.toJson<bool>(isCurrent),
      'data': serializer.toJson<String>(data),
    };
  }

  SessionRow copyWith({String? id, bool? isCurrent, String? data}) =>
      SessionRow(
        id: id ?? this.id,
        isCurrent: isCurrent ?? this.isCurrent,
        data: data ?? this.data,
      );
  SessionRow copyWithCompanion(SessionRowsCompanion data) {
    return SessionRow(
      id: data.id.present ? data.id.value : this.id,
      isCurrent: data.isCurrent.present ? data.isCurrent.value : this.isCurrent,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionRow(')
          ..write('id: $id, ')
          ..write('isCurrent: $isCurrent, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, isCurrent, data);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionRow &&
          other.id == this.id &&
          other.isCurrent == this.isCurrent &&
          other.data == this.data);
}

class SessionRowsCompanion extends UpdateCompanion<SessionRow> {
  final Value<String> id;
  final Value<bool> isCurrent;
  final Value<String> data;
  final Value<int> rowid;
  const SessionRowsCompanion({
    this.id = const Value.absent(),
    this.isCurrent = const Value.absent(),
    this.data = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionRowsCompanion.insert({
    required String id,
    this.isCurrent = const Value.absent(),
    required String data,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       data = Value(data);
  static Insertable<SessionRow> custom({
    Expression<String>? id,
    Expression<bool>? isCurrent,
    Expression<String>? data,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isCurrent != null) 'is_current': isCurrent,
      if (data != null) 'data': data,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionRowsCompanion copyWith({
    Value<String>? id,
    Value<bool>? isCurrent,
    Value<String>? data,
    Value<int>? rowid,
  }) {
    return SessionRowsCompanion(
      id: id ?? this.id,
      isCurrent: isCurrent ?? this.isCurrent,
      data: data ?? this.data,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (isCurrent.present) {
      map['is_current'] = Variable<bool>(isCurrent.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionRowsCompanion(')
          ..write('id: $id, ')
          ..write('isCurrent: $isCurrent, ')
          ..write('data: $data, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessageRowsTable extends MessageRows
    with TableInfo<$MessageRowsTable, MessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessageRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [sessionId, data];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  MessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageRow(
      sessionId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}session_id'],
          )!,
      data:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}data'],
          )!,
    );
  }

  @override
  $MessageRowsTable createAlias(String alias) {
    return $MessageRowsTable(attachedDatabase, alias);
  }
}

class MessageRow extends DataClass implements Insertable<MessageRow> {
  final String sessionId;
  final String data;
  const MessageRow({required this.sessionId, required this.data});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['data'] = Variable<String>(data);
    return map;
  }

  MessageRowsCompanion toCompanion(bool nullToAbsent) {
    return MessageRowsCompanion(sessionId: Value(sessionId), data: Value(data));
  }

  factory MessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageRow(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      data: serializer.fromJson<String>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'data': serializer.toJson<String>(data),
    };
  }

  MessageRow copyWith({String? sessionId, String? data}) => MessageRow(
    sessionId: sessionId ?? this.sessionId,
    data: data ?? this.data,
  );
  MessageRow copyWithCompanion(MessageRowsCompanion data) {
    return MessageRow(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageRow(')
          ..write('sessionId: $sessionId, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sessionId, data);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageRow &&
          other.sessionId == this.sessionId &&
          other.data == this.data);
}

class MessageRowsCompanion extends UpdateCompanion<MessageRow> {
  final Value<String> sessionId;
  final Value<String> data;
  final Value<int> rowid;
  const MessageRowsCompanion({
    this.sessionId = const Value.absent(),
    this.data = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessageRowsCompanion.insert({
    required String sessionId,
    required String data,
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       data = Value(data);
  static Insertable<MessageRow> custom({
    Expression<String>? sessionId,
    Expression<String>? data,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (data != null) 'data': data,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessageRowsCompanion copyWith({
    Value<String>? sessionId,
    Value<String>? data,
    Value<int>? rowid,
  }) {
    return MessageRowsCompanion(
      sessionId: sessionId ?? this.sessionId,
      data: data ?? this.data,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessageRowsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('data: $data, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ModelRowsTable extends ModelRows
    with TableInfo<$ModelRowsTable, ModelRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ModelRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, data];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'model_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<ModelRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ModelRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ModelRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      data:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}data'],
          )!,
    );
  }

  @override
  $ModelRowsTable createAlias(String alias) {
    return $ModelRowsTable(attachedDatabase, alias);
  }
}

class ModelRow extends DataClass implements Insertable<ModelRow> {
  final String id;
  final String data;
  const ModelRow({required this.id, required this.data});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['data'] = Variable<String>(data);
    return map;
  }

  ModelRowsCompanion toCompanion(bool nullToAbsent) {
    return ModelRowsCompanion(id: Value(id), data: Value(data));
  }

  factory ModelRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ModelRow(
      id: serializer.fromJson<String>(json['id']),
      data: serializer.fromJson<String>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'data': serializer.toJson<String>(data),
    };
  }

  ModelRow copyWith({String? id, String? data}) =>
      ModelRow(id: id ?? this.id, data: data ?? this.data);
  ModelRow copyWithCompanion(ModelRowsCompanion data) {
    return ModelRow(
      id: data.id.present ? data.id.value : this.id,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ModelRow(')
          ..write('id: $id, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, data);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ModelRow && other.id == this.id && other.data == this.data);
}

class ModelRowsCompanion extends UpdateCompanion<ModelRow> {
  final Value<String> id;
  final Value<String> data;
  final Value<int> rowid;
  const ModelRowsCompanion({
    this.id = const Value.absent(),
    this.data = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ModelRowsCompanion.insert({
    required String id,
    required String data,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       data = Value(data);
  static Insertable<ModelRow> custom({
    Expression<String>? id,
    Expression<String>? data,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (data != null) 'data': data,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ModelRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? data,
    Value<int>? rowid,
  }) {
    return ModelRowsCompanion(
      id: id ?? this.id,
      data: data ?? this.data,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ModelRowsCompanion(')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $McpRowsTable extends McpRows with TableInfo<$McpRowsTable, McpRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $McpRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [name, data];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mcp_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<McpRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  McpRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return McpRow(
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      data:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}data'],
          )!,
    );
  }

  @override
  $McpRowsTable createAlias(String alias) {
    return $McpRowsTable(attachedDatabase, alias);
  }
}

class McpRow extends DataClass implements Insertable<McpRow> {
  final String name;
  final String data;
  const McpRow({required this.name, required this.data});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['data'] = Variable<String>(data);
    return map;
  }

  McpRowsCompanion toCompanion(bool nullToAbsent) {
    return McpRowsCompanion(name: Value(name), data: Value(data));
  }

  factory McpRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return McpRow(
      name: serializer.fromJson<String>(json['name']),
      data: serializer.fromJson<String>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'data': serializer.toJson<String>(data),
    };
  }

  McpRow copyWith({String? name, String? data}) =>
      McpRow(name: name ?? this.name, data: data ?? this.data);
  McpRow copyWithCompanion(McpRowsCompanion data) {
    return McpRow(
      name: data.name.present ? data.name.value : this.name,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('McpRow(')
          ..write('name: $name, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, data);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is McpRow && other.name == this.name && other.data == this.data);
}

class McpRowsCompanion extends UpdateCompanion<McpRow> {
  final Value<String> name;
  final Value<String> data;
  final Value<int> rowid;
  const McpRowsCompanion({
    this.name = const Value.absent(),
    this.data = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  McpRowsCompanion.insert({
    required String name,
    required String data,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       data = Value(data);
  static Insertable<McpRow> custom({
    Expression<String>? name,
    Expression<String>? data,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (data != null) 'data': data,
      if (rowid != null) 'rowid': rowid,
    });
  }

  McpRowsCompanion copyWith({
    Value<String>? name,
    Value<String>? data,
    Value<int>? rowid,
  }) {
    return McpRowsCompanion(
      name: name ?? this.name,
      data: data ?? this.data,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('McpRowsCompanion(')
          ..write('name: $name, ')
          ..write('data: $data, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingRowsTable extends SettingRows
    with TableInfo<$SettingRowsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, data];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'setting_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
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
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}key'],
          )!,
      data:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}data'],
          )!,
    );
  }

  @override
  $SettingRowsTable createAlias(String alias) {
    return $SettingRowsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String data;
  const SettingRow({required this.key, required this.data});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['data'] = Variable<String>(data);
    return map;
  }

  SettingRowsCompanion toCompanion(bool nullToAbsent) {
    return SettingRowsCompanion(key: Value(key), data: Value(data));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      data: serializer.fromJson<String>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'data': serializer.toJson<String>(data),
    };
  }

  SettingRow copyWith({String? key, String? data}) =>
      SettingRow(key: key ?? this.key, data: data ?? this.data);
  SettingRow copyWithCompanion(SettingRowsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, data);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow && other.key == this.key && other.data == this.data);
}

class SettingRowsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> data;
  final Value<int> rowid;
  const SettingRowsCompanion({
    this.key = const Value.absent(),
    this.data = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingRowsCompanion.insert({
    required String key,
    required String data,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       data = Value(data);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? data,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (data != null) 'data': data,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingRowsCompanion copyWith({
    Value<String>? key,
    Value<String>? data,
    Value<int>? rowid,
  }) {
    return SettingRowsCompanion(
      key: key ?? this.key,
      data: data ?? this.data,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingRowsCompanion(')
          ..write('key: $key, ')
          ..write('data: $data, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditRowsTable extends AuditRows
    with TableInfo<$AuditRowsTable, AuditRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _requestIdMeta = const VerificationMeta(
    'requestId',
  );
  @override
  late final GeneratedColumn<String> requestId = GeneratedColumn<String>(
    'request_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    requestId,
    sessionId,
    timestamp,
    data,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('request_id')) {
      context.handle(
        _requestIdMeta,
        requestId.isAcceptableOrUnknown(data['request_id']!, _requestIdMeta),
      );
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      requestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request_id'],
      ),
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      ),
      timestamp:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}timestamp'],
          )!,
      data:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}data'],
          )!,
    );
  }

  @override
  $AuditRowsTable createAlias(String alias) {
    return $AuditRowsTable(attachedDatabase, alias);
  }
}

class AuditRow extends DataClass implements Insertable<AuditRow> {
  final int id;
  final String? requestId;
  final String? sessionId;
  final int timestamp;
  final String data;
  const AuditRow({
    required this.id,
    this.requestId,
    this.sessionId,
    required this.timestamp,
    required this.data,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || requestId != null) {
      map['request_id'] = Variable<String>(requestId);
    }
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    map['timestamp'] = Variable<int>(timestamp);
    map['data'] = Variable<String>(data);
    return map;
  }

  AuditRowsCompanion toCompanion(bool nullToAbsent) {
    return AuditRowsCompanion(
      id: Value(id),
      requestId:
          requestId == null && nullToAbsent
              ? const Value.absent()
              : Value(requestId),
      sessionId:
          sessionId == null && nullToAbsent
              ? const Value.absent()
              : Value(sessionId),
      timestamp: Value(timestamp),
      data: Value(data),
    );
  }

  factory AuditRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditRow(
      id: serializer.fromJson<int>(json['id']),
      requestId: serializer.fromJson<String?>(json['requestId']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      data: serializer.fromJson<String>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'requestId': serializer.toJson<String?>(requestId),
      'sessionId': serializer.toJson<String?>(sessionId),
      'timestamp': serializer.toJson<int>(timestamp),
      'data': serializer.toJson<String>(data),
    };
  }

  AuditRow copyWith({
    int? id,
    Value<String?> requestId = const Value.absent(),
    Value<String?> sessionId = const Value.absent(),
    int? timestamp,
    String? data,
  }) => AuditRow(
    id: id ?? this.id,
    requestId: requestId.present ? requestId.value : this.requestId,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
    timestamp: timestamp ?? this.timestamp,
    data: data ?? this.data,
  );
  AuditRow copyWithCompanion(AuditRowsCompanion data) {
    return AuditRow(
      id: data.id.present ? data.id.value : this.id,
      requestId: data.requestId.present ? data.requestId.value : this.requestId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditRow(')
          ..write('id: $id, ')
          ..write('requestId: $requestId, ')
          ..write('sessionId: $sessionId, ')
          ..write('timestamp: $timestamp, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, requestId, sessionId, timestamp, data);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditRow &&
          other.id == this.id &&
          other.requestId == this.requestId &&
          other.sessionId == this.sessionId &&
          other.timestamp == this.timestamp &&
          other.data == this.data);
}

class AuditRowsCompanion extends UpdateCompanion<AuditRow> {
  final Value<int> id;
  final Value<String?> requestId;
  final Value<String?> sessionId;
  final Value<int> timestamp;
  final Value<String> data;
  const AuditRowsCompanion({
    this.id = const Value.absent(),
    this.requestId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.data = const Value.absent(),
  });
  AuditRowsCompanion.insert({
    this.id = const Value.absent(),
    this.requestId = const Value.absent(),
    this.sessionId = const Value.absent(),
    required int timestamp,
    required String data,
  }) : timestamp = Value(timestamp),
       data = Value(data);
  static Insertable<AuditRow> custom({
    Expression<int>? id,
    Expression<String>? requestId,
    Expression<String>? sessionId,
    Expression<int>? timestamp,
    Expression<String>? data,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (requestId != null) 'request_id': requestId,
      if (sessionId != null) 'session_id': sessionId,
      if (timestamp != null) 'timestamp': timestamp,
      if (data != null) 'data': data,
    });
  }

  AuditRowsCompanion copyWith({
    Value<int>? id,
    Value<String?>? requestId,
    Value<String?>? sessionId,
    Value<int>? timestamp,
    Value<String>? data,
  }) {
    return AuditRowsCompanion(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      sessionId: sessionId ?? this.sessionId,
      timestamp: timestamp ?? this.timestamp,
      data: data ?? this.data,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (requestId.present) {
      map['request_id'] = Variable<String>(requestId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditRowsCompanion(')
          ..write('id: $id, ')
          ..write('requestId: $requestId, ')
          ..write('sessionId: $sessionId, ')
          ..write('timestamp: $timestamp, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }
}

class $UsageRowsTable extends UsageRows
    with TableInfo<$UsageRowsTable, UsageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsageRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _detailKeyMeta = const VerificationMeta(
    'detailKey',
  );
  @override
  late final GeneratedColumn<String> detailKey = GeneratedColumn<String>(
    'detail_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    detailKey,
    sessionId,
    model,
    timestamp,
    data,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'usage_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<UsageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('detail_key')) {
      context.handle(
        _detailKeyMeta,
        detailKey.isAcceptableOrUnknown(data['detail_key']!, _detailKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_detailKeyMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UsageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UsageRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      detailKey:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}detail_key'],
          )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      ),
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      timestamp:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}timestamp'],
          )!,
      data:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}data'],
          )!,
    );
  }

  @override
  $UsageRowsTable createAlias(String alias) {
    return $UsageRowsTable(attachedDatabase, alias);
  }
}

class UsageRow extends DataClass implements Insertable<UsageRow> {
  final int id;
  final String detailKey;
  final String? sessionId;
  final String? model;
  final int timestamp;
  final String data;
  const UsageRow({
    required this.id,
    required this.detailKey,
    this.sessionId,
    this.model,
    required this.timestamp,
    required this.data,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['detail_key'] = Variable<String>(detailKey);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    map['timestamp'] = Variable<int>(timestamp);
    map['data'] = Variable<String>(data);
    return map;
  }

  UsageRowsCompanion toCompanion(bool nullToAbsent) {
    return UsageRowsCompanion(
      id: Value(id),
      detailKey: Value(detailKey),
      sessionId:
          sessionId == null && nullToAbsent
              ? const Value.absent()
              : Value(sessionId),
      model:
          model == null && nullToAbsent ? const Value.absent() : Value(model),
      timestamp: Value(timestamp),
      data: Value(data),
    );
  }

  factory UsageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UsageRow(
      id: serializer.fromJson<int>(json['id']),
      detailKey: serializer.fromJson<String>(json['detailKey']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
      model: serializer.fromJson<String?>(json['model']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      data: serializer.fromJson<String>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'detailKey': serializer.toJson<String>(detailKey),
      'sessionId': serializer.toJson<String?>(sessionId),
      'model': serializer.toJson<String?>(model),
      'timestamp': serializer.toJson<int>(timestamp),
      'data': serializer.toJson<String>(data),
    };
  }

  UsageRow copyWith({
    int? id,
    String? detailKey,
    Value<String?> sessionId = const Value.absent(),
    Value<String?> model = const Value.absent(),
    int? timestamp,
    String? data,
  }) => UsageRow(
    id: id ?? this.id,
    detailKey: detailKey ?? this.detailKey,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
    model: model.present ? model.value : this.model,
    timestamp: timestamp ?? this.timestamp,
    data: data ?? this.data,
  );
  UsageRow copyWithCompanion(UsageRowsCompanion data) {
    return UsageRow(
      id: data.id.present ? data.id.value : this.id,
      detailKey: data.detailKey.present ? data.detailKey.value : this.detailKey,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      model: data.model.present ? data.model.value : this.model,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UsageRow(')
          ..write('id: $id, ')
          ..write('detailKey: $detailKey, ')
          ..write('sessionId: $sessionId, ')
          ..write('model: $model, ')
          ..write('timestamp: $timestamp, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, detailKey, sessionId, model, timestamp, data);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UsageRow &&
          other.id == this.id &&
          other.detailKey == this.detailKey &&
          other.sessionId == this.sessionId &&
          other.model == this.model &&
          other.timestamp == this.timestamp &&
          other.data == this.data);
}

class UsageRowsCompanion extends UpdateCompanion<UsageRow> {
  final Value<int> id;
  final Value<String> detailKey;
  final Value<String?> sessionId;
  final Value<String?> model;
  final Value<int> timestamp;
  final Value<String> data;
  const UsageRowsCompanion({
    this.id = const Value.absent(),
    this.detailKey = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.model = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.data = const Value.absent(),
  });
  UsageRowsCompanion.insert({
    this.id = const Value.absent(),
    required String detailKey,
    this.sessionId = const Value.absent(),
    this.model = const Value.absent(),
    required int timestamp,
    required String data,
  }) : detailKey = Value(detailKey),
       timestamp = Value(timestamp),
       data = Value(data);
  static Insertable<UsageRow> custom({
    Expression<int>? id,
    Expression<String>? detailKey,
    Expression<String>? sessionId,
    Expression<String>? model,
    Expression<int>? timestamp,
    Expression<String>? data,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (detailKey != null) 'detail_key': detailKey,
      if (sessionId != null) 'session_id': sessionId,
      if (model != null) 'model': model,
      if (timestamp != null) 'timestamp': timestamp,
      if (data != null) 'data': data,
    });
  }

  UsageRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? detailKey,
    Value<String?>? sessionId,
    Value<String?>? model,
    Value<int>? timestamp,
    Value<String>? data,
  }) {
    return UsageRowsCompanion(
      id: id ?? this.id,
      detailKey: detailKey ?? this.detailKey,
      sessionId: sessionId ?? this.sessionId,
      model: model ?? this.model,
      timestamp: timestamp ?? this.timestamp,
      data: data ?? this.data,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (detailKey.present) {
      map['detail_key'] = Variable<String>(detailKey.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsageRowsCompanion(')
          ..write('id: $id, ')
          ..write('detailKey: $detailKey, ')
          ..write('sessionId: $sessionId, ')
          ..write('model: $model, ')
          ..write('timestamp: $timestamp, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }
}

class $VendorKeyRowsTable extends VendorKeyRows
    with TableInfo<$VendorKeyRowsTable, VendorKeyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VendorKeyRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _vendorIdMeta = const VerificationMeta(
    'vendorId',
  );
  @override
  late final GeneratedColumn<String> vendorId = GeneratedColumn<String>(
    'vendor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _apiKeyMeta = const VerificationMeta('apiKey');
  @override
  late final GeneratedColumn<String> apiKey = GeneratedColumn<String>(
    'api_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [vendorId, apiKey, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vendor_key_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<VendorKeyRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('vendor_id')) {
      context.handle(
        _vendorIdMeta,
        vendorId.isAcceptableOrUnknown(data['vendor_id']!, _vendorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vendorIdMeta);
    }
    if (data.containsKey('api_key')) {
      context.handle(
        _apiKeyMeta,
        apiKey.isAcceptableOrUnknown(data['api_key']!, _apiKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_apiKeyMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {vendorId};
  @override
  VendorKeyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VendorKeyRow(
      vendorId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}vendor_id'],
          )!,
      apiKey:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}api_key'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $VendorKeyRowsTable createAlias(String alias) {
    return $VendorKeyRowsTable(attachedDatabase, alias);
  }
}

class VendorKeyRow extends DataClass implements Insertable<VendorKeyRow> {
  final String vendorId;
  final String apiKey;
  final String updatedAt;
  const VendorKeyRow({
    required this.vendorId,
    required this.apiKey,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['vendor_id'] = Variable<String>(vendorId);
    map['api_key'] = Variable<String>(apiKey);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  VendorKeyRowsCompanion toCompanion(bool nullToAbsent) {
    return VendorKeyRowsCompanion(
      vendorId: Value(vendorId),
      apiKey: Value(apiKey),
      updatedAt: Value(updatedAt),
    );
  }

  factory VendorKeyRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VendorKeyRow(
      vendorId: serializer.fromJson<String>(json['vendorId']),
      apiKey: serializer.fromJson<String>(json['apiKey']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'vendorId': serializer.toJson<String>(vendorId),
      'apiKey': serializer.toJson<String>(apiKey),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  VendorKeyRow copyWith({
    String? vendorId,
    String? apiKey,
    String? updatedAt,
  }) => VendorKeyRow(
    vendorId: vendorId ?? this.vendorId,
    apiKey: apiKey ?? this.apiKey,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  VendorKeyRow copyWithCompanion(VendorKeyRowsCompanion data) {
    return VendorKeyRow(
      vendorId: data.vendorId.present ? data.vendorId.value : this.vendorId,
      apiKey: data.apiKey.present ? data.apiKey.value : this.apiKey,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VendorKeyRow(')
          ..write('vendorId: $vendorId, ')
          ..write('apiKey: $apiKey, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(vendorId, apiKey, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VendorKeyRow &&
          other.vendorId == this.vendorId &&
          other.apiKey == this.apiKey &&
          other.updatedAt == this.updatedAt);
}

class VendorKeyRowsCompanion extends UpdateCompanion<VendorKeyRow> {
  final Value<String> vendorId;
  final Value<String> apiKey;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const VendorKeyRowsCompanion({
    this.vendorId = const Value.absent(),
    this.apiKey = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VendorKeyRowsCompanion.insert({
    required String vendorId,
    required String apiKey,
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : vendorId = Value(vendorId),
       apiKey = Value(apiKey),
       updatedAt = Value(updatedAt);
  static Insertable<VendorKeyRow> custom({
    Expression<String>? vendorId,
    Expression<String>? apiKey,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (vendorId != null) 'vendor_id': vendorId,
      if (apiKey != null) 'api_key': apiKey,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VendorKeyRowsCompanion copyWith({
    Value<String>? vendorId,
    Value<String>? apiKey,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return VendorKeyRowsCompanion(
      vendorId: vendorId ?? this.vendorId,
      apiKey: apiKey ?? this.apiKey,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (vendorId.present) {
      map['vendor_id'] = Variable<String>(vendorId.value);
    }
    if (apiKey.present) {
      map['api_key'] = Variable<String>(apiKey.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VendorKeyRowsCompanion(')
          ..write('vendorId: $vendorId, ')
          ..write('apiKey: $apiKey, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SessionRowsTable sessionRows = $SessionRowsTable(this);
  late final $MessageRowsTable messageRows = $MessageRowsTable(this);
  late final $ModelRowsTable modelRows = $ModelRowsTable(this);
  late final $McpRowsTable mcpRows = $McpRowsTable(this);
  late final $SettingRowsTable settingRows = $SettingRowsTable(this);
  late final $AuditRowsTable auditRows = $AuditRowsTable(this);
  late final $UsageRowsTable usageRows = $UsageRowsTable(this);
  late final $VendorKeyRowsTable vendorKeyRows = $VendorKeyRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sessionRows,
    messageRows,
    modelRows,
    mcpRows,
    settingRows,
    auditRows,
    usageRows,
    vendorKeyRows,
  ];
}

typedef $$SessionRowsTableCreateCompanionBuilder =
    SessionRowsCompanion Function({
      required String id,
      Value<bool> isCurrent,
      required String data,
      Value<int> rowid,
    });
typedef $$SessionRowsTableUpdateCompanionBuilder =
    SessionRowsCompanion Function({
      Value<String> id,
      Value<bool> isCurrent,
      Value<String> data,
      Value<int> rowid,
    });

class $$SessionRowsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionRowsTable> {
  $$SessionRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCurrent => $composableBuilder(
    column: $table.isCurrent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionRowsTable> {
  $$SessionRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCurrent => $composableBuilder(
    column: $table.isCurrent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionRowsTable> {
  $$SessionRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isCurrent =>
      $composableBuilder(column: $table.isCurrent, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);
}

class $$SessionRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionRowsTable,
          SessionRow,
          $$SessionRowsTableFilterComposer,
          $$SessionRowsTableOrderingComposer,
          $$SessionRowsTableAnnotationComposer,
          $$SessionRowsTableCreateCompanionBuilder,
          $$SessionRowsTableUpdateCompanionBuilder,
          (
            SessionRow,
            BaseReferences<_$AppDatabase, $SessionRowsTable, SessionRow>,
          ),
          SessionRow,
          PrefetchHooks Function()
        > {
  $$SessionRowsTableTableManager(_$AppDatabase db, $SessionRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$SessionRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$SessionRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$SessionRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<bool> isCurrent = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionRowsCompanion(
                id: id,
                isCurrent: isCurrent,
                data: data,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<bool> isCurrent = const Value.absent(),
                required String data,
                Value<int> rowid = const Value.absent(),
              }) => SessionRowsCompanion.insert(
                id: id,
                isCurrent: isCurrent,
                data: data,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionRowsTable,
      SessionRow,
      $$SessionRowsTableFilterComposer,
      $$SessionRowsTableOrderingComposer,
      $$SessionRowsTableAnnotationComposer,
      $$SessionRowsTableCreateCompanionBuilder,
      $$SessionRowsTableUpdateCompanionBuilder,
      (
        SessionRow,
        BaseReferences<_$AppDatabase, $SessionRowsTable, SessionRow>,
      ),
      SessionRow,
      PrefetchHooks Function()
    >;
typedef $$MessageRowsTableCreateCompanionBuilder =
    MessageRowsCompanion Function({
      required String sessionId,
      required String data,
      Value<int> rowid,
    });
typedef $$MessageRowsTableUpdateCompanionBuilder =
    MessageRowsCompanion Function({
      Value<String> sessionId,
      Value<String> data,
      Value<int> rowid,
    });

class $$MessageRowsTableFilterComposer
    extends Composer<_$AppDatabase, $MessageRowsTable> {
  $$MessageRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessageRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $MessageRowsTable> {
  $$MessageRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessageRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessageRowsTable> {
  $$MessageRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);
}

class $$MessageRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessageRowsTable,
          MessageRow,
          $$MessageRowsTableFilterComposer,
          $$MessageRowsTableOrderingComposer,
          $$MessageRowsTableAnnotationComposer,
          $$MessageRowsTableCreateCompanionBuilder,
          $$MessageRowsTableUpdateCompanionBuilder,
          (
            MessageRow,
            BaseReferences<_$AppDatabase, $MessageRowsTable, MessageRow>,
          ),
          MessageRow,
          PrefetchHooks Function()
        > {
  $$MessageRowsTableTableManager(_$AppDatabase db, $MessageRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$MessageRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$MessageRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$MessageRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessageRowsCompanion(
                sessionId: sessionId,
                data: data,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required String data,
                Value<int> rowid = const Value.absent(),
              }) => MessageRowsCompanion.insert(
                sessionId: sessionId,
                data: data,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessageRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessageRowsTable,
      MessageRow,
      $$MessageRowsTableFilterComposer,
      $$MessageRowsTableOrderingComposer,
      $$MessageRowsTableAnnotationComposer,
      $$MessageRowsTableCreateCompanionBuilder,
      $$MessageRowsTableUpdateCompanionBuilder,
      (
        MessageRow,
        BaseReferences<_$AppDatabase, $MessageRowsTable, MessageRow>,
      ),
      MessageRow,
      PrefetchHooks Function()
    >;
typedef $$ModelRowsTableCreateCompanionBuilder =
    ModelRowsCompanion Function({
      required String id,
      required String data,
      Value<int> rowid,
    });
typedef $$ModelRowsTableUpdateCompanionBuilder =
    ModelRowsCompanion Function({
      Value<String> id,
      Value<String> data,
      Value<int> rowid,
    });

class $$ModelRowsTableFilterComposer
    extends Composer<_$AppDatabase, $ModelRowsTable> {
  $$ModelRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ModelRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $ModelRowsTable> {
  $$ModelRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ModelRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ModelRowsTable> {
  $$ModelRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);
}

class $$ModelRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ModelRowsTable,
          ModelRow,
          $$ModelRowsTableFilterComposer,
          $$ModelRowsTableOrderingComposer,
          $$ModelRowsTableAnnotationComposer,
          $$ModelRowsTableCreateCompanionBuilder,
          $$ModelRowsTableUpdateCompanionBuilder,
          (ModelRow, BaseReferences<_$AppDatabase, $ModelRowsTable, ModelRow>),
          ModelRow,
          PrefetchHooks Function()
        > {
  $$ModelRowsTableTableManager(_$AppDatabase db, $ModelRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ModelRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$ModelRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$ModelRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ModelRowsCompanion(id: id, data: data, rowid: rowid),
          createCompanionCallback:
              ({
                required String id,
                required String data,
                Value<int> rowid = const Value.absent(),
              }) => ModelRowsCompanion.insert(id: id, data: data, rowid: rowid),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ModelRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ModelRowsTable,
      ModelRow,
      $$ModelRowsTableFilterComposer,
      $$ModelRowsTableOrderingComposer,
      $$ModelRowsTableAnnotationComposer,
      $$ModelRowsTableCreateCompanionBuilder,
      $$ModelRowsTableUpdateCompanionBuilder,
      (ModelRow, BaseReferences<_$AppDatabase, $ModelRowsTable, ModelRow>),
      ModelRow,
      PrefetchHooks Function()
    >;
typedef $$McpRowsTableCreateCompanionBuilder =
    McpRowsCompanion Function({
      required String name,
      required String data,
      Value<int> rowid,
    });
typedef $$McpRowsTableUpdateCompanionBuilder =
    McpRowsCompanion Function({
      Value<String> name,
      Value<String> data,
      Value<int> rowid,
    });

class $$McpRowsTableFilterComposer
    extends Composer<_$AppDatabase, $McpRowsTable> {
  $$McpRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );
}

class $$McpRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $McpRowsTable> {
  $$McpRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$McpRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $McpRowsTable> {
  $$McpRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);
}

class $$McpRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $McpRowsTable,
          McpRow,
          $$McpRowsTableFilterComposer,
          $$McpRowsTableOrderingComposer,
          $$McpRowsTableAnnotationComposer,
          $$McpRowsTableCreateCompanionBuilder,
          $$McpRowsTableUpdateCompanionBuilder,
          (McpRow, BaseReferences<_$AppDatabase, $McpRowsTable, McpRow>),
          McpRow,
          PrefetchHooks Function()
        > {
  $$McpRowsTableTableManager(_$AppDatabase db, $McpRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$McpRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$McpRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$McpRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => McpRowsCompanion(name: name, data: data, rowid: rowid),
          createCompanionCallback:
              ({
                required String name,
                required String data,
                Value<int> rowid = const Value.absent(),
              }) =>
                  McpRowsCompanion.insert(name: name, data: data, rowid: rowid),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$McpRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $McpRowsTable,
      McpRow,
      $$McpRowsTableFilterComposer,
      $$McpRowsTableOrderingComposer,
      $$McpRowsTableAnnotationComposer,
      $$McpRowsTableCreateCompanionBuilder,
      $$McpRowsTableUpdateCompanionBuilder,
      (McpRow, BaseReferences<_$AppDatabase, $McpRowsTable, McpRow>),
      McpRow,
      PrefetchHooks Function()
    >;
typedef $$SettingRowsTableCreateCompanionBuilder =
    SettingRowsCompanion Function({
      required String key,
      required String data,
      Value<int> rowid,
    });
typedef $$SettingRowsTableUpdateCompanionBuilder =
    SettingRowsCompanion Function({
      Value<String> key,
      Value<String> data,
      Value<int> rowid,
    });

class $$SettingRowsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingRowsTable> {
  $$SettingRowsTableFilterComposer({
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

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingRowsTable> {
  $$SettingRowsTableOrderingComposer({
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

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingRowsTable> {
  $$SettingRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);
}

class $$SettingRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingRowsTable,
          SettingRow,
          $$SettingRowsTableFilterComposer,
          $$SettingRowsTableOrderingComposer,
          $$SettingRowsTableAnnotationComposer,
          $$SettingRowsTableCreateCompanionBuilder,
          $$SettingRowsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $SettingRowsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingRowsTableTableManager(_$AppDatabase db, $SettingRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$SettingRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$SettingRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$SettingRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingRowsCompanion(key: key, data: data, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String data,
                Value<int> rowid = const Value.absent(),
              }) => SettingRowsCompanion.insert(
                key: key,
                data: data,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingRowsTable,
      SettingRow,
      $$SettingRowsTableFilterComposer,
      $$SettingRowsTableOrderingComposer,
      $$SettingRowsTableAnnotationComposer,
      $$SettingRowsTableCreateCompanionBuilder,
      $$SettingRowsTableUpdateCompanionBuilder,
      (
        SettingRow,
        BaseReferences<_$AppDatabase, $SettingRowsTable, SettingRow>,
      ),
      SettingRow,
      PrefetchHooks Function()
    >;
typedef $$AuditRowsTableCreateCompanionBuilder =
    AuditRowsCompanion Function({
      Value<int> id,
      Value<String?> requestId,
      Value<String?> sessionId,
      required int timestamp,
      required String data,
    });
typedef $$AuditRowsTableUpdateCompanionBuilder =
    AuditRowsCompanion Function({
      Value<int> id,
      Value<String?> requestId,
      Value<String?> sessionId,
      Value<int> timestamp,
      Value<String> data,
    });

class $$AuditRowsTableFilterComposer
    extends Composer<_$AppDatabase, $AuditRowsTable> {
  $$AuditRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuditRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditRowsTable> {
  $$AuditRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuditRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditRowsTable> {
  $$AuditRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get requestId =>
      $composableBuilder(column: $table.requestId, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);
}

class $$AuditRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuditRowsTable,
          AuditRow,
          $$AuditRowsTableFilterComposer,
          $$AuditRowsTableOrderingComposer,
          $$AuditRowsTableAnnotationComposer,
          $$AuditRowsTableCreateCompanionBuilder,
          $$AuditRowsTableUpdateCompanionBuilder,
          (AuditRow, BaseReferences<_$AppDatabase, $AuditRowsTable, AuditRow>),
          AuditRow,
          PrefetchHooks Function()
        > {
  $$AuditRowsTableTableManager(_$AppDatabase db, $AuditRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$AuditRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$AuditRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$AuditRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> requestId = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
                Value<String> data = const Value.absent(),
              }) => AuditRowsCompanion(
                id: id,
                requestId: requestId,
                sessionId: sessionId,
                timestamp: timestamp,
                data: data,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> requestId = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                required int timestamp,
                required String data,
              }) => AuditRowsCompanion.insert(
                id: id,
                requestId: requestId,
                sessionId: sessionId,
                timestamp: timestamp,
                data: data,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuditRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuditRowsTable,
      AuditRow,
      $$AuditRowsTableFilterComposer,
      $$AuditRowsTableOrderingComposer,
      $$AuditRowsTableAnnotationComposer,
      $$AuditRowsTableCreateCompanionBuilder,
      $$AuditRowsTableUpdateCompanionBuilder,
      (AuditRow, BaseReferences<_$AppDatabase, $AuditRowsTable, AuditRow>),
      AuditRow,
      PrefetchHooks Function()
    >;
typedef $$UsageRowsTableCreateCompanionBuilder =
    UsageRowsCompanion Function({
      Value<int> id,
      required String detailKey,
      Value<String?> sessionId,
      Value<String?> model,
      required int timestamp,
      required String data,
    });
typedef $$UsageRowsTableUpdateCompanionBuilder =
    UsageRowsCompanion Function({
      Value<int> id,
      Value<String> detailKey,
      Value<String?> sessionId,
      Value<String?> model,
      Value<int> timestamp,
      Value<String> data,
    });

class $$UsageRowsTableFilterComposer
    extends Composer<_$AppDatabase, $UsageRowsTable> {
  $$UsageRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detailKey => $composableBuilder(
    column: $table.detailKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsageRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $UsageRowsTable> {
  $$UsageRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detailKey => $composableBuilder(
    column: $table.detailKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsageRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsageRowsTable> {
  $$UsageRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get detailKey =>
      $composableBuilder(column: $table.detailKey, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);
}

class $$UsageRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsageRowsTable,
          UsageRow,
          $$UsageRowsTableFilterComposer,
          $$UsageRowsTableOrderingComposer,
          $$UsageRowsTableAnnotationComposer,
          $$UsageRowsTableCreateCompanionBuilder,
          $$UsageRowsTableUpdateCompanionBuilder,
          (UsageRow, BaseReferences<_$AppDatabase, $UsageRowsTable, UsageRow>),
          UsageRow,
          PrefetchHooks Function()
        > {
  $$UsageRowsTableTableManager(_$AppDatabase db, $UsageRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$UsageRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$UsageRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$UsageRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> detailKey = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
                Value<String> data = const Value.absent(),
              }) => UsageRowsCompanion(
                id: id,
                detailKey: detailKey,
                sessionId: sessionId,
                model: model,
                timestamp: timestamp,
                data: data,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String detailKey,
                Value<String?> sessionId = const Value.absent(),
                Value<String?> model = const Value.absent(),
                required int timestamp,
                required String data,
              }) => UsageRowsCompanion.insert(
                id: id,
                detailKey: detailKey,
                sessionId: sessionId,
                model: model,
                timestamp: timestamp,
                data: data,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsageRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsageRowsTable,
      UsageRow,
      $$UsageRowsTableFilterComposer,
      $$UsageRowsTableOrderingComposer,
      $$UsageRowsTableAnnotationComposer,
      $$UsageRowsTableCreateCompanionBuilder,
      $$UsageRowsTableUpdateCompanionBuilder,
      (UsageRow, BaseReferences<_$AppDatabase, $UsageRowsTable, UsageRow>),
      UsageRow,
      PrefetchHooks Function()
    >;
typedef $$VendorKeyRowsTableCreateCompanionBuilder =
    VendorKeyRowsCompanion Function({
      required String vendorId,
      required String apiKey,
      required String updatedAt,
      Value<int> rowid,
    });
typedef $$VendorKeyRowsTableUpdateCompanionBuilder =
    VendorKeyRowsCompanion Function({
      Value<String> vendorId,
      Value<String> apiKey,
      Value<String> updatedAt,
      Value<int> rowid,
    });

class $$VendorKeyRowsTableFilterComposer
    extends Composer<_$AppDatabase, $VendorKeyRowsTable> {
  $$VendorKeyRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get vendorId => $composableBuilder(
    column: $table.vendorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get apiKey => $composableBuilder(
    column: $table.apiKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VendorKeyRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $VendorKeyRowsTable> {
  $$VendorKeyRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get vendorId => $composableBuilder(
    column: $table.vendorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get apiKey => $composableBuilder(
    column: $table.apiKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VendorKeyRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VendorKeyRowsTable> {
  $$VendorKeyRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get vendorId =>
      $composableBuilder(column: $table.vendorId, builder: (column) => column);

  GeneratedColumn<String> get apiKey =>
      $composableBuilder(column: $table.apiKey, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$VendorKeyRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VendorKeyRowsTable,
          VendorKeyRow,
          $$VendorKeyRowsTableFilterComposer,
          $$VendorKeyRowsTableOrderingComposer,
          $$VendorKeyRowsTableAnnotationComposer,
          $$VendorKeyRowsTableCreateCompanionBuilder,
          $$VendorKeyRowsTableUpdateCompanionBuilder,
          (
            VendorKeyRow,
            BaseReferences<_$AppDatabase, $VendorKeyRowsTable, VendorKeyRow>,
          ),
          VendorKeyRow,
          PrefetchHooks Function()
        > {
  $$VendorKeyRowsTableTableManager(_$AppDatabase db, $VendorKeyRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$VendorKeyRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$VendorKeyRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$VendorKeyRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> vendorId = const Value.absent(),
                Value<String> apiKey = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VendorKeyRowsCompanion(
                vendorId: vendorId,
                apiKey: apiKey,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String vendorId,
                required String apiKey,
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => VendorKeyRowsCompanion.insert(
                vendorId: vendorId,
                apiKey: apiKey,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VendorKeyRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VendorKeyRowsTable,
      VendorKeyRow,
      $$VendorKeyRowsTableFilterComposer,
      $$VendorKeyRowsTableOrderingComposer,
      $$VendorKeyRowsTableAnnotationComposer,
      $$VendorKeyRowsTableCreateCompanionBuilder,
      $$VendorKeyRowsTableUpdateCompanionBuilder,
      (
        VendorKeyRow,
        BaseReferences<_$AppDatabase, $VendorKeyRowsTable, VendorKeyRow>,
      ),
      VendorKeyRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SessionRowsTableTableManager get sessionRows =>
      $$SessionRowsTableTableManager(_db, _db.sessionRows);
  $$MessageRowsTableTableManager get messageRows =>
      $$MessageRowsTableTableManager(_db, _db.messageRows);
  $$ModelRowsTableTableManager get modelRows =>
      $$ModelRowsTableTableManager(_db, _db.modelRows);
  $$McpRowsTableTableManager get mcpRows =>
      $$McpRowsTableTableManager(_db, _db.mcpRows);
  $$SettingRowsTableTableManager get settingRows =>
      $$SettingRowsTableTableManager(_db, _db.settingRows);
  $$AuditRowsTableTableManager get auditRows =>
      $$AuditRowsTableTableManager(_db, _db.auditRows);
  $$UsageRowsTableTableManager get usageRows =>
      $$UsageRowsTableTableManager(_db, _db.usageRows);
  $$VendorKeyRowsTableTableManager get vendorKeyRows =>
      $$VendorKeyRowsTableTableManager(_db, _db.vendorKeyRows);
}
