// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_models.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarChatModelCollection on Isar {
  IsarCollection<IsarChatModel> get isarChatModels => this.collection();
}

const IsarChatModelSchema = CollectionSchema(
  name: r'IsarChatModel',
  id: 219756321204894702,
  properties: {
    r'apiKey': PropertySchema(
      id: 0,
      name: r'apiKey',
      type: IsarType.string,
    ),
    r'apiUrl': PropertySchema(
      id: 1,
      name: r'apiUrl',
      type: IsarType.string,
    ),
    r'chatCommandsJson': PropertySchema(
      id: 2,
      name: r'chatCommandsJson',
      type: IsarType.string,
    ),
    r'chatSettingsJson': PropertySchema(
      id: 3,
      name: r'chatSettingsJson',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 4,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'description': PropertySchema(
      id: 5,
      name: r'description',
      type: IsarType.string,
    ),
    r'mcpServicesJson': PropertySchema(
      id: 6,
      name: r'mcpServicesJson',
      type: IsarType.string,
    ),
    r'model': PropertySchema(
      id: 7,
      name: r'model',
      type: IsarType.string,
    ),
    r'modelId': PropertySchema(
      id: 8,
      name: r'modelId',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 9,
      name: r'name',
      type: IsarType.string,
    ),
    r'provider': PropertySchema(
      id: 10,
      name: r'provider',
      type: IsarType.string,
    ),
    r'skillsJson': PropertySchema(
      id: 11,
      name: r'skillsJson',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 12,
      name: r'status',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 13,
      name: r'type',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 14,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _isarChatModelEstimateSize,
  serialize: _isarChatModelSerialize,
  deserialize: _isarChatModelDeserialize,
  deserializeProp: _isarChatModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'modelId': IndexSchema(
      id: -1910745378942518156,
      name: r'modelId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'modelId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'type': IndexSchema(
      id: 5117122708147080838,
      name: r'type',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'type',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'provider': IndexSchema(
      id: -6343122774420421053,
      name: r'provider',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'provider',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarChatModelGetId,
  getLinks: _isarChatModelGetLinks,
  attach: _isarChatModelAttach,
  version: '3.1.0+1',
);

int _isarChatModelEstimateSize(
  IsarChatModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.apiKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.apiUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.chatCommandsJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.chatSettingsJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.mcpServicesJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.model.length * 3;
  bytesCount += 3 + object.modelId.length * 3;
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.provider;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.skillsJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.status.length * 3;
  {
    final value = object.type;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _isarChatModelSerialize(
  IsarChatModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.apiKey);
  writer.writeString(offsets[1], object.apiUrl);
  writer.writeString(offsets[2], object.chatCommandsJson);
  writer.writeString(offsets[3], object.chatSettingsJson);
  writer.writeDateTime(offsets[4], object.createdAt);
  writer.writeString(offsets[5], object.description);
  writer.writeString(offsets[6], object.mcpServicesJson);
  writer.writeString(offsets[7], object.model);
  writer.writeString(offsets[8], object.modelId);
  writer.writeString(offsets[9], object.name);
  writer.writeString(offsets[10], object.provider);
  writer.writeString(offsets[11], object.skillsJson);
  writer.writeString(offsets[12], object.status);
  writer.writeString(offsets[13], object.type);
  writer.writeDateTime(offsets[14], object.updatedAt);
}

IsarChatModel _isarChatModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarChatModel();
  object.apiKey = reader.readStringOrNull(offsets[0]);
  object.apiUrl = reader.readStringOrNull(offsets[1]);
  object.chatCommandsJson = reader.readStringOrNull(offsets[2]);
  object.chatSettingsJson = reader.readStringOrNull(offsets[3]);
  object.createdAt = reader.readDateTimeOrNull(offsets[4]);
  object.description = reader.readStringOrNull(offsets[5]);
  object.id = id;
  object.mcpServicesJson = reader.readStringOrNull(offsets[6]);
  object.model = reader.readString(offsets[7]);
  object.modelId = reader.readString(offsets[8]);
  object.name = reader.readString(offsets[9]);
  object.provider = reader.readStringOrNull(offsets[10]);
  object.skillsJson = reader.readStringOrNull(offsets[11]);
  object.status = reader.readString(offsets[12]);
  object.type = reader.readStringOrNull(offsets[13]);
  object.updatedAt = reader.readDateTimeOrNull(offsets[14]);
  return object;
}

P _isarChatModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarChatModelGetId(IsarChatModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarChatModelGetLinks(IsarChatModel object) {
  return [];
}

void _isarChatModelAttach(
    IsarCollection<dynamic> col, Id id, IsarChatModel object) {
  object.id = id;
}

extension IsarChatModelByIndex on IsarCollection<IsarChatModel> {
  Future<IsarChatModel?> getByModelId(String modelId) {
    return getByIndex(r'modelId', [modelId]);
  }

  IsarChatModel? getByModelIdSync(String modelId) {
    return getByIndexSync(r'modelId', [modelId]);
  }

  Future<bool> deleteByModelId(String modelId) {
    return deleteByIndex(r'modelId', [modelId]);
  }

  bool deleteByModelIdSync(String modelId) {
    return deleteByIndexSync(r'modelId', [modelId]);
  }

  Future<List<IsarChatModel?>> getAllByModelId(List<String> modelIdValues) {
    final values = modelIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'modelId', values);
  }

  List<IsarChatModel?> getAllByModelIdSync(List<String> modelIdValues) {
    final values = modelIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'modelId', values);
  }

  Future<int> deleteAllByModelId(List<String> modelIdValues) {
    final values = modelIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'modelId', values);
  }

  int deleteAllByModelIdSync(List<String> modelIdValues) {
    final values = modelIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'modelId', values);
  }

  Future<Id> putByModelId(IsarChatModel object) {
    return putByIndex(r'modelId', object);
  }

  Id putByModelIdSync(IsarChatModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'modelId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByModelId(List<IsarChatModel> objects) {
    return putAllByIndex(r'modelId', objects);
  }

  List<Id> putAllByModelIdSync(List<IsarChatModel> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'modelId', objects, saveLinks: saveLinks);
  }
}

extension IsarChatModelQueryWhereSort
    on QueryBuilder<IsarChatModel, IsarChatModel, QWhere> {
  QueryBuilder<IsarChatModel, IsarChatModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarChatModelQueryWhere
    on QueryBuilder<IsarChatModel, IsarChatModel, QWhereClause> {
  QueryBuilder<IsarChatModel, IsarChatModel, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterWhereClause> modelIdEqualTo(
      String modelId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'modelId',
        value: [modelId],
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterWhereClause>
      modelIdNotEqualTo(String modelId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'modelId',
              lower: [],
              upper: [modelId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'modelId',
              lower: [modelId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'modelId',
              lower: [modelId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'modelId',
              lower: [],
              upper: [modelId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterWhereClause> typeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'type',
        value: [null],
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterWhereClause>
      typeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'type',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterWhereClause> typeEqualTo(
      String? type) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'type',
        value: [type],
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterWhereClause> typeNotEqualTo(
      String? type) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [],
              upper: [type],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [type],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [type],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [],
              upper: [type],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterWhereClause>
      providerIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'provider',
        value: [null],
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterWhereClause>
      providerIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'provider',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterWhereClause> providerEqualTo(
      String? provider) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'provider',
        value: [provider],
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterWhereClause>
      providerNotEqualTo(String? provider) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'provider',
              lower: [],
              upper: [provider],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'provider',
              lower: [provider],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'provider',
              lower: [provider],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'provider',
              lower: [],
              upper: [provider],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarChatModelQueryFilter
    on QueryBuilder<IsarChatModel, IsarChatModel, QFilterCondition> {
  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      apiKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'apiKey',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      apiKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'apiKey',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      apiKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'apiKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      apiKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'apiKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      apiKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'apiKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      apiKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'apiKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      apiKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'apiKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      apiKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'apiKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      apiKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'apiKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      apiKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'apiKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      apiKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'apiKey',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      apiKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'apiKey',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      apiUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'apiUrl',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      apiUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'apiUrl',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      apiUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'apiUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      apiUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'apiUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      apiUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'apiUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      apiUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'apiUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      apiUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'apiUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      apiUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'apiUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      apiUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'apiUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      apiUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'apiUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      apiUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'apiUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      apiUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'apiUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      chatCommandsJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'chatCommandsJson',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      chatCommandsJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'chatCommandsJson',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      chatCommandsJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chatCommandsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      chatCommandsJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'chatCommandsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      chatCommandsJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'chatCommandsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      chatCommandsJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'chatCommandsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      chatCommandsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'chatCommandsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      chatCommandsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'chatCommandsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      chatCommandsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'chatCommandsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      chatCommandsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'chatCommandsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      chatCommandsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chatCommandsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      chatCommandsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'chatCommandsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      chatSettingsJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'chatSettingsJson',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      chatSettingsJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'chatSettingsJson',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      chatSettingsJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chatSettingsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      chatSettingsJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'chatSettingsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      chatSettingsJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'chatSettingsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      chatSettingsJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'chatSettingsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      chatSettingsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'chatSettingsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      chatSettingsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'chatSettingsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      chatSettingsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'chatSettingsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      chatSettingsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'chatSettingsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      chatSettingsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chatSettingsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      chatSettingsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'chatSettingsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      createdAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      createdAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      createdAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      createdAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      createdAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      descriptionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      descriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      descriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      descriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      mcpServicesJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mcpServicesJson',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      mcpServicesJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mcpServicesJson',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      mcpServicesJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mcpServicesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      mcpServicesJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mcpServicesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      mcpServicesJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mcpServicesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      mcpServicesJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mcpServicesJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      mcpServicesJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mcpServicesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      mcpServicesJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mcpServicesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      mcpServicesJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mcpServicesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      mcpServicesJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mcpServicesJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      mcpServicesJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mcpServicesJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      mcpServicesJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mcpServicesJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      modelEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'model',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      modelGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'model',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      modelLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'model',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      modelBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'model',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      modelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'model',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      modelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'model',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      modelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'model',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      modelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'model',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      modelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'model',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      modelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'model',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      modelIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'modelId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      modelIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'modelId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      modelIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'modelId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      modelIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'modelId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      modelIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'modelId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      modelIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'modelId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      modelIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'modelId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      modelIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'modelId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      modelIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'modelId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      modelIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'modelId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      providerIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'provider',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      providerIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'provider',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      providerEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      providerGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      providerLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      providerBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'provider',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      providerStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      providerEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      providerContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      providerMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'provider',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      providerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'provider',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      providerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'provider',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      skillsJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'skillsJson',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      skillsJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'skillsJson',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      skillsJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'skillsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      skillsJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'skillsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      skillsJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'skillsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      skillsJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'skillsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      skillsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'skillsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      skillsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'skillsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      skillsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'skillsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      skillsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'skillsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      skillsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'skillsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      skillsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'skillsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      statusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      typeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'type',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      typeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'type',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition> typeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      typeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      typeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition> typeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition> typeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      updatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      updatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IsarChatModelQueryObject
    on QueryBuilder<IsarChatModel, IsarChatModel, QFilterCondition> {}

extension IsarChatModelQueryLinks
    on QueryBuilder<IsarChatModel, IsarChatModel, QFilterCondition> {}

extension IsarChatModelQuerySortBy
    on QueryBuilder<IsarChatModel, IsarChatModel, QSortBy> {
  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> sortByApiKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiKey', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> sortByApiKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiKey', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> sortByApiUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiUrl', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> sortByApiUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiUrl', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy>
      sortByChatCommandsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chatCommandsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy>
      sortByChatCommandsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chatCommandsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy>
      sortByChatSettingsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chatSettingsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy>
      sortByChatSettingsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chatSettingsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy>
      sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy>
      sortByMcpServicesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mcpServicesJson', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy>
      sortByMcpServicesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mcpServicesJson', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> sortByModel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'model', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> sortByModelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'model', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> sortByModelId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelId', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> sortByModelIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelId', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> sortByProvider() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'provider', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy>
      sortByProviderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'provider', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> sortBySkillsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skillsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy>
      sortBySkillsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skillsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension IsarChatModelQuerySortThenBy
    on QueryBuilder<IsarChatModel, IsarChatModel, QSortThenBy> {
  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> thenByApiKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiKey', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> thenByApiKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiKey', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> thenByApiUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiUrl', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> thenByApiUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiUrl', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy>
      thenByChatCommandsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chatCommandsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy>
      thenByChatCommandsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chatCommandsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy>
      thenByChatSettingsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chatSettingsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy>
      thenByChatSettingsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chatSettingsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy>
      thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy>
      thenByMcpServicesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mcpServicesJson', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy>
      thenByMcpServicesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mcpServicesJson', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> thenByModel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'model', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> thenByModelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'model', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> thenByModelId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelId', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> thenByModelIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelId', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> thenByProvider() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'provider', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy>
      thenByProviderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'provider', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> thenBySkillsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skillsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy>
      thenBySkillsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skillsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension IsarChatModelQueryWhereDistinct
    on QueryBuilder<IsarChatModel, IsarChatModel, QDistinct> {
  QueryBuilder<IsarChatModel, IsarChatModel, QDistinct> distinctByApiKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'apiKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QDistinct> distinctByApiUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'apiUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QDistinct>
      distinctByChatCommandsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'chatCommandsJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QDistinct>
      distinctByChatSettingsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'chatSettingsJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QDistinct>
      distinctByMcpServicesJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mcpServicesJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QDistinct> distinctByModel(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'model', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QDistinct> distinctByModelId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'modelId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QDistinct> distinctByProvider(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'provider', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QDistinct> distinctBySkillsJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'skillsJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QDistinct> distinctByType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension IsarChatModelQueryProperty
    on QueryBuilder<IsarChatModel, IsarChatModel, QQueryProperty> {
  QueryBuilder<IsarChatModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarChatModel, String?, QQueryOperations> apiKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'apiKey');
    });
  }

  QueryBuilder<IsarChatModel, String?, QQueryOperations> apiUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'apiUrl');
    });
  }

  QueryBuilder<IsarChatModel, String?, QQueryOperations>
      chatCommandsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'chatCommandsJson');
    });
  }

  QueryBuilder<IsarChatModel, String?, QQueryOperations>
      chatSettingsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'chatSettingsJson');
    });
  }

  QueryBuilder<IsarChatModel, DateTime?, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<IsarChatModel, String?, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<IsarChatModel, String?, QQueryOperations>
      mcpServicesJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mcpServicesJson');
    });
  }

  QueryBuilder<IsarChatModel, String, QQueryOperations> modelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'model');
    });
  }

  QueryBuilder<IsarChatModel, String, QQueryOperations> modelIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'modelId');
    });
  }

  QueryBuilder<IsarChatModel, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<IsarChatModel, String?, QQueryOperations> providerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'provider');
    });
  }

  QueryBuilder<IsarChatModel, String?, QQueryOperations> skillsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'skillsJson');
    });
  }

  QueryBuilder<IsarChatModel, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<IsarChatModel, String?, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<IsarChatModel, DateTime?, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarChatSessionCollection on Isar {
  IsarCollection<IsarChatSession> get isarChatSessions => this.collection();
}

