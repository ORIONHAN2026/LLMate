// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_models.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetL0ConversationCollection on Isar {
  IsarCollection<L0Conversation> get l0Conversations => this.collection();
}

const L0ConversationSchema = CollectionSchema(
  name: r'L0Conversation',
  id: 750149510936047056,
  properties: {
    r'assistantText': PropertySchema(
      id: 0,
      name: r'assistantText',
      type: IsarType.string,
    ),
    r'messagesJson': PropertySchema(
      id: 1,
      name: r'messagesJson',
      type: IsarType.string,
    ),
    r'processedAt': PropertySchema(
      id: 2,
      name: r'processedAt',
      type: IsarType.dateTime,
    ),
    r'processedToL1': PropertySchema(
      id: 3,
      name: r'processedToL1',
      type: IsarType.bool,
    ),
    r'sessionId': PropertySchema(
      id: 4,
      name: r'sessionId',
      type: IsarType.string,
    ),
    r'sessionKey': PropertySchema(
      id: 5,
      name: r'sessionKey',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 6,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
    r'userText': PropertySchema(
      id: 7,
      name: r'userText',
      type: IsarType.string,
    )
  },
  estimateSize: _l0ConversationEstimateSize,
  serialize: _l0ConversationSerialize,
  deserialize: _l0ConversationDeserialize,
  deserializeProp: _l0ConversationDeserializeProp,
  idName: r'id',
  indexes: {
    r'sessionKey': IndexSchema(
      id: -4553619741042231539,
      name: r'sessionKey',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'sessionKey',
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
    r'processedToL1': IndexSchema(
      id: 8944632283874553388,
      name: r'processedToL1',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'processedToL1',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _l0ConversationGetId,
  getLinks: _l0ConversationGetLinks,
  attach: _l0ConversationAttach,
  version: '3.1.0+1',
);

int _l0ConversationEstimateSize(
  L0Conversation object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.assistantText.length * 3;
  bytesCount += 3 + object.messagesJson.length * 3;
  bytesCount += 3 + object.sessionId.length * 3;
  bytesCount += 3 + object.sessionKey.length * 3;
  bytesCount += 3 + object.userText.length * 3;
  return bytesCount;
}

void _l0ConversationSerialize(
  L0Conversation object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.assistantText);
  writer.writeString(offsets[1], object.messagesJson);
  writer.writeDateTime(offsets[2], object.processedAt);
  writer.writeBool(offsets[3], object.processedToL1);
  writer.writeString(offsets[4], object.sessionId);
  writer.writeString(offsets[5], object.sessionKey);
  writer.writeDateTime(offsets[6], object.timestamp);
  writer.writeString(offsets[7], object.userText);
}

L0Conversation _l0ConversationDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = L0Conversation();
  object.assistantText = reader.readString(offsets[0]);
  object.id = id;
  object.messagesJson = reader.readString(offsets[1]);
  object.processedAt = reader.readDateTimeOrNull(offsets[2]);
  object.processedToL1 = reader.readBool(offsets[3]);
  object.sessionId = reader.readString(offsets[4]);
  object.sessionKey = reader.readString(offsets[5]);
  object.timestamp = reader.readDateTime(offsets[6]);
  object.userText = reader.readString(offsets[7]);
  return object;
}

P _l0ConversationDeserializeProp<P>(
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
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _l0ConversationGetId(L0Conversation object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _l0ConversationGetLinks(L0Conversation object) {
  return [];
}

void _l0ConversationAttach(
    IsarCollection<dynamic> col, Id id, L0Conversation object) {
  object.id = id;
}

extension L0ConversationQueryWhereSort
    on QueryBuilder<L0Conversation, L0Conversation, QWhere> {
  QueryBuilder<L0Conversation, L0Conversation, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterWhere> anyProcessedToL1() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'processedToL1'),
      );
    });
  }
}

