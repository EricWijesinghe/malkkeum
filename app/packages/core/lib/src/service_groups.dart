import 'api.dart';
import 'models.dart';

/// Home a customer picks for the move-in / move-out and whole-home flows (CR-3, CR-4).
/// [code] matches the server's `home_type` answer.
enum MoveHome {
  oneTwoRoom('one_two_room'),
  apartment('apartment'),
  villaHouse('villa_house');

  const MoveHome(this.code);
  final String code;

  static MoveHome? fromCode(String? code) {
    for (final h in values) {
      if (h.code == code) return h;
    }
    return null;
  }
}

/// A home-screen category (CR-2) with its member services, as the API sends it.
class ServiceGroup {
  const ServiceGroup({
    required this.code,
    required this.title,
    required this.sortOrder,
    required this.active,
    required this.chooser,
    required this.icon,
    required this.services,
    this.badge,
    this.config = const {},
  });

  final String code;

  /// `{"ko": ..., "en": ...}`.
  final Map<String, String> title;
  final int sortOrder;
  final bool active;

  /// `move` (home type questions first), `list` (picker of [services]) or `direct` (one service).
  final String chooser;
  final String icon;

  /// `null`, `"N"` or `"HOT"`, derived by the server from member services.
  final String? badge;
  final List<String> services;
  final Json config;

  String titleFor(String lang) => title[lang] ?? title['ko'] ?? code;

  factory ServiceGroup.fromJson(Json j) {
    final code = _str(j, 'code');
    final title = j['title'];
    if (title is! Map) throw FormatException('group $code: title missing');
    final services = j['services'];
    if (services is! List)
      throw FormatException('group $code: services missing');
    return ServiceGroup(
      code: code,
      title: {for (final e in title.entries) '${e.key}': '${e.value}'},
      sortOrder: _sortOrder(j, code),
      active: j['active'] != false,
      chooser: _str(j, 'chooser'),
      icon: _str(j, 'icon'),
      badge: _badge(j, code),
      services: [for (final s in services) '$s'],
      config: _config(j, code),
    );
  }

  static String _str(Json j, String key) {
    final v = j[key];
    if (v is! String || v.isEmpty) {
      throw FormatException('group field $key missing');
    }
    return v;
  }

  static int _sortOrder(Json j, String code) {
    final v = j['sort_order'];
    if (v == null) return 0;
    if (v is! num) throw FormatException('group $code: sort_order not a number');
    return v.toInt();
  }

  static String? _badge(Json j, String code) {
    final v = j['badge'];
    if (v == null) return null;
    if (v is! String) throw FormatException('group $code: badge not a string');
    return v;
  }

  static Json _config(Json j, String code) {
    final v = j['config'];
    if (v == null) return const {};
    if (v is! Map<String, dynamic>) {
      throw FormatException('group $code: config not an object');
    }
    return v;
  }
}

/// Built in for an API that does not send groups yet. Keep in step with the server's default catalogue.
final defaultServiceGroups = [
  const ServiceGroup(
    code: 'moving',
    title: {'ko': '이사·입주 청소', 'en': 'Move-in & move-out cleaning'},
    sortOrder: 0,
    active: true,
    chooser: 'move',
    icon: 'svc_move',
    services: ['move_in', 'move_out'],
    config: {
      'build_age': {'new': 'move_in', 'old': 'move_out'},
      'home_types': ['one_two_room', 'apartment', 'villa_house'],
    },
  ),
  const ServiceGroup(
    code: 'living',
    title: {'ko': '거주 청소', 'en': 'Home cleaning'},
    sortOrder: 1,
    active: true,
    chooser: 'list',
    icon: 'svc_living',
    services: ['bathroom', 'kitchen', 'whole_home', 'window'],
  ),
  const ServiceGroup(
    code: 'appliance',
    title: {'ko': '가전·가구 청소', 'en': 'Appliance & furniture cleaning'},
    sortOrder: 2,
    active: true,
    chooser: 'list',
    icon: 'svc_appliance',
    services: ['aircon', 'mattress', 'sofa'],
  ),
  const ServiceGroup(
    code: 'disinfection',
    title: {'ko': '방역·소독', 'en': 'Disinfection'},
    sortOrder: 3,
    active: true,
    chooser: 'list',
    icon: 'svc_disinfection',
    services: ['disinfection'],
  ),
];

/// Parses a `GET /v1/service-groups` body. An empty or missing list gives the built-in groups;
/// a malformed row throws so the caller can fall back as a whole.
List<ServiceGroup> parseServiceGroups(Object? body) {
  final raw = body is Map ? body['groups'] : null;
  if (raw is! List || raw.isEmpty) return defaultServiceGroups;
  final groups = [
    for (final g in raw)
      if (g is Map<String, dynamic>)
        ServiceGroup.fromJson(g)
      else
        throw const FormatException('group row is not an object'),
  ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return [
    for (final g in groups)
      if (g.active) g,
  ];
}

/// Groups for the home screen. Offline or on a bad response the built-in groups keep the app usable;
/// the server copy is read again on the next launch.
Future<List<ServiceGroup>> fetchServiceGroups(ApiClient api) async {
  try {
    return parseServiceGroups(await api.get('/service-groups'));
  } on ApiException {
    return defaultServiceGroups;
  } on FormatException {
    return defaultServiceGroups;
  }
}
