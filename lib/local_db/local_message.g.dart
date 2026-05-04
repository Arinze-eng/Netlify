// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_message.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLocalMessageCollection on Isar {
  IsarCollection<LocalMessage> get localMessages => this.collection();
}

const LocalMessageSchema = CollectionSchema(
  name: r'LocalMessage',
  id: 1045835317208282169,
  properties: {
    r'caption': PropertySchema(
      id: 0,
      name: r'caption',
      type: IsarType.string,
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
    r'deletedAt': PropertySchema(
      id: 3,
      name: r'deletedAt',
      type: IsarType.dateTime,
    ),
    r'deletedForReceiver': PropertySchema(
      id: 4,
      name: r'deletedForReceiver',
      type: IsarType.bool,
    ),
    r'deletedForSender': PropertySchema(
      id: 5,
      name: r'deletedForSender',
      type: IsarType.bool,
    ),
    r'editedAt': PropertySchema(
      id: 6,
      name: r'editedAt',
      type: IsarType.dateTime,
    ),
    r'expiresAt': PropertySchema(
      id: 7,
      name: r'expiresAt',
      type: IsarType.dateTime,
    ),
    r'isLiked': PropertySchema(
      id: 8,
      name: r'isLiked',
      type: IsarType.bool,
    ),
    r'isPinned': PropertySchema(
      id: 9,
      name: r'isPinned',
      type: IsarType.bool,
    ),
    r'isRead': PropertySchema(
      id: 10,
      name: r'isRead',
      type: IsarType.bool,
    ),
    r'localMediaPath': PropertySchema(
      id: 11,
      name: r'localMediaPath',
      type: IsarType.string,
    ),
    r'mediaDurationMs': PropertySchema(
      id: 12,
      name: r'mediaDurationMs',
      type: IsarType.long,
    ),
    r'mediaExpiresAt': PropertySchema(
      id: 13,
      name: r'mediaExpiresAt',
      type: IsarType.dateTime,
    ),
    r'mediaMime': PropertySchema(
      id: 14,
      name: r'mediaMime',
      type: IsarType.string,
    ),
    r'mediaName': PropertySchema(
      id: 15,
      name: r'mediaName',
      type: IsarType.string,
    ),
    r'mediaPath': PropertySchema(
      id: 16,
      name: r'mediaPath',
      type: IsarType.string,
    ),
    r'mediaSizeBytes': PropertySchema(
      id: 17,
      name: r'mediaSizeBytes',
      type: IsarType.long,
    ),
    r'messageType': PropertySchema(
      id: 18,
      name: r'messageType',
      type: IsarType.string,
    ),
    r'otherUserId': PropertySchema(
      id: 19,
      name: r'otherUserId',
      type: IsarType.string,
    ),
    r'ownerUserId': PropertySchema(
      id: 20,
      name: r'ownerUserId',
      type: IsarType.string,
    ),
    r'reactions': PropertySchema(
      id: 21,
      name: r'reactions',
      type: IsarType.string,
    ),
    r'receiverId': PropertySchema(
      id: 22,
      name: r'receiverId',
      type: IsarType.string,
    ),
    r'remoteId': PropertySchema(
      id: 23,
      name: r'remoteId',
      type: IsarType.long,
    ),
    r'replyToRemoteId': PropertySchema(
      id: 24,
      name: r'replyToRemoteId',
      type: IsarType.long,
    ),
    r'senderId': PropertySchema(
      id: 25,
      name: r'senderId',
      type: IsarType.string,
    ),
    r'viewOnce': PropertySchema(
      id: 26,
      name: r'viewOnce',
      type: IsarType.bool,
    ),
    r'viewedByReceiver': PropertySchema(
      id: 27,
      name: r'viewedByReceiver',
      type: IsarType.bool,
    ),
    r'viewedBySender': PropertySchema(
      id: 28,
      name: r'viewedBySender',
      type: IsarType.bool,
    )
  },
  estimateSize: _localMessageEstimateSize,
  serialize: _localMessageSerialize,
  deserialize: _localMessageDeserialize,
  deserializeProp: _localMessageDeserializeProp,
  idName: r'id',
  indexes: {
    r'remoteId': IndexSchema(
      id: 6301175856541681032,
      name: r'remoteId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'remoteId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'ownerUserId': IndexSchema(
      id: 1631799950038639233,
      name: r'ownerUserId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'ownerUserId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'otherUserId': IndexSchema(
      id: -5407668344836905452,
      name: r'otherUserId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'otherUserId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _localMessageGetId,
  getLinks: _localMessageGetLinks,
  attach: _localMessageAttach,
  version: '3.1.0+1',
);

int _localMessageEstimateSize(
  LocalMessage object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.caption;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.content.length * 3;
  {
    final value = object.localMediaPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.mediaMime;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.mediaName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.mediaPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.messageType.length * 3;
  bytesCount += 3 + object.otherUserId.length * 3;
  bytesCount += 3 + object.ownerUserId.length * 3;
  {
    final value = object.reactions;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.receiverId.length * 3;
  bytesCount += 3 + object.senderId.length * 3;
  return bytesCount;
}

void _localMessageSerialize(
  LocalMessage object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.caption);
  writer.writeString(offsets[1], object.content);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeDateTime(offsets[3], object.deletedAt);
  writer.writeBool(offsets[4], object.deletedForReceiver);
  writer.writeBool(offsets[5], object.deletedForSender);
  writer.writeDateTime(offsets[6], object.editedAt);
  writer.writeDateTime(offsets[7], object.expiresAt);
  writer.writeBool(offsets[8], object.isLiked);
  writer.writeBool(offsets[9], object.isPinned);
  writer.writeBool(offsets[10], object.isRead);
  writer.writeString(offsets[11], object.localMediaPath);
  writer.writeLong(offsets[12], object.mediaDurationMs);
  writer.writeDateTime(offsets[13], object.mediaExpiresAt);
  writer.writeString(offsets[14], object.mediaMime);
  writer.writeString(offsets[15], object.mediaName);
  writer.writeString(offsets[16], object.mediaPath);
  writer.writeLong(offsets[17], object.mediaSizeBytes);
  writer.writeString(offsets[18], object.messageType);
  writer.writeString(offsets[19], object.otherUserId);
  writer.writeString(offsets[20], object.ownerUserId);
  writer.writeString(offsets[21], object.reactions);
  writer.writeString(offsets[22], object.receiverId);
  writer.writeLong(offsets[23], object.remoteId);
  writer.writeLong(offsets[24], object.replyToRemoteId);
  writer.writeString(offsets[25], object.senderId);
  writer.writeBool(offsets[26], object.viewOnce);
  writer.writeBool(offsets[27], object.viewedByReceiver);
  writer.writeBool(offsets[28], object.viewedBySender);
}

LocalMessage _localMessageDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LocalMessage();
  object.caption = reader.readStringOrNull(offsets[0]);
  object.content = reader.readString(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.deletedAt = reader.readDateTimeOrNull(offsets[3]);
  object.deletedForReceiver = reader.readBool(offsets[4]);
  object.deletedForSender = reader.readBool(offsets[5]);
  object.editedAt = reader.readDateTimeOrNull(offsets[6]);
  object.expiresAt = reader.readDateTimeOrNull(offsets[7]);
  object.id = id;
  object.isLiked = reader.readBool(offsets[8]);
  object.isPinned = reader.readBool(offsets[9]);
  object.isRead = reader.readBool(offsets[10]);
  object.localMediaPath = reader.readStringOrNull(offsets[11]);
  object.mediaDurationMs = reader.readLongOrNull(offsets[12]);
  object.mediaExpiresAt = reader.readDateTimeOrNull(offsets[13]);
  object.mediaMime = reader.readStringOrNull(offsets[14]);
  object.mediaName = reader.readStringOrNull(offsets[15]);
  object.mediaPath = reader.readStringOrNull(offsets[16]);
  object.mediaSizeBytes = reader.readLongOrNull(offsets[17]);
  object.messageType = reader.readString(offsets[18]);
  object.otherUserId = reader.readString(offsets[19]);
  object.ownerUserId = reader.readString(offsets[20]);
  object.reactions = reader.readStringOrNull(offsets[21]);
  object.receiverId = reader.readString(offsets[22]);
  object.remoteId = reader.readLongOrNull(offsets[23]);
  object.replyToRemoteId = reader.readLongOrNull(offsets[24]);
  object.senderId = reader.readString(offsets[25]);
  object.viewOnce = reader.readBool(offsets[26]);
  object.viewedByReceiver = reader.readBool(offsets[27]);
  object.viewedBySender = reader.readBool(offsets[28]);
  return object;
}

P _localMessageDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readLongOrNull(offset)) as P;
    case 13:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (reader.readLongOrNull(offset)) as P;
    case 18:
      return (reader.readString(offset)) as P;
    case 19:
      return (reader.readString(offset)) as P;
    case 20:
      return (reader.readString(offset)) as P;
    case 21:
      return (reader.readStringOrNull(offset)) as P;
    case 22:
      return (reader.readString(offset)) as P;
    case 23:
      return (reader.readLongOrNull(offset)) as P;
    case 24:
      return (reader.readLongOrNull(offset)) as P;
    case 25:
      return (reader.readString(offset)) as P;
    case 26:
      return (reader.readBool(offset)) as P;
    case 27:
      return (reader.readBool(offset)) as P;
    case 28:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _localMessageGetId(LocalMessage object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _localMessageGetLinks(LocalMessage object) {
  return [];
}

void _localMessageAttach(
    IsarCollection<dynamic> col, Id id, LocalMessage object) {
  object.id = id;
}

extension LocalMessageByIndex on IsarCollection<LocalMessage> {
  Future<LocalMessage?> getByRemoteId(int? remoteId) {
    return getByIndex(r'remoteId', [remoteId]);
  }

  LocalMessage? getByRemoteIdSync(int? remoteId) {
    return getByIndexSync(r'remoteId', [remoteId]);
  }

  Future<bool> deleteByRemoteId(int? remoteId) {
    return deleteByIndex(r'remoteId', [remoteId]);
  }

  bool deleteByRemoteIdSync(int? remoteId) {
    return deleteByIndexSync(r'remoteId', [remoteId]);
  }

  Future<List<LocalMessage?>> getAllByRemoteId(List<int?> remoteIdValues) {
    final values = remoteIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'remoteId', values);
  }

  List<LocalMessage?> getAllByRemoteIdSync(List<int?> remoteIdValues) {
    final values = remoteIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'remoteId', values);
  }

  Future<int> deleteAllByRemoteId(List<int?> remoteIdValues) {
    final values = remoteIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'remoteId', values);
  }

  int deleteAllByRemoteIdSync(List<int?> remoteIdValues) {
    final values = remoteIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'remoteId', values);
  }

  Future<Id> putByRemoteId(LocalMessage object) {
    return putByIndex(r'remoteId', object);
  }

  Id putByRemoteIdSync(LocalMessage object, {bool saveLinks = true}) {
    return putByIndexSync(r'remoteId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByRemoteId(List<LocalMessage> objects) {
    return putAllByIndex(r'remoteId', objects);
  }

  List<Id> putAllByRemoteIdSync(List<LocalMessage> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'remoteId', objects, saveLinks: saveLinks);
  }
}

extension LocalMessageQueryWhereSort
    on QueryBuilder<LocalMessage, LocalMessage, QWhere> {
  QueryBuilder<LocalMessage, LocalMessage, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterWhere> anyRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'remoteId'),
      );
    });
  }
}

