class Student {
  final int id;
  final String name;
  final String email;
  final String? regNo;
  final String? semester;

  Student({
    required this.id,
    required this.name,
    required this.email,
    this.regNo,
    this.semester,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      regNo: json['reg_no'],
      semester: json['semester'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'reg_no': regNo,
      'semester': semester,
    };
  }
}
