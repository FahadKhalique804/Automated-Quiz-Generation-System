class Course {
  final int id;
  final String code;
  final String title;

  Course({
    required this.id,
    required this.code,
    required this.title,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      code: json['code'],
      title: json['title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'title': title,
    };
  }
}