extension L0ConversationQueryWhere
    on QueryBuilder<L0Conversation, L0Conversation, QWhereClause> {
  QueryBuilder<L0Conversation, L0Conversation, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<L0Conversation, L0Conversation, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterWhereClause> idBetween(
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

  QueryBuilder<L0Conversation, L0Conversation, QAfterWhereClause>
      sessionKeyEqualTo(String sessionKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sessionKey',
        value: [sessionKey],
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterWhereClause>
      sessionKeyNotEqualTo(String sessionKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionKey',
              lower: [],
              upper: [sessionKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionKey',
              lower: [sessionKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionKey',
              lower: [sessionKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionKey',
              lower: [],
              upper: [sessionKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterWhereClause>
      sessionIdEqualTo(String sessionId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sessionId',
        value: [sessionId],
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterWhereClause>
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

  QueryBuilder<L0Conversation, L0Conversation, QAfterWhereClause>
      processedToL1EqualTo(bool processedToL1) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'processedToL1',
        value: [processedToL1],
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterWhereClause>
      processedToL1NotEqualTo(bool processedToL1) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'processedToL1',
              lower: [],
              upper: [processedToL1],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'processedToL1',
              lower: [processedToL1],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'processedToL1',
              lower: [processedToL1],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'processedToL1',
              lower: [],
              upper: [processedToL1],
              includeUpper: false,
            ));
      }
    });
  }
}

extension L0ConversationQueryFilter
    on QueryBuilder<L0Conversation, L0Conversation, QFilterCondition> {
  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      assistantTextEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assistantText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      assistantTextGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'assistantText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      assistantTextLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'assistantText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      assistantTextBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'assistantText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      assistantTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'assistantText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      assistantTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'assistantText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      assistantTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'assistantText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      assistantTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'assistantText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      assistantTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assistantText',
        value: '',
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      assistantTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'assistantText',
        value: '',
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
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

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
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

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition> idBetween(
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

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      messagesJsonEqualTo(
    String value, {
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

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      messagesJsonGreaterThan(
    String value, {
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

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      messagesJsonLessThan(
    String value, {
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

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      messagesJsonBetween(
    String lower,
    String upper, {
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

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
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

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
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

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      messagesJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'messagesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      messagesJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'messagesJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      messagesJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'messagesJson',
        value: '',
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      messagesJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'messagesJson',
        value: '',
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      processedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'processedAt',
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      processedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'processedAt',
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      processedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'processedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      processedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'processedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      processedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'processedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      processedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'processedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      processedToL1EqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'processedToL1',
        value: value,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
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

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
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

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
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

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
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

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
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

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
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

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      sessionIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      sessionIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sessionId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      sessionIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionId',
        value: '',
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      sessionIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sessionId',
        value: '',
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      sessionKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      sessionKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sessionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      sessionKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sessionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      sessionKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sessionKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      sessionKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sessionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      sessionKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sessionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      sessionKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sessionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      sessionKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sessionKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      sessionKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionKey',
        value: '',
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      sessionKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sessionKey',
        value: '',
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
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

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
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

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
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

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      userTextEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      userTextGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      userTextLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      userTextBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      userTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      userTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      userTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      userTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      userTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userText',
        value: '',
      ));
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterFilterCondition>
      userTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userText',
        value: '',
      ));
    });
  }
}

extension L0ConversationQueryObject
    on QueryBuilder<L0Conversation, L0Conversation, QFilterCondition> {}

extension L0ConversationQueryLinks
    on QueryBuilder<L0Conversation, L0Conversation, QFilterCondition> {}

extension L0ConversationQuerySortBy
    on QueryBuilder<L0Conversation, L0Conversation, QSortBy> {
  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy>
      sortByAssistantText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assistantText', Sort.asc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy>
      sortByAssistantTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assistantText', Sort.desc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy>
      sortByMessagesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messagesJson', Sort.asc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy>
      sortByMessagesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messagesJson', Sort.desc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy>
      sortByProcessedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'processedAt', Sort.asc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy>
      sortByProcessedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'processedAt', Sort.desc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy>
      sortByProcessedToL1() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'processedToL1', Sort.asc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy>
      sortByProcessedToL1Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'processedToL1', Sort.desc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy> sortBySessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.asc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy>
      sortBySessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.desc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy>
      sortBySessionKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionKey', Sort.asc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy>
      sortBySessionKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionKey', Sort.desc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy> sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy> sortByUserText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userText', Sort.asc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy>
      sortByUserTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userText', Sort.desc);
    });
  }
}

extension L0ConversationQuerySortThenBy
    on QueryBuilder<L0Conversation, L0Conversation, QSortThenBy> {
  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy>
      thenByAssistantText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assistantText', Sort.asc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy>
      thenByAssistantTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assistantText', Sort.desc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy>
      thenByMessagesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messagesJson', Sort.asc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy>
      thenByMessagesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messagesJson', Sort.desc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy>
      thenByProcessedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'processedAt', Sort.asc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy>
      thenByProcessedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'processedAt', Sort.desc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy>
      thenByProcessedToL1() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'processedToL1', Sort.asc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy>
      thenByProcessedToL1Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'processedToL1', Sort.desc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy> thenBySessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.asc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy>
      thenBySessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.desc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy>
      thenBySessionKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionKey', Sort.asc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy>
      thenBySessionKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionKey', Sort.desc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy> thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy> thenByUserText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userText', Sort.asc);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QAfterSortBy>
      thenByUserTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userText', Sort.desc);
    });
  }
}

extension L0ConversationQueryWhereDistinct
    on QueryBuilder<L0Conversation, L0Conversation, QDistinct> {
  QueryBuilder<L0Conversation, L0Conversation, QDistinct>
      distinctByAssistantText({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'assistantText',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QDistinct>
      distinctByMessagesJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'messagesJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QDistinct>
      distinctByProcessedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'processedAt');
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QDistinct>
      distinctByProcessedToL1() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'processedToL1');
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QDistinct> distinctBySessionId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sessionId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QDistinct> distinctBySessionKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sessionKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QDistinct>
      distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }

  QueryBuilder<L0Conversation, L0Conversation, QDistinct> distinctByUserText(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userText', caseSensitive: caseSensitive);
    });
  }
}

extension L0ConversationQueryProperty
    on QueryBuilder<L0Conversation, L0Conversation, QQueryProperty> {
  QueryBuilder<L0Conversation, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<L0Conversation, String, QQueryOperations>
      assistantTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'assistantText');
    });
  }

  QueryBuilder<L0Conversation, String, QQueryOperations>
      messagesJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'messagesJson');
    });
  }

  QueryBuilder<L0Conversation, DateTime?, QQueryOperations>
      processedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'processedAt');
    });
  }

  QueryBuilder<L0Conversation, bool, QQueryOperations> processedToL1Property() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'processedToL1');
    });
  }

  QueryBuilder<L0Conversation, String, QQueryOperations> sessionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sessionId');
    });
  }

  QueryBuilder<L0Conversation, String, QQueryOperations> sessionKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sessionKey');
    });
  }

  QueryBuilder<L0Conversation, DateTime, QQueryOperations> timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }

  QueryBuilder<L0Conversation, String, QQueryOperations> userTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userText');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetL1MemoryCollection on Isar {
  IsarCollection<L1Memory> get l1Memorys => this.collection();
}

