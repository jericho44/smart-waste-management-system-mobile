/// Waste category entity representing category classifications.
class WasteCategory {
  final String uuid;
  final String name;
  final String slug;
  final String? description;
  final bool isActive;

  const WasteCategory({
    required this.uuid,
    required this.name,
    required this.slug,
    this.description,
    this.isActive = true,
  });

  factory WasteCategory.fromJson(Map<String, dynamic> json) {
    return WasteCategory(
      uuid: json['uuid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'name': name,
    'slug': slug,
    'description': description,
    'is_active': isActive,
  };
}