extension LocalMessageQueryWhere
    on QueryBuilder<LocalMessage, LocalMessage, QWhereClause> {
  QueryBuilder<LocalMessage, LocalMessage, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<LocalMessage, LocalMessage, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterWhereClause> idBetween(
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

  QueryBuilder<LocalMessage, LocalMessage, QAfterWhereClause> remoteIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'remoteId',
        value: [null],
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterWhereClause>
      remoteIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'remoteId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterWhereClause> remoteIdEqualTo(
      int? remoteId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'remoteId',
        value: [remoteId],
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterWhereClause>
      remoteIdNotEqualTo(int? remoteId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'remoteId',
              lower: [],
              upper: [remoteId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'remoteId',
              lower: [remoteId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'remoteId',
              lower: [remoteId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'remoteId',
              lower: [],
              upper: [remoteId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterWhereClause>
      remoteIdGreaterThan(
    int? remoteId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'remoteId',
        lower: [remoteId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterWhereClause> remoteIdLessThan(
    int? remoteId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'remoteId',
        lower: [],
        upper: [remoteId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterWhereClause> remoteIdBetween(
    int? lowerRemoteId,
    int? upperRemoteId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'remoteId',
        lower: [lowerRemoteId],
        includeLower: includeLower,
        upper: [upperRemoteId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterWhereClause>
      ownerUserIdEqualTo(String ownerUserId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ownerUserId',
        value: [ownerUserId],
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterWhereClause>
      ownerUserIdNotEqualTo(String ownerUserId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUserId',
              lower: [],
              upper: [ownerUserId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUserId',
              lower: [ownerUserId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUserId',
              lower: [ownerUserId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUserId',
              lower: [],
              upper: [ownerUserId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterWhereClause>
      otherUserIdEqualTo(String otherUserId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'otherUserId',
        value: [otherUserId],
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterWhereClause>
      otherUserIdNotEqualTo(String otherUserId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'otherUserId',
              lower: [],
              upper: [otherUserId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'otherUserId',
              lower: [otherUserId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'otherUserId',
              lower: [otherUserId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'otherUserId',
              lower: [],
              upper: [otherUserId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension LocalMessageQueryFilter
    on QueryBuilder<LocalMessage, LocalMessage, QFilterCondition> {
  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      captionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'caption',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      captionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'caption',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      captionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'caption',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      captionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'caption',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      captionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'caption',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      captionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'caption',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      captionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'caption',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      captionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'caption',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      captionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'caption',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      captionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'caption',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      captionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'caption',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      captionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'caption',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      contentEqualTo(
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

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      contentGreaterThan(
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

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      contentLessThan(
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

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      contentBetween(
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

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      contentStartsWith(
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

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      contentEndsWith(
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

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      contentContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      contentMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'content',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      contentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'content',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      contentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'content',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
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

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
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

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
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

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      deletedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      deletedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      deletedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      deletedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deletedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      deletedForReceiverEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deletedForReceiver',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      deletedForSenderEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deletedForSender',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      editedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'editedAt',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      editedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'editedAt',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      editedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'editedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      editedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'editedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      editedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'editedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      editedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'editedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      expiresAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'expiresAt',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      expiresAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'expiresAt',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      expiresAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'expiresAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      expiresAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'expiresAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      expiresAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'expiresAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      expiresAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'expiresAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition> idBetween(
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

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      isLikedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isLiked',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      isPinnedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isPinned',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition> isReadEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isRead',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      localMediaPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'localMediaPath',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      localMediaPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'localMediaPath',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      localMediaPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localMediaPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      localMediaPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localMediaPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      localMediaPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localMediaPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      localMediaPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localMediaPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      localMediaPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'localMediaPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      localMediaPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'localMediaPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      localMediaPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'localMediaPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      localMediaPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'localMediaPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      localMediaPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localMediaPath',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      localMediaPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'localMediaPath',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaDurationMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mediaDurationMs',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaDurationMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mediaDurationMs',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaDurationMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaDurationMs',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaDurationMsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mediaDurationMs',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaDurationMsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mediaDurationMs',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaDurationMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mediaDurationMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaExpiresAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mediaExpiresAt',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaExpiresAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mediaExpiresAt',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaExpiresAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaExpiresAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaExpiresAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mediaExpiresAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaExpiresAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mediaExpiresAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaExpiresAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mediaExpiresAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaMimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mediaMime',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaMimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mediaMime',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaMimeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaMime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaMimeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mediaMime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaMimeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mediaMime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaMimeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mediaMime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaMimeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mediaMime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaMimeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mediaMime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaMimeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mediaMime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaMimeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mediaMime',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaMimeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaMime',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaMimeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mediaMime',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mediaName',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mediaName',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mediaName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mediaName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mediaName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mediaName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mediaName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mediaName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mediaName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaName',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mediaName',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mediaPath',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mediaPath',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mediaPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mediaPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mediaPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mediaPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mediaPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mediaPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mediaPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaPath',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mediaPath',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaSizeBytesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mediaSizeBytes',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaSizeBytesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mediaSizeBytes',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaSizeBytesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaSizeBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaSizeBytesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mediaSizeBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaSizeBytesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mediaSizeBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      mediaSizeBytesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mediaSizeBytes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      messageTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'messageType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      messageTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'messageType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      messageTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'messageType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      messageTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'messageType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      messageTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'messageType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      messageTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'messageType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      messageTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'messageType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      messageTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'messageType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      messageTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'messageType',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      messageTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'messageType',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      otherUserIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'otherUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      otherUserIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'otherUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      otherUserIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'otherUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      otherUserIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'otherUserId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      otherUserIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'otherUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      otherUserIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'otherUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      otherUserIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'otherUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      otherUserIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'otherUserId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      otherUserIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'otherUserId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      otherUserIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'otherUserId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      ownerUserIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      ownerUserIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ownerUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      ownerUserIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ownerUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      ownerUserIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ownerUserId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      ownerUserIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ownerUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      ownerUserIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ownerUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      ownerUserIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ownerUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      ownerUserIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ownerUserId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      ownerUserIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerUserId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      ownerUserIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ownerUserId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      reactionsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'reactions',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      reactionsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'reactions',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      reactionsEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reactions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      reactionsGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reactions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      reactionsLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reactions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      reactionsBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reactions',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      reactionsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'reactions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      reactionsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'reactions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      reactionsContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'reactions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      reactionsMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'reactions',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      reactionsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reactions',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      reactionsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'reactions',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      receiverIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'receiverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      receiverIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'receiverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      receiverIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'receiverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      receiverIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'receiverId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      receiverIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'receiverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      receiverIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'receiverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      receiverIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'receiverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      receiverIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'receiverId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      receiverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'receiverId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      receiverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'receiverId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      remoteIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'remoteId',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      remoteIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'remoteId',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      remoteIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remoteId',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      remoteIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remoteId',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      remoteIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remoteId',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      remoteIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remoteId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      replyToRemoteIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'replyToRemoteId',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      replyToRemoteIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'replyToRemoteId',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      replyToRemoteIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'replyToRemoteId',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      replyToRemoteIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'replyToRemoteId',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      replyToRemoteIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'replyToRemoteId',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      replyToRemoteIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'replyToRemoteId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      senderIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'senderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      senderIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'senderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      senderIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'senderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      senderIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'senderId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      senderIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'senderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      senderIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'senderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      senderIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'senderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      senderIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'senderId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      senderIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'senderId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      senderIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'senderId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      viewOnceEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'viewOnce',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      viewedByReceiverEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'viewedByReceiver',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      viewedBySenderEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'viewedBySender',
        value: value,
      ));
    });
  }
}

extension LocalMessageQueryObject
    on QueryBuilder<LocalMessage, LocalMessage, QFilterCondition> {}

extension LocalMessageQueryLinks
    on QueryBuilder<LocalMessage, LocalMessage, QFilterCondition> {}

extension LocalMessageQuerySortBy
    on QueryBuilder<LocalMessage, LocalMessage, QSortBy> {
  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByCaption() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caption', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByCaptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caption', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      sortByDeletedForReceiver() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedForReceiver', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      sortByDeletedForReceiverDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedForReceiver', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      sortByDeletedForSender() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedForSender', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      sortByDeletedForSenderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedForSender', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByEditedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByEditedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByExpiresAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByExpiresAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByIsLiked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLiked', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByIsLikedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLiked', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByIsPinnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByIsRead() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRead', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByIsReadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRead', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      sortByLocalMediaPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localMediaPath', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      sortByLocalMediaPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localMediaPath', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      sortByMediaDurationMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaDurationMs', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      sortByMediaDurationMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaDurationMs', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      sortByMediaExpiresAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaExpiresAt', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      sortByMediaExpiresAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaExpiresAt', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByMediaMime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaMime', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByMediaMimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaMime', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByMediaName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaName', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByMediaNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaName', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByMediaPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaPath', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByMediaPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaPath', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      sortByMediaSizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaSizeBytes', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      sortByMediaSizeBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaSizeBytes', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByMessageType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageType', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      sortByMessageTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageType', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByOtherUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherUserId', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      sortByOtherUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherUserId', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByOwnerUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUserId', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      sortByOwnerUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUserId', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByReactions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reactions', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByReactionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reactions', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByReceiverId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiverId', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      sortByReceiverIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiverId', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      sortByReplyToRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyToRemoteId', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      sortByReplyToRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyToRemoteId', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortBySenderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderId', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortBySenderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderId', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByViewOnce() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'viewOnce', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByViewOnceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'viewOnce', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      sortByViewedByReceiver() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'viewedByReceiver', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      sortByViewedByReceiverDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'viewedByReceiver', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      sortByViewedBySender() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'viewedBySender', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      sortByViewedBySenderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'viewedBySender', Sort.desc);
    });
  }
}

extension LocalMessageQuerySortThenBy
    on QueryBuilder<LocalMessage, LocalMessage, QSortThenBy> {
  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByCaption() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caption', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByCaptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caption', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      thenByDeletedForReceiver() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedForReceiver', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      thenByDeletedForReceiverDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedForReceiver', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      thenByDeletedForSender() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedForSender', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      thenByDeletedForSenderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedForSender', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByEditedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByEditedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByExpiresAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByExpiresAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByIsLiked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLiked', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByIsLikedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLiked', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByIsPinnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByIsRead() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRead', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByIsReadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRead', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      thenByLocalMediaPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localMediaPath', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      thenByLocalMediaPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localMediaPath', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      thenByMediaDurationMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaDurationMs', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      thenByMediaDurationMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaDurationMs', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      thenByMediaExpiresAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaExpiresAt', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      thenByMediaExpiresAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaExpiresAt', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByMediaMime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaMime', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByMediaMimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaMime', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByMediaName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaName', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByMediaNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaName', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByMediaPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaPath', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByMediaPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaPath', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      thenByMediaSizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaSizeBytes', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      thenByMediaSizeBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaSizeBytes', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByMessageType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageType', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      thenByMessageTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageType', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByOtherUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherUserId', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      thenByOtherUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherUserId', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByOwnerUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUserId', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      thenByOwnerUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUserId', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByReactions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reactions', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByReactionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reactions', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByReceiverId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiverId', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      thenByReceiverIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiverId', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      thenByReplyToRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyToRemoteId', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      thenByReplyToRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyToRemoteId', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenBySenderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderId', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenBySenderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderId', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByViewOnce() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'viewOnce', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByViewOnceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'viewOnce', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      thenByViewedByReceiver() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'viewedByReceiver', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      thenByViewedByReceiverDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'viewedByReceiver', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      thenByViewedBySender() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'viewedBySender', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      thenByViewedBySenderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'viewedBySender', Sort.desc);
    });
  }
}

extension LocalMessageQueryWhereDistinct
    on QueryBuilder<LocalMessage, LocalMessage, QDistinct> {
  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByCaption(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'caption', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByContent(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'content', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedAt');
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct>
      distinctByDeletedForReceiver() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedForReceiver');
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct>
      distinctByDeletedForSender() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedForSender');
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByEditedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'editedAt');
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByExpiresAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expiresAt');
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByIsLiked() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isLiked');
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPinned');
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByIsRead() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isRead');
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByLocalMediaPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localMediaPath',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct>
      distinctByMediaDurationMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mediaDurationMs');
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct>
      distinctByMediaExpiresAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mediaExpiresAt');
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByMediaMime(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mediaMime', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByMediaName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mediaName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByMediaPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mediaPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct>
      distinctByMediaSizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mediaSizeBytes');
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByMessageType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'messageType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByOtherUserId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'otherUserId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByOwnerUserId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerUserId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByReactions(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reactions', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByReceiverId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'receiverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remoteId');
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct>
      distinctByReplyToRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'replyToRemoteId');
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctBySenderId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'senderId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByViewOnce() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'viewOnce');
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct>
      distinctByViewedByReceiver() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'viewedByReceiver');
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct>
      distinctByViewedBySender() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'viewedBySender');
    });
  }
}

extension LocalMessageQueryProperty
    on QueryBuilder<LocalMessage, LocalMessage, QQueryProperty> {
  QueryBuilder<LocalMessage, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LocalMessage, String?, QQueryOperations> captionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'caption');
    });
  }

  QueryBuilder<LocalMessage, String, QQueryOperations> contentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'content');
    });
  }

  QueryBuilder<LocalMessage, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<LocalMessage, DateTime?, QQueryOperations> deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedAt');
    });
  }

  QueryBuilder<LocalMessage, bool, QQueryOperations>
      deletedForReceiverProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedForReceiver');
    });
  }

  QueryBuilder<LocalMessage, bool, QQueryOperations>
      deletedForSenderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedForSender');
    });
  }

  QueryBuilder<LocalMessage, DateTime?, QQueryOperations> editedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'editedAt');
    });
  }

  QueryBuilder<LocalMessage, DateTime?, QQueryOperations> expiresAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expiresAt');
    });
  }

  QueryBuilder<LocalMessage, bool, QQueryOperations> isLikedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isLiked');
    });
  }

  QueryBuilder<LocalMessage, bool, QQueryOperations> isPinnedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPinned');
    });
  }

  QueryBuilder<LocalMessage, bool, QQueryOperations> isReadProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isRead');
    });
  }

  QueryBuilder<LocalMessage, String?, QQueryOperations>
      localMediaPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localMediaPath');
    });
  }

  QueryBuilder<LocalMessage, int?, QQueryOperations> mediaDurationMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mediaDurationMs');
    });
  }

  QueryBuilder<LocalMessage, DateTime?, QQueryOperations>
      mediaExpiresAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mediaExpiresAt');
    });
  }

  QueryBuilder<LocalMessage, String?, QQueryOperations> mediaMimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mediaMime');
    });
  }

  QueryBuilder<LocalMessage, String?, QQueryOperations> mediaNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mediaName');
    });
  }

  QueryBuilder<LocalMessage, String?, QQueryOperations> mediaPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mediaPath');
    });
  }

  QueryBuilder<LocalMessage, int?, QQueryOperations> mediaSizeBytesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mediaSizeBytes');
    });
  }

  QueryBuilder<LocalMessage, String, QQueryOperations> messageTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'messageType');
    });
  }

  QueryBuilder<LocalMessage, String, QQueryOperations> otherUserIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'otherUserId');
    });
  }

  QueryBuilder<LocalMessage, String, QQueryOperations> ownerUserIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerUserId');
    });
  }

  QueryBuilder<LocalMessage, String?, QQueryOperations> reactionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reactions');
    });
  }

  QueryBuilder<LocalMessage, String, QQueryOperations> receiverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'receiverId');
    });
  }

  QueryBuilder<LocalMessage, int?, QQueryOperations> remoteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteId');
    });
  }

  QueryBuilder<LocalMessage, int?, QQueryOperations> replyToRemoteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'replyToRemoteId');
    });
  }

  QueryBuilder<LocalMessage, String, QQueryOperations> senderIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'senderId');
    });
  }

  QueryBuilder<LocalMessage, bool, QQueryOperations> viewOnceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'viewOnce');
    });
  }

  QueryBuilder<LocalMessage, bool, QQueryOperations>
      viewedByReceiverProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'viewedByReceiver');
    });
  }

  QueryBuilder<LocalMessage, bool, QQueryOperations> viewedBySenderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'viewedBySender');
    });
  }
}
