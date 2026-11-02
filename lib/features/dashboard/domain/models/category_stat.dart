/// Category distribution metric in user dashboard.
class CategoryStat {
  final String uuid;
  final String name;
  final String slug;
  final int count;
  final double percentage;

  const CategoryStat({
    required this.uuid,
    required this.name,
    required this.slug,
    required this.count,
    required this.percentage,
  });

  factory CategoryStat.fromJson(Map<String, dynamic> json) {
    return CategoryStat(
      uuid: json['uuid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'name': name,
    'slug': slug,
    'count': count,
    'percentage': percentage,
  };
}
