class RegisterStudentRequest {
  RegisterStudentRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.cutoff,
    required this.category,
    required this.preferredCourse,
  });

  final String name;
  final String email;
  final String password;
  final double cutoff;
  final String category;
  final String preferredCourse;
}
