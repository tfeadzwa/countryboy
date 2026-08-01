// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CachedFleetsTable extends CachedFleets
    with TableInfo<$CachedFleetsTable, CachedFleet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedFleetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<String> number = GeneratedColumn<String>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _registrationNumberMeta =
      const VerificationMeta('registrationNumber');
  @override
  late final GeneratedColumn<String> registrationNumber =
      GeneratedColumn<String>(
        'registration_number',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ACTIVE'),
  );
  static const VerificationMeta _onTripMeta = const VerificationMeta('onTrip');
  @override
  late final GeneratedColumn<bool> onTrip = GeneratedColumn<bool>(
    'on_trip',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("on_trip" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _capacityMeta = const VerificationMeta(
    'capacity',
  );
  @override
  late final GeneratedColumn<int> capacity = GeneratedColumn<int>(
    'capacity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    number,
    registrationNumber,
    status,
    onTrip,
    capacity,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_fleets';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedFleet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('registration_number')) {
      context.handle(
        _registrationNumberMeta,
        registrationNumber.isAcceptableOrUnknown(
          data['registration_number']!,
          _registrationNumberMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('on_trip')) {
      context.handle(
        _onTripMeta,
        onTrip.isAcceptableOrUnknown(data['on_trip']!, _onTripMeta),
      );
    }
    if (data.containsKey('capacity')) {
      context.handle(
        _capacityMeta,
        capacity.isAcceptableOrUnknown(data['capacity']!, _capacityMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedFleet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedFleet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}number'],
      )!,
      registrationNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}registration_number'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      onTrip: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}on_trip'],
      )!,
      capacity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}capacity'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedFleetsTable createAlias(String alias) {
    return $CachedFleetsTable(attachedDatabase, alias);
  }
}

