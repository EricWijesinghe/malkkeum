// Step-by-step guides for each setup-wizard card. Written for the person installing the
// service, who may not be technical: every step says where to click and what to copy.
// Korean first (the operators are in Korea); English for everyone else.

import 'package:core/core.dart';

class Tr {
  const Tr(this.ko, this.en);
  final String ko;
  final String en;
  String of(String lang) => lang == 'ko' ? ko : en;
}

class FieldGuide {
  const FieldGuide(this.label, {this.hint, this.suggestions = const []});
  final Tr label;
  final Tr? hint;

  /// For map fields: the keys the server understands (payment methods, event kinds).
  final List<String> suggestions;
}

class Guide {
  const Guide({
    required this.title,
    required this.site,
    required this.steps,
    required this.fields,
  });
  final String Function(T) title;
  final String site;
  final List<Tr> steps;
  final Map<String, FieldGuide> fields;
}

const paymentMethodKeys = [
  'card',
  'kakaopay',
  'naverpay',
  'tosspay',
  'payco',
  'samsungpay',
  'applepay',
  'transfer',
  'virtual_account',
  'phone',
];
const messageEventKeys = [
  'booking.status',
  'booking.completed',
  'booking.reschedule_confirmed',
];

final guides = <String, Guide>{
  'portone': Guide(
    title: (t) => t.cIntPortone,
    site: 'https://admin.portone.io',
    steps: const [
      Tr(
        'admin.portone.io 에 가입하고 로그인해요. (사업자등록증이 필요해요)',
        'Sign up at admin.portone.io and log in (business registration required).',
      ),
      Tr(
        '[결제 연동] → [연동 정보] → [식별코드 · API Keys] 에서 "상점 아이디"를 복사해 아래에 붙여넣어요.',
        'Integration → Info → IDs & API Keys: copy the Store ID below.',
      ),
      Tr(
        '같은 화면에서 [V2 API Secret 발급] 을 누르고 나온 값을 복사해 붙여넣어요.',
        'On the same page create a V2 API Secret and paste it.',
      ),
      Tr(
        '[결제 연동] → [채널 관리] 에서 결제사 채널(카드, 카카오페이, 네이버페이, 토스페이 등)을 추가하고, 채널 키를 결제수단별로 넣어요.',
        'Integration → Channels: add each payment channel and enter its channel key per method.',
      ),
      Tr(
        '[결제 연동] → [웹훅] 에서 아래 "웹훅 주소"를 붙여넣고 버전 V2 를 고르면 whsec_ 로 시작하는 시크릿이 나와요. 그 값을 붙여넣어요.',
        'Integration → Webhooks: paste the webhook URL below (version V2), then paste the whsec_ secret it shows.',
      ),
      Tr(
        '저장한 뒤 [연결 테스트] 를 눌러 초록색이 나오면 끝!',
        'Save, then press Test connection. Green means done!',
      ),
    ],
    fields: const {
      'store_id': FieldGuide(
        Tr('상점 아이디 (Store ID)', 'Store ID'),
        hint: Tr('store-로 시작해요', 'Starts with store-'),
      ),
      'api_secret': FieldGuide(Tr('V2 API Secret', 'V2 API Secret')),
      'webhook_secret': FieldGuide(
        Tr('웹훅 시크릿', 'Webhook secret'),
        hint: Tr('whsec_ 로 시작해요', 'Starts with whsec_'),
      ),
      'channel_keys': FieldGuide(
        Tr('결제수단별 채널 키', 'Channel key per payment method'),
        suggestions: paymentMethodKeys,
      ),
    },
  ),
  'backup': Guide(
    title: (t) => t.cIntBackup,
    site: 'https://dash.cloudflare.com',
    steps: const [
      Tr(
        'Cloudflare R2 또는 네이버 클라우드 Object Storage 에 가입하고, 비공개 버킷을 하나 만들어요 (예: malkkeum-backup).',
        'Sign up for Cloudflare R2 or Naver Cloud Object Storage and create one private bucket (e.g. malkkeum-backup).',
      ),
      Tr(
        'R2: [R2 → API 토큰] 에서 "객체 읽기 및 쓰기" 권한 토큰을 만들어요. 네이버 클라우드: 마이페이지 → 인증키 관리에서 액세스 키를 만들어요. 나온 Access Key 와 Secret Key 를 복사해요 (Secret 은 한 번만 보여요).',
        'R2: create an API token with Object Read & Write under R2 → API Tokens. Naver Cloud: My page → Access key management. Copy the Access Key and Secret Key (the secret is shown once).',
      ),
      Tr(
        '엔드포인트와 리전: R2 는 https://<계정ID>.r2.cloudflarestorage.com 과 리전 auto. 네이버 클라우드는 https://kr.object.ncloudstorage.com 과 리전 kr-standard.',
        'Endpoint and region: R2 uses https://<account-id>.r2.cloudflarestorage.com and region auto. Naver Cloud uses https://kr.object.ncloudstorage.com and region kr-standard.',
      ),
      Tr(
        '보관 기간(일)을 정해요. 기본 30일이 지난 백업 파일은 자동으로 지워져요.',
        'Choose how many days to keep backups (default 30). Older backup files are deleted automatically.',
      ),
      Tr(
        '저장한 뒤 [연결 테스트] 를 눌러요. 작은 테스트 파일을 올렸다가 바로 지워요. 비용은 저장 용량에 따라 달라요 (백업 몇 개 분량이면 월 몇 천 원 수준이에요). 정확한 요금은 각 서비스의 요금표를 확인하세요.',
        'Save, then press Test connection (it uploads and deletes a tiny test file). Cost depends on storage used; a few backups usually cost very little. Check each provider’s price page for exact rates.',
      ),
    ],
    fields: const {
      'endpoint': FieldGuide(Tr('엔드포인트', 'Endpoint'), hint: Tr('https://...', 'https://...')),
      'region': FieldGuide(Tr('리전', 'Region'), hint: Tr('R2: auto · 네이버: kr-standard', 'R2: auto · Naver: kr-standard')),
      'bucket': FieldGuide(Tr('버킷 이름', 'Bucket name')),
      'access_key': FieldGuide(Tr('Access Key', 'Access Key')),
      'secret_key': FieldGuide(Tr('Secret Key', 'Secret Key')),
      'retention_days': FieldGuide(Tr('보관 기간(일)', 'Keep for (days)'), hint: Tr('기본 30', 'default 30')),
    },
  ),
  'solapi': Guide(
    title: (t) => t.cIntSolapi,
    site: 'https://console.solapi.com',
    steps: const [
      Tr(
        'solapi.com 에 가입하고, [발신번호 관리] 에서 고객센터 번호를 등록해요. (통신서비스 이용증명원이 필요해요)',
        'Sign up at solapi.com and register your support number as a sender.',
      ),
      Tr(
        '[개발/연동] → [API Key 관리] → [새 API Key 생성] 을 눌러 API Key 와 API Secret 을 복사해요.',
        'Developers → API Keys → create a key; copy the API Key and API Secret.',
      ),
      Tr(
        '등록한 발신번호를 숫자만 입력해요.',
        'Enter the registered sender number (digits only).',
      ),
      Tr(
        '(선택) 카카오 알림톡: [카카오 채널 연동] 으로 채널을 연결하고 채널 ID(pfId)를 넣어요. 템플릿이 승인되면 템플릿 ID 를 알림 종류별로 넣어요.',
        '(Optional) KakaoTalk AlimTalk: link your Kakao channel, paste its pfId, and add approved template IDs per notification.',
      ),
      Tr(
        '저장한 뒤 [연결 테스트] 를 눌러요. 문자는 보내지 않고 잔액만 확인해요.',
        'Save and press Test connection (it only reads your balance, no message is sent).',
      ),
    ],
    fields: const {
      'api_key': FieldGuide(Tr('API Key', 'API Key')),
      'api_secret': FieldGuide(Tr('API Secret', 'API Secret')),
      'sender': FieldGuide(
        Tr('발신번호', 'Sender number'),
        hint: Tr('예: 0212345678', 'e.g. 0212345678'),
      ),
      'pf_id': FieldGuide(Tr('카카오 채널 ID (pfId)', 'Kakao channel ID (pfId)')),
      'templates': FieldGuide(
        Tr('알림톡 템플릿 ID', 'AlimTalk template IDs'),
        suggestions: messageEventKeys,
      ),
    },
  ),
  'push': Guide(
    title: (t) => t.cIntPush,
    site: 'https://console.firebase.google.com',
    steps: const [
      Tr(
        'console.firebase.google.com 에서 프로젝트를 만들어요. (앱 빌드 담당자와 같은 프로젝트를 써야 해요)',
        'Create a project at console.firebase.google.com (the same project the app builds use).',
      ),
      Tr(
        '톱니바퀴 → [프로젝트 설정] → [서비스 계정] → [새 비공개 키 생성] 을 누르면 .json 파일이 내려받아져요.',
        'Gear → Project settings → Service accounts → Generate new private key. A .json file downloads.',
      ),
      Tr(
        '그 파일을 메모장으로 열어 내용 전체를 복사해 아래에 붙여넣어요.',
        'Open the file in a text editor, copy everything and paste it below.',
      ),
      Tr('저장한 뒤 [연결 테스트] 를 눌러요.', 'Save and press Test connection.'),
    ],
    fields: const {
      'service_account': FieldGuide(
        Tr('서비스 계정 키 (.json 내용)', 'Service account key (.json contents)'),
      ),
    },
  ),
  'kakao': Guide(
    title: (t) => t.cIntKakao,
    site: 'https://developers.kakao.com/console/app',
    steps: const [
      Tr(
        'developers.kakao.com 에서 [내 애플리케이션] → [애플리케이션 추가하기] 를 눌러요.',
        'At developers.kakao.com open My Applications → Add application.',
      ),
      Tr(
        '[앱 설정] → [앱 키] 화면 맨 위의 "앱 ID"(숫자)를 복사해 붙여넣어요.',
        'App settings → App keys: copy the numeric App ID at the top.',
      ),
      Tr(
        '[카카오 로그인] 을 활성화하고 동의항목에서 이메일을 선택해요. 네이티브 앱 키는 앱 빌드 담당자에게 전달해요.',
        'Enable Kakao Login and the email consent item. Send the Native app key to whoever builds the apps.',
      ),
    ],
    fields: const {'app_id': FieldGuide(Tr('앱 ID (숫자)', 'App ID (number)'))},
  ),
  'naver': Guide(
    title: (t) => t.cIntNaver,
    site: 'https://developers.naver.com/apps',
    steps: const [
      Tr(
        'developers.naver.com → [Application] → [애플리케이션 등록] 에서 "네이버 로그인" 을 선택해요.',
        'developers.naver.com → Application → Register, choose Naver Login.',
      ),
      Tr(
        '등록 후 나오는 Client ID 를 붙여넣어요. Client Secret 은 앱 빌드 담당자에게 전달해요.',
        'Paste the Client ID. Send the Client Secret to whoever builds the apps.',
      ),
    ],
    fields: const {'client_id': FieldGuide(Tr('Client ID', 'Client ID'))},
  ),
  'google': Guide(
    title: (t) => t.cIntGoogle,
    site: 'https://console.cloud.google.com/apis/credentials',
    steps: const [
      Tr(
        'console.cloud.google.com → [API 및 서비스] → [사용자 인증 정보] 로 가요. (Firebase 와 같은 프로젝트)',
        'console.cloud.google.com → APIs & Services → Credentials (same project as Firebase).',
      ),
      Tr(
        'OAuth 클라이언트 ID 를 Android, iOS, 웹용으로 각각 만들어요.',
        'Create OAuth client IDs for Android, iOS and Web.',
      ),
      Tr(
        '만든 클라이언트 ID 들을 쉼표(,)로 구분해 붙여넣어요.',
        'Paste all client IDs separated by commas.',
      ),
    ],
    fields: const {
      'client_ids': FieldGuide(
        Tr('클라이언트 ID 목록', 'Client IDs'),
        hint: Tr(
          '….apps.googleusercontent.com, …',
          '….apps.googleusercontent.com, …',
        ),
      ),
    },
  ),
  'apple': Guide(
    title: (t) => t.cIntApple,
    site: 'https://developer.apple.com/account/resources/identifiers/list',
    steps: const [
      Tr(
        'developer.apple.com → [Identifiers] 에서 고객 앱과 파트너 앱의 App ID 에 "Sign in with Apple" 을 켜요.',
        'developer.apple.com → Identifiers: enable Sign in with Apple for the customer and partner App IDs.',
      ),
      Tr(
        '두 앱의 번들 ID 를 쉼표로 구분해 붙여넣어요. 예: com.malkkeum.customer, com.malkkeum.partner',
        'Paste both bundle IDs separated by commas, e.g. com.malkkeum.customer, com.malkkeum.partner',
      ),
    ],
    fields: const {'client_ids': FieldGuide(Tr('번들 ID 목록', 'Bundle IDs'))},
  ),
  'juso': Guide(
    title: (t) => t.cIntJuso,
    site: 'https://business.juso.go.kr',
    steps: const [
      Tr(
        'business.juso.go.kr 에 가입한 뒤 [도로명주소 검색 API] 를 신청해요. 승인까지 하루 정도 걸릴 수 있어요.',
        'Sign up at business.juso.go.kr and apply for the road address search API. Approval can take about a day.',
      ),
      Tr(
        '승인되면 발급된 승인키(confmKey)를 복사해 아래 칸에 붙여넣어요.',
        'Once approved, copy the confirm key (confmKey) and paste it in the box below.',
      ),
      Tr(
        '저장한 뒤 [연결 테스트] 를 눌러 초록색이 나오면 끝! 키가 없으면 고객 앱은 주소를 직접 입력해요.',
        'Save, then press Test connection. Green means done! Without a key the customer app takes typed addresses.',
      ),
    ],
    fields: const {'confm_key': FieldGuide(Tr('승인키', 'Confirm key'), hint: Tr('confmKey 값', 'The confmKey value'))},
  ),
  'payout': Guide(
    title: (t) => t.cIntPayout,
    site: 'https://www.tosspayments.com',
    steps: const [
      Tr(
        '기본은 [직접 이체] 예요. 정산 화면에 계좌와 금액이 나오면 은행 앱으로 보내고 [이체 완료] 를 눌러요.',
        'The default is manual transfer: the settlements screen shows the account and amount, you send it from your bank app and press Transferred.',
      ),
      Tr(
        '토스 지급대행 계약이 있으면 mode 에 toss 를, 아래 칸에 시크릿 키를 넣어요. 지금은 테스트 키(test_)만 받아요.',
        'With a Toss payouts contract, set mode to toss and paste the secret key below. For now only test keys (test_) are accepted.',
      ),
    ],
    fields: const {
      'mode': FieldGuide(Tr('방식', 'Mode'), hint: Tr('manual 또는 toss', 'manual or toss'), suggestions: ['manual', 'toss']),
      'secret_key': FieldGuide(Tr('토스 시크릿 키', 'Toss secret key'), hint: Tr('toss 일 때만', 'Only for toss')),
    },
  ),
  'ai': Guide(
    title: (t) => t.aiLabel,
    site: 'https://console.anthropic.com',
    steps: const [
      Tr(
        'console.anthropic.com 에 가입하고 로그인해요. 결제 수단을 등록해야 키를 쓸 수 있어요.',
        'Sign up and log in at console.anthropic.com. A payment method is required before the key works.',
      ),
      Tr(
        '왼쪽 메뉴의 [API keys] 를 열고 [Create Key] 를 눌러 새 키를 만들어요.',
        'Open API keys in the left menu and press Create Key.',
      ),
      Tr(
        '만든 키(sk-ant- 로 시작)를 복사해 아래 API 키 칸에 붙여넣어요. 키는 한 번만 보여요.',
        'Copy the key (it starts with sk-ant-) and paste it in the API key box below. It is shown only once.',
      ),
      Tr(
        '[Settings] → [Limits] 에서 월 사용 한도(Monthly spend limit)를 꼭 정해 두세요. AI가 답변할 때마다 요금이 나와요.',
        'In Settings → Limits, set a monthly spend limit. Every answer the AI gives costs money.',
      ),
      Tr(
        '운영 방식을 골라요. offline 은 상담원이 없을 때만, always_first 는 항상 AI가 먼저 답변해요. 비워두면 offline 이에요.',
        'Choose a mode: offline answers only when staff are away, always_first answers first every time. Empty means offline.',
      ),
      Tr(
        '저장한 뒤 [연결 테스트] 를 눌러 초록색이 나오면 끝! 테스트는 토큰을 쓰지 않아요.',
        'Save, then press Test connection. Green means done! The test spends no tokens.',
      ),
    ],
    fields: const {
      'api_key': FieldGuide(
        Tr('API 키', 'API key'),
        hint: Tr('sk-ant- 로 시작해요', 'Starts with sk-ant-'),
      ),
      'model': FieldGuide(
        Tr('모델', 'Model'),
        hint: Tr('비워두면 claude-opus-5-5', 'Leave empty for claude-opus-5-5'),
      ),
      'mode': FieldGuide(
        Tr('운영 방식', 'Mode'),
        hint: Tr('offline 또는 always_first', 'offline or always_first'),
      ),
    },
  ),
};