const IsarChatSessionSchema = CollectionSchema(
  name: r'IsarChatSession',
  id: -2190692605320253250,
  properties: {
    r'attachmentsJson': PropertySchema(
      id: 0,
      name: r'attachmentsJson',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'deepThink': PropertySchema(
      id: 2,
      name: r'deepThink',
      type: IsarType.bool,
    ),
    r'inputContent': PropertySchema(
      id: 3,
      name: r'inputContent',
      type: IsarType.string,
    ),
    r'isCurrent': PropertySchema(
      id: 4,
      name: r'isCurrent',
      type: IsarType.bool,
    ),
    r'isFavorite': PropertySchema(
      id: 5,
      name: r'isFavorite',
      type: IsarType.bool,
    ),
    r'isSending': PropertySchema(
      id: 6,
      name: r'isSending',
      type: IsarType.bool,
    ),
    r'lastSelectedDirectory': PropertySchema(
      id: 7,
      name: r'lastSelectedDirectory',
      type: IsarType.string,
    ),
    r'mcpServerJson': PropertySchema(
      id: 8,
      name: r'mcpServerJson',
      type: IsarType.string,
    ),
    r'memoryRounds': PropertySchema(
      id: 9,
      name: r'memoryRounds',
      type: IsarType.long,
    ),
    r'messagesJson': PropertySchema(
      id: 10,
      name: r'messagesJson',
      type: IsarType.string,
    ),
    r'modelId': PropertySchema(
      id: 11,
      name: r'modelId',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 12,
      name: r'name',
      type: IsarType.string,
    ),
    r'scrollPosition': PropertySchema(
      id: 13,
      name: r'scrollPosition',
      type: IsarType.double,
    ),
    r'sessionId': PropertySchema(
      id: 14,
      name: r'sessionId',
      type: IsarType.string,
    ),
    r'sessionQuickCommandsJson': PropertySchema(
      id: 15,
      name: r'sessionQuickCommandsJson',
      type: IsarType.string,
    ),
    r'shouldStopResponse': PropertySchema(
      id: 16,
      name: r'shouldStopResponse',
      type: IsarType.bool,
    ),
    r'skillJson': PropertySchema(
      id: 17,
      name: r'skillJson',
      type: IsarType.string,
    ),
    r'workDirectory': PropertySchema(
      id: 18,
      name: r'workDirectory',
      type: IsarType.string,
    )
  },
  estimateSize: _isarChatSessionEstimateSize,
  serialize: _isarChatSessionSerialize,
  deserialize: _isarChatSessionDeserialize,
  deserializeProp: _isarChatSessionDeserializeProp,
  idName: r'id',
  indexes: {
    r'sessionId': IndexSchema(
      id: 6949518585047923839,
      name: r'sessionId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'sessionId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'isCurrent': IndexSchema(
      id: -8698398489692661776,
      name: r'isCurrent',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isCurrent',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarChatSessionGetId,
  getLinks: _isarChatSessionGetLinks,
  attach: _isarChatSessionAttach,
  version: '3.1.0+1',
);

int _isarChatSessionEstimateSize(
  IsarChatSession object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.attachmentsJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.inputContent.length * 3;
  {
    final value = object.lastSelectedDirectory;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.mcpServerJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.messagesJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.modelId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.sessionId.length * 3;
  {
    final value = object.sessionQuickCommandsJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.skillJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.workDirectory;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _isarChatSessionSerialize(
  IsarChatSession object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.attachmentsJson);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeBool(offsets[2], object.deepThink);
  writer.writeString(offsets[3], object.inputContent);
  writer.writeBool(offsets[4], object.isCurrent);
  writer.writeBool(offsets[5], object.isFavorite);
  writer.writeBool(offsets[6], object.isSending);
  writer.writeString(offsets[7], object.lastSelectedDirectory);
  writer.writeString(offsets[8], object.mcpServerJson);
  writer.writeLong(offsets[9], object.memoryRounds);
  writer.writeString(offsets[10], object.messagesJson);
  writer.writeString(offsets[11], object.modelId);
  writer.writeString(offsets[12], object.name);
  writer.writeDouble(offsets[13], object.scrollPosition);
  writer.writeString(offsets[14], object.sessionId);
  writer.writeString(offsets[15], object.sessionQuickCommandsJson);
  writer.writeBool(offsets[16], object.shouldStopResponse);
  writer.writeString(offsets[17], object.skillJson);
  writer.writeString(offsets[18], object.workDirectory);
}

IsarChatSession _isarChatSessionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarChatSession();
  object.attachmentsJson = reader.readStringOrNull(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.deepThink = reader.readBool(offsets[2]);
  object.id = id;
  object.inputContent = reader.readString(offsets[3]);
  object.isCurrent = reader.readBool(offsets[4]);
  object.isFavorite = reader.readBool(offsets[5]);
  object.isSending = reader.readBool(offsets[6]);
  object.lastSelectedDirectory = reader.readStringOrNull(offsets[7]);
  object.mcpServerJson = reader.readStringOrNull(offsets[8]);
  object.memoryRounds = reader.readLong(offsets[9]);
  object.messagesJson = reader.readStringOrNull(offsets[10]);
  object.modelId = reader.readStringOrNull(offsets[11]);
  object.name = reader.readString(offsets[12]);
  object.scrollPosition = reader.readDouble(offsets[13]);
  object.sessionId = reader.readString(offsets[14]);
  object.sessionQuickCommandsJson = reader.readStringOrNull(offsets[15]);
  object.shouldStopResponse = reader.readBool(offsets[16]);
  object.skillJson = reader.readStringOrNull(offsets[17]);
  object.workDirectory = reader.readStringOrNull(offsets[18]);
  return object;
}

P _isarChatSessionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readDouble(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readBool(offset)) as P;
    case 17:
      return (reader.readStringOrNull(offset)) as P;
    case 18:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarChatSessionGetId(IsarChatSession object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarChatSessionGetLinks(IsarChatSession object) {
  return [];
}

void _isarChatSessionAttach(
    IsarCollection<dynamic> col, Id id, IsarChatSession object) {
  object.id = id;
}

extension IsarChatSessionByIndex on IsarCollection<IsarChatSession> {
  Future<IsarChatSession?> getBySessionId(String sessionId) {
    return getByIndex(r'sessionId', [sessionId]);
  }

  IsarChatSession? getBySessionIdSync(String sessionId) {
    return getByIndexSync(r'sessionId', [sessionId]);
  }

  Future<bool> deleteBySessionId(String sessionId) {
    return deleteByIndex(r'sessionId', [sessionId]);
  }

  bool deleteBySessionIdSync(String sessionId) {
    return deleteByIndexSync(r'sessionId', [sessionId]);
  }

  Future<List<IsarChatSession?>> getAllBySessionId(
      List<String> sessionIdValues) {
    final values = sessionIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'sessionId', values);
  }

  List<IsarChatSession?> getAllBySessionIdSync(List<String> sessionIdValues) {
    final values = sessionIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'sessionId', values);
  }

  Future<int> deleteAllBySessionId(List<String> sessionIdValues) {
    final values = sessionIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'sessionId', values);
  }

  int deleteAllBySessionIdSync(List<String> sessionIdValues) {
    final values = sessionIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'sessionId', values);
  }

  Future<Id> putBySessionId(IsarChatSession object) {
    return putByIndex(r'sessionId', object);
  }

  Id putBySessionIdSync(IsarChatSession object, {bool saveLinks = true}) {
    return putByIndexSync(r'sessionId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySessionId(List<IsarChatSession> objects) {
    return putAllByIndex(r'sessionId', objects);
  }

  List<Id> putAllBySessionIdSync(List<IsarChatSession> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'sessionId', objects, saveLinks: saveLinks);
  }
}

extension IsarChatSessionQueryWhereSort
    on QueryBuilder<IsarChatSession, IsarChatSession, QWhere> {
  QueryBuilder<IsarChatSession, IsarChatSession, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterWhere> anyIsCurrent() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isCurrent'),
      );
    });
  }
}