class CachedFleet extends DataClass implements Insertable<CachedFleet> {
  final String id;
  final String number;
  final String? registrationNumber;
  final String status;
  final bool onTrip;
  final int capacity;
  final DateTime cachedAt;
  const CachedFleet({
    required this.id,
    required this.number,
    this.registrationNumber,
    required this.status,
    required this.onTrip,
    required this.capacity,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['number'] = Variable<String>(number);
    if (!nullToAbsent || registrationNumber != null) {
      map['registration_number'] = Variable<String>(registrationNumber);
    }
    map['status'] = Variable<String>(status);
    map['on_trip'] = Variable<bool>(onTrip);
    map['capacity'] = Variable<int>(capacity);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedFleetsCompanion toCompanion(bool nullToAbsent) {
    return CachedFleetsCompanion(
      id: Value(id),
      number: Value(number),
      registrationNumber: registrationNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(registrationNumber),
      status: Value(status),
      onTrip: Value(onTrip),
      capacity: Value(capacity),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedFleet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedFleet(
      id: serializer.fromJson<String>(json['id']),
      number: serializer.fromJson<String>(json['number']),
      registrationNumber: serializer.fromJson<String?>(
        json['registrationNumber'],
      ),
      status: serializer.fromJson<String>(json['status']),
      onTrip: serializer.fromJson<bool>(json['onTrip']),
      capacity: serializer.fromJson<int>(json['capacity']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'number': serializer.toJson<String>(number),
      'registrationNumber': serializer.toJson<String?>(registrationNumber),
      'status': serializer.toJson<String>(status),
      'onTrip': serializer.toJson<bool>(onTrip),
      'capacity': serializer.toJson<int>(capacity),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedFleet copyWith({
    String? id,
    String? number,
    Value<String?> registrationNumber = const Value.absent(),
    String? status,
    bool? onTrip,
    int? capacity,
    DateTime? cachedAt,
  }) => CachedFleet(
    id: id ?? this.id,
    number: number ?? this.number,
    registrationNumber: registrationNumber.present
        ? registrationNumber.value
        : this.registrationNumber,
    status: status ?? this.status,
    onTrip: onTrip ?? this.onTrip,
    capacity: capacity ?? this.capacity,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedFleet copyWithCompanion(CachedFleetsCompanion data) {
    return CachedFleet(
      id: data.id.present ? data.id.value : this.id,
      number: data.number.present ? data.number.value : this.number,
      registrationNumber: data.registrationNumber.present
          ? data.registrationNumber.value
          : this.registrationNumber,
      status: data.status.present ? data.status.value : this.status,
      onTrip: data.onTrip.present ? data.onTrip.value : this.onTrip,
      capacity: data.capacity.present ? data.capacity.value : this.capacity,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedFleet(')
          ..write('id: $id, ')
          ..write('number: $number, ')
          ..write('registrationNumber: $registrationNumber, ')
          ..write('status: $status, ')
          ..write('onTrip: $onTrip, ')
          ..write('capacity: $capacity, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    number,
    registrationNumber,
    status,
    onTrip,
    capacity,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedFleet &&
          other.id == this.id &&
          other.number == this.number &&
          other.registrationNumber == this.registrationNumber &&
          other.status == this.status &&
          other.onTrip == this.onTrip &&
          other.capacity == this.capacity &&
          other.cachedAt == this.cachedAt);
}

class CachedFleetsCompanion extends UpdateCompanion<CachedFleet> {
  final Value<String> id;
  final Value<String> number;
  final Value<String?> registrationNumber;
  final Value<String> status;
  final Value<bool> onTrip;
  final Value<int> capacity;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedFleetsCompanion({
    this.id = const Value.absent(),
    this.number = const Value.absent(),
    this.registrationNumber = const Value.absent(),
    this.status = const Value.absent(),
    this.onTrip = const Value.absent(),
    this.capacity = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedFleetsCompanion.insert({
    required String id,
    required String number,
    this.registrationNumber = const Value.absent(),
    this.status = const Value.absent(),
    this.onTrip = const Value.absent(),
    this.capacity = const Value.absent(),
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       number = Value(number),
       cachedAt = Value(cachedAt);
  static Insertable<CachedFleet> custom({
    Expression<String>? id,
    Expression<String>? number,
    Expression<String>? registrationNumber,
    Expression<String>? status,
    Expression<bool>? onTrip,
    Expression<int>? capacity,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (number != null) 'number': number,
      if (registrationNumber != null) 'registration_number': registrationNumber,
      if (status != null) 'status': status,
      if (onTrip != null) 'on_trip': onTrip,
      if (capacity != null) 'capacity': capacity,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedFleetsCompanion copyWith({
    Value<String>? id,
    Value<String>? number,
    Value<String?>? registrationNumber,
    Value<String>? status,
    Value<bool>? onTrip,
    Value<int>? capacity,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedFleetsCompanion(
      id: id ?? this.id,
      number: number ?? this.number,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      status: status ?? this.status,
      onTrip: onTrip ?? this.onTrip,
      capacity: capacity ?? this.capacity,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (registrationNumber.present) {
      map['registration_number'] = Variable<String>(registrationNumber.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (onTrip.present) {
      map['on_trip'] = Variable<bool>(onTrip.value);
    }
    if (capacity.present) {
      map['capacity'] = Variable<int>(capacity.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedFleetsCompanion(')
          ..write('id: $id, ')
          ..write('number: $number, ')
          ..write('registrationNumber: $registrationNumber, ')
          ..write('status: $status, ')
          ..write('onTrip: $onTrip, ')
          ..write('capacity: $capacity, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedDriversTable extends CachedDrivers
    with TableInfo<$CachedDriversTable, CachedDriver> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedDriversTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ACTIVE'),
  );
  static const VerificationMeta _onTripMeta = const VerificationMeta('onTrip');
  @override
  late final GeneratedColumn<bool> onTrip = GeneratedColumn<bool>(
    'on_trip',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("on_trip" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fullName,
    status,
    onTrip,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_drivers';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedDriver> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('on_trip')) {
      context.handle(
        _onTripMeta,
        onTrip.isAcceptableOrUnknown(data['on_trip']!, _onTripMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedDriver map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedDriver(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      onTrip: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}on_trip'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedDriversTable createAlias(String alias) {
    return $CachedDriversTable(attachedDatabase, alias);
  }
}

class CachedDriver extends DataClass implements Insertable<CachedDriver> {
  final String id;
  final String fullName;
  final String status;
  final bool onTrip;
  final DateTime cachedAt;
  const CachedDriver({
    required this.id,
    required this.fullName,
    required this.status,
    required this.onTrip,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['full_name'] = Variable<String>(fullName);
    map['status'] = Variable<String>(status);
    map['on_trip'] = Variable<bool>(onTrip);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedDriversCompanion toCompanion(bool nullToAbsent) {
    return CachedDriversCompanion(
      id: Value(id),
      fullName: Value(fullName),
      status: Value(status),
      onTrip: Value(onTrip),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedDriver.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedDriver(
      id: serializer.fromJson<String>(json['id']),
      fullName: serializer.fromJson<String>(json['fullName']),
      status: serializer.fromJson<String>(json['status']),
      onTrip: serializer.fromJson<bool>(json['onTrip']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fullName': serializer.toJson<String>(fullName),
      'status': serializer.toJson<String>(status),
      'onTrip': serializer.toJson<bool>(onTrip),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedDriver copyWith({
    String? id,
    String? fullName,
    String? status,
    bool? onTrip,
    DateTime? cachedAt,
  }) => CachedDriver(
    id: id ?? this.id,
    fullName: fullName ?? this.fullName,
    status: status ?? this.status,
    onTrip: onTrip ?? this.onTrip,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedDriver copyWithCompanion(CachedDriversCompanion data) {
    return CachedDriver(
      id: data.id.present ? data.id.value : this.id,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      status: data.status.present ? data.status.value : this.status,
      onTrip: data.onTrip.present ? data.onTrip.value : this.onTrip,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedDriver(')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('status: $status, ')
          ..write('onTrip: $onTrip, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fullName, status, onTrip, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedDriver &&
          other.id == this.id &&
          other.fullName == this.fullName &&
          other.status == this.status &&
          other.onTrip == this.onTrip &&
          other.cachedAt == this.cachedAt);
}

class CachedDriversCompanion extends UpdateCompanion<CachedDriver> {
  final Value<String> id;
  final Value<String> fullName;
  final Value<String> status;
  final Value<bool> onTrip;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedDriversCompanion({
    this.id = const Value.absent(),
    this.fullName = const Value.absent(),
    this.status = const Value.absent(),
    this.onTrip = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedDriversCompanion.insert({
    required String id,
    required String fullName,
    this.status = const Value.absent(),
    this.onTrip = const Value.absent(),
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       fullName = Value(fullName),
       cachedAt = Value(cachedAt);
  static Insertable<CachedDriver> custom({
    Expression<String>? id,
    Expression<String>? fullName,
    Expression<String>? status,
    Expression<bool>? onTrip,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fullName != null) 'full_name': fullName,
      if (status != null) 'status': status,
      if (onTrip != null) 'on_trip': onTrip,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedDriversCompanion copyWith({
    Value<String>? id,
    Value<String>? fullName,
    Value<String>? status,
    Value<bool>? onTrip,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedDriversCompanion(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      status: status ?? this.status,
      onTrip: onTrip ?? this.onTrip,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (onTrip.present) {
      map['on_trip'] = Variable<bool>(onTrip.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedDriversCompanion(')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('status: $status, ')
          ..write('onTrip: $onTrip, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedRoutesTable extends CachedRoutes
    with TableInfo<$CachedRoutesTable, CachedRoute> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedRoutesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _destinationMeta = const VerificationMeta(
    'destination',
  );
  @override
  late final GeneratedColumn<String> destination = GeneratedColumn<String>(
    'destination',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentRouteIdsJsonMeta =
      const VerificationMeta('parentRouteIdsJson');
  @override
  late final GeneratedColumn<String> parentRouteIdsJson =
      GeneratedColumn<String>(
        'parent_route_ids_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _childRouteIdsJsonMeta = const VerificationMeta(
    'childRouteIdsJson',
  );
  @override
  late final GeneratedColumn<String> childRouteIdsJson =
      GeneratedColumn<String>(
        'child_route_ids_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    origin,
    destination,
    parentRouteIdsJson,
    childRouteIdsJson,
    isActive,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_routes';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedRoute> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('destination')) {
      context.handle(
        _destinationMeta,
        destination.isAcceptableOrUnknown(
          data['destination']!,
          _destinationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_destinationMeta);
    }
    if (data.containsKey('parent_route_ids_json')) {
      context.handle(
        _parentRouteIdsJsonMeta,
        parentRouteIdsJson.isAcceptableOrUnknown(
          data['parent_route_ids_json']!,
          _parentRouteIdsJsonMeta,
        ),
      );
    }
    if (data.containsKey('child_route_ids_json')) {
      context.handle(
        _childRouteIdsJsonMeta,
        childRouteIdsJson.isAcceptableOrUnknown(
          data['child_route_ids_json']!,
          _childRouteIdsJsonMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedRoute map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedRoute(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      destination: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination'],
      )!,
      parentRouteIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_route_ids_json'],
      )!,
      childRouteIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_route_ids_json'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedRoutesTable createAlias(String alias) {
    return $CachedRoutesTable(attachedDatabase, alias);
  }
}

class CachedRoute extends DataClass implements Insertable<CachedRoute> {
  final String id;
  final String origin;
  final String destination;

  /// JSON array of parent corridor route ids.
  final String parentRouteIdsJson;

  /// JSON array of direct child segment route ids.
  final String childRouteIdsJson;
  final bool isActive;
  final DateTime cachedAt;
  const CachedRoute({
    required this.id,
    required this.origin,
    required this.destination,
    required this.parentRouteIdsJson,
    required this.childRouteIdsJson,
    required this.isActive,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['origin'] = Variable<String>(origin);
    map['destination'] = Variable<String>(destination);
    map['parent_route_ids_json'] = Variable<String>(parentRouteIdsJson);
    map['child_route_ids_json'] = Variable<String>(childRouteIdsJson);
    map['is_active'] = Variable<bool>(isActive);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedRoutesCompanion toCompanion(bool nullToAbsent) {
    return CachedRoutesCompanion(
      id: Value(id),
      origin: Value(origin),
      destination: Value(destination),
      parentRouteIdsJson: Value(parentRouteIdsJson),
      childRouteIdsJson: Value(childRouteIdsJson),
      isActive: Value(isActive),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedRoute.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedRoute(
      id: serializer.fromJson<String>(json['id']),
      origin: serializer.fromJson<String>(json['origin']),
      destination: serializer.fromJson<String>(json['destination']),
      parentRouteIdsJson: serializer.fromJson<String>(
        json['parentRouteIdsJson'],
      ),
      childRouteIdsJson: serializer.fromJson<String>(json['childRouteIdsJson']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'origin': serializer.toJson<String>(origin),
      'destination': serializer.toJson<String>(destination),
      'parentRouteIdsJson': serializer.toJson<String>(parentRouteIdsJson),
      'childRouteIdsJson': serializer.toJson<String>(childRouteIdsJson),
      'isActive': serializer.toJson<bool>(isActive),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedRoute copyWith({
    String? id,
    String? origin,
    String? destination,
    String? parentRouteIdsJson,
    String? childRouteIdsJson,
    bool? isActive,
    DateTime? cachedAt,
  }) => CachedRoute(
    id: id ?? this.id,
    origin: origin ?? this.origin,
    destination: destination ?? this.destination,
    parentRouteIdsJson: parentRouteIdsJson ?? this.parentRouteIdsJson,
    childRouteIdsJson: childRouteIdsJson ?? this.childRouteIdsJson,
    isActive: isActive ?? this.isActive,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedRoute copyWithCompanion(CachedRoutesCompanion data) {
    return CachedRoute(
      id: data.id.present ? data.id.value : this.id,
      origin: data.origin.present ? data.origin.value : this.origin,
      destination: data.destination.present
          ? data.destination.value
          : this.destination,
      parentRouteIdsJson: data.parentRouteIdsJson.present
          ? data.parentRouteIdsJson.value
          : this.parentRouteIdsJson,
      childRouteIdsJson: data.childRouteIdsJson.present
          ? data.childRouteIdsJson.value
          : this.childRouteIdsJson,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedRoute(')
          ..write('id: $id, ')
          ..write('origin: $origin, ')
          ..write('destination: $destination, ')
          ..write('parentRouteIdsJson: $parentRouteIdsJson, ')
          ..write('childRouteIdsJson: $childRouteIdsJson, ')
          ..write('isActive: $isActive, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    origin,
    destination,
    parentRouteIdsJson,
    childRouteIdsJson,
    isActive,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedRoute &&
          other.id == this.id &&
          other.origin == this.origin &&
          other.destination == this.destination &&
          other.parentRouteIdsJson == this.parentRouteIdsJson &&
          other.childRouteIdsJson == this.childRouteIdsJson &&
          other.isActive == this.isActive &&
          other.cachedAt == this.cachedAt);
}

class CachedRoutesCompanion extends UpdateCompanion<CachedRoute> {
  final Value<String> id;
  final Value<String> origin;
  final Value<String> destination;
  final Value<String> parentRouteIdsJson;
  final Value<String> childRouteIdsJson;
  final Value<bool> isActive;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedRoutesCompanion({
    this.id = const Value.absent(),
    this.origin = const Value.absent(),
    this.destination = const Value.absent(),
    this.parentRouteIdsJson = const Value.absent(),
    this.childRouteIdsJson = const Value.absent(),
    this.isActive = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedRoutesCompanion.insert({
    required String id,
    required String origin,
    required String destination,
    this.parentRouteIdsJson = const Value.absent(),
    this.childRouteIdsJson = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       origin = Value(origin),
       destination = Value(destination),
       cachedAt = Value(cachedAt);
  static Insertable<CachedRoute> custom({
    Expression<String>? id,
    Expression<String>? origin,
    Expression<String>? destination,
    Expression<String>? parentRouteIdsJson,
    Expression<String>? childRouteIdsJson,
    Expression<bool>? isActive,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (origin != null) 'origin': origin,
      if (destination != null) 'destination': destination,
      if (parentRouteIdsJson != null)
        'parent_route_ids_json': parentRouteIdsJson,
      if (childRouteIdsJson != null) 'child_route_ids_json': childRouteIdsJson,
      if (isActive != null) 'is_active': isActive,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedRoutesCompanion copyWith({
    Value<String>? id,
    Value<String>? origin,
    Value<String>? destination,
    Value<String>? parentRouteIdsJson,
    Value<String>? childRouteIdsJson,
    Value<bool>? isActive,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedRoutesCompanion(
      id: id ?? this.id,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      parentRouteIdsJson: parentRouteIdsJson ?? this.parentRouteIdsJson,
      childRouteIdsJson: childRouteIdsJson ?? this.childRouteIdsJson,
      isActive: isActive ?? this.isActive,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (destination.present) {
      map['destination'] = Variable<String>(destination.value);
    }
    if (parentRouteIdsJson.present) {
      map['parent_route_ids_json'] = Variable<String>(parentRouteIdsJson.value);
    }
    if (childRouteIdsJson.present) {
      map['child_route_ids_json'] = Variable<String>(childRouteIdsJson.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedRoutesCompanion(')
          ..write('id: $id, ')
          ..write('origin: $origin, ')
          ..write('destination: $destination, ')
          ..write('parentRouteIdsJson: $parentRouteIdsJson, ')
          ..write('childRouteIdsJson: $childRouteIdsJson, ')
          ..write('isActive: $isActive, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedFaresTable extends CachedFares
    with TableInfo<$CachedFaresTable, CachedFare> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedFaresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _routeIdMeta = const VerificationMeta(
    'routeId',
  );
  @override
  late final GeneratedColumn<String> routeId = GeneratedColumn<String>(
    'route_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _routeLabelMeta = const VerificationMeta(
    'routeLabel',
  );
  @override
  late final GeneratedColumn<String> routeLabel = GeneratedColumn<String>(
    'route_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    routeId,
    currency,
    amount,
    routeLabel,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_fares';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedFare> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('route_id')) {
      context.handle(
        _routeIdMeta,
        routeId.isAcceptableOrUnknown(data['route_id']!, _routeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_routeIdMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('route_label')) {
      context.handle(
        _routeLabelMeta,
        routeLabel.isAcceptableOrUnknown(data['route_label']!, _routeLabelMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedFare map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedFare(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      routeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_id'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      routeLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_label'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedFaresTable createAlias(String alias) {
    return $CachedFaresTable(attachedDatabase, alias);
  }
}

class CachedFare extends DataClass implements Insertable<CachedFare> {
  final String id;
  final String routeId;
  final String currency;
  final double amount;
  final String? routeLabel;
  final DateTime cachedAt;
  const CachedFare({
    required this.id,
    required this.routeId,
    required this.currency,
    required this.amount,
    this.routeLabel,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['route_id'] = Variable<String>(routeId);
    map['currency'] = Variable<String>(currency);
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || routeLabel != null) {
      map['route_label'] = Variable<String>(routeLabel);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedFaresCompanion toCompanion(bool nullToAbsent) {
    return CachedFaresCompanion(
      id: Value(id),
      routeId: Value(routeId),
      currency: Value(currency),
      amount: Value(amount),
      routeLabel: routeLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(routeLabel),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedFare.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedFare(
      id: serializer.fromJson<String>(json['id']),
      routeId: serializer.fromJson<String>(json['routeId']),
      currency: serializer.fromJson<String>(json['currency']),
      amount: serializer.fromJson<double>(json['amount']),
      routeLabel: serializer.fromJson<String?>(json['routeLabel']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'routeId': serializer.toJson<String>(routeId),
      'currency': serializer.toJson<String>(currency),
      'amount': serializer.toJson<double>(amount),
      'routeLabel': serializer.toJson<String?>(routeLabel),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedFare copyWith({
    String? id,
    String? routeId,
    String? currency,
    double? amount,
    Value<String?> routeLabel = const Value.absent(),
    DateTime? cachedAt,
  }) => CachedFare(
    id: id ?? this.id,
    routeId: routeId ?? this.routeId,
    currency: currency ?? this.currency,
    amount: amount ?? this.amount,
    routeLabel: routeLabel.present ? routeLabel.value : this.routeLabel,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedFare copyWithCompanion(CachedFaresCompanion data) {
    return CachedFare(
      id: data.id.present ? data.id.value : this.id,
      routeId: data.routeId.present ? data.routeId.value : this.routeId,
      currency: data.currency.present ? data.currency.value : this.currency,
      amount: data.amount.present ? data.amount.value : this.amount,
      routeLabel: data.routeLabel.present
          ? data.routeLabel.value
          : this.routeLabel,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedFare(')
          ..write('id: $id, ')
          ..write('routeId: $routeId, ')
          ..write('currency: $currency, ')
          ..write('amount: $amount, ')
          ..write('routeLabel: $routeLabel, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, routeId, currency, amount, routeLabel, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedFare &&
          other.id == this.id &&
          other.routeId == this.routeId &&
          other.currency == this.currency &&
          other.amount == this.amount &&
          other.routeLabel == this.routeLabel &&
          other.cachedAt == this.cachedAt);
}

class CachedFaresCompanion extends UpdateCompanion<CachedFare> {
  final Value<String> id;
  final Value<String> routeId;
  final Value<String> currency;
  final Value<double> amount;
  final Value<String?> routeLabel;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedFaresCompanion({
    this.id = const Value.absent(),
    this.routeId = const Value.absent(),
    this.currency = const Value.absent(),
    this.amount = const Value.absent(),
    this.routeLabel = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedFaresCompanion.insert({
    required String id,
    required String routeId,
    required String currency,
    required double amount,
    this.routeLabel = const Value.absent(),
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       routeId = Value(routeId),
       currency = Value(currency),
       amount = Value(amount),
       cachedAt = Value(cachedAt);
  static Insertable<CachedFare> custom({
    Expression<String>? id,
    Expression<String>? routeId,
    Expression<String>? currency,
    Expression<double>? amount,
    Expression<String>? routeLabel,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (routeId != null) 'route_id': routeId,
      if (currency != null) 'currency': currency,
      if (amount != null) 'amount': amount,
      if (routeLabel != null) 'route_label': routeLabel,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedFaresCompanion copyWith({
    Value<String>? id,
    Value<String>? routeId,
    Value<String>? currency,
    Value<double>? amount,
    Value<String?>? routeLabel,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedFaresCompanion(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      currency: currency ?? this.currency,
      amount: amount ?? this.amount,
      routeLabel: routeLabel ?? this.routeLabel,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (routeId.present) {
      map['route_id'] = Variable<String>(routeId.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (routeLabel.present) {
      map['route_label'] = Variable<String>(routeLabel.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedFaresCompanion(')
          ..write('id: $id, ')
          ..write('routeId: $routeId, ')
          ..write('currency: $currency, ')
          ..write('amount: $amount, ')
          ..write('routeLabel: $routeLabel, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalTripsTable extends LocalTrips
    with TableInfo<$LocalTripsTable, LocalTrip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTripsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _agentIdMeta = const VerificationMeta(
    'agentId',
  );
  @override
  late final GeneratedColumn<String> agentId = GeneratedColumn<String>(
    'agent_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fleetIdMeta = const VerificationMeta(
    'fleetId',
  );
  @override
  late final GeneratedColumn<String> fleetId = GeneratedColumn<String>(
    'fleet_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _routeIdMeta = const VerificationMeta(
    'routeId',
  );
  @override
  late final GeneratedColumn<String> routeId = GeneratedColumn<String>(
    'route_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _depotIdMeta = const VerificationMeta(
    'depotId',
  );
  @override
  late final GeneratedColumn<String> depotId = GeneratedColumn<String>(
    'depot_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ACTIVE'),
  );
  static const VerificationMeta _startedOfflineMeta = const VerificationMeta(
    'startedOffline',
  );
  @override
  late final GeneratedColumn<bool> startedOffline = GeneratedColumn<bool>(
    'started_offline',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("started_offline" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fleetNumberMeta = const VerificationMeta(
    'fleetNumber',
  );
  @override
  late final GeneratedColumn<String> fleetNumber = GeneratedColumn<String>(
    'fleet_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fleetRegistrationNumberMeta =
      const VerificationMeta('fleetRegistrationNumber');
  @override
  late final GeneratedColumn<String> fleetRegistrationNumber =
      GeneratedColumn<String>(
        'fleet_registration_number',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _driverIdMeta = const VerificationMeta(
    'driverId',
  );
  @override
  late final GeneratedColumn<String> driverId = GeneratedColumn<String>(
    'driver_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _driverNameMeta = const VerificationMeta(
    'driverName',
  );
  @override
  late final GeneratedColumn<String> driverName = GeneratedColumn<String>(
    'driver_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _routeOriginMeta = const VerificationMeta(
    'routeOrigin',
  );
  @override
  late final GeneratedColumn<String> routeOrigin = GeneratedColumn<String>(
    'route_origin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _routeDestinationMeta = const VerificationMeta(
    'routeDestination',
  );
  @override
  late final GeneratedColumn<String> routeDestination = GeneratedColumn<String>(
    'route_destination',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startingMileageMeta = const VerificationMeta(
    'startingMileage',
  );
  @override
  late final GeneratedColumn<int> startingMileage = GeneratedColumn<int>(
    'starting_mileage',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _waybillNoMeta = const VerificationMeta(
    'waybillNo',
  );
  @override
  late final GeneratedColumn<String> waybillNo = GeneratedColumn<String>(
    'waybill_no',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _closingMileageMeta = const VerificationMeta(
    'closingMileage',
  );
  @override
  late final GeneratedColumn<int> closingMileage = GeneratedColumn<int>(
    'closing_mileage',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    agentId,
    fleetId,
    routeId,
    deviceId,
    depotId,
    status,
    startedOffline,
    startedAt,
    endedAt,
    fleetNumber,
    fleetRegistrationNumber,
    driverId,
    driverName,
    routeOrigin,
    routeDestination,
    startingMileage,
    waybillNo,
    closingMileage,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_trips';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalTrip> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('agent_id')) {
      context.handle(
        _agentIdMeta,
        agentId.isAcceptableOrUnknown(data['agent_id']!, _agentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_agentIdMeta);
    }
    if (data.containsKey('fleet_id')) {
      context.handle(
        _fleetIdMeta,
        fleetId.isAcceptableOrUnknown(data['fleet_id']!, _fleetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fleetIdMeta);
    }
    if (data.containsKey('route_id')) {
      context.handle(
        _routeIdMeta,
        routeId.isAcceptableOrUnknown(data['route_id']!, _routeIdMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('depot_id')) {
      context.handle(
        _depotIdMeta,
        depotId.isAcceptableOrUnknown(data['depot_id']!, _depotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_depotIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('started_offline')) {
      context.handle(
        _startedOfflineMeta,
        startedOffline.isAcceptableOrUnknown(
          data['started_offline']!,
          _startedOfflineMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('fleet_number')) {
      context.handle(
        _fleetNumberMeta,
        fleetNumber.isAcceptableOrUnknown(
          data['fleet_number']!,
          _fleetNumberMeta,
        ),
      );
    }
    if (data.containsKey('fleet_registration_number')) {
      context.handle(
        _fleetRegistrationNumberMeta,
        fleetRegistrationNumber.isAcceptableOrUnknown(
          data['fleet_registration_number']!,
          _fleetRegistrationNumberMeta,
        ),
      );
    }
    if (data.containsKey('driver_id')) {
      context.handle(
        _driverIdMeta,
        driverId.isAcceptableOrUnknown(data['driver_id']!, _driverIdMeta),
      );
    }
    if (data.containsKey('driver_name')) {
      context.handle(
        _driverNameMeta,
        driverName.isAcceptableOrUnknown(data['driver_name']!, _driverNameMeta),
      );
    }
    if (data.containsKey('route_origin')) {
      context.handle(
        _routeOriginMeta,
        routeOrigin.isAcceptableOrUnknown(
          data['route_origin']!,
          _routeOriginMeta,
        ),
      );
    }
    if (data.containsKey('route_destination')) {
      context.handle(
        _routeDestinationMeta,
        routeDestination.isAcceptableOrUnknown(
          data['route_destination']!,
          _routeDestinationMeta,
        ),
      );
    }
    if (data.containsKey('starting_mileage')) {
      context.handle(
        _startingMileageMeta,
        startingMileage.isAcceptableOrUnknown(
          data['starting_mileage']!,
          _startingMileageMeta,
        ),
      );
    }
    if (data.containsKey('waybill_no')) {
      context.handle(
        _waybillNoMeta,
        waybillNo.isAcceptableOrUnknown(data['waybill_no']!, _waybillNoMeta),
      );
    }
    if (data.containsKey('closing_mileage')) {
      context.handle(
        _closingMileageMeta,
        closingMileage.isAcceptableOrUnknown(
          data['closing_mileage']!,
          _closingMileageMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalTrip map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTrip(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      agentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_id'],
      )!,
      fleetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fleet_id'],
      )!,
      routeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_id'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      depotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}depot_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      startedOffline: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}started_offline'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      fleetNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fleet_number'],
      ),
      fleetRegistrationNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fleet_registration_number'],
      ),
      driverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}driver_id'],
      ),
      driverName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}driver_name'],
      ),
      routeOrigin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_origin'],
      ),
      routeDestination: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_destination'],
      ),
      startingMileage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}starting_mileage'],
      ),
      waybillNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}waybill_no'],
      ),
      closingMileage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}closing_mileage'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $LocalTripsTable createAlias(String alias) {
    return $LocalTripsTable(attachedDatabase, alias);
  }
}

class LocalTrip extends DataClass implements Insertable<LocalTrip> {
  final String id;
  final String agentId;
  final String fleetId;
  final String? routeId;
  final String? deviceId;
  final String depotId;
  final String status;
  final bool startedOffline;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? fleetNumber;
  final String? fleetRegistrationNumber;
  final String? driverId;
  final String? driverName;
  final String? routeOrigin;
  final String? routeDestination;
  final int? startingMileage;
  final String? waybillNo;
  final int? closingMileage;
  final String syncStatus;
  const LocalTrip({
    required this.id,
    required this.agentId,
    required this.fleetId,
    this.routeId,
    this.deviceId,
    required this.depotId,
    required this.status,
    required this.startedOffline,
    required this.startedAt,
    this.endedAt,
    this.fleetNumber,
    this.fleetRegistrationNumber,
    this.driverId,
    this.driverName,
    this.routeOrigin,
    this.routeDestination,
    this.startingMileage,
    this.waybillNo,
    this.closingMileage,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['agent_id'] = Variable<String>(agentId);
    map['fleet_id'] = Variable<String>(fleetId);
    if (!nullToAbsent || routeId != null) {
      map['route_id'] = Variable<String>(routeId);
    }
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    map['depot_id'] = Variable<String>(depotId);
    map['status'] = Variable<String>(status);
    map['started_offline'] = Variable<bool>(startedOffline);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    if (!nullToAbsent || fleetNumber != null) {
      map['fleet_number'] = Variable<String>(fleetNumber);
    }
    if (!nullToAbsent || fleetRegistrationNumber != null) {
      map['fleet_registration_number'] = Variable<String>(
        fleetRegistrationNumber,
      );
    }
    if (!nullToAbsent || driverId != null) {
      map['driver_id'] = Variable<String>(driverId);
    }
    if (!nullToAbsent || driverName != null) {
      map['driver_name'] = Variable<String>(driverName);
    }
    if (!nullToAbsent || routeOrigin != null) {
      map['route_origin'] = Variable<String>(routeOrigin);
    }
    if (!nullToAbsent || routeDestination != null) {
      map['route_destination'] = Variable<String>(routeDestination);
    }
    if (!nullToAbsent || startingMileage != null) {
      map['starting_mileage'] = Variable<int>(startingMileage);
    }
    if (!nullToAbsent || waybillNo != null) {
      map['waybill_no'] = Variable<String>(waybillNo);
    }
    if (!nullToAbsent || closingMileage != null) {
      map['closing_mileage'] = Variable<int>(closingMileage);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  LocalTripsCompanion toCompanion(bool nullToAbsent) {
    return LocalTripsCompanion(
      id: Value(id),
      agentId: Value(agentId),
      fleetId: Value(fleetId),
      routeId: routeId == null && nullToAbsent
          ? const Value.absent()
          : Value(routeId),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      depotId: Value(depotId),
      status: Value(status),
      startedOffline: Value(startedOffline),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      fleetNumber: fleetNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(fleetNumber),
      fleetRegistrationNumber: fleetRegistrationNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(fleetRegistrationNumber),
      driverId: driverId == null && nullToAbsent
          ? const Value.absent()
          : Value(driverId),
      driverName: driverName == null && nullToAbsent
          ? const Value.absent()
          : Value(driverName),
      routeOrigin: routeOrigin == null && nullToAbsent
          ? const Value.absent()
          : Value(routeOrigin),
      routeDestination: routeDestination == null && nullToAbsent
          ? const Value.absent()
          : Value(routeDestination),
      startingMileage: startingMileage == null && nullToAbsent
          ? const Value.absent()
          : Value(startingMileage),
      waybillNo: waybillNo == null && nullToAbsent
          ? const Value.absent()
          : Value(waybillNo),
      closingMileage: closingMileage == null && nullToAbsent
          ? const Value.absent()
          : Value(closingMileage),
      syncStatus: Value(syncStatus),
    );
  }

  factory LocalTrip.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTrip(
      id: serializer.fromJson<String>(json['id']),
      agentId: serializer.fromJson<String>(json['agentId']),
      fleetId: serializer.fromJson<String>(json['fleetId']),
      routeId: serializer.fromJson<String?>(json['routeId']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      depotId: serializer.fromJson<String>(json['depotId']),
      status: serializer.fromJson<String>(json['status']),
      startedOffline: serializer.fromJson<bool>(json['startedOffline']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      fleetNumber: serializer.fromJson<String?>(json['fleetNumber']),
      fleetRegistrationNumber: serializer.fromJson<String?>(
        json['fleetRegistrationNumber'],
      ),
      driverId: serializer.fromJson<String?>(json['driverId']),
      driverName: serializer.fromJson<String?>(json['driverName']),
      routeOrigin: serializer.fromJson<String?>(json['routeOrigin']),
      routeDestination: serializer.fromJson<String?>(json['routeDestination']),
      startingMileage: serializer.fromJson<int?>(json['startingMileage']),
      waybillNo: serializer.fromJson<String?>(json['waybillNo']),
      closingMileage: serializer.fromJson<int?>(json['closingMileage']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'agentId': serializer.toJson<String>(agentId),
      'fleetId': serializer.toJson<String>(fleetId),
      'routeId': serializer.toJson<String?>(routeId),
      'deviceId': serializer.toJson<String?>(deviceId),
      'depotId': serializer.toJson<String>(depotId),
      'status': serializer.toJson<String>(status),
      'startedOffline': serializer.toJson<bool>(startedOffline),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'fleetNumber': serializer.toJson<String?>(fleetNumber),
      'fleetRegistrationNumber': serializer.toJson<String?>(
        fleetRegistrationNumber,
      ),
      'driverId': serializer.toJson<String?>(driverId),
      'driverName': serializer.toJson<String?>(driverName),
      'routeOrigin': serializer.toJson<String?>(routeOrigin),
      'routeDestination': serializer.toJson<String?>(routeDestination),
      'startingMileage': serializer.toJson<int?>(startingMileage),
      'waybillNo': serializer.toJson<String?>(waybillNo),
      'closingMileage': serializer.toJson<int?>(closingMileage),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  LocalTrip copyWith({
    String? id,
    String? agentId,
    String? fleetId,
    Value<String?> routeId = const Value.absent(),
    Value<String?> deviceId = const Value.absent(),
    String? depotId,
    String? status,
    bool? startedOffline,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    Value<String?> fleetNumber = const Value.absent(),
    Value<String?> fleetRegistrationNumber = const Value.absent(),
    Value<String?> driverId = const Value.absent(),
    Value<String?> driverName = const Value.absent(),
    Value<String?> routeOrigin = const Value.absent(),
    Value<String?> routeDestination = const Value.absent(),
    Value<int?> startingMileage = const Value.absent(),
    Value<String?> waybillNo = const Value.absent(),
    Value<int?> closingMileage = const Value.absent(),
    String? syncStatus,
  }) => LocalTrip(
    id: id ?? this.id,
    agentId: agentId ?? this.agentId,
    fleetId: fleetId ?? this.fleetId,
    routeId: routeId.present ? routeId.value : this.routeId,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    depotId: depotId ?? this.depotId,
    status: status ?? this.status,
    startedOffline: startedOffline ?? this.startedOffline,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    fleetNumber: fleetNumber.present ? fleetNumber.value : this.fleetNumber,
    fleetRegistrationNumber: fleetRegistrationNumber.present
        ? fleetRegistrationNumber.value
        : this.fleetRegistrationNumber,
    driverId: driverId.present ? driverId.value : this.driverId,
    driverName: driverName.present ? driverName.value : this.driverName,
    routeOrigin: routeOrigin.present ? routeOrigin.value : this.routeOrigin,
    routeDestination: routeDestination.present
        ? routeDestination.value
        : this.routeDestination,
    startingMileage: startingMileage.present
        ? startingMileage.value
        : this.startingMileage,
    waybillNo: waybillNo.present ? waybillNo.value : this.waybillNo,
    closingMileage: closingMileage.present
        ? closingMileage.value
        : this.closingMileage,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  LocalTrip copyWithCompanion(LocalTripsCompanion data) {
    return LocalTrip(
      id: data.id.present ? data.id.value : this.id,
      agentId: data.agentId.present ? data.agentId.value : this.agentId,
      fleetId: data.fleetId.present ? data.fleetId.value : this.fleetId,
      routeId: data.routeId.present ? data.routeId.value : this.routeId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      depotId: data.depotId.present ? data.depotId.value : this.depotId,
      status: data.status.present ? data.status.value : this.status,
      startedOffline: data.startedOffline.present
          ? data.startedOffline.value
          : this.startedOffline,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      fleetNumber: data.fleetNumber.present
          ? data.fleetNumber.value
          : this.fleetNumber,
      fleetRegistrationNumber: data.fleetRegistrationNumber.present
          ? data.fleetRegistrationNumber.value
          : this.fleetRegistrationNumber,
      driverId: data.driverId.present ? data.driverId.value : this.driverId,
      driverName: data.driverName.present
          ? data.driverName.value
          : this.driverName,
      routeOrigin: data.routeOrigin.present
          ? data.routeOrigin.value
          : this.routeOrigin,
      routeDestination: data.routeDestination.present
          ? data.routeDestination.value
          : this.routeDestination,
      startingMileage: data.startingMileage.present
          ? data.startingMileage.value
          : this.startingMileage,
      waybillNo: data.waybillNo.present ? data.waybillNo.value : this.waybillNo,
      closingMileage: data.closingMileage.present
          ? data.closingMileage.value
          : this.closingMileage,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTrip(')
          ..write('id: $id, ')
          ..write('agentId: $agentId, ')
          ..write('fleetId: $fleetId, ')
          ..write('routeId: $routeId, ')
          ..write('deviceId: $deviceId, ')
          ..write('depotId: $depotId, ')
          ..write('status: $status, ')
          ..write('startedOffline: $startedOffline, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('fleetNumber: $fleetNumber, ')
          ..write('fleetRegistrationNumber: $fleetRegistrationNumber, ')
          ..write('driverId: $driverId, ')
          ..write('driverName: $driverName, ')
          ..write('routeOrigin: $routeOrigin, ')
          ..write('routeDestination: $routeDestination, ')
          ..write('startingMileage: $startingMileage, ')
          ..write('waybillNo: $waybillNo, ')
          ..write('closingMileage: $closingMileage, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    agentId,
    fleetId,
    routeId,
    deviceId,
    depotId,
    status,
    startedOffline,
    startedAt,
    endedAt,
    fleetNumber,
    fleetRegistrationNumber,
    driverId,
    driverName,
    routeOrigin,
    routeDestination,
    startingMileage,
    waybillNo,
    closingMileage,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTrip &&
          other.id == this.id &&
          other.agentId == this.agentId &&
          other.fleetId == this.fleetId &&
          other.routeId == this.routeId &&
          other.deviceId == this.deviceId &&
          other.depotId == this.depotId &&
          other.status == this.status &&
          other.startedOffline == this.startedOffline &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.fleetNumber == this.fleetNumber &&
          other.fleetRegistrationNumber == this.fleetRegistrationNumber &&
          other.driverId == this.driverId &&
          other.driverName == this.driverName &&
          other.routeOrigin == this.routeOrigin &&
          other.routeDestination == this.routeDestination &&
          other.startingMileage == this.startingMileage &&
          other.waybillNo == this.waybillNo &&
          other.closingMileage == this.closingMileage &&
          other.syncStatus == this.syncStatus);
}

class LocalTripsCompanion extends UpdateCompanion<LocalTrip> {
  final Value<String> id;
  final Value<String> agentId;
  final Value<String> fleetId;
  final Value<String?> routeId;
  final Value<String?> deviceId;
  final Value<String> depotId;
  final Value<String> status;
  final Value<bool> startedOffline;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<String?> fleetNumber;
  final Value<String?> fleetRegistrationNumber;
  final Value<String?> driverId;
  final Value<String?> driverName;
  final Value<String?> routeOrigin;
  final Value<String?> routeDestination;
  final Value<int?> startingMileage;
  final Value<String?> waybillNo;
  final Value<int?> closingMileage;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const LocalTripsCompanion({
    this.id = const Value.absent(),
    this.agentId = const Value.absent(),
    this.fleetId = const Value.absent(),
    this.routeId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.depotId = const Value.absent(),
    this.status = const Value.absent(),
    this.startedOffline = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.fleetNumber = const Value.absent(),
    this.fleetRegistrationNumber = const Value.absent(),
    this.driverId = const Value.absent(),
    this.driverName = const Value.absent(),
    this.routeOrigin = const Value.absent(),
    this.routeDestination = const Value.absent(),
    this.startingMileage = const Value.absent(),
    this.waybillNo = const Value.absent(),
    this.closingMileage = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalTripsCompanion.insert({
    required String id,
    required String agentId,
    required String fleetId,
    this.routeId = const Value.absent(),
    this.deviceId = const Value.absent(),
    required String depotId,
    this.status = const Value.absent(),
    this.startedOffline = const Value.absent(),
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.fleetNumber = const Value.absent(),
    this.fleetRegistrationNumber = const Value.absent(),
    this.driverId = const Value.absent(),
    this.driverName = const Value.absent(),
    this.routeOrigin = const Value.absent(),
    this.routeDestination = const Value.absent(),
    this.startingMileage = const Value.absent(),
    this.waybillNo = const Value.absent(),
    this.closingMileage = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       agentId = Value(agentId),
       fleetId = Value(fleetId),
       depotId = Value(depotId),
       startedAt = Value(startedAt);
  static Insertable<LocalTrip> custom({
    Expression<String>? id,
    Expression<String>? agentId,
    Expression<String>? fleetId,
    Expression<String>? routeId,
    Expression<String>? deviceId,
    Expression<String>? depotId,
    Expression<String>? status,
    Expression<bool>? startedOffline,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? fleetNumber,
    Expression<String>? fleetRegistrationNumber,
    Expression<String>? driverId,
    Expression<String>? driverName,
    Expression<String>? routeOrigin,
    Expression<String>? routeDestination,
    Expression<int>? startingMileage,
    Expression<String>? waybillNo,
    Expression<int>? closingMileage,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (agentId != null) 'agent_id': agentId,
      if (fleetId != null) 'fleet_id': fleetId,
      if (routeId != null) 'route_id': routeId,
      if (deviceId != null) 'device_id': deviceId,
      if (depotId != null) 'depot_id': depotId,
      if (status != null) 'status': status,
      if (startedOffline != null) 'started_offline': startedOffline,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (fleetNumber != null) 'fleet_number': fleetNumber,
      if (fleetRegistrationNumber != null)
        'fleet_registration_number': fleetRegistrationNumber,
      if (driverId != null) 'driver_id': driverId,
      if (driverName != null) 'driver_name': driverName,
      if (routeOrigin != null) 'route_origin': routeOrigin,
      if (routeDestination != null) 'route_destination': routeDestination,
      if (startingMileage != null) 'starting_mileage': startingMileage,
      if (waybillNo != null) 'waybill_no': waybillNo,
      if (closingMileage != null) 'closing_mileage': closingMileage,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalTripsCompanion copyWith({
    Value<String>? id,
    Value<String>? agentId,
    Value<String>? fleetId,
    Value<String?>? routeId,
    Value<String?>? deviceId,
    Value<String>? depotId,
    Value<String>? status,
    Value<bool>? startedOffline,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<String?>? fleetNumber,
    Value<String?>? fleetRegistrationNumber,
    Value<String?>? driverId,
    Value<String?>? driverName,
    Value<String?>? routeOrigin,
    Value<String?>? routeDestination,
    Value<int?>? startingMileage,
    Value<String?>? waybillNo,
    Value<int?>? closingMileage,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return LocalTripsCompanion(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      fleetId: fleetId ?? this.fleetId,
      routeId: routeId ?? this.routeId,
      deviceId: deviceId ?? this.deviceId,
      depotId: depotId ?? this.depotId,
      status: status ?? this.status,
      startedOffline: startedOffline ?? this.startedOffline,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      fleetNumber: fleetNumber ?? this.fleetNumber,
      fleetRegistrationNumber:
          fleetRegistrationNumber ?? this.fleetRegistrationNumber,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      routeOrigin: routeOrigin ?? this.routeOrigin,
      routeDestination: routeDestination ?? this.routeDestination,
      startingMileage: startingMileage ?? this.startingMileage,
      waybillNo: waybillNo ?? this.waybillNo,
      closingMileage: closingMileage ?? this.closingMileage,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (agentId.present) {
      map['agent_id'] = Variable<String>(agentId.value);
    }
    if (fleetId.present) {
      map['fleet_id'] = Variable<String>(fleetId.value);
    }
    if (routeId.present) {
      map['route_id'] = Variable<String>(routeId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (depotId.present) {
      map['depot_id'] = Variable<String>(depotId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startedOffline.present) {
      map['started_offline'] = Variable<bool>(startedOffline.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (fleetNumber.present) {
      map['fleet_number'] = Variable<String>(fleetNumber.value);
    }
    if (fleetRegistrationNumber.present) {
      map['fleet_registration_number'] = Variable<String>(
        fleetRegistrationNumber.value,
      );
    }
    if (driverId.present) {
      map['driver_id'] = Variable<String>(driverId.value);
    }
    if (driverName.present) {
      map['driver_name'] = Variable<String>(driverName.value);
    }
    if (routeOrigin.present) {
      map['route_origin'] = Variable<String>(routeOrigin.value);
    }
    if (routeDestination.present) {
      map['route_destination'] = Variable<String>(routeDestination.value);
    }
    if (startingMileage.present) {
      map['starting_mileage'] = Variable<int>(startingMileage.value);
    }
    if (waybillNo.present) {
      map['waybill_no'] = Variable<String>(waybillNo.value);
    }
    if (closingMileage.present) {
      map['closing_mileage'] = Variable<int>(closingMileage.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTripsCompanion(')
          ..write('id: $id, ')
          ..write('agentId: $agentId, ')
          ..write('fleetId: $fleetId, ')
          ..write('routeId: $routeId, ')
          ..write('deviceId: $deviceId, ')
          ..write('depotId: $depotId, ')
          ..write('status: $status, ')
          ..write('startedOffline: $startedOffline, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('fleetNumber: $fleetNumber, ')
          ..write('fleetRegistrationNumber: $fleetRegistrationNumber, ')
          ..write('driverId: $driverId, ')
          ..write('driverName: $driverName, ')
          ..write('routeOrigin: $routeOrigin, ')
          ..write('routeDestination: $routeDestination, ')
          ..write('startingMileage: $startingMileage, ')
          ..write('waybillNo: $waybillNo, ')
          ..write('closingMileage: $closingMileage, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalTicketsTable extends LocalTickets
    with TableInfo<$LocalTicketsTable, LocalTicket> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTicketsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _agentIdMeta = const VerificationMeta(
    'agentId',
  );
  @override
  late final GeneratedColumn<String> agentId = GeneratedColumn<String>(
    'agent_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _depotIdMeta = const VerificationMeta(
    'depotId',
  );
  @override
  late final GeneratedColumn<String> depotId = GeneratedColumn<String>(
    'depot_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ticketCategoryMeta = const VerificationMeta(
    'ticketCategory',
  );
  @override
  late final GeneratedColumn<String> ticketCategory = GeneratedColumn<String>(
    'ticket_category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _departureMeta = const VerificationMeta(
    'departure',
  );
  @override
  late final GeneratedColumn<String> departure = GeneratedColumn<String>(
    'departure',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _destinationMeta = const VerificationMeta(
    'destination',
  );
  @override
  late final GeneratedColumn<String> destination = GeneratedColumn<String>(
    'destination',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _passengerNameMeta = const VerificationMeta(
    'passengerName',
  );
  @override
  late final GeneratedColumn<String> passengerName = GeneratedColumn<String>(
    'passenger_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _passengerPhoneMeta = const VerificationMeta(
    'passengerPhone',
  );
  @override
  late final GeneratedColumn<String> passengerPhone = GeneratedColumn<String>(
    'passenger_phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _luggageAmountMeta = const VerificationMeta(
    'luggageAmount',
  );
  @override
  late final GeneratedColumn<double> luggageAmount = GeneratedColumn<double>(
    'luggage_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _luggageDescriptionMeta =
      const VerificationMeta('luggageDescription');
  @override
  late final GeneratedColumn<String> luggageDescription =
      GeneratedColumn<String>(
        'luggage_description',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _serialNumberMeta = const VerificationMeta(
    'serialNumber',
  );
  @override
  late final GeneratedColumn<int> serialNumber = GeneratedColumn<int>(
    'serial_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _issuedAtMeta = const VerificationMeta(
    'issuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> issuedAt = GeneratedColumn<DateTime>(
    'issued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _printedMeta = const VerificationMeta(
    'printed',
  );
  @override
  late final GeneratedColumn<bool> printed = GeneratedColumn<bool>(
    'printed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("printed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _printedAtMeta = const VerificationMeta(
    'printedAt',
  );
  @override
  late final GeneratedColumn<DateTime> printedAt = GeneratedColumn<DateTime>(
    'printed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tripId,
    agentId,
    deviceId,
    depotId,
    ticketCategory,
    currency,
    amount,
    departure,
    destination,
    passengerName,
    passengerPhone,
    luggageAmount,
    luggageDescription,
    serialNumber,
    issuedAt,
    printed,
    printedAt,
    syncStatus,
    idempotencyKey,
    lastError,
    retryCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_tickets';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalTicket> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('agent_id')) {
      context.handle(
        _agentIdMeta,
        agentId.isAcceptableOrUnknown(data['agent_id']!, _agentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_agentIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('depot_id')) {
      context.handle(
        _depotIdMeta,
        depotId.isAcceptableOrUnknown(data['depot_id']!, _depotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_depotIdMeta);
    }
    if (data.containsKey('ticket_category')) {
      context.handle(
        _ticketCategoryMeta,
        ticketCategory.isAcceptableOrUnknown(
          data['ticket_category']!,
          _ticketCategoryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ticketCategoryMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('departure')) {
      context.handle(
        _departureMeta,
        departure.isAcceptableOrUnknown(data['departure']!, _departureMeta),
      );
    }
    if (data.containsKey('destination')) {
      context.handle(
        _destinationMeta,
        destination.isAcceptableOrUnknown(
          data['destination']!,
          _destinationMeta,
        ),
      );
    }
    if (data.containsKey('passenger_name')) {
      context.handle(
        _passengerNameMeta,
        passengerName.isAcceptableOrUnknown(
          data['passenger_name']!,
          _passengerNameMeta,
        ),
      );
    }
    if (data.containsKey('passenger_phone')) {
      context.handle(
        _passengerPhoneMeta,
        passengerPhone.isAcceptableOrUnknown(
          data['passenger_phone']!,
          _passengerPhoneMeta,
        ),
      );
    }
    if (data.containsKey('luggage_amount')) {
      context.handle(
        _luggageAmountMeta,
        luggageAmount.isAcceptableOrUnknown(
          data['luggage_amount']!,
          _luggageAmountMeta,
        ),
      );
    }
    if (data.containsKey('luggage_description')) {
      context.handle(
        _luggageDescriptionMeta,
        luggageDescription.isAcceptableOrUnknown(
          data['luggage_description']!,
          _luggageDescriptionMeta,
        ),
      );
    }
    if (data.containsKey('serial_number')) {
      context.handle(
        _serialNumberMeta,
        serialNumber.isAcceptableOrUnknown(
          data['serial_number']!,
          _serialNumberMeta,
        ),
      );
    }
    if (data.containsKey('issued_at')) {
      context.handle(
        _issuedAtMeta,
        issuedAt.isAcceptableOrUnknown(data['issued_at']!, _issuedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_issuedAtMeta);
    }
    if (data.containsKey('printed')) {
      context.handle(
        _printedMeta,
        printed.isAcceptableOrUnknown(data['printed']!, _printedMeta),
      );
    }
    if (data.containsKey('printed_at')) {
      context.handle(
        _printedAtMeta,
        printedAt.isAcceptableOrUnknown(data['printed_at']!, _printedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {idempotencyKey},
  ];
  @override
  LocalTicket map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTicket(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      )!,
      agentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      depotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}depot_id'],
      )!,
      ticketCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ticket_category'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      departure: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}departure'],
      ),
      destination: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination'],
      ),
      passengerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}passenger_name'],
      ),
      passengerPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}passenger_phone'],
      ),
      luggageAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}luggage_amount'],
      ),
      luggageDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}luggage_description'],
      ),
      serialNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}serial_number'],
      ),
      issuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}issued_at'],
      )!,
      printed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}printed'],
      )!,
      printedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}printed_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
    );
  }

  @override
  $LocalTicketsTable createAlias(String alias) {
    return $LocalTicketsTable(attachedDatabase, alias);
  }
}

class LocalTicket extends DataClass implements Insertable<LocalTicket> {
  final String id;
  final String tripId;
  final String agentId;
  final String? deviceId;
  final String depotId;
  final String ticketCategory;
  final String currency;
  final double amount;
  final String? departure;
  final String? destination;
  final String? passengerName;
  final String? passengerPhone;
  final double? luggageAmount;
  final String? luggageDescription;
  final int? serialNumber;
  final DateTime issuedAt;
  final bool printed;
  final DateTime? printedAt;
  final String syncStatus;
  final String idempotencyKey;
  final String? lastError;
  final int retryCount;
  const LocalTicket({
    required this.id,
    required this.tripId,
    required this.agentId,
    this.deviceId,
    required this.depotId,
    required this.ticketCategory,
    required this.currency,
    required this.amount,
    this.departure,
    this.destination,
    this.passengerName,
    this.passengerPhone,
    this.luggageAmount,
    this.luggageDescription,
    this.serialNumber,
    required this.issuedAt,
    required this.printed,
    this.printedAt,
    required this.syncStatus,
    required this.idempotencyKey,
    this.lastError,
    required this.retryCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['trip_id'] = Variable<String>(tripId);
    map['agent_id'] = Variable<String>(agentId);
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    map['depot_id'] = Variable<String>(depotId);
    map['ticket_category'] = Variable<String>(ticketCategory);
    map['currency'] = Variable<String>(currency);
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || departure != null) {
      map['departure'] = Variable<String>(departure);
    }
    if (!nullToAbsent || destination != null) {
      map['destination'] = Variable<String>(destination);
    }
    if (!nullToAbsent || passengerName != null) {
      map['passenger_name'] = Variable<String>(passengerName);
    }
    if (!nullToAbsent || passengerPhone != null) {
      map['passenger_phone'] = Variable<String>(passengerPhone);
    }
    if (!nullToAbsent || luggageAmount != null) {
      map['luggage_amount'] = Variable<double>(luggageAmount);
    }
    if (!nullToAbsent || luggageDescription != null) {
      map['luggage_description'] = Variable<String>(luggageDescription);
    }
    if (!nullToAbsent || serialNumber != null) {
      map['serial_number'] = Variable<int>(serialNumber);
    }
    map['issued_at'] = Variable<DateTime>(issuedAt);
    map['printed'] = Variable<bool>(printed);
    if (!nullToAbsent || printedAt != null) {
      map['printed_at'] = Variable<DateTime>(printedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['retry_count'] = Variable<int>(retryCount);
    return map;
  }

  LocalTicketsCompanion toCompanion(bool nullToAbsent) {
    return LocalTicketsCompanion(
      id: Value(id),
      tripId: Value(tripId),
      agentId: Value(agentId),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      depotId: Value(depotId),
      ticketCategory: Value(ticketCategory),
      currency: Value(currency),
      amount: Value(amount),
      departure: departure == null && nullToAbsent
          ? const Value.absent()
          : Value(departure),
      destination: destination == null && nullToAbsent
          ? const Value.absent()
          : Value(destination),
      passengerName: passengerName == null && nullToAbsent
          ? const Value.absent()
          : Value(passengerName),
      passengerPhone: passengerPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(passengerPhone),
      luggageAmount: luggageAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(luggageAmount),
      luggageDescription: luggageDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(luggageDescription),
      serialNumber: serialNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(serialNumber),
      issuedAt: Value(issuedAt),
      printed: Value(printed),
      printedAt: printedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(printedAt),
      syncStatus: Value(syncStatus),
      idempotencyKey: Value(idempotencyKey),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      retryCount: Value(retryCount),
    );
  }

  factory LocalTicket.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTicket(
      id: serializer.fromJson<String>(json['id']),
      tripId: serializer.fromJson<String>(json['tripId']),
      agentId: serializer.fromJson<String>(json['agentId']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      depotId: serializer.fromJson<String>(json['depotId']),
      ticketCategory: serializer.fromJson<String>(json['ticketCategory']),
      currency: serializer.fromJson<String>(json['currency']),
      amount: serializer.fromJson<double>(json['amount']),
      departure: serializer.fromJson<String?>(json['departure']),
      destination: serializer.fromJson<String?>(json['destination']),
      passengerName: serializer.fromJson<String?>(json['passengerName']),
      passengerPhone: serializer.fromJson<String?>(json['passengerPhone']),
      luggageAmount: serializer.fromJson<double?>(json['luggageAmount']),
      luggageDescription: serializer.fromJson<String?>(
        json['luggageDescription'],
      ),
      serialNumber: serializer.fromJson<int?>(json['serialNumber']),
      issuedAt: serializer.fromJson<DateTime>(json['issuedAt']),
      printed: serializer.fromJson<bool>(json['printed']),
      printedAt: serializer.fromJson<DateTime?>(json['printedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tripId': serializer.toJson<String>(tripId),
      'agentId': serializer.toJson<String>(agentId),
      'deviceId': serializer.toJson<String?>(deviceId),
      'depotId': serializer.toJson<String>(depotId),
      'ticketCategory': serializer.toJson<String>(ticketCategory),
      'currency': serializer.toJson<String>(currency),
      'amount': serializer.toJson<double>(amount),
      'departure': serializer.toJson<String?>(departure),
      'destination': serializer.toJson<String?>(destination),
      'passengerName': serializer.toJson<String?>(passengerName),
      'passengerPhone': serializer.toJson<String?>(passengerPhone),
      'luggageAmount': serializer.toJson<double?>(luggageAmount),
      'luggageDescription': serializer.toJson<String?>(luggageDescription),
      'serialNumber': serializer.toJson<int?>(serialNumber),
      'issuedAt': serializer.toJson<DateTime>(issuedAt),
      'printed': serializer.toJson<bool>(printed),
      'printedAt': serializer.toJson<DateTime?>(printedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'lastError': serializer.toJson<String?>(lastError),
      'retryCount': serializer.toJson<int>(retryCount),
    };
  }

  LocalTicket copyWith({
    String? id,
    String? tripId,
    String? agentId,
    Value<String?> deviceId = const Value.absent(),
    String? depotId,
    String? ticketCategory,
    String? currency,
    double? amount,
    Value<String?> departure = const Value.absent(),
    Value<String?> destination = const Value.absent(),
    Value<String?> passengerName = const Value.absent(),
    Value<String?> passengerPhone = const Value.absent(),
    Value<double?> luggageAmount = const Value.absent(),
    Value<String?> luggageDescription = const Value.absent(),
    Value<int?> serialNumber = const Value.absent(),
    DateTime? issuedAt,
    bool? printed,
    Value<DateTime?> printedAt = const Value.absent(),
    String? syncStatus,
    String? idempotencyKey,
    Value<String?> lastError = const Value.absent(),
    int? retryCount,
  }) => LocalTicket(
    id: id ?? this.id,
    tripId: tripId ?? this.tripId,
    agentId: agentId ?? this.agentId,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    depotId: depotId ?? this.depotId,
    ticketCategory: ticketCategory ?? this.ticketCategory,
    currency: currency ?? this.currency,
    amount: amount ?? this.amount,
    departure: departure.present ? departure.value : this.departure,
    destination: destination.present ? destination.value : this.destination,
    passengerName: passengerName.present
        ? passengerName.value
        : this.passengerName,
    passengerPhone: passengerPhone.present
        ? passengerPhone.value
        : this.passengerPhone,
    luggageAmount: luggageAmount.present
        ? luggageAmount.value
        : this.luggageAmount,
    luggageDescription: luggageDescription.present
        ? luggageDescription.value
        : this.luggageDescription,
    serialNumber: serialNumber.present ? serialNumber.value : this.serialNumber,
    issuedAt: issuedAt ?? this.issuedAt,
    printed: printed ?? this.printed,
    printedAt: printedAt.present ? printedAt.value : this.printedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    lastError: lastError.present ? lastError.value : this.lastError,
    retryCount: retryCount ?? this.retryCount,
  );
  LocalTicket copyWithCompanion(LocalTicketsCompanion data) {
    return LocalTicket(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      agentId: data.agentId.present ? data.agentId.value : this.agentId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      depotId: data.depotId.present ? data.depotId.value : this.depotId,
      ticketCategory: data.ticketCategory.present
          ? data.ticketCategory.value
          : this.ticketCategory,
      currency: data.currency.present ? data.currency.value : this.currency,
      amount: data.amount.present ? data.amount.value : this.amount,
      departure: data.departure.present ? data.departure.value : this.departure,
      destination: data.destination.present
          ? data.destination.value
          : this.destination,
      passengerName: data.passengerName.present
          ? data.passengerName.value
          : this.passengerName,
      passengerPhone: data.passengerPhone.present
          ? data.passengerPhone.value
          : this.passengerPhone,
      luggageAmount: data.luggageAmount.present
          ? data.luggageAmount.value
          : this.luggageAmount,
      luggageDescription: data.luggageDescription.present
          ? data.luggageDescription.value
          : this.luggageDescription,
      serialNumber: data.serialNumber.present
          ? data.serialNumber.value
          : this.serialNumber,
      issuedAt: data.issuedAt.present ? data.issuedAt.value : this.issuedAt,
      printed: data.printed.present ? data.printed.value : this.printed,
      printedAt: data.printedAt.present ? data.printedAt.value : this.printedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTicket(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('agentId: $agentId, ')
          ..write('deviceId: $deviceId, ')
          ..write('depotId: $depotId, ')
          ..write('ticketCategory: $ticketCategory, ')
          ..write('currency: $currency, ')
          ..write('amount: $amount, ')
          ..write('departure: $departure, ')
          ..write('destination: $destination, ')
          ..write('passengerName: $passengerName, ')
          ..write('passengerPhone: $passengerPhone, ')
          ..write('luggageAmount: $luggageAmount, ')
          ..write('luggageDescription: $luggageDescription, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('issuedAt: $issuedAt, ')
          ..write('printed: $printed, ')
          ..write('printedAt: $printedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('lastError: $lastError, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    tripId,
    agentId,
    deviceId,
    depotId,
    ticketCategory,
    currency,
    amount,
    departure,
    destination,
    passengerName,
    passengerPhone,
    luggageAmount,
    luggageDescription,
    serialNumber,
    issuedAt,
    printed,
    printedAt,
    syncStatus,
    idempotencyKey,
    lastError,
    retryCount,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTicket &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.agentId == this.agentId &&
          other.deviceId == this.deviceId &&
          other.depotId == this.depotId &&
          other.ticketCategory == this.ticketCategory &&
          other.currency == this.currency &&
          other.amount == this.amount &&
          other.departure == this.departure &&
          other.destination == this.destination &&
          other.passengerName == this.passengerName &&
          other.passengerPhone == this.passengerPhone &&
          other.luggageAmount == this.luggageAmount &&
          other.luggageDescription == this.luggageDescription &&
          other.serialNumber == this.serialNumber &&
          other.issuedAt == this.issuedAt &&
          other.printed == this.printed &&
          other.printedAt == this.printedAt &&
          other.syncStatus == this.syncStatus &&
          other.idempotencyKey == this.idempotencyKey &&
          other.lastError == this.lastError &&
          other.retryCount == this.retryCount);
}

class LocalTicketsCompanion extends UpdateCompanion<LocalTicket> {
  final Value<String> id;
  final Value<String> tripId;
  final Value<String> agentId;
  final Value<String?> deviceId;
  final Value<String> depotId;
  final Value<String> ticketCategory;
  final Value<String> currency;
  final Value<double> amount;
  final Value<String?> departure;
  final Value<String?> destination;
  final Value<String?> passengerName;
  final Value<String?> passengerPhone;
  final Value<double?> luggageAmount;
  final Value<String?> luggageDescription;
  final Value<int?> serialNumber;
  final Value<DateTime> issuedAt;
  final Value<bool> printed;
  final Value<DateTime?> printedAt;
  final Value<String> syncStatus;
  final Value<String> idempotencyKey;
  final Value<String?> lastError;
  final Value<int> retryCount;
  final Value<int> rowid;
  const LocalTicketsCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.agentId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.depotId = const Value.absent(),
    this.ticketCategory = const Value.absent(),
    this.currency = const Value.absent(),
    this.amount = const Value.absent(),
    this.departure = const Value.absent(),
    this.destination = const Value.absent(),
    this.passengerName = const Value.absent(),
    this.passengerPhone = const Value.absent(),
    this.luggageAmount = const Value.absent(),
    this.luggageDescription = const Value.absent(),
    this.serialNumber = const Value.absent(),
    this.issuedAt = const Value.absent(),
    this.printed = const Value.absent(),
    this.printedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.lastError = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalTicketsCompanion.insert({
    required String id,
    required String tripId,
    required String agentId,
    this.deviceId = const Value.absent(),
    required String depotId,
    required String ticketCategory,
    required String currency,
    required double amount,
    this.departure = const Value.absent(),
    this.destination = const Value.absent(),
    this.passengerName = const Value.absent(),
    this.passengerPhone = const Value.absent(),
    this.luggageAmount = const Value.absent(),
    this.luggageDescription = const Value.absent(),
    this.serialNumber = const Value.absent(),
    required DateTime issuedAt,
    this.printed = const Value.absent(),
    this.printedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required String idempotencyKey,
    this.lastError = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tripId = Value(tripId),
       agentId = Value(agentId),
       depotId = Value(depotId),
       ticketCategory = Value(ticketCategory),
       currency = Value(currency),
       amount = Value(amount),
       issuedAt = Value(issuedAt),
       idempotencyKey = Value(idempotencyKey);
  static Insertable<LocalTicket> custom({
    Expression<String>? id,
    Expression<String>? tripId,
    Expression<String>? agentId,
    Expression<String>? deviceId,
    Expression<String>? depotId,
    Expression<String>? ticketCategory,
    Expression<String>? currency,
    Expression<double>? amount,
    Expression<String>? departure,
    Expression<String>? destination,
    Expression<String>? passengerName,
    Expression<String>? passengerPhone,
    Expression<double>? luggageAmount,
    Expression<String>? luggageDescription,
    Expression<int>? serialNumber,
    Expression<DateTime>? issuedAt,
    Expression<bool>? printed,
    Expression<DateTime>? printedAt,
    Expression<String>? syncStatus,
    Expression<String>? idempotencyKey,
    Expression<String>? lastError,
    Expression<int>? retryCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (agentId != null) 'agent_id': agentId,
      if (deviceId != null) 'device_id': deviceId,
      if (depotId != null) 'depot_id': depotId,
      if (ticketCategory != null) 'ticket_category': ticketCategory,
      if (currency != null) 'currency': currency,
      if (amount != null) 'amount': amount,
      if (departure != null) 'departure': departure,
      if (destination != null) 'destination': destination,
      if (passengerName != null) 'passenger_name': passengerName,
      if (passengerPhone != null) 'passenger_phone': passengerPhone,
      if (luggageAmount != null) 'luggage_amount': luggageAmount,
      if (luggageDescription != null) 'luggage_description': luggageDescription,
      if (serialNumber != null) 'serial_number': serialNumber,
      if (issuedAt != null) 'issued_at': issuedAt,
      if (printed != null) 'printed': printed,
      if (printedAt != null) 'printed_at': printedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (lastError != null) 'last_error': lastError,
      if (retryCount != null) 'retry_count': retryCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalTicketsCompanion copyWith({
    Value<String>? id,
    Value<String>? tripId,
    Value<String>? agentId,
    Value<String?>? deviceId,
    Value<String>? depotId,
    Value<String>? ticketCategory,
    Value<String>? currency,
    Value<double>? amount,
    Value<String?>? departure,
    Value<String?>? destination,
    Value<String?>? passengerName,
    Value<String?>? passengerPhone,
    Value<double?>? luggageAmount,
    Value<String?>? luggageDescription,
    Value<int?>? serialNumber,
    Value<DateTime>? issuedAt,
    Value<bool>? printed,
    Value<DateTime?>? printedAt,
    Value<String>? syncStatus,
    Value<String>? idempotencyKey,
    Value<String?>? lastError,
    Value<int>? retryCount,
    Value<int>? rowid,
  }) {
    return LocalTicketsCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      agentId: agentId ?? this.agentId,
      deviceId: deviceId ?? this.deviceId,
      depotId: depotId ?? this.depotId,
      ticketCategory: ticketCategory ?? this.ticketCategory,
      currency: currency ?? this.currency,
      amount: amount ?? this.amount,
      departure: departure ?? this.departure,
      destination: destination ?? this.destination,
      passengerName: passengerName ?? this.passengerName,
      passengerPhone: passengerPhone ?? this.passengerPhone,
      luggageAmount: luggageAmount ?? this.luggageAmount,
      luggageDescription: luggageDescription ?? this.luggageDescription,
      serialNumber: serialNumber ?? this.serialNumber,
      issuedAt: issuedAt ?? this.issuedAt,
      printed: printed ?? this.printed,
      printedAt: printedAt ?? this.printedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      lastError: lastError ?? this.lastError,
      retryCount: retryCount ?? this.retryCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (agentId.present) {
      map['agent_id'] = Variable<String>(agentId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (depotId.present) {
      map['depot_id'] = Variable<String>(depotId.value);
    }
    if (ticketCategory.present) {
      map['ticket_category'] = Variable<String>(ticketCategory.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (departure.present) {
      map['departure'] = Variable<String>(departure.value);
    }
    if (destination.present) {
      map['destination'] = Variable<String>(destination.value);
    }
    if (passengerName.present) {
      map['passenger_name'] = Variable<String>(passengerName.value);
    }
    if (passengerPhone.present) {
      map['passenger_phone'] = Variable<String>(passengerPhone.value);
    }
    if (luggageAmount.present) {
      map['luggage_amount'] = Variable<double>(luggageAmount.value);
    }
    if (luggageDescription.present) {
      map['luggage_description'] = Variable<String>(luggageDescription.value);
    }
    if (serialNumber.present) {
      map['serial_number'] = Variable<int>(serialNumber.value);
    }
    if (issuedAt.present) {
      map['issued_at'] = Variable<DateTime>(issuedAt.value);
    }
    if (printed.present) {
      map['printed'] = Variable<bool>(printed.value);
    }
    if (printedAt.present) {
      map['printed_at'] = Variable<DateTime>(printedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTicketsCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('agentId: $agentId, ')
          ..write('deviceId: $deviceId, ')
          ..write('depotId: $depotId, ')
          ..write('ticketCategory: $ticketCategory, ')
          ..write('currency: $currency, ')
          ..write('amount: $amount, ')
          ..write('departure: $departure, ')
          ..write('destination: $destination, ')
          ..write('passengerName: $passengerName, ')
          ..write('passengerPhone: $passengerPhone, ')
          ..write('luggageAmount: $luggageAmount, ')
          ..write('luggageDescription: $luggageDescription, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('issuedAt: $issuedAt, ')
          ..write('printed: $printed, ')
          ..write('printedAt: $printedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('lastError: $lastError, ')
          ..write('retryCount: $retryCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueItemsTable extends SyncQueueItems
    with TableInfo<$SyncQueueItemsTable, SyncQueueItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityId,
    operation,
    payloadJson,
    status,
    retryCount,
    lastError,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SyncQueueItemsTable createAlias(String alias) {
    return $SyncQueueItemsTable(attachedDatabase, alias);
  }
}

class SyncQueueItem extends DataClass implements Insertable<SyncQueueItem> {
  final int id;
  final String entityType;
  final String entityId;
  final String operation;
  final String payloadJson;
  final String status;
  final int retryCount;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payloadJson,
    required this.status,
    required this.retryCount,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['payload_json'] = Variable<String>(payloadJson);
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncQueueItemsCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueItemsCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      payloadJson: Value(payloadJson),
      status: Value(status),
      retryCount: Value(retryCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncQueueItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueItem(
      id: serializer.fromJson<int>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncQueueItem copyWith({
    int? id,
    String? entityType,
    String? entityId,
    String? operation,
    String? payloadJson,
    String? status,
    int? retryCount,
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SyncQueueItem(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    operation: operation ?? this.operation,
    payloadJson: payloadJson ?? this.payloadJson,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SyncQueueItem copyWithCompanion(SyncQueueItemsCompanion data) {
    return SyncQueueItem(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      status: data.status.present ? data.status.value : this.status,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueItem(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityId,
    operation,
    payloadJson,
    status,
    retryCount,
    lastError,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueItem &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payloadJson == this.payloadJson &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SyncQueueItemsCompanion extends UpdateCompanion<SyncQueueItem> {
  final Value<int> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> payloadJson;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SyncQueueItemsCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SyncQueueItemsCompanion.insert({
    this.id = const Value.absent(),
    required String entityType,
    required String entityId,
    required String operation,
    required String payloadJson,
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : entityType = Value(entityType),
       entityId = Value(entityId),
       operation = Value(operation),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SyncQueueItem> custom({
    Expression<int>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? payloadJson,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SyncQueueItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? operation,
    Value<String>? payloadJson,
    Value<String>? status,
    Value<int>? retryCount,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return SyncQueueItemsCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payloadJson: payloadJson ?? this.payloadJson,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueItemsCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SyncMetadataTable extends SyncMetadata
    with TableInfo<$SyncMetadataTable, SyncMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetadataTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'sync_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetadataData> instance, {
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
  SyncMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetadataData(
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
  $SyncMetadataTable createAlias(String alias) {
    return $SyncMetadataTable(attachedDatabase, alias);
  }
}

class SyncMetadataData extends DataClass
    implements Insertable<SyncMetadataData> {
  final String key;
  final String value;
  const SyncMetadataData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncMetadataCompanion toCompanion(bool nullToAbsent) {
    return SyncMetadataCompanion(key: Value(key), value: Value(value));
  }

  factory SyncMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetadataData(
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

  SyncMetadataData copyWith({String? key, String? value}) =>
      SyncMetadataData(key: key ?? this.key, value: value ?? this.value);
  SyncMetadataData copyWithCompanion(SyncMetadataCompanion data) {
    return SyncMetadataData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataData(')
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
      (other is SyncMetadataData &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncMetadataCompanion extends UpdateCompanion<SyncMetadataData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncMetadataCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetadataCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SyncMetadataData> custom({
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

  SyncMetadataCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SyncMetadataCompanion(
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
    return (StringBuffer('SyncMetadataCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedFleetsTable cachedFleets = $CachedFleetsTable(this);
  late final $CachedDriversTable cachedDrivers = $CachedDriversTable(this);
  late final $CachedRoutesTable cachedRoutes = $CachedRoutesTable(this);
  late final $CachedFaresTable cachedFares = $CachedFaresTable(this);
  late final $LocalTripsTable localTrips = $LocalTripsTable(this);
  late final $LocalTicketsTable localTickets = $LocalTicketsTable(this);
  late final $SyncQueueItemsTable syncQueueItems = $SyncQueueItemsTable(this);
  late final $SyncMetadataTable syncMetadata = $SyncMetadataTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedFleets,
    cachedDrivers,
    cachedRoutes,
    cachedFares,
    localTrips,
    localTickets,
    syncQueueItems,
    syncMetadata,
  ];
}

typedef $$CachedFleetsTableCreateCompanionBuilder =
    CachedFleetsCompanion Function({
      required String id,
      required String number,
      Value<String?> registrationNumber,
      Value<String> status,
      Value<bool> onTrip,
      Value<int> capacity,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedFleetsTableUpdateCompanionBuilder =
    CachedFleetsCompanion Function({
      Value<String> id,
      Value<String> number,
      Value<String?> registrationNumber,
      Value<String> status,
      Value<bool> onTrip,
      Value<int> capacity,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedFleetsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedFleetsTable> {
  $$CachedFleetsTableFilterComposer({
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

  ColumnFilters<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get registrationNumber => $composableBuilder(
    column: $table.registrationNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onTrip => $composableBuilder(
    column: $table.onTrip,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get capacity => $composableBuilder(
    column: $table.capacity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedFleetsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedFleetsTable> {
  $$CachedFleetsTableOrderingComposer({
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

  ColumnOrderings<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get registrationNumber => $composableBuilder(
    column: $table.registrationNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onTrip => $composableBuilder(
    column: $table.onTrip,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get capacity => $composableBuilder(
    column: $table.capacity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedFleetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedFleetsTable> {
  $$CachedFleetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get registrationNumber => $composableBuilder(
    column: $table.registrationNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get onTrip =>
      $composableBuilder(column: $table.onTrip, builder: (column) => column);

  GeneratedColumn<int> get capacity =>
      $composableBuilder(column: $table.capacity, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedFleetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedFleetsTable,
          CachedFleet,
          $$CachedFleetsTableFilterComposer,
          $$CachedFleetsTableOrderingComposer,
          $$CachedFleetsTableAnnotationComposer,
          $$CachedFleetsTableCreateCompanionBuilder,
          $$CachedFleetsTableUpdateCompanionBuilder,
          (
            CachedFleet,
            BaseReferences<_$AppDatabase, $CachedFleetsTable, CachedFleet>,
          ),
          CachedFleet,
          PrefetchHooks Function()
        > {
  $$CachedFleetsTableTableManager(_$AppDatabase db, $CachedFleetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedFleetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedFleetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedFleetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> number = const Value.absent(),
                Value<String?> registrationNumber = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> onTrip = const Value.absent(),
                Value<int> capacity = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedFleetsCompanion(
                id: id,
                number: number,
                registrationNumber: registrationNumber,
                status: status,
                onTrip: onTrip,
                capacity: capacity,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String number,
                Value<String?> registrationNumber = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> onTrip = const Value.absent(),
                Value<int> capacity = const Value.absent(),
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedFleetsCompanion.insert(
                id: id,
                number: number,
                registrationNumber: registrationNumber,
                status: status,
                onTrip: onTrip,
                capacity: capacity,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedFleetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedFleetsTable,
      CachedFleet,
      $$CachedFleetsTableFilterComposer,
      $$CachedFleetsTableOrderingComposer,
      $$CachedFleetsTableAnnotationComposer,
      $$CachedFleetsTableCreateCompanionBuilder,
      $$CachedFleetsTableUpdateCompanionBuilder,
      (
        CachedFleet,
        BaseReferences<_$AppDatabase, $CachedFleetsTable, CachedFleet>,
      ),
      CachedFleet,
      PrefetchHooks Function()
    >;
typedef $$CachedDriversTableCreateCompanionBuilder =
    CachedDriversCompanion Function({
      required String id,
      required String fullName,
      Value<String> status,
      Value<bool> onTrip,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedDriversTableUpdateCompanionBuilder =
    CachedDriversCompanion Function({
      Value<String> id,
      Value<String> fullName,
      Value<String> status,
      Value<bool> onTrip,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedDriversTableFilterComposer
    extends Composer<_$AppDatabase, $CachedDriversTable> {
  $$CachedDriversTableFilterComposer({
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

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onTrip => $composableBuilder(
    column: $table.onTrip,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedDriversTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedDriversTable> {
  $$CachedDriversTableOrderingComposer({
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

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onTrip => $composableBuilder(
    column: $table.onTrip,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedDriversTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedDriversTable> {
  $$CachedDriversTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get onTrip =>
      $composableBuilder(column: $table.onTrip, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedDriversTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedDriversTable,
          CachedDriver,
          $$CachedDriversTableFilterComposer,
          $$CachedDriversTableOrderingComposer,
          $$CachedDriversTableAnnotationComposer,
          $$CachedDriversTableCreateCompanionBuilder,
          $$CachedDriversTableUpdateCompanionBuilder,
          (
            CachedDriver,
            BaseReferences<_$AppDatabase, $CachedDriversTable, CachedDriver>,
          ),
          CachedDriver,
          PrefetchHooks Function()
        > {
  $$CachedDriversTableTableManager(_$AppDatabase db, $CachedDriversTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedDriversTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedDriversTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedDriversTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> fullName = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> onTrip = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedDriversCompanion(
                id: id,
                fullName: fullName,
                status: status,
                onTrip: onTrip,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String fullName,
                Value<String> status = const Value.absent(),
                Value<bool> onTrip = const Value.absent(),
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedDriversCompanion.insert(
                id: id,
                fullName: fullName,
                status: status,
                onTrip: onTrip,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedDriversTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedDriversTable,
      CachedDriver,
      $$CachedDriversTableFilterComposer,
      $$CachedDriversTableOrderingComposer,
      $$CachedDriversTableAnnotationComposer,
      $$CachedDriversTableCreateCompanionBuilder,
      $$CachedDriversTableUpdateCompanionBuilder,
      (
        CachedDriver,
        BaseReferences<_$AppDatabase, $CachedDriversTable, CachedDriver>,
      ),
      CachedDriver,
      PrefetchHooks Function()
    >;
typedef $$CachedRoutesTableCreateCompanionBuilder =
    CachedRoutesCompanion Function({
      required String id,
      required String origin,
      required String destination,
      Value<String> parentRouteIdsJson,
      Value<String> childRouteIdsJson,
      Value<bool> isActive,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedRoutesTableUpdateCompanionBuilder =
    CachedRoutesCompanion Function({
      Value<String> id,
      Value<String> origin,
      Value<String> destination,
      Value<String> parentRouteIdsJson,
      Value<String> childRouteIdsJson,
      Value<bool> isActive,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedRoutesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedRoutesTable> {
  $$CachedRoutesTableFilterComposer({
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

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentRouteIdsJson => $composableBuilder(
    column: $table.parentRouteIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get childRouteIdsJson => $composableBuilder(
    column: $table.childRouteIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedRoutesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedRoutesTable> {
  $$CachedRoutesTableOrderingComposer({
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

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentRouteIdsJson => $composableBuilder(
    column: $table.parentRouteIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get childRouteIdsJson => $composableBuilder(
    column: $table.childRouteIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedRoutesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedRoutesTable> {
  $$CachedRoutesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parentRouteIdsJson => $composableBuilder(
    column: $table.parentRouteIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get childRouteIdsJson => $composableBuilder(
    column: $table.childRouteIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedRoutesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedRoutesTable,
          CachedRoute,
          $$CachedRoutesTableFilterComposer,
          $$CachedRoutesTableOrderingComposer,
          $$CachedRoutesTableAnnotationComposer,
          $$CachedRoutesTableCreateCompanionBuilder,
          $$CachedRoutesTableUpdateCompanionBuilder,
          (
            CachedRoute,
            BaseReferences<_$AppDatabase, $CachedRoutesTable, CachedRoute>,
          ),
          CachedRoute,
          PrefetchHooks Function()
        > {
  $$CachedRoutesTableTableManager(_$AppDatabase db, $CachedRoutesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedRoutesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedRoutesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedRoutesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<String> destination = const Value.absent(),
                Value<String> parentRouteIdsJson = const Value.absent(),
                Value<String> childRouteIdsJson = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedRoutesCompanion(
                id: id,
                origin: origin,
                destination: destination,
                parentRouteIdsJson: parentRouteIdsJson,
                childRouteIdsJson: childRouteIdsJson,
                isActive: isActive,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String origin,
                required String destination,
                Value<String> parentRouteIdsJson = const Value.absent(),
                Value<String> childRouteIdsJson = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedRoutesCompanion.insert(
                id: id,
                origin: origin,
                destination: destination,
                parentRouteIdsJson: parentRouteIdsJson,
                childRouteIdsJson: childRouteIdsJson,
                isActive: isActive,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedRoutesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedRoutesTable,
      CachedRoute,
      $$CachedRoutesTableFilterComposer,
      $$CachedRoutesTableOrderingComposer,
      $$CachedRoutesTableAnnotationComposer,
      $$CachedRoutesTableCreateCompanionBuilder,
      $$CachedRoutesTableUpdateCompanionBuilder,
      (
        CachedRoute,
        BaseReferences<_$AppDatabase, $CachedRoutesTable, CachedRoute>,
      ),
      CachedRoute,
      PrefetchHooks Function()
    >;
typedef $$CachedFaresTableCreateCompanionBuilder =
    CachedFaresCompanion Function({
      required String id,
      required String routeId,
      required String currency,
      required double amount,
      Value<String?> routeLabel,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedFaresTableUpdateCompanionBuilder =
    CachedFaresCompanion Function({
      Value<String> id,
      Value<String> routeId,
      Value<String> currency,
      Value<double> amount,
      Value<String?> routeLabel,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedFaresTableFilterComposer
    extends Composer<_$AppDatabase, $CachedFaresTable> {
  $$CachedFaresTableFilterComposer({
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

  ColumnFilters<String> get routeId => $composableBuilder(
    column: $table.routeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routeLabel => $composableBuilder(
    column: $table.routeLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedFaresTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedFaresTable> {
  $$CachedFaresTableOrderingComposer({
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

  ColumnOrderings<String> get routeId => $composableBuilder(
    column: $table.routeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routeLabel => $composableBuilder(
    column: $table.routeLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedFaresTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedFaresTable> {
  $$CachedFaresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get routeId =>
      $composableBuilder(column: $table.routeId, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get routeLabel => $composableBuilder(
    column: $table.routeLabel,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedFaresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedFaresTable,
          CachedFare,
          $$CachedFaresTableFilterComposer,
          $$CachedFaresTableOrderingComposer,
          $$CachedFaresTableAnnotationComposer,
          $$CachedFaresTableCreateCompanionBuilder,
          $$CachedFaresTableUpdateCompanionBuilder,
          (
            CachedFare,
            BaseReferences<_$AppDatabase, $CachedFaresTable, CachedFare>,
          ),
          CachedFare,
          PrefetchHooks Function()
        > {
  $$CachedFaresTableTableManager(_$AppDatabase db, $CachedFaresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedFaresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedFaresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedFaresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> routeId = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String?> routeLabel = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedFaresCompanion(
                id: id,
                routeId: routeId,
                currency: currency,
                amount: amount,
                routeLabel: routeLabel,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String routeId,
                required String currency,
                required double amount,
                Value<String?> routeLabel = const Value.absent(),
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedFaresCompanion.insert(
                id: id,
                routeId: routeId,
                currency: currency,
                amount: amount,
                routeLabel: routeLabel,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedFaresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedFaresTable,
      CachedFare,
      $$CachedFaresTableFilterComposer,
      $$CachedFaresTableOrderingComposer,
      $$CachedFaresTableAnnotationComposer,
      $$CachedFaresTableCreateCompanionBuilder,
      $$CachedFaresTableUpdateCompanionBuilder,
      (
        CachedFare,
        BaseReferences<_$AppDatabase, $CachedFaresTable, CachedFare>,
      ),
      CachedFare,
      PrefetchHooks Function()
    >;
typedef $$LocalTripsTableCreateCompanionBuilder =
    LocalTripsCompanion Function({
      required String id,
      required String agentId,
      required String fleetId,
      Value<String?> routeId,
      Value<String?> deviceId,
      required String depotId,
      Value<String> status,
      Value<bool> startedOffline,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<String?> fleetNumber,
      Value<String?> fleetRegistrationNumber,
      Value<String?> driverId,
      Value<String?> driverName,
      Value<String?> routeOrigin,
      Value<String?> routeDestination,
      Value<int?> startingMileage,
      Value<String?> waybillNo,
      Value<int?> closingMileage,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$LocalTripsTableUpdateCompanionBuilder =
    LocalTripsCompanion Function({
      Value<String> id,
      Value<String> agentId,
      Value<String> fleetId,
      Value<String?> routeId,
      Value<String?> deviceId,
      Value<String> depotId,
      Value<String> status,
      Value<bool> startedOffline,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<String?> fleetNumber,
      Value<String?> fleetRegistrationNumber,
      Value<String?> driverId,
      Value<String?> driverName,
      Value<String?> routeOrigin,
      Value<String?> routeDestination,
      Value<int?> startingMileage,
      Value<String?> waybillNo,
      Value<int?> closingMileage,
      Value<String> syncStatus,
      Value<int> rowid,
    });

class $$LocalTripsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalTripsTable> {
  $$LocalTripsTableFilterComposer({
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

  ColumnFilters<String> get agentId => $composableBuilder(
    column: $table.agentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fleetId => $composableBuilder(
    column: $table.fleetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routeId => $composableBuilder(
    column: $table.routeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get depotId => $composableBuilder(
    column: $table.depotId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get startedOffline => $composableBuilder(
    column: $table.startedOffline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fleetNumber => $composableBuilder(
    column: $table.fleetNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fleetRegistrationNumber => $composableBuilder(
    column: $table.fleetRegistrationNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get driverId => $composableBuilder(
    column: $table.driverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get driverName => $composableBuilder(
    column: $table.driverName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routeOrigin => $composableBuilder(
    column: $table.routeOrigin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routeDestination => $composableBuilder(
    column: $table.routeDestination,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startingMileage => $composableBuilder(
    column: $table.startingMileage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get waybillNo => $composableBuilder(
    column: $table.waybillNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get closingMileage => $composableBuilder(
    column: $table.closingMileage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalTripsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalTripsTable> {
  $$LocalTripsTableOrderingComposer({
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

  ColumnOrderings<String> get agentId => $composableBuilder(
    column: $table.agentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fleetId => $composableBuilder(
    column: $table.fleetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routeId => $composableBuilder(
    column: $table.routeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get depotId => $composableBuilder(
    column: $table.depotId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get startedOffline => $composableBuilder(
    column: $table.startedOffline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fleetNumber => $composableBuilder(
    column: $table.fleetNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fleetRegistrationNumber => $composableBuilder(
    column: $table.fleetRegistrationNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get driverId => $composableBuilder(
    column: $table.driverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get driverName => $composableBuilder(
    column: $table.driverName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routeOrigin => $composableBuilder(
    column: $table.routeOrigin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routeDestination => $composableBuilder(
    column: $table.routeDestination,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startingMileage => $composableBuilder(
    column: $table.startingMileage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get waybillNo => $composableBuilder(
    column: $table.waybillNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get closingMileage => $composableBuilder(
    column: $table.closingMileage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalTripsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalTripsTable> {
  $$LocalTripsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get agentId =>
      $composableBuilder(column: $table.agentId, builder: (column) => column);

  GeneratedColumn<String> get fleetId =>
      $composableBuilder(column: $table.fleetId, builder: (column) => column);

  GeneratedColumn<String> get routeId =>
      $composableBuilder(column: $table.routeId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get depotId =>
      $composableBuilder(column: $table.depotId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get startedOffline => $composableBuilder(
    column: $table.startedOffline,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get fleetNumber => $composableBuilder(
    column: $table.fleetNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fleetRegistrationNumber => $composableBuilder(
    column: $table.fleetRegistrationNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get driverId =>
      $composableBuilder(column: $table.driverId, builder: (column) => column);

  GeneratedColumn<String> get driverName => $composableBuilder(
    column: $table.driverName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get routeOrigin => $composableBuilder(
    column: $table.routeOrigin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get routeDestination => $composableBuilder(
    column: $table.routeDestination,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startingMileage => $composableBuilder(
    column: $table.startingMileage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get waybillNo =>
      $composableBuilder(column: $table.waybillNo, builder: (column) => column);

  GeneratedColumn<int> get closingMileage => $composableBuilder(
    column: $table.closingMileage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$LocalTripsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalTripsTable,
          LocalTrip,
          $$LocalTripsTableFilterComposer,
          $$LocalTripsTableOrderingComposer,
          $$LocalTripsTableAnnotationComposer,
          $$LocalTripsTableCreateCompanionBuilder,
          $$LocalTripsTableUpdateCompanionBuilder,
          (
            LocalTrip,
            BaseReferences<_$AppDatabase, $LocalTripsTable, LocalTrip>,
          ),
          LocalTrip,
          PrefetchHooks Function()
        > {
  $$LocalTripsTableTableManager(_$AppDatabase db, $LocalTripsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTripsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTripsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalTripsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> agentId = const Value.absent(),
                Value<String> fleetId = const Value.absent(),
                Value<String?> routeId = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String> depotId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> startedOffline = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String?> fleetNumber = const Value.absent(),
                Value<String?> fleetRegistrationNumber = const Value.absent(),
                Value<String?> driverId = const Value.absent(),
                Value<String?> driverName = const Value.absent(),
                Value<String?> routeOrigin = const Value.absent(),
                Value<String?> routeDestination = const Value.absent(),
                Value<int?> startingMileage = const Value.absent(),
                Value<String?> waybillNo = const Value.absent(),
                Value<int?> closingMileage = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalTripsCompanion(
                id: id,
                agentId: agentId,
                fleetId: fleetId,
                routeId: routeId,
                deviceId: deviceId,
                depotId: depotId,
                status: status,
                startedOffline: startedOffline,
                startedAt: startedAt,
                endedAt: endedAt,
                fleetNumber: fleetNumber,
                fleetRegistrationNumber: fleetRegistrationNumber,
                driverId: driverId,
                driverName: driverName,
                routeOrigin: routeOrigin,
                routeDestination: routeDestination,
                startingMileage: startingMileage,
                waybillNo: waybillNo,
                closingMileage: closingMileage,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String agentId,
                required String fleetId,
                Value<String?> routeId = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                required String depotId,
                Value<String> status = const Value.absent(),
                Value<bool> startedOffline = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String?> fleetNumber = const Value.absent(),
                Value<String?> fleetRegistrationNumber = const Value.absent(),
                Value<String?> driverId = const Value.absent(),
                Value<String?> driverName = const Value.absent(),
                Value<String?> routeOrigin = const Value.absent(),
                Value<String?> routeDestination = const Value.absent(),
                Value<int?> startingMileage = const Value.absent(),
                Value<String?> waybillNo = const Value.absent(),
                Value<int?> closingMileage = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalTripsCompanion.insert(
                id: id,
                agentId: agentId,
                fleetId: fleetId,
                routeId: routeId,
                deviceId: deviceId,
                depotId: depotId,
                status: status,
                startedOffline: startedOffline,
                startedAt: startedAt,
                endedAt: endedAt,
                fleetNumber: fleetNumber,
                fleetRegistrationNumber: fleetRegistrationNumber,
                driverId: driverId,
                driverName: driverName,
                routeOrigin: routeOrigin,
                routeDestination: routeDestination,
                startingMileage: startingMileage,
                waybillNo: waybillNo,
                closingMileage: closingMileage,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalTripsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalTripsTable,
      LocalTrip,
      $$LocalTripsTableFilterComposer,
      $$LocalTripsTableOrderingComposer,
      $$LocalTripsTableAnnotationComposer,
      $$LocalTripsTableCreateCompanionBuilder,
      $$LocalTripsTableUpdateCompanionBuilder,
      (LocalTrip, BaseReferences<_$AppDatabase, $LocalTripsTable, LocalTrip>),
      LocalTrip,
      PrefetchHooks Function()
    >;
typedef $$LocalTicketsTableCreateCompanionBuilder =
    LocalTicketsCompanion Function({
      required String id,
      required String tripId,
      required String agentId,
      Value<String?> deviceId,
      required String depotId,
      required String ticketCategory,
      required String currency,
      required double amount,
      Value<String?> departure,
      Value<String?> destination,
      Value<String?> passengerName,
      Value<String?> passengerPhone,
      Value<double?> luggageAmount,
      Value<String?> luggageDescription,
      Value<int?> serialNumber,
      required DateTime issuedAt,
      Value<bool> printed,
      Value<DateTime?> printedAt,
      Value<String> syncStatus,
      required String idempotencyKey,
      Value<String?> lastError,
      Value<int> retryCount,
      Value<int> rowid,
    });
typedef $$LocalTicketsTableUpdateCompanionBuilder =
    LocalTicketsCompanion Function({
      Value<String> id,
      Value<String> tripId,
      Value<String> agentId,
      Value<String?> deviceId,
      Value<String> depotId,
      Value<String> ticketCategory,
      Value<String> currency,
      Value<double> amount,
      Value<String?> departure,
      Value<String?> destination,
      Value<String?> passengerName,
      Value<String?> passengerPhone,
      Value<double?> luggageAmount,
      Value<String?> luggageDescription,
      Value<int?> serialNumber,
      Value<DateTime> issuedAt,
      Value<bool> printed,
      Value<DateTime?> printedAt,
      Value<String> syncStatus,
      Value<String> idempotencyKey,
      Value<String?> lastError,
      Value<int> retryCount,
      Value<int> rowid,
    });

class $$LocalTicketsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalTicketsTable> {
  $$LocalTicketsTableFilterComposer({
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

  ColumnFilters<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agentId => $composableBuilder(
    column: $table.agentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get depotId => $composableBuilder(
    column: $table.depotId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ticketCategory => $composableBuilder(
    column: $table.ticketCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get departure => $composableBuilder(
    column: $table.departure,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passengerName => $composableBuilder(
    column: $table.passengerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passengerPhone => $composableBuilder(
    column: $table.passengerPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get luggageAmount => $composableBuilder(
    column: $table.luggageAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get luggageDescription => $composableBuilder(
    column: $table.luggageDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get issuedAt => $composableBuilder(
    column: $table.issuedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get printed => $composableBuilder(
    column: $table.printed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get printedAt => $composableBuilder(
    column: $table.printedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalTicketsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalTicketsTable> {
  $$LocalTicketsTableOrderingComposer({
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

  ColumnOrderings<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agentId => $composableBuilder(
    column: $table.agentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get depotId => $composableBuilder(
    column: $table.depotId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ticketCategory => $composableBuilder(
    column: $table.ticketCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get departure => $composableBuilder(
    column: $table.departure,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passengerName => $composableBuilder(
    column: $table.passengerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passengerPhone => $composableBuilder(
    column: $table.passengerPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get luggageAmount => $composableBuilder(
    column: $table.luggageAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get luggageDescription => $composableBuilder(
    column: $table.luggageDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get issuedAt => $composableBuilder(
    column: $table.issuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get printed => $composableBuilder(
    column: $table.printed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get printedAt => $composableBuilder(
    column: $table.printedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalTicketsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalTicketsTable> {
  $$LocalTicketsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tripId =>
      $composableBuilder(column: $table.tripId, builder: (column) => column);

  GeneratedColumn<String> get agentId =>
      $composableBuilder(column: $table.agentId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get depotId =>
      $composableBuilder(column: $table.depotId, builder: (column) => column);

  GeneratedColumn<String> get ticketCategory => $composableBuilder(
    column: $table.ticketCategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get departure =>
      $composableBuilder(column: $table.departure, builder: (column) => column);

  GeneratedColumn<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => column,
  );

  GeneratedColumn<String> get passengerName => $composableBuilder(
    column: $table.passengerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get passengerPhone => $composableBuilder(
    column: $table.passengerPhone,
    builder: (column) => column,
  );

  GeneratedColumn<double> get luggageAmount => $composableBuilder(
    column: $table.luggageAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get luggageDescription => $composableBuilder(
    column: $table.luggageDescription,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get issuedAt =>
      $composableBuilder(column: $table.issuedAt, builder: (column) => column);

  GeneratedColumn<bool> get printed =>
      $composableBuilder(column: $table.printed, builder: (column) => column);

  GeneratedColumn<DateTime> get printedAt =>
      $composableBuilder(column: $table.printedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );
}

class $$LocalTicketsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalTicketsTable,
          LocalTicket,
          $$LocalTicketsTableFilterComposer,
          $$LocalTicketsTableOrderingComposer,
          $$LocalTicketsTableAnnotationComposer,
          $$LocalTicketsTableCreateCompanionBuilder,
          $$LocalTicketsTableUpdateCompanionBuilder,
          (
            LocalTicket,
            BaseReferences<_$AppDatabase, $LocalTicketsTable, LocalTicket>,
          ),
          LocalTicket,
          PrefetchHooks Function()
        > {
  $$LocalTicketsTableTableManager(_$AppDatabase db, $LocalTicketsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTicketsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTicketsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalTicketsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tripId = const Value.absent(),
                Value<String> agentId = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String> depotId = const Value.absent(),
                Value<String> ticketCategory = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String?> departure = const Value.absent(),
                Value<String?> destination = const Value.absent(),
                Value<String?> passengerName = const Value.absent(),
                Value<String?> passengerPhone = const Value.absent(),
                Value<double?> luggageAmount = const Value.absent(),
                Value<String?> luggageDescription = const Value.absent(),
                Value<int?> serialNumber = const Value.absent(),
                Value<DateTime> issuedAt = const Value.absent(),
                Value<bool> printed = const Value.absent(),
                Value<DateTime?> printedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalTicketsCompanion(
                id: id,
                tripId: tripId,
                agentId: agentId,
                deviceId: deviceId,
                depotId: depotId,
                ticketCategory: ticketCategory,
                currency: currency,
                amount: amount,
                departure: departure,
                destination: destination,
                passengerName: passengerName,
                passengerPhone: passengerPhone,
                luggageAmount: luggageAmount,
                luggageDescription: luggageDescription,
                serialNumber: serialNumber,
                issuedAt: issuedAt,
                printed: printed,
                printedAt: printedAt,
                syncStatus: syncStatus,
                idempotencyKey: idempotencyKey,
                lastError: lastError,
                retryCount: retryCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tripId,
                required String agentId,
                Value<String?> deviceId = const Value.absent(),
                required String depotId,
                required String ticketCategory,
                required String currency,
                required double amount,
                Value<String?> departure = const Value.absent(),
                Value<String?> destination = const Value.absent(),
                Value<String?> passengerName = const Value.absent(),
                Value<String?> passengerPhone = const Value.absent(),
                Value<double?> luggageAmount = const Value.absent(),
                Value<String?> luggageDescription = const Value.absent(),
                Value<int?> serialNumber = const Value.absent(),
                required DateTime issuedAt,
                Value<bool> printed = const Value.absent(),
                Value<DateTime?> printedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                required String idempotencyKey,
                Value<String?> lastError = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalTicketsCompanion.insert(
                id: id,
                tripId: tripId,
                agentId: agentId,
                deviceId: deviceId,
                depotId: depotId,
                ticketCategory: ticketCategory,
                currency: currency,
                amount: amount,
                departure: departure,
                destination: destination,
                passengerName: passengerName,
                passengerPhone: passengerPhone,
                luggageAmount: luggageAmount,
                luggageDescription: luggageDescription,
                serialNumber: serialNumber,
                issuedAt: issuedAt,
                printed: printed,
                printedAt: printedAt,
                syncStatus: syncStatus,
                idempotencyKey: idempotencyKey,
                lastError: lastError,
                retryCount: retryCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalTicketsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalTicketsTable,
      LocalTicket,
      $$LocalTicketsTableFilterComposer,
      $$LocalTicketsTableOrderingComposer,
      $$LocalTicketsTableAnnotationComposer,
      $$LocalTicketsTableCreateCompanionBuilder,
      $$LocalTicketsTableUpdateCompanionBuilder,
      (
        LocalTicket,
        BaseReferences<_$AppDatabase, $LocalTicketsTable, LocalTicket>,
      ),
      LocalTicket,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueItemsTableCreateCompanionBuilder =
    SyncQueueItemsCompanion Function({
      Value<int> id,
      required String entityType,
      required String entityId,
      required String operation,
      required String payloadJson,
      Value<String> status,
      Value<int> retryCount,
      Value<String?> lastError,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$SyncQueueItemsTableUpdateCompanionBuilder =
    SyncQueueItemsCompanion Function({
      Value<int> id,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> operation,
      Value<String> payloadJson,
      Value<String> status,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$SyncQueueItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueItemsTable> {
  $$SyncQueueItemsTableFilterComposer({
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

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueItemsTable> {
  $$SyncQueueItemsTableOrderingComposer({
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

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueItemsTable> {
  $$SyncQueueItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncQueueItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueItemsTable,
          SyncQueueItem,
          $$SyncQueueItemsTableFilterComposer,
          $$SyncQueueItemsTableOrderingComposer,
          $$SyncQueueItemsTableAnnotationComposer,
          $$SyncQueueItemsTableCreateCompanionBuilder,
          $$SyncQueueItemsTableUpdateCompanionBuilder,
          (
            SyncQueueItem,
            BaseReferences<_$AppDatabase, $SyncQueueItemsTable, SyncQueueItem>,
          ),
          SyncQueueItem,
          PrefetchHooks Function()
        > {
  $$SyncQueueItemsTableTableManager(
    _$AppDatabase db,
    $SyncQueueItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SyncQueueItemsCompanion(
                id: id,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                payloadJson: payloadJson,
                status: status,
                retryCount: retryCount,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entityType,
                required String entityId,
                required String operation,
                required String payloadJson,
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => SyncQueueItemsCompanion.insert(
                id: id,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                payloadJson: payloadJson,
                status: status,
                retryCount: retryCount,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueItemsTable,
      SyncQueueItem,
      $$SyncQueueItemsTableFilterComposer,
      $$SyncQueueItemsTableOrderingComposer,
      $$SyncQueueItemsTableAnnotationComposer,
      $$SyncQueueItemsTableCreateCompanionBuilder,
      $$SyncQueueItemsTableUpdateCompanionBuilder,
      (
        SyncQueueItem,
        BaseReferences<_$AppDatabase, $SyncQueueItemsTable, SyncQueueItem>,
      ),
      SyncQueueItem,
      PrefetchHooks Function()
    >;
typedef $$SyncMetadataTableCreateCompanionBuilder =
    SyncMetadataCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SyncMetadataTableUpdateCompanionBuilder =
    SyncMetadataCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SyncMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableFilterComposer({
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

class $$SyncMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableOrderingComposer({
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

class $$SyncMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableAnnotationComposer({
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

class $$SyncMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMetadataTable,
          SyncMetadataData,
          $$SyncMetadataTableFilterComposer,
          $$SyncMetadataTableOrderingComposer,
          $$SyncMetadataTableAnnotationComposer,
          $$SyncMetadataTableCreateCompanionBuilder,
          $$SyncMetadataTableUpdateCompanionBuilder,
          (
            SyncMetadataData,
            BaseReferences<_$AppDatabase, $SyncMetadataTable, SyncMetadataData>,
          ),
          SyncMetadataData,
          PrefetchHooks Function()
        > {
  $$SyncMetadataTableTableManager(_$AppDatabase db, $SyncMetadataTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMetadataTable,
      SyncMetadataData,
      $$SyncMetadataTableFilterComposer,
      $$SyncMetadataTableOrderingComposer,
      $$SyncMetadataTableAnnotationComposer,
      $$SyncMetadataTableCreateCompanionBuilder,
      $$SyncMetadataTableUpdateCompanionBuilder,
      (
        SyncMetadataData,
        BaseReferences<_$AppDatabase, $SyncMetadataTable, SyncMetadataData>,
      ),
      SyncMetadataData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedFleetsTableTableManager get cachedFleets =>
      $$CachedFleetsTableTableManager(_db, _db.cachedFleets);
  $$CachedDriversTableTableManager get cachedDrivers =>
      $$CachedDriversTableTableManager(_db, _db.cachedDrivers);
  $$CachedRoutesTableTableManager get cachedRoutes =>
      $$CachedRoutesTableTableManager(_db, _db.cachedRoutes);
  $$CachedFaresTableTableManager get cachedFares =>
      $$CachedFaresTableTableManager(_db, _db.cachedFares);
  $$LocalTripsTableTableManager get localTrips =>
      $$LocalTripsTableTableManager(_db, _db.localTrips);
  $$LocalTicketsTableTableManager get localTickets =>
      $$LocalTicketsTableTableManager(_db, _db.localTickets);
  $$SyncQueueItemsTableTableManager get syncQueueItems =>
      $$SyncQueueItemsTableTableManager(_db, _db.syncQueueItems);
  $$SyncMetadataTableTableManager get syncMetadata =>
      $$SyncMetadataTableTableManager(_db, _db.syncMetadata);
}
