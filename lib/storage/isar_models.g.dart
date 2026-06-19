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
    r'chatSettingsJson': PropertySchema(
      id: 2,
      name: r'chatSettingsJson',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'model': PropertySchema(
      id: 4,
      name: r'model',
      type: IsarType.string,
    ),
    r'modelId': PropertySchema(
      id: 5,
      name: r'modelId',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 6,
      name: r'name',
      type: IsarType.string,
    ),
    r'platform': PropertySchema(
      id: 7,
      name: r'platform',
      type: IsarType.string,
    ),
    r'protocol': PropertySchema(
      id: 8,
      name: r'protocol',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 9,
      name: r'type',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 10,
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
    final value = object.chatSettingsJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.model.length * 3;
  bytesCount += 3 + object.modelId.length * 3;
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.platform;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.protocol;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
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
  writer.writeString(offsets[2], object.chatSettingsJson);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeString(offsets[4], object.model);
  writer.writeString(offsets[5], object.modelId);
  writer.writeString(offsets[6], object.name);
  writer.writeString(offsets[7], object.platform);
  writer.writeString(offsets[8], object.protocol);
  writer.writeString(offsets[9], object.type);
  writer.writeDateTime(offsets[10], object.updatedAt);
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
  object.chatSettingsJson = reader.readStringOrNull(offsets[2]);
  object.createdAt = reader.readDateTimeOrNull(offsets[3]);
  object.id = id;
  object.model = reader.readString(offsets[4]);
  object.modelId = reader.readString(offsets[5]);
  object.name = reader.readString(offsets[6]);
  object.platform = reader.readStringOrNull(offsets[7]);
  object.protocol = reader.readStringOrNull(offsets[8]);
  object.type = reader.readStringOrNull(offsets[9]);
  object.updatedAt = reader.readDateTimeOrNull(offsets[10]);
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
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
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
      platformIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'platform',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      platformIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'platform',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      platformEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'platform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      platformGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'platform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      platformLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'platform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      platformBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'platform',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      platformStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'platform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      platformEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'platform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      platformContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'platform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      platformMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'platform',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      platformIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'platform',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      platformIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'platform',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      protocolIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'protocol',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      protocolIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'protocol',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      protocolEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'protocol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      protocolGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'protocol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      protocolLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'protocol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      protocolBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'protocol',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      protocolStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'protocol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      protocolEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'protocol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      protocolContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'protocol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      protocolMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'protocol',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      protocolIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'protocol',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterFilterCondition>
      protocolIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'protocol',
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

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> sortByPlatform() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'platform', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy>
      sortByPlatformDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'platform', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> sortByProtocol() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protocol', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy>
      sortByProtocolDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protocol', Sort.desc);
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

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> thenByPlatform() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'platform', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy>
      thenByPlatformDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'platform', Sort.desc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy> thenByProtocol() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protocol', Sort.asc);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QAfterSortBy>
      thenByProtocolDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protocol', Sort.desc);
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

  QueryBuilder<IsarChatModel, IsarChatModel, QDistinct> distinctByPlatform(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'platform', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarChatModel, IsarChatModel, QDistinct> distinctByProtocol(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'protocol', caseSensitive: caseSensitive);
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

  QueryBuilder<IsarChatModel, String?, QQueryOperations> platformProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'platform');
    });
  }

  QueryBuilder<IsarChatModel, String?, QQueryOperations> protocolProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'protocol');
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

extension GetIsarChatMessageCollection on Isar {
  IsarCollection<IsarChatMessage> get isarChatMessages => this.collection();
}

