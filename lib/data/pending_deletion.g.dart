// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_deletion.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPendingDeletionCollection on Isar {
  IsarCollection<PendingDeletion> get pendingDeletions => this.collection();
}

const PendingDeletionSchema = CollectionSchema(
  name: r'PendingDeletion',
  id: -174119354375474202,
  properties: {
    r'deletedAt': PropertySchema(
      id: 0,
      name: r'deletedAt',
      type: IsarType.dateTime,
    ),
    r'index': PropertySchema(
      id: 1,
      name: r'index',
      type: IsarType.long,
    ),
    r'remoteIndex': PropertySchema(
      id: 2,
      name: r'remoteIndex',
      type: IsarType.string,
    )
  },
  estimateSize: _pendingDeletionEstimateSize,
  serialize: _pendingDeletionSerialize,
  deserialize: _pendingDeletionDeserialize,
  deserializeProp: _pendingDeletionDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _pendingDeletionGetId,
  getLinks: _pendingDeletionGetLinks,
  attach: _pendingDeletionAttach,
  version: '3.1.0+1',
);

int _pendingDeletionEstimateSize(
  PendingDeletion object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.remoteIndex.length * 3;
  return bytesCount;
}

void _pendingDeletionSerialize(
  PendingDeletion object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.deletedAt);
  writer.writeLong(offsets[1], object.index);
  writer.writeString(offsets[2], object.remoteIndex);
}

PendingDeletion _pendingDeletionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PendingDeletion();
  object.deletedAt = reader.readDateTime(offsets[0]);
  object.id = id;
  object.index = reader.readLong(offsets[1]);
  object.remoteIndex = reader.readString(offsets[2]);
  return object;
}

P _pendingDeletionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _pendingDeletionGetId(PendingDeletion object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _pendingDeletionGetLinks(PendingDeletion object) {
  return [];
}

void _pendingDeletionAttach(
    IsarCollection<dynamic> col, Id id, PendingDeletion object) {
  object.id = id;
}

extension PendingDeletionQueryWhereSort
    on QueryBuilder<PendingDeletion, PendingDeletion, QWhere> {
  QueryBuilder<PendingDeletion, PendingDeletion, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PendingDeletionQueryWhere
    on QueryBuilder<PendingDeletion, PendingDeletion, QWhereClause> {
  QueryBuilder<PendingDeletion, PendingDeletion, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterWhereClause>
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

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterWhereClause> idBetween(
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
}

extension PendingDeletionQueryFilter
    on QueryBuilder<PendingDeletion, PendingDeletion, QFilterCondition> {
  QueryBuilder<PendingDeletion, PendingDeletion, QAfterFilterCondition>
      deletedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterFilterCondition>
      deletedAtGreaterThan(
    DateTime value, {
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

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterFilterCondition>
      deletedAtLessThan(
    DateTime value, {
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

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterFilterCondition>
      deletedAtBetween(
    DateTime lower,
    DateTime upper, {
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

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterFilterCondition>
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

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterFilterCondition>
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

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterFilterCondition>
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

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterFilterCondition>
      indexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'index',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterFilterCondition>
      indexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'index',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterFilterCondition>
      indexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'index',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterFilterCondition>
      indexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'index',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterFilterCondition>
      remoteIndexEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remoteIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterFilterCondition>
      remoteIndexGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remoteIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterFilterCondition>
      remoteIndexLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remoteIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterFilterCondition>
      remoteIndexBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remoteIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterFilterCondition>
      remoteIndexStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'remoteIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterFilterCondition>
      remoteIndexEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'remoteIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterFilterCondition>
      remoteIndexContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'remoteIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterFilterCondition>
      remoteIndexMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'remoteIndex',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterFilterCondition>
      remoteIndexIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remoteIndex',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterFilterCondition>
      remoteIndexIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'remoteIndex',
        value: '',
      ));
    });
  }
}

extension PendingDeletionQueryObject
    on QueryBuilder<PendingDeletion, PendingDeletion, QFilterCondition> {}

extension PendingDeletionQueryLinks
    on QueryBuilder<PendingDeletion, PendingDeletion, QFilterCondition> {}

extension PendingDeletionQuerySortBy
    on QueryBuilder<PendingDeletion, PendingDeletion, QSortBy> {
  QueryBuilder<PendingDeletion, PendingDeletion, QAfterSortBy>
      sortByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterSortBy>
      sortByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterSortBy> sortByIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'index', Sort.asc);
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterSortBy>
      sortByIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'index', Sort.desc);
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterSortBy>
      sortByRemoteIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteIndex', Sort.asc);
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterSortBy>
      sortByRemoteIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteIndex', Sort.desc);
    });
  }
}

extension PendingDeletionQuerySortThenBy
    on QueryBuilder<PendingDeletion, PendingDeletion, QSortThenBy> {
  QueryBuilder<PendingDeletion, PendingDeletion, QAfterSortBy>
      thenByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterSortBy>
      thenByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterSortBy> thenByIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'index', Sort.asc);
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterSortBy>
      thenByIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'index', Sort.desc);
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterSortBy>
      thenByRemoteIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteIndex', Sort.asc);
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QAfterSortBy>
      thenByRemoteIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteIndex', Sort.desc);
    });
  }
}

extension PendingDeletionQueryWhereDistinct
    on QueryBuilder<PendingDeletion, PendingDeletion, QDistinct> {
  QueryBuilder<PendingDeletion, PendingDeletion, QDistinct>
      distinctByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedAt');
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QDistinct> distinctByIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'index');
    });
  }

  QueryBuilder<PendingDeletion, PendingDeletion, QDistinct>
      distinctByRemoteIndex({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remoteIndex', caseSensitive: caseSensitive);
    });
  }
}

extension PendingDeletionQueryProperty
    on QueryBuilder<PendingDeletion, PendingDeletion, QQueryProperty> {
  QueryBuilder<PendingDeletion, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PendingDeletion, DateTime, QQueryOperations>
      deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedAt');
    });
  }

  QueryBuilder<PendingDeletion, int, QQueryOperations> indexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'index');
    });
  }

  QueryBuilder<PendingDeletion, String, QQueryOperations>
      remoteIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteIndex');
    });
  }
}
