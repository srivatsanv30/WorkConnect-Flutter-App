class AppUser {
  final String id;
  final String name;
  final String email;
  final List<String> skills;
  final String bio;
  final String availability;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.skills,
    required this.bio,
    required this.availability,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      skills: (json['skills'] as List?)?.map((e) => e.toString()).toList() ?? [],
      bio: json['bio'] ?? '',
      availability: json['availability'] ?? 'available',
    );
  }
}