const IsarChatMessageSchema = CollectionSchema(
  name: r'IsarChatMessage',
  id: 5522043315384162516,
  properties: {
    r'messageJson': PropertySchema(
      id: 0,
      name: r'messageJson',
      type: IsarType.string,
    ),
    r'msgId': PropertySchema(
      id: 1,
      name: r'msgId',
      type: IsarType.string,
    ),
    r'sessionId': PropertySchema(
      id: 2,
      name: r'sessionId',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 3,
      name: r'timestamp',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _isarChatMessageEstimateSize,
  serialize: _isarChatMessageSerialize,
  deserialize: _isarChatMessageDeserialize,
  deserializeProp: _isarChatMessageDeserializeProp,
  idName: r'id',
  indexes: {
    r'msgId': IndexSchema(
      id: 8574845111581175867,
      name: r'msgId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'msgId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'sessionId': IndexSchema(
      id: 6949518585047923839,
      name: r'sessionId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'sessionId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'timestamp': IndexSchema(
      id: 1852253767416892198,
      name: r'timestamp',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'timestamp',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarChatMessageGetId,
  getLinks: _isarChatMessageGetLinks,
  attach: _isarChatMessageAttach,
  version: '3.1.0+1',
);

int _isarChatMessageEstimateSize(
  IsarChatMessage object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.messageJson.length * 3;
  bytesCount += 3 + object.msgId.length * 3;
  bytesCount += 3 + object.sessionId.length * 3;
  return bytesCount;
}

void _isarChatMessageSerialize(
  IsarChatMessage object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.messageJson);
  writer.writeString(offsets[1], object.msgId);
  writer.writeString(offsets[2], object.sessionId);
  writer.writeDateTime(offsets[3], object.timestamp);
}

IsarChatMessage _isarChatMessageDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarChatMessage();
  object.id = id;
  object.messageJson = reader.readString(offsets[0]);
  object.msgId = reader.readString(offsets[1]);
  object.sessionId = reader.readString(offsets[2]);
  object.timestamp = reader.readDateTime(offsets[3]);
  return object;
}

P _isarChatMessageDeserializeProp<P>(
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
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarChatMessageGetId(IsarChatMessage object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarChatMessageGetLinks(IsarChatMessage object) {
  return [];
}

void _isarChatMessageAttach(
    IsarCollection<dynamic> col, Id id, IsarChatMessage object) {
  object.id = id;
}

extension IsarChatMessageByIndex on IsarCollection<IsarChatMessage> {
  Future<IsarChatMessage?> getByMsgId(String msgId) {
    return getByIndex(r'msgId', [msgId]);
  }

  IsarChatMessage? getByMsgIdSync(String msgId) {
    return getByIndexSync(r'msgId', [msgId]);
  }

  Future<bool> deleteByMsgId(String msgId) {
    return deleteByIndex(r'msgId', [msgId]);
  }

  bool deleteByMsgIdSync(String msgId) {
    return deleteByIndexSync(r'msgId', [msgId]);
  }

  Future<List<IsarChatMessage?>> getAllByMsgId(List<String> msgIdValues) {
    final values = msgIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'msgId', values);
  }

  List<IsarChatMessage?> getAllByMsgIdSync(List<String> msgIdValues) {
    final values = msgIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'msgId', values);
  }

  Future<int> deleteAllByMsgId(List<String> msgIdValues) {
    final values = msgIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'msgId', values);
  }

  int deleteAllByMsgIdSync(List<String> msgIdValues) {
    final values = msgIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'msgId', values);
  }

  Future<Id> putByMsgId(IsarChatMessage object) {
    return putByIndex(r'msgId', object);
  }

  Id putByMsgIdSync(IsarChatMessage object, {bool saveLinks = true}) {
    return putByIndexSync(r'msgId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByMsgId(List<IsarChatMessage> objects) {
    return putAllByIndex(r'msgId', objects);
  }

  List<Id> putAllByMsgIdSync(List<IsarChatMessage> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'msgId', objects, saveLinks: saveLinks);
  }
}

extension IsarChatMessageQueryWhereSort
    on QueryBuilder<IsarChatMessage, IsarChatMessage, QWhere> {
  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterWhere> anyTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'timestamp'),
      );
    });
  }
}