const L1MemorySchema = CollectionSchema(
  name: r'L1Memory',
  id: 1037739842181505650,
  properties: {
    r'confidence': PropertySchema(
      id: 0,
      name: r'confidence',
      type: IsarType.double,
    ),
    r'content': PropertySchema(
      id: 1,
      name: r'content',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'embeddingJson': PropertySchema(
      id: 3,
      name: r'embeddingJson',
      type: IsarType.string,
    ),
    r'keywords': PropertySchema(
      id: 4,
      name: r'keywords',
      type: IsarType.stringList,
    ),
    r'sceneId': PropertySchema(
      id: 5,
      name: r'sceneId',
      type: IsarType.long,
    ),
    r'sessionKey': PropertySchema(
      id: 6,
      name: r'sessionKey',
      type: IsarType.string,
    ),
    r'sourceConversationIds': PropertySchema(
      id: 7,
      name: r'sourceConversationIds',
      type: IsarType.longList,
    ),
    r'type': PropertySchema(
      id: 8,
      name: r'type',
      type: IsarType.byte,
      enumMap: _L1MemorytypeEnumValueMap,
    ),
    r'updatedAt': PropertySchema(
      id: 9,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _l1MemoryEstimateSize,
  serialize: _l1MemorySerialize,
  deserialize: _l1MemoryDeserialize,
  deserializeProp: _l1MemoryDeserializeProp,
  idName: r'id',
  indexes: {
    r'sessionKey': IndexSchema(
      id: -4553619741042231539,
      name: r'sessionKey',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'sessionKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'sceneId': IndexSchema(
      id: -2132069569599388541,
      name: r'sceneId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'sceneId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _l1MemoryGetId,
  getLinks: _l1MemoryGetLinks,
  attach: _l1MemoryAttach,
  version: '3.1.0+1',
);

int _l1MemoryEstimateSize(
  L1Memory object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.content.length * 3;
  {
    final value = object.embeddingJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.keywords.length * 3;
  {
    for (var i = 0; i < object.keywords.length; i++) {
      final value = object.keywords[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.sessionKey.length * 3;
  bytesCount += 3 + object.sourceConversationIds.length * 8;
  return bytesCount;
}

void _l1MemorySerialize(
  L1Memory object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.confidence);
  writer.writeString(offsets[1], object.content);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.embeddingJson);
  writer.writeStringList(offsets[4], object.keywords);
  writer.writeLong(offsets[5], object.sceneId);
  writer.writeString(offsets[6], object.sessionKey);
  writer.writeLongList(offsets[7], object.sourceConversationIds);
  writer.writeByte(offsets[8], object.type.index);
  writer.writeDateTime(offsets[9], object.updatedAt);
}

L1Memory _l1MemoryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = L1Memory();
  object.confidence = reader.readDouble(offsets[0]);
  object.content = reader.readString(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.embeddingJson = reader.readStringOrNull(offsets[3]);
  object.id = id;
  object.keywords = reader.readStringList(offsets[4]) ?? [];
  object.sceneId = reader.readLongOrNull(offsets[5]);
  object.sessionKey = reader.readString(offsets[6]);
  object.sourceConversationIds = reader.readLongList(offsets[7]) ?? [];
  object.type = _L1MemorytypeValueEnumMap[reader.readByteOrNull(offsets[8])] ??
      MemoryType.fact;
  object.updatedAt = reader.readDateTimeOrNull(offsets[9]);
  return object;
}

P _l1MemoryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringList(offset) ?? []) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLongList(offset) ?? []) as P;
    case 8:
      return (_L1MemorytypeValueEnumMap[reader.readByteOrNull(offset)] ??
          MemoryType.fact) as P;
    case 9:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _L1MemorytypeEnumValueMap = {
  'fact': 0,
  'preference': 1,
  'goal': 2,
  'project': 3,
  'tool': 4,
  'code': 5,
  'learning': 6,
  'other': 7,
};
const _L1MemorytypeValueEnumMap = {
  0: MemoryType.fact,
  1: MemoryType.preference,
  2: MemoryType.goal,
  3: MemoryType.project,
  4: MemoryType.tool,
  5: MemoryType.code,
  6: MemoryType.learning,
  7: MemoryType.other,
};

Id _l1MemoryGetId(L1Memory object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _l1MemoryGetLinks(L1Memory object) {
  return [];
}

void _l1MemoryAttach(IsarCollection<dynamic> col, Id id, L1Memory object) {
  object.id = id;
}

extension L1MemoryQueryWhereSort on QueryBuilder<L1Memory, L1Memory, QWhere> {
  QueryBuilder<L1Memory, L1Memory, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterWhere> anySceneId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'sceneId'),
      );
    });
  }
}

extension L1MemoryQueryWhere on QueryBuilder<L1Memory, L1Memory, QWhereClause> {
  QueryBuilder<L1Memory, L1Memory, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<L1Memory, L1Memory, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterWhereClause> idBetween(
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

  QueryBuilder<L1Memory, L1Memory, QAfterWhereClause> sessionKeyEqualTo(
      String sessionKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sessionKey',
        value: [sessionKey],
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterWhereClause> sessionKeyNotEqualTo(
      String sessionKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionKey',
              lower: [],
              upper: [sessionKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionKey',
              lower: [sessionKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionKey',
              lower: [sessionKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionKey',
              lower: [],
              upper: [sessionKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterWhereClause> sceneIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sceneId',
        value: [null],
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterWhereClause> sceneIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'sceneId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterWhereClause> sceneIdEqualTo(
      int? sceneId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sceneId',
        value: [sceneId],
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterWhereClause> sceneIdNotEqualTo(
      int? sceneId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sceneId',
              lower: [],
              upper: [sceneId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sceneId',
              lower: [sceneId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sceneId',
              lower: [sceneId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sceneId',
              lower: [],
              upper: [sceneId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterWhereClause> sceneIdGreaterThan(
    int? sceneId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'sceneId',
        lower: [sceneId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterWhereClause> sceneIdLessThan(
    int? sceneId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'sceneId',
        lower: [],
        upper: [sceneId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterWhereClause> sceneIdBetween(
    int? lowerSceneId,
    int? upperSceneId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'sceneId',
        lower: [lowerSceneId],
        includeLower: includeLower,
        upper: [upperSceneId],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension L1MemoryQueryFilter
    on QueryBuilder<L1Memory, L1Memory, QFilterCondition> {
  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> confidenceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'confidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> confidenceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'confidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> confidenceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'confidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> confidenceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'confidence',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> contentEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> contentGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> contentLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> contentBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'content',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> contentStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> contentEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> contentContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> contentMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'content',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> contentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'content',
        value: '',
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> contentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'content',
        value: '',
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> createdAtGreaterThan(
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

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> createdAtLessThan(
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

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> createdAtBetween(
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

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      embeddingJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'embeddingJson',
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      embeddingJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'embeddingJson',
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> embeddingJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'embeddingJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      embeddingJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'embeddingJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> embeddingJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'embeddingJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> embeddingJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'embeddingJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      embeddingJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'embeddingJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> embeddingJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'embeddingJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> embeddingJsonContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'embeddingJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> embeddingJsonMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'embeddingJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      embeddingJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'embeddingJson',
        value: '',
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      embeddingJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'embeddingJson',
        value: '',
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> idBetween(
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

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      keywordsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'keywords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      keywordsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'keywords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      keywordsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'keywords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      keywordsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'keywords',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      keywordsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'keywords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      keywordsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'keywords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      keywordsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'keywords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      keywordsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'keywords',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      keywordsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'keywords',
        value: '',
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      keywordsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'keywords',
        value: '',
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> keywordsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'keywords',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> keywordsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'keywords',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> keywordsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'keywords',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      keywordsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'keywords',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      keywordsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'keywords',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> keywordsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'keywords',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> sceneIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sceneId',
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> sceneIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sceneId',
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> sceneIdEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sceneId',
        value: value,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> sceneIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sceneId',
        value: value,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> sceneIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sceneId',
        value: value,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> sceneIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sceneId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> sessionKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> sessionKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sessionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> sessionKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sessionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> sessionKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sessionKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> sessionKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sessionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> sessionKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sessionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> sessionKeyContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sessionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> sessionKeyMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sessionKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> sessionKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionKey',
        value: '',
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      sessionKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sessionKey',
        value: '',
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      sourceConversationIdsElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceConversationIds',
        value: value,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      sourceConversationIdsElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceConversationIds',
        value: value,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      sourceConversationIdsElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceConversationIds',
        value: value,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      sourceConversationIdsElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceConversationIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      sourceConversationIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sourceConversationIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      sourceConversationIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sourceConversationIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      sourceConversationIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sourceConversationIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      sourceConversationIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sourceConversationIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      sourceConversationIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sourceConversationIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition>
      sourceConversationIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sourceConversationIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> typeEqualTo(
      MemoryType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> typeGreaterThan(
    MemoryType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> typeLessThan(
    MemoryType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> typeBetween(
    MemoryType lower,
    MemoryType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> updatedAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> updatedAtGreaterThan(
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

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> updatedAtLessThan(
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

  QueryBuilder<L1Memory, L1Memory, QAfterFilterCondition> updatedAtBetween(
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

extension L1MemoryQueryObject
    on QueryBuilder<L1Memory, L1Memory, QFilterCondition> {}

extension L1MemoryQueryLinks
    on QueryBuilder<L1Memory, L1Memory, QFilterCondition> {}

extension L1MemoryQuerySortBy on QueryBuilder<L1Memory, L1Memory, QSortBy> {
  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> sortByConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.asc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> sortByConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.desc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> sortByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> sortByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> sortByEmbeddingJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'embeddingJson', Sort.asc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> sortByEmbeddingJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'embeddingJson', Sort.desc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> sortBySceneId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sceneId', Sort.asc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> sortBySceneIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sceneId', Sort.desc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> sortBySessionKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionKey', Sort.asc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> sortBySessionKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionKey', Sort.desc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension L1MemoryQuerySortThenBy
    on QueryBuilder<L1Memory, L1Memory, QSortThenBy> {
  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> thenByConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.asc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> thenByConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.desc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> thenByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> thenByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> thenByEmbeddingJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'embeddingJson', Sort.asc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> thenByEmbeddingJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'embeddingJson', Sort.desc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> thenBySceneId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sceneId', Sort.asc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> thenBySceneIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sceneId', Sort.desc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> thenBySessionKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionKey', Sort.asc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> thenBySessionKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionKey', Sort.desc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension L1MemoryQueryWhereDistinct
    on QueryBuilder<L1Memory, L1Memory, QDistinct> {
  QueryBuilder<L1Memory, L1Memory, QDistinct> distinctByConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'confidence');
    });
  }

  QueryBuilder<L1Memory, L1Memory, QDistinct> distinctByContent(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'content', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<L1Memory, L1Memory, QDistinct> distinctByEmbeddingJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'embeddingJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QDistinct> distinctByKeywords() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'keywords');
    });
  }

  QueryBuilder<L1Memory, L1Memory, QDistinct> distinctBySceneId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sceneId');
    });
  }

  QueryBuilder<L1Memory, L1Memory, QDistinct> distinctBySessionKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sessionKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<L1Memory, L1Memory, QDistinct>
      distinctBySourceConversationIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceConversationIds');
    });
  }

  QueryBuilder<L1Memory, L1Memory, QDistinct> distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type');
    });
  }

  QueryBuilder<L1Memory, L1Memory, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension L1MemoryQueryProperty
    on QueryBuilder<L1Memory, L1Memory, QQueryProperty> {
  QueryBuilder<L1Memory, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<L1Memory, double, QQueryOperations> confidenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'confidence');
    });
  }

  QueryBuilder<L1Memory, String, QQueryOperations> contentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'content');
    });
  }

  QueryBuilder<L1Memory, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<L1Memory, String?, QQueryOperations> embeddingJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'embeddingJson');
    });
  }

  QueryBuilder<L1Memory, List<String>, QQueryOperations> keywordsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'keywords');
    });
  }

  QueryBuilder<L1Memory, int?, QQueryOperations> sceneIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sceneId');
    });
  }

  QueryBuilder<L1Memory, String, QQueryOperations> sessionKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sessionKey');
    });
  }

  QueryBuilder<L1Memory, List<int>, QQueryOperations>
      sourceConversationIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceConversationIds');
    });
  }

  QueryBuilder<L1Memory, MemoryType, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<L1Memory, DateTime?, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetL2SceneCollection on Isar {
  IsarCollection<L2Scene> get l2Scenes => this.collection();
}