extension IsarChatSessionQueryWhere
    on QueryBuilder<IsarChatSession, IsarChatSession, QWhereClause> {
  QueryBuilder<IsarChatSession, IsarChatSession, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterWhereClause>
      sessionIdEqualTo(String sessionId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sessionId',
        value: [sessionId],
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterWhereClause>
      sessionIdNotEqualTo(String sessionId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionId',
              lower: [],
              upper: [sessionId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionId',
              lower: [sessionId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionId',
              lower: [sessionId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionId',
              lower: [],
              upper: [sessionId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterWhereClause>
      isCurrentEqualTo(bool isCurrent) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isCurrent',
        value: [isCurrent],
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterWhereClause>
      isCurrentNotEqualTo(bool isCurrent) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isCurrent',
              lower: [],
              upper: [isCurrent],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isCurrent',
              lower: [isCurrent],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isCurrent',
              lower: [isCurrent],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isCurrent',
              lower: [],
              upper: [isCurrent],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarChatSessionQueryFilter
    on QueryBuilder<IsarChatSession, IsarChatSession, QFilterCondition> {
  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      attachmentsJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'attachmentsJson',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      attachmentsJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'attachmentsJson',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      attachmentsJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'attachmentsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      attachmentsJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'attachmentsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      attachmentsJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'attachmentsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      attachmentsJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'attachmentsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      attachmentsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'attachmentsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      attachmentsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'attachmentsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      attachmentsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'attachmentsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      attachmentsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'attachmentsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      attachmentsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'attachmentsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      attachmentsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'attachmentsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      deepThinkEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deepThink',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      inputContentEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'inputContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      inputContentGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'inputContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      inputContentLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'inputContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      inputContentBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'inputContent',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      inputContentStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'inputContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      inputContentEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'inputContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      inputContentContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'inputContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      inputContentMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'inputContent',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      inputContentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'inputContent',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      inputContentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'inputContent',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      isCurrentEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isCurrent',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      isFavoriteEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isFavorite',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      isSendingEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSending',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      lastSelectedDirectoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSelectedDirectory',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      lastSelectedDirectoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSelectedDirectory',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      lastSelectedDirectoryEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSelectedDirectory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      lastSelectedDirectoryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSelectedDirectory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      lastSelectedDirectoryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSelectedDirectory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      lastSelectedDirectoryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSelectedDirectory',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      lastSelectedDirectoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastSelectedDirectory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      lastSelectedDirectoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastSelectedDirectory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      lastSelectedDirectoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastSelectedDirectory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      lastSelectedDirectoryMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastSelectedDirectory',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      lastSelectedDirectoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSelectedDirectory',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      lastSelectedDirectoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastSelectedDirectory',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      mcpServerJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mcpServerJson',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      mcpServerJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mcpServerJson',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      mcpServerJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mcpServerJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      mcpServerJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mcpServerJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      mcpServerJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mcpServerJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      mcpServerJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mcpServerJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      mcpServerJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mcpServerJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      mcpServerJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mcpServerJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      mcpServerJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mcpServerJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      mcpServerJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mcpServerJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      mcpServerJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mcpServerJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      mcpServerJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mcpServerJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      memoryRoundsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'memoryRounds',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      memoryRoundsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'memoryRounds',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      memoryRoundsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'memoryRounds',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      memoryRoundsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'memoryRounds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      messagesJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'messagesJson',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      messagesJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'messagesJson',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      messagesJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'messagesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      messagesJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'messagesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      messagesJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'messagesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      messagesJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'messagesJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      messagesJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'messagesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      messagesJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'messagesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      messagesJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'messagesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      messagesJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'messagesJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      messagesJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'messagesJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      messagesJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'messagesJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      modelIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'modelId',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      modelIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'modelId',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      modelIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'modelId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      modelIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'modelId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      modelIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'modelId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      modelIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'modelId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      modelIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'modelId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      modelIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'modelId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      modelIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'modelId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      modelIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'modelId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      modelIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'modelId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      modelIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'modelId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      scrollPositionEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scrollPosition',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      scrollPositionGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scrollPosition',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      scrollPositionLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scrollPosition',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      scrollPositionBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scrollPosition',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      sessionIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      sessionIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      sessionIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      sessionIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sessionId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      sessionIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      sessionIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      sessionIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      sessionIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sessionId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      sessionIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      sessionIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sessionId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      sessionQuickCommandsJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sessionQuickCommandsJson',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      sessionQuickCommandsJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sessionQuickCommandsJson',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      sessionQuickCommandsJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionQuickCommandsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      sessionQuickCommandsJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sessionQuickCommandsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      sessionQuickCommandsJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sessionQuickCommandsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      sessionQuickCommandsJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sessionQuickCommandsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      sessionQuickCommandsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sessionQuickCommandsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      sessionQuickCommandsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sessionQuickCommandsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      sessionQuickCommandsJsonContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sessionQuickCommandsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      sessionQuickCommandsJsonMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sessionQuickCommandsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      sessionQuickCommandsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionQuickCommandsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      sessionQuickCommandsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sessionQuickCommandsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      shouldStopResponseEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'shouldStopResponse',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      skillJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'skillJson',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      skillJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'skillJson',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      skillJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'skillJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      skillJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'skillJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      skillJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'skillJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      skillJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'skillJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      skillJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'skillJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      skillJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'skillJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      skillJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'skillJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      skillJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'skillJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      skillJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'skillJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      skillJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'skillJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      workDirectoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'workDirectory',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      workDirectoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'workDirectory',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      workDirectoryEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'workDirectory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      workDirectoryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'workDirectory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      workDirectoryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'workDirectory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      workDirectoryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'workDirectory',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      workDirectoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'workDirectory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      workDirectoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'workDirectory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      workDirectoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'workDirectory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      workDirectoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'workDirectory',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      workDirectoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'workDirectory',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      workDirectoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'workDirectory',
        value: '',
      ));
    });
  }
}

extension IsarChatSessionQueryObject
    on QueryBuilder<IsarChatSession, IsarChatSession, QFilterCondition> {}

extension IsarChatSessionQueryLinks
    on QueryBuilder<IsarChatSession, IsarChatSession, QFilterCondition> {}

extension IsarChatSessionQuerySortBy
    on QueryBuilder<IsarChatSession, IsarChatSession, QSortBy> {
  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByAttachmentsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attachmentsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByAttachmentsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attachmentsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByDeepThink() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deepThink', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByDeepThinkDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deepThink', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByInputContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inputContent', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByInputContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inputContent', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByIsCurrent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCurrent', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByIsCurrentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCurrent', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByIsSending() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSending', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByIsSendingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSending', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByLastSelectedDirectory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSelectedDirectory', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByLastSelectedDirectoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSelectedDirectory', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByMcpServerJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mcpServerJson', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByMcpServerJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mcpServerJson', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByMemoryRounds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memoryRounds', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByMemoryRoundsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memoryRounds', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByMessagesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messagesJson', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByMessagesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messagesJson', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy> sortByModelId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelId', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByModelIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelId', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByScrollPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scrollPosition', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByScrollPositionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scrollPosition', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortBySessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortBySessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortBySessionQuickCommandsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionQuickCommandsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortBySessionQuickCommandsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionQuickCommandsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByShouldStopResponse() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shouldStopResponse', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByShouldStopResponseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shouldStopResponse', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortBySkillJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skillJson', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortBySkillJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skillJson', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByWorkDirectory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workDirectory', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByWorkDirectoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workDirectory', Sort.desc);
    });
  }
}

