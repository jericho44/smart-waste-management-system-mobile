/// State of profile operations (editing profile info and changing password).
class ProfileState {
  final bool isUpdatingProfile;
  final bool isChangingPassword;
  final Map<String, String> profileErrors;
  final Map<String, String> passwordErrors;
  final String? profileSuccessMessage;
  final String? passwordSuccessMessage;
  final String? errorMessage;

  const ProfileState({
    this.isUpdatingProfile = false,
    this.isChangingPassword = false,
    this.profileErrors = const {},
    this.passwordErrors = const {},
    this.profileSuccessMessage,
    this.passwordSuccessMessage,
    this.errorMessage,
  });

  factory ProfileState.initial() => const ProfileState();

  String? profileErrorFor(String field) => profileErrors[field];
  String? passwordErrorFor(String field) => passwordErrors[field];

  ProfileState copyWith({
    bool? isUpdatingProfile,
    bool? isChangingPassword,
    Map<String, String>? profileErrors,
    Map<String, String>? passwordErrors,
    String? profileSuccessMessage,
    bool clearProfileSuccess = false,
    String? passwordSuccessMessage,
    bool clearPasswordSuccess = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      isUpdatingProfile: isUpdatingProfile ?? this.isUpdatingProfile,
      isChangingPassword: isChangingPassword ?? this.isChangingPassword,
      profileErrors: profileErrors ?? this.profileErrors,
      passwordErrors: passwordErrors ?? this.passwordErrors,
      profileSuccessMessage: clearProfileSuccess
          ? null
          : (profileSuccessMessage ?? this.profileSuccessMessage),
      passwordSuccessMessage: clearPasswordSuccess
          ? null
          : (passwordSuccessMessage ?? this.passwordSuccessMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
