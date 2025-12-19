enum UserRole {
  student,
  admin;

  static UserRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'admin':
      case 'dsa':
        return UserRole.admin;
      default:
        return UserRole.student;
    }
  }

  String get label {
    return this == UserRole.admin ? 'admin' : 'student';
  }
}