extension IsarChatSessionQuerySortThenBy
    on QueryBuilder<IsarChatSession, IsarChatSession, QSortThenBy> {
  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByAttachmentsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attachmentsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByAttachmentsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attachmentsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByDeepThink() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deepThink', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByDeepThinkDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deepThink', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByInputContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inputContent', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByInputContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inputContent', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByIsCurrent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCurrent', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByIsCurrentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCurrent', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByIsSending() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSending', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByIsSendingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSending', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByLastSelectedDirectory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSelectedDirectory', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByLastSelectedDirectoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSelectedDirectory', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByMcpServerJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mcpServerJson', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByMcpServerJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mcpServerJson', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByMemoryRounds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memoryRounds', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByMemoryRoundsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memoryRounds', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByMessagesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messagesJson', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByMessagesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messagesJson', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy> thenByModelId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelId', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByModelIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelId', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByScrollPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scrollPosition', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByScrollPositionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scrollPosition', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenBySessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenBySessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenBySessionQuickCommandsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionQuickCommandsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenBySessionQuickCommandsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionQuickCommandsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByShouldStopResponse() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shouldStopResponse', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByShouldStopResponseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shouldStopResponse', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenBySkillJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skillJson', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenBySkillJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skillJson', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByWorkDirectory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workDirectory', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByWorkDirectoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workDirectory', Sort.desc);
    });
  }
}