extension IsarChatMessageQueryWhere
    on QueryBuilder<IsarChatMessage, IsarChatMessage, QWhereClause> {
  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterWhereClause>
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

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterWhereClause>
      msgIdEqualTo(String msgId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'msgId',
        value: [msgId],
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterWhereClause>
      msgIdNotEqualTo(String msgId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'msgId',
              lower: [],
              upper: [msgId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'msgId',
              lower: [msgId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'msgId',
              lower: [msgId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'msgId',
              lower: [],
              upper: [msgId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterWhereClause>
      sessionIdEqualTo(String sessionId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sessionId',
        value: [sessionId],
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterWhereClause>
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

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterWhereClause>
      timestampEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'timestamp',
        value: [timestamp],
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterWhereClause>
      timestampNotEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterWhereClause>
      timestampGreaterThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [timestamp],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterWhereClause>
      timestampLessThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [],
        upper: [timestamp],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterWhereClause>
      timestampBetween(
    DateTime lowerTimestamp,
    DateTime upperTimestamp, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [lowerTimestamp],
        includeLower: includeLower,
        upper: [upperTimestamp],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IsarChatMessageQueryFilter
    on QueryBuilder<IsarChatMessage, IsarChatMessage, QFilterCondition> {
  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
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

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
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

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
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

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      messageJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'messageJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      messageJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'messageJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      messageJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'messageJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      messageJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'messageJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      messageJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'messageJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      messageJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'messageJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      messageJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'messageJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      messageJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'messageJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      messageJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'messageJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      messageJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'messageJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      msgIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'msgId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      msgIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'msgId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      msgIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'msgId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      msgIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'msgId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      msgIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'msgId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      msgIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'msgId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      msgIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'msgId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      msgIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'msgId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      msgIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'msgId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      msgIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'msgId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
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

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
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

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
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

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
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

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
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

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
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

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      sessionIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      sessionIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sessionId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      sessionIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      sessionIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sessionId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition>
      timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IsarChatMessageQueryObject
    on QueryBuilder<IsarChatMessage, IsarChatMessage, QFilterCondition> {}

extension IsarChatMessageQueryLinks
    on QueryBuilder<IsarChatMessage, IsarChatMessage, QFilterCondition> {}

extension IsarChatMessageQuerySortBy
    on QueryBuilder<IsarChatMessage, IsarChatMessage, QSortBy> {
  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterSortBy>
      sortByMessageJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageJson', Sort.asc);
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterSortBy>
      sortByMessageJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageJson', Sort.desc);
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterSortBy> sortByMsgId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'msgId', Sort.asc);
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterSortBy>
      sortByMsgIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'msgId', Sort.desc);
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterSortBy>
      sortBySessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.asc);
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterSortBy>
      sortBySessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.desc);
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterSortBy>
      sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension IsarChatMessageQuerySortThenBy
    on QueryBuilder<IsarChatMessage, IsarChatMessage, QSortThenBy> {
  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterSortBy>
      thenByMessageJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageJson', Sort.asc);
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterSortBy>
      thenByMessageJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageJson', Sort.desc);
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterSortBy> thenByMsgId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'msgId', Sort.asc);
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterSortBy>
      thenByMsgIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'msgId', Sort.desc);
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterSortBy>
      thenBySessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.asc);
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterSortBy>
      thenBySessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.desc);
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterSortBy>
      thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension IsarChatMessageQueryWhereDistinct
    on QueryBuilder<IsarChatMessage, IsarChatMessage, QDistinct> {
  QueryBuilder<IsarChatMessage, IsarChatMessage, QDistinct>
      distinctByMessageJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'messageJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QDistinct> distinctByMsgId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'msgId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QDistinct> distinctBySessionId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sessionId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarChatMessage, IsarChatMessage, QDistinct>
      distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }
}

extension IsarChatMessageQueryProperty
    on QueryBuilder<IsarChatMessage, IsarChatMessage, QQueryProperty> {
  QueryBuilder<IsarChatMessage, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarChatMessage, String, QQueryOperations>
      messageJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'messageJson');
    });
  }

  QueryBuilder<IsarChatMessage, String, QQueryOperations> msgIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'msgId');
    });
  }

  QueryBuilder<IsarChatMessage, String, QQueryOperations> sessionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sessionId');
    });
  }

  QueryBuilder<IsarChatMessage, DateTime, QQueryOperations>
      timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
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
    r'compressedMemory': PropertySchema(
      id: 1,
      name: r'compressedMemory',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'deepThink': PropertySchema(
      id: 3,
      name: r'deepThink',
      type: IsarType.bool,
    ),
    r'inputContent': PropertySchema(
      id: 4,
      name: r'inputContent',
      type: IsarType.string,
    ),
    r'isCurrent': PropertySchema(
      id: 5,
      name: r'isCurrent',
      type: IsarType.bool,
    ),
    r'isFavorite': PropertySchema(
      id: 6,
      name: r'isFavorite',
      type: IsarType.bool,
    ),
    r'isSending': PropertySchema(
      id: 7,
      name: r'isSending',
      type: IsarType.bool,
    ),
    r'lastSelectedDirectory': PropertySchema(
      id: 8,
      name: r'lastSelectedDirectory',
      type: IsarType.string,
    ),
    r'mcpId': PropertySchema(
      id: 9,
      name: r'mcpId',
      type: IsarType.string,
    ),
    r'memoryJson': PropertySchema(
      id: 10,
      name: r'memoryJson',
      type: IsarType.string,
    ),
    r'memoryRounds': PropertySchema(
      id: 11,
      name: r'memoryRounds',
      type: IsarType.long,
    ),
    r'messagesJson': PropertySchema(
      id: 12,
      name: r'messagesJson',
      type: IsarType.string,
    ),
    r'modelId': PropertySchema(
      id: 13,
      name: r'modelId',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 14,
      name: r'name',
      type: IsarType.string,
    ),
    r'scheduledTasksJson': PropertySchema(
      id: 15,
      name: r'scheduledTasksJson',
      type: IsarType.string,
    ),
    r'scrollPosition': PropertySchema(
      id: 16,
      name: r'scrollPosition',
      type: IsarType.double,
    ),
    r'sessionId': PropertySchema(
      id: 17,
      name: r'sessionId',
      type: IsarType.string,
    ),
    r'sessionQuickCommandsJson': PropertySchema(
      id: 18,
      name: r'sessionQuickCommandsJson',
      type: IsarType.string,
    ),
    r'shouldStopResponse': PropertySchema(
      id: 19,
      name: r'shouldStopResponse',
      type: IsarType.bool,
    ),
    r'skillId': PropertySchema(
      id: 20,
      name: r'skillId',
      type: IsarType.string,
    ),
    r'workDirectory': PropertySchema(
      id: 21,
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
  {
    final value = object.compressedMemory;
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
    final value = object.mcpId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.memoryJson;
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
  {
    final value = object.scheduledTasksJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.sessionId.length * 3;
  {
    final value = object.sessionQuickCommandsJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.skillId;
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
  writer.writeString(offsets[1], object.compressedMemory);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeBool(offsets[3], object.deepThink);
  writer.writeString(offsets[4], object.inputContent);
  writer.writeBool(offsets[5], object.isCurrent);
  writer.writeBool(offsets[6], object.isFavorite);
  writer.writeBool(offsets[7], object.isSending);
  writer.writeString(offsets[8], object.lastSelectedDirectory);
  writer.writeString(offsets[9], object.mcpId);
  writer.writeString(offsets[10], object.memoryJson);
  writer.writeLong(offsets[11], object.memoryRounds);
  writer.writeString(offsets[12], object.messagesJson);
  writer.writeString(offsets[13], object.modelId);
  writer.writeString(offsets[14], object.name);
  writer.writeString(offsets[15], object.scheduledTasksJson);
  writer.writeDouble(offsets[16], object.scrollPosition);
  writer.writeString(offsets[17], object.sessionId);
  writer.writeString(offsets[18], object.sessionQuickCommandsJson);
  writer.writeBool(offsets[19], object.shouldStopResponse);
  writer.writeString(offsets[20], object.skillId);
  writer.writeString(offsets[21], object.workDirectory);
}

IsarChatSession _isarChatSessionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarChatSession();
  object.attachmentsJson = reader.readStringOrNull(offsets[0]);
  object.compressedMemory = reader.readStringOrNull(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.deepThink = reader.readBool(offsets[3]);
  object.id = id;
  object.inputContent = reader.readString(offsets[4]);
  object.isCurrent = reader.readBool(offsets[5]);
  object.isFavorite = reader.readBool(offsets[6]);
  object.isSending = reader.readBool(offsets[7]);
  object.lastSelectedDirectory = reader.readStringOrNull(offsets[8]);
  object.mcpId = reader.readStringOrNull(offsets[9]);
  object.memoryJson = reader.readStringOrNull(offsets[10]);
  object.memoryRounds = reader.readLong(offsets[11]);
  object.messagesJson = reader.readStringOrNull(offsets[12]);
  object.modelId = reader.readStringOrNull(offsets[13]);
  object.name = reader.readString(offsets[14]);
  object.scheduledTasksJson = reader.readStringOrNull(offsets[15]);
  object.scrollPosition = reader.readDouble(offsets[16]);
  object.sessionId = reader.readString(offsets[17]);
  object.sessionQuickCommandsJson = reader.readStringOrNull(offsets[18]);
  object.shouldStopResponse = reader.readBool(offsets[19]);
  object.skillId = reader.readStringOrNull(offsets[20]);
  object.workDirectory = reader.readStringOrNull(offsets[21]);
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
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readDouble(offset)) as P;
    case 17:
      return (reader.readString(offset)) as P;
    case 18:
      return (reader.readStringOrNull(offset)) as P;
    case 19:
      return (reader.readBool(offset)) as P;
    case 20:
      return (reader.readStringOrNull(offset)) as P;
    case 21:
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
      compressedMemoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'compressedMemory',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      compressedMemoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'compressedMemory',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      compressedMemoryEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'compressedMemory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      compressedMemoryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'compressedMemory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      compressedMemoryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'compressedMemory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      compressedMemoryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'compressedMemory',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      compressedMemoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'compressedMemory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      compressedMemoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'compressedMemory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      compressedMemoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'compressedMemory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      compressedMemoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'compressedMemory',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      compressedMemoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'compressedMemory',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      compressedMemoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'compressedMemory',
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
      mcpIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mcpId',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      mcpIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mcpId',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      mcpIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mcpId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      mcpIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mcpId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      mcpIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mcpId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      mcpIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mcpId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      mcpIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mcpId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      mcpIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mcpId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      mcpIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mcpId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      mcpIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mcpId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      mcpIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mcpId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      mcpIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mcpId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      memoryJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'memoryJson',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      memoryJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'memoryJson',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      memoryJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'memoryJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      memoryJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'memoryJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      memoryJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'memoryJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      memoryJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'memoryJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      memoryJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'memoryJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      memoryJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'memoryJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      memoryJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'memoryJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      memoryJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'memoryJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      memoryJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'memoryJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      memoryJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'memoryJson',
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
      scheduledTasksJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'scheduledTasksJson',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      scheduledTasksJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'scheduledTasksJson',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      scheduledTasksJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scheduledTasksJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      scheduledTasksJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scheduledTasksJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      scheduledTasksJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scheduledTasksJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      scheduledTasksJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scheduledTasksJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      scheduledTasksJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'scheduledTasksJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      scheduledTasksJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'scheduledTasksJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      scheduledTasksJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'scheduledTasksJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      scheduledTasksJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'scheduledTasksJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      scheduledTasksJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scheduledTasksJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      scheduledTasksJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'scheduledTasksJson',
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
      skillIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'skillId',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      skillIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'skillId',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      skillIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'skillId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      skillIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'skillId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      skillIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'skillId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      skillIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'skillId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      skillIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'skillId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      skillIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'skillId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      skillIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'skillId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      skillIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'skillId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      skillIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'skillId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterFilterCondition>
      skillIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'skillId',
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
      sortByCompressedMemory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'compressedMemory', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByCompressedMemoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'compressedMemory', Sort.desc);
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

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy> sortByMcpId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mcpId', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByMcpIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mcpId', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByMemoryJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memoryJson', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByMemoryJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memoryJson', Sort.desc);
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
      sortByScheduledTasksJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledTasksJson', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortByScheduledTasksJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledTasksJson', Sort.desc);
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

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy> sortBySkillId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skillId', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      sortBySkillIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skillId', Sort.desc);
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
      thenByCompressedMemory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'compressedMemory', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByCompressedMemoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'compressedMemory', Sort.desc);
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

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy> thenByMcpId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mcpId', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByMcpIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mcpId', Sort.desc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByMemoryJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memoryJson', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByMemoryJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memoryJson', Sort.desc);
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
      thenByScheduledTasksJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledTasksJson', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenByScheduledTasksJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledTasksJson', Sort.desc);
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

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy> thenBySkillId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skillId', Sort.asc);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QAfterSortBy>
      thenBySkillIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skillId', Sort.desc);
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
      distinctByCompressedMemory({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'compressedMemory',
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

  QueryBuilder<IsarChatSession, IsarChatSession, QDistinct> distinctByMcpId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mcpId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarChatSession, IsarChatSession, QDistinct>
      distinctByMemoryJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'memoryJson', caseSensitive: caseSensitive);
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
      distinctByScheduledTasksJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scheduledTasksJson',
          caseSensitive: caseSensitive);
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

  QueryBuilder<IsarChatSession, IsarChatSession, QDistinct> distinctBySkillId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'skillId', caseSensitive: caseSensitive);
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

  QueryBuilder<IsarChatSession, String?, QQueryOperations>
      compressedMemoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'compressedMemory');
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

  QueryBuilder<IsarChatSession, String?, QQueryOperations> mcpIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mcpId');
    });
  }

  QueryBuilder<IsarChatSession, String?, QQueryOperations>
      memoryJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'memoryJson');
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

  QueryBuilder<IsarChatSession, String?, QQueryOperations>
      scheduledTasksJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scheduledTasksJson');
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

  QueryBuilder<IsarChatSession, String?, QQueryOperations> skillIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'skillId');
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
    r'args': PropertySchema(
      id: 0,
      name: r'args',
      type: IsarType.stringList,
    ),
    r'body': PropertySchema(
      id: 1,
      name: r'body',
      type: IsarType.string,
    ),
    r'code': PropertySchema(
      id: 2,
      name: r'code',
      type: IsarType.string,
    ),
    r'command': PropertySchema(
      id: 3,
      name: r'command',
      type: IsarType.string,
    ),
    r'description': PropertySchema(
      id: 4,
      name: r'description',
      type: IsarType.string,
    ),
    r'env': PropertySchema(
      id: 5,
      name: r'env',
      type: IsarType.string,
    ),
    r'headers': PropertySchema(
      id: 6,
      name: r'headers',
      type: IsarType.string,
    ),
    r'lastUpdated': PropertySchema(
      id: 7,
      name: r'lastUpdated',
      type: IsarType.dateTime,
    ),
    r'mcpId': PropertySchema(
      id: 8,
      name: r'mcpId',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 9,
      name: r'name',
      type: IsarType.string,
    ),
    r'prompt': PropertySchema(
      id: 10,
      name: r'prompt',
      type: IsarType.string,
    ),
    r'timeout': PropertySchema(
      id: 11,
      name: r'timeout',
      type: IsarType.long,
    ),
    r'tools': PropertySchema(
      id: 12,
      name: r'tools',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 13,
      name: r'type',
      type: IsarType.string,
    ),
    r'url': PropertySchema(
      id: 14,
      name: r'url',
      type: IsarType.string,
    ),
    r'workingDirectory': PropertySchema(
      id: 15,
      name: r'workingDirectory',
      type: IsarType.string,
    )
  },
  estimateSize: _isarMcpServiceEstimateSize,
  serialize: _isarMcpServiceSerialize,
  deserialize: _isarMcpServiceDeserialize,
  deserializeProp: _isarMcpServiceDeserializeProp,
  idName: r'id',
  indexes: {
    r'mcpId': IndexSchema(
      id: 4601851386080442350,
      name: r'mcpId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'mcpId',
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
  {
    final list = object.args;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += value.length * 3;
        }
      }
    }
  }
  {
    final value = object.body;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.code;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.command;
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
    final value = object.env;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.headers;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.mcpId.length * 3;
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.prompt;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.tools;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.type;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.url;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.workingDirectory;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _isarMcpServiceSerialize(
  IsarMcpService object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.args);
  writer.writeString(offsets[1], object.body);
  writer.writeString(offsets[2], object.code);
  writer.writeString(offsets[3], object.command);
  writer.writeString(offsets[4], object.description);
  writer.writeString(offsets[5], object.env);
  writer.writeString(offsets[6], object.headers);
  writer.writeDateTime(offsets[7], object.lastUpdated);
  writer.writeString(offsets[8], object.mcpId);
  writer.writeString(offsets[9], object.name);
  writer.writeString(offsets[10], object.prompt);
  writer.writeLong(offsets[11], object.timeout);
  writer.writeString(offsets[12], object.tools);
  writer.writeString(offsets[13], object.type);
  writer.writeString(offsets[14], object.url);
  writer.writeString(offsets[15], object.workingDirectory);
}

