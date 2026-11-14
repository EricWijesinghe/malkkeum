import 'package:core/core.dart';

/// Values the owner can pick for a group's tap behaviour and move-chooser questions.
const groupChoosers = ['move', 'list', 'direct'];
const groupHomeTypes = ['one_two_room', 'apartment', 'villa_house'];
const groupTitleMax = 40;
const groupOrderMax = 99;
const groupDefaultIcon = 'svc_move';

/// Editable draft of one home tile. Built from the admin GET row, saved as the PUT body.
class GroupDraft {
  GroupDraft({
    required this.code,
    required this.titleKo,
    required this.titleEn,
    required this.order,
    required this.active,
    required this.icon,
    required this.chooser,
    required this.members,
    required this.newService,
    required this.oldService,
    required this.homeTypes,
  });

  factory GroupDraft.from(Json g) {
    final config = (g['config'] as Json?) ?? const {};
    final age = (config['build_age'] as Json?) ?? const {};
    final title = (g['title'] as Json?) ?? const {};
    return GroupDraft(
      code: g['code'] as String,
      titleKo: '${title['ko'] ?? ''}',
      titleEn: '${title['en'] ?? ''}',
      order: (g['sort_order'] as num?)?.toInt() ?? 0,
      active: g['active'] as bool? ?? true,
      icon: (g['icon'] as String?) ?? groupDefaultIcon,
      chooser: (g['chooser'] as String?) ?? 'list',
      members: ((g['services'] as List?) ?? const []).cast<String>().toList(),
      newService: age['new'] as String?,
      oldService: age['old'] as String?,
      homeTypes: ((config['home_types'] as List?) ?? const [])
          .cast<String>()
          .toList(),
    );
  }

  final String code;
  String titleKo;
  String titleEn;
  int order;
  bool active;
  String icon;
  String chooser;

  /// Member codes in the order the apps show them.
  final List<String> members;
  String? newService;
  String? oldService;
  List<String> homeTypes;

  /// First problem with the draft as a message, or null when it can be saved.
  String? problem(T t) {
    if (!_titleOk(titleKo) || !_titleOk(titleEn)) return t.cgGroupErrTitle;
    if (order < 0 || order > groupOrderMax) return t.cgGroupErrOrder;
    if (members.isEmpty) return t.cgGroupErrMembers;
    if (chooser == 'direct' && members.length != 1) return t.cgGroupErrDirect;
    if (chooser == 'move' && !_moveReady()) return t.cgGroupErrMove;
    return null;
  }

  bool _titleOk(String s) =>
      s.trim().isNotEmpty && s.trim().length <= groupTitleMax;

  bool _moveReady() =>
      newService != null &&
      oldService != null &&
      members.contains(newService) &&
      members.contains(oldService) &&
      homeTypes.isNotEmpty;

  /// PUT body. Config is only sent for the move chooser; other tiles store an empty object.
  Json toBody() => {
    'title_ko': titleKo.trim(),
    'title_en': titleEn.trim(),
    'sort_order': order,
    'active': active,
    'icon': icon,
    'chooser': chooser,
    'services': members,
    'config': chooser == 'move'
        ? {
            'build_age': {'new': newService, 'old': oldService},
            'home_types': [
              for (final h in groupHomeTypes)
                if (homeTypes.contains(h)) h,
            ],
          }
        : <String, Object?>{},
  };
}

/// Server refusal code to a Korean-first message, or null for an unknown code.
String? groupServerMessage(T t, String code) => switch (code) {
  'invalid_group_title' => t.cgGroupErrTitle,
  'invalid_group_order' => t.cgGroupErrOrder,
  'invalid_group_icon' => t.cgGroupErrIcon,
  'service_in_other_group' => t.cgGroupErrOtherGroup,
  'invalid_group_config' => t.cgGroupErrMove,
  'invalid_group_services' || 'unknown_service' => t.cgGroupErrMembers,
  _ => null,
};
