enum AppRole { customer, assistant }

class UserModel {
  final String id;
  final String email;
  final String? phone;
  final String? name;
  final String? avatarUrl;
  final List<String> roles;
  final String? activeRole;
  final String? referralCode;
  final double walletBalance;
  final bool isOnline;
  final bool emailVerified;
  final bool profileComplete;
  final AssistantProfileModel? assistantProfile;

  const UserModel({
    required this.id,
    required this.email,
    this.phone,
    this.name,
    this.avatarUrl,
    required this.roles,
    this.activeRole,
    this.referralCode,
    this.walletBalance = 0,
    this.isOnline = false,
    this.emailVerified = false,
    this.profileComplete = false,
    this.assistantProfile,
  });

  UserModel copyWith({
    String? name,
    String? phone,
    String? avatarUrl,
    bool? profileComplete,
    String? activeRole,
    bool? emailVerified,
  }) =>
      UserModel(
        id: id,
        email: email,
        phone: phone ?? this.phone,
        name: name ?? this.name,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        roles: roles,
        activeRole: activeRole ?? this.activeRole,
        referralCode: referralCode,
        walletBalance: walletBalance,
        isOnline: isOnline,
        emailVerified: emailVerified ?? this.emailVerified,
        profileComplete: profileComplete ?? this.profileComplete,
        assistantProfile: assistantProfile,
      );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final ap = json['assistantProfile'] as Map<String, dynamic>?;
    final verified = json['emailVerified'] as bool? ?? false;
    final name = json['name'] as String?;
    return UserModel(
      id: json['id'] as String,
      email: (json['email'] as String?) ?? '',
      phone: json['phone'] as String?,
      name: name,
      avatarUrl: json['avatarUrl'] as String?,
      roles: List<String>.from(json['roles'] ?? []),
      activeRole: json['activeRole'] as String?,
      referralCode: json['referralCode'] as String?,
      walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0,
      isOnline: json['isOnline'] as bool? ?? false,
      emailVerified: verified,
      profileComplete: json['profileComplete'] as bool? ??
          (verified &&
              (name?.trim().isNotEmpty == true) &&
              (json['phone'] as String?)?.length == 10),
      assistantProfile:
          ap != null ? AssistantProfileModel.fromJson(ap) : null,
    );
  }

  AppRole? get role =>
      activeRole == 'assistant' ? AppRole.assistant : AppRole.customer;

  bool get hasCustomer => roles.contains('customer');
  bool get hasAssistant => roles.contains('assistant');
}

class AssistantProfileModel {
  final double rating;
  final int totalJobs;
  final int profileCompletion;
  final String? assistantCode;
  final bool adminVerified;

  const AssistantProfileModel({
    required this.rating,
    required this.totalJobs,
    required this.profileCompletion,
    this.assistantCode,
    this.adminVerified = false,
  });

  factory AssistantProfileModel.fromJson(Map<String, dynamic> json) =>
      AssistantProfileModel(
        rating: (json['rating'] as num?)?.toDouble() ?? 5,
        totalJobs: json['totalJobs'] as int? ?? 0,
        profileCompletion: json['profileCompletion'] as int? ?? 0,
        assistantCode: json['assistantCode'] as String?,
        adminVerified: json['adminVerified'] as bool? ?? false,
      );
}