IsarMcpService _isarMcpServiceDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarMcpService();
  object.args = reader.readStringList(offsets[0]);
  object.body = reader.readStringOrNull(offsets[1]);
  object.code = reader.readStringOrNull(offsets[2]);
  object.command = reader.readStringOrNull(offsets[3]);
  object.description = reader.readStringOrNull(offsets[4]);
  object.env = reader.readStringOrNull(offsets[5]);
  object.headers = reader.readStringOrNull(offsets[6]);
  object.id = id;
  object.lastUpdated = reader.readDateTimeOrNull(offsets[7]);
  object.mcpId = reader.readString(offsets[8]);
  object.name = reader.readString(offsets[9]);
  object.prompt = reader.readStringOrNull(offsets[10]);
  object.timeout = reader.readLongOrNull(offsets[11]);
  object.tools = reader.readStringOrNull(offsets[12]);
  object.type = reader.readStringOrNull(offsets[13]);
  object.url = reader.readStringOrNull(offsets[14]);
  object.workingDirectory = reader.readStringOrNull(offsets[15]);
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
      return (reader.readStringList(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readLongOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
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
  Future<IsarMcpService?> getByMcpId(String mcpId) {
    return getByIndex(r'mcpId', [mcpId]);
  }

  IsarMcpService? getByMcpIdSync(String mcpId) {
    return getByIndexSync(r'mcpId', [mcpId]);
  }

  Future<bool> deleteByMcpId(String mcpId) {
    return deleteByIndex(r'mcpId', [mcpId]);
  }

  bool deleteByMcpIdSync(String mcpId) {
    return deleteByIndexSync(r'mcpId', [mcpId]);
  }

  Future<List<IsarMcpService?>> getAllByMcpId(List<String> mcpIdValues) {
    final values = mcpIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'mcpId', values);
  }

  List<IsarMcpService?> getAllByMcpIdSync(List<String> mcpIdValues) {
    final values = mcpIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'mcpId', values);
  }

  Future<int> deleteAllByMcpId(List<String> mcpIdValues) {
    final values = mcpIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'mcpId', values);
  }

  int deleteAllByMcpIdSync(List<String> mcpIdValues) {
    final values = mcpIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'mcpId', values);
  }

  Future<Id> putByMcpId(IsarMcpService object) {
    return putByIndex(r'mcpId', object);
  }

  Id putByMcpIdSync(IsarMcpService object, {bool saveLinks = true}) {
    return putByIndexSync(r'mcpId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByMcpId(List<IsarMcpService> objects) {
    return putAllByIndex(r'mcpId', objects);
  }

  List<Id> putAllByMcpIdSync(List<IsarMcpService> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'mcpId', objects, saveLinks: saveLinks);
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

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterWhereClause> mcpIdEqualTo(
      String mcpId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'mcpId',
        value: [mcpId],
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterWhereClause>
      mcpIdNotEqualTo(String mcpId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mcpId',
              lower: [],
              upper: [mcpId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mcpId',
              lower: [mcpId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mcpId',
              lower: [mcpId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mcpId',
              lower: [],
              upper: [mcpId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarMcpServiceQueryFilter
    on QueryBuilder<IsarMcpService, IsarMcpService, QFilterCondition> {
  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      argsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'args',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      argsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'args',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      argsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'args',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      argsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'args',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      argsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'args',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      argsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'args',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      argsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'args',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      argsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'args',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      argsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'args',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      argsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'args',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      argsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'args',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      argsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'args',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      argsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'args',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      argsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'args',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      argsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'args',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      argsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'args',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      argsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'args',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      argsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'args',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      bodyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'body',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      bodyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'body',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      bodyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'body',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      bodyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'body',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      bodyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'body',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      bodyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'body',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      bodyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'body',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      bodyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'body',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      bodyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'body',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      bodyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'body',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      bodyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'body',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      bodyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'body',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      codeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'code',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      codeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'code',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      codeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      codeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      codeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      codeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'code',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      codeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      codeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      codeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      codeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'code',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      codeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'code',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      codeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'code',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      commandIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'command',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      commandIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'command',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      commandEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'command',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      commandGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'command',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      commandLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'command',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      commandBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'command',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      commandStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'command',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      commandEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'command',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      commandContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'command',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      commandMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'command',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      commandIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'command',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      commandIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'command',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
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

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
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

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
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

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
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

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
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

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
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

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      envIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'env',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      envIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'env',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      envEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'env',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      envGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'env',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      envLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'env',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      envBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'env',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      envStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'env',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      envEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'env',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      envContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'env',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      envMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'env',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      envIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'env',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      envIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'env',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      headersIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'headers',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      headersIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'headers',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      headersEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'headers',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      headersGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'headers',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      headersLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'headers',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      headersBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'headers',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      headersStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'headers',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      headersEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'headers',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      headersContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'headers',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      headersMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'headers',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      headersIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'headers',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      headersIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'headers',
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
      lastUpdatedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastUpdated',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      lastUpdatedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastUpdated',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      lastUpdatedEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      lastUpdatedGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      lastUpdatedLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      lastUpdatedBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastUpdated',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      mcpIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mcpId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      mcpIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mcpId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      mcpIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mcpId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      mcpIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mcpId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      mcpIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mcpId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      mcpIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mcpId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      mcpIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mcpId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      mcpIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mcpId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      mcpIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mcpId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      mcpIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mcpId',
        value: '',
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

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      promptIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'prompt',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      promptIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'prompt',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      promptEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'prompt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      promptGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'prompt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      promptLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'prompt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      promptBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'prompt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      promptStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'prompt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      promptEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'prompt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      promptContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'prompt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      promptMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'prompt',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      promptIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'prompt',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      promptIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'prompt',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      timeoutIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'timeout',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      timeoutIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'timeout',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      timeoutEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timeout',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      timeoutGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timeout',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      timeoutLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timeout',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      timeoutBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timeout',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      toolsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'tools',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      toolsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'tools',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      toolsEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tools',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      toolsGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tools',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      toolsLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tools',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      toolsBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tools',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      toolsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tools',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      toolsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tools',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      toolsContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tools',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      toolsMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tools',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      toolsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tools',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      toolsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tools',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      typeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'type',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      typeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'type',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      typeEqualTo(
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

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
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

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
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

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      typeBetween(
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

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
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

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
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

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      urlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'url',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      urlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'url',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      urlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      urlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      urlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      urlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'url',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      urlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      urlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      urlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      urlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'url',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      urlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'url',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      urlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'url',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      workingDirectoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'workingDirectory',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      workingDirectoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'workingDirectory',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      workingDirectoryEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'workingDirectory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      workingDirectoryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'workingDirectory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      workingDirectoryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'workingDirectory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      workingDirectoryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'workingDirectory',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      workingDirectoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'workingDirectory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      workingDirectoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'workingDirectory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      workingDirectoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'workingDirectory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      workingDirectoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'workingDirectory',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      workingDirectoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'workingDirectory',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterFilterCondition>
      workingDirectoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'workingDirectory',
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
  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> sortByBody() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'body', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> sortByBodyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'body', Sort.desc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> sortByCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> sortByCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.desc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> sortByCommand() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'command', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy>
      sortByCommandDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'command', Sort.desc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy>
      sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy>
      sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> sortByEnv() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'env', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> sortByEnvDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'env', Sort.desc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> sortByHeaders() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'headers', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy>
      sortByHeadersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'headers', Sort.desc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy>
      sortByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy>
      sortByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> sortByMcpId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mcpId', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> sortByMcpIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mcpId', Sort.desc);
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

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> sortByPrompt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prompt', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy>
      sortByPromptDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prompt', Sort.desc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> sortByTimeout() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeout', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy>
      sortByTimeoutDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeout', Sort.desc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> sortByTools() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tools', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> sortByToolsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tools', Sort.desc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> sortByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> sortByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy>
      sortByWorkingDirectory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workingDirectory', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy>
      sortByWorkingDirectoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workingDirectory', Sort.desc);
    });
  }
}

extension IsarMcpServiceQuerySortThenBy
    on QueryBuilder<IsarMcpService, IsarMcpService, QSortThenBy> {
  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> thenByBody() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'body', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> thenByBodyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'body', Sort.desc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> thenByCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> thenByCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.desc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> thenByCommand() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'command', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy>
      thenByCommandDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'command', Sort.desc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy>
      thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy>
      thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> thenByEnv() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'env', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> thenByEnvDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'env', Sort.desc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> thenByHeaders() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'headers', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy>
      thenByHeadersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'headers', Sort.desc);
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

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy>
      thenByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy>
      thenByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> thenByMcpId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mcpId', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> thenByMcpIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mcpId', Sort.desc);
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

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> thenByPrompt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prompt', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy>
      thenByPromptDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prompt', Sort.desc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> thenByTimeout() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeout', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy>
      thenByTimeoutDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeout', Sort.desc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> thenByTools() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tools', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> thenByToolsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tools', Sort.desc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> thenByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy> thenByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy>
      thenByWorkingDirectory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workingDirectory', Sort.asc);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QAfterSortBy>
      thenByWorkingDirectoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workingDirectory', Sort.desc);
    });
  }
}