extension IsarChatSessionQueryWhereDistinct
    on QueryBuilder<IsarChatSession, IsarChatSession, QDistinct> {
  QueryBuilder<IsarChatSession, IsarChatSession, QDistinct>
      distinctByAttachmentsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'attachmentsJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QDistinct>
      distinctByDeepThink() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deepThink');
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QDistinct>
      distinctByInputContent({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'inputContent', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QDistinct>
      distinctByIsCurrent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isCurrent');
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QDistinct>
      distinctByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFavorite');
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QDistinct>
      distinctByIsSending() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSending');
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QDistinct>
      distinctByLastSelectedDirectory({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSelectedDirectory',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QDistinct>
      distinctByMcpServerJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mcpServerJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QDistinct>
      distinctByMemoryRounds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'memoryRounds');
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QDistinct>
      distinctByMessagesJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'messagesJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QDistinct> distinctByModelId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'modelId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QDistinct>
      distinctByScrollPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scrollPosition');
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QDistinct> distinctBySessionId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sessionId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QDistinct>
      distinctBySessionQuickCommandsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sessionQuickCommandsJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QDistinct>
      distinctByShouldStopResponse() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'shouldStopResponse');
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QDistinct> distinctBySkillJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'skillJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QDistinct>
      distinctByWorkDirectory({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'workDirectory',
          caseSensitive: caseSensitive);
    });
  }
}

