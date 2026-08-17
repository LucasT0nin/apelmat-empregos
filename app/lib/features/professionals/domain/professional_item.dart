class ProfessionalItem {
  const ProfessionalItem({
    required this.userId,
    required this.displayName,
    required this.headline,
    required this.bio,
    required this.city,
    required this.state,
    required this.verifiedByApelmat,
    required this.catalogStatus,
    required this.catalogStatusLabel,
    required this.hasResume,
    required this.objectives,
    required this.yearsOfExperience,
    this.email,
    this.phone,
    this.contactRequestId,
    this.contactRequestStatus,
    this.contactRequestStatusLabel,
    this.resumeDownloadUrl,
  });

  factory ProfessionalItem.fromJson(Map<String, dynamic> json) {
    return ProfessionalItem(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      headline: json['headline'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      verifiedByApelmat: json['verified_by_apelmat'] as bool? ?? false,
      catalogStatus: json['catalog_status'] as String? ?? 'draft',
      catalogStatusLabel: json['catalog_status_label'] as String? ?? '',
      hasResume: json['has_resume'] as bool? ?? false,
      objectives:
          (json['objectives'] as List<dynamic>? ?? [])
              .map(
                (item) => ProfessionalObjectiveSummary.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList(),
      yearsOfExperience: json['years_of_experience'] as int? ?? 0,
      contactRequestId: json['contact_request_id'] as String?,
      contactRequestStatus: json['contact_request_status'] as String?,
      contactRequestStatusLabel:
          json['contact_request_status_label'] as String?,
      resumeDownloadUrl: json['resume_download_url'] as String?,
    );
  }

  final String userId;
  final String displayName;
  final String? email;
  final String? phone;
  final String headline;
  final String bio;
  final String city;
  final String state;
  final bool verifiedByApelmat;
  final String catalogStatus;
  final String catalogStatusLabel;
  final bool hasResume;
  final List<ProfessionalObjectiveSummary> objectives;
  final int yearsOfExperience;
  final String? contactRequestId;
  final String? contactRequestStatus;
  final String? contactRequestStatusLabel;
  final String? resumeDownloadUrl;

  bool get contactReleased => contactRequestStatus == 'approved';
  bool get contactPending => contactRequestStatus == 'pending';
}

class ProfessionalObjectiveSummary {
  const ProfessionalObjectiveSummary({
    required this.id,
    required this.role,
    required this.roleLabel,
    required this.summary,
    required this.salaryExpectation,
    required this.availability,
    required this.answers,
    required this.status,
    required this.statusLabel,
  });

  factory ProfessionalObjectiveSummary.fromJson(Map<String, dynamic> json) {
    return ProfessionalObjectiveSummary(
      id: json['id'] as String,
      role: json['role'] as String,
      roleLabel: json['role_label'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      salaryExpectation: json['salary_expectation'] as String? ?? '',
      availability: json['availability'] as String? ?? '',
      answers: (json['answers'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      status: json['status'] as String? ?? 'review',
      statusLabel: json['status_label'] as String? ?? 'Em analise',
    );
  }

  final String id;
  final String role;
  final String roleLabel;
  final String summary;
  final String salaryExpectation;
  final String availability;
  final Map<String, String> answers;
  final String status;
  final String statusLabel;
}