extension IsarMcpServiceQueryWhereDistinct
    on QueryBuilder<IsarMcpService, IsarMcpService, QDistinct> {
  QueryBuilder<IsarMcpService, IsarMcpService, QDistinct> distinctByArgs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'args');
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QDistinct> distinctByBody(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'body', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QDistinct> distinctByCode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'code', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QDistinct> distinctByCommand(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'command', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QDistinct> distinctByEnv(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'env', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QDistinct> distinctByHeaders(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'headers', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QDistinct>
      distinctByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUpdated');
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QDistinct> distinctByMcpId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mcpId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QDistinct> distinctByPrompt(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'prompt', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QDistinct> distinctByTimeout() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timeout');
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QDistinct> distinctByTools(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tools', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QDistinct> distinctByType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QDistinct> distinctByUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'url', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarMcpService, IsarMcpService, QDistinct>
      distinctByWorkingDirectory({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'workingDirectory',
          caseSensitive: caseSensitive);
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

  QueryBuilder<IsarMcpService, List<String>?, QQueryOperations> argsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'args');
    });
  }

  QueryBuilder<IsarMcpService, String?, QQueryOperations> bodyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'body');
    });
  }

  QueryBuilder<IsarMcpService, String?, QQueryOperations> codeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'code');
    });
  }

  QueryBuilder<IsarMcpService, String?, QQueryOperations> commandProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'command');
    });
  }

  QueryBuilder<IsarMcpService, String?, QQueryOperations>
      descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<IsarMcpService, String?, QQueryOperations> envProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'env');
    });
  }

  QueryBuilder<IsarMcpService, String?, QQueryOperations> headersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'headers');
    });
  }

  QueryBuilder<IsarMcpService, DateTime?, QQueryOperations>
      lastUpdatedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUpdated');
    });
  }

  QueryBuilder<IsarMcpService, String, QQueryOperations> mcpIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mcpId');
    });
  }

  QueryBuilder<IsarMcpService, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<IsarMcpService, String?, QQueryOperations> promptProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'prompt');
    });
  }

  QueryBuilder<IsarMcpService, int?, QQueryOperations> timeoutProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timeout');
    });
  }

  QueryBuilder<IsarMcpService, String?, QQueryOperations> toolsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tools');
    });
  }

  QueryBuilder<IsarMcpService, String?, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<IsarMcpService, String?, QQueryOperations> urlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'url');
    });
  }

  QueryBuilder<IsarMcpService, String?, QQueryOperations>
      workingDirectoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'workingDirectory');
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

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarVendorKeyCollection on Isar {
  IsarCollection<IsarVendorKey> get isarVendorKeys => this.collection();
}