extension IsarChatSessionQueryProperty
    on QueryBuilder<IsarChatSession, IsarChatSession, QQueryProperty> {
  QueryBuilder<IsarChatSession, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarChatSession, String?, QQueryOperations>
      attachmentsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'attachmentsJson');
    });
  }

  QueryBuilder<IsarChatSession, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<IsarChatSession, bool, QQueryOperations> deepThinkProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deepThink');
    });
  }

  QueryBuilder<IsarChatSession, String, QQueryOperations>
      inputContentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'inputContent');
    });
  }

  QueryBuilder<IsarChatSession, bool, QQueryOperations> isCurrentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isCurrent');
    });
  }

  QueryBuilder<IsarChatSession, bool, QQueryOperations> isFavoriteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFavorite');
    });
  }

  QueryBuilder<IsarChatSession, bool, QQueryOperations> isSendingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSending');
    });
  }

  QueryBuilder<IsarChatSession, String?, QQueryOperations>
      lastSelectedDirectoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSelectedDirectory');
    });
  }

  QueryBuilder<IsarChatSession, String?, QQueryOperations>
      mcpServerJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mcpServerJson');
    });
  }

  QueryBuilder<IsarChatSession, int, QQueryOperations> memoryRoundsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'memoryRounds');
    });
  }

  QueryBuilder<IsarChatSession, String?, QQueryOperations>
      messagesJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'messagesJson');
    });
  }

  QueryBuilder<IsarChatSession, String?, QQueryOperations> modelIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'modelId');
    });
  }

  QueryBuilder<IsarChatSession, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<IsarChatSession, double, QQueryOperations>
      scrollPositionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scrollPosition');
    });
  }

  QueryBuilder<IsarChatSession, String, QQueryOperations> sessionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sessionId');
    });
  }

  QueryBuilder<IsarChatSession, String?, QQueryOperations>
      sessionQuickCommandsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sessionQuickCommandsJson');
    });
  }

  QueryBuilder<IsarChatSession, bool, QQueryOperations>
      shouldStopResponseProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'shouldStopResponse');
    });
  }

  QueryBuilder<IsarChatSession, String?, QQueryOperations> skillJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'skillJson');
    });
  }

  QueryBuilder<IsarChatSession, String?, QQueryOperations>
      workDirectoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'workDirectory');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarMcpServiceCollection on Isar {
  IsarCollection<IsarMcpService> get isarMcpServices => this.collection();
}

