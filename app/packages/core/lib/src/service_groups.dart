import 'models.dart';

/// One home tile (서비스 묶음) from GET /v1/service-groups. [chooser] is move, list or direct.
class ServiceGroup {
  const ServiceGroup({
    required this.code,
    required this.titleKo,
    required this.titleEn,
    required this.sortOrder,
    required this.icon,
    required this.chooser,
    required this.services,
    this.badge,
    this.config = const {},
  });

  factory ServiceGroup.fromJson(Json j) {
    final title = (j['title'] as Json?) ?? const {};
    return ServiceGroup(
      code: j['code'] as String,
      titleKo: title['ko'] as String,
      titleEn: title['en'] as String,
      sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
      icon: j['icon'] as String,
      chooser: j['chooser'] as String,
      services: (j['services'] as List).cast<String>(),
      badge: j['badge'] as String?,
      config: (j['config'] as Json?) ?? const {},
    );
  }

  final String code;
  final String titleKo;
  final String titleEn;
  final int sortOrder;
  final String icon;
  final String chooser;

  /// Live member service codes, in the order the owner set.
  final List<String> services;

  /// `N` or `HOT` from the member services, or null.
  final String? badge;

  /// Move-chooser questions: `build_age` targets and `home_types`.
  final Json config;

  String title({required bool korean}) => korean ? titleKo : titleEn;
}

/// Groups from a GET /v1/service-groups body, in the owner's order.
List<ServiceGroup> serviceGroupsFrom(Json body) {
  final groups = [
    for (final g in ((body['groups'] as List?) ?? const []).cast<Json>())
      ServiceGroup.fromJson(g),
  ];
  groups.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return groups;
}