const IsarVendorKeySchema = CollectionSchema(
  name: r'IsarVendorKey',
  id: 6400204150897309604,
  properties: {
    r'apiKey': PropertySchema(
      id: 0,
      name: r'apiKey',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 1,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'vendorId': PropertySchema(
      id: 2,
      name: r'vendorId',
      type: IsarType.string,
    )
  },
  estimateSize: _isarVendorKeyEstimateSize,
  serialize: _isarVendorKeySerialize,
  deserialize: _isarVendorKeyDeserialize,
  deserializeProp: _isarVendorKeyDeserializeProp,
  idName: r'id',
  indexes: {
    r'vendorId': IndexSchema(
      id: -4437098950868530640,
      name: r'vendorId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'vendorId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarVendorKeyGetId,
  getLinks: _isarVendorKeyGetLinks,
  attach: _isarVendorKeyAttach,
  version: '3.1.0+1',
);

int _isarVendorKeyEstimateSize(
  IsarVendorKey object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.apiKey.length * 3;
  bytesCount += 3 + object.vendorId.length * 3;
  return bytesCount;
}

void _isarVendorKeySerialize(
  IsarVendorKey object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.apiKey);
  writer.writeDateTime(offsets[1], object.updatedAt);
  writer.writeString(offsets[2], object.vendorId);
}

IsarVendorKey _isarVendorKeyDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarVendorKey();
  object.apiKey = reader.readString(offsets[0]);
  object.id = id;
  object.updatedAt = reader.readDateTime(offsets[1]);
  object.vendorId = reader.readString(offsets[2]);
  return object;
}

P _isarVendorKeyDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarVendorKeyGetId(IsarVendorKey object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarVendorKeyGetLinks(IsarVendorKey object) {
  return [];
}

void _isarVendorKeyAttach(
    IsarCollection<dynamic> col, Id id, IsarVendorKey object) {
  object.id = id;
}

extension IsarVendorKeyByIndex on IsarCollection<IsarVendorKey> {
  Future<IsarVendorKey?> getByVendorId(String vendorId) {
    return getByIndex(r'vendorId', [vendorId]);
  }

  IsarVendorKey? getByVendorIdSync(String vendorId) {
    return getByIndexSync(r'vendorId', [vendorId]);
  }

  Future<bool> deleteByVendorId(String vendorId) {
    return deleteByIndex(r'vendorId', [vendorId]);
  }

  bool deleteByVendorIdSync(String vendorId) {
    return deleteByIndexSync(r'vendorId', [vendorId]);
  }

  Future<List<IsarVendorKey?>> getAllByVendorId(List<String> vendorIdValues) {
    final values = vendorIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'vendorId', values);
  }

  List<IsarVendorKey?> getAllByVendorIdSync(List<String> vendorIdValues) {
    final values = vendorIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'vendorId', values);
  }

  Future<int> deleteAllByVendorId(List<String> vendorIdValues) {
    final values = vendorIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'vendorId', values);
  }

  int deleteAllByVendorIdSync(List<String> vendorIdValues) {
    final values = vendorIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'vendorId', values);
  }

  Future<Id> putByVendorId(IsarVendorKey object) {
    return putByIndex(r'vendorId', object);
  }

  Id putByVendorIdSync(IsarVendorKey object, {bool saveLinks = true}) {
    return putByIndexSync(r'vendorId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByVendorId(List<IsarVendorKey> objects) {
    return putAllByIndex(r'vendorId', objects);
  }

  List<Id> putAllByVendorIdSync(List<IsarVendorKey> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'vendorId', objects, saveLinks: saveLinks);
  }
}

