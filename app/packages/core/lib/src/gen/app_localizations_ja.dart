// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class TJa extends T {
  TJa([String locale = 'ja']) : super(locale);

  @override
  String get apSocialOr => 'または';

  @override
  String get apSocialSignIn => '簡単ログイン';

  @override
  String get apLoginKakao => 'カカオで続ける';

  @override
  String get apLoginNaver => 'ネイバーで続ける';

  @override
  String get apLoginGoogle => 'Googleで続ける';

  @override
  String get apLoginApple => 'Appleで続ける';

  @override
  String get apDevSocialNote => '開発モードです。実際のソーシャルアカウントではなくテストアカウントでログインします。';

  @override
  String get apSocialFailed => '簡単ログインに失敗しました。もう一度お試しください。';

  @override
  String get apProviderNotConfigured => 'このログイン方法はまだ準備中です';

  @override
  String get apPhoneTaken => 'この番号は別のアカウントに登録されています';

  @override
  String get apPhoneAttachTitle => '携帯番号を認証してください';

  @override
  String get apPhoneAttachBody => '予約と担当者への連絡に使う番号です。一度認証すれば十分です。';

  @override
  String get apPayAllTitle => '支払い方法を選択';

  @override
  String get apPaySavedTitle => '保存済みの支払い方法';

  @override
  String get apPayMoreTitle => 'すべての支払い方法';

  @override
  String get apPayBillingHint => '一度登録すれば次からワンタップで支払えます';

  @override
  String get apPayCheckoutHint => '決済画面で完了します';

  @override
  String get apPayRegistering => '登録中…';

  @override
  String get apPayManageHint => '登録した支払い方法でワンタップ決済できます。ここで追加できます。';

  @override
  String get apMethodCard => 'クレジット・デビットカード';

  @override
  String get apMethodKakao => 'カカオペイ';

  @override
  String get apMethodNaver => 'ネイバーペイ';

  @override
  String get apMethodToss => 'トスペイ';

  @override
  String get apMethodPayco => 'PAYCO';

  @override
  String get apMethodSamsung => 'Samsung Pay';

  @override
  String get apMethodApple => 'Apple Pay';

  @override
  String get apMethodTransfer => '口座振替';

  @override
  String get apMethodVirtual => '仮想口座';

  @override
  String get apMethodPhone => '携帯決済';

  @override
  String get apMethodUnknown => 'その他';

  @override
  String get apVaTitle => '入金口座の準備ができました';

  @override
  String get apVaWaiting => '入金待ち';

  @override
  String get apVaBody => '期限内に入金されると予約が確定します。入金は自動で確認されます。';

  @override
  String get apVaBank => '銀行';

  @override
  String get apVaAccount => '口座番号';

  @override
  String get apVaHolder => '口座名義';

  @override
  String get apVaAmount => '入金額';

  @override
  String apVaDue(String due) {
    return '$dueまでに入金してください';
  }

  @override
  String get apVaCopy => 'コピー';

  @override
  String get apVaCopied => '口座番号をコピーしました';

  @override
  String get apVaBannerTitle => '入金待ちの予約があります';

  @override
  String apVaBannerBody(String amount, String due) {
    return '$amount · $dueまで';
  }

  @override
  String get apVaBannerAction => '口座を見る';

  @override
  String get apPgTitle => '決済画面';

  @override
  String get apPgDevNote => '開発環境専用の決済シミュレーションです。実際の決済は行われません。';

  @override
  String apPgPay(String amount) {
    return '$amount を支払う';
  }

  @override
  String get apPgIssue => '口座番号を発行';

  @override
  String get apPgCancel => '支払いをキャンセル';

  @override
  String get apErrSlotFullRefunded => 'その時間が埋まったため、お支払いは自動キャンセルされました';

  @override
  String get apErrCheckoutExpired => '決済の有効時間が過ぎました。もう一度お試しください。';

  @override
  String get apIdentityTitle => '本人確認 (PASS)';

  @override
  String get apIdentityBody => '携帯回線の名義で本人を確認します。安全な取引と精算に使われます。';

  @override
  String get apIdentityAction => '本人確認する';

  @override
  String get apIdentityDone => '本人確認が完了しました';

  @override
  String get apIdentityVerified => '確認済み';

  @override
  String get apIdentityUnverified => '未確認です';

  @override
  String get apIdentityDevTitle => 'テスト本人確認';

  @override
  String get apIdentityDevBody => '開発環境では実際の確認なしで通過します。';

  @override
  String get apIdentityDevPass => '通過にする';

  @override
  String get apPayManageTitle => '簡単決済の登録';

  @override
  String get cTitle => '運営コンソール';

  @override
  String get cEmail => 'メール';

  @override
  String get cPassword => 'パスワード';

  @override
  String get cLogin => 'ログイン';

  @override
  String get cLoginFailed => 'メールまたはパスワードが違います';

  @override
  String get cDashboard => 'ダッシュボード';

  @override
  String get cBookings => '予約';

  @override
  String get cQuoteDesk => '見積デスク';

  @override
  String get cInbox => '相談箱';

  @override
  String get cCatalog => 'カタログ・価格';

  @override
  String get cMarketing => 'クーポン・コンテンツ';

  @override
  String get cPartners => 'パートナー';

  @override
  String get cSettlements => '精算';

  @override
  String get cCustomers => '顧客';

  @override
  String get cStaff => 'スタッフ';

  @override
  String get cSearchCommand => '検索・コマンド';

  @override
  String get cPaletteHint => 'メニュー名か予約番号を入力';

  @override
  String get cTodayJobs => '本日の作業';

  @override
  String get cOpenQuotes => '見積待ち';

  @override
  String get cUnassigned => '未割当';

  @override
  String get cUnreadThreads => '未読の相談';

  @override
  String get cRevenue30 => '30日決済額';

  @override
  String get cBookings30 => '30日予約';

  @override
  String get cByService => 'サービス別予約（30日）';

  @override
  String get cAllStatus => '全ステータス';

  @override
  String get cAllServices => '全サービス';

  @override
  String get cSearch => '検索（番号・電話・名前・住所）';

  @override
  String get cNoResults => '結果なし';

  @override
  String get cNumber => '予約番号';

  @override
  String get cVisit => '訪問';

  @override
  String get cService => 'サービス';

  @override
  String get cStatus => 'ステータス';

  @override
  String get cTeam => 'チーム';

  @override
  String get cAmount => '金額';

  @override
  String get cCustomer => '顧客';

  @override
  String get cPayments => '決済';

  @override
  String get cChangeStatus => 'ステータス変更';

  @override
  String get cTeamName => '割当チーム名';

  @override
  String get cAssign => 'チーム割当';

  @override
  String get cMarkDone => '完了にする';

  @override
  String get cConfirm => '確定にする';

  @override
  String get cCancelRefund => 'キャンセル・返金';

  @override
  String get cRefundAmount => '返金額（空欄で全額）';

  @override
  String get cDone => '完了しました';

  @override
  String get cAnswers => '顧客の回答';

  @override
  String get cEstimateCalc => '自動算定';

  @override
  String get cBase => '基本';

  @override
  String get cExtras => '追加';

  @override
  String get cSurcharge => '割増';

  @override
  String get cBeforeVat => '税抜';

  @override
  String get cProQuotes => 'パートナー見積';

  @override
  String get cNoProQuotes => 'まだ見積はありません';

  @override
  String get cFinalPrice => '顧客の最終金額';

  @override
  String get cQuoteNote => '顧客へのメモ';

  @override
  String get cSendQuote => '顧客に見積を送る';

  @override
  String get cQuoteSent => '見積を送りました';

  @override
  String get cCustomerChats => '顧客';

  @override
  String get cPartnerChats => 'パートナー';

  @override
  String get cSelectBooking => '予約を選択してください';

  @override
  String get cRefunded => '返金済み';

  @override
  String get cPartRefunded => '一部返金';

  @override
  String get cFailed => '失敗';

  @override
  String get cSelectThread => '会話を選択してください';

  @override
  String get cReplyHint => '返信を入力・Ctrl+Enterで送信';

  @override
  String get cOpenBooking => '予約を開く';

  @override
  String get cShortcuts => 'J/K移動・Ctrl+Kコマンド';

  @override
  String get cPricing => '価格';

  @override
  String get cMinutes => '所要(分)';

  @override
  String get cActive => '販売中';

  @override
  String get cSaved => '保存しました';

  @override
  String get cSlotCapacity => '時間帯別の受付数';

  @override
  String get cUnlimited => '制限なし';

  @override
  String get cFormula => '見積算定式';

  @override
  String get f_base_studio => '基本：ワンルーム';

  @override
  String get f_base_one_and_half => '基本：1.5ルーム';

  @override
  String get f_base_two_rooms => '基本：2部屋';

  @override
  String get f_base_three_rooms => '基本：3部屋';

  @override
  String get f_base_four_plus => '基本：4部屋以上';

  @override
  String get f_per_extra_bathroom => '浴室追加ごと';

  @override
  String get f_per_balcony => 'バルコニーごと';

  @override
  String get f_duplex => 'メゾネット';

  @override
  String get f_no_elevator_high_floor => 'EVなし＋3階以上';

  @override
  String get cIssueCoupon => 'クーポン発行';

  @override
  String get cCouponName => 'クーポン名';

  @override
  String get cCouponPhones => '対象電話番号（改行区切り）';

  @override
  String get cAllCustomers => '全顧客へ';

  @override
  String cIssued(String n) {
    return '$n枚発行しました';
  }

  @override
  String get cContent => 'コンテンツ';

  @override
  String get cKind_notice => 'お知らせ';

  @override
  String get cKind_tip => 'ヒント';

  @override
  String get cKind_faq => 'FAQ';

  @override
  String get cKind_banner => 'バナー';

  @override
  String get cKind_legal => '規約';

  @override
  String get cNewContent => '新規コンテンツ';

  @override
  String get cTitleField => 'タイトル';

  @override
  String get cBodyField => '本文';

  @override
  String get cSlug => '識別子（規約：privacy / terms）';

  @override
  String get cVerify => '承認';

  @override
  String get cSuspend => '停止';

  @override
  String get cPro_pending => '承認待ち';

  @override
  String get cPro_verified => '活動中';

  @override
  String get cPro_suspended => '停止中';

  @override
  String get cCompleted => '完了';

  @override
  String get cCancelledN => 'キャンセル';

  @override
  String get cRating => '評価';

  @override
  String get cFeeRate => '手数料率 %';

  @override
  String get cRunPayouts => '精算支払いを実行';

  @override
  String get cPayoutDate => '支払基準日';

  @override
  String cPayoutDone(String n) {
    return '$n名に支払いました';
  }

  @override
  String get cHold => '保留';

  @override
  String get cRelease => '保留解除';

  @override
  String get cNet => '支払額';

  @override
  String get cAddStaff => 'スタッフ追加';

  @override
  String get cRoleAdmin => '管理者';

  @override
  String get cRoleConsultant => '相談員';

  @override
  String get cDeactivate => '無効化';

  @override
  String get cActivate => '有効化';

  @override
  String get cPasswordRule => '12文字以上';

  @override
  String get cAdminOnly => '管理者のみ操作できます';

  @override
  String cBookingsCount(String n) {
    return '予約$n件';
  }

  @override
  String get cJoined => '登録';

  @override
  String get cNewBooking => '新しい予約';

  @override
  String get cNewMessage => '新着メッセージ';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'キャンセル';

  @override
  String get next => '次へ';

  @override
  String get close => '閉じる';

  @override
  String get save => '保存';

  @override
  String get delete => '削除';

  @override
  String get edit => '編集';

  @override
  String get change => '変更';

  @override
  String get retry => '再試行';

  @override
  String get yes => 'はい';

  @override
  String get no => 'いいえ';

  @override
  String get required => '必須';

  @override
  String get viewAll => 'すべて見る';

  @override
  String get today => '今日';

  @override
  String get errorGeneric => '問題が発生しました。もう一度お試しください。';

  @override
  String get errorNetwork => 'インターネット接続を確認してください';

  @override
  String get err_invalid_phone => '携帯番号を確認してください';

  @override
  String get err_otp_invalid => '認証番号が違います';

  @override
  String get err_otp_expired => '認証番号の有効期限が切れました';

  @override
  String get err_rate_limited => '試行回数が多すぎます';

  @override
  String get err_studio_too_large => 'ワンルーム清掃は10坪以下のお部屋のみです';

  @override
  String get err_date_out_of_range => '明日から60日以内を選んでください';

  @override
  String get err_slot_full => 'その時間は埋まりました';

  @override
  String get err_coupon_expired => '期限切れのクーポンです';

  @override
  String get err_coupon_used => '使用済みのクーポンです';

  @override
  String get err_coupon_wrong_service => 'このサービスには使えません';

  @override
  String get err_payment_failed => '決済が承認されませんでした';

  @override
  String get err_payment_method_required => '支払い方法を選んでください';

  @override
  String get err_cancellation_window_closed => '訪問2日前からは相談チーム経由でキャンセルできます';

  @override
  String get err_address_required => '訪問先住所を登録してください';

  @override
  String get err_already_taken => '他のパートナーが先に受けました';

  @override
  String get err_invalid_address => '住所をすべて入力してください';

  @override
  String get tabHome => 'ホーム';

  @override
  String get tabBookings => '予約';

  @override
  String get tabChat => '相談';

  @override
  String get tabMore => 'その他';

  @override
  String get introTitle => 'プロの清掃を\nいちばん簡単に予約';

  @override
  String get introBody => '明朗価格・確かなチーム・リアルタイム進行';

  @override
  String get introStart => '電話番号ではじめる';

  @override
  String get loginPhoneTitle => '携帯番号を入力してください';

  @override
  String get loginPhoneHint => '010-0000-0000';

  @override
  String get loginSendCode => '認証番号を送信';

  @override
  String get loginCodeTitle => '6桁の認証番号を入力';

  @override
  String loginCodeSentTo(String phone) {
    return '$phone に送信しました';
  }

  @override
  String get loginResend => '再送信';

  @override
  String get loginVerify => '確認';

  @override
  String get loginTerms => '続行すると利用規約とプライバシーポリシーに同意したことになります';

  @override
  String get profileTitle => 'お名前を教えてください';

  @override
  String get profileNameHint => 'お名前';

  @override
  String get profileDone => 'はじめる';

  @override
  String get welcomeToast => 'ウェルカムクーポンを2枚お届けしました';

  @override
  String get svc_studio => 'ワンルーム清掃';

  @override
  String get svc_kitchen => 'キッチン清掃';

  @override
  String get svc_bathroom => '浴室清掃';

  @override
  String get svc_mattress => 'マットレス清掃';

  @override
  String get svc_aircon => 'エアコン清掃';

  @override
  String get svc_sofa => 'ソファ清掃';

  @override
  String get svc_move_out => '退去清掃';

  @override
  String get svc_move_in => '入居清掃';

  @override
  String get svcShort_studio => 'ワンルーム';

  @override
  String get svcShort_kitchen => 'キッチン';

  @override
  String get svcShort_bathroom => '浴室';

  @override
  String get svcShort_mattress => 'マットレス';

  @override
  String get svcShort_aircon => 'エアコン';

  @override
  String get svcShort_sofa => 'ソファ';

  @override
  String get svcShort_move_out => '退去';

  @override
  String get svcShort_move_in => '入居';

  @override
  String get svcDesc_studio => '10坪以下のワンルーム(1部屋+浴室)を2時間しっかり清掃します。';

  @override
  String get svcDesc_kitchen => 'シンク・コンロ・レンジフード外側・天板を集中清掃します。';

  @override
  String get svcDesc_bathroom => '棚・蛇口・洗面台・便器を内外清掃し、床の水気まで仕上げます。';

  @override
  String get svcDesc_mattress => '専用機材でホコリ・ダニ・シミを吸引し、スチームで除菌洗浄します。';

  @override
  String get svcDesc_aircon => '分解して熱交換器・送風ファン・フィルターを高圧洗浄し除菌します。';

  @override
  String get svcDesc_sofa => '素材に合った洗剤で汚れを分解し、湿式抽出で洗浄します。';

  @override
  String get svcDesc_move_out => '退去前、荷物を出したお部屋をプロチームが機材持参で清掃します。';

  @override
  String get svcDesc_move_in => '入居前、プロチームが機材持参で新居を清掃します。';

  @override
  String get svcNotes_bathroom =>
      '排水口・便器の詰まりがある場合は制限されます\n特殊薬剤・天井・換気扇の清掃は対象外です\n古いカビや頑固な汚れは完全に落ちない場合があります';

  @override
  String get svcNotes_mattress =>
      'シングルからキングまで同料金です\n完全乾燥まで4〜6時間かかります\nスプリング損傷などの構造的問題は改善しません';

  @override
  String get svcNotes_aircon =>
      '製造10年以上の製品は分解洗浄が難しい場合があります\n室外機は含まれません\n洗浄前後に動作を確認します';

  @override
  String get svcNotes_sofa =>
      '革ソファはクリーニングと保湿コーティングで対応します\n古いシミや色移りは完全に落ちない場合があります\n完全乾燥まで4〜6時間かかります';

  @override
  String get unitTitle_bathroom => '浴室の数';

  @override
  String get unitTitle_mattress => 'マットレスの数';

  @override
  String get unitTitle_aircon => 'エアコンの種類';

  @override
  String get unitTitle_sofa => 'ソファのサイズ';

  @override
  String unit_count(String n) {
    return '$n台';
  }

  @override
  String get unit_wall => '壁掛け1台';

  @override
  String get unit_stand => 'スタンド1台';

  @override
  String get unit_two_in_one => '2in1（スタンド+壁掛け）';

  @override
  String get unit_ceiling => '天井埋込1台';

  @override
  String get unit_seat_1_2 => '1〜2人掛け';

  @override
  String get unit_seat_3 => '3人掛け';

  @override
  String get unit_seat_4_plus => '4人掛け以上';

  @override
  String get unit_l_shape => 'L字・カウチ';

  @override
  String durH(String h) {
    return '$h時間';
  }

  @override
  String durHM(String h, String m) {
    return '$h時間$m分';
  }

  @override
  String durM(String m) {
    return '$m分';
  }

  @override
  String about(String value) {
    return '約$value';
  }

  @override
  String fromPrice(String price) {
    return '$price〜';
  }

  @override
  String get quoteBadge => '見積';

  @override
  String get status0 => '相談中';

  @override
  String get status1 => '予約確定';

  @override
  String get status2 => 'チーム決定';

  @override
  String get status3 => '清掃完了';

  @override
  String get statusCancelled => 'キャンセル済み';

  @override
  String homeGreeting(String name) {
    return '$nameさん、\n今日はどこをきれいにしますか？';
  }

  @override
  String get homeGreetingAnon => '今日はどこを\nきれいにしますか？';

  @override
  String get homeUpcoming => '次の予約';

  @override
  String dDay(String days) {
    return 'あと$days日';
  }

  @override
  String get homeServices => 'どの清掃が必要ですか？';

  @override
  String get homeAddAddress => '住所を登録すると利用可能なサービスが表示されます';

  @override
  String get homeAddAddressCta => '住所を登録';

  @override
  String homeRebook(String service) {
    return '$serviceをもう一度予約';
  }

  @override
  String get homeRebookBody => '前回と同じ条件ですぐ予約';

  @override
  String get homeNotices => 'お知らせ';

  @override
  String get trustVat => '税込価格、\n追加料金なし';

  @override
  String get trustCancel => '訪問2日前まで\n無料キャンセル';

  @override
  String get trustCard => 'カード情報は\n決済会社のみが保管';

  @override
  String stepOf(String current, String total) {
    return '$current / $total';
  }

  @override
  String get chooseDate => '日付を選ぶ';

  @override
  String get notIncluded => 'ご確認ください';

  @override
  String studioBlockedTitle(String size) {
    return '$size坪はワンルーム清掃の対象外です';
  }

  @override
  String get studioBlockedBody => '相談チームがお部屋に合うサービスをご提案します。';

  @override
  String get consultCta => '相談する';

  @override
  String get addressTitle => 'どちらに伺いますか？';

  @override
  String get addressAdd => '新しい住所を追加';

  @override
  String get addressLabel => '名前';

  @override
  String get addressLabelHint => '例：自宅';

  @override
  String get addressDistrict => '区';

  @override
  String get addressRoad => '道路名住所';

  @override
  String get addressDetail => '詳細住所';

  @override
  String get addressSize => '広さ（坪）';

  @override
  String get addressSizeHelp => '専有面積・1坪≈3.3㎡';

  @override
  String get addressHome => '自宅';

  @override
  String get addressOffice => 'オフィス';

  @override
  String get addressEmpty => '保存された住所はありません';

  @override
  String get addressSaved => '住所を保存しました';

  @override
  String pyeong(String n) {
    return '$n坪';
  }

  @override
  String get scheduleTitle => 'いつ伺いますか？';

  @override
  String get scheduleArrival => '到着時間';

  @override
  String get scheduleFull => '満席';

  @override
  String scheduleWindow(String start, String end) {
    return '$start〜$end到着';
  }

  @override
  String scheduleEnds(String duration, String time) {
    return '所要$duration・$time頃に終了';
  }

  @override
  String get scheduleRange => '明日から60日以内で予約できます';

  @override
  String get morning => '午前';

  @override
  String get afternoon => '午後';

  @override
  String get scheduleQuoteNote => '正確な到着時間は相談でご案内します';

  @override
  String get goToPayment => 'お支払いへ';

  @override
  String get prepTitle => '訪問前にご準備ください';

  @override
  String get prepBody => '準備がないと一部作業が制限されます';

  @override
  String get prepAsk => '準備が難しい場合は相談でお知らせください';

  @override
  String get tool_vacuum => '掃除機';

  @override
  String get tool_trash => 'ゴミ袋';

  @override
  String get tool_mop => 'モップ';

  @override
  String get tool_cloth => '雑巾';

  @override
  String get tool_gloves => 'ゴム手袋';

  @override
  String get tool_sponge => 'スポンジ';

  @override
  String get tool_spray => '多目的洗剤';

  @override
  String get checkoutTitle => 'お支払い';

  @override
  String get coupon => 'クーポン';

  @override
  String get couponNone => '使わない';

  @override
  String couponAvailable(String count) {
    return '利用可能 $count枚';
  }

  @override
  String get paymentMethod => '支払い方法';

  @override
  String get addPaymentMethod => '支払い方法を登録';

  @override
  String get methodCard => 'クレジット・デビットカード';

  @override
  String get methodKakao => 'KakaoPay';

  @override
  String get methodNaver => 'Naver Pay';

  @override
  String get methodToss => 'Toss Pay';

  @override
  String get methodRegistered => '登録済み';

  @override
  String get methodAdded => '支払い方法を登録しました';

  @override
  String get listPrice => 'サービス料金';

  @override
  String get discount => 'クーポン割引';

  @override
  String get total => 'お支払い金額';

  @override
  String get vatIncluded => '税込';

  @override
  String payAmount(String amount) {
    return '$amountを支払う';
  }

  @override
  String get needMethod => '支払い方法を登録してください';

  @override
  String freeCancelUntil(String date) {
    return '$dateまで無料キャンセル';
  }

  @override
  String get doneTitle => '予約が完了しました';

  @override
  String get doneBody => 'チームが決まり次第お知らせします';

  @override
  String get doneQuoteTitle => '相談を受け付けました';

  @override
  String get doneQuoteBody => '相談チームが確認後、最終見積をお送りします。相談タブでご確認ください。';

  @override
  String get goHome => 'ホームへ';

  @override
  String get viewBooking => '予約を見る';

  @override
  String get bookingsTitle => '予約';

  @override
  String get bookingsUpcoming => 'これからの予約';

  @override
  String get bookingsPast => '過去の予約';

  @override
  String get bookingsEmpty => 'まだ予約はありません';

  @override
  String get bookingsEmptyBody => '初回予約に使えるクーポンがあります';

  @override
  String get bookNow => '清掃を予約';

  @override
  String get detailTitle => '予約詳細';

  @override
  String get stepRequested => '相談受付';

  @override
  String get stepConfirmed => '予約確定';

  @override
  String get stepAssigned => 'チーム決定';

  @override
  String get stepCompleted => '清掃完了';

  @override
  String teamVisiting(String team) {
    return '$teamが伺います';
  }

  @override
  String get photosSoon => '完了後にビフォーアフター写真が表示されます';

  @override
  String get before => 'ビフォー';

  @override
  String get after => 'アフター';

  @override
  String get prepCheck => '準備物チェック';

  @override
  String get prepAllSet => '準備完了';

  @override
  String get visitAddress => '訪問先';

  @override
  String get paid => '決済';

  @override
  String get askTeam => '相談チームに問い合わせ';

  @override
  String get cancelBooking => '予約をキャンセル';

  @override
  String get cancelTitle => '予約をキャンセルしますか？';

  @override
  String get cancelFree => '全額返金され、クーポンも戻ります。';

  @override
  String get cancelKeep => 'キャンセルしない';

  @override
  String get cancelled => 'キャンセルしました';

  @override
  String get reschedule => '日程変更';

  @override
  String get rescheduled => '日程を変更しました';

  @override
  String get visitNotes => '訪問時のご要望';

  @override
  String get notesEntry => '入館方法（オートロック番号など）';

  @override
  String get notesParking => '駐車';

  @override
  String get notesOther => 'その他';

  @override
  String get notesSaved => 'ご要望を保存しました';

  @override
  String depositDue(String amount) {
    return '予約金$amountのお支払いで確定します';
  }

  @override
  String get payDeposit => '予約金を支払う';

  @override
  String get waitingQuote => '相談チームが見積を準備中です';

  @override
  String get estimate => '概算金額';

  @override
  String get finalPrice => '最終見積';

  @override
  String get deposit => '予約金';

  @override
  String get balance => '残金';

  @override
  String balanceDue(String amount) {
    return '残金$amountをお支払いください';
  }

  @override
  String get payBalance => '残金を支払う';

  @override
  String get reviewTitle => '清掃はいかがでしたか？';

  @override
  String get reviewHint => '良かった点や改善点を教えてください';

  @override
  String ratingStars(String n) {
    return '$nつ星';
  }

  @override
  String get reviewSubmit => 'レビューを投稿';

  @override
  String get reviewThanks => 'レビューありがとうございます';

  @override
  String get bookAgain => '同じ条件で再予約';

  @override
  String get chatTitle => '相談';

  @override
  String get chatTeam => '相談チーム';

  @override
  String get chatHours => '平日 09:00–18:00';

  @override
  String get chatEmpty => 'ご質問はいつでもどうぞ';

  @override
  String get chatNew => '新しい相談';

  @override
  String get chatTopicTitle => 'どんなご相談ですか？';

  @override
  String get topicOther => 'その他のお問い合わせ';

  @override
  String get chatHint => 'メッセージを入力';

  @override
  String get chatSend => '送信';

  @override
  String get chatPhoto => '写真を送る';

  @override
  String get chatTyping => '入力中';

  @override
  String get quick_confirm => '予約を確定します';

  @override
  String get quick_price => '料金について';

  @override
  String get quick_date => '日程を変えたい';

  @override
  String get quick_parking => '駐車できますか？';

  @override
  String get quick_hello => 'こんにちは';

  @override
  String get quick_duration => 'どのくらいかかりますか？';

  @override
  String get quoteArrived => '最終見積が届きました';

  @override
  String get quoteDepositNow => '今お支払いの予約金10%';

  @override
  String get quoteBalanceLater => '清掃後の残金';

  @override
  String get quotePay => '予約金を払って確定';

  @override
  String get quotePaid => '支払い済み';

  @override
  String get requestCard => '見積依頼';

  @override
  String get sys_consultation_received => '相談を受け付けました';

  @override
  String sys_deposit_paid(String amount) {
    return '予約金$amountのお支払いが完了し、予約が確定しました。';
  }

  @override
  String get sys_booking_cancelled => '予約がキャンセルされました';

  @override
  String sys_status_changed(String status) {
    return '予約状況が「$status」になりました';
  }

  @override
  String get sys_job_completed => '清掃が完了しました。写真をご確認ください。';

  @override
  String sys_rescheduled(String date) {
    return '日程が$dateに変更されました';
  }

  @override
  String get sys_reschedule_declined => 'パートナーが新しい日程に対応できません。相談チームが再調整します。';

  @override
  String get moreTitle => 'その他';

  @override
  String get moreScope => 'サービス範囲';

  @override
  String get morePayments => '支払い方法';

  @override
  String get moreCoupons => 'クーポン';

  @override
  String get morePoints => 'ポイント';

  @override
  String get moreAccount => 'アカウント';

  @override
  String get moreAddresses => '住所管理';

  @override
  String get moreNotices => 'お知らせ';

  @override
  String get moreTips => 'お掃除のコツ';

  @override
  String get moreFaq => 'よくある質問';

  @override
  String get morePartner => 'パートナー提携';

  @override
  String get moreLanguage => '言語';

  @override
  String get langSystem => '端末の設定に従う';

  @override
  String moreVersion(String v) {
    return 'バージョン $v';
  }

  @override
  String get morePrivacy => 'プライバシーポリシー';

  @override
  String get moreTerms => '利用規約';

  @override
  String get moreLicenses => 'オープンソースライセンス';

  @override
  String get logout => 'ログアウト';

  @override
  String get deleteAccount => '退会';

  @override
  String get deleteAccountBody => '個人情報は削除され、元に戻せません。進行中の予約は先にキャンセルしてください。';

  @override
  String get couponsEmpty => 'クーポンはありません';

  @override
  String couponUntil(String date) {
    return '$dateまで';
  }

  @override
  String get couponUsed => '使用済み';

  @override
  String get couponExpired => '期限切れ';

  @override
  String get couponAnyService => '全サービス';

  @override
  String get coupon_welcome_studio => 'ウェルカム：ワンルーム';

  @override
  String get coupon_welcome_any => 'ウェルカムクーポン';

  @override
  String get pointsBalance => '保有ポイント';

  @override
  String get pointsEmpty => 'ポイント履歴はありません';

  @override
  String get accountName => '名前';

  @override
  String get accountPhone => '携帯番号';

  @override
  String get accountEmail => 'メール';

  @override
  String get accountLogin => 'ログイン方法';

  @override
  String get accountLoginPhone => '電話番号認証';

  @override
  String get methodsEmpty => '登録された支払い方法はありません';

  @override
  String get noContent => 'まだありません';

  @override
  String get quoteTypeTitle => 'どの清掃ですか？';

  @override
  String get type_standard => '退去清掃';

  @override
  String get type_same_day_move => '引越し当日清掃';

  @override
  String get type_some_luggage_left => '荷物が一部残る';

  @override
  String get type_normal_move_in => '通常入居';

  @override
  String get type_after_interior => 'リフォーム後';

  @override
  String get type_lived_in_deep_clean => '居住中の大掃除';

  @override
  String get luggageTitle => '荷物の状態は？';

  @override
  String get luggage_empty => '荷物なし';

  @override
  String get luggage_partly_unpacked => '一部片付け中';

  @override
  String get luggage_fully_lived_in => '生活中';

  @override
  String get luggage_unknown => 'わからない';

  @override
  String get quoteBasicTitle => 'お部屋の情報を教えてください';

  @override
  String get buildingType => '建物タイプ';

  @override
  String get building_apartment => 'マンション';

  @override
  String get building_villa => 'ヴィラ';

  @override
  String get building_officetel => 'オフィステル';

  @override
  String get building_house => '一戸建て';

  @override
  String get building_other => 'その他';

  @override
  String get layoutTitle => '間取り';

  @override
  String get layout_studio => 'ワンルーム';

  @override
  String get layout_one_and_half => '1.5ルーム';

  @override
  String get layout_two_rooms => '2部屋';

  @override
  String get layout_three_rooms => '3部屋';

  @override
  String get layout_four_plus => '4部屋以上';

  @override
  String get duplexTitle => 'メゾネットですか？';

  @override
  String get quoteSpaceTitle => '空間について教えてください';

  @override
  String get bathroomsLabel => '浴室';

  @override
  String get balconiesLabel => 'バルコニー・多目的室';

  @override
  String get elevatorTitle => 'エレベーターはありますか？';

  @override
  String get floor3Label => '3階以上';

  @override
  String get quoteEstimateTitle => '概算見積です';

  @override
  String get quoteEstimateBody => '相談で写真などを確認後、最終金額が決まります';

  @override
  String get quoteG1 => '最終金額は相談で確定';

  @override
  String get quoteG2 => '予約金10%で確定、残金は清掃後';

  @override
  String get quoteG3 => '確定前はいつでも無料キャンセル';

  @override
  String get quoteConfirmTitle => '依頼内容をご確認ください';

  @override
  String get quoteRequest => '相談を依頼';

  @override
  String get quoteNoPayNow => '今は支払い不要です';

  @override
  String get summaryType => '種類';

  @override
  String get summaryHome => 'お部屋';

  @override
  String get summaryDate => '訪問日程';

  @override
  String get themeTitle => 'テーマ';

  @override
  String get themeDark => 'ダーク';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeSystem => 'システム設定';

  @override
  String get themeTip => 'テーマを変更';

  @override
  String get pTabJobs => '仕事';

  @override
  String get pTabQuotes => '見積';

  @override
  String get pTabSchedule => '予定';

  @override
  String get pIntroTitle => '清掃のプロのための\n仕事・予定・精算';

  @override
  String get pIntroBody => '希望の地域と時間だけ働き、毎週精算';

  @override
  String get pOnbTitle => 'パートナー情報を入力';

  @override
  String get pOnbName => '代表者名';

  @override
  String get pOnbTeam => 'チーム名';

  @override
  String get pOnbServices => '対応できるサービス';

  @override
  String get pOnbAreas => '活動地域';

  @override
  String get pOnbDone => '申請する';

  @override
  String get pPendingTitle => '承認をお待ちください';

  @override
  String get pPendingBody => '運営チームが確認後お知らせします。その間に精算口座を登録してください。';

  @override
  String get pSuspended => 'アカウントが一時停止中です。運営にお問い合わせください。';

  @override
  String get pDirect => '即予約';

  @override
  String get pQuoteReq => '見積依頼';

  @override
  String get pShowClosed => '締切済みも表示';

  @override
  String get pSortNewest => '新着順';

  @override
  String get pSortVisit => '訪問日が近い順';

  @override
  String get pSortAmount => '金額が高い順';

  @override
  String get pNoJobs => '条件に合う仕事はありません';

  @override
  String get pNoJobsBody => 'サービス・地域・時間を広げると増えます';

  @override
  String get pPayout => '精算予定';

  @override
  String get pCustomerEstimate => '顧客の概算';

  @override
  String get pNew => 'NEW';

  @override
  String get pClosed => '締切';

  @override
  String get pPrivacyNote => '正確な住所と顧客情報は受諾後に表示されます';

  @override
  String get pAccept => '受ける';

  @override
  String get pAcceptConfirm => 'この仕事を受けますか？';

  @override
  String get pAcceptBody => '予定に追加され、顧客に通知されます。訪問2日前からのキャンセルは制限されます。';

  @override
  String get pAccepted => '仕事を受けました';

  @override
  String get pSendQuote => '見積を送る';

  @override
  String get pQuotePrice => '顧客支払額';

  @override
  String get pQuoteNote => '相談チームへのメモ';

  @override
  String get pQuoteSent => '見積を送りました';

  @override
  String pFee(String rate) {
    return '手数料$rate%';
  }

  @override
  String get pYouGet => '受取額';

  @override
  String get pQuoteAll => 'すべて';

  @override
  String get pQ_waiting => '待機中';

  @override
  String get pQ_selected => '選択';

  @override
  String get pQ_rejected => '不採用';

  @override
  String get pQ_closed => '終了';

  @override
  String get pUnseenOnly => '新しい結果のみ';

  @override
  String get pNoQuotes => '見積はありません';

  @override
  String get pMyQuote => '自分の見積';

  @override
  String get pWithdraw => '取り下げ';

  @override
  String get pWithdrawn => '見積を取り下げました';

  @override
  String get pOnlyMine => '自分の予定のみ';

  @override
  String pJobsCount(String n) {
    return '$n件';
  }

  @override
  String get pNoSchedule => '予定はありません';

  @override
  String get pCancelledBanner => 'キャンセルされた仕事です。完了できません。';

  @override
  String pRescheduleBanner(String from, String to) {
    return '日程変更依頼：$from → $to';
  }

  @override
  String get pRescheduleOk => '対応可能';

  @override
  String get pRescheduleNo => '難しい';

  @override
  String get pCustomer => '顧客';

  @override
  String get pCall => '安心番号で電話';

  @override
  String get pCallSoon => '安心番号はサービス開始時に有効になります';

  @override
  String get pQuietHours => '20時以降の電話はお控えください';

  @override
  String get pAssignee => '担当者';

  @override
  String get pChangeAssignee => '担当者を変更';

  @override
  String get pCustomerRequests => 'お客様のご要望';

  @override
  String get pTeamMemo => 'チームメモ（顧客には非表示）';

  @override
  String get pMemoSaved => 'メモを保存しました';

  @override
  String get pPayoutBreakdown => '精算内訳';

  @override
  String get pAfterBalance => '顧客の残金支払い後に精算されます';

  @override
  String get pChatOps => '運営とチャット';

  @override
  String get pComplete => '作業完了チェック';

  @override
  String get pBeforePhotos => '清掃前の写真';

  @override
  String get pAfterPhotos => '清掃後の写真';

  @override
  String get pAddPhoto => '写真を追加';

  @override
  String get pChecklist => '確認項目';

  @override
  String get pCheck1 => '依頼された全箇所を清掃した';

  @override
  String get pCheck2 => 'ゴミを片付け道具を回収した';

  @override
  String get pCheck3 => '窓・電気・水道を確認した';

  @override
  String get pCheck4 => 'お客様のご要望に対応した';

  @override
  String get pCompleteCta => '完了にする';

  @override
  String get pCompleteNeed => '各1枚以上の写真と全項目チェックが必要です';

  @override
  String get pCompleted => 'お疲れさまでした！';

  @override
  String pPayoutOn(String date, String amount) {
    return '$dateに$amountを精算予定';
  }

  @override
  String get pPayoutWaiting => '顧客の残金支払い後に精算日が決まります';

  @override
  String get pPendingPayout => '精算予定額';

  @override
  String get pSettlements => '精算履歴';

  @override
  String get pS_waiting_balance => '残金待ち';

  @override
  String get pS_pending => '精算予定';

  @override
  String get pS_paid => '支払済み';

  @override
  String get pS_held => '保留';

  @override
  String get pReviews => 'レビュー';

  @override
  String get pNoReviews => 'まだレビューはありません';

  @override
  String get pReplyLater => '返信機能は近日公開';

  @override
  String get pServicesAreas => 'サービス・地域';

  @override
  String get pPayoutAccount => '精算口座';

  @override
  String get pBank => '銀行';

  @override
  String get pAccountNumber => '口座番号';

  @override
  String get pHolder => '口座名義';

  @override
  String get pVerified => '確認済み';

  @override
  String get pUnverified => '確認中';

  @override
  String get pAccountSaved => '保存しました。変更時は再確認されます。';

  @override
  String get pWorkSchedule => '勤務スケジュール';

  @override
  String get pWeekdays => '勤務曜日';

  @override
  String get pDayParts => '勤務時間帯';

  @override
  String get pDaysOff => '休日';

  @override
  String get pAddDayOff => '休日を追加';

  @override
  String get pSaved => '保存しました';

  @override
  String get pTeam => 'チームメンバー';

  @override
  String get pOwner => '代表';

  @override
  String get pInvited => '招待中';

  @override
  String get pInvite => 'メンバーを招待';

  @override
  String get pInviteSent => '招待SMSを送りました';

  @override
  String get pRemove => '削除';

  @override
  String get pNotifications => '通知設定';

  @override
  String get pNotifyDirect => '新しい即予約';

  @override
  String get pNotifyQuotes => '見積依頼・結果';

  @override
  String get pNotifyChat => '運営からのメッセージ';

  @override
  String get pQuietNight => '夜間通知オフ（22〜8時）';

  @override
  String get pNewInquiry => '新規問い合わせ';

  @override
  String get pTopic_settlement => '精算';

  @override
  String get pTopic_reschedule => '日程変更・キャンセル';

  @override
  String get pTopic_app => 'アプリの使い方';

  @override
  String get pOpsTeam => '運営チーム';

  @override
  String get pViewJob => '仕事を見る';

  @override
  String pBookingNo(String n) {
    return '予約番号 $n';
  }

  @override
  String get pSize => '面積';

  @override
  String get pSchedule => '日程';

  @override
  String get pSpace => '空間情報';

  @override
  String get cSetup => '設定';

  @override
  String get cSetupTitle => 'サービス開始の準備';

  @override
  String cSetupProgress(String done, String total) {
    return '$done/$total 完了';
  }

  @override
  String get cSetupAllDone => 'すべての準備ができました！';

  @override
  String get cSetupBusiness => '事業者情報';

  @override
  String get cSetupBusinessName => 'サービス名';

  @override
  String get cSetupSupportPhone => 'サポート電話';

  @override
  String get cSetupSupportEmail => 'サポートメール';

  @override
  String get cSetupSupportHours => '受付時間';

  @override
  String get cSetupColor => 'ブランドカラー';

  @override
  String get cSetupLogo => 'ロゴをアップロード';

  @override
  String get cSetupCompany => '事業者情報（アプリ・サイト下部に表示）';

  @override
  String get cSetupLegalName => '商号';

  @override
  String get cSetupCeo => '代表者';

  @override
  String get cSetupRegNo => '事業者登録番号';

  @override
  String get cSetupMailOrderNo => '通信販売業届出番号';

  @override
  String get cSetupAddress => '所在地';

  @override
  String get cSetupPrivacyOfficer => '個人情報保護責任者';

  @override
  String get cSetupStoreLinks => 'ストアURL（入力するとサイトのボタンが有効に）';

  @override
  String get cSetupCustomerApp => 'お客様アプリ';

  @override
  String get cSetupPartnerApp => 'パートナーアプリ';

  @override
  String get cSetupSave => '保存';

  @override
  String get cSetupSaved => '保存しました';

  @override
  String get cSetupTest => '接続テスト';

  @override
  String get cSetupClear => '接続解除';

  @override
  String get cSetupConnected => '接続済み';

  @override
  String get cSetupNotConnected => '未接続';

  @override
  String get cSetupFromEnv => 'サーバー設定を使用中';

  @override
  String get cSetupCheckInApp => '保存済み・アプリでログインして確認';

  @override
  String get cSetupInvalidKey => 'キーが正しくありません。コピーした値を確認してください';

  @override
  String get cSetupUnreachable => 'サービスに接続できません。しばらくして再試行してください';

  @override
  String get cSetupKeepValue => '保存済み（変更時のみ入力）';

  @override
  String get cSetupGuide => '設定手順';

  @override
  String get cSetupOpenSite => 'サイトを開く';

  @override
  String get cSetupWebhook => 'Webhook URL（PortOneコンソールに貼り付け）';

  @override
  String get cCopied => 'コピーしました';

  @override
  String get cSetupDevMode => 'テストモードです。実際の決済・メッセージは送信されません';

  @override
  String get cSetupOptional => '任意';

  @override
  String get cIntPortone => '決済（PortOne）';

  @override
  String get cIntSolapi => 'SMS・アラートトーク（Solapi）';

  @override
  String get cIntPush => 'アプリ通知（Firebase）';

  @override
  String get cIntKakao => 'Kakaoログイン';

  @override
  String get cIntNaver => 'Naverログイン';

  @override
  String get cIntGoogle => 'Googleログイン';

  @override
  String get cIntApple => 'Appleログイン';

  @override
  String get cFirstRunTitle => 'ようこそ！オーナーのアカウントを作成してください';

  @override
  String get cFirstRunBody => 'インストール時に表示された12桁の設置コードを入力してください。';

  @override
  String get cFirstRunCode => '設置コード';

  @override
  String get cName => '名前';

  @override
  String get cFirstRunCreate => 'アカウントを作成して開始';

  @override
  String get cWrongSetupCode => '設置コードが違います';

  @override
  String get cWeakPassword => 'パスワードは12文字以上必要です';

  @override
  String get cInvalidValue => '入力内容を確認してください';
}
