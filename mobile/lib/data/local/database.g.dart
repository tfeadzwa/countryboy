// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DevicesTable extends Devices with TableInfo<$DevicesTable, Device> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DevicesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _deviceTokenMeta = const VerificationMeta(
    'deviceToken',
  );
  @override
  late final GeneratedColumn<String> deviceToken = GeneratedColumn<String>(
    'device_token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _merchantCodeMeta = const VerificationMeta(
    'merchantCode',
  );
  @override
  late final GeneratedColumn<String> merchantCode = GeneratedColumn<String>(
    'merchant_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceNameMeta = const VerificationMeta(
    'deviceName',
  );
  @override
  late final GeneratedColumn<String> deviceName = GeneratedColumn<String>(
    'device_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceModelMeta = const VerificationMeta(
    'deviceModel',
  );
  @override
  late final GeneratedColumn<String> deviceModel = GeneratedColumn<String>(
    'device_model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pairedAtMeta = const VerificationMeta(
    'pairedAt',
  );
  @override
  late final GeneratedColumn<DateTime> pairedAt = GeneratedColumn<DateTime>(
    'paired_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deviceToken,
    merchantCode,
    deviceName,
    deviceModel,
    pairedAt,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<Device> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('device_token')) {
      context.handle(
        _deviceTokenMeta,
        deviceToken.isAcceptableOrUnknown(
          data['device_token']!,
          _deviceTokenMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deviceTokenMeta);
    }
    if (data.containsKey('merchant_code')) {
      context.handle(
        _merchantCodeMeta,
        merchantCode.isAcceptableOrUnknown(
          data['merchant_code']!,
          _merchantCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_merchantCodeMeta);
    }
    if (data.containsKey('device_name')) {
      context.handle(
        _deviceNameMeta,
        deviceName.isAcceptableOrUnknown(data['device_name']!, _deviceNameMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceNameMeta);
    }
    if (data.containsKey('device_model')) {
      context.handle(
        _deviceModelMeta,
        deviceModel.isAcceptableOrUnknown(
          data['device_model']!,
          _deviceModelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deviceModelMeta);
    }
    if (data.containsKey('paired_at')) {
      context.handle(
        _pairedAtMeta,
        pairedAt.isAcceptableOrUnknown(data['paired_at']!, _pairedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_pairedAtMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Device map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Device(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deviceToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_token'],
      )!,
      merchantCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant_code'],
      )!,
      deviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_name'],
      )!,
      deviceModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_model'],
      )!,
      pairedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paired_at'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $DevicesTable createAlias(String alias) {
    return $DevicesTable(attachedDatabase, alias);
  }
}

class Device extends DataClass implements Insertable<Device> {
  final int id;
  final String deviceToken;
  final String merchantCode;
  final String deviceName;
  final String deviceModel;
  final DateTime pairedAt;
  final bool isActive;
  const Device({
    required this.id,
    required this.deviceToken,
    required this.merchantCode,
    required this.deviceName,
    required this.deviceModel,
    required this.pairedAt,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['device_token'] = Variable<String>(deviceToken);
    map['merchant_code'] = Variable<String>(merchantCode);
    map['device_name'] = Variable<String>(deviceName);
    map['device_model'] = Variable<String>(deviceModel);
    map['paired_at'] = Variable<DateTime>(pairedAt);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  DevicesCompanion toCompanion(bool nullToAbsent) {
    return DevicesCompanion(
      id: Value(id),
      deviceToken: Value(deviceToken),
      merchantCode: Value(merchantCode),
      deviceName: Value(deviceName),
      deviceModel: Value(deviceModel),
      pairedAt: Value(pairedAt),
      isActive: Value(isActive),
    );
  }

  factory Device.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Device(
      id: serializer.fromJson<int>(json['id']),
      deviceToken: serializer.fromJson<String>(json['deviceToken']),
      merchantCode: serializer.fromJson<String>(json['merchantCode']),
      deviceName: serializer.fromJson<String>(json['deviceName']),
      deviceModel: serializer.fromJson<String>(json['deviceModel']),
      pairedAt: serializer.fromJson<DateTime>(json['pairedAt']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deviceToken': serializer.toJson<String>(deviceToken),
      'merchantCode': serializer.toJson<String>(merchantCode),
      'deviceName': serializer.toJson<String>(deviceName),
      'deviceModel': serializer.toJson<String>(deviceModel),
      'pairedAt': serializer.toJson<DateTime>(pairedAt),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  Device copyWith({
    int? id,
    String? deviceToken,
    String? merchantCode,
    String? deviceName,
    String? deviceModel,
    DateTime? pairedAt,
    bool? isActive,
  }) => Device(
    id: id ?? this.id,
    deviceToken: deviceToken ?? this.deviceToken,
    merchantCode: merchantCode ?? this.merchantCode,
    deviceName: deviceName ?? this.deviceName,
    deviceModel: deviceModel ?? this.deviceModel,
    pairedAt: pairedAt ?? this.pairedAt,
    isActive: isActive ?? this.isActive,
  );
  Device copyWithCompanion(DevicesCompanion data) {
    return Device(
      id: data.id.present ? data.id.value : this.id,
      deviceToken: data.deviceToken.present
          ? data.deviceToken.value
          : this.deviceToken,
      merchantCode: data.merchantCode.present
          ? data.merchantCode.value
          : this.merchantCode,
      deviceName: data.deviceName.present
          ? data.deviceName.value
          : this.deviceName,
      deviceModel: data.deviceModel.present
          ? data.deviceModel.value
          : this.deviceModel,
      pairedAt: data.pairedAt.present ? data.pairedAt.value : this.pairedAt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Device(')
          ..write('id: $id, ')
          ..write('deviceToken: $deviceToken, ')
          ..write('merchantCode: $merchantCode, ')
          ..write('deviceName: $deviceName, ')
          ..write('deviceModel: $deviceModel, ')
          ..write('pairedAt: $pairedAt, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    deviceToken,
    merchantCode,
    deviceName,
    deviceModel,
    pairedAt,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Device &&
          other.id == this.id &&
          other.deviceToken == this.deviceToken &&
          other.merchantCode == this.merchantCode &&
          other.deviceName == this.deviceName &&
          other.deviceModel == this.deviceModel &&
          other.pairedAt == this.pairedAt &&
          other.isActive == this.isActive);
}

class DevicesCompanion extends UpdateCompanion<Device> {
  final Value<int> id;
  final Value<String> deviceToken;
  final Value<String> merchantCode;
  final Value<String> deviceName;
  final Value<String> deviceModel;
  final Value<DateTime> pairedAt;
  final Value<bool> isActive;
  const DevicesCompanion({
    this.id = const Value.absent(),
    this.deviceToken = const Value.absent(),
    this.merchantCode = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.deviceModel = const Value.absent(),
    this.pairedAt = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  DevicesCompanion.insert({
    this.id = const Value.absent(),
    required String deviceToken,
    required String merchantCode,
    required String deviceName,
    required String deviceModel,
    required DateTime pairedAt,
    this.isActive = const Value.absent(),
  }) : deviceToken = Value(deviceToken),
       merchantCode = Value(merchantCode),
       deviceName = Value(deviceName),
       deviceModel = Value(deviceModel),
       pairedAt = Value(pairedAt);
  static Insertable<Device> custom({
    Expression<int>? id,
    Expression<String>? deviceToken,
    Expression<String>? merchantCode,
    Expression<String>? deviceName,
    Expression<String>? deviceModel,
    Expression<DateTime>? pairedAt,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceToken != null) 'device_token': deviceToken,
      if (merchantCode != null) 'merchant_code': merchantCode,
      if (deviceName != null) 'device_name': deviceName,
      if (deviceModel != null) 'device_model': deviceModel,
      if (pairedAt != null) 'paired_at': pairedAt,
      if (isActive != null) 'is_active': isActive,
    });
  }

  DevicesCompanion copyWith({
    Value<int>? id,
    Value<String>? deviceToken,
    Value<String>? merchantCode,
    Value<String>? deviceName,
    Value<String>? deviceModel,
    Value<DateTime>? pairedAt,
    Value<bool>? isActive,
  }) {
    return DevicesCompanion(
      id: id ?? this.id,
      deviceToken: deviceToken ?? this.deviceToken,
      merchantCode: merchantCode ?? this.merchantCode,
      deviceName: deviceName ?? this.deviceName,
      deviceModel: deviceModel ?? this.deviceModel,
      pairedAt: pairedAt ?? this.pairedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deviceToken.present) {
      map['device_token'] = Variable<String>(deviceToken.value);
    }
    if (merchantCode.present) {
      map['merchant_code'] = Variable<String>(merchantCode.value);
    }
    if (deviceName.present) {
      map['device_name'] = Variable<String>(deviceName.value);
    }
    if (deviceModel.present) {
      map['device_model'] = Variable<String>(deviceModel.value);
    }
    if (pairedAt.present) {
      map['paired_at'] = Variable<DateTime>(pairedAt.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DevicesCompanion(')
          ..write('id: $id, ')
          ..write('deviceToken: $deviceToken, ')
          ..write('merchantCode: $merchantCode, ')
          ..write('deviceName: $deviceName, ')
          ..write('deviceModel: $deviceModel, ')
          ..write('pairedAt: $pairedAt, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $AgentsTable extends Agents with TableInfo<$AgentsTable, Agent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AgentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _agentCodeMeta = const VerificationMeta(
    'agentCode',
  );
  @override
  late final GeneratedColumn<String> agentCode = GeneratedColumn<String>(
    'agent_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _firstNameMeta = const VerificationMeta(
    'firstName',
  );
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
    'first_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastNameMeta = const VerificationMeta(
    'lastName',
  );
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
    'last_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _merchantCodeMeta = const VerificationMeta(
    'merchantCode',
  );
  @override
  late final GeneratedColumn<String> merchantCode = GeneratedColumn<String>(
    'merchant_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _merchantNameMeta = const VerificationMeta(
    'merchantName',
  );
  @override
  late final GeneratedColumn<String> merchantName = GeneratedColumn<String>(
    'merchant_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _depotCodeMeta = const VerificationMeta(
    'depotCode',
  );
  @override
  late final GeneratedColumn<String> depotCode = GeneratedColumn<String>(
    'depot_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _depotNameMeta = const VerificationMeta(
    'depotName',
  );
  @override
  late final GeneratedColumn<String> depotName = GeneratedColumn<String>(
    'depot_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastLoginMeta = const VerificationMeta(
    'lastLogin',
  );
  @override
  late final GeneratedColumn<DateTime> lastLogin = GeneratedColumn<DateTime>(
    'last_login',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
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
    agentCode,
    firstName,
    lastName,
    role,
    merchantCode,
    merchantName,
    depotCode,
    depotName,
    lastLogin,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agents';
  @override
  VerificationContext validateIntegrity(
    Insertable<Agent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('agent_code')) {
      context.handle(
        _agentCodeMeta,
        agentCode.isAcceptableOrUnknown(data['agent_code']!, _agentCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_agentCodeMeta);
    }
    if (data.containsKey('first_name')) {
      context.handle(
        _firstNameMeta,
        firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta),
      );
    } else if (isInserting) {
      context.missing(_firstNameMeta);
    }
    if (data.containsKey('last_name')) {
      context.handle(
        _lastNameMeta,
        lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta),
      );
    } else if (isInserting) {
      context.missing(_lastNameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('merchant_code')) {
      context.handle(
        _merchantCodeMeta,
        merchantCode.isAcceptableOrUnknown(
          data['merchant_code']!,
          _merchantCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_merchantCodeMeta);
    }
    if (data.containsKey('merchant_name')) {
      context.handle(
        _merchantNameMeta,
        merchantName.isAcceptableOrUnknown(
          data['merchant_name']!,
          _merchantNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_merchantNameMeta);
    }
    if (data.containsKey('depot_code')) {
      context.handle(
        _depotCodeMeta,
        depotCode.isAcceptableOrUnknown(data['depot_code']!, _depotCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_depotCodeMeta);
    }
    if (data.containsKey('depot_name')) {
      context.handle(
        _depotNameMeta,
        depotName.isAcceptableOrUnknown(data['depot_name']!, _depotNameMeta),
      );
    } else if (isInserting) {
      context.missing(_depotNameMeta);
    }
    if (data.containsKey('last_login')) {
      context.handle(
        _lastLoginMeta,
        lastLogin.isAcceptableOrUnknown(data['last_login']!, _lastLoginMeta),
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
  Agent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Agent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      agentCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_code'],
      )!,
      firstName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_name'],
      )!,
      lastName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      merchantCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant_code'],
      )!,
      merchantName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant_name'],
      )!,
      depotCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}depot_code'],
      )!,
      depotName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}depot_name'],
      )!,
      lastLogin: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_login'],
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
  $AgentsTable createAlias(String alias) {
    return $AgentsTable(attachedDatabase, alias);
  }
}

class Agent extends DataClass implements Insertable<Agent> {
  final int id;
  final String agentCode;
  final String firstName;
  final String lastName;
  final String role;
  final String merchantCode;
  final String merchantName;
  final String depotCode;
  final String depotName;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Agent({
    required this.id,
    required this.agentCode,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.merchantCode,
    required this.merchantName,
    required this.depotCode,
    required this.depotName,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['agent_code'] = Variable<String>(agentCode);
    map['first_name'] = Variable<String>(firstName);
    map['last_name'] = Variable<String>(lastName);
    map['role'] = Variable<String>(role);
    map['merchant_code'] = Variable<String>(merchantCode);
    map['merchant_name'] = Variable<String>(merchantName);
    map['depot_code'] = Variable<String>(depotCode);
    map['depot_name'] = Variable<String>(depotName);
    if (!nullToAbsent || lastLogin != null) {
      map['last_login'] = Variable<DateTime>(lastLogin);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AgentsCompanion toCompanion(bool nullToAbsent) {
    return AgentsCompanion(
      id: Value(id),
      agentCode: Value(agentCode),
      firstName: Value(firstName),
      lastName: Value(lastName),
      role: Value(role),
      merchantCode: Value(merchantCode),
      merchantName: Value(merchantName),
      depotCode: Value(depotCode),
      depotName: Value(depotName),
      lastLogin: lastLogin == null && nullToAbsent
          ? const Value.absent()
          : Value(lastLogin),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Agent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Agent(
      id: serializer.fromJson<int>(json['id']),
      agentCode: serializer.fromJson<String>(json['agentCode']),
      firstName: serializer.fromJson<String>(json['firstName']),
      lastName: serializer.fromJson<String>(json['lastName']),
      role: serializer.fromJson<String>(json['role']),
      merchantCode: serializer.fromJson<String>(json['merchantCode']),
      merchantName: serializer.fromJson<String>(json['merchantName']),
      depotCode: serializer.fromJson<String>(json['depotCode']),
      depotName: serializer.fromJson<String>(json['depotName']),
      lastLogin: serializer.fromJson<DateTime?>(json['lastLogin']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'agentCode': serializer.toJson<String>(agentCode),
      'firstName': serializer.toJson<String>(firstName),
      'lastName': serializer.toJson<String>(lastName),
      'role': serializer.toJson<String>(role),
      'merchantCode': serializer.toJson<String>(merchantCode),
      'merchantName': serializer.toJson<String>(merchantName),
      'depotCode': serializer.toJson<String>(depotCode),
      'depotName': serializer.toJson<String>(depotName),
      'lastLogin': serializer.toJson<DateTime?>(lastLogin),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Agent copyWith({
    int? id,
    String? agentCode,
    String? firstName,
    String? lastName,
    String? role,
    String? merchantCode,
    String? merchantName,
    String? depotCode,
    String? depotName,
    Value<DateTime?> lastLogin = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Agent(
    id: id ?? this.id,
    agentCode: agentCode ?? this.agentCode,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    role: role ?? this.role,
    merchantCode: merchantCode ?? this.merchantCode,
    merchantName: merchantName ?? this.merchantName,
    depotCode: depotCode ?? this.depotCode,
    depotName: depotName ?? this.depotName,
    lastLogin: lastLogin.present ? lastLogin.value : this.lastLogin,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Agent copyWithCompanion(AgentsCompanion data) {
    return Agent(
      id: data.id.present ? data.id.value : this.id,
      agentCode: data.agentCode.present ? data.agentCode.value : this.agentCode,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      role: data.role.present ? data.role.value : this.role,
      merchantCode: data.merchantCode.present
          ? data.merchantCode.value
          : this.merchantCode,
      merchantName: data.merchantName.present
          ? data.merchantName.value
          : this.merchantName,
      depotCode: data.depotCode.present ? data.depotCode.value : this.depotCode,
      depotName: data.depotName.present ? data.depotName.value : this.depotName,
      lastLogin: data.lastLogin.present ? data.lastLogin.value : this.lastLogin,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Agent(')
          ..write('id: $id, ')
          ..write('agentCode: $agentCode, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('role: $role, ')
          ..write('merchantCode: $merchantCode, ')
          ..write('merchantName: $merchantName, ')
          ..write('depotCode: $depotCode, ')
          ..write('depotName: $depotName, ')
          ..write('lastLogin: $lastLogin, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    agentCode,
    firstName,
    lastName,
    role,
    merchantCode,
    merchantName,
    depotCode,
    depotName,
    lastLogin,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Agent &&
          other.id == this.id &&
          other.agentCode == this.agentCode &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.role == this.role &&
          other.merchantCode == this.merchantCode &&
          other.merchantName == this.merchantName &&
          other.depotCode == this.depotCode &&
          other.depotName == this.depotName &&
          other.lastLogin == this.lastLogin &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AgentsCompanion extends UpdateCompanion<Agent> {
  final Value<int> id;
  final Value<String> agentCode;
  final Value<String> firstName;
  final Value<String> lastName;
  final Value<String> role;
  final Value<String> merchantCode;
  final Value<String> merchantName;
  final Value<String> depotCode;
  final Value<String> depotName;
  final Value<DateTime?> lastLogin;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const AgentsCompanion({
    this.id = const Value.absent(),
    this.agentCode = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.role = const Value.absent(),
    this.merchantCode = const Value.absent(),
    this.merchantName = const Value.absent(),
    this.depotCode = const Value.absent(),
    this.depotName = const Value.absent(),
    this.lastLogin = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AgentsCompanion.insert({
    this.id = const Value.absent(),
    required String agentCode,
    required String firstName,
    required String lastName,
    required String role,
    required String merchantCode,
    required String merchantName,
    required String depotCode,
    required String depotName,
    this.lastLogin = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : agentCode = Value(agentCode),
       firstName = Value(firstName),
       lastName = Value(lastName),
       role = Value(role),
       merchantCode = Value(merchantCode),
       merchantName = Value(merchantName),
       depotCode = Value(depotCode),
       depotName = Value(depotName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Agent> custom({
    Expression<int>? id,
    Expression<String>? agentCode,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<String>? role,
    Expression<String>? merchantCode,
    Expression<String>? merchantName,
    Expression<String>? depotCode,
    Expression<String>? depotName,
    Expression<DateTime>? lastLogin,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (agentCode != null) 'agent_code': agentCode,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (role != null) 'role': role,
      if (merchantCode != null) 'merchant_code': merchantCode,
      if (merchantName != null) 'merchant_name': merchantName,
      if (depotCode != null) 'depot_code': depotCode,
      if (depotName != null) 'depot_name': depotName,
      if (lastLogin != null) 'last_login': lastLogin,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AgentsCompanion copyWith({
    Value<int>? id,
    Value<String>? agentCode,
    Value<String>? firstName,
    Value<String>? lastName,
    Value<String>? role,
    Value<String>? merchantCode,
    Value<String>? merchantName,
    Value<String>? depotCode,
    Value<String>? depotName,
    Value<DateTime?>? lastLogin,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return AgentsCompanion(
      id: id ?? this.id,
      agentCode: agentCode ?? this.agentCode,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      merchantCode: merchantCode ?? this.merchantCode,
      merchantName: merchantName ?? this.merchantName,
      depotCode: depotCode ?? this.depotCode,
      depotName: depotName ?? this.depotName,
      lastLogin: lastLogin ?? this.lastLogin,
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
    if (agentCode.present) {
      map['agent_code'] = Variable<String>(agentCode.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (merchantCode.present) {
      map['merchant_code'] = Variable<String>(merchantCode.value);
    }
    if (merchantName.present) {
      map['merchant_name'] = Variable<String>(merchantName.value);
    }
    if (depotCode.present) {
      map['depot_code'] = Variable<String>(depotCode.value);
    }
    if (depotName.present) {
      map['depot_name'] = Variable<String>(depotName.value);
    }
    if (lastLogin.present) {
      map['last_login'] = Variable<DateTime>(lastLogin.value);
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
    return (StringBuffer('AgentsCompanion(')
          ..write('id: $id, ')
          ..write('agentCode: $agentCode, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('role: $role, ')
          ..write('merchantCode: $merchantCode, ')
          ..write('merchantName: $merchantName, ')
          ..write('depotCode: $depotCode, ')
          ..write('depotName: $depotName, ')
          ..write('lastLogin: $lastLogin, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $RoutesTable extends Routes with TableInfo<$RoutesTable, Route> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _routeCodeMeta = const VerificationMeta(
    'routeCode',
  );
  @override
  late final GeneratedColumn<String> routeCode = GeneratedColumn<String>(
    'route_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _routeNameMeta = const VerificationMeta(
    'routeName',
  );
  @override
  late final GeneratedColumn<String> routeName = GeneratedColumn<String>(
    'route_name',
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
  static const VerificationMeta _fareMeta = const VerificationMeta('fare');
  @override
  late final GeneratedColumn<double> fare = GeneratedColumn<double>(
    'fare',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceKmMeta = const VerificationMeta(
    'distanceKm',
  );
  @override
  late final GeneratedColumn<int> distanceKm = GeneratedColumn<int>(
    'distance_km',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
    serverId,
    routeCode,
    routeName,
    origin,
    destination,
    fare,
    distanceKm,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Route> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('route_code')) {
      context.handle(
        _routeCodeMeta,
        routeCode.isAcceptableOrUnknown(data['route_code']!, _routeCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_routeCodeMeta);
    }
    if (data.containsKey('route_name')) {
      context.handle(
        _routeNameMeta,
        routeName.isAcceptableOrUnknown(data['route_name']!, _routeNameMeta),
      );
    } else if (isInserting) {
      context.missing(_routeNameMeta);
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
    if (data.containsKey('fare')) {
      context.handle(
        _fareMeta,
        fare.isAcceptableOrUnknown(data['fare']!, _fareMeta),
      );
    } else if (isInserting) {
      context.missing(_fareMeta);
    }
    if (data.containsKey('distance_km')) {
      context.handle(
        _distanceKmMeta,
        distanceKm.isAcceptableOrUnknown(data['distance_km']!, _distanceKmMeta),
      );
    } else if (isInserting) {
      context.missing(_distanceKmMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
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
  Route map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Route(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      )!,
      routeCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_code'],
      )!,
      routeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_name'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      destination: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination'],
      )!,
      fare: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fare'],
      )!,
      distanceKm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}distance_km'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
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
  $RoutesTable createAlias(String alias) {
    return $RoutesTable(attachedDatabase, alias);
  }
}

class Route extends DataClass implements Insertable<Route> {
  final int id;
  final String serverId;
  final String routeCode;
  final String routeName;
  final String origin;
  final String destination;
  final double fare;
  final int distanceKm;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Route({
    required this.id,
    required this.serverId,
    required this.routeCode,
    required this.routeName,
    required this.origin,
    required this.destination,
    required this.fare,
    required this.distanceKm,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['server_id'] = Variable<String>(serverId);
    map['route_code'] = Variable<String>(routeCode);
    map['route_name'] = Variable<String>(routeName);
    map['origin'] = Variable<String>(origin);
    map['destination'] = Variable<String>(destination);
    map['fare'] = Variable<double>(fare);
    map['distance_km'] = Variable<int>(distanceKm);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RoutesCompanion toCompanion(bool nullToAbsent) {
    return RoutesCompanion(
      id: Value(id),
      serverId: Value(serverId),
      routeCode: Value(routeCode),
      routeName: Value(routeName),
      origin: Value(origin),
      destination: Value(destination),
      fare: Value(fare),
      distanceKm: Value(distanceKm),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Route.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Route(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String>(json['serverId']),
      routeCode: serializer.fromJson<String>(json['routeCode']),
      routeName: serializer.fromJson<String>(json['routeName']),
      origin: serializer.fromJson<String>(json['origin']),
      destination: serializer.fromJson<String>(json['destination']),
      fare: serializer.fromJson<double>(json['fare']),
      distanceKm: serializer.fromJson<int>(json['distanceKm']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String>(serverId),
      'routeCode': serializer.toJson<String>(routeCode),
      'routeName': serializer.toJson<String>(routeName),
      'origin': serializer.toJson<String>(origin),
      'destination': serializer.toJson<String>(destination),
      'fare': serializer.toJson<double>(fare),
      'distanceKm': serializer.toJson<int>(distanceKm),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Route copyWith({
    int? id,
    String? serverId,
    String? routeCode,
    String? routeName,
    String? origin,
    String? destination,
    double? fare,
    int? distanceKm,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Route(
    id: id ?? this.id,
    serverId: serverId ?? this.serverId,
    routeCode: routeCode ?? this.routeCode,
    routeName: routeName ?? this.routeName,
    origin: origin ?? this.origin,
    destination: destination ?? this.destination,
    fare: fare ?? this.fare,
    distanceKm: distanceKm ?? this.distanceKm,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Route copyWithCompanion(RoutesCompanion data) {
    return Route(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      routeCode: data.routeCode.present ? data.routeCode.value : this.routeCode,
      routeName: data.routeName.present ? data.routeName.value : this.routeName,
      origin: data.origin.present ? data.origin.value : this.origin,
      destination: data.destination.present
          ? data.destination.value
          : this.destination,
      fare: data.fare.present ? data.fare.value : this.fare,
      distanceKm: data.distanceKm.present
          ? data.distanceKm.value
          : this.distanceKm,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Route(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('routeCode: $routeCode, ')
          ..write('routeName: $routeName, ')
          ..write('origin: $origin, ')
          ..write('destination: $destination, ')
          ..write('fare: $fare, ')
          ..write('distanceKm: $distanceKm, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    routeCode,
    routeName,
    origin,
    destination,
    fare,
    distanceKm,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Route &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.routeCode == this.routeCode &&
          other.routeName == this.routeName &&
          other.origin == this.origin &&
          other.destination == this.destination &&
          other.fare == this.fare &&
          other.distanceKm == this.distanceKm &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RoutesCompanion extends UpdateCompanion<Route> {
  final Value<int> id;
  final Value<String> serverId;
  final Value<String> routeCode;
  final Value<String> routeName;
  final Value<String> origin;
  final Value<String> destination;
  final Value<double> fare;
  final Value<int> distanceKm;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const RoutesCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.routeCode = const Value.absent(),
    this.routeName = const Value.absent(),
    this.origin = const Value.absent(),
    this.destination = const Value.absent(),
    this.fare = const Value.absent(),
    this.distanceKm = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  RoutesCompanion.insert({
    this.id = const Value.absent(),
    required String serverId,
    required String routeCode,
    required String routeName,
    required String origin,
    required String destination,
    required double fare,
    required int distanceKm,
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : serverId = Value(serverId),
       routeCode = Value(routeCode),
       routeName = Value(routeName),
       origin = Value(origin),
       destination = Value(destination),
       fare = Value(fare),
       distanceKm = Value(distanceKm),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Route> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? routeCode,
    Expression<String>? routeName,
    Expression<String>? origin,
    Expression<String>? destination,
    Expression<double>? fare,
    Expression<int>? distanceKm,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (routeCode != null) 'route_code': routeCode,
      if (routeName != null) 'route_name': routeName,
      if (origin != null) 'origin': origin,
      if (destination != null) 'destination': destination,
      if (fare != null) 'fare': fare,
      if (distanceKm != null) 'distance_km': distanceKm,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  RoutesCompanion copyWith({
    Value<int>? id,
    Value<String>? serverId,
    Value<String>? routeCode,
    Value<String>? routeName,
    Value<String>? origin,
    Value<String>? destination,
    Value<double>? fare,
    Value<int>? distanceKm,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return RoutesCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      routeCode: routeCode ?? this.routeCode,
      routeName: routeName ?? this.routeName,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      fare: fare ?? this.fare,
      distanceKm: distanceKm ?? this.distanceKm,
      isActive: isActive ?? this.isActive,
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
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (routeCode.present) {
      map['route_code'] = Variable<String>(routeCode.value);
    }
    if (routeName.present) {
      map['route_name'] = Variable<String>(routeName.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (destination.present) {
      map['destination'] = Variable<String>(destination.value);
    }
    if (fare.present) {
      map['fare'] = Variable<double>(fare.value);
    }
    if (distanceKm.present) {
      map['distance_km'] = Variable<int>(distanceKm.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
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
    return (StringBuffer('RoutesCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('routeCode: $routeCode, ')
          ..write('routeName: $routeName, ')
          ..write('origin: $origin, ')
          ..write('destination: $destination, ')
          ..write('fare: $fare, ')
          ..write('distanceKm: $distanceKm, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $FleetsTable extends Fleets with TableInfo<$FleetsTable, Fleet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FleetsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
    serverId,
    number,
    depotId,
    isActive,
    cachedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fleets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Fleet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('depot_id')) {
      context.handle(
        _depotIdMeta,
        depotId.isAcceptableOrUnknown(data['depot_id']!, _depotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_depotIdMeta);
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
  Fleet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Fleet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}number'],
      )!,
      depotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}depot_id'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FleetsTable createAlias(String alias) {
    return $FleetsTable(attachedDatabase, alias);
  }
}

class Fleet extends DataClass implements Insertable<Fleet> {
  final int id;
  final String serverId;
  final String number;
  final String depotId;
  final bool isActive;
  final DateTime cachedAt;
  final DateTime updatedAt;
  const Fleet({
    required this.id,
    required this.serverId,
    required this.number,
    required this.depotId,
    required this.isActive,
    required this.cachedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['server_id'] = Variable<String>(serverId);
    map['number'] = Variable<String>(number);
    map['depot_id'] = Variable<String>(depotId);
    map['is_active'] = Variable<bool>(isActive);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FleetsCompanion toCompanion(bool nullToAbsent) {
    return FleetsCompanion(
      id: Value(id),
      serverId: Value(serverId),
      number: Value(number),
      depotId: Value(depotId),
      isActive: Value(isActive),
      cachedAt: Value(cachedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Fleet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Fleet(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String>(json['serverId']),
      number: serializer.fromJson<String>(json['number']),
      depotId: serializer.fromJson<String>(json['depotId']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String>(serverId),
      'number': serializer.toJson<String>(number),
      'depotId': serializer.toJson<String>(depotId),
      'isActive': serializer.toJson<bool>(isActive),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Fleet copyWith({
    int? id,
    String? serverId,
    String? number,
    String? depotId,
    bool? isActive,
    DateTime? cachedAt,
    DateTime? updatedAt,
  }) => Fleet(
    id: id ?? this.id,
    serverId: serverId ?? this.serverId,
    number: number ?? this.number,
    depotId: depotId ?? this.depotId,
    isActive: isActive ?? this.isActive,
    cachedAt: cachedAt ?? this.cachedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Fleet copyWithCompanion(FleetsCompanion data) {
    return Fleet(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      number: data.number.present ? data.number.value : this.number,
      depotId: data.depotId.present ? data.depotId.value : this.depotId,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Fleet(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('number: $number, ')
          ..write('depotId: $depotId, ')
          ..write('isActive: $isActive, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, serverId, number, depotId, isActive, cachedAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Fleet &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.number == this.number &&
          other.depotId == this.depotId &&
          other.isActive == this.isActive &&
          other.cachedAt == this.cachedAt &&
          other.updatedAt == this.updatedAt);
}

class FleetsCompanion extends UpdateCompanion<Fleet> {
  final Value<int> id;
  final Value<String> serverId;
  final Value<String> number;
  final Value<String> depotId;
  final Value<bool> isActive;
  final Value<DateTime> cachedAt;
  final Value<DateTime> updatedAt;
  const FleetsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.number = const Value.absent(),
    this.depotId = const Value.absent(),
    this.isActive = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  FleetsCompanion.insert({
    this.id = const Value.absent(),
    required String serverId,
    required String number,
    required String depotId,
    this.isActive = const Value.absent(),
    required DateTime cachedAt,
    required DateTime updatedAt,
  }) : serverId = Value(serverId),
       number = Value(number),
       depotId = Value(depotId),
       cachedAt = Value(cachedAt),
       updatedAt = Value(updatedAt);
  static Insertable<Fleet> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? number,
    Expression<String>? depotId,
    Expression<bool>? isActive,
    Expression<DateTime>? cachedAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (number != null) 'number': number,
      if (depotId != null) 'depot_id': depotId,
      if (isActive != null) 'is_active': isActive,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  FleetsCompanion copyWith({
    Value<int>? id,
    Value<String>? serverId,
    Value<String>? number,
    Value<String>? depotId,
    Value<bool>? isActive,
    Value<DateTime>? cachedAt,
    Value<DateTime>? updatedAt,
  }) {
    return FleetsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      number: number ?? this.number,
      depotId: depotId ?? this.depotId,
      isActive: isActive ?? this.isActive,
      cachedAt: cachedAt ?? this.cachedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (depotId.present) {
      map['depot_id'] = Variable<String>(depotId.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FleetsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('number: $number, ')
          ..write('depotId: $depotId, ')
          ..write('isActive: $isActive, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TripsTable extends Trips with TableInfo<$TripsTable, Trip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TripsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _tripCodeMeta = const VerificationMeta(
    'tripCode',
  );
  @override
  late final GeneratedColumn<String> tripCode = GeneratedColumn<String>(
    'trip_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
  static const VerificationMeta _busNumberMeta = const VerificationMeta(
    'busNumber',
  );
  @override
  late final GeneratedColumn<String> busNumber = GeneratedColumn<String>(
    'bus_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _driverNameMeta = const VerificationMeta(
    'driverName',
  );
  @override
  late final GeneratedColumn<String> driverName = GeneratedColumn<String>(
    'driver_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _departureTimeMeta = const VerificationMeta(
    'departureTime',
  );
  @override
  late final GeneratedColumn<DateTime> departureTime =
      GeneratedColumn<DateTime>(
        'departure_time',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _arrivalTimeMeta = const VerificationMeta(
    'arrivalTime',
  );
  @override
  late final GeneratedColumn<DateTime> arrivalTime = GeneratedColumn<DateTime>(
    'arrival_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalSeatsMeta = const VerificationMeta(
    'totalSeats',
  );
  @override
  late final GeneratedColumn<int> totalSeats = GeneratedColumn<int>(
    'total_seats',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _availableSeatsMeta = const VerificationMeta(
    'availableSeats',
  );
  @override
  late final GeneratedColumn<int> availableSeats = GeneratedColumn<int>(
    'available_seats',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _agentCodeMeta = const VerificationMeta(
    'agentCode',
  );
  @override
  late final GeneratedColumn<String> agentCode = GeneratedColumn<String>(
    'agent_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    serverId,
    localId,
    tripCode,
    routeId,
    fleetId,
    busNumber,
    driverName,
    departureTime,
    arrivalTime,
    status,
    totalSeats,
    availableSeats,
    agentId,
    agentCode,
    startedOffline,
    isSynced,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trips';
  @override
  VerificationContext validateIntegrity(
    Insertable<Trip> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('trip_code')) {
      context.handle(
        _tripCodeMeta,
        tripCode.isAcceptableOrUnknown(data['trip_code']!, _tripCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_tripCodeMeta);
    }
    if (data.containsKey('route_id')) {
      context.handle(
        _routeIdMeta,
        routeId.isAcceptableOrUnknown(data['route_id']!, _routeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_routeIdMeta);
    }
    if (data.containsKey('fleet_id')) {
      context.handle(
        _fleetIdMeta,
        fleetId.isAcceptableOrUnknown(data['fleet_id']!, _fleetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fleetIdMeta);
    }
    if (data.containsKey('bus_number')) {
      context.handle(
        _busNumberMeta,
        busNumber.isAcceptableOrUnknown(data['bus_number']!, _busNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_busNumberMeta);
    }
    if (data.containsKey('driver_name')) {
      context.handle(
        _driverNameMeta,
        driverName.isAcceptableOrUnknown(data['driver_name']!, _driverNameMeta),
      );
    } else if (isInserting) {
      context.missing(_driverNameMeta);
    }
    if (data.containsKey('departure_time')) {
      context.handle(
        _departureTimeMeta,
        departureTime.isAcceptableOrUnknown(
          data['departure_time']!,
          _departureTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_departureTimeMeta);
    }
    if (data.containsKey('arrival_time')) {
      context.handle(
        _arrivalTimeMeta,
        arrivalTime.isAcceptableOrUnknown(
          data['arrival_time']!,
          _arrivalTimeMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('total_seats')) {
      context.handle(
        _totalSeatsMeta,
        totalSeats.isAcceptableOrUnknown(data['total_seats']!, _totalSeatsMeta),
      );
    } else if (isInserting) {
      context.missing(_totalSeatsMeta);
    }
    if (data.containsKey('available_seats')) {
      context.handle(
        _availableSeatsMeta,
        availableSeats.isAcceptableOrUnknown(
          data['available_seats']!,
          _availableSeatsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_availableSeatsMeta);
    }
    if (data.containsKey('agent_id')) {
      context.handle(
        _agentIdMeta,
        agentId.isAcceptableOrUnknown(data['agent_id']!, _agentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_agentIdMeta);
    }
    if (data.containsKey('agent_code')) {
      context.handle(
        _agentCodeMeta,
        agentCode.isAcceptableOrUnknown(data['agent_code']!, _agentCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_agentCodeMeta);
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
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
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
  Trip map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Trip(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      tripCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_code'],
      )!,
      routeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_id'],
      )!,
      fleetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fleet_id'],
      )!,
      busNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bus_number'],
      )!,
      driverName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}driver_name'],
      )!,
      departureTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}departure_time'],
      )!,
      arrivalTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}arrival_time'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      totalSeats: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_seats'],
      )!,
      availableSeats: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}available_seats'],
      )!,
      agentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_id'],
      )!,
      agentCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_code'],
      )!,
      startedOffline: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}started_offline'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
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
  $TripsTable createAlias(String alias) {
    return $TripsTable(attachedDatabase, alias);
  }
}

class Trip extends DataClass implements Insertable<Trip> {
  final int id;
  final String? serverId;
  final String localId;
  final String tripCode;
  final String routeId;
  final String fleetId;
  final String busNumber;
  final String driverName;
  final DateTime departureTime;
  final DateTime? arrivalTime;
  final String status;
  final int totalSeats;
  final int availableSeats;
  final String agentId;
  final String agentCode;
  final bool startedOffline;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Trip({
    required this.id,
    this.serverId,
    required this.localId,
    required this.tripCode,
    required this.routeId,
    required this.fleetId,
    required this.busNumber,
    required this.driverName,
    required this.departureTime,
    this.arrivalTime,
    required this.status,
    required this.totalSeats,
    required this.availableSeats,
    required this.agentId,
    required this.agentCode,
    required this.startedOffline,
    required this.isSynced,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['local_id'] = Variable<String>(localId);
    map['trip_code'] = Variable<String>(tripCode);
    map['route_id'] = Variable<String>(routeId);
    map['fleet_id'] = Variable<String>(fleetId);
    map['bus_number'] = Variable<String>(busNumber);
    map['driver_name'] = Variable<String>(driverName);
    map['departure_time'] = Variable<DateTime>(departureTime);
    if (!nullToAbsent || arrivalTime != null) {
      map['arrival_time'] = Variable<DateTime>(arrivalTime);
    }
    map['status'] = Variable<String>(status);
    map['total_seats'] = Variable<int>(totalSeats);
    map['available_seats'] = Variable<int>(availableSeats);
    map['agent_id'] = Variable<String>(agentId);
    map['agent_code'] = Variable<String>(agentCode);
    map['started_offline'] = Variable<bool>(startedOffline);
    map['is_synced'] = Variable<bool>(isSynced);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TripsCompanion toCompanion(bool nullToAbsent) {
    return TripsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      localId: Value(localId),
      tripCode: Value(tripCode),
      routeId: Value(routeId),
      fleetId: Value(fleetId),
      busNumber: Value(busNumber),
      driverName: Value(driverName),
      departureTime: Value(departureTime),
      arrivalTime: arrivalTime == null && nullToAbsent
          ? const Value.absent()
          : Value(arrivalTime),
      status: Value(status),
      totalSeats: Value(totalSeats),
      availableSeats: Value(availableSeats),
      agentId: Value(agentId),
      agentCode: Value(agentCode),
      startedOffline: Value(startedOffline),
      isSynced: Value(isSynced),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Trip.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Trip(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      localId: serializer.fromJson<String>(json['localId']),
      tripCode: serializer.fromJson<String>(json['tripCode']),
      routeId: serializer.fromJson<String>(json['routeId']),
      fleetId: serializer.fromJson<String>(json['fleetId']),
      busNumber: serializer.fromJson<String>(json['busNumber']),
      driverName: serializer.fromJson<String>(json['driverName']),
      departureTime: serializer.fromJson<DateTime>(json['departureTime']),
      arrivalTime: serializer.fromJson<DateTime?>(json['arrivalTime']),
      status: serializer.fromJson<String>(json['status']),
      totalSeats: serializer.fromJson<int>(json['totalSeats']),
      availableSeats: serializer.fromJson<int>(json['availableSeats']),
      agentId: serializer.fromJson<String>(json['agentId']),
      agentCode: serializer.fromJson<String>(json['agentCode']),
      startedOffline: serializer.fromJson<bool>(json['startedOffline']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'localId': serializer.toJson<String>(localId),
      'tripCode': serializer.toJson<String>(tripCode),
      'routeId': serializer.toJson<String>(routeId),
      'fleetId': serializer.toJson<String>(fleetId),
      'busNumber': serializer.toJson<String>(busNumber),
      'driverName': serializer.toJson<String>(driverName),
      'departureTime': serializer.toJson<DateTime>(departureTime),
      'arrivalTime': serializer.toJson<DateTime?>(arrivalTime),
      'status': serializer.toJson<String>(status),
      'totalSeats': serializer.toJson<int>(totalSeats),
      'availableSeats': serializer.toJson<int>(availableSeats),
      'agentId': serializer.toJson<String>(agentId),
      'agentCode': serializer.toJson<String>(agentCode),
      'startedOffline': serializer.toJson<bool>(startedOffline),
      'isSynced': serializer.toJson<bool>(isSynced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Trip copyWith({
    int? id,
    Value<String?> serverId = const Value.absent(),
    String? localId,
    String? tripCode,
    String? routeId,
    String? fleetId,
    String? busNumber,
    String? driverName,
    DateTime? departureTime,
    Value<DateTime?> arrivalTime = const Value.absent(),
    String? status,
    int? totalSeats,
    int? availableSeats,
    String? agentId,
    String? agentCode,
    bool? startedOffline,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Trip(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    localId: localId ?? this.localId,
    tripCode: tripCode ?? this.tripCode,
    routeId: routeId ?? this.routeId,
    fleetId: fleetId ?? this.fleetId,
    busNumber: busNumber ?? this.busNumber,
    driverName: driverName ?? this.driverName,
    departureTime: departureTime ?? this.departureTime,
    arrivalTime: arrivalTime.present ? arrivalTime.value : this.arrivalTime,
    status: status ?? this.status,
    totalSeats: totalSeats ?? this.totalSeats,
    availableSeats: availableSeats ?? this.availableSeats,
    agentId: agentId ?? this.agentId,
    agentCode: agentCode ?? this.agentCode,
    startedOffline: startedOffline ?? this.startedOffline,
    isSynced: isSynced ?? this.isSynced,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Trip copyWithCompanion(TripsCompanion data) {
    return Trip(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      localId: data.localId.present ? data.localId.value : this.localId,
      tripCode: data.tripCode.present ? data.tripCode.value : this.tripCode,
      routeId: data.routeId.present ? data.routeId.value : this.routeId,
      fleetId: data.fleetId.present ? data.fleetId.value : this.fleetId,
      busNumber: data.busNumber.present ? data.busNumber.value : this.busNumber,
      driverName: data.driverName.present
          ? data.driverName.value
          : this.driverName,
      departureTime: data.departureTime.present
          ? data.departureTime.value
          : this.departureTime,
      arrivalTime: data.arrivalTime.present
          ? data.arrivalTime.value
          : this.arrivalTime,
      status: data.status.present ? data.status.value : this.status,
      totalSeats: data.totalSeats.present
          ? data.totalSeats.value
          : this.totalSeats,
      availableSeats: data.availableSeats.present
          ? data.availableSeats.value
          : this.availableSeats,
      agentId: data.agentId.present ? data.agentId.value : this.agentId,
      agentCode: data.agentCode.present ? data.agentCode.value : this.agentCode,
      startedOffline: data.startedOffline.present
          ? data.startedOffline.value
          : this.startedOffline,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Trip(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('localId: $localId, ')
          ..write('tripCode: $tripCode, ')
          ..write('routeId: $routeId, ')
          ..write('fleetId: $fleetId, ')
          ..write('busNumber: $busNumber, ')
          ..write('driverName: $driverName, ')
          ..write('departureTime: $departureTime, ')
          ..write('arrivalTime: $arrivalTime, ')
          ..write('status: $status, ')
          ..write('totalSeats: $totalSeats, ')
          ..write('availableSeats: $availableSeats, ')
          ..write('agentId: $agentId, ')
          ..write('agentCode: $agentCode, ')
          ..write('startedOffline: $startedOffline, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    localId,
    tripCode,
    routeId,
    fleetId,
    busNumber,
    driverName,
    departureTime,
    arrivalTime,
    status,
    totalSeats,
    availableSeats,
    agentId,
    agentCode,
    startedOffline,
    isSynced,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Trip &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.localId == this.localId &&
          other.tripCode == this.tripCode &&
          other.routeId == this.routeId &&
          other.fleetId == this.fleetId &&
          other.busNumber == this.busNumber &&
          other.driverName == this.driverName &&
          other.departureTime == this.departureTime &&
          other.arrivalTime == this.arrivalTime &&
          other.status == this.status &&
          other.totalSeats == this.totalSeats &&
          other.availableSeats == this.availableSeats &&
          other.agentId == this.agentId &&
          other.agentCode == this.agentCode &&
          other.startedOffline == this.startedOffline &&
          other.isSynced == this.isSynced &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TripsCompanion extends UpdateCompanion<Trip> {
  final Value<int> id;
  final Value<String?> serverId;
  final Value<String> localId;
  final Value<String> tripCode;
  final Value<String> routeId;
  final Value<String> fleetId;
  final Value<String> busNumber;
  final Value<String> driverName;
  final Value<DateTime> departureTime;
  final Value<DateTime?> arrivalTime;
  final Value<String> status;
  final Value<int> totalSeats;
  final Value<int> availableSeats;
  final Value<String> agentId;
  final Value<String> agentCode;
  final Value<bool> startedOffline;
  final Value<bool> isSynced;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const TripsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.localId = const Value.absent(),
    this.tripCode = const Value.absent(),
    this.routeId = const Value.absent(),
    this.fleetId = const Value.absent(),
    this.busNumber = const Value.absent(),
    this.driverName = const Value.absent(),
    this.departureTime = const Value.absent(),
    this.arrivalTime = const Value.absent(),
    this.status = const Value.absent(),
    this.totalSeats = const Value.absent(),
    this.availableSeats = const Value.absent(),
    this.agentId = const Value.absent(),
    this.agentCode = const Value.absent(),
    this.startedOffline = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TripsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required String localId,
    required String tripCode,
    required String routeId,
    required String fleetId,
    required String busNumber,
    required String driverName,
    required DateTime departureTime,
    this.arrivalTime = const Value.absent(),
    required String status,
    required int totalSeats,
    required int availableSeats,
    required String agentId,
    required String agentCode,
    this.startedOffline = const Value.absent(),
    this.isSynced = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : localId = Value(localId),
       tripCode = Value(tripCode),
       routeId = Value(routeId),
       fleetId = Value(fleetId),
       busNumber = Value(busNumber),
       driverName = Value(driverName),
       departureTime = Value(departureTime),
       status = Value(status),
       totalSeats = Value(totalSeats),
       availableSeats = Value(availableSeats),
       agentId = Value(agentId),
       agentCode = Value(agentCode),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Trip> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? localId,
    Expression<String>? tripCode,
    Expression<String>? routeId,
    Expression<String>? fleetId,
    Expression<String>? busNumber,
    Expression<String>? driverName,
    Expression<DateTime>? departureTime,
    Expression<DateTime>? arrivalTime,
    Expression<String>? status,
    Expression<int>? totalSeats,
    Expression<int>? availableSeats,
    Expression<String>? agentId,
    Expression<String>? agentCode,
    Expression<bool>? startedOffline,
    Expression<bool>? isSynced,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (localId != null) 'local_id': localId,
      if (tripCode != null) 'trip_code': tripCode,
      if (routeId != null) 'route_id': routeId,
      if (fleetId != null) 'fleet_id': fleetId,
      if (busNumber != null) 'bus_number': busNumber,
      if (driverName != null) 'driver_name': driverName,
      if (departureTime != null) 'departure_time': departureTime,
      if (arrivalTime != null) 'arrival_time': arrivalTime,
      if (status != null) 'status': status,
      if (totalSeats != null) 'total_seats': totalSeats,
      if (availableSeats != null) 'available_seats': availableSeats,
      if (agentId != null) 'agent_id': agentId,
      if (agentCode != null) 'agent_code': agentCode,
      if (startedOffline != null) 'started_offline': startedOffline,
      if (isSynced != null) 'is_synced': isSynced,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TripsCompanion copyWith({
    Value<int>? id,
    Value<String?>? serverId,
    Value<String>? localId,
    Value<String>? tripCode,
    Value<String>? routeId,
    Value<String>? fleetId,
    Value<String>? busNumber,
    Value<String>? driverName,
    Value<DateTime>? departureTime,
    Value<DateTime?>? arrivalTime,
    Value<String>? status,
    Value<int>? totalSeats,
    Value<int>? availableSeats,
    Value<String>? agentId,
    Value<String>? agentCode,
    Value<bool>? startedOffline,
    Value<bool>? isSynced,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return TripsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      localId: localId ?? this.localId,
      tripCode: tripCode ?? this.tripCode,
      routeId: routeId ?? this.routeId,
      fleetId: fleetId ?? this.fleetId,
      busNumber: busNumber ?? this.busNumber,
      driverName: driverName ?? this.driverName,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      status: status ?? this.status,
      totalSeats: totalSeats ?? this.totalSeats,
      availableSeats: availableSeats ?? this.availableSeats,
      agentId: agentId ?? this.agentId,
      agentCode: agentCode ?? this.agentCode,
      startedOffline: startedOffline ?? this.startedOffline,
      isSynced: isSynced ?? this.isSynced,
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
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (tripCode.present) {
      map['trip_code'] = Variable<String>(tripCode.value);
    }
    if (routeId.present) {
      map['route_id'] = Variable<String>(routeId.value);
    }
    if (fleetId.present) {
      map['fleet_id'] = Variable<String>(fleetId.value);
    }
    if (busNumber.present) {
      map['bus_number'] = Variable<String>(busNumber.value);
    }
    if (driverName.present) {
      map['driver_name'] = Variable<String>(driverName.value);
    }
    if (departureTime.present) {
      map['departure_time'] = Variable<DateTime>(departureTime.value);
    }
    if (arrivalTime.present) {
      map['arrival_time'] = Variable<DateTime>(arrivalTime.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (totalSeats.present) {
      map['total_seats'] = Variable<int>(totalSeats.value);
    }
    if (availableSeats.present) {
      map['available_seats'] = Variable<int>(availableSeats.value);
    }
    if (agentId.present) {
      map['agent_id'] = Variable<String>(agentId.value);
    }
    if (agentCode.present) {
      map['agent_code'] = Variable<String>(agentCode.value);
    }
    if (startedOffline.present) {
      map['started_offline'] = Variable<bool>(startedOffline.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
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
    return (StringBuffer('TripsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('localId: $localId, ')
          ..write('tripCode: $tripCode, ')
          ..write('routeId: $routeId, ')
          ..write('fleetId: $fleetId, ')
          ..write('busNumber: $busNumber, ')
          ..write('driverName: $driverName, ')
          ..write('departureTime: $departureTime, ')
          ..write('arrivalTime: $arrivalTime, ')
          ..write('status: $status, ')
          ..write('totalSeats: $totalSeats, ')
          ..write('availableSeats: $availableSeats, ')
          ..write('agentId: $agentId, ')
          ..write('agentCode: $agentCode, ')
          ..write('startedOffline: $startedOffline, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TicketsTable extends Tickets with TableInfo<$TicketsTable, Ticket> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TicketsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _tripLocalIdMeta = const VerificationMeta(
    'tripLocalId',
  );
  @override
  late final GeneratedColumn<String> tripLocalId = GeneratedColumn<String>(
    'trip_local_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tripServerIdMeta = const VerificationMeta(
    'tripServerId',
  );
  @override
  late final GeneratedColumn<String> tripServerId = GeneratedColumn<String>(
    'trip_server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serialNumberMeta = const VerificationMeta(
    'serialNumber',
  );
  @override
  late final GeneratedColumn<String> serialNumber = GeneratedColumn<String>(
    'serial_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _linkedPassengerTicketIdMeta =
      const VerificationMeta('linkedPassengerTicketId');
  @override
  late final GeneratedColumn<String> linkedPassengerTicketId =
      GeneratedColumn<String>(
        'linked_passenger_ticket_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
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
  static const VerificationMeta _agentCodeMeta = const VerificationMeta(
    'agentCode',
  );
  @override
  late final GeneratedColumn<String> agentCode = GeneratedColumn<String>(
    'agent_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _issuedOfflineMeta = const VerificationMeta(
    'issuedOffline',
  );
  @override
  late final GeneratedColumn<bool> issuedOffline = GeneratedColumn<bool>(
    'issued_offline',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("issued_offline" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncAttemptAtMeta = const VerificationMeta(
    'lastSyncAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAttemptAt =
      GeneratedColumn<DateTime>(
        'last_sync_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localId,
    serverId,
    tripLocalId,
    tripServerId,
    serialNumber,
    ticketCategory,
    currency,
    amount,
    departure,
    destination,
    linkedPassengerTicketId,
    agentId,
    agentCode,
    issuedAt,
    issuedOffline,
    isSynced,
    syncError,
    lastSyncAttemptAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tickets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Ticket> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('trip_local_id')) {
      context.handle(
        _tripLocalIdMeta,
        tripLocalId.isAcceptableOrUnknown(
          data['trip_local_id']!,
          _tripLocalIdMeta,
        ),
      );
    }
    if (data.containsKey('trip_server_id')) {
      context.handle(
        _tripServerIdMeta,
        tripServerId.isAcceptableOrUnknown(
          data['trip_server_id']!,
          _tripServerIdMeta,
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
    if (data.containsKey('linked_passenger_ticket_id')) {
      context.handle(
        _linkedPassengerTicketIdMeta,
        linkedPassengerTicketId.isAcceptableOrUnknown(
          data['linked_passenger_ticket_id']!,
          _linkedPassengerTicketIdMeta,
        ),
      );
    }
    if (data.containsKey('agent_id')) {
      context.handle(
        _agentIdMeta,
        agentId.isAcceptableOrUnknown(data['agent_id']!, _agentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_agentIdMeta);
    }
    if (data.containsKey('agent_code')) {
      context.handle(
        _agentCodeMeta,
        agentCode.isAcceptableOrUnknown(data['agent_code']!, _agentCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_agentCodeMeta);
    }
    if (data.containsKey('issued_at')) {
      context.handle(
        _issuedAtMeta,
        issuedAt.isAcceptableOrUnknown(data['issued_at']!, _issuedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_issuedAtMeta);
    }
    if (data.containsKey('issued_offline')) {
      context.handle(
        _issuedOfflineMeta,
        issuedOffline.isAcceptableOrUnknown(
          data['issued_offline']!,
          _issuedOfflineMeta,
        ),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('last_sync_attempt_at')) {
      context.handle(
        _lastSyncAttemptAtMeta,
        lastSyncAttemptAt.isAcceptableOrUnknown(
          data['last_sync_attempt_at']!,
          _lastSyncAttemptAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ticket map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ticket(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      tripLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_local_id'],
      ),
      tripServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_server_id'],
      ),
      serialNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serial_number'],
      ),
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
      linkedPassengerTicketId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_passenger_ticket_id'],
      ),
      agentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_id'],
      )!,
      agentCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_code'],
      )!,
      issuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}issued_at'],
      )!,
      issuedOffline: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}issued_offline'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      lastSyncAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_attempt_at'],
      ),
    );
  }

  @override
  $TicketsTable createAlias(String alias) {
    return $TicketsTable(attachedDatabase, alias);
  }
}

class Ticket extends DataClass implements Insertable<Ticket> {
  final int id;
  final String localId;
  final String? serverId;
  final String? tripLocalId;
  final String? tripServerId;
  final String? serialNumber;
  final String ticketCategory;
  final String currency;
  final double amount;
  final String? departure;
  final String? destination;
  final String? linkedPassengerTicketId;
  final String agentId;
  final String agentCode;
  final DateTime issuedAt;
  final bool issuedOffline;
  final bool isSynced;
  final String? syncError;
  final DateTime? lastSyncAttemptAt;
  const Ticket({
    required this.id,
    required this.localId,
    this.serverId,
    this.tripLocalId,
    this.tripServerId,
    this.serialNumber,
    required this.ticketCategory,
    required this.currency,
    required this.amount,
    this.departure,
    this.destination,
    this.linkedPassengerTicketId,
    required this.agentId,
    required this.agentCode,
    required this.issuedAt,
    required this.issuedOffline,
    required this.isSynced,
    this.syncError,
    this.lastSyncAttemptAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    if (!nullToAbsent || tripLocalId != null) {
      map['trip_local_id'] = Variable<String>(tripLocalId);
    }
    if (!nullToAbsent || tripServerId != null) {
      map['trip_server_id'] = Variable<String>(tripServerId);
    }
    if (!nullToAbsent || serialNumber != null) {
      map['serial_number'] = Variable<String>(serialNumber);
    }
    map['ticket_category'] = Variable<String>(ticketCategory);
    map['currency'] = Variable<String>(currency);
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || departure != null) {
      map['departure'] = Variable<String>(departure);
    }
    if (!nullToAbsent || destination != null) {
      map['destination'] = Variable<String>(destination);
    }
    if (!nullToAbsent || linkedPassengerTicketId != null) {
      map['linked_passenger_ticket_id'] = Variable<String>(
        linkedPassengerTicketId,
      );
    }
    map['agent_id'] = Variable<String>(agentId);
    map['agent_code'] = Variable<String>(agentCode);
    map['issued_at'] = Variable<DateTime>(issuedAt);
    map['issued_offline'] = Variable<bool>(issuedOffline);
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    if (!nullToAbsent || lastSyncAttemptAt != null) {
      map['last_sync_attempt_at'] = Variable<DateTime>(lastSyncAttemptAt);
    }
    return map;
  }

  TicketsCompanion toCompanion(bool nullToAbsent) {
    return TicketsCompanion(
      id: Value(id),
      localId: Value(localId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      tripLocalId: tripLocalId == null && nullToAbsent
          ? const Value.absent()
          : Value(tripLocalId),
      tripServerId: tripServerId == null && nullToAbsent
          ? const Value.absent()
          : Value(tripServerId),
      serialNumber: serialNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(serialNumber),
      ticketCategory: Value(ticketCategory),
      currency: Value(currency),
      amount: Value(amount),
      departure: departure == null && nullToAbsent
          ? const Value.absent()
          : Value(departure),
      destination: destination == null && nullToAbsent
          ? const Value.absent()
          : Value(destination),
      linkedPassengerTicketId: linkedPassengerTicketId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedPassengerTicketId),
      agentId: Value(agentId),
      agentCode: Value(agentCode),
      issuedAt: Value(issuedAt),
      issuedOffline: Value(issuedOffline),
      isSynced: Value(isSynced),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      lastSyncAttemptAt: lastSyncAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAttemptAt),
    );
  }

  factory Ticket.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ticket(
      id: serializer.fromJson<int>(json['id']),
      localId: serializer.fromJson<String>(json['localId']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      tripLocalId: serializer.fromJson<String?>(json['tripLocalId']),
      tripServerId: serializer.fromJson<String?>(json['tripServerId']),
      serialNumber: serializer.fromJson<String?>(json['serialNumber']),
      ticketCategory: serializer.fromJson<String>(json['ticketCategory']),
      currency: serializer.fromJson<String>(json['currency']),
      amount: serializer.fromJson<double>(json['amount']),
      departure: serializer.fromJson<String?>(json['departure']),
      destination: serializer.fromJson<String?>(json['destination']),
      linkedPassengerTicketId: serializer.fromJson<String?>(
        json['linkedPassengerTicketId'],
      ),
      agentId: serializer.fromJson<String>(json['agentId']),
      agentCode: serializer.fromJson<String>(json['agentCode']),
      issuedAt: serializer.fromJson<DateTime>(json['issuedAt']),
      issuedOffline: serializer.fromJson<bool>(json['issuedOffline']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      lastSyncAttemptAt: serializer.fromJson<DateTime?>(
        json['lastSyncAttemptAt'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'localId': serializer.toJson<String>(localId),
      'serverId': serializer.toJson<String?>(serverId),
      'tripLocalId': serializer.toJson<String?>(tripLocalId),
      'tripServerId': serializer.toJson<String?>(tripServerId),
      'serialNumber': serializer.toJson<String?>(serialNumber),
      'ticketCategory': serializer.toJson<String>(ticketCategory),
      'currency': serializer.toJson<String>(currency),
      'amount': serializer.toJson<double>(amount),
      'departure': serializer.toJson<String?>(departure),
      'destination': serializer.toJson<String?>(destination),
      'linkedPassengerTicketId': serializer.toJson<String?>(
        linkedPassengerTicketId,
      ),
      'agentId': serializer.toJson<String>(agentId),
      'agentCode': serializer.toJson<String>(agentCode),
      'issuedAt': serializer.toJson<DateTime>(issuedAt),
      'issuedOffline': serializer.toJson<bool>(issuedOffline),
      'isSynced': serializer.toJson<bool>(isSynced),
      'syncError': serializer.toJson<String?>(syncError),
      'lastSyncAttemptAt': serializer.toJson<DateTime?>(lastSyncAttemptAt),
    };
  }

  Ticket copyWith({
    int? id,
    String? localId,
    Value<String?> serverId = const Value.absent(),
    Value<String?> tripLocalId = const Value.absent(),
    Value<String?> tripServerId = const Value.absent(),
    Value<String?> serialNumber = const Value.absent(),
    String? ticketCategory,
    String? currency,
    double? amount,
    Value<String?> departure = const Value.absent(),
    Value<String?> destination = const Value.absent(),
    Value<String?> linkedPassengerTicketId = const Value.absent(),
    String? agentId,
    String? agentCode,
    DateTime? issuedAt,
    bool? issuedOffline,
    bool? isSynced,
    Value<String?> syncError = const Value.absent(),
    Value<DateTime?> lastSyncAttemptAt = const Value.absent(),
  }) => Ticket(
    id: id ?? this.id,
    localId: localId ?? this.localId,
    serverId: serverId.present ? serverId.value : this.serverId,
    tripLocalId: tripLocalId.present ? tripLocalId.value : this.tripLocalId,
    tripServerId: tripServerId.present ? tripServerId.value : this.tripServerId,
    serialNumber: serialNumber.present ? serialNumber.value : this.serialNumber,
    ticketCategory: ticketCategory ?? this.ticketCategory,
    currency: currency ?? this.currency,
    amount: amount ?? this.amount,
    departure: departure.present ? departure.value : this.departure,
    destination: destination.present ? destination.value : this.destination,
    linkedPassengerTicketId: linkedPassengerTicketId.present
        ? linkedPassengerTicketId.value
        : this.linkedPassengerTicketId,
    agentId: agentId ?? this.agentId,
    agentCode: agentCode ?? this.agentCode,
    issuedAt: issuedAt ?? this.issuedAt,
    issuedOffline: issuedOffline ?? this.issuedOffline,
    isSynced: isSynced ?? this.isSynced,
    syncError: syncError.present ? syncError.value : this.syncError,
    lastSyncAttemptAt: lastSyncAttemptAt.present
        ? lastSyncAttemptAt.value
        : this.lastSyncAttemptAt,
  );
  Ticket copyWithCompanion(TicketsCompanion data) {
    return Ticket(
      id: data.id.present ? data.id.value : this.id,
      localId: data.localId.present ? data.localId.value : this.localId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      tripLocalId: data.tripLocalId.present
          ? data.tripLocalId.value
          : this.tripLocalId,
      tripServerId: data.tripServerId.present
          ? data.tripServerId.value
          : this.tripServerId,
      serialNumber: data.serialNumber.present
          ? data.serialNumber.value
          : this.serialNumber,
      ticketCategory: data.ticketCategory.present
          ? data.ticketCategory.value
          : this.ticketCategory,
      currency: data.currency.present ? data.currency.value : this.currency,
      amount: data.amount.present ? data.amount.value : this.amount,
      departure: data.departure.present ? data.departure.value : this.departure,
      destination: data.destination.present
          ? data.destination.value
          : this.destination,
      linkedPassengerTicketId: data.linkedPassengerTicketId.present
          ? data.linkedPassengerTicketId.value
          : this.linkedPassengerTicketId,
      agentId: data.agentId.present ? data.agentId.value : this.agentId,
      agentCode: data.agentCode.present ? data.agentCode.value : this.agentCode,
      issuedAt: data.issuedAt.present ? data.issuedAt.value : this.issuedAt,
      issuedOffline: data.issuedOffline.present
          ? data.issuedOffline.value
          : this.issuedOffline,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      lastSyncAttemptAt: data.lastSyncAttemptAt.present
          ? data.lastSyncAttemptAt.value
          : this.lastSyncAttemptAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ticket(')
          ..write('id: $id, ')
          ..write('localId: $localId, ')
          ..write('serverId: $serverId, ')
          ..write('tripLocalId: $tripLocalId, ')
          ..write('tripServerId: $tripServerId, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('ticketCategory: $ticketCategory, ')
          ..write('currency: $currency, ')
          ..write('amount: $amount, ')
          ..write('departure: $departure, ')
          ..write('destination: $destination, ')
          ..write('linkedPassengerTicketId: $linkedPassengerTicketId, ')
          ..write('agentId: $agentId, ')
          ..write('agentCode: $agentCode, ')
          ..write('issuedAt: $issuedAt, ')
          ..write('issuedOffline: $issuedOffline, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncError: $syncError, ')
          ..write('lastSyncAttemptAt: $lastSyncAttemptAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    localId,
    serverId,
    tripLocalId,
    tripServerId,
    serialNumber,
    ticketCategory,
    currency,
    amount,
    departure,
    destination,
    linkedPassengerTicketId,
    agentId,
    agentCode,
    issuedAt,
    issuedOffline,
    isSynced,
    syncError,
    lastSyncAttemptAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ticket &&
          other.id == this.id &&
          other.localId == this.localId &&
          other.serverId == this.serverId &&
          other.tripLocalId == this.tripLocalId &&
          other.tripServerId == this.tripServerId &&
          other.serialNumber == this.serialNumber &&
          other.ticketCategory == this.ticketCategory &&
          other.currency == this.currency &&
          other.amount == this.amount &&
          other.departure == this.departure &&
          other.destination == this.destination &&
          other.linkedPassengerTicketId == this.linkedPassengerTicketId &&
          other.agentId == this.agentId &&
          other.agentCode == this.agentCode &&
          other.issuedAt == this.issuedAt &&
          other.issuedOffline == this.issuedOffline &&
          other.isSynced == this.isSynced &&
          other.syncError == this.syncError &&
          other.lastSyncAttemptAt == this.lastSyncAttemptAt);
}

class TicketsCompanion extends UpdateCompanion<Ticket> {
  final Value<int> id;
  final Value<String> localId;
  final Value<String?> serverId;
  final Value<String?> tripLocalId;
  final Value<String?> tripServerId;
  final Value<String?> serialNumber;
  final Value<String> ticketCategory;
  final Value<String> currency;
  final Value<double> amount;
  final Value<String?> departure;
  final Value<String?> destination;
  final Value<String?> linkedPassengerTicketId;
  final Value<String> agentId;
  final Value<String> agentCode;
  final Value<DateTime> issuedAt;
  final Value<bool> issuedOffline;
  final Value<bool> isSynced;
  final Value<String?> syncError;
  final Value<DateTime?> lastSyncAttemptAt;
  const TicketsCompanion({
    this.id = const Value.absent(),
    this.localId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.tripLocalId = const Value.absent(),
    this.tripServerId = const Value.absent(),
    this.serialNumber = const Value.absent(),
    this.ticketCategory = const Value.absent(),
    this.currency = const Value.absent(),
    this.amount = const Value.absent(),
    this.departure = const Value.absent(),
    this.destination = const Value.absent(),
    this.linkedPassengerTicketId = const Value.absent(),
    this.agentId = const Value.absent(),
    this.agentCode = const Value.absent(),
    this.issuedAt = const Value.absent(),
    this.issuedOffline = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncError = const Value.absent(),
    this.lastSyncAttemptAt = const Value.absent(),
  });
  TicketsCompanion.insert({
    this.id = const Value.absent(),
    required String localId,
    this.serverId = const Value.absent(),
    this.tripLocalId = const Value.absent(),
    this.tripServerId = const Value.absent(),
    this.serialNumber = const Value.absent(),
    required String ticketCategory,
    required String currency,
    required double amount,
    this.departure = const Value.absent(),
    this.destination = const Value.absent(),
    this.linkedPassengerTicketId = const Value.absent(),
    required String agentId,
    required String agentCode,
    required DateTime issuedAt,
    this.issuedOffline = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncError = const Value.absent(),
    this.lastSyncAttemptAt = const Value.absent(),
  }) : localId = Value(localId),
       ticketCategory = Value(ticketCategory),
       currency = Value(currency),
       amount = Value(amount),
       agentId = Value(agentId),
       agentCode = Value(agentCode),
       issuedAt = Value(issuedAt);
  static Insertable<Ticket> custom({
    Expression<int>? id,
    Expression<String>? localId,
    Expression<String>? serverId,
    Expression<String>? tripLocalId,
    Expression<String>? tripServerId,
    Expression<String>? serialNumber,
    Expression<String>? ticketCategory,
    Expression<String>? currency,
    Expression<double>? amount,
    Expression<String>? departure,
    Expression<String>? destination,
    Expression<String>? linkedPassengerTicketId,
    Expression<String>? agentId,
    Expression<String>? agentCode,
    Expression<DateTime>? issuedAt,
    Expression<bool>? issuedOffline,
    Expression<bool>? isSynced,
    Expression<String>? syncError,
    Expression<DateTime>? lastSyncAttemptAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localId != null) 'local_id': localId,
      if (serverId != null) 'server_id': serverId,
      if (tripLocalId != null) 'trip_local_id': tripLocalId,
      if (tripServerId != null) 'trip_server_id': tripServerId,
      if (serialNumber != null) 'serial_number': serialNumber,
      if (ticketCategory != null) 'ticket_category': ticketCategory,
      if (currency != null) 'currency': currency,
      if (amount != null) 'amount': amount,
      if (departure != null) 'departure': departure,
      if (destination != null) 'destination': destination,
      if (linkedPassengerTicketId != null)
        'linked_passenger_ticket_id': linkedPassengerTicketId,
      if (agentId != null) 'agent_id': agentId,
      if (agentCode != null) 'agent_code': agentCode,
      if (issuedAt != null) 'issued_at': issuedAt,
      if (issuedOffline != null) 'issued_offline': issuedOffline,
      if (isSynced != null) 'is_synced': isSynced,
      if (syncError != null) 'sync_error': syncError,
      if (lastSyncAttemptAt != null) 'last_sync_attempt_at': lastSyncAttemptAt,
    });
  }

  TicketsCompanion copyWith({
    Value<int>? id,
    Value<String>? localId,
    Value<String?>? serverId,
    Value<String?>? tripLocalId,
    Value<String?>? tripServerId,
    Value<String?>? serialNumber,
    Value<String>? ticketCategory,
    Value<String>? currency,
    Value<double>? amount,
    Value<String?>? departure,
    Value<String?>? destination,
    Value<String?>? linkedPassengerTicketId,
    Value<String>? agentId,
    Value<String>? agentCode,
    Value<DateTime>? issuedAt,
    Value<bool>? issuedOffline,
    Value<bool>? isSynced,
    Value<String?>? syncError,
    Value<DateTime?>? lastSyncAttemptAt,
  }) {
    return TicketsCompanion(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      tripLocalId: tripLocalId ?? this.tripLocalId,
      tripServerId: tripServerId ?? this.tripServerId,
      serialNumber: serialNumber ?? this.serialNumber,
      ticketCategory: ticketCategory ?? this.ticketCategory,
      currency: currency ?? this.currency,
      amount: amount ?? this.amount,
      departure: departure ?? this.departure,
      destination: destination ?? this.destination,
      linkedPassengerTicketId:
          linkedPassengerTicketId ?? this.linkedPassengerTicketId,
      agentId: agentId ?? this.agentId,
      agentCode: agentCode ?? this.agentCode,
      issuedAt: issuedAt ?? this.issuedAt,
      issuedOffline: issuedOffline ?? this.issuedOffline,
      isSynced: isSynced ?? this.isSynced,
      syncError: syncError ?? this.syncError,
      lastSyncAttemptAt: lastSyncAttemptAt ?? this.lastSyncAttemptAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (tripLocalId.present) {
      map['trip_local_id'] = Variable<String>(tripLocalId.value);
    }
    if (tripServerId.present) {
      map['trip_server_id'] = Variable<String>(tripServerId.value);
    }
    if (serialNumber.present) {
      map['serial_number'] = Variable<String>(serialNumber.value);
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
    if (linkedPassengerTicketId.present) {
      map['linked_passenger_ticket_id'] = Variable<String>(
        linkedPassengerTicketId.value,
      );
    }
    if (agentId.present) {
      map['agent_id'] = Variable<String>(agentId.value);
    }
    if (agentCode.present) {
      map['agent_code'] = Variable<String>(agentCode.value);
    }
    if (issuedAt.present) {
      map['issued_at'] = Variable<DateTime>(issuedAt.value);
    }
    if (issuedOffline.present) {
      map['issued_offline'] = Variable<bool>(issuedOffline.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (lastSyncAttemptAt.present) {
      map['last_sync_attempt_at'] = Variable<DateTime>(lastSyncAttemptAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TicketsCompanion(')
          ..write('id: $id, ')
          ..write('localId: $localId, ')
          ..write('serverId: $serverId, ')
          ..write('tripLocalId: $tripLocalId, ')
          ..write('tripServerId: $tripServerId, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('ticketCategory: $ticketCategory, ')
          ..write('currency: $currency, ')
          ..write('amount: $amount, ')
          ..write('departure: $departure, ')
          ..write('destination: $destination, ')
          ..write('linkedPassengerTicketId: $linkedPassengerTicketId, ')
          ..write('agentId: $agentId, ')
          ..write('agentCode: $agentCode, ')
          ..write('issuedAt: $issuedAt, ')
          ..write('issuedOffline: $issuedOffline, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncError: $syncError, ')
          ..write('lastSyncAttemptAt: $lastSyncAttemptAt')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
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
  late final GeneratedColumn<int> entityId = GeneratedColumn<int>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityId,
    operation,
    data,
    retryCount,
    createdAt,
    lastAttemptAt,
    error,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueData> instance, {
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
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
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
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entity_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final int id;
  final String entityType;
  final int entityId;
  final String operation;
  final String data;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final String? error;
  const SyncQueueData({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.data,
    required this.retryCount,
    required this.createdAt,
    this.lastAttemptAt,
    this.error,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<int>(entityId);
    map['operation'] = Variable<String>(operation);
    map['data'] = Variable<String>(data);
    map['retry_count'] = Variable<int>(retryCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      data: Value(data),
      retryCount: Value(retryCount),
      createdAt: Value(createdAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
    );
  }

  factory SyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<int>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      data: serializer.fromJson<String>(json['data']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      error: serializer.fromJson<String?>(json['error']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<int>(entityId),
      'operation': serializer.toJson<String>(operation),
      'data': serializer.toJson<String>(data),
      'retryCount': serializer.toJson<int>(retryCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'error': serializer.toJson<String?>(error),
    };
  }

  SyncQueueData copyWith({
    int? id,
    String? entityType,
    int? entityId,
    String? operation,
    String? data,
    int? retryCount,
    DateTime? createdAt,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<String?> error = const Value.absent(),
  }) => SyncQueueData(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    operation: operation ?? this.operation,
    data: data ?? this.data,
    retryCount: retryCount ?? this.retryCount,
    createdAt: createdAt ?? this.createdAt,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    error: error.present ? error.value : this.error,
  );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      data: data.data.present ? data.data.value : this.data,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      error: data.error.present ? data.error.value : this.error,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('data: $data, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('error: $error')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityId,
    operation,
    data,
    retryCount,
    createdAt,
    lastAttemptAt,
    error,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.data == this.data &&
          other.retryCount == this.retryCount &&
          other.createdAt == this.createdAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.error == this.error);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<int> id;
  final Value<String> entityType;
  final Value<int> entityId;
  final Value<String> operation;
  final Value<String> data;
  final Value<int> retryCount;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastAttemptAt;
  final Value<String?> error;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.data = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.error = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String entityType,
    required int entityId,
    required String operation,
    required String data,
    this.retryCount = const Value.absent(),
    required DateTime createdAt,
    this.lastAttemptAt = const Value.absent(),
    this.error = const Value.absent(),
  }) : entityType = Value(entityType),
       entityId = Value(entityId),
       operation = Value(operation),
       data = Value(data),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? entityType,
    Expression<int>? entityId,
    Expression<String>? operation,
    Expression<String>? data,
    Expression<int>? retryCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastAttemptAt,
    Expression<String>? error,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (data != null) 'data': data,
      if (retryCount != null) 'retry_count': retryCount,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (error != null) 'error': error,
    });
  }

  SyncQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? entityType,
    Value<int>? entityId,
    Value<String>? operation,
    Value<String>? data,
    Value<int>? retryCount,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastAttemptAt,
    Value<String?>? error,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      data: data ?? this.data,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      error: error ?? this.error,
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
      map['entity_id'] = Variable<int>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('data: $data, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('error: $error')
          ..write(')'))
        .toString();
  }
}

class $CacheMetadataTable extends CacheMetadata
    with TableInfo<$CacheMetadataTable, CacheMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CacheMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dataTypeMeta = const VerificationMeta(
    'dataType',
  );
  @override
  late final GeneratedColumn<String> dataType = GeneratedColumn<String>(
    'data_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastCachedAtMeta = const VerificationMeta(
    'lastCachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastCachedAt = GeneratedColumn<DateTime>(
    'last_cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordCountMeta = const VerificationMeta(
    'recordCount',
  );
  @override
  late final GeneratedColumn<int> recordCount = GeneratedColumn<int>(
    'record_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [dataType, lastCachedAt, recordCount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cache_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('data_type')) {
      context.handle(
        _dataTypeMeta,
        dataType.isAcceptableOrUnknown(data['data_type']!, _dataTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_dataTypeMeta);
    }
    if (data.containsKey('last_cached_at')) {
      context.handle(
        _lastCachedAtMeta,
        lastCachedAt.isAcceptableOrUnknown(
          data['last_cached_at']!,
          _lastCachedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastCachedAtMeta);
    }
    if (data.containsKey('record_count')) {
      context.handle(
        _recordCountMeta,
        recordCount.isAcceptableOrUnknown(
          data['record_count']!,
          _recordCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dataType};
  @override
  CacheMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheMetadataData(
      dataType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_type'],
      )!,
      lastCachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_cached_at'],
      )!,
      recordCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}record_count'],
      )!,
    );
  }

  @override
  $CacheMetadataTable createAlias(String alias) {
    return $CacheMetadataTable(attachedDatabase, alias);
  }
}

class CacheMetadataData extends DataClass
    implements Insertable<CacheMetadataData> {
  final String dataType;
  final DateTime lastCachedAt;
  final int recordCount;
  const CacheMetadataData({
    required this.dataType,
    required this.lastCachedAt,
    required this.recordCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['data_type'] = Variable<String>(dataType);
    map['last_cached_at'] = Variable<DateTime>(lastCachedAt);
    map['record_count'] = Variable<int>(recordCount);
    return map;
  }

  CacheMetadataCompanion toCompanion(bool nullToAbsent) {
    return CacheMetadataCompanion(
      dataType: Value(dataType),
      lastCachedAt: Value(lastCachedAt),
      recordCount: Value(recordCount),
    );
  }

  factory CacheMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheMetadataData(
      dataType: serializer.fromJson<String>(json['dataType']),
      lastCachedAt: serializer.fromJson<DateTime>(json['lastCachedAt']),
      recordCount: serializer.fromJson<int>(json['recordCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dataType': serializer.toJson<String>(dataType),
      'lastCachedAt': serializer.toJson<DateTime>(lastCachedAt),
      'recordCount': serializer.toJson<int>(recordCount),
    };
  }

  CacheMetadataData copyWith({
    String? dataType,
    DateTime? lastCachedAt,
    int? recordCount,
  }) => CacheMetadataData(
    dataType: dataType ?? this.dataType,
    lastCachedAt: lastCachedAt ?? this.lastCachedAt,
    recordCount: recordCount ?? this.recordCount,
  );
  CacheMetadataData copyWithCompanion(CacheMetadataCompanion data) {
    return CacheMetadataData(
      dataType: data.dataType.present ? data.dataType.value : this.dataType,
      lastCachedAt: data.lastCachedAt.present
          ? data.lastCachedAt.value
          : this.lastCachedAt,
      recordCount: data.recordCount.present
          ? data.recordCount.value
          : this.recordCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheMetadataData(')
          ..write('dataType: $dataType, ')
          ..write('lastCachedAt: $lastCachedAt, ')
          ..write('recordCount: $recordCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(dataType, lastCachedAt, recordCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheMetadataData &&
          other.dataType == this.dataType &&
          other.lastCachedAt == this.lastCachedAt &&
          other.recordCount == this.recordCount);
}

class CacheMetadataCompanion extends UpdateCompanion<CacheMetadataData> {
  final Value<String> dataType;
  final Value<DateTime> lastCachedAt;
  final Value<int> recordCount;
  final Value<int> rowid;
  const CacheMetadataCompanion({
    this.dataType = const Value.absent(),
    this.lastCachedAt = const Value.absent(),
    this.recordCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CacheMetadataCompanion.insert({
    required String dataType,
    required DateTime lastCachedAt,
    this.recordCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : dataType = Value(dataType),
       lastCachedAt = Value(lastCachedAt);
  static Insertable<CacheMetadataData> custom({
    Expression<String>? dataType,
    Expression<DateTime>? lastCachedAt,
    Expression<int>? recordCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dataType != null) 'data_type': dataType,
      if (lastCachedAt != null) 'last_cached_at': lastCachedAt,
      if (recordCount != null) 'record_count': recordCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CacheMetadataCompanion copyWith({
    Value<String>? dataType,
    Value<DateTime>? lastCachedAt,
    Value<int>? recordCount,
    Value<int>? rowid,
  }) {
    return CacheMetadataCompanion(
      dataType: dataType ?? this.dataType,
      lastCachedAt: lastCachedAt ?? this.lastCachedAt,
      recordCount: recordCount ?? this.recordCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dataType.present) {
      map['data_type'] = Variable<String>(dataType.value);
    }
    if (lastCachedAt.present) {
      map['last_cached_at'] = Variable<DateTime>(lastCachedAt.value);
    }
    if (recordCount.present) {
      map['record_count'] = Variable<int>(recordCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CacheMetadataCompanion(')
          ..write('dataType: $dataType, ')
          ..write('lastCachedAt: $lastCachedAt, ')
          ..write('recordCount: $recordCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DevicesTable devices = $DevicesTable(this);
  late final $AgentsTable agents = $AgentsTable(this);
  late final $RoutesTable routes = $RoutesTable(this);
  late final $FleetsTable fleets = $FleetsTable(this);
  late final $TripsTable trips = $TripsTable(this);
  late final $TicketsTable tickets = $TicketsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $CacheMetadataTable cacheMetadata = $CacheMetadataTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    devices,
    agents,
    routes,
    fleets,
    trips,
    tickets,
    syncQueue,
    cacheMetadata,
  ];
}

typedef $$DevicesTableCreateCompanionBuilder =
    DevicesCompanion Function({
      Value<int> id,
      required String deviceToken,
      required String merchantCode,
      required String deviceName,
      required String deviceModel,
      required DateTime pairedAt,
      Value<bool> isActive,
    });
typedef $$DevicesTableUpdateCompanionBuilder =
    DevicesCompanion Function({
      Value<int> id,
      Value<String> deviceToken,
      Value<String> merchantCode,
      Value<String> deviceName,
      Value<String> deviceModel,
      Value<DateTime> pairedAt,
      Value<bool> isActive,
    });

class $$DevicesTableFilterComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableFilterComposer({
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

  ColumnFilters<String> get deviceToken => $composableBuilder(
    column: $table.deviceToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchantCode => $composableBuilder(
    column: $table.merchantCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceModel => $composableBuilder(
    column: $table.deviceModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pairedAt => $composableBuilder(
    column: $table.pairedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DevicesTableOrderingComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableOrderingComposer({
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

  ColumnOrderings<String> get deviceToken => $composableBuilder(
    column: $table.deviceToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchantCode => $composableBuilder(
    column: $table.merchantCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceModel => $composableBuilder(
    column: $table.deviceModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pairedAt => $composableBuilder(
    column: $table.pairedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DevicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deviceToken => $composableBuilder(
    column: $table.deviceToken,
    builder: (column) => column,
  );

  GeneratedColumn<String> get merchantCode => $composableBuilder(
    column: $table.merchantCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceModel => $composableBuilder(
    column: $table.deviceModel,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get pairedAt =>
      $composableBuilder(column: $table.pairedAt, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$DevicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DevicesTable,
          Device,
          $$DevicesTableFilterComposer,
          $$DevicesTableOrderingComposer,
          $$DevicesTableAnnotationComposer,
          $$DevicesTableCreateCompanionBuilder,
          $$DevicesTableUpdateCompanionBuilder,
          (Device, BaseReferences<_$AppDatabase, $DevicesTable, Device>),
          Device,
          PrefetchHooks Function()
        > {
  $$DevicesTableTableManager(_$AppDatabase db, $DevicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> deviceToken = const Value.absent(),
                Value<String> merchantCode = const Value.absent(),
                Value<String> deviceName = const Value.absent(),
                Value<String> deviceModel = const Value.absent(),
                Value<DateTime> pairedAt = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => DevicesCompanion(
                id: id,
                deviceToken: deviceToken,
                merchantCode: merchantCode,
                deviceName: deviceName,
                deviceModel: deviceModel,
                pairedAt: pairedAt,
                isActive: isActive,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String deviceToken,
                required String merchantCode,
                required String deviceName,
                required String deviceModel,
                required DateTime pairedAt,
                Value<bool> isActive = const Value.absent(),
              }) => DevicesCompanion.insert(
                id: id,
                deviceToken: deviceToken,
                merchantCode: merchantCode,
                deviceName: deviceName,
                deviceModel: deviceModel,
                pairedAt: pairedAt,
                isActive: isActive,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DevicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DevicesTable,
      Device,
      $$DevicesTableFilterComposer,
      $$DevicesTableOrderingComposer,
      $$DevicesTableAnnotationComposer,
      $$DevicesTableCreateCompanionBuilder,
      $$DevicesTableUpdateCompanionBuilder,
      (Device, BaseReferences<_$AppDatabase, $DevicesTable, Device>),
      Device,
      PrefetchHooks Function()
    >;
typedef $$AgentsTableCreateCompanionBuilder =
    AgentsCompanion Function({
      Value<int> id,
      required String agentCode,
      required String firstName,
      required String lastName,
      required String role,
      required String merchantCode,
      required String merchantName,
      required String depotCode,
      required String depotName,
      Value<DateTime?> lastLogin,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$AgentsTableUpdateCompanionBuilder =
    AgentsCompanion Function({
      Value<int> id,
      Value<String> agentCode,
      Value<String> firstName,
      Value<String> lastName,
      Value<String> role,
      Value<String> merchantCode,
      Value<String> merchantName,
      Value<String> depotCode,
      Value<String> depotName,
      Value<DateTime?> lastLogin,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$AgentsTableFilterComposer
    extends Composer<_$AppDatabase, $AgentsTable> {
  $$AgentsTableFilterComposer({
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

  ColumnFilters<String> get agentCode => $composableBuilder(
    column: $table.agentCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchantCode => $composableBuilder(
    column: $table.merchantCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchantName => $composableBuilder(
    column: $table.merchantName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get depotCode => $composableBuilder(
    column: $table.depotCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get depotName => $composableBuilder(
    column: $table.depotName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastLogin => $composableBuilder(
    column: $table.lastLogin,
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

class $$AgentsTableOrderingComposer
    extends Composer<_$AppDatabase, $AgentsTable> {
  $$AgentsTableOrderingComposer({
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

  ColumnOrderings<String> get agentCode => $composableBuilder(
    column: $table.agentCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchantCode => $composableBuilder(
    column: $table.merchantCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchantName => $composableBuilder(
    column: $table.merchantName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get depotCode => $composableBuilder(
    column: $table.depotCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get depotName => $composableBuilder(
    column: $table.depotName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastLogin => $composableBuilder(
    column: $table.lastLogin,
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

class $$AgentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AgentsTable> {
  $$AgentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get agentCode =>
      $composableBuilder(column: $table.agentCode, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get merchantCode => $composableBuilder(
    column: $table.merchantCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get merchantName => $composableBuilder(
    column: $table.merchantName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get depotCode =>
      $composableBuilder(column: $table.depotCode, builder: (column) => column);

  GeneratedColumn<String> get depotName =>
      $composableBuilder(column: $table.depotName, builder: (column) => column);

  GeneratedColumn<DateTime> get lastLogin =>
      $composableBuilder(column: $table.lastLogin, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AgentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AgentsTable,
          Agent,
          $$AgentsTableFilterComposer,
          $$AgentsTableOrderingComposer,
          $$AgentsTableAnnotationComposer,
          $$AgentsTableCreateCompanionBuilder,
          $$AgentsTableUpdateCompanionBuilder,
          (Agent, BaseReferences<_$AppDatabase, $AgentsTable, Agent>),
          Agent,
          PrefetchHooks Function()
        > {
  $$AgentsTableTableManager(_$AppDatabase db, $AgentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AgentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AgentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AgentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> agentCode = const Value.absent(),
                Value<String> firstName = const Value.absent(),
                Value<String> lastName = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> merchantCode = const Value.absent(),
                Value<String> merchantName = const Value.absent(),
                Value<String> depotCode = const Value.absent(),
                Value<String> depotName = const Value.absent(),
                Value<DateTime?> lastLogin = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AgentsCompanion(
                id: id,
                agentCode: agentCode,
                firstName: firstName,
                lastName: lastName,
                role: role,
                merchantCode: merchantCode,
                merchantName: merchantName,
                depotCode: depotCode,
                depotName: depotName,
                lastLogin: lastLogin,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String agentCode,
                required String firstName,
                required String lastName,
                required String role,
                required String merchantCode,
                required String merchantName,
                required String depotCode,
                required String depotName,
                Value<DateTime?> lastLogin = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => AgentsCompanion.insert(
                id: id,
                agentCode: agentCode,
                firstName: firstName,
                lastName: lastName,
                role: role,
                merchantCode: merchantCode,
                merchantName: merchantName,
                depotCode: depotCode,
                depotName: depotName,
                lastLogin: lastLogin,
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

typedef $$AgentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AgentsTable,
      Agent,
      $$AgentsTableFilterComposer,
      $$AgentsTableOrderingComposer,
      $$AgentsTableAnnotationComposer,
      $$AgentsTableCreateCompanionBuilder,
      $$AgentsTableUpdateCompanionBuilder,
      (Agent, BaseReferences<_$AppDatabase, $AgentsTable, Agent>),
      Agent,
      PrefetchHooks Function()
    >;
typedef $$RoutesTableCreateCompanionBuilder =
    RoutesCompanion Function({
      Value<int> id,
      required String serverId,
      required String routeCode,
      required String routeName,
      required String origin,
      required String destination,
      required double fare,
      required int distanceKm,
      Value<bool> isActive,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$RoutesTableUpdateCompanionBuilder =
    RoutesCompanion Function({
      Value<int> id,
      Value<String> serverId,
      Value<String> routeCode,
      Value<String> routeName,
      Value<String> origin,
      Value<String> destination,
      Value<double> fare,
      Value<int> distanceKm,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$RoutesTableFilterComposer
    extends Composer<_$AppDatabase, $RoutesTable> {
  $$RoutesTableFilterComposer({
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

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routeCode => $composableBuilder(
    column: $table.routeCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routeName => $composableBuilder(
    column: $table.routeName,
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

  ColumnFilters<double> get fare => $composableBuilder(
    column: $table.fare,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
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

class $$RoutesTableOrderingComposer
    extends Composer<_$AppDatabase, $RoutesTable> {
  $$RoutesTableOrderingComposer({
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

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routeCode => $composableBuilder(
    column: $table.routeCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routeName => $composableBuilder(
    column: $table.routeName,
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

  ColumnOrderings<double> get fare => $composableBuilder(
    column: $table.fare,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
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

class $$RoutesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoutesTable> {
  $$RoutesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get routeCode =>
      $composableBuilder(column: $table.routeCode, builder: (column) => column);

  GeneratedColumn<String> get routeName =>
      $composableBuilder(column: $table.routeName, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fare =>
      $composableBuilder(column: $table.fare, builder: (column) => column);

  GeneratedColumn<int> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$RoutesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoutesTable,
          Route,
          $$RoutesTableFilterComposer,
          $$RoutesTableOrderingComposer,
          $$RoutesTableAnnotationComposer,
          $$RoutesTableCreateCompanionBuilder,
          $$RoutesTableUpdateCompanionBuilder,
          (Route, BaseReferences<_$AppDatabase, $RoutesTable, Route>),
          Route,
          PrefetchHooks Function()
        > {
  $$RoutesTableTableManager(_$AppDatabase db, $RoutesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoutesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoutesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoutesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> serverId = const Value.absent(),
                Value<String> routeCode = const Value.absent(),
                Value<String> routeName = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<String> destination = const Value.absent(),
                Value<double> fare = const Value.absent(),
                Value<int> distanceKm = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => RoutesCompanion(
                id: id,
                serverId: serverId,
                routeCode: routeCode,
                routeName: routeName,
                origin: origin,
                destination: destination,
                fare: fare,
                distanceKm: distanceKm,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String serverId,
                required String routeCode,
                required String routeName,
                required String origin,
                required String destination,
                required double fare,
                required int distanceKm,
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => RoutesCompanion.insert(
                id: id,
                serverId: serverId,
                routeCode: routeCode,
                routeName: routeName,
                origin: origin,
                destination: destination,
                fare: fare,
                distanceKm: distanceKm,
                isActive: isActive,
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

typedef $$RoutesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoutesTable,
      Route,
      $$RoutesTableFilterComposer,
      $$RoutesTableOrderingComposer,
      $$RoutesTableAnnotationComposer,
      $$RoutesTableCreateCompanionBuilder,
      $$RoutesTableUpdateCompanionBuilder,
      (Route, BaseReferences<_$AppDatabase, $RoutesTable, Route>),
      Route,
      PrefetchHooks Function()
    >;
typedef $$FleetsTableCreateCompanionBuilder =
    FleetsCompanion Function({
      Value<int> id,
      required String serverId,
      required String number,
      required String depotId,
      Value<bool> isActive,
      required DateTime cachedAt,
      required DateTime updatedAt,
    });
typedef $$FleetsTableUpdateCompanionBuilder =
    FleetsCompanion Function({
      Value<int> id,
      Value<String> serverId,
      Value<String> number,
      Value<String> depotId,
      Value<bool> isActive,
      Value<DateTime> cachedAt,
      Value<DateTime> updatedAt,
    });

class $$FleetsTableFilterComposer
    extends Composer<_$AppDatabase, $FleetsTable> {
  $$FleetsTableFilterComposer({
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

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get depotId => $composableBuilder(
    column: $table.depotId,
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

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FleetsTableOrderingComposer
    extends Composer<_$AppDatabase, $FleetsTable> {
  $$FleetsTableOrderingComposer({
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

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get depotId => $composableBuilder(
    column: $table.depotId,
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

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FleetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FleetsTable> {
  $$FleetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get depotId =>
      $composableBuilder(column: $table.depotId, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FleetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FleetsTable,
          Fleet,
          $$FleetsTableFilterComposer,
          $$FleetsTableOrderingComposer,
          $$FleetsTableAnnotationComposer,
          $$FleetsTableCreateCompanionBuilder,
          $$FleetsTableUpdateCompanionBuilder,
          (Fleet, BaseReferences<_$AppDatabase, $FleetsTable, Fleet>),
          Fleet,
          PrefetchHooks Function()
        > {
  $$FleetsTableTableManager(_$AppDatabase db, $FleetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FleetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FleetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FleetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> serverId = const Value.absent(),
                Value<String> number = const Value.absent(),
                Value<String> depotId = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => FleetsCompanion(
                id: id,
                serverId: serverId,
                number: number,
                depotId: depotId,
                isActive: isActive,
                cachedAt: cachedAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String serverId,
                required String number,
                required String depotId,
                Value<bool> isActive = const Value.absent(),
                required DateTime cachedAt,
                required DateTime updatedAt,
              }) => FleetsCompanion.insert(
                id: id,
                serverId: serverId,
                number: number,
                depotId: depotId,
                isActive: isActive,
                cachedAt: cachedAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FleetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FleetsTable,
      Fleet,
      $$FleetsTableFilterComposer,
      $$FleetsTableOrderingComposer,
      $$FleetsTableAnnotationComposer,
      $$FleetsTableCreateCompanionBuilder,
      $$FleetsTableUpdateCompanionBuilder,
      (Fleet, BaseReferences<_$AppDatabase, $FleetsTable, Fleet>),
      Fleet,
      PrefetchHooks Function()
    >;
typedef $$TripsTableCreateCompanionBuilder =
    TripsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      required String localId,
      required String tripCode,
      required String routeId,
      required String fleetId,
      required String busNumber,
      required String driverName,
      required DateTime departureTime,
      Value<DateTime?> arrivalTime,
      required String status,
      required int totalSeats,
      required int availableSeats,
      required String agentId,
      required String agentCode,
      Value<bool> startedOffline,
      Value<bool> isSynced,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$TripsTableUpdateCompanionBuilder =
    TripsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      Value<String> localId,
      Value<String> tripCode,
      Value<String> routeId,
      Value<String> fleetId,
      Value<String> busNumber,
      Value<String> driverName,
      Value<DateTime> departureTime,
      Value<DateTime?> arrivalTime,
      Value<String> status,
      Value<int> totalSeats,
      Value<int> availableSeats,
      Value<String> agentId,
      Value<String> agentCode,
      Value<bool> startedOffline,
      Value<bool> isSynced,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$TripsTableFilterComposer extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableFilterComposer({
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

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tripCode => $composableBuilder(
    column: $table.tripCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routeId => $composableBuilder(
    column: $table.routeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fleetId => $composableBuilder(
    column: $table.fleetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get busNumber => $composableBuilder(
    column: $table.busNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get driverName => $composableBuilder(
    column: $table.driverName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get departureTime => $composableBuilder(
    column: $table.departureTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get arrivalTime => $composableBuilder(
    column: $table.arrivalTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSeats => $composableBuilder(
    column: $table.totalSeats,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get availableSeats => $composableBuilder(
    column: $table.availableSeats,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agentId => $composableBuilder(
    column: $table.agentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agentCode => $composableBuilder(
    column: $table.agentCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get startedOffline => $composableBuilder(
    column: $table.startedOffline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
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

class $$TripsTableOrderingComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableOrderingComposer({
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

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tripCode => $composableBuilder(
    column: $table.tripCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routeId => $composableBuilder(
    column: $table.routeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fleetId => $composableBuilder(
    column: $table.fleetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get busNumber => $composableBuilder(
    column: $table.busNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get driverName => $composableBuilder(
    column: $table.driverName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get departureTime => $composableBuilder(
    column: $table.departureTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get arrivalTime => $composableBuilder(
    column: $table.arrivalTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSeats => $composableBuilder(
    column: $table.totalSeats,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get availableSeats => $composableBuilder(
    column: $table.availableSeats,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agentId => $composableBuilder(
    column: $table.agentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agentCode => $composableBuilder(
    column: $table.agentCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get startedOffline => $composableBuilder(
    column: $table.startedOffline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
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

class $$TripsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get tripCode =>
      $composableBuilder(column: $table.tripCode, builder: (column) => column);

  GeneratedColumn<String> get routeId =>
      $composableBuilder(column: $table.routeId, builder: (column) => column);

  GeneratedColumn<String> get fleetId =>
      $composableBuilder(column: $table.fleetId, builder: (column) => column);

  GeneratedColumn<String> get busNumber =>
      $composableBuilder(column: $table.busNumber, builder: (column) => column);

  GeneratedColumn<String> get driverName => $composableBuilder(
    column: $table.driverName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get departureTime => $composableBuilder(
    column: $table.departureTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get arrivalTime => $composableBuilder(
    column: $table.arrivalTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get totalSeats => $composableBuilder(
    column: $table.totalSeats,
    builder: (column) => column,
  );

  GeneratedColumn<int> get availableSeats => $composableBuilder(
    column: $table.availableSeats,
    builder: (column) => column,
  );

  GeneratedColumn<String> get agentId =>
      $composableBuilder(column: $table.agentId, builder: (column) => column);

  GeneratedColumn<String> get agentCode =>
      $composableBuilder(column: $table.agentCode, builder: (column) => column);

  GeneratedColumn<bool> get startedOffline => $composableBuilder(
    column: $table.startedOffline,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TripsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TripsTable,
          Trip,
          $$TripsTableFilterComposer,
          $$TripsTableOrderingComposer,
          $$TripsTableAnnotationComposer,
          $$TripsTableCreateCompanionBuilder,
          $$TripsTableUpdateCompanionBuilder,
          (Trip, BaseReferences<_$AppDatabase, $TripsTable, Trip>),
          Trip,
          PrefetchHooks Function()
        > {
  $$TripsTableTableManager(_$AppDatabase db, $TripsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TripsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TripsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TripsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> localId = const Value.absent(),
                Value<String> tripCode = const Value.absent(),
                Value<String> routeId = const Value.absent(),
                Value<String> fleetId = const Value.absent(),
                Value<String> busNumber = const Value.absent(),
                Value<String> driverName = const Value.absent(),
                Value<DateTime> departureTime = const Value.absent(),
                Value<DateTime?> arrivalTime = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> totalSeats = const Value.absent(),
                Value<int> availableSeats = const Value.absent(),
                Value<String> agentId = const Value.absent(),
                Value<String> agentCode = const Value.absent(),
                Value<bool> startedOffline = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => TripsCompanion(
                id: id,
                serverId: serverId,
                localId: localId,
                tripCode: tripCode,
                routeId: routeId,
                fleetId: fleetId,
                busNumber: busNumber,
                driverName: driverName,
                departureTime: departureTime,
                arrivalTime: arrivalTime,
                status: status,
                totalSeats: totalSeats,
                availableSeats: availableSeats,
                agentId: agentId,
                agentCode: agentCode,
                startedOffline: startedOffline,
                isSynced: isSynced,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                required String localId,
                required String tripCode,
                required String routeId,
                required String fleetId,
                required String busNumber,
                required String driverName,
                required DateTime departureTime,
                Value<DateTime?> arrivalTime = const Value.absent(),
                required String status,
                required int totalSeats,
                required int availableSeats,
                required String agentId,
                required String agentCode,
                Value<bool> startedOffline = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => TripsCompanion.insert(
                id: id,
                serverId: serverId,
                localId: localId,
                tripCode: tripCode,
                routeId: routeId,
                fleetId: fleetId,
                busNumber: busNumber,
                driverName: driverName,
                departureTime: departureTime,
                arrivalTime: arrivalTime,
                status: status,
                totalSeats: totalSeats,
                availableSeats: availableSeats,
                agentId: agentId,
                agentCode: agentCode,
                startedOffline: startedOffline,
                isSynced: isSynced,
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

typedef $$TripsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TripsTable,
      Trip,
      $$TripsTableFilterComposer,
      $$TripsTableOrderingComposer,
      $$TripsTableAnnotationComposer,
      $$TripsTableCreateCompanionBuilder,
      $$TripsTableUpdateCompanionBuilder,
      (Trip, BaseReferences<_$AppDatabase, $TripsTable, Trip>),
      Trip,
      PrefetchHooks Function()
    >;
typedef $$TicketsTableCreateCompanionBuilder =
    TicketsCompanion Function({
      Value<int> id,
      required String localId,
      Value<String?> serverId,
      Value<String?> tripLocalId,
      Value<String?> tripServerId,
      Value<String?> serialNumber,
      required String ticketCategory,
      required String currency,
      required double amount,
      Value<String?> departure,
      Value<String?> destination,
      Value<String?> linkedPassengerTicketId,
      required String agentId,
      required String agentCode,
      required DateTime issuedAt,
      Value<bool> issuedOffline,
      Value<bool> isSynced,
      Value<String?> syncError,
      Value<DateTime?> lastSyncAttemptAt,
    });
typedef $$TicketsTableUpdateCompanionBuilder =
    TicketsCompanion Function({
      Value<int> id,
      Value<String> localId,
      Value<String?> serverId,
      Value<String?> tripLocalId,
      Value<String?> tripServerId,
      Value<String?> serialNumber,
      Value<String> ticketCategory,
      Value<String> currency,
      Value<double> amount,
      Value<String?> departure,
      Value<String?> destination,
      Value<String?> linkedPassengerTicketId,
      Value<String> agentId,
      Value<String> agentCode,
      Value<DateTime> issuedAt,
      Value<bool> issuedOffline,
      Value<bool> isSynced,
      Value<String?> syncError,
      Value<DateTime?> lastSyncAttemptAt,
    });

class $$TicketsTableFilterComposer
    extends Composer<_$AppDatabase, $TicketsTable> {
  $$TicketsTableFilterComposer({
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

  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tripLocalId => $composableBuilder(
    column: $table.tripLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tripServerId => $composableBuilder(
    column: $table.tripServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
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

  ColumnFilters<String> get linkedPassengerTicketId => $composableBuilder(
    column: $table.linkedPassengerTicketId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agentId => $composableBuilder(
    column: $table.agentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agentCode => $composableBuilder(
    column: $table.agentCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get issuedAt => $composableBuilder(
    column: $table.issuedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get issuedOffline => $composableBuilder(
    column: $table.issuedOffline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAttemptAt => $composableBuilder(
    column: $table.lastSyncAttemptAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TicketsTableOrderingComposer
    extends Composer<_$AppDatabase, $TicketsTable> {
  $$TicketsTableOrderingComposer({
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

  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tripLocalId => $composableBuilder(
    column: $table.tripLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tripServerId => $composableBuilder(
    column: $table.tripServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
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

  ColumnOrderings<String> get linkedPassengerTicketId => $composableBuilder(
    column: $table.linkedPassengerTicketId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agentId => $composableBuilder(
    column: $table.agentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agentCode => $composableBuilder(
    column: $table.agentCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get issuedAt => $composableBuilder(
    column: $table.issuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get issuedOffline => $composableBuilder(
    column: $table.issuedOffline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAttemptAt => $composableBuilder(
    column: $table.lastSyncAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TicketsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TicketsTable> {
  $$TicketsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get tripLocalId => $composableBuilder(
    column: $table.tripLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tripServerId => $composableBuilder(
    column: $table.tripServerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => column,
  );

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

  GeneratedColumn<String> get linkedPassengerTicketId => $composableBuilder(
    column: $table.linkedPassengerTicketId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get agentId =>
      $composableBuilder(column: $table.agentId, builder: (column) => column);

  GeneratedColumn<String> get agentCode =>
      $composableBuilder(column: $table.agentCode, builder: (column) => column);

  GeneratedColumn<DateTime> get issuedAt =>
      $composableBuilder(column: $table.issuedAt, builder: (column) => column);

  GeneratedColumn<bool> get issuedOffline => $composableBuilder(
    column: $table.issuedOffline,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncAttemptAt => $composableBuilder(
    column: $table.lastSyncAttemptAt,
    builder: (column) => column,
  );
}

class $$TicketsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TicketsTable,
          Ticket,
          $$TicketsTableFilterComposer,
          $$TicketsTableOrderingComposer,
          $$TicketsTableAnnotationComposer,
          $$TicketsTableCreateCompanionBuilder,
          $$TicketsTableUpdateCompanionBuilder,
          (Ticket, BaseReferences<_$AppDatabase, $TicketsTable, Ticket>),
          Ticket,
          PrefetchHooks Function()
        > {
  $$TicketsTableTableManager(_$AppDatabase db, $TicketsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TicketsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TicketsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TicketsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> localId = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String?> tripLocalId = const Value.absent(),
                Value<String?> tripServerId = const Value.absent(),
                Value<String?> serialNumber = const Value.absent(),
                Value<String> ticketCategory = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String?> departure = const Value.absent(),
                Value<String?> destination = const Value.absent(),
                Value<String?> linkedPassengerTicketId = const Value.absent(),
                Value<String> agentId = const Value.absent(),
                Value<String> agentCode = const Value.absent(),
                Value<DateTime> issuedAt = const Value.absent(),
                Value<bool> issuedOffline = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime?> lastSyncAttemptAt = const Value.absent(),
              }) => TicketsCompanion(
                id: id,
                localId: localId,
                serverId: serverId,
                tripLocalId: tripLocalId,
                tripServerId: tripServerId,
                serialNumber: serialNumber,
                ticketCategory: ticketCategory,
                currency: currency,
                amount: amount,
                departure: departure,
                destination: destination,
                linkedPassengerTicketId: linkedPassengerTicketId,
                agentId: agentId,
                agentCode: agentCode,
                issuedAt: issuedAt,
                issuedOffline: issuedOffline,
                isSynced: isSynced,
                syncError: syncError,
                lastSyncAttemptAt: lastSyncAttemptAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String localId,
                Value<String?> serverId = const Value.absent(),
                Value<String?> tripLocalId = const Value.absent(),
                Value<String?> tripServerId = const Value.absent(),
                Value<String?> serialNumber = const Value.absent(),
                required String ticketCategory,
                required String currency,
                required double amount,
                Value<String?> departure = const Value.absent(),
                Value<String?> destination = const Value.absent(),
                Value<String?> linkedPassengerTicketId = const Value.absent(),
                required String agentId,
                required String agentCode,
                required DateTime issuedAt,
                Value<bool> issuedOffline = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime?> lastSyncAttemptAt = const Value.absent(),
              }) => TicketsCompanion.insert(
                id: id,
                localId: localId,
                serverId: serverId,
                tripLocalId: tripLocalId,
                tripServerId: tripServerId,
                serialNumber: serialNumber,
                ticketCategory: ticketCategory,
                currency: currency,
                amount: amount,
                departure: departure,
                destination: destination,
                linkedPassengerTicketId: linkedPassengerTicketId,
                agentId: agentId,
                agentCode: agentCode,
                issuedAt: issuedAt,
                issuedOffline: issuedOffline,
                isSynced: isSynced,
                syncError: syncError,
                lastSyncAttemptAt: lastSyncAttemptAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TicketsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TicketsTable,
      Ticket,
      $$TicketsTableFilterComposer,
      $$TicketsTableOrderingComposer,
      $$TicketsTableAnnotationComposer,
      $$TicketsTableCreateCompanionBuilder,
      $$TicketsTableUpdateCompanionBuilder,
      (Ticket, BaseReferences<_$AppDatabase, $TicketsTable, Ticket>),
      Ticket,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      required String entityType,
      required int entityId,
      required String operation,
      required String data,
      Value<int> retryCount,
      required DateTime createdAt,
      Value<DateTime?> lastAttemptAt,
      Value<String?> error,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      Value<String> entityType,
      Value<int> entityId,
      Value<String> operation,
      Value<String> data,
      Value<int> retryCount,
      Value<DateTime> createdAt,
      Value<DateTime?> lastAttemptAt,
      Value<String?> error,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
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

  ColumnFilters<int> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
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

  ColumnOrderings<int> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
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

  GeneratedColumn<int> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueData,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueData,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
          ),
          SyncQueueData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<int> entityId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> error = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                data: data,
                retryCount: retryCount,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                error: error,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entityType,
                required int entityId,
                required String operation,
                required String data,
                Value<int> retryCount = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> error = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                id: id,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                data: data,
                retryCount: retryCount,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                error: error,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueData,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueData,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
      ),
      SyncQueueData,
      PrefetchHooks Function()
    >;
typedef $$CacheMetadataTableCreateCompanionBuilder =
    CacheMetadataCompanion Function({
      required String dataType,
      required DateTime lastCachedAt,
      Value<int> recordCount,
      Value<int> rowid,
    });
typedef $$CacheMetadataTableUpdateCompanionBuilder =
    CacheMetadataCompanion Function({
      Value<String> dataType,
      Value<DateTime> lastCachedAt,
      Value<int> recordCount,
      Value<int> rowid,
    });

class $$CacheMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $CacheMetadataTable> {
  $$CacheMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get dataType => $composableBuilder(
    column: $table.dataType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastCachedAt => $composableBuilder(
    column: $table.lastCachedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordCount => $composableBuilder(
    column: $table.recordCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CacheMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $CacheMetadataTable> {
  $$CacheMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get dataType => $composableBuilder(
    column: $table.dataType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastCachedAt => $composableBuilder(
    column: $table.lastCachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordCount => $composableBuilder(
    column: $table.recordCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CacheMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $CacheMetadataTable> {
  $$CacheMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get dataType =>
      $composableBuilder(column: $table.dataType, builder: (column) => column);

  GeneratedColumn<DateTime> get lastCachedAt => $composableBuilder(
    column: $table.lastCachedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recordCount => $composableBuilder(
    column: $table.recordCount,
    builder: (column) => column,
  );
}

class $$CacheMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CacheMetadataTable,
          CacheMetadataData,
          $$CacheMetadataTableFilterComposer,
          $$CacheMetadataTableOrderingComposer,
          $$CacheMetadataTableAnnotationComposer,
          $$CacheMetadataTableCreateCompanionBuilder,
          $$CacheMetadataTableUpdateCompanionBuilder,
          (
            CacheMetadataData,
            BaseReferences<
              _$AppDatabase,
              $CacheMetadataTable,
              CacheMetadataData
            >,
          ),
          CacheMetadataData,
          PrefetchHooks Function()
        > {
  $$CacheMetadataTableTableManager(_$AppDatabase db, $CacheMetadataTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CacheMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CacheMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CacheMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> dataType = const Value.absent(),
                Value<DateTime> lastCachedAt = const Value.absent(),
                Value<int> recordCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheMetadataCompanion(
                dataType: dataType,
                lastCachedAt: lastCachedAt,
                recordCount: recordCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String dataType,
                required DateTime lastCachedAt,
                Value<int> recordCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheMetadataCompanion.insert(
                dataType: dataType,
                lastCachedAt: lastCachedAt,
                recordCount: recordCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CacheMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CacheMetadataTable,
      CacheMetadataData,
      $$CacheMetadataTableFilterComposer,
      $$CacheMetadataTableOrderingComposer,
      $$CacheMetadataTableAnnotationComposer,
      $$CacheMetadataTableCreateCompanionBuilder,
      $$CacheMetadataTableUpdateCompanionBuilder,
      (
        CacheMetadataData,
        BaseReferences<_$AppDatabase, $CacheMetadataTable, CacheMetadataData>,
      ),
      CacheMetadataData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db, _db.devices);
  $$AgentsTableTableManager get agents =>
      $$AgentsTableTableManager(_db, _db.agents);
  $$RoutesTableTableManager get routes =>
      $$RoutesTableTableManager(_db, _db.routes);
  $$FleetsTableTableManager get fleets =>
      $$FleetsTableTableManager(_db, _db.fleets);
  $$TripsTableTableManager get trips =>
      $$TripsTableTableManager(_db, _db.trips);
  $$TicketsTableTableManager get tickets =>
      $$TicketsTableTableManager(_db, _db.tickets);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$CacheMetadataTableTableManager get cacheMetadata =>
      $$CacheMetadataTableTableManager(_db, _db.cacheMetadata);
}