extension IsarVendorKeyQueryWhereSort
    on QueryBuilder<IsarVendorKey, IsarVendorKey, QWhere> {
  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarVendorKeyQueryWhere
    on QueryBuilder<IsarVendorKey, IsarVendorKey, QWhereClause> {
  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterWhereClause> vendorIdEqualTo(
      String vendorId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'vendorId',
        value: [vendorId],
      ));
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterWhereClause>
      vendorIdNotEqualTo(String vendorId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'vendorId',
              lower: [],
              upper: [vendorId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'vendorId',
              lower: [vendorId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'vendorId',
              lower: [vendorId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'vendorId',
              lower: [],
              upper: [vendorId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarVendorKeyQueryFilter
    on QueryBuilder<IsarVendorKey, IsarVendorKey, QFilterCondition> {
  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterFilterCondition>
      apiKeyEqualTo(
    String value, {
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

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterFilterCondition>
      apiKeyGreaterThan(
    String value, {
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

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterFilterCondition>
      apiKeyLessThan(
    String value, {
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

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterFilterCondition>
      apiKeyBetween(
    String lower,
    String upper, {
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

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterFilterCondition>
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

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterFilterCondition>
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

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterFilterCondition>
      apiKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'apiKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterFilterCondition>
      apiKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'apiKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterFilterCondition>
      apiKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'apiKey',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterFilterCondition>
      apiKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'apiKey',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterFilterCondition>
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

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterFilterCondition> idBetween(
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

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
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

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
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

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
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

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterFilterCondition>
      vendorIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vendorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterFilterCondition>
      vendorIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'vendorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterFilterCondition>
      vendorIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'vendorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterFilterCondition>
      vendorIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'vendorId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterFilterCondition>
      vendorIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'vendorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterFilterCondition>
      vendorIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'vendorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterFilterCondition>
      vendorIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'vendorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterFilterCondition>
      vendorIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'vendorId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterFilterCondition>
      vendorIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vendorId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterFilterCondition>
      vendorIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'vendorId',
        value: '',
      ));
    });
  }
}

extension IsarVendorKeyQueryObject
    on QueryBuilder<IsarVendorKey, IsarVendorKey, QFilterCondition> {}

extension IsarVendorKeyQueryLinks
    on QueryBuilder<IsarVendorKey, IsarVendorKey, QFilterCondition> {}

extension IsarVendorKeyQuerySortBy
    on QueryBuilder<IsarVendorKey, IsarVendorKey, QSortBy> {
  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterSortBy> sortByApiKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiKey', Sort.asc);
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterSortBy> sortByApiKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiKey', Sort.desc);
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterSortBy> sortByVendorId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vendorId', Sort.asc);
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterSortBy>
      sortByVendorIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vendorId', Sort.desc);
    });
  }
}

extension IsarVendorKeyQuerySortThenBy
    on QueryBuilder<IsarVendorKey, IsarVendorKey, QSortThenBy> {
  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterSortBy> thenByApiKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiKey', Sort.asc);
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterSortBy> thenByApiKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiKey', Sort.desc);
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterSortBy> thenByVendorId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vendorId', Sort.asc);
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QAfterSortBy>
      thenByVendorIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vendorId', Sort.desc);
    });
  }
}

extension IsarVendorKeyQueryWhereDistinct
    on QueryBuilder<IsarVendorKey, IsarVendorKey, QDistinct> {
  QueryBuilder<IsarVendorKey, IsarVendorKey, QDistinct> distinctByApiKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'apiKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<IsarVendorKey, IsarVendorKey, QDistinct> distinctByVendorId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vendorId', caseSensitive: caseSensitive);
    });
  }
}

extension IsarVendorKeyQueryProperty
    on QueryBuilder<IsarVendorKey, IsarVendorKey, QQueryProperty> {
  QueryBuilder<IsarVendorKey, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarVendorKey, String, QQueryOperations> apiKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'apiKey');
    });
  }

  QueryBuilder<IsarVendorKey, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<IsarVendorKey, String, QQueryOperations> vendorIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vendorId');
    });
  }
}
