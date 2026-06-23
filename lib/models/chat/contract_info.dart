/// 合同信息结构体
///
/// 存储从合同中提取的关键信息，由系统内置工具 [contract_inspect] 写入。
class ContractInfo {
  /// 合同名称/文件标题
  final String name;

  /// 签署方列表（甲方、乙方等）
  final List<ContractParty> parties;

  /// 收支条款
  final String? paymentClause;

  /// 收支计划
  final String? paymentSchedule;

  /// 违约条款
  final String? breachClause;

  /// 违约责任
  final String? liabilityClause;

  /// 合同起始时间
  final String? startDate;

  /// 合同结束时间
  final String? endDate;

  /// 签订时间（合同签署日期）
  final String? signingDate;

  /// 合同类型
  final String? contractType;

  const ContractInfo({
    required this.name,
    this.parties = const [],
    this.paymentClause,
    this.paymentSchedule,
    this.breachClause,
    this.liabilityClause,
    this.startDate,
    this.endDate,
    this.signingDate,
    this.contractType,
  });

  ContractInfo copyWith({
    String? name,
    List<ContractParty>? parties,
    String? paymentClause,
    bool clearPaymentClause = false,
    String? paymentSchedule,
    bool clearPaymentSchedule = false,
    String? breachClause,
    bool clearBreachClause = false,
    String? liabilityClause,
    bool clearLiabilityClause = false,
    String? startDate,
    bool clearStartDate = false,
    String? endDate,
    bool clearEndDate = false,
    String? signingDate,
    bool clearSigningDate = false,
    String? contractType,
    bool clearContractType = false,
  }) {
    return ContractInfo(
      name: name ?? this.name,
      parties: parties ?? this.parties,
      paymentClause:
          clearPaymentClause ? null : (paymentClause ?? this.paymentClause),
      paymentSchedule:
          clearPaymentSchedule
              ? null
              : (paymentSchedule ?? this.paymentSchedule),
      breachClause:
          clearBreachClause ? null : (breachClause ?? this.breachClause),
      liabilityClause:
          clearLiabilityClause
              ? null
              : (liabilityClause ?? this.liabilityClause),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      signingDate:
          clearSigningDate ? null : (signingDate ?? this.signingDate),
      contractType:
          clearContractType ? null : (contractType ?? this.contractType),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'parties': parties.map((p) => p.toJson()).toList(),
      if (paymentClause != null) 'paymentClause': paymentClause,
      if (paymentSchedule != null) 'paymentSchedule': paymentSchedule,
      if (breachClause != null) 'breachClause': breachClause,
      if (liabilityClause != null) 'liabilityClause': liabilityClause,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (signingDate != null) 'signingDate': signingDate,
      if (contractType != null) 'contractType': contractType,
    };
  }

  factory ContractInfo.fromJson(Map<String, dynamic> json) {
    return ContractInfo(
      name: json['name'] as String? ?? '',
      parties:
          (json['parties'] as List<dynamic>?)
              ?.map(
                (p) => ContractParty.fromJson(p as Map<String, dynamic>),
              )
              .toList() ??
          [],
      paymentClause: json['paymentClause'] as String?,
      paymentSchedule: json['paymentSchedule'] as String?,
      breachClause: json['breachClause'] as String?,
      liabilityClause: json['liabilityClause'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      signingDate: json['signingDate'] as String?,
      contractType: json['contractType'] as String?,
    );
  }

  /// 序列化为 Markdown 格式
  String toMarkdown() {
    final buf = StringBuffer();
    buf.writeln('## $name');
    buf.writeln();
    if (contractType != null && contractType!.isNotEmpty) {
      buf.writeln('**合同类型**: $contractType');
      buf.writeln();
    }
    if (parties.isNotEmpty) {
      buf.writeln('**签署方**:');
      for (final p in parties) {
        buf.writeln('- **${p.role}**: ${p.name}');
        if (p.contact != null && p.contact!.isNotEmpty) {
          buf.writeln('  联系方式: ${p.contact}');
        }
        if (p.address != null && p.address!.isNotEmpty) {
          buf.writeln('  地址: ${p.address}');
        }
      }
      buf.writeln();
    }
    if (startDate != null || endDate != null || signingDate != null) {
      buf.writeln('**合同期限**:');
      if (startDate != null && startDate!.isNotEmpty) {
        buf.writeln('- 起始时间: $startDate');
      }
      if (endDate != null && endDate!.isNotEmpty) {
        buf.writeln('- 结束时间: $endDate');
      }
      if (signingDate != null && signingDate!.isNotEmpty) {
        buf.writeln('- 签订日期: $signingDate');
      }
      buf.writeln();
    }
    if (paymentClause != null && paymentClause!.isNotEmpty) {
      buf.writeln('**收支条款**:');
      buf.writeln(paymentClause);
      buf.writeln();
    }
    if (paymentSchedule != null && paymentSchedule!.isNotEmpty) {
      buf.writeln('**支付计划**:');
      buf.writeln(paymentSchedule);
      buf.writeln();
    }
    if (breachClause != null && breachClause!.isNotEmpty) {
      buf.writeln('**违约条款**:');
      buf.writeln(breachClause);
      buf.writeln();
    }
    if (liabilityClause != null && liabilityClause!.isNotEmpty) {
      buf.writeln('**违约责任**:');
      buf.writeln(liabilityClause);
      buf.writeln();
    }
    buf.writeln('---');
    buf.writeln();
    return buf.toString();
  }
}

/// 合同签署方
class ContractParty {
  /// 角色（如：甲方、乙方、丙方）
  final String role;

  /// 名称
  final String name;

  /// 联系信息
  final String? contact;

  /// 地址
  final String? address;

  const ContractParty({
    required this.role,
    required this.name,
    this.contact,
    this.address,
  });

  ContractParty copyWith({
    String? role,
    String? name,
    String? contact,
    String? address,
  }) {
    return ContractParty(
      role: role ?? this.role,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'name': name,
      if (contact != null) 'contact': contact,
      if (address != null) 'address': address,
    };
  }

  factory ContractParty.fromJson(Map<String, dynamic> json) {
    return ContractParty(
      role: json['role'] as String? ?? '',
      name: json['name'] as String? ?? '',
      contact: json['contact'] as String?,
      address: json['address'] as String?,
    );
  }
}