const L2SceneSchema = CollectionSchema(
  name: r'L2Scene',
  id: 5615801949775767177,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'description': PropertySchema(
      id: 1,
      name: r'description',
      type: IsarType.string,
    ),
    r'embeddingJson': PropertySchema(
      id: 2,
      name: r'embeddingJson',
      type: IsarType.string,
    ),
    r'endTime': PropertySchema(
      id: 3,
      name: r'endTime',
      type: IsarType.dateTime,
    ),
    r'memoryIds': PropertySchema(
      id: 4,
      name: r'memoryIds',
      type: IsarType.longList,
    ),
    r'sessionKey': PropertySchema(
      id: 5,
      name: r'sessionKey',
      type: IsarType.string,
    ),
    r'startTime': PropertySchema(
      id: 6,
      name: r'startTime',
      type: IsarType.dateTime,
    ),
    r'tags': PropertySchema(
      id: 7,
      name: r'tags',
      type: IsarType.stringList,
    ),
    r'title': PropertySchema(
      id: 8,
      name: r'title',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 9,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _l2SceneEstimateSize,
  serialize: _l2SceneSerialize,
  deserialize: _l2SceneDeserialize,
  deserializeProp: _l2SceneDeserializeProp,
  idName: r'id',
  indexes: {
    r'sessionKey': IndexSchema(
      id: -4553619741042231539,
      name: r'sessionKey',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'sessionKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _l2SceneGetId,
  getLinks: _l2SceneGetLinks,
  attach: _l2SceneAttach,
  version: '3.1.0+1',
);

int _l2SceneEstimateSize(
  L2Scene object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.description.length * 3;
  {
    final value = object.embeddingJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.memoryIds.length * 8;
  bytesCount += 3 + object.sessionKey.length * 3;
  bytesCount += 3 + object.tags.length * 3;
  {
    for (var i = 0; i < object.tags.length; i++) {
      final value = object.tags[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _l2SceneSerialize(
  L2Scene object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.description);
  writer.writeString(offsets[2], object.embeddingJson);
  writer.writeDateTime(offsets[3], object.endTime);
  writer.writeLongList(offsets[4], object.memoryIds);
  writer.writeString(offsets[5], object.sessionKey);
  writer.writeDateTime(offsets[6], object.startTime);
  writer.writeStringList(offsets[7], object.tags);
  writer.writeString(offsets[8], object.title);
  writer.writeDateTime(offsets[9], object.updatedAt);
}

L2Scene _l2SceneDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = L2Scene();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.description = reader.readString(offsets[1]);
  object.embeddingJson = reader.readStringOrNull(offsets[2]);
  object.endTime = reader.readDateTimeOrNull(offsets[3]);
  object.id = id;
  object.memoryIds = reader.readLongList(offsets[4]) ?? [];
  object.sessionKey = reader.readString(offsets[5]);
  object.startTime = reader.readDateTimeOrNull(offsets[6]);
  object.tags = reader.readStringList(offsets[7]) ?? [];
  object.title = reader.readString(offsets[8]);
  object.updatedAt = reader.readDateTimeOrNull(offsets[9]);
  return object;
}

P _l2SceneDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readLongList(offset) ?? []) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readStringList(offset) ?? []) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _l2SceneGetId(L2Scene object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _l2SceneGetLinks(L2Scene object) {
  return [];
}

void _l2SceneAttach(IsarCollection<dynamic> col, Id id, L2Scene object) {
  object.id = id;
}

extension L2SceneQueryWhereSort on QueryBuilder<L2Scene, L2Scene, QWhere> {
  QueryBuilder<L2Scene, L2Scene, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension L2SceneQueryWhere on QueryBuilder<L2Scene, L2Scene, QWhereClause> {
  QueryBuilder<L2Scene, L2Scene, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<L2Scene, L2Scene, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterWhereClause> idBetween(
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

  QueryBuilder<L2Scene, L2Scene, QAfterWhereClause> sessionKeyEqualTo(
      String sessionKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sessionKey',
        value: [sessionKey],
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterWhereClause> sessionKeyNotEqualTo(
      String sessionKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionKey',
              lower: [],
              upper: [sessionKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionKey',
              lower: [sessionKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionKey',
              lower: [sessionKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionKey',
              lower: [],
              upper: [sessionKey],
              includeUpper: false,
            ));
      }
    });
  }
}

extension L2SceneQueryFilter
    on QueryBuilder<L2Scene, L2Scene, QFilterCondition> {
  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> createdAtGreaterThan(
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

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> createdAtLessThan(
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

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> createdAtBetween(
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

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> descriptionEqualTo(
    String value, {
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

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> descriptionGreaterThan(
    String value, {
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

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> descriptionLessThan(
    String value, {
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

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> descriptionBetween(
    String lower,
    String upper, {
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

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> descriptionStartsWith(
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

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> descriptionEndsWith(
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

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> descriptionContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> descriptionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> embeddingJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'embeddingJson',
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition>
      embeddingJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'embeddingJson',
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> embeddingJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'embeddingJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition>
      embeddingJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'embeddingJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> embeddingJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'embeddingJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> embeddingJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'embeddingJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> embeddingJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'embeddingJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> embeddingJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'embeddingJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> embeddingJsonContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'embeddingJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> embeddingJsonMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'embeddingJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> embeddingJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'embeddingJson',
        value: '',
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition>
      embeddingJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'embeddingJson',
        value: '',
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> endTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'endTime',
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> endTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'endTime',
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> endTimeEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endTime',
        value: value,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> endTimeGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endTime',
        value: value,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> endTimeLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endTime',
        value: value,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> endTimeBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> idBetween(
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

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> memoryIdsElementEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'memoryIds',
        value: value,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition>
      memoryIdsElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'memoryIds',
        value: value,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition>
      memoryIdsElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'memoryIds',
        value: value,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> memoryIdsElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'memoryIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> memoryIdsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'memoryIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> memoryIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'memoryIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> memoryIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'memoryIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> memoryIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'memoryIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition>
      memoryIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'memoryIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> memoryIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'memoryIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> sessionKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> sessionKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sessionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> sessionKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sessionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> sessionKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sessionKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> sessionKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sessionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> sessionKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sessionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> sessionKeyContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sessionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> sessionKeyMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sessionKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> sessionKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionKey',
        value: '',
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> sessionKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sessionKey',
        value: '',
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> startTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'startTime',
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> startTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'startTime',
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> startTimeEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startTime',
        value: value,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> startTimeGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startTime',
        value: value,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> startTimeLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startTime',
        value: value,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> startTimeBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> tagsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> tagsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> tagsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> tagsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tags',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> tagsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> tagsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> tagsElementContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> tagsElementMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tags',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> tagsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tags',
        value: '',
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition>
      tagsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tags',
        value: '',
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> tagsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> tagsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> tagsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> tagsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> tagsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> tagsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> titleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> titleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> updatedAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> updatedAtGreaterThan(
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

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> updatedAtLessThan(
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

  QueryBuilder<L2Scene, L2Scene, QAfterFilterCondition> updatedAtBetween(
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

extension L2SceneQueryObject
    on QueryBuilder<L2Scene, L2Scene, QFilterCondition> {}

extension L2SceneQueryLinks
    on QueryBuilder<L2Scene, L2Scene, QFilterCondition> {}

extension L2SceneQuerySortBy on QueryBuilder<L2Scene, L2Scene, QSortBy> {
  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> sortByEmbeddingJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'embeddingJson', Sort.asc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> sortByEmbeddingJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'embeddingJson', Sort.desc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> sortByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.asc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> sortByEndTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.desc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> sortBySessionKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionKey', Sort.asc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> sortBySessionKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionKey', Sort.desc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> sortByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.asc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> sortByStartTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.desc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension L2SceneQuerySortThenBy
    on QueryBuilder<L2Scene, L2Scene, QSortThenBy> {
  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> thenByEmbeddingJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'embeddingJson', Sort.asc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> thenByEmbeddingJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'embeddingJson', Sort.desc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> thenByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.asc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> thenByEndTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.desc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> thenBySessionKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionKey', Sort.asc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> thenBySessionKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionKey', Sort.desc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> thenByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.asc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> thenByStartTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.desc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension L2SceneQueryWhereDistinct
    on QueryBuilder<L2Scene, L2Scene, QDistinct> {
  QueryBuilder<L2Scene, L2Scene, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<L2Scene, L2Scene, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QDistinct> distinctByEmbeddingJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'embeddingJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QDistinct> distinctByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endTime');
    });
  }

  QueryBuilder<L2Scene, L2Scene, QDistinct> distinctByMemoryIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'memoryIds');
    });
  }

  QueryBuilder<L2Scene, L2Scene, QDistinct> distinctBySessionKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sessionKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QDistinct> distinctByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startTime');
    });
  }

  QueryBuilder<L2Scene, L2Scene, QDistinct> distinctByTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tags');
    });
  }

  QueryBuilder<L2Scene, L2Scene, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<L2Scene, L2Scene, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension L2SceneQueryProperty
    on QueryBuilder<L2Scene, L2Scene, QQueryProperty> {
  QueryBuilder<L2Scene, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<L2Scene, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<L2Scene, String, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<L2Scene, String?, QQueryOperations> embeddingJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'embeddingJson');
    });
  }

  QueryBuilder<L2Scene, DateTime?, QQueryOperations> endTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endTime');
    });
  }

  QueryBuilder<L2Scene, List<int>, QQueryOperations> memoryIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'memoryIds');
    });
  }

  QueryBuilder<L2Scene, String, QQueryOperations> sessionKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sessionKey');
    });
  }

  QueryBuilder<L2Scene, DateTime?, QQueryOperations> startTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startTime');
    });
  }

  QueryBuilder<L2Scene, List<String>, QQueryOperations> tagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tags');
    });
  }

  QueryBuilder<L2Scene, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<L2Scene, DateTime?, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetL3PersonaCollection on Isar {
  IsarCollection<L3Persona> get l3Personas => this.collection();
}