/// Labels and hints that come from the generated strings (every app language), keyed by
/// `<section>.<field>`. Fields not listed here use their [Tr] text above.
final localFields = <String, LocalField>{
  'ai.thread_hourly_cap': LocalField((t) => t.aiCapThreadLabel, (t) => t.aiCapHint),
  'ai.member_daily_cap': LocalField((t) => t.aiCapMemberLabel, (t) => t.aiCapHint),
  'ai.daily_cap': LocalField((t) => t.aiCapDailyLabel, (t) => t.aiCapHint),
};

class LocalField {
  const LocalField(this.label, this.hint);
  final String Function(T) label;
  final String Function(T) hint;
}

/// Plain-language message for a setup error or test result code from the server.
String setupMessage(T t, String code) => switch (code) {
  'connected' => t.cSetupConnected,
  'saved_check_in_app' => t.cSetupCheckInApp,
  'invalid_key' => t.cSetupInvalidKey,
  'unreachable' || 'provider_error' => t.cSetupUnreachable,
  'not_configured' => t.cSetupNotConnected,
  'weak_password' => t.cWeakPassword,
  'invalid_webhook_secret' => t.err_invalid_webhook_secret,
  'invalid_endpoint' => t.err_invalid_endpoint,
  'invalid_bucket' => t.err_invalid_bucket,
  'invalid_region' => t.err_invalid_region,
  'invalid_retention' => t.err_invalid_retention,
  'invalid_service_account' => t.err_invalid_service_account,
  'invalid_mode' => t.err_invalid_mode,
  'invalid_model' => t.err_invalid_model,
  'missing_field' => t.err_missing_field,
  'toss_unverified' => t.err_toss_unverified,
  'invalid_cap' => t.err_invalid_cap,
  _ => t.cInvalidValue,
};
