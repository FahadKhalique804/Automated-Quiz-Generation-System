import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {

  static const String baseUrl =
      'http://192.222.18.77:8000'; // change the IP according to your connected WIFI IP

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- Auth ---
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to login: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  // --- Students ---
  static Future<List<dynamic>> getStudents() async {
    final url = Uri.parse('$baseUrl/students/');
    try {
      final response = await http.get(url, headers: await getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch students');
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching students: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> getStudent(int id) async {
    final url = Uri.parse('$baseUrl/students/$id');
    try {
      final response = await http.get(url, headers: await getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch student');
      }
    } catch (e) {
      throw Exception("Error fetching student: $e");
    }
  }

  static Future<void> addStudent(Map<String, dynamic> studentData) async {
    final url = Uri.parse('$baseUrl/students/');
    final response = await http.post(
      url,
      headers: await getHeaders(),
      body: jsonEncode({
        'name': studentData['name'],
        'email': studentData['email'],
        'password': studentData['password'] ?? 'student123',
        'reg_no': studentData['reg_no'],
        'semester': studentData['semester'],
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to add student: ${response.body}');
    }
  }

  static Future<void> updateStudent(
      int id, Map<String, dynamic> studentData) async {
    final url = Uri.parse('$baseUrl/students/$id');
    final response = await http.put(
      url,
      headers: await getHeaders(),
      body: jsonEncode({
        'name': studentData['name'],
        'email': studentData['email'],
        'reg_no': studentData['reg_no'],
        'semester': studentData['semester'],
        if (studentData['password'] != null &&
            studentData['password'].toString().isNotEmpty)
          'password': studentData['password'],
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update student: ${response.body}');
    }
  }

  static Future<void> deleteStudent(int id) async {
    final url = Uri.parse('$baseUrl/students/$id');
    final response = await http.delete(url, headers: await getHeaders());
    if (response.statusCode != 200) {
      throw Exception('Failed to delete student');
    }
  }

  // --- Teachers ---
  static Future<List<dynamic>> getTeachers() async {
    final url = Uri.parse('$baseUrl/teachers/');
    try {
      final response = await http.get(url, headers: await getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch teachers');
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching teachers: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> getTeacher(int id) async {
    final url = Uri.parse('$baseUrl/teachers/$id');
    try {
      final response = await http.get(url, headers: await getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch teacher');
      }
    } catch (e) {
      throw Exception("Error fetching teacher: $e");
    }
  }

  static Future<void> addTeacher(Map<String, dynamic> teacherData) async {
    final url = Uri.parse('$baseUrl/teachers/');
    final response = await http.post(
      url,
      headers: await getHeaders(),
      body: jsonEncode({
        'name': teacherData['name'],
        'email': teacherData['email'],
        'password': teacherData['password'] ?? 'teacher123',
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to add teacher: ${response.body}');
    }
  }

  static Future<void> updateTeacher(
      int id, Map<String, dynamic> teacherData) async {
    final url = Uri.parse('$baseUrl/teachers/$id');
    final response = await http.put(
      url,
      headers: await getHeaders(),
      body: jsonEncode({
        'name': teacherData['name'],
        'email': teacherData['email'],
        if (teacherData['password'] != null &&
            teacherData['password'].toString().isNotEmpty)
          'password': teacherData['password'],
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update teacher: ${response.body}');
    }
  }

  static Future<void> deleteTeacher(int id) async {
    final url = Uri.parse('$baseUrl/teachers/$id');
    final response = await http.delete(url, headers: await getHeaders());
    if (response.statusCode != 200) {
      throw Exception('Failed to delete teacher');
    }
  }

  // --- Lecture Notes (Upload) ---
  static Future<int> uploadLectureNote(
      String filePath, int courseId, int uploadedBy) async {
    final url = Uri.parse('$baseUrl/lecture-notes/');
    var request = http.MultipartRequest('POST', url);
    request.fields['course_id'] = courseId.toString();
    request.fields['uploaded_by'] = uploadedBy.toString();
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id'];
      } else {
        throw Exception('Upload failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Upload error: $e');
    }
  }

  static Future<List<dynamic>> getLectureNotes() async {
    final url = Uri.parse('$baseUrl/lecture-notes/');
    try {
      final response = await http.get(url, headers: await getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch lecture notes');
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching lecture notes: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getLectureNotesByCourse(int courseId) async {
    final url = Uri.parse('$baseUrl/lecture-notes/by-course/$courseId');
    try {
      final response = await http.get(url, headers: await getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch lecture notes for course');
      }
    } catch (e) {
      return [];
    }
  }

  static Future<void> deleteLectureNote(int id) async {
    final url = Uri.parse('$baseUrl/lecture-notes/$id');
    final response = await http.delete(url, headers: await getHeaders());
    if (response.statusCode != 200) {
      throw Exception('Failed to delete lecture note');
    }
  }

  // --- Quiz Generation ---
  static Future<List<dynamic>> generateQuizPreview(
    int noteId,
    String topic,
    String difficulty,
    int numQuestions,
    Map<String, int> difficultyDict, {
    List<int> selectedLibraryQuestionIds = const [],
  }) async {
    final url = Uri.parse('$baseUrl/quizzes/generate-preview');
    final response = await http.post(url,
        headers: await getHeaders(),
        body: jsonEncode({
          'lecture_note_id': noteId,
          'topic': topic,
          'difficulty': difficulty,
          'num_questions': numQuestions,
          'difficulty_dict': difficultyDict,
          'selected_library_question_ids': selectedLibraryQuestionIds,
        }));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Quiz preview generation failed: ${response.body}');
    }
  }

  static Future<void> finalizeQuiz(
    int noteId,
    String topic,
    String difficulty,
    List<dynamic> questions,
  ) async {
    final url = Uri.parse('$baseUrl/quizzes/finalize');
    final response = await http.post(url,
        headers: await getHeaders(),
        body: jsonEncode({
          'lecture_note_id': noteId,
          'topic': topic,
          'difficulty': difficulty,
          'questions': questions,
        }));

    if (response.statusCode != 200) {
      throw Exception('Quiz finalization failed: ${response.body}');
    }
  }

  static Future<void> generateQuiz(
    int noteId,
    String topic,
    String difficulty,
    int numQuestions,
    Map<String, int> difficultyDict, {
    List<int> selectedLibraryQuestionIds = const [],
  }) async {
    final url = Uri.parse('$baseUrl/quizzes/generate');
    final response = await http.post(url,
        headers: await getHeaders(),
        body: jsonEncode({
          'lecture_note_id': noteId,
          'topic': topic,
          'difficulty': difficulty,
          'num_questions': numQuestions,
          'difficulty_dict': difficultyDict,
          'selected_library_question_ids': selectedLibraryQuestionIds,
        }));

    if (response.statusCode != 200) {
      throw Exception('Quiz generation failed: ${response.body}');
    }
  }

  // --- Quizzes ---
  static Future<List<dynamic>> getQuizzes() async {
    final url = Uri.parse('$baseUrl/quizzes/');
    try {
      final response = await http.get(url, headers: await getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch quizzes');
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching quizzes: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getQuizQuestions(int quizId) async {
    final url = Uri.parse('$baseUrl/quiz-questions/by-quiz/$quizId');
    try {
      final response = await http.get(url, headers: await getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch questions');
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching questions: $e");
      return [];
    }
  }

  static Future<void> addQuestion(Map<String, dynamic> questionData) async {
    final url = Uri.parse('$baseUrl/quiz-questions/');
    final response = await http.post(
      url,
      headers: await getHeaders(),
      body: jsonEncode(questionData),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to add question: ${response.body}');
    }
  }

  static Future<void> updateQuestion(
      int id, Map<String, dynamic> questionData) async {
    final url = Uri.parse('$baseUrl/quiz-questions/$id');
    final response = await http.put(
      url,
      headers: await getHeaders(),
      body: jsonEncode(questionData),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update question: ${response.body}');
    }
  }

  static Future<void> deleteQuestion(int id) async {
    final url = Uri.parse('$baseUrl/quiz-questions/$id');
    final response = await http.delete(url, headers: await getHeaders());
    if (response.statusCode != 200) {
      throw Exception('Failed to delete question');
    }
  }

  // --- Question Library ---
  static Future<List<dynamic>> getLibraryQuestions(int noteId) async {
    final url = Uri.parse('$baseUrl/question-library/by-note/$noteId');
    try {
      final response = await http.get(url, headers: await getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch library questions');
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching library questions: $e");
      return [];
    }
  }

  static Future<void> markQuestionAsPoor(
      int quizId, String questionText) async {
    final url = Uri.parse('$baseUrl/question-library/mark-poor');
    final response = await http.post(
      url,
      headers: await getHeaders(),
      body: jsonEncode({
        'quiz_id': quizId,
        'question_text': questionText,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to mark question as poor');
    }
  }

  // --- Courses ---
  static Future<List<dynamic>> getCourses() async {
    final url = Uri.parse('$baseUrl/courses/');
    try {
      final response = await http.get(url, headers: await getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch courses');
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching courses: $e");
      return [];
    }
  }

  static Future<void> addCourse(Map<String, dynamic> courseData) async {
    final url = Uri.parse('$baseUrl/courses/');
    final response = await http.post(
      url,
      headers: await getHeaders(),
      body: jsonEncode({
        'code': courseData['code'],
        'title': courseData['title'],
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to add course: ${response.body}');
    }
  }

  static Future<void> updateCourse(
      int id, Map<String, dynamic> courseData) async {
    final url = Uri.parse('$baseUrl/courses/$id');
    final response = await http.put(
      url,
      headers: await getHeaders(),
      body: jsonEncode({
        'code': courseData['code'],
        'title': courseData['title'],
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update course: ${response.body}');
    }
  }

  static Future<void> deleteCourse(int id) async {
    final url = Uri.parse('$baseUrl/courses/$id');
    final response = await http.delete(url, headers: await getHeaders());
    if (response.statusCode != 200) {
      throw Exception('Failed to delete course');
    }
  }

  // --- Teacher Allocation (Teaches) ---
  static Future<List<dynamic>> getAllocations() async {
    final url = Uri.parse('$baseUrl/teaches/');
    try {
      final response = await http.get(url, headers: await getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch allocations');
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching allocations: $e");
      return [];
    }
  }

  static Future<void> assignTeacher(int teacherId, int courseId) async {
    final url = Uri.parse('$baseUrl/teaches/');
    final response = await http.post(
      url,
      headers: await getHeaders(),
      body: jsonEncode({
        'teacher_id': teacherId,
        'course_id': courseId,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to assign teacher: ${response.body}');
    }
  }

  static Future<void> removeAllocation(int teacherId, int courseId) async {
    final url = Uri.parse(
        '$baseUrl/teaches/?teacher_id=$teacherId&course_id=$courseId');
    final response = await http.delete(url, headers: await getHeaders());
    if (response.statusCode != 200) {
      throw Exception('Failed to remove allocation');
    }
  }

  // --- Student Enrollment ---
  static Future<List<dynamic>> getEnrollments() async {
    final url = Uri.parse('$baseUrl/enrollments/');
    try {
      final response = await http.get(url, headers: await getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch enrollments');
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching enrollments: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getEnrollmentsByCourse(int courseId) async {
    final url = Uri.parse('$baseUrl/enrollments/by-course/$courseId');
    try {
      final response = await http.get(url, headers: await getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch enrollments for course $courseId');
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching enrollments by course: $e");
      return [];
    }
  }

  static Future<void> enrollStudent(int studentId, int courseId) async {
    final url = Uri.parse('$baseUrl/enrollments/');
    final response = await http.post(
      url,
      headers: await getHeaders(),
      body: jsonEncode({
        'student_id': studentId,
        'course_id': courseId,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to enroll student: ${response.body}');
    }
  }

  static Future<void> deleteEnrollment(int id) async {
    final url = Uri.parse('$baseUrl/enrollments/$id');
    final response = await http.delete(url, headers: await getHeaders());
    if (response.statusCode != 200) {
      throw Exception('Failed to delete enrollment');
    }
  }

  static Future<List<dynamic>> getEnrollmentsByStudent(int studentId) async {
    final url = Uri.parse('$baseUrl/enrollments/by-student/$studentId');
    try {
      final response = await http.get(url, headers: await getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch enrollments for student $studentId');
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching enrollments by student: $e");
      return [];
    }
  }

  static Future<void> publishQuiz(int quizId) async {
    final url = Uri.parse('$baseUrl/quizzes/$quizId/publish');
    final response = await http.put(url, headers: await getHeaders());
    if (response.statusCode != 200) {
      throw Exception('Failed to publish quiz');
    }
  }

  // --- Attempts (Assessment) ---
  static Future<List<dynamic>> getAttemptsByQuiz(int quizId) async {
    final url = Uri.parse('$baseUrl/attempts/by-quiz/$quizId');
    try {
      final response = await http.get(url, headers: await getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch attempts for quiz $quizId');
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching attempts: $e");
      return [];
    }
  }

  static Future<void> updateAttempt(
      int attemptId, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/attempts/$attemptId');
    final response = await http.put(
      url,
      headers: await getHeaders(),
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update attempt');
    }
  }

  static Future<List<dynamic>> getAttemptsByStudent(int studentId) async {
    final url = Uri.parse('$baseUrl/attempts/by-student/$studentId');
    try {
      final response = await http.get(url, headers: await getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch attempts for student $studentId');
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching attempts: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> submitAttempt(
      Map<String, dynamic> attemptData) async {
    final url = Uri.parse('$baseUrl/attempts/');
    final response = await http.post(
      url,
      headers: await getHeaders(),
      body: jsonEncode(attemptData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to submit attempt: ${response.body}');
    }
  }

  // --- Assignments (Just-In-Time) ---

  static Future<List<dynamic>> getAssignmentsByStudent(int studentId) async {
    final url = Uri.parse('$baseUrl/assignments/by-student/$studentId');
    try {
      final response = await http.get(url, headers: await getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch assignments');
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching assignments: $e");
      return [];
    }
  }

  static Future<int> createAssignment(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/assignments/');
    final response = await http.post(
      url,
      headers: await getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final resData = jsonDecode(response.body);
      return resData['id'];
    } else {
      throw Exception('Failed to create assignment: ${response.body}');
    }
  }

  static Future<int> ensureAssignment(
      int quizId, int studentId, int teacherId) async {
    try {
      // 1. Check existing assignments
      final assignments = await getAssignmentsByStudent(studentId);
      final existing = assignments.firstWhere(
        (a) => a['quiz_id'] == quizId,
        orElse: () => null,
      );

      if (existing != null) {
        return existing['id'];
      }

      // 2. Create new if not exists
      // Using a far future date for due_at since it's on-demand
      final assignmentId = await createAssignment({
        'quiz_id': quizId,
        'student_id': studentId,
        'assigned_by': teacherId,
        'due_at':
            DateTime.now().add(const Duration(days: 365)).toIso8601String(),
        'status': 'assigned'
      });
      return assignmentId;
    } catch (e) {
      throw Exception("Error ensuring assignment: $e");
    }
  }
}