const IsarMcpServiceSchema = CollectionSchema(
  name: r'IsarMcpService',
  id: 5628804302628824559,
  properties: {
    r'configJson': PropertySchema(
      id: 0,
      name: r'configJson',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 1,
      name: r'name',
      type: IsarType.string,
    )
  },
  estimateSize: _isarMcpServiceEstimateSize,
  serialize: _isarMcpServiceSerialize,
  deserialize: _isarMcpServiceDeserialize,
  deserializeProp: _isarMcpServiceDeserializeProp,
  idName: r'id',
  indexes: {
    r'name': IndexSchema(
      id: 879695947855722453,
      name: r'name',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'name',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarMcpServiceGetId,
  getLinks: _isarMcpServiceGetLinks,
  attach: _isarMcpServiceAttach,
  version: '3.1.0+1',
);

int _isarMcpServiceEstimateSize(
  IsarMcpService object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.configJson.length * 3;
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _isarMcpServiceSerialize(
  IsarMcpService object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.configJson);
  writer.writeString(offsets[1], object.name);
}

IsarMcpService _isarMcpServiceDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarMcpService();
  object.configJson = reader.readString(offsets[0]);
  object.id = id;
  object.name = reader.readString(offsets[1]);
  return object;
}

P _isarMcpServiceDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarMcpServiceGetId(IsarMcpService object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarMcpServiceGetLinks(IsarMcpService object) {
  return [];
}

void _isarMcpServiceAttach(
    IsarCollection<dynamic> col, Id id, IsarMcpService object) {
  object.id = id;
}

extension IsarMcpServiceByIndex on IsarCollection<IsarMcpService> {
  Future<IsarMcpService?> getByName(String name) {
    return getByIndex(r'name', [name]);
  }

  IsarMcpService? getByNameSync(String name) {
    return getByIndexSync(r'name', [name]);
  }

  Future<bool> deleteByName(String name) {
    return deleteByIndex(r'name', [name]);
  }

  bool deleteByNameSync(String name) {
    return deleteByIndexSync(r'name', [name]);
  }

  Future<List<IsarMcpService?>> getAllByName(List<String> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return getAllByIndex(r'name', values);
  }

  List<IsarMcpService?> getAllByNameSync(List<String> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'name', values);
  }

  Future<int> deleteAllByName(List<String> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'name', values);
  }

  int deleteAllByNameSync(List<String> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'name', values);
  }

  Future<Id> putByName(IsarMcpService object) {
    return putByIndex(r'name', object);
  }

  Id putByNameSync(IsarMcpService object, {bool saveLinks = true}) {
    return putByIndexSync(r'name', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByName(List<IsarMcpService> objects) {
    return putAllByIndex(r'name', objects);
  }

  List<Id> putAllByNameSync(List<IsarMcpService> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'name', objects, saveLinks: saveLinks);
  }
}

extension IsarMcpServiceQueryWhereSort
    on QueryBuilder<IsarMcpService, IsarMcpService, QWhere> {
  QueryBuilder<IsarMcpService, IsarMcpService, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarMcpServiceQueryWhere
    on QueryBuilder<IsarMcpService, IsarMcpService, QWhereClause> {
  QueryBuilder<IsarMcpService, IsarMcpService, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterWhereClause> nameEqualTo(
      String name) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'name',
        value: [name],
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterWhereClause>
      nameNotEqualTo(String name) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [],
              upper: [name],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [name],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [name],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [],
              upper: [name],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarMcpServiceQueryFilter
    on QueryBuilder<IsarMcpService, IsarMcpService, QFilterCondition> {
  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      configJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'configJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      configJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'configJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      configJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'configJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      configJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'configJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      configJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'configJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      configJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'configJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      configJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'configJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      configJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'configJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      configJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'configJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      configJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'configJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }
}

extension IsarMcpServiceQueryObject
    on QueryBuilder<IsarMcpService, IsarMcpService, QFilterCondition> {}

extension IsarMcpServiceQueryLinks
    on QueryBuilder<IsarMcpService, IsarMcpService, QFilterCondition> {}

extension IsarMcpServiceQuerySortBy
    on QueryBuilder<IsarMcpService, IsarMcpService, QSortBy> {
  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy>
      sortByConfigJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configJson', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy>
      sortByConfigJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configJson', Sort.desc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension IsarMcpServiceQuerySortThenBy
    on QueryBuilder<IsarMcpService, IsarMcpService, QSortThenBy> {
  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy>
      thenByConfigJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configJson', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy>
      thenByConfigJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configJson', Sort.desc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension IsarMcpServiceQueryWhereDistinct
    on QueryBuilder<IsarMcpService, IsarMcpService, QDistinct> {
  QueryBuilder<IsarMcpService, IsarMcpService, QDistinct> distinctByConfigJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'configJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }
}

extension IsarMcpServiceQueryProperty
    on QueryBuilder<IsarMcpService, IsarMcpService, QQueryProperty> {
  QueryBuilder<IsarMcpService, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarMcpService, String, QQueryOperations> configJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'configJson');
    });
  }

  QueryBuilder<IsarMcpService, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarSettingsCollection on Isar {
  IsarCollection<IsarSettings> get isarSettings => this.collection();
}

