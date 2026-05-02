// lib/data/models/share_code.dart

import 'shop_package.dart';

enum ShareCodeStatus { pending, redeemed, expired }

class ShareCode {
  final String code;
  final String packageId;
  final RewardBundle giftContents;
  final ShareCodeStatus status;
  final DateTime createdAt;

  const ShareCode({
    required this.code,
    required this.packageId,
    required this.giftContents,
    required this.status,
    required this.createdAt,
  });

  ShareCode copyWith({
    String? code,
    String? packageId,
    RewardBundle? giftContents,
    ShareCodeStatus? status,
    DateTime? createdAt,
  }) =>
      ShareCode(
        code: code ?? this.code,
        packageId: packageId ?? this.packageId,
        giftContents: giftContents ?? this.giftContents,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShareCode &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          packageId == other.packageId &&
          giftContents == other.giftContents &&
          status == other.status &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(code, packageId, giftContents, status, createdAt);

  Map<String, dynamic> toJson() => {
        'code': code,
        'packageId': packageId,
        'giftContents': {
          'lives': giftContents.lives,
          'bomb2': giftContents.bomb2,
          'bomb3': giftContents.bomb3,
          'undo1': giftContents.undo1,
          'undo3': giftContents.undo3,
        },
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ShareCode.fromJson(Map<String, dynamic> json) {
    final g = json['giftContents'] as Map<String, dynamic>;
    return ShareCode(
      code: json['code'] as String,
      packageId: json['packageId'] as String,
      giftContents: RewardBundle(
        lives: g['lives'] as int,
        bomb2: g['bomb2'] as int,
        bomb3: g['bomb3'] as int,
        undo1: g['undo1'] as int,
        undo3: g['undo3'] as int,
      ),
      status: ShareCodeStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
