class AppUser {
  final String id;
  final String name;
  final String email;
  final List<String> skills;
  final String bio;
  final String availability;
  final String title;
  final String phone;
  final String location;
  final int xp;
  final int projectsCompleted;
  final double ratingAverage;
  final int ratingCount;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.skills,
    required this.bio,
    required this.availability,
    this.title = '',
    this.phone = '',
    this.location = '',
    this.xp = 0,
    this.projectsCompleted = 0,
    this.ratingAverage = 0.0,
    this.ratingCount = 0,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      skills: (json['skills'] as List?)?.map((e) => e.toString()).toList() ?? [],
      bio: json['bio'] ?? '',
      availability: json['availability'] ?? 'available',
      title: json['title'] ?? '',
      phone: json['phone'] ?? '',
      location: json['location'] ?? '',
      xp: json['xp']?.toInt() ?? 0,
      projectsCompleted: json['projectsCompleted']?.toInt() ?? 0,
      ratingAverage: json['ratingAverage']?.toDouble() ?? 0.0,
      ratingCount: json['ratingCount']?.toInt() ?? 0,
    );
  }
}
