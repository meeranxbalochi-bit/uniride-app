/// User profile model matching the Firestore 'users' collection.
class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final String role; // 'admin' | 'driver' | 'student'
  final String? assignedBusId; // Driver: assigned bus
  final String? studentBusId; // Student: enrolled bus to track
  final String? studentStopId; // Student: target stop for proximity
  final String? studentStopName;
  final String? phoneNumber;
  final int createdAt;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.role,
    this.assignedBusId,
    this.studentBusId,
    this.studentStopId,
    this.studentStopName,
    this.phoneNumber,
    required this.createdAt,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Unknown',
      photoURL: map['photoURL'] as String?,
      role: map['role'] as String? ?? 'student',
      assignedBusId: map['assignedBusId'] as String?,
      studentBusId: map['studentBusId'] as String?,
      studentStopId: map['studentStopId'] as String?,
      studentStopName: map['studentStopName'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      createdAt: map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': role,
      'assignedBusId': assignedBusId,
      'studentBusId': studentBusId,
      'studentStopId': studentStopId,
      'studentStopName': studentStopName,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt,
    };
  }

  UserProfile copyWith({
    String? email,
    String? displayName,
    String? photoURL,
    String? role,
    String? assignedBusId,
    String? studentBusId,
    String? studentStopId,
    String? studentStopName,
    String? phoneNumber,
    int? createdAt,
  }) {
    return UserProfile(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      role: role ?? this.role,
      assignedBusId: assignedBusId ?? this.assignedBusId,
      studentBusId: studentBusId ?? this.studentBusId,
      studentStopId: studentStopId ?? this.studentStopId,
      studentStopName: studentStopName ?? this.studentStopName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'UserProfile(uid: $uid, email: $email, role: $role)';
}