const IsarSettingsSchema = CollectionSchema(
  name: r'IsarSettings',
  id: -2003972169886166418,
  properties: {
    r'key': PropertySchema(
      id: 0,
      name: r'key',
      type: IsarType.string,
    ),
    r'value': PropertySchema(
      id: 1,
      name: r'value',
      type: IsarType.string,
    )
  },
  estimateSize: _isarSettingsEstimateSize,
  serialize: _isarSettingsSerialize,
  deserialize: _isarSettingsDeserialize,
  deserializeProp: _isarSettingsDeserializeProp,
  idName: r'id',
  indexes: {
    r'key': IndexSchema(
      id: -4906094122524121629,
      name: r'key',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'key',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarSettingsGetId,
  getLinks: _isarSettingsGetLinks,
  attach: _isarSettingsAttach,
  version: '3.1.0+1',
);

int _isarSettingsEstimateSize(
  IsarSettings object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.key.length * 3;
  bytesCount += 3 + object.value.length * 3;
  return bytesCount;
}

void _isarSettingsSerialize(
  IsarSettings object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.key);
  writer.writeString(offsets[1], object.value);
}

IsarSettings _isarSettingsDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarSettings();
  object.id = id;
  object.key = reader.readString(offsets[0]);
  object.value = reader.readString(offsets[1]);
  return object;
}

P _isarSettingsDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarSettingsGetId(IsarSettings object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarSettingsGetLinks(IsarSettings object) {
  return [];
}

void _isarSettingsAttach(
    IsarCollection<dynamic> col, Id id, IsarSettings object) {
  object.id = id;
}

extension IsarSettingsByIndex on IsarCollection<IsarSettings> {
  Future<IsarSettings?> getByKey(String key) {
    return getByIndex(r'key', [key]);
  }

  IsarSettings? getByKeySync(String key) {
    return getByIndexSync(r'key', [key]);
  }

  Future<bool> deleteByKey(String key) {
    return deleteByIndex(r'key', [key]);
  }

  bool deleteByKeySync(String key) {
    return deleteByIndexSync(r'key', [key]);
  }

  Future<List<IsarSettings?>> getAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndex(r'key', values);
  }

  List<IsarSettings?> getAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'key', values);
  }

  Future<int> deleteAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'key', values);
  }

  int deleteAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'key', values);
  }

  Future<Id> putByKey(IsarSettings object) {
    return putByIndex(r'key', object);
  }

  Id putByKeySync(IsarSettings object, {bool saveLinks = true}) {
    return putByIndexSync(r'key', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByKey(List<IsarSettings> objects) {
    return putAllByIndex(r'key', objects);
  }

  List<Id> putAllByKeySync(List<IsarSettings> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'key', objects, saveLinks: saveLinks);
  }
}

extension IsarSettingsQueryWhereSort
    on QueryBuilder<IsarSettings, IsarSettings, QWhere> {
  QueryBuilder<IsarSettings, IsarSettings, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarSettingsQueryWhere
    on QueryBuilder<IsarSettings, IsarSettings, QWhereClause> {
  QueryBuilder<IsarSettings, IsarSettings, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterWhereClause> keyEqualTo(
      String key) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'key',
        value: [key],
      ));
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterWhereClause> keyNotEqualTo(
      String key) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [],
              upper: [key],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [key],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [key],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [],
              upper: [key],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarSettingsQueryFilter
    on QueryBuilder<IsarSettings, IsarSettings, QFilterCondition> {
  QueryBuilder<IsarSettings, IsarSettings, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterFilterCondition> keyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterFilterCondition>
      keyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterFilterCondition> keyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterFilterCondition> keyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'key',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterFilterCondition> keyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterFilterCondition> keyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterFilterCondition> keyContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterFilterCondition> keyMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'key',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterFilterCondition> keyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'key',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterFilterCondition>
      keyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'key',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterFilterCondition> valueEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterFilterCondition>
      valueGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterFilterCondition> valueLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterFilterCondition> valueBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'value',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterFilterCondition>
      valueStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterFilterCondition> valueEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterFilterCondition> valueContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterFilterCondition> valueMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'value',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterFilterCondition>
      valueIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'value',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterFilterCondition>
      valueIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'value',
        value: '',
      ));
    });
  }
}

extension IsarSettingsQueryObject
    on QueryBuilder<IsarSettings, IsarSettings, QFilterCondition> {}

extension IsarSettingsQueryLinks
    on QueryBuilder<IsarSettings, IsarSettings, QFilterCondition> {}

extension IsarSettingsQuerySortBy
    on QueryBuilder<IsarSettings, IsarSettings, QSortBy> {
  QueryBuilder<IsarSettings, IsarSettings, QAfterSortBy> sortByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterSortBy> sortByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterSortBy> sortByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.asc);
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterSortBy> sortByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.desc);
    });
  }
}

extension IsarSettingsQuerySortThenBy
    on QueryBuilder<IsarSettings, IsarSettings, QSortThenBy> {
  QueryBuilder<IsarSettings, IsarSettings, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterSortBy> thenByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterSortBy> thenByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterSortBy> thenByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.asc);
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QAfterSortBy> thenByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.desc);
    });
  }
}

extension IsarSettingsQueryWhereDistinct
    on QueryBuilder<IsarSettings, IsarSettings, QDistinct> {
  QueryBuilder<IsarSettings, IsarSettings, QDistinct> distinctByKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'key', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSettings, IsarSettings, QDistinct> distinctByValue(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'value', caseSensitive: caseSensitive);
    });
  }
}

extension IsarSettingsQueryProperty
    on QueryBuilder<IsarSettings, IsarSettings, QQueryProperty> {
  QueryBuilder<IsarSettings, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarSettings, String, QQueryOperations> keyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'key');
    });
  }

  QueryBuilder<IsarSettings, String, QQueryOperations> valueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'value');
    });
  }
}