const L3PersonaSchema = CollectionSchema(
  name: r'L3Persona',
  id: 914478283885287151,
  properties: {
    r'communicationStyle': PropertySchema(
      id: 0,
      name: r'communicationStyle',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'preferences': PropertySchema(
      id: 2,
      name: r'preferences',
      type: IsarType.string,
    ),
    r'preferredTools': PropertySchema(
      id: 3,
      name: r'preferredTools',
      type: IsarType.stringList,
    ),
    r'projectContext': PropertySchema(
      id: 4,
      name: r'projectContext',
      type: IsarType.string,
    ),
    r'skills': PropertySchema(
      id: 5,
      name: r'skills',
      type: IsarType.string,
    ),
    r'sourceSceneIds': PropertySchema(
      id: 6,
      name: r'sourceSceneIds',
      type: IsarType.longList,
    ),
    r'updatedAt': PropertySchema(
      id: 7,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'userId': PropertySchema(
      id: 8,
      name: r'userId',
      type: IsarType.string,
    ),
    r'version': PropertySchema(
      id: 9,
      name: r'version',
      type: IsarType.long,
    )
  },
  estimateSize: _l3PersonaEstimateSize,
  serialize: _l3PersonaSerialize,
  deserialize: _l3PersonaDeserialize,
  deserializeProp: _l3PersonaDeserializeProp,
  idName: r'id',
  indexes: {
    r'userId': IndexSchema(
      id: -2005826577402374815,
      name: r'userId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'userId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _l3PersonaGetId,
  getLinks: _l3PersonaGetLinks,
  attach: _l3PersonaAttach,
  version: '3.1.0+1',
);

int _l3PersonaEstimateSize(
  L3Persona object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.communicationStyle;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.preferences.length * 3;
  bytesCount += 3 + object.preferredTools.length * 3;
  {
    for (var i = 0; i < object.preferredTools.length; i++) {
      final value = object.preferredTools[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.projectContext;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.skills;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.sourceSceneIds.length * 8;
  bytesCount += 3 + object.userId.length * 3;
  return bytesCount;
}

void _l3PersonaSerialize(
  L3Persona object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.communicationStyle);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.preferences);
  writer.writeStringList(offsets[3], object.preferredTools);
  writer.writeString(offsets[4], object.projectContext);
  writer.writeString(offsets[5], object.skills);
  writer.writeLongList(offsets[6], object.sourceSceneIds);
  writer.writeDateTime(offsets[7], object.updatedAt);
  writer.writeString(offsets[8], object.userId);
  writer.writeLong(offsets[9], object.version);
}

L3Persona _l3PersonaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = L3Persona();
  object.communicationStyle = reader.readStringOrNull(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.id = id;
  object.preferences = reader.readString(offsets[2]);
  object.preferredTools = reader.readStringList(offsets[3]) ?? [];
  object.projectContext = reader.readStringOrNull(offsets[4]);
  object.skills = reader.readStringOrNull(offsets[5]);
  object.sourceSceneIds = reader.readLongList(offsets[6]) ?? [];
  object.updatedAt = reader.readDateTime(offsets[7]);
  object.userId = reader.readString(offsets[8]);
  object.version = reader.readLong(offsets[9]);
  return object;
}

P _l3PersonaDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringList(offset) ?? []) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readLongList(offset) ?? []) as P;
    case 7:
      return (reader.readDateTime(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _l3PersonaGetId(L3Persona object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _l3PersonaGetLinks(L3Persona object) {
  return [];
}

void _l3PersonaAttach(IsarCollection<dynamic> col, Id id, L3Persona object) {
  object.id = id;
}

extension L3PersonaByIndex on IsarCollection<L3Persona> {
  Future<L3Persona?> getByUserId(String userId) {
    return getByIndex(r'userId', [userId]);
  }

  L3Persona? getByUserIdSync(String userId) {
    return getByIndexSync(r'userId', [userId]);
  }

  Future<bool> deleteByUserId(String userId) {
    return deleteByIndex(r'userId', [userId]);
  }

  bool deleteByUserIdSync(String userId) {
    return deleteByIndexSync(r'userId', [userId]);
  }

  Future<List<L3Persona?>> getAllByUserId(List<String> userIdValues) {
    final values = userIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'userId', values);
  }

  List<L3Persona?> getAllByUserIdSync(List<String> userIdValues) {
    final values = userIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'userId', values);
  }

  Future<int> deleteAllByUserId(List<String> userIdValues) {
    final values = userIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'userId', values);
  }

  int deleteAllByUserIdSync(List<String> userIdValues) {
    final values = userIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'userId', values);
  }

  Future<Id> putByUserId(L3Persona object) {
    return putByIndex(r'userId', object);
  }

  Id putByUserIdSync(L3Persona object, {bool saveLinks = true}) {
    return putByIndexSync(r'userId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUserId(List<L3Persona> objects) {
    return putAllByIndex(r'userId', objects);
  }

  List<Id> putAllByUserIdSync(List<L3Persona> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'userId', objects, saveLinks: saveLinks);
  }
}

extension L3PersonaQueryWhereSort
    on QueryBuilder<L3Persona, L3Persona, QWhere> {
  QueryBuilder<L3Persona, L3Persona, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension L3PersonaQueryWhere
    on QueryBuilder<L3Persona, L3Persona, QWhereClause> {
  QueryBuilder<L3Persona, L3Persona, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<L3Persona, L3Persona, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterWhereClause> idBetween(
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

  QueryBuilder<L3Persona, L3Persona, QAfterWhereClause> userIdEqualTo(
      String userId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userId',
        value: [userId],
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterWhereClause> userIdNotEqualTo(
      String userId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [],
              upper: [userId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [userId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [userId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [],
              upper: [userId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension L3PersonaQueryFilter
    on QueryBuilder<L3Persona, L3Persona, QFilterCondition> {
  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      communicationStyleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'communicationStyle',
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      communicationStyleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'communicationStyle',
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      communicationStyleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'communicationStyle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      communicationStyleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'communicationStyle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      communicationStyleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'communicationStyle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      communicationStyleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'communicationStyle',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      communicationStyleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'communicationStyle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      communicationStyleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'communicationStyle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      communicationStyleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'communicationStyle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      communicationStyleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'communicationStyle',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      communicationStyleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'communicationStyle',
        value: '',
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      communicationStyleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'communicationStyle',
        value: '',
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
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

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> createdAtLessThan(
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

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> createdAtBetween(
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

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> idBetween(
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

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> preferencesEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'preferences',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      preferencesGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'preferences',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> preferencesLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'preferences',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> preferencesBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'preferences',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      preferencesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'preferences',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> preferencesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'preferences',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> preferencesContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'preferences',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> preferencesMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'preferences',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      preferencesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'preferences',
        value: '',
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      preferencesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'preferences',
        value: '',
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      preferredToolsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'preferredTools',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      preferredToolsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'preferredTools',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      preferredToolsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'preferredTools',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      preferredToolsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'preferredTools',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      preferredToolsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'preferredTools',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      preferredToolsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'preferredTools',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      preferredToolsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'preferredTools',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      preferredToolsElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'preferredTools',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      preferredToolsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'preferredTools',
        value: '',
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      preferredToolsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'preferredTools',
        value: '',
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      preferredToolsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'preferredTools',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      preferredToolsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'preferredTools',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      preferredToolsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'preferredTools',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      preferredToolsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'preferredTools',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      preferredToolsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'preferredTools',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      preferredToolsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'preferredTools',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      projectContextIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'projectContext',
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      projectContextIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'projectContext',
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      projectContextEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'projectContext',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      projectContextGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'projectContext',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      projectContextLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'projectContext',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      projectContextBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'projectContext',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      projectContextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'projectContext',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      projectContextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'projectContext',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      projectContextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'projectContext',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      projectContextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'projectContext',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      projectContextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'projectContext',
        value: '',
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      projectContextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'projectContext',
        value: '',
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> skillsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'skills',
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> skillsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'skills',
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> skillsEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'skills',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> skillsGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'skills',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> skillsLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'skills',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> skillsBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'skills',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> skillsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'skills',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> skillsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'skills',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> skillsContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'skills',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> skillsMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'skills',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> skillsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'skills',
        value: '',
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> skillsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'skills',
        value: '',
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      sourceSceneIdsElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceSceneIds',
        value: value,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      sourceSceneIdsElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceSceneIds',
        value: value,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      sourceSceneIdsElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceSceneIds',
        value: value,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      sourceSceneIdsElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceSceneIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      sourceSceneIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sourceSceneIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      sourceSceneIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sourceSceneIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      sourceSceneIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sourceSceneIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      sourceSceneIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sourceSceneIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      sourceSceneIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sourceSceneIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
      sourceSceneIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sourceSceneIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> updatedAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition>
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

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> updatedAtLessThan(
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

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> updatedAtBetween(
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

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> userIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> userIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> userIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> userIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> userIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> userIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> userIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> userIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> versionEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> versionGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> versionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterFilterCondition> versionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'version',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension L3PersonaQueryObject
    on QueryBuilder<L3Persona, L3Persona, QFilterCondition> {}

extension L3PersonaQueryLinks
    on QueryBuilder<L3Persona, L3Persona, QFilterCondition> {}

extension L3PersonaQuerySortBy on QueryBuilder<L3Persona, L3Persona, QSortBy> {
  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> sortByCommunicationStyle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'communicationStyle', Sort.asc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy>
      sortByCommunicationStyleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'communicationStyle', Sort.desc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> sortByPreferences() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferences', Sort.asc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> sortByPreferencesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferences', Sort.desc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> sortByProjectContext() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectContext', Sort.asc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> sortByProjectContextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectContext', Sort.desc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> sortBySkills() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skills', Sort.asc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> sortBySkillsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skills', Sort.desc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> sortByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> sortByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension L3PersonaQuerySortThenBy
    on QueryBuilder<L3Persona, L3Persona, QSortThenBy> {
  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> thenByCommunicationStyle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'communicationStyle', Sort.asc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy>
      thenByCommunicationStyleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'communicationStyle', Sort.desc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> thenByPreferences() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferences', Sort.asc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> thenByPreferencesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferences', Sort.desc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> thenByProjectContext() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectContext', Sort.asc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> thenByProjectContextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectContext', Sort.desc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> thenBySkills() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skills', Sort.asc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> thenBySkillsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skills', Sort.desc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> thenByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QAfterSortBy> thenByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension L3PersonaQueryWhereDistinct
    on QueryBuilder<L3Persona, L3Persona, QDistinct> {
  QueryBuilder<L3Persona, L3Persona, QDistinct> distinctByCommunicationStyle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'communicationStyle',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<L3Persona, L3Persona, QDistinct> distinctByPreferences(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'preferences', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QDistinct> distinctByPreferredTools() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'preferredTools');
    });
  }

  QueryBuilder<L3Persona, L3Persona, QDistinct> distinctByProjectContext(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'projectContext',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QDistinct> distinctBySkills(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'skills', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QDistinct> distinctBySourceSceneIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceSceneIds');
    });
  }

  QueryBuilder<L3Persona, L3Persona, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<L3Persona, L3Persona, QDistinct> distinctByUserId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<L3Persona, L3Persona, QDistinct> distinctByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'version');
    });
  }
}

extension L3PersonaQueryProperty
    on QueryBuilder<L3Persona, L3Persona, QQueryProperty> {
  QueryBuilder<L3Persona, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<L3Persona, String?, QQueryOperations>
      communicationStyleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'communicationStyle');
    });
  }

  QueryBuilder<L3Persona, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<L3Persona, String, QQueryOperations> preferencesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'preferences');
    });
  }

  QueryBuilder<L3Persona, List<String>, QQueryOperations>
      preferredToolsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'preferredTools');
    });
  }

  QueryBuilder<L3Persona, String?, QQueryOperations> projectContextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'projectContext');
    });
  }

  QueryBuilder<L3Persona, String?, QQueryOperations> skillsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'skills');
    });
  }

  QueryBuilder<L3Persona, List<int>, QQueryOperations>
      sourceSceneIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceSceneIds');
    });
  }

  QueryBuilder<L3Persona, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<L3Persona, String, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }

  QueryBuilder<L3Persona, int, QQueryOperations> versionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'version');
    });
  }
}
