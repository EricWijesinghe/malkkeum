// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class TRu extends T {
  TRu([String locale = 'ru']) : super(locale);

  @override
  String get addressSearch => 'Поиск адреса';

  @override
  String get addressSearchHint => 'Поиск по названию улицы, зданию или участку';

  @override
  String get addressSearchButton => 'Найти';

  @override
  String get addressSearchMinChars => 'Введите не менее 2 символов';

  @override
  String get addressNoResults => 'Ничего не найдено. Попробуйте другие слова.';

  @override
  String get addressManualEntry => 'Ввести вручную';

  @override
  String get cardRegisterTitle => 'Добавить карту';

  @override
  String get cIntJuso => 'Поиск адреса (juso.go.kr)';

  @override
  String get aiLabel => 'ИИ-ассистент';

  @override
  String get aiBadge => 'ИИ';

  @override
  String get aiCardHint =>
      'Автоматически отвечает в чатах клиентов. Каждое сообщение оплачивается по тарифу API.';

  @override
  String get aiModeOffline => 'Отвечает, только когда сотрудников нет';

  @override
  String get aiModeAlways => 'ИИ всегда отвечает первым';

  @override
  String get aiPause => 'Пауза для ИИ';

  @override
  String get aiResume => 'Возобновить ИИ';

  @override
  String get aiPausedNote => 'ИИ приостановлен для этого чата';

  @override
  String aiUsageMonth(String count) {
    return 'Вызовов ИИ в этом месяце: $count';
  }

  @override
  String get aiNotConfigured => 'ИИ-ассистент выключен';

  @override
  String get aiCapThreadLabel => 'Лимит ответов на чат в час';

  @override
  String get aiCapMemberLabel => 'Лимит ответов на клиента в день';

  @override
  String get aiCapDailyLabel => 'Лимит ответов в день на все чаты';

  @override
  String get aiCapHint =>
      'Только цифры. Оставьте пустым для значения по умолчанию.';

  @override
  String get apSocialOr => 'или';

  @override
  String get apSocialSignIn => 'Быстрый вход';

  @override
  String get apLoginKakao => 'Продолжить с Kakao';

  @override
  String get apLoginNaver => 'Продолжить с Naver';

  @override
  String get apLoginGoogle => 'Продолжить с Google';

  @override
  String get apLoginApple => 'Продолжить с Apple';

  @override
  String get apDevSocialNote =>
      'Режим разработки: вход в тестовый аккаунт, а не в настоящий аккаунт соцсети.';

  @override
  String get apSocialFailed =>
      'Не удалось выполнить быстрый вход. Попробуйте ещё раз.';

  @override
  String get apProviderNotConfigured => 'Этот способ входа пока недоступен';

  @override
  String get apPhoneTaken => 'Этот номер уже привязан к другому аккаунту';

  @override
  String get apPhoneAttachTitle => 'Подтвердите номер телефона';

  @override
  String get apPhoneAttachBody =>
      'Номер нужен для бронирований и связи с мастером. Подтверждение нужно только один раз.';

  @override
  String get apPayAllTitle => 'Выберите способ оплаты';

  @override
  String get apPaySavedTitle => 'Сохранённые способы';

  @override
  String get apPayMoreTitle => 'Все способы оплаты';

  @override
  String get apPayBillingHint =>
      'Сохраните один раз, и дальше оплата будет в одно касание';

  @override
  String get apPayCheckoutHint => 'Завершите оплату в окне платежа';

  @override
  String get apPayRegistering => 'Регистрируем…';

  @override
  String get apPayManageHint =>
      'Оплачивайте в одно касание сохранённым способом. Экспресс-платежи можно добавить здесь.';

  @override
  String get apMethodCard => 'Кредитная и дебетовая карта';

  @override
  String get apMethodKakao => 'KakaoPay';

  @override
  String get apMethodNaver => 'NaverPay';

  @override
  String get apMethodToss => 'TossPay';

  @override
  String get apMethodPayco => 'PAYCO';

  @override
  String get apMethodSamsung => 'Samsung Pay';

  @override
  String get apMethodApple => 'Apple Pay';

  @override
  String get apMethodTransfer => 'Банковский перевод';

  @override
  String get apMethodVirtual => 'Виртуальный счёт';

  @override
  String get apMethodPhone => 'Оплата с телефона';

  @override
  String get apMethodUnknown => 'Другой способ';

  @override
  String get apVaTitle => 'Счёт для перевода готов';

  @override
  String get apVaWaiting => 'Ожидаем перевод';

  @override
  String get apVaBody =>
      'Бронь подтвердится после поступления перевода в срок. Поступление проверяется автоматически.';

  @override
  String get apVaBank => 'Банк';

  @override
  String get apVaAccount => 'Номер счёта';

  @override
  String get apVaHolder => 'Владелец счёта';

  @override
  String get apVaAmount => 'Сумма перевода';

  @override
  String apVaDue(String due) {
    return 'Переведите до $due';
  }

  @override
  String get apVaCopy => 'Копировать';

  @override
  String get apVaCopied => 'Номер счёта скопирован';

  @override
  String get apVaBannerTitle => 'Бронь ждёт перевода';

  @override
  String apVaBannerBody(String amount, String due) {
    return '$amount · до $due';
  }

  @override
  String get apVaBannerAction => 'Открыть счёт';

  @override
  String get apPgTitle => 'Окно оплаты';

  @override
  String get apPgDevNote =>
      'Симуляция оплаты только для среды разработки. Реального списания не происходит.';

  @override
  String apPgPay(String amount) {
    return 'Оплатить $amount';
  }

  @override
  String get apPgIssue => 'Получить номер счёта';

  @override
  String get apPgCancel => 'Отменить оплату';

  @override
  String get apErrSlotFullRefunded =>
      'Это время только что заполнилось, поэтому оплата отменена автоматически';

  @override
  String get apErrCheckoutExpired =>
      'Время на оплату истекло. Попробуйте ещё раз.';

  @override
  String get apIdentityTitle => 'Подтверждение личности (PASS)';

  @override
  String get apIdentityBody =>
      'Подтверждаем вас по телефонному оператору. Это нужно для безопасных сделок и выплат.';

  @override
  String get apIdentityAction => 'Подтвердить личность';

  @override
  String get apIdentityDone => 'Личность подтверждена';

  @override
  String get apIdentityVerified => 'Подтверждено';

  @override
  String get apIdentityUnverified => 'Пока не подтверждено';

  @override
  String get apIdentityDevTitle => 'Тестовое подтверждение личности';

  @override
  String get apIdentityDevBody =>
      'В режиме разработки проверка проходит без реального подтверждения.';

  @override
  String get apIdentityDevPass => 'Пропустить';

  @override
  String get apPayManageTitle => 'Подключить экспресс-оплату';

  @override
  String get cTitle => 'Консоль оператора';

  @override
  String get cEmail => 'Эл. почта';

  @override
  String get cPassword => 'Пароль';

  @override
  String get cLogin => 'Войти';

  @override
  String get cLoginFailed => 'Неверная почта или пароль';

  @override
  String get cDashboard => 'Панель';

  @override
  String get cBookings => 'Брони';

  @override
  String get cQuoteDesk => 'Расчёт стоимости';

  @override
  String get cInbox => 'Обращения';

  @override
  String get cCatalog => 'Каталог · цены';

  @override
  String get cMarketing => 'Купоны · контент';

  @override
  String get cPartners => 'Партнёры';

  @override
  String get cSettlements => 'Выплаты';

  @override
  String get cCustomers => 'Клиенты';

  @override
  String get cStaff => 'Сотрудники';

  @override
  String get cSearchCommand => 'Поиск · команды';

  @override
  String get cPaletteHint => 'Введите название раздела или номер брони';

  @override
  String get cTodayJobs => 'Заказы на сегодня';

  @override
  String get cOpenQuotes => 'Ожидают расчёта';

  @override
  String get cUnassigned => 'Без бригады';

  @override
  String get cUnreadThreads => 'Непрочитанные обращения';

  @override
  String get cRevenue30 => 'Оплаты за 30 дней';

  @override
  String get cBookings30 => 'Брони за 30 дней';

  @override
  String get cByService => 'Брони по услугам (30 дней)';

  @override
  String get cAllStatus => 'Все статусы';

  @override
  String get cAllServices => 'Все услуги';

  @override
  String get cSearch => 'Поиск (номер, телефон, имя, адрес)';

  @override
  String get cNoResults => 'Ничего не найдено';

  @override
  String get cNumber => 'Номер';

  @override
  String get cVisit => 'Визит';

  @override
  String get cService => 'Услуга';

  @override
  String get cStatus => 'Статус';

  @override
  String get cTeam => 'Бригада';

  @override
  String get cAmount => 'Сумма';

  @override
  String get cCustomer => 'Клиент';

  @override
  String get cPayments => 'Платежи';

  @override
  String get cChangeStatus => 'Сменить статус';

  @override
  String get cTeamName => 'Назначенная бригада';

  @override
  String get cAssign => 'Назначить бригаду';

  @override
  String get cMarkDone => 'Отметить выполненной';

  @override
  String get cConfirm => 'Отметить подтверждённой';

  @override
  String get cCancelRefund => 'Отмена · возврат';

  @override
  String get cRefundAmount => 'Сумма возврата (пусто = полная)';

  @override
  String get cDone => 'Готово';

  @override
  String get cAnswers => 'Ответы клиента';

  @override
  String get cEstimateCalc => 'Автоматический расчёт';

  @override
  String get cBase => 'Базовая';

  @override
  String get cExtras => 'Дополнительно';

  @override
  String get cSurcharge => 'Наценка';

  @override
  String get cBeforeVat => 'Без НДС';

  @override
  String get cProQuotes => 'Расчёты партнёров';

  @override
  String get cNoProQuotes => 'Пока нет расчётов от партнёров';

  @override
  String get cFinalPrice => 'Итоговая цена для клиента';

  @override
  String get cQuoteNote => 'Комментарий для клиента';

  @override
  String get cSendQuote => 'Отправить клиенту расчёт';

  @override
  String get cQuoteSent => 'Расчёт отправлен';

  @override
  String get cCustomerChats => 'Клиенты';

  @override
  String get cPartnerChats => 'Партнёры';

  @override
  String get cSelectBooking => 'Выберите бронь';

  @override
  String get cRefunded => 'Возвращено';

  @override
  String get cPartRefunded => 'Частичный возврат';

  @override
  String get cFailed => 'Ошибка';

  @override
  String get cSelectThread => 'Выберите диалог';

  @override
  String get cReplyHint => 'Введите ответ · Ctrl+Enter — отправить';

  @override
  String get cOpenBooking => 'Открыть бронь';

  @override
  String get cShortcuts => 'J/K — навигация · Ctrl+K — команды';

  @override
  String get cPricing => 'Цены';

  @override
  String get cMinutes => 'Время (мин)';

  @override
  String get cActive => 'В продаже';

  @override
  String get cSaved => 'Сохранено';

  @override
  String get cSlotCapacity => 'Вместимость по времени прибытия';

  @override
  String get cUnlimited => 'Без ограничений';

  @override
  String get cFormula => 'Формула расчёта';

  @override
  String get cTabCancelPolicy => 'Политика отмены';

  @override
  String get cPolicyDefaultBanner =>
      'Это значение по умолчанию. Проверьте и сохраните, чтобы подтвердить.';

  @override
  String get cPolicyDaysBefore => 'Дней до визита (от)';

  @override
  String get cPolicyPercent =>
      'Комиссия % (пусто = отмена в приложении недоступна)';

  @override
  String get cPolicyMinFee => 'Минимальная комиссия (KRW)';

  @override
  String get cPolicyReschedule =>
      'Перенос разрешён (за сколько дней до визита)';

  @override
  String get cPolicyHint =>
      'Сразу применяется на экране отмены в приложении клиента. Условия обновятся в следующей сборке.';

  @override
  String get f_base_studio => 'База: студия';

  @override
  String get f_base_one_and_half => 'База: 1,5 комнаты';

  @override
  String get f_base_two_rooms => 'База: 2 комнаты';

  @override
  String get f_base_three_rooms => 'База: 3 комнаты';

  @override
  String get f_base_four_plus => 'База: 4+ комнаты';

  @override
  String get f_per_extra_bathroom => 'За каждую доп. ванную';

  @override
  String get f_per_balcony => 'За балкон';

  @override
  String get f_duplex => 'Двухуровневая';

  @override
  String get f_no_elevator_high_floor => 'Без лифта + 3 этаж и выше';

  @override
  String get cIssueCoupon => 'Выдать купоны';

  @override
  String get cCouponName => 'Название купона';

  @override
  String get cCouponPhones => 'Номера клиентов (каждый с новой строки)';

  @override
  String get cAllCustomers => 'Всем клиентам';

  @override
  String cIssued(String n) {
    return 'Выдано: $n';
  }

  @override
  String get cContent => 'Контент';

  @override
  String get cKind_notice => 'Объявление';

  @override
  String get cKind_tip => 'Совет';

  @override
  String get cKind_faq => 'FAQ';

  @override
  String get cKind_banner => 'Баннер';

  @override
  String get cKind_legal => 'Условия';

  @override
  String get cNewContent => 'Новый контент';

  @override
  String get cTitleField => 'Заголовок';

  @override
  String get cBodyField => 'Текст';

  @override
  String get cSlug => 'Идентификатор (условия: privacy / terms)';

  @override
  String get cVerify => 'Одобрить';

  @override
  String get cSuspend => 'Приостановить';

  @override
  String get cPro_pending => 'Ожидает одобрения';

  @override
  String get cPro_verified => 'Активен';

  @override
  String get cPro_suspended => 'Приостановлен';

  @override
  String get cCompleted => 'Выполнено';

  @override
  String get cCancelledN => 'Отменено';

  @override
  String get cRating => 'Рейтинг';

  @override
  String get cFeeRate => 'Комиссия %';

  @override
  String get cRunPayouts => 'Запустить выплаты';

  @override
  String get cPayoutDate => 'Выплатить за период до';

  @override
  String cPayoutDone(String n) {
    return 'Выплата отправлена: $n партнёрам';
  }

  @override
  String get cHold => 'Удержать';

  @override
  String get cRelease => 'Снять удержание';

  @override
  String get cNet => 'К выплате';

  @override
  String get cAddStaff => 'Добавить сотрудника';

  @override
  String get cRoleAdmin => 'Администратор';

  @override
  String get cRoleConsultant => 'Консультант';

  @override
  String get cDeactivate => 'Деактивировать';

  @override
  String get cActivate => 'Активировать';

  @override
  String get cPasswordRule => 'Не менее 12 символов';

  @override
  String get cAdminOnly => 'Только для администраторов';

  @override
  String cBookingsCount(String n) {
    return 'Броней: $n';
  }

  @override
  String get cJoined => 'Регистрация';

  @override
  String get cNewBooking => 'Пришла новая бронь';

  @override
  String get cNewMessage => 'Новое сообщение';

  @override
  String get cConfirmAsk => 'Вы уверены?';

  @override
  String get ok => 'ОК';

  @override
  String get cancel => 'Отмена';

  @override
  String get next => 'Далее';

  @override
  String get close => 'Закрыть';

  @override
  String get save => 'Сохранить';

  @override
  String get delete => 'Удалить';

  @override
  String get edit => 'Изменить';

  @override
  String get change => 'Изменить';

  @override
  String get retry => 'Повторить';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';

  @override
  String get required => 'Обязательно';

  @override
  String get viewAll => 'Смотреть все';

  @override
  String get today => 'Сегодня';

  @override
  String get errorGeneric =>
      'Что-то пошло не так. Попробуйте ещё раз немного позже.';

  @override
  String get errorNetwork => 'Проверьте подключение к интернету';

  @override
  String get err_invalid_phone => 'Проверьте номер телефона';

  @override
  String get err_otp_invalid => 'Неверный код подтверждения';

  @override
  String get err_otp_expired => 'Срок действия кода истёк. Запросите новый.';

  @override
  String get err_rate_limited => 'Слишком много попыток. Попробуйте позже.';

  @override
  String get err_studio_too_large =>
      'Уборка студии доступна только для квартир до 10 пхён';

  @override
  String get err_date_out_of_range =>
      'Выберите дату от завтрашнего дня и не позднее чем через 60 дней';

  @override
  String get err_slot_full => 'Это время уже занято. Выберите другое.';

  @override
  String get err_coupon_expired => 'Срок действия купона истёк';

  @override
  String get err_coupon_used => 'Этот купон уже использован';

  @override
  String get err_coupon_wrong_service =>
      'Этот купон нельзя использовать для данной услуги';

  @override
  String get err_payment_failed =>
      'Оплата не прошла. Попробуйте другой способ.';

  @override
  String get err_payment_method_required => 'Выберите способ оплаты';

  @override
  String get err_cancellation_window_closed =>
      'Эту бронь уже нельзя отменить в приложении. Свяжитесь с нашей командой';

  @override
  String get err_address_required => 'Добавьте адрес визита';

  @override
  String get err_already_taken => 'Другой мастер уже принял этот заказ';

  @override
  String get err_invalid_address => 'Заполните все поля адреса';

  @override
  String get tabHome => 'Главная';

  @override
  String get tabBookings => 'Брони';

  @override
  String get tabChat => 'Чат';

  @override
  String get tabMore => 'Ещё';

  @override
  String get introTitle => 'Уборка от профессионалов\nзабронируйте за минуту';

  @override
  String get introBody =>
      'Цены без сюрпризов · Проверенные бригады · Ход работ в реальном времени';

  @override
  String get introStart => 'Продолжить с номером телефона';

  @override
  String get loginPhoneTitle => 'Укажите номер телефона';

  @override
  String get loginPhoneHint => '010-0000-0000';

  @override
  String get loginSendCode => 'Получить код';

  @override
  String get loginCodeTitle => 'Введите 6-значный код';

  @override
  String loginCodeSentTo(String phone) {
    return 'Код отправлен на $phone';
  }

  @override
  String get loginResend => 'Отправить снова';

  @override
  String get loginVerify => 'Подтвердить';

  @override
  String get loginTerms =>
      'Продолжая, вы соглашаетесь с Условиями использования и Политикой конфиденциальности';

  @override
  String get profileTitle => 'Как к вам обращаться?';

  @override
  String get profileNameHint => 'Имя';

  @override
  String get profileDone => 'Начать';

  @override
  String get welcomeToast =>
      'Мы добавили в ваш кошелёк 2 купона на приветствие';

  @override
  String get svc_studio => 'Уборка студии';

  @override
  String get svc_kitchen => 'Уборка кухни';

  @override
  String get svc_bathroom => 'Уборка ванной';

  @override
  String get svc_mattress => 'Чистка матраса';

  @override
  String get svc_aircon => 'Чистка кондиционера';

  @override
  String get svc_sofa => 'Чистка дивана';

  @override
  String get svc_move_out => 'Уборка перед выездом';

  @override
  String get svc_move_in => 'Уборка перед заселением';

  @override
  String get svcShort_studio => 'Студия';

  @override
  String get svcShort_kitchen => 'Кухня';

  @override
  String get svcShort_bathroom => 'Ванная';

  @override
  String get svcShort_mattress => 'Матрас';

  @override
  String get svcShort_aircon => 'Кондиционер';

  @override
  String get svcShort_sofa => 'Диван';

  @override
  String get svcShort_move_out => 'Выезд';

  @override
  String get svcShort_move_in => 'Заезд';

  @override
  String get svcDesc_studio =>
      'Двухчасовая тщательная уборка студии до 10 пхён: одна комната и один санузел.';

  @override
  String get svcDesc_kitchen =>
      'Фокусная уборка кухни: мойка, плита, внешняя часть вытяжки и столешницы.';

  @override
  String get svcDesc_bathroom =>
      'Полки, краны, раковина и унитаз снаружи и внутри, пол в конце протираем досуха.';

  @override
  String get svcDesc_mattress =>
      'Профессиональное оборудование удаляет пыль, клещей и пятна, затем паровая санобработка.';

  @override
  String get svcDesc_aircon =>
      'Разбираем и промываем под давлением теплообменник, вентилятор и фильтр, затем санобработка.';

  @override
  String get svcDesc_sofa =>
      'Средство под ткань расщепляет загрязнения, затем влажная экстракция.';

  @override
  String get svcDesc_move_out =>
      'Перед выездом профессиональная бригада с оборудованием уберёт пустую квартиру.';

  @override
  String get svcDesc_move_in =>
      'Перед заселением профессиональная бригада с оборудованием уберёт новое жильё.';

  @override
  String get svcNotes_bathroom =>
      'Из-за засора в сливе или унитазе услуга может быть ограничена\nСпециальная химчистка, уборка потолка и вытяжки не производится\nСтарая плесень и въевшаяся грязь могут остаться не удалёнными полностью';

  @override
  String get svcNotes_mattress =>
      'Одинаковая цена от односпального до king-size\nПолное высыхание занимает 4–6 часов\nПовреждённые пружины и провисание устранить нельзя';

  @override
  String get svcNotes_aircon =>
      'Для устройств старше 10 лет разборка может быть небезопасной\nНаружный блок не входит в услугу\nПроверяем работу до и после чистки';

  @override
  String get svcNotes_sofa =>
      'Кожаные диваны чистятся с последующим увлажняющим покрытием\nСтарые пятна и перекрас могут не отойти полностью\nПолное высыхание занимает 4–6 часов';

  @override
  String get unitTitle_bathroom => 'Количество ванных';

  @override
  String get unitTitle_mattress => 'Количество матрасов';

  @override
  String get unitTitle_aircon => 'Тип кондиционера';

  @override
  String get unitTitle_sofa => 'Размер дивана';

  @override
  String unit_count(String n) {
    return '$n шт.';
  }

  @override
  String get unit_wall => 'Настенный, 1 шт.';

  @override
  String get unit_stand => 'Напольный, 1 шт.';

  @override
  String get unit_two_in_one => '2 в 1 (напольный + настенный)';

  @override
  String get unit_ceiling => 'Кассетный, 1 шт.';

  @override
  String get unit_seat_1_2 => '1–2 места';

  @override
  String get unit_seat_3 => '3 места';

  @override
  String get unit_seat_4_plus => '4 места и более';

  @override
  String get unit_l_shape => 'Угловой / кушетка';

  @override
  String durH(String h) {
    return '$h ч';
  }

  @override
  String durHM(String h, String m) {
    return '$h ч $m мин';
  }

  @override
  String durM(String m) {
    return '$m мин';
  }

  @override
  String about(String value) {
    return 'около $value';
  }

  @override
  String fromPrice(String price) {
    return 'от $price';
  }

  @override
  String get quoteBadge => 'Расчёт';

  @override
  String get status0 => 'На консультации';

  @override
  String get status1 => 'Бронь подтверждена';

  @override
  String get status2 => 'Бригада назначена';

  @override
  String get status3 => 'Уборка выполнена';

  @override
  String get statusCancelled => 'Отменено';

  @override
  String homeGreeting(String name) {
    return '$name,\nчто будем сегодня убирать?';
  }

  @override
  String get homeGreetingAnon => 'Что уберём\nсегодня?';

  @override
  String get homeUpcoming => 'Ближайшие брони';

  @override
  String dDay(String days) {
    return 'через $days дн.';
  }

  @override
  String get homeServices => 'Какая уборка нужна?';

  @override
  String get homeAddAddress =>
      'Добавьте адрес, и мы сразу покажем доступные услуги и цены';

  @override
  String get homeAddAddressCta => 'Добавить адрес';

  @override
  String homeRebook(String service) {
    return 'Забронировать «$service» снова';
  }

  @override
  String get homeRebookBody =>
      'Те же условия, что в прошлый раз, — всего два нажатия';

  @override
  String get homeNotices => 'Новости';

  @override
  String get trustVat => 'НДС включён\nцена без сюрпризов';

  @override
  String get trustCancel => 'Бесплатная отмена\nдо 2 дней до визита';

  @override
  String get trustCard => 'Данные карты хранятся\nтолько у платёжной компании';

  @override
  String stepOf(String current, String total) {
    return '$current из $total';
  }

  @override
  String get chooseDate => 'Выберите дату';

  @override
  String get notIncluded => 'Обязательно к прочтению';

  @override
  String studioBlockedTitle(String size) {
    return '$size пхён — это больше, чем для уборки студии';
  }

  @override
  String get studioBlockedBody =>
      'Консультант подберёт подходящую услугу для вашего жилья.';

  @override
  String get consultCta => 'Написать консультанту';

  @override
  String get addressTitle => 'Куда приехать?';

  @override
  String get addressAdd => 'Добавить новый адрес';

  @override
  String get addressLabel => 'Название';

  @override
  String get addressLabelHint => 'например: Дом';

  @override
  String get addressDistrict => 'Район';

  @override
  String get addressRoad => 'Адрес (по улице)';

  @override
  String get addressDetail => 'Квартира / этаж';

  @override
  String get addressSize => 'Площадь жилья (пхён)';

  @override
  String get addressSizeHelp => 'Полезная площадь · 1 пхён ≈ 3,3 м²';

  @override
  String get addressHome => 'Дом';

  @override
  String get addressOffice => 'Офис';

  @override
  String get addressEmpty => 'Нет сохранённых адресов';

  @override
  String get addressSaved => 'Адрес сохранён';

  @override
  String pyeong(String n) {
    return '$n пхён';
  }

  @override
  String get scheduleTitle => 'Когда приехать?';

  @override
  String get scheduleArrival => 'Время прибытия';

  @override
  String get scheduleFull => 'Занято';

  @override
  String scheduleWindow(String start, String end) {
    return 'Приедем $start–$end';
  }

  @override
  String scheduleEnds(String duration, String time) {
    return '$duration · закончим примерно в $time';
  }

  @override
  String get scheduleRange =>
      'Можно забронировать с завтрашнего дня и не позднее чем на 60 дней вперёд';

  @override
  String get morning => 'Утро';

  @override
  String get afternoon => 'День';

  @override
  String get scheduleQuoteNote => 'Точное время прибытия подтвердим в чате';

  @override
  String get goToPayment => 'Перейти к оплате';

  @override
  String get prepTitle => 'Подготовьте, пожалуйста';

  @override
  String get prepBody => 'Без этого некоторые работы могут быть ограничены';

  @override
  String get prepAsk => 'Не можете подготовить? Сообщите нашей команде';

  @override
  String get tool_vacuum => 'Пылесос';

  @override
  String get tool_trash => 'Мешки для мусора';

  @override
  String get tool_mop => 'Швабра';

  @override
  String get tool_cloth => 'Тряпки';

  @override
  String get tool_gloves => 'Резиновые перчатки';

  @override
  String get tool_sponge => 'Губка для мытья';

  @override
  String get tool_spray => 'Универсальное средство';

  @override
  String get checkoutTitle => 'Оплата';

  @override
  String get coupon => 'Купон';

  @override
  String get couponNone => 'Не использовать';

  @override
  String couponAvailable(String count) {
    return 'Доступно: $count';
  }

  @override
  String get paymentMethod => 'Способ оплаты';

  @override
  String get addPaymentMethod => 'Добавить способ оплаты';

  @override
  String get methodCard => 'Кредитная / дебетовая карта';

  @override
  String get methodKakao => 'KakaoPay';

  @override
  String get methodNaver => 'Naver Pay';

  @override
  String get methodToss => 'Toss Pay';

  @override
  String get methodRegistered => 'Добавлено';

  @override
  String get methodAdded => 'Способ оплаты добавлен';

  @override
  String get listPrice => 'Стоимость услуги';

  @override
  String get discount => 'Скидка по купону';

  @override
  String get total => 'Итого';

  @override
  String get vatIncluded => 'НДС включён';

  @override
  String payAmount(String amount) {
    return 'Оплатить $amount';
  }

  @override
  String get needMethod => 'Сначала добавьте способ оплаты';

  @override
  String freeCancelUntil(String date) {
    return 'Бесплатная отмена до $date';
  }

  @override
  String get doneTitle => 'Бронь оформлена!';

  @override
  String get doneBody => 'Сообщим, как только назначат бригаду';

  @override
  String get doneQuoteTitle => 'Заявка на консультацию принята';

  @override
  String get doneQuoteBody =>
      'Консультант проверит заявку и пришлёт итоговый расчёт. Найти его можно во вкладке «Чат».';

  @override
  String get goHome => 'На главную';

  @override
  String get viewBooking => 'Посмотреть бронь';

  @override
  String get bookingsTitle => 'Брони';

  @override
  String get bookingsUpcoming => 'Ближайшие';

  @override
  String get bookingsPast => 'Прошедшие';

  @override
  String get bookingsEmpty => 'Броней пока нет';

  @override
  String get bookingsEmptyBody => 'Купоны на первую бронь уже ждут вас';

  @override
  String get bookNow => 'Заказать уборку';

  @override
  String get detailTitle => 'Бронь';

  @override
  String get stepRequested => 'Заявка принята';

  @override
  String get stepConfirmed => 'Бронь подтверждена';

  @override
  String get stepAssigned => 'Бригада назначена';

  @override
  String get stepCompleted => 'Уборка выполнена';

  @override
  String teamVisiting(String team) {
    return '$team скоро приедет';
  }

  @override
  String get photosSoon => 'После уборки здесь появятся фото до и после';

  @override
  String photoThumb(String n) {
    return 'Фото $n';
  }

  @override
  String get before => 'До';

  @override
  String get after => 'После';

  @override
  String get prepCheck => 'Чек-лист подготовки';

  @override
  String get prepAllSet => 'Всё готово';

  @override
  String get visitAddress => 'Адрес';

  @override
  String get paid => 'Оплачено';

  @override
  String get askTeam => 'Написать нашей команде';

  @override
  String get cancelBooking => 'Отменить бронь';

  @override
  String get cancelTitle => 'Отменить бронь?';

  @override
  String get cancelFree =>
      'При отмене сейчас вся сумма вернётся, а купон будет возвращён.';

  @override
  String get cancelKeep => 'Оставить';

  @override
  String cancelFeeNow(String fee, String refund) {
    return 'Если отменить сейчас, будет удержано $fee, а $refund вернётся вам.';
  }

  @override
  String cancelFeeAccept(String fee) {
    return 'Принять комиссию $fee и отменить';
  }

  @override
  String get cancelled => 'Бронь отменена';

  @override
  String get reschedule => 'Перенести';

  @override
  String get rescheduled => 'Время изменено';

  @override
  String get visitNotes => 'Пожелания для бригады';

  @override
  String get notesEntry => 'Как попасть в дом (код домофона и т. д.)';

  @override
  String get notesParking => 'Парковка';

  @override
  String get notesOther => 'Другое';

  @override
  String get notesSaved => 'Пожелания сохранены';

  @override
  String depositDue(String amount) {
    return 'Бронь подтвердится после оплаты предоплаты $amount';
  }

  @override
  String get payDeposit => 'Оплатить предоплату';

  @override
  String get waitingQuote => 'Консультант готовит для вас расчёт';

  @override
  String get estimate => 'Ориентировочная сумма';

  @override
  String get finalPrice => 'Итоговый расчёт';

  @override
  String get deposit => 'Предоплата';

  @override
  String get balance => 'Остаток';

  @override
  String balanceDue(String amount) {
    return 'Оплатите остаток: $amount';
  }

  @override
  String get payBalance => 'Оплатить остаток';

  @override
  String get reviewTitle => 'Как прошла уборка?';

  @override
  String get reviewHint => 'Расскажите, что понравилось или что можно улучшить';

  @override
  String ratingStars(String n) {
    return '$n из 5';
  }

  @override
  String get reviewSubmit => 'Оставить отзыв';

  @override
  String get reviewThanks => 'Спасибо за отзыв!';

  @override
  String get bookAgain => 'Забронировать снова';

  @override
  String get chatTitle => 'Чат';

  @override
  String get chatTeam => 'Служба поддержки';

  @override
  String get chatHours => 'По будням 09:00–18:00';

  @override
  String get chatEmpty => 'Есть вопросы? Спрашивайте в любое время';

  @override
  String get chatNew => 'Новое обращение';

  @override
  String get chatTopicTitle => 'О чём вы хотите узнать?';

  @override
  String get topicOther => 'Другой вопрос';

  @override
  String get chatHint => 'Введите сообщение';

  @override
  String get chatSend => 'Отправить';

  @override
  String get chatPhoto => 'Отправить фото';

  @override
  String get chatTyping => 'Команда печатает…';

  @override
  String get quick_confirm => 'Подтвердите бронь, пожалуйста';

  @override
  String get quick_price => 'Интересует цена';

  @override
  String get quick_date => 'Хочу изменить дату';

  @override
  String get quick_parking => 'Есть ли парковка?';

  @override
  String get quick_hello => 'Здравствуйте';

  @override
  String get quick_duration => 'Сколько это займёт времени?';

  @override
  String get quoteArrived => 'Итоговый расчёт готов';

  @override
  String get quoteDepositNow => 'Предоплата сейчас: 10%';

  @override
  String get quoteBalanceLater => 'Остаток после уборки';

  @override
  String get quotePay => 'Оплатить предоплату и подтвердить';

  @override
  String get quotePaid => 'Оплачено';

  @override
  String get requestCard => 'Запрос расчёта';

  @override
  String get sys_consultation_received => 'Заявка на консультацию получена';

  @override
  String sys_deposit_paid(String amount) {
    return 'Предоплата $amount получена. Бронь подтверждена.';
  }

  @override
  String get sys_booking_cancelled => 'Бронь отменена';

  @override
  String sys_status_changed(String status) {
    return 'Статус изменён на «$status»';
  }

  @override
  String get sys_job_completed =>
      'Уборка завершена. Посмотрите фото до и после.';

  @override
  String sys_rescheduled(String date) {
    return 'Время перенесено на $date';
  }

  @override
  String get sys_reschedule_declined =>
      'Мастер не может прийти в новое время. Наша команда подберёт другое.';

  @override
  String get moreTitle => 'Ещё';

  @override
  String get moreScope => 'Что входит в услугу';

  @override
  String get morePayments => 'Способы оплаты';

  @override
  String get moreCoupons => 'Купоны';

  @override
  String get morePoints => 'Баллы за уборку';

  @override
  String get moreAccount => 'Данные аккаунта';

  @override
  String get moreAddresses => 'Адреса';

  @override
  String get moreNotices => 'Объявления';

  @override
  String get moreTips => 'Советы по уборке';

  @override
  String get moreFaq => 'Частые вопросы';

  @override
  String get morePartner => 'Стать партнёром';

  @override
  String get moreLanguage => 'Язык';

  @override
  String get langSystem => 'Как в настройках устройства';

  @override
  String moreVersion(String v) {
    return 'Версия $v';
  }

  @override
  String get morePrivacy => 'Политика конфиденциальности';

  @override
  String get moreTerms => 'Условия использования';

  @override
  String get moreLicenses => 'Лицензии открытого ПО';

  @override
  String get logout => 'Выйти';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get deleteAccountBody =>
      'Персональные данные будут удалены без возможности восстановления. Сначала отмените активные брони.';

  @override
  String get couponsEmpty => 'Купонов пока нет';

  @override
  String couponUntil(String date) {
    return 'До $date';
  }

  @override
  String get couponUsed => 'Использован';

  @override
  String get couponExpired => 'Срок истёк';

  @override
  String get couponAnyService => 'Любая услуга';

  @override
  String get coupon_welcome_studio => 'Купон на уборку студии при регистрации';

  @override
  String get coupon_welcome_any => 'Купон на приветствие';

  @override
  String get pointsBalance => 'Ваши баллы';

  @override
  String get pointsEmpty => 'Истории баллов пока нет';

  @override
  String get accountName => 'Имя';

  @override
  String get accountPhone => 'Телефон';

  @override
  String get accountEmail => 'Эл. почта';

  @override
  String get accountLogin => 'Способ входа';

  @override
  String get accountLoginPhone => 'Подтверждение по телефону';

  @override
  String get methodsEmpty => 'Нет способов оплаты';

  @override
  String get noContent => 'Пока здесь пусто';

  @override
  String get quoteTypeTitle => 'Какая уборка нужна?';

  @override
  String get type_standard => 'Уборка перед выездом';

  @override
  String get type_same_day_move => 'Уборка в день переезда';

  @override
  String get type_some_luggage_left => 'Остались вещи';

  @override
  String get type_normal_move_in => 'Обычное заселение';

  @override
  String get type_after_interior => 'После ремонта';

  @override
  String get type_lived_in_deep_clean => 'Генеральная уборка в жилой квартире';

  @override
  String get luggageTitle => 'Насколько заполнена квартира?';

  @override
  String get luggage_empty => 'Пусто';

  @override
  String get luggage_partly_unpacked => 'Частично разобрано';

  @override
  String get luggage_fully_lived_in => 'Полностью обжито';

  @override
  String get luggage_unknown => 'Не уверен(а)';

  @override
  String get quoteBasicTitle => 'Расскажите о жилье';

  @override
  String get buildingType => 'Тип здания';

  @override
  String get building_apartment => 'Квартира';

  @override
  String get building_villa => 'Малоэтажное жильё';

  @override
  String get building_officetel => 'Офисная квартира (officetel)';

  @override
  String get building_house => 'Частный дом';

  @override
  String get building_other => 'Другое';

  @override
  String get layoutTitle => 'Планировка';

  @override
  String get layout_studio => 'Студия';

  @override
  String get layout_one_and_half => '1,5 комнаты';

  @override
  String get layout_two_rooms => '2 комнаты';

  @override
  String get layout_three_rooms => '3 комнаты';

  @override
  String get layout_four_plus => '4 комнаты и более';

  @override
  String get duplexTitle => 'Это двухуровневая квартира?';

  @override
  String get quoteSpaceTitle => 'Расскажите о пространстве';

  @override
  String get bathroomsLabel => 'Ванные';

  @override
  String get balconiesLabel => 'Балкон · подсобное помещение';

  @override
  String get elevatorTitle => 'Есть лифт?';

  @override
  String get floor3Label => '3 этаж и выше';

  @override
  String get quoteEstimateTitle => 'Ориентировочный расчёт';

  @override
  String get quoteEstimateBody =>
      'Итоговая сумма определяется в чате после просмотра фото';

  @override
  String get quoteG1 => 'Итоговая сумма согласуется с вами в чате';

  @override
  String get quoteG2 =>
      'Предоплата 10% для подтверждения, остаток — после уборки';

  @override
  String get quoteG3 => 'До подтверждения можно бесплатно отменить';

  @override
  String get quoteConfirmTitle => 'Проверьте заявку';

  @override
  String get quoteRequest => 'Отправить заявку';

  @override
  String get quoteNoPayNow => 'Сейчас ничего не нужно оплачивать';

  @override
  String get summaryType => 'Тип уборки';

  @override
  String get summaryHome => 'Жильё';

  @override
  String get summaryDate => 'Визит';

  @override
  String get cpTitle => 'Политика отмены';

  @override
  String cpWhen(String days) {
    return 'за $days и более дней до визита';
  }

  @override
  String get cpWhenSameDay => 'В день визита';

  @override
  String get cpFree => 'Полный возврат';

  @override
  String cpFee(String percent, String fee, String refund) {
    return 'Комиссия $percent% ($fee), возврат $refund';
  }

  @override
  String get cpClosed => 'Отмена в приложении недоступна (проверка командой)';

  @override
  String get hhTitle => 'Данные о доме';

  @override
  String get hhAddPet => 'Добавить питомца';

  @override
  String get hhPetCount => 'Кол-во';

  @override
  String get hhFloorLabel => 'Этаж (для подвала — минус)';

  @override
  String get hhElevator => 'Есть лифт';

  @override
  String get hhNotes => 'Заметки';

  @override
  String get hhHint => 'Сохраняется за этим адресом и меняется в каждой брони.';

  @override
  String get themeTitle => 'Тема';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeSystem => 'Как в системе';

  @override
  String get themeTip => 'Сменить тему';

  @override
  String get err_price_changed =>
      'Цена изменилась. Проверьте новое предложение и попробуйте снова.';

  @override
  String get err_checkout_closed => 'Этот платёж уже закрыт. Начните заново.';

  @override
  String get err_checkout_refunded => 'Этот платёж отменён, деньги возвращены.';

  @override
  String get err_already_paid => 'Этот платёж уже оплачен.';

  @override
  String get err_quote_not_payable =>
      'Это предложение пока нельзя оплатить. Свяжитесь с нашей командой.';

  @override
  String get err_payment_method_disabled =>
      'Этот способ оплаты сейчас недоступен.';

  @override
  String get err_invalid_payment_method =>
      'Этот способ оплаты нельзя использовать. Выберите другой.';

  @override
  String get err_balance_not_due => 'Остаток пока не нужно оплачивать.';

  @override
  String get err_invalid_slot => 'Это время недоступно для выбранной услуги.';

  @override
  String get err_booking_changed =>
      'Бронирование изменилось. Обновите страницу и проверьте детали.';

  @override
  String get err_booking_closed => 'Это бронирование больше нельзя изменить.';

  @override
  String get err_reschedule_closed =>
      'Сейчас перенести визит нельзя. Свяжитесь с нашей командой.';

  @override
  String get err_too_many_open_requests =>
      'Слишком много открытых запросов. Сначала завершите один из них.';

  @override
  String get err_already_reviewed => 'Вы уже оставили отзыв об этом визите.';

  @override
  String get err_identity_not_verified => 'Сначала пройдите проверку личности.';

  @override
  String get err_email_taken => 'Этот email уже используется.';

  @override
  String get err_invalid_email => 'Проверьте адрес email.';

  @override
  String get err_file_too_large =>
      'Файл слишком большой. Загрузите файл меньшего размера.';

  @override
  String get err_unsupported_image =>
      'Этот формат фото не поддерживается. Загрузите JPG или PNG.';

  @override
  String get err_upload_quota =>
      'Достигнут лимит загрузок на сегодня. Попробуйте завтра.';

  @override
  String get err_provider_unreachable =>
      'Не удалось связаться с сервисом. Попробуйте чуть позже.';

  @override
  String get err_invalid_token => 'Не удалось войти. Попробуйте снова.';

  @override
  String get err_invalid_transition =>
      'Сейчас нельзя изменить статус таким образом.';

  @override
  String get err_job_not_started => 'Сначала начните работу.';

  @override
  String get err_job_not_active => 'Эта работа не активна.';

  @override
  String get err_quote_locked =>
      'Предложение заблокировано и не может быть изменено.';

  @override
  String get err_request_closed => 'Этот запрос закрыт.';

  @override
  String get err_team_full => 'Команда заполнена.';

  @override
  String get err_invalid_webhook_secret =>
      'Webhook secret должен начинаться с whsec_.';

  @override
  String get err_invalid_endpoint =>
      'Адрес endpoint должен начинаться с https://.';

  @override
  String get err_invalid_bucket => 'Некорректное имя bucket.';

  @override
  String get err_invalid_region => 'Некорректный регион.';

  @override
  String get err_invalid_retention =>
      'Срок хранения вне допустимого диапазона.';

  @override
  String get err_invalid_service_account =>
      'Некорректный файл service account.';

  @override
  String get err_invalid_mode => 'Выберите корректный режим AI.';

  @override
  String get err_invalid_model => 'Некорректное название модели AI.';

  @override
  String get err_missing_field => 'Заполните все обязательные поля.';

  @override
  String get err_invalid_amount => 'Введите корректную сумму.';

  @override
  String get err_cannot_deactivate_self =>
      'Нельзя деактивировать собственный аккаунт.';

  @override
  String get err_invalid_coupon => 'Этот купон недействителен.';

  @override
  String get err_settlement_state => 'Сейчас нельзя изменить расчёт.';

  @override
  String get err_deposit_required => 'Сначала нужно внести депозит.';

  @override
  String get err_payout_state =>
      'Статус выплаты изменился. Обновите и проверьте снова.';

  @override
  String get err_payout_provider => 'Этот способ выплаты сейчас недоступен.';

  @override
  String get err_unsupported_bank => 'Этот банк не поддерживается для выплат.';

  @override
  String get err_toss_unverified =>
      'Выплаты Toss пока недоступны. Используйте ручной перевод.';

  @override
  String get err_invalid_cap => 'Введите число в допустимом диапазоне.';

  @override
  String get err_invalid_capacity => 'Введите корректную вместимость.';

  @override
  String get err_seller_declined =>
      'Toss не одобрил регистрацию продавца. Проверьте данные бизнеса.';

  @override
  String get err_payout_account_unverified =>
      'У этого партнёра ещё нет подтверждённого счёта для выплат. Сначала подтвердите счёт.';

  @override
  String get guestSheetTitle => 'Войдите, чтобы продолжить';

  @override
  String get guestSheetBody =>
      'Все, что вы ввели, сохранится. Продолжите с того же места.';

  @override
  String get greetMorning => 'Доброе утро';

  @override
  String get greetAfternoon => 'Добрый день';

  @override
  String get greetEvening => 'Добрый вечер';

  @override
  String get feedHeading => 'Для вас';

  @override
  String get feedTitleDue => 'Пора на следующую уборку';

  @override
  String get feedTitleRebook => 'Снова запишитесь к партнёру на 5 звёзд';

  @override
  String get feedTitleDraft => 'Продолжить расчёт стоимости';

  @override
  String get feedTitleSeasonal => 'Уборка под это время года';

  @override
  String get feedTitleSize => 'Расчёт по сохранённой площади';

  @override
  String get feedTitleSubscription => 'Экономьте с подпиской';

  @override
  String get feedTitleDistrict => 'Соседи тоже записываются';

  @override
  String feedWhyCadence(String days) {
    return 'С последней уборки прошло $days дн.';
  }

  @override
  String feedWhyRated(String days) {
    return 'Вы поставили этому партнёру 5 звёзд $days дн. назад';
  }

  @override
  String get feedWhyDraft => 'На этом устройстве остался незавершённый расчёт';

  @override
  String get feedWhySummer => 'Лучшее время почистить кондиционер перед летом';

  @override
  String get feedWhyMoving => 'Сезон переездов и въездов — много заявок';

  @override
  String feedWhyHoliday(String days) {
    return 'До генеральной уборки к празднику $days дн.';
  }

  @override
  String feedWhySize(String pyeong) {
    return 'Мгновенная оценка для сохранённых $pyeong пхён';
  }

  @override
  String get feedWhyRepeat => 'Если вы заказываете часто, подписка выгоднее';

  @override
  String feedWhyDistrict(String district, String count) {
    return 'На этой неделе в районе $district записались $count домов';
  }

  @override
  String get fFinance => 'Финансы';

  @override
  String get fPeriodDay => 'День';

  @override
  String get fPeriodWeek => 'Неделя';

  @override
  String get fPeriodMonth => 'Месяц';

  @override
  String get fPeriodCustom => 'Период';

  @override
  String get fFrom => 'С';

  @override
  String get fTo => 'По';

  @override
  String get fGross => 'Сумма платежей';

  @override
  String get fRefunds => 'Возвраты';

  @override
  String get fNetRevenue => 'Чистая выручка';

  @override
  String get fPlatformFee => 'Комиссия платформы';

  @override
  String get fPaidOut => 'Выплачено партнёрам';

  @override
  String get fPendingOut => 'Ожидают выплаты';

  @override
  String get fHeldOut => 'На удержании';

  @override
  String get fVatEstimate => 'НДС (оценка)';

  @override
  String get fVatNote =>
      'Оценка: 10% от комиссии платформы. Уточните у бухгалтера.';

  @override
  String get fAov => 'Средний чек';

  @override
  String get fBookings => 'Заказы';

  @override
  String get fCancelRate => 'Доля отмен';

  @override
  String get fDiscounts => 'Скидки и купоны';

  @override
  String get fMethods => 'Способы оплаты';

  @override
  String get fTrend => 'Динамика';

  @override
  String fRangeDays(String n) {
    return 'Последние $n дн.';
  }

  @override
  String get fRangeWeeks => 'Последние 12 недель';

  @override
  String get fRangeMonths => 'Последние 12 месяцев';

  @override
  String get fByPartner => 'Доход по партнёрам';

  @override
  String get fByService => 'Выручка по услугам';

  @override
  String get fExportTitle => 'Выгрузки для бухгалтерии';

  @override
  String get fExportLedger => 'CSV: журнал платежей';

  @override
  String get fExportSettlements => 'CSV: расчёты';

  @override
  String get fExportMonthly => 'CSV: месячная сводка (бухгалтер)';

  @override
  String get fDownload => 'Скачать CSV';

  @override
  String get fDownloadWebOnly => 'CSV скачивается в веб-консоли';

  @override
  String get fDownloadFailed => 'Не удалось скачать';

  @override
  String get fNoRecords => 'За этот период записей нет';

  @override
  String get fLoadFailed => 'Не удалось загрузить финансы';

  @override
  String get fRetry => 'Повторить';

  @override
  String get fColPartner => 'Партнёр';

  @override
  String get fColJobs => 'Заказов';

  @override
  String get fColSettled => 'Начислено';

  @override
  String get fColFee => 'Комиссия';

  @override
  String get fColNet => 'К выплате';

  @override
  String get pEarnings => 'Заработок';

  @override
  String get pNextPayout => 'Следующая выплата';

  @override
  String pNextPayoutOn(String date) {
    return 'Выплата $date';
  }

  @override
  String get pNoPayout => 'Выплат не запланировано';

  @override
  String get pPendingTotal => 'Ожидает выплаты';

  @override
  String get pPaidTotal => 'Выплачено';

  @override
  String get pWeekly => 'По неделям';

  @override
  String get pMonthly => 'По месяцам';

  @override
  String proofHomes(String count) {
    return 'В этом месяце убрано домов: $count';
  }

  @override
  String proofRating(String rating, String count) {
    return 'Средняя оценка $rating · отзывов: $count';
  }

  @override
  String get proofReviewsTitle => 'Последние отзывы';

  @override
  String get rebookTitle => 'Забронировать последнюю услугу снова?';

  @override
  String rebookBody(String service, String date) {
    return '$service · последний визит $date';
  }

  @override
  String get rebookButton => 'Забронировать снова';

  @override
  String seatsLeft(String count) {
    return 'Осталось мест: $count';
  }

  @override
  String get reviewSheetTitle => 'Как прошла уборка?';

  @override
  String get reviewPhotosAdd => 'Добавить фото';

  @override
  String get reviewPhotosHint => 'До 5 фото';

  @override
  String get reviewSaved => 'Спасибо за отзыв';

  @override
  String get reviewPhotoFailed =>
      'Не удалось загрузить фото. Попробуйте ещё раз.';

  @override
  String get referralTitle => 'Пригласите друга и получите купон';

  @override
  String referralBody(String amount) {
    return 'Когда друг завершит первую запись, вы оба получите купон на $amount';
  }

  @override
  String get referralCopy => 'Скопировать код';

  @override
  String get referralCopied => 'Реферальный код скопирован';

  @override
  String get referralClaimTitle => 'Есть реферальный код?';

  @override
  String get referralClaimField => 'Введите реферальный код';

  @override
  String get referralClaimButton => 'Применить';

  @override
  String get referralClaimed => 'Реферальный код применён';

  @override
  String referralStats(String invited, String rewarded) {
    return 'Приглашено: $invited · наград: $rewarded';
  }

  @override
  String get err_self_referral => 'Нельзя использовать свой код';

  @override
  String get err_referee_already_booked =>
      'Код можно ввести только до первой записи';

  @override
  String get err_already_referred => 'Реферальный код уже применён';

  @override
  String get err_invalid_referral_code => 'Проверьте реферальный код';

  @override
  String get err_referral_disabled => 'Рефералы временно приостановлены';

  @override
  String get err_invalid_photos =>
      'Можно прикрепить только фото, загруженные через Malkkeum';

  @override
  String get welcomeOfferTitle => 'Скидка на первую запись';

  @override
  String get welcomeOfferBody =>
      'Применяется автоматически к первой записи нового клиента. Не суммируется с купонами.';

  @override
  String get offerKindAmount => 'Фиксированная (вон)';

  @override
  String get offerKindPercent => 'Процент (%)';

  @override
  String get offerValue => 'Размер скидки';

  @override
  String get offerEnabled => 'Вкл.';

  @override
  String get offerSaved => 'Сохранено';

  @override
  String get referralSettingsTitle => 'Награда за рекомендацию';

  @override
  String get referralSettingsBody =>
      'Выплачивается, когда первая запись друга завершена и оплачена. Самореферал и повтор номера блокируются.';

  @override
  String get referralRewardAmount => 'Сумма награды (вон)';

  @override
  String get reviewsModerationTitle => 'Модерация отзывов';

  @override
  String get reviewHide => 'Скрыть';

  @override
  String get reviewShow => 'Показать снова';

  @override
  String get reviewHiddenTag => 'Скрыт';

  @override
  String get growthAverageRating => 'Средняя оценка';

  @override
  String growthReviewCount(String count) {
    return 'Отзывов: $count';
  }

  @override
  String get growthReferralConversion => 'Конверсия рефералов';

  @override
  String get growthTab => 'Рост';

  @override
  String growthReferralValue(String rewarded, String invited) {
    return '$rewarded из $invited';
  }

  @override
  String get locUseCurrent => 'Использовать моё местоположение';

  @override
  String get locConsentTitle => 'Условия сервиса на основе геолокации';

  @override
  String get locConsentBody =>
      'Чтобы найти адрес по текущему местоположению, примите условия сервиса на основе геолокации. Мы определяем местоположение один раз, только когда вы нажимаете «Использовать моё местоположение», и используем его только для подсказки адреса. Координаты не сохраняются на наших серверах. Согласие можно отозвать в любой момент в разделе «Настройки согласий».';

  @override
  String get locConsentAgree => 'Принять и продолжить';

  @override
  String get locSuggestionTitle => 'Это ваш адрес?';

  @override
  String get locUseAddress => 'Использовать этот адрес';

  @override
  String get locDenied => 'Нет доступа к геолокации. Введите адрес вручную.';

  @override
  String get locServicesOff =>
      'Службы геолокации на устройстве отключены. Введите адрес вручную.';

  @override
  String get locTimeout =>
      'Определение местоположения занимает слишком много времени. Введите адрес вручную.';

  @override
  String get locNoAddress =>
      'Не удалось найти адрес для вашего местоположения. Введите адрес вручную.';

  @override
  String get uMaintenanceTitle => 'Ведутся технические работы';

  @override
  String get uMaintenanceBody =>
      'Мы улучшаем сервис. Пожалуйста, зайдите немного позже.';

  @override
  String get cmTab => 'Кампании';

  @override
  String get cmNew => 'Новая кампания';

  @override
  String get cmAudience => 'Аудитория';

  @override
  String get cmSegAll => 'Все клиенты';

  @override
  String get cmSegNever => 'Ни разу не бронировали';

  @override
  String cmSegLapsed(String days) {
    return 'Последний заказ $days+ дн. назад';
  }

  @override
  String get cmDays => 'Дней';

  @override
  String cmConsentCount(String total, String consented) {
    return 'Маркетинговое согласие: $consented из $total';
  }

  @override
  String get cmChannel => 'Канал';

  @override
  String get cmPush => 'Push в приложении';

  @override
  String get cmSms => 'SMS';

  @override
  String get cmTitle => 'Заголовок';

  @override
  String get cmBody => 'Текст';

  @override
  String get cmOptout => 'Номер для отказа (080)';

  @override
  String get cmPreview => 'Предпросмотр';

  @override
  String get cmSchedule => 'Время отправки';

  @override
  String get cmSendNow => 'Отправить сейчас';

  @override
  String get cmTestSend => 'Тест на мой телефон';

  @override
  String get cmCreate => 'Сохранить кампанию';

  @override
  String get cmNeedOptout => 'Для SMS нужен номер для отказа 080';

  @override
  String get cmLog => 'Журнал отправок';

  @override
  String cmStatSent(String count) {
    return 'Отправлено $count';
  }

  @override
  String cmStatSkipped(String count) {
    return 'Без согласия $count';
  }

  @override
  String cmStatFailed(String count) {
    return 'Ошибок $count';
  }

  @override
  String get cmSaved => 'Кампания сохранена';

  @override
  String anFunnel(String days) {
    return 'Воронка регистраций (последние $days дн.)';
  }

  @override
  String get anInstalls => 'Открыли приложение (с согласием)';

  @override
  String get anSignedUp => 'Зарегистрировались';

  @override
  String get anQuoted => 'Запросили расчёт';

  @override
  String get anBooked => 'Забронировали';

  @override
  String get anPaid => 'Оплатили';

  @override
  String get anRepeat => 'Повторные (2+)';

  @override
  String get anCohorts =>
      'Недельные когорты (доля заказов по неделе регистрации)';

  @override
  String anCohortSize(String count) {
    return 'Регистраций $count';
  }

  @override
  String anWeekAfter(String n) {
    return 'Заказ на неделе $n';
  }

  @override
  String get cOps => 'Состояние системы';

  @override
  String get oLevelGreen => 'В норме';

  @override
  String get oLevelYellow => 'Проверить';

  @override
  String get oLevelRed => 'Нужны действия';

  @override
  String get oOverall => 'Состояние сервера';

  @override
  String get oRefresh => 'Обновить';

  @override
  String get oVersion => 'Версия';

  @override
  String get oUptime => 'Время работы';

  @override
  String oUptimeValue(String hours, String minutes) {
    return '$hours ч $minutes мин';
  }

  @override
  String get oChecks => 'Проверки';

  @override
  String get oCheckDb => 'База данных';

  @override
  String oCheckDbValue(String ms, String mb) {
    return 'Отклик $ms мс · размер $mb МБ';
  }

  @override
  String get oCheckDisk => 'Диск сервера';

  @override
  String oCheckDiskValue(String pct) {
    return 'свободно $pct%';
  }

  @override
  String get oCheckBackup => 'Автоматическая копия';

  @override
  String oCheckBackupValue(String hours) {
    return 'Последняя копия $hours ч назад';
  }

  @override
  String get oCheckBackupNone => 'Копий пока нет';

  @override
  String get oCheckErrors => 'Ошибки сервера (24 ч)';

  @override
  String oCheckErrorsValue(String count) {
    return '$count';
  }

  @override
  String get oCheckPayments => 'Платежи для проверки';

  @override
  String oCheckPaymentsValue(String count) {
    return '$count (24 ч)';
  }

  @override
  String get oCheckWebhook => 'Уведомления об оплате (webhook)';

  @override
  String oCheckWebhookValue(String count) {
    return 'Ошибки подписи $count (24 ч)';
  }

  @override
  String get oIntegrations => 'Внешние сервисы';

  @override
  String get oIntNotSet => 'Не настроено';

  @override
  String oIntLastOk(String at) {
    return 'Последний успех $at';
  }

  @override
  String oIntLastFail(String at, String code) {
    return 'Последняя ошибка $at ($code)';
  }

  @override
  String get oIntNever => 'Пока не использовалось';

  @override
  String get oActDb =>
      'Нет подключения к базе данных. Выполните malkkeum logs на сервере; если проблема сохраняется, перезапустите сервер.';

  @override
  String get oActDisk =>
      'Свободно меньше 10% диска. Удалите старые копии или увеличьте диск.';

  @override
  String get oActBackup =>
      'Автоматическая копия просрочена. Выполните malkkeum backup на сервере и проверьте backups/backup.log.';

  @override
  String get oActErrors =>
      'Много ошибок сервера. Посмотрите строки error в malkkeum logs и передайте разработчику, если они повторяются.';

  @override
  String get oActPayments =>
      'Оплата могла пройти, но не обработалась автоматически. Проверьте её в PortOne и при необходимости верните деньги вручную.';

  @override
  String get oActWebhook =>
      'Не проходит проверка подписи уведомлений об оплате. Введите webhook secret заново в Настройки > Оплата (PortOne).';

  @override
  String get oActIntegration =>
      'Подключение не работает. Проверьте ключи в настройках и нажмите Test connection.';

  @override
  String get oActNotSet => 'Не настроено. Введите ключи в настройках.';

  @override
  String get oAlerts => 'Настройки оповещений';

  @override
  String get oAlertsHint =>
      'О проблемах сообщим во входящих и SMS на телефон владельца. Одна и та же проблема отправляется не чаще раза в 6 часов.';

  @override
  String get oRuleSms => 'Не отправляются SMS';

  @override
  String get oRulePush => 'Не работают push-уведомления';

  @override
  String get oRulePayment => 'Не работает подключение оплаты';

  @override
  String get oRuleStuck => 'Оплата не обработалась автоматически';

  @override
  String get oRuleSocial => 'Не работает вход через соцсети';

  @override
  String get oRuleBackup => 'Пропущена автоматическая копия';

  @override
  String get oRuleDisk => 'Диск почти заполнен';

  @override
  String get oRuleAuth => 'Подозрительная активность входа';

  @override
  String get oQuietHours => 'Тихие часы';

  @override
  String get oQuietFrom => 'С';

  @override
  String get oQuietTo => 'До';

  @override
  String oHour(String hour) {
    return '$hour:00';
  }

  @override
  String get oQuietHint =>
      'В это время оповещения не отправляются; после окончания придёт одно сообщение.';

  @override
  String get oAlertPhone => 'Телефон для оповещений';

  @override
  String get oAlertPhoneHint =>
      'Оставьте пустым, чтобы использовать номер поддержки из данных о компании.';

  @override
  String get oSave => 'Сохранить';

  @override
  String get oSaved => 'Настройки оповещений сохранены';

  @override
  String get oSaveFailed => 'Не удалось сохранить. Проверьте значения.';

  @override
  String get oLoadFailed => 'Не удалось загрузить состояние';

  @override
  String get oBackupOffsite => 'Внешняя копия (S3)';

  @override
  String get oBackupOffsiteOff =>
      'Выключено. Включите в Настройки > Внешняя копия.';

  @override
  String get oLastBackup => 'Последняя копия';

  @override
  String get oDiskFree => 'Свободное место';

  @override
  String get oNoData => 'Данных пока нет';

  @override
  String get cIntBackup => 'Внешняя копия (совместимо с S3)';

  @override
  String get pTabJobs => 'Заказы';

  @override
  String get pTabQuotes => 'Мои расчёты';

  @override
  String get pTabSchedule => 'График';

  @override
  String get pIntroTitle =>
      'Заказы, график и выплаты\nдля профессионалов уборки';

  @override
  String get pIntroBody =>
      'Работайте только там и тогда, когда хотите. Выплаты каждую неделю.';

  @override
  String get pOnbTitle => 'Расскажите о себе';

  @override
  String get pOnbName => 'Имя руководителя';

  @override
  String get pOnbTeam => 'Название бригады';

  @override
  String get pOnbServices => 'Услуги, которые вы выполняете';

  @override
  String get pOnbAreas => 'Районы работы';

  @override
  String get pOnbDone => 'Подать заявку';

  @override
  String get pPendingTitle => 'Ожидаем одобрения';

  @override
  String get pPendingBody =>
      'Мы отправим уведомление после проверки. А пока добавьте банковский счёт для выплат.';

  @override
  String get pSuspended =>
      'Аккаунт временно приостановлен. Свяжитесь с отделом операций.';

  @override
  String get pDirect => 'Прямая бронь';

  @override
  String get pQuoteReq => 'Запросы на расчёт';

  @override
  String get pShowClosed => 'Показать закрытые заказы';

  @override
  String get pSortNewest => 'Сначала новые';

  @override
  String get pSortVisit => 'Ближайшая дата визита';

  @override
  String get pSortAmount => 'Сначала дороже';

  @override
  String get pNoJobs => 'Сейчас нет подходящих заказов';

  @override
  String get pNoJobsBody =>
      'Расширьте услуги, районы или часы работы, чтобы увидеть больше заказов';

  @override
  String get pPayout => 'Ожидаемая выплата';

  @override
  String get pCustomerEstimate => 'Ориентировочная цена клиента';

  @override
  String get pNew => 'NEW';

  @override
  String get pClosed => 'Закрыт';

  @override
  String get pPrivacyNote =>
      'Точный адрес и данные клиента появятся после принятия заказа';

  @override
  String get pAccept => 'Принять заказ';

  @override
  String get pAcceptConfirm => 'Принять этот заказ?';

  @override
  String get pAcceptBody =>
      'Заказ появится в вашем графике, клиент получит уведомление о назначении бригады. За 2 дня до визита отменить будет нельзя.';

  @override
  String get pAccepted => 'Заказ принят';

  @override
  String get pSendQuote => 'Отправить расчёт';

  @override
  String get pQuotePrice => 'Цена для клиента';

  @override
  String get pQuoteNote => 'Комментарий для команды';

  @override
  String get pQuoteSent => 'Расчёт отправлен';

  @override
  String pFee(String rate) {
    return 'Комиссия $rate%';
  }

  @override
  String get pYouGet => 'Вы получаете';

  @override
  String get pQuoteAll => 'Все';

  @override
  String get pQ_waiting => 'Ожидание';

  @override
  String get pQ_selected => 'Выбран';

  @override
  String get pQ_rejected => 'Не выбран';

  @override
  String get pQ_closed => 'Закрыт';

  @override
  String get pUnseenOnly => 'Только новые результаты';

  @override
  String get pNoQuotes => 'Расчётов пока нет';

  @override
  String get pMyQuote => 'Мой расчёт';

  @override
  String get pWithdraw => 'Отозвать расчёт';

  @override
  String get pWithdrawn => 'Расчёт отозван';

  @override
  String get pOnlyMine => 'Только мои';

  @override
  String pJobsCount(String n) {
    return 'Заказов: $n';
  }

  @override
  String get pNoSchedule => 'На этот день ничего не запланировано';

  @override
  String get pCancelledBanner =>
      'Клиент отменил этот заказ. Отметить его выполненным нельзя.';

  @override
  String pRescheduleBanner(String from, String to) {
    return 'Запрос на перенос: $from → $to';
  }

  @override
  String get pRescheduleOk => 'Смогу прийти';

  @override
  String get pRescheduleNo => 'Не смогу';

  @override
  String get pCustomer => 'Клиент';

  @override
  String get pCall => 'Позвонить (защищённый номер)';

  @override
  String get pCallSoon =>
      'Защищённые звонки будут доступны после запуска сервиса';

  @override
  String get pQuietHours => 'Не звоните после 20:00';

  @override
  String get pAssignee => 'Ответственный';

  @override
  String get pChangeAssignee => 'Сменить ответственного';

  @override
  String get pCustomerRequests => 'Пожелания клиента';

  @override
  String get pHousehold => 'Данные о доме';

  @override
  String get pPets => 'Домашние животные';

  @override
  String get pPetDog => 'Собака';

  @override
  String get pPetCat => 'Кошка';

  @override
  String get pPetBird => 'Птица';

  @override
  String get pPetFish => 'Рыба';

  @override
  String get pPetOther => 'Другое животное';

  @override
  String get pAllergies => 'Аллергия и чувствительность';

  @override
  String get pPreferredProducts => 'Предпочитаемые средства';

  @override
  String get pParking => 'Парковка';

  @override
  String pFloor(String floor) {
    return '$floor этаж';
  }

  @override
  String get pElevatorYes => 'Есть лифт';

  @override
  String get pElevatorNo => 'Без лифта';

  @override
  String get pTeamMemo => 'Заметка для команды (клиент её не видит)';

  @override
  String get pMemoSaved => 'Заметка сохранена';

  @override
  String get pPayoutBreakdown => 'Выплата';

  @override
  String get pAfterBalance => 'Выплата после оплаты клиентом остатка';

  @override
  String get pChatOps => 'Чат с отделом операций';

  @override
  String get pComplete => 'Отметить работу выполненной';

  @override
  String get pBeforePhotos => 'Фото до уборки';

  @override
  String get pAfterPhotos => 'Фото после уборки';

  @override
  String get pAddPhoto => 'Добавить фото';

  @override
  String get pChecklist => 'Чек-лист';

  @override
  String get pCheck1 => 'Убраны все запрошенные зоны';

  @override
  String get pCheck2 => 'Мусор вынесен, инвентарь собран';

  @override
  String get pCheck3 => 'Проверены окна, электричество и вода';

  @override
  String get pCheck4 => 'Пожелания клиента выполнены';

  @override
  String get pCompleteCta => 'Отметить выполненным';

  @override
  String get pCompleteNeed =>
      'Добавьте хотя бы по одному фото и отметьте все пункты';

  @override
  String get pCompleted => 'Отличная работа!';

  @override
  String pPayoutOn(String date, String amount) {
    return '$amount будут выплачены $date';
  }

  @override
  String get pPayoutWaiting => 'Дата выплаты определится после оплаты клиентом';

  @override
  String get pPendingPayout => 'Ожидаемая выплата';

  @override
  String get pSettlements => 'Выплаты';

  @override
  String get pS_waiting_balance => 'Ждём остаток';

  @override
  String get pS_pending => 'Запланировано';

  @override
  String get pS_paid => 'Выплачено';

  @override
  String get pS_held => 'Удержано';

  @override
  String get pReviews => 'Отзывы клиентов';

  @override
  String get pNoReviews => 'Отзывов пока нет';

  @override
  String get pReplyLater => 'Ответы на отзывы скоро появятся';

  @override
  String get pServicesAreas => 'Услуги · районы';

  @override
  String get pPayoutAccount => 'Банковский счёт для выплат';

  @override
  String get pBank => 'Банк';

  @override
  String get pAccountNumber => 'Номер счёта';

  @override
  String get pHolder => 'Владелец счёта';

  @override
  String get pVerified => 'Подтверждён';

  @override
  String get pUnverified => 'Проверяется';

  @override
  String get pAccountSaved =>
      'Счёт сохранён. При изменении он проверяется заново.';

  @override
  String get pWorkSchedule => 'Рабочий график';

  @override
  String get pWeekdays => 'Рабочие дни';

  @override
  String get pDayParts => 'Рабочее время';

  @override
  String get pDaysOff => 'Выходные';

  @override
  String get pAddDayOff => 'Добавить выходной';

  @override
  String get pSaved => 'Сохранено';

  @override
  String get pTeam => 'Участники';

  @override
  String get pOwner => 'Руководитель';

  @override
  String get pInvited => 'Приглашён';

  @override
  String get pInvite => 'Пригласить участника';

  @override
  String get pInviteSent => 'Приглашение отправлено';

  @override
  String get pRemove => 'Удалить';

  @override
  String get pNotifications => 'Уведомления';

  @override
  String get pNotifyDirect => 'Новые прямые заказы';

  @override
  String get pNotifyQuotes => 'Запросы и результаты расчётов';

  @override
  String get pNotifyChat => 'Сообщения от отдела операций';

  @override
  String get pQuietNight => 'Не беспокоить ночью (22–08)';

  @override
  String get pNewInquiry => 'Новое обращение';

  @override
  String get pTopic_settlement => 'Выплаты';

  @override
  String get pTopic_reschedule => 'Перенос / отмена';

  @override
  String get pTopic_app => 'Помощь по приложению';

  @override
  String get pOpsTeam => 'Отдел операций';

  @override
  String get pViewJob => 'Открыть заказ';

  @override
  String pBookingNo(String n) {
    return 'Бронь $n';
  }

  @override
  String get pSize => 'Площадь';

  @override
  String get pSchedule => 'График';

  @override
  String get pSpace => 'Информация о пространстве';

  @override
  String get pNavigate => 'Маршрут';

  @override
  String get pNavHint =>
      'Откроет адрес выезда в приложении карт. Если его нет, откроется веб-карта.';

  @override
  String get pOfflineSaved =>
      'Нет сети. Сохранено и отправится, когда появится связь.';

  @override
  String get pPhotoRetry => 'Повторить загрузку';

  @override
  String get pPhotoWaiting =>
      'Фото, которые не загрузились, отправятся автоматически при появлении связи.';

  @override
  String pUploadedCount(String total, String done) {
    return 'Загружено $done из $total';
  }

  @override
  String get cIntPayout => 'Выплаты партнёрам';

  @override
  String get poTabSettlements => 'Расчёты';

  @override
  String get poTabPayouts => 'Выплаты';

  @override
  String get poState_requested => 'Запрошено';

  @override
  String get poState_sent => 'Отправлено';

  @override
  String get poState_paid => 'Оплачено';

  @override
  String get poState_failed => 'Ошибка';

  @override
  String get poProviderManual => 'Ручной перевод';

  @override
  String get poProviderToss => 'Выплаты через Toss';

  @override
  String get poShowAccount => 'Показать счёт';

  @override
  String get poAccountTitle => 'Реквизиты перевода';

  @override
  String poAccountBody(
    String holder,
    String bank,
    String account,
    String amount,
  ) {
    return 'Отправьте $amount вон на $holder · $bank · $account, затем нажмите «Подтвердить».';
  }

  @override
  String get poConfirmPaid => 'Отметить как переведено';

  @override
  String get poMarkFailed => 'Отметить как неудачное';

  @override
  String get poReasonTitle => 'Причина ошибки';

  @override
  String get poReasonHint => 'напр.: неверный счёт, перевод отменён';

  @override
  String get poSend => 'Отправить через Toss';

  @override
  String get poSync => 'Проверить статус';

  @override
  String get poRetry => 'Повторить';

  @override
  String get poNoPayouts => 'Выплат пока нет';

  @override
  String poRequestedToast(String n) {
    return 'Создано запросов на выплату: $n';
  }

  @override
  String get poReasonRequired => 'Укажите причину';

  @override
  String get poRevealNote => 'Просмотр реквизитов фиксируется';

  @override
  String get poSellerAction => 'Регистрация продавца';

  @override
  String get poSellerTitle => 'Регистрация продавца Toss';

  @override
  String get poSellerHint =>
      'Используется подтверждённый счёт партнёра. Укажите только данные бизнеса.';

  @override
  String get poSellerIndividual => 'Физлицо';

  @override
  String get poSellerCompany => 'Бизнес';

  @override
  String get poSellerName => 'Имя';

  @override
  String get poSellerRepresentative => 'ФИО руководителя';

  @override
  String get poSellerRegNo => 'Регистрационный номер бизнеса (10 цифр)';

  @override
  String get poSellerEmail => 'Эл. почта для расчётов';

  @override
  String get poSellerPhone => 'Телефон';

  @override
  String get poSellerSubmit => 'Зарегистрировать';

  @override
  String poSellerDone(String status) {
    return 'Статус продавца: $status';
  }

  @override
  String get oFlags => 'Переключатели функций';

  @override
  String get oFlagBooking => 'Бронирования';

  @override
  String get oFlagChat => 'Чат';

  @override
  String get oFlagAi => 'ИИ-помощник';

  @override
  String get oFlagPayments => 'Платежи';

  @override
  String get oMaintenance => 'Режим технических работ';

  @override
  String get oMaintenanceHint =>
      'Когда включено, приложения клиентов и партнёров показывают экран технических работ. Консоль работает.';

  @override
  String get oMaintenanceMessage => 'Текст для технических работ';

  @override
  String get oClientErrors => 'Отчёты об ошибках приложений';

  @override
  String get oClientErrorsHint =>
      'Последние ошибки из веба, Windows и консоли. Персональные данные скрываются автоматически.';

  @override
  String get oClientErrorsEmpty => 'Недавних ошибок нет';

  @override
  String get oHeartbeat => 'Heartbeat-мониторинг';

  @override
  String get oHeartbeatOn =>
      'Подключено. Внешний сервис получает сигнал, пока сервер работает.';

  @override
  String get oHeartbeatOff =>
      'Не настроено: добавьте MALKKEUM_HEARTBEAT_URL в install.sh.';

  @override
  String get pvManage => 'Управление согласиями';

  @override
  String get pvOptional => 'Необязательно';

  @override
  String get pvTerms => 'Условия использования';

  @override
  String get pvPrivacy => 'Сбор и использование персональных данных';

  @override
  String get pvOverseas => 'Передача персональных данных за рубеж';

  @override
  String get pvMarketing => 'Рекламные сообщения';

  @override
  String get pvMarketingHint =>
      'Купоны и новости акций по SMS, в KakaoTalk и push-уведомлениях приложения. Отключить можно в любой момент.';

  @override
  String get pvReconsent =>
      'Политика конфиденциальности изменилась. Пожалуйста, ознакомьтесь и согласитесь снова.';

  @override
  String get pvSaved => 'Настройки согласий сохранены';

  @override
  String get pvExport => 'Скачать мои данные';

  @override
  String get pvExportHint =>
      'Показывает все данные о вас, которые у нас есть, в формате JSON. Их можно скопировать и сохранить.';

  @override
  String get pvCopy => 'Копировать';

  @override
  String get pvCopied => 'Скопировано';

  @override
  String get pvExportFailed =>
      'Не удалось загрузить ваши данные. Попробуйте позже.';

  @override
  String get safetyEmergency => 'Экстренные контакты';

  @override
  String get emergencyPolice => '112 Полиция';

  @override
  String get emergencyFire => '119 Пожарные и спасатели';

  @override
  String get emergencyShop => 'Поддержка';

  @override
  String get caseReportAction => 'Сообщить о проблеме';

  @override
  String get caseReportTitle => 'Что произошло?';

  @override
  String get caseKindDamage => 'Повреждение';

  @override
  String get caseKindLoss => 'Пропажа';

  @override
  String get caseKindComplaint => 'Жалоба';

  @override
  String get caseKindNoShow => 'Исполнитель не пришёл';

  @override
  String get caseKindSafety => 'Вопрос безопасности';

  @override
  String get caseKindPayment => 'Спор по оплате';

  @override
  String get caseSummaryHint => 'Опишите, что произошло (до 300 символов)';

  @override
  String get caseSubmit => 'Отправить';

  @override
  String get caseSubmitted => 'Принято. Мы ответим в течение 24 часов.';

  @override
  String get caseFailed => 'Не удалось отправить. Попробуйте ещё раз.';

  @override
  String get checkInAction => 'Отметить прибытие';

  @override
  String get checkOutAction => 'Отметить уход';

  @override
  String checkedInAt(String time) {
    return 'Прибыл в $time';
  }

  @override
  String checkedOutAt(String time) {
    return 'Ушёл в $time';
  }

  @override
  String get entryCodeAction => 'Показать код домофона';

  @override
  String get entryCodeTitle => 'Код домофона';

  @override
  String get entryCodeNotToday => 'Доступно только в день визита';

  @override
  String get entryCodeEmpty => 'Код не указан';

  @override
  String get actionFailed => 'Не удалось выполнить. Попробуйте ещё раз.';

  @override
  String get consoleCasesTitle => 'Очередь обращений';

  @override
  String get consoleCasesEmpty => 'Открытых обращений нет';

  @override
  String get caseOverdue => 'Просрочено';

  @override
  String get caseStatusOpen => 'Открыто';

  @override
  String get caseStatusInvestigating => 'На рассмотрении';

  @override
  String get caseStatusResolved => 'Решено';

  @override
  String get caseStatusRejected => 'Отклонено';

  @override
  String get caseReassign => 'Переназначить исполнителя';

  @override
  String get caseRefund => 'Возврат';

  @override
  String get caseHold => 'Приостановить выплату';

  @override
  String get caseNoteHint => 'Внутренняя заметка';

  @override
  String get caseSave => 'Сохранить';

  @override
  String get cSetup => 'Настройка';

  @override
  String get cSetupTitle => 'Подготовка к запуску';

  @override
  String cSetupProgress(String done, String total) {
    return 'Готово $done из $total';
  }

  @override
  String get cSetupAllDone => 'Всё готово!';

  @override
  String get cSetupBusiness => 'Профиль компании';

  @override
  String get cSetupBusinessName => 'Название сервиса';

  @override
  String get cSetupSupportPhone => 'Телефон поддержки';

  @override
  String get cSetupSupportEmail => 'Email поддержки';

  @override
  String get cSetupSupportHours => 'Часы поддержки';

  @override
  String get cSetupColor => 'Фирменный цвет';

  @override
  String get cSetupLogo => 'Загрузить логотип';

  @override
  String get cSetupCompany => 'Реквизиты (в подвале приложения и сайта)';

  @override
  String get cSetupLegalName => 'Юридическое название';

  @override
  String get cSetupCeo => 'Руководитель';

  @override
  String get cSetupRegNo => 'Рег. номер компании';

  @override
  String get cSetupMailOrderNo => 'Номер регистрации продаж';

  @override
  String get cSetupAddress => 'Адрес';

  @override
  String get cSetupPrivacyOfficer => 'Ответственный за данные';

  @override
  String get cSetupStoreLinks =>
      'Ссылки на магазины (кнопки на сайте включатся после заполнения)';

  @override
  String get cSetupCustomerApp => 'Приложение клиента';

  @override
  String get cSetupPartnerApp => 'Приложение партнёра';

  @override
  String get cSetupPayMethods => 'Способы оплаты';

  @override
  String get cSetupPayMethodsHint =>
      'Включайте и выключайте способы оплаты для клиентов. Применяется сразу.';

  @override
  String get cReviewTitle => 'Демо-аккаунт для проверки в магазине';

  @override
  String get cReviewHint =>
      'Проверяющие не получают корейские SMS. Укажите номер и 6-значный код в заметках для проверки. Отключится автоматически.';

  @override
  String get cReviewPhone => 'Демо-номер телефона';

  @override
  String get cReviewCode => 'Постоянный код (6 цифр)';

  @override
  String cReviewActiveUntil(String date) {
    return 'Действует до $date';
  }

  @override
  String get cReviewEnable => 'Включить (14 дней)';

  @override
  String get pDeleteAccountBody =>
      'Команда и личные данные будут удалены без возможности восстановления. Сначала завершите назначенные работы и выплаты.';

  @override
  String get err_has_active_jobs =>
      'У вас есть назначенные работы. Завершите их или попросите поддержку передать.';

  @override
  String get err_pending_payouts =>
      'Есть невыплаченная сумма. Удалить аккаунт можно после выплаты.';

  @override
  String get err_phone_required =>
      'Подтвердите номер телефона, прежде чем брать работы.';

  @override
  String get nAlerts => 'Уведомления';

  @override
  String get nEmpty => 'Пока нет уведомлений';

  @override
  String nUnread(String count) {
    return 'Непрочитанных: $count';
  }

  @override
  String get pVerifyPhone => 'Подтвердить';

  @override
  String get mMyJobs => 'Мои работы';

  @override
  String get mNoJobs =>
      'Пока нет назначенных работ. Здесь появятся работы от руководителя команды.';

  @override
  String mTeam(String team) {
    return 'Участник $team';
  }

  @override
  String get cSetupSave => 'Сохранить';

  @override
  String get cSetupSaved => 'Сохранено';

  @override
  String get cSetupTest => 'Проверить подключение';

  @override
  String get cSetupClear => 'Отключить';

  @override
  String get cSetupConnected => 'Подключено';

  @override
  String get cSetupNotConnected => 'Не подключено';

  @override
  String get cSetupFromEnv => 'Используются настройки сервера';

  @override
  String get cSetupCheckInApp => 'Сохранено · проверьте входом в приложении';

  @override
  String get cSetupInvalidKey =>
      'Ключ отклонён. Проверьте скопированное значение';

  @override
  String get cSetupUnreachable => 'Сервис недоступен. Повторите позже';

  @override
  String get cSetupKeepValue => 'Сохранено (введите, только чтобы заменить)';

  @override
  String get cSetupGuide => 'Как настроить';

  @override
  String get cSetupOpenSite => 'Открыть сайт';

  @override
  String get cSetupWebhook => 'Адрес webhook (вставьте в консоль PortOne)';

  @override
  String get cCopied => 'Скопировано';

  @override
  String get cSetupDevMode =>
      'Тестовый режим: реальные платежи и сообщения не отправляются';

  @override
  String get cSetupOptional => 'Необязательно';

  @override
  String get cIntPortone => 'Платежи (PortOne)';

  @override
  String get cIntSolapi => 'SMS и KakaoTalk (Solapi)';

  @override
  String get cIntPush => 'Push-уведомления (Firebase)';

  @override
  String get cIntKakao => 'Вход через Kakao';

  @override
  String get cIntNaver => 'Вход через Naver';

  @override
  String get cIntGoogle => 'Вход через Google';

  @override
  String get cIntApple => 'Вход через Apple';

  @override
  String get cFirstRunTitle => 'Добро пожаловать! Создайте аккаунт владельца';

  @override
  String get cFirstRunBody =>
      'Введите 12-значный код, показанный при установке. Этот аккаунт управляет всеми настройками.';

  @override
  String get cFirstRunCode => 'Код установки';

  @override
  String get cName => 'Имя';

  @override
  String get cFirstRunCreate => 'Создать аккаунт и начать';

  @override
  String get cWrongSetupCode => 'Неверный код установки';

  @override
  String get cWeakPassword => 'Пароль должен быть не короче 12 символов';

  @override
  String get cInvalidValue => 'Проверьте введённое значение';

  @override
  String get cMfaTitle => 'Вход в два шага';

  @override
  String get cMfaCode => '6-значный код из приложения-аутентификатора';

  @override
  String get cMfaRecovery => 'Код восстановления';

  @override
  String get cMfaUseRecovery => 'Использовать код восстановления';

  @override
  String get cMfaUseCode => 'Использовать код из приложения';

  @override
  String get cMfaVerify => 'Подтвердить';

  @override
  String get cMfaBack => 'Назад ко входу';

  @override
  String get cMfaEnrolTitle => 'Настройте вход в два шага';

  @override
  String get cMfaEnrolBody =>
      'Администраторам нужно приложение-аутентификатор. Добавьте ключ ниже в Google Authenticator, 1Password или похожее приложение и введите 6-значный код из него.';

  @override
  String get cMfaSecret => 'Ключ настройки';

  @override
  String get cMfaLink => 'Ссылка настройки (otpauth)';

  @override
  String get cMfaCopy => 'Копировать';

  @override
  String get cMfaCopied => 'Скопировано';

  @override
  String get cMfaConfirm => 'Подтвердить и включить';

  @override
  String get cMfaCodesTitle => 'Сохраните коды восстановления';

  @override
  String get cMfaCodesBody =>
      'Если вы потеряете приложение-аутентификатор, каждый код позволит войти один раз. Они показываются только сейчас.';

  @override
  String get cMfaDownload => 'Скачать';

  @override
  String get cMfaSaveFailed =>
      'Это устройство не может сохранить файл. Скопируйте коды и храните их в безопасном месте.';

  @override
  String get cMfaContinue => 'Перейти в консоль';

  @override
  String get cMfaInvalid =>
      'Код не подходит. Проверьте, верно ли время на телефоне, и попробуйте снова.';

  @override
  String get cMfaExpired => 'Время входа истекло. Начните снова с пароля.';

  @override
  String get cMfaLocked =>
      'Слишком много попыток. Подождите несколько минут и попробуйте снова.';

  @override
  String get cStaffReset => 'Сбросить пароль';

  @override
  String get cStaffResetConfirm =>
      'Сбросить пароль этого сотрудника? Он будет выведен со всех устройств.';

  @override
  String get cStaffResetTitle => 'Токен сброса';

  @override
  String get cStaffResetBody =>
      'Передайте этот токен сотруднику. Он работает один раз в течение 30 минут. После закрытия его не покажут снова.';

  @override
  String get subTitle => 'Регулярная уборка';

  @override
  String get subNew => 'Оформить подписку';

  @override
  String get subCadence => 'Периодичность';

  @override
  String get subWeekly => 'Каждую неделю';

  @override
  String get subBiweekly => 'Раз в 2 недели';

  @override
  String get subEvery4Weeks => 'Раз в 4 недели';

  @override
  String get subWeekday => 'День недели';

  @override
  String get subHour => 'Время прихода';

  @override
  String subDiscountNote(String percent) {
    return 'Скидка $percent% на каждый визит';
  }

  @override
  String get subChargeNote => 'Оплата за день до визита с сохранённой карты';

  @override
  String get subCreate => 'Оформить';

  @override
  String get subCreated => 'Подписка оформлена';

  @override
  String get subNeedAddress => 'Сначала добавьте адрес для визита';

  @override
  String get subListEmpty => 'Подписок пока нет';

  @override
  String get subStatusActive => 'Активна';

  @override
  String get subStatusPaused => 'Приостановлена';

  @override
  String get subStatusCancelled => 'Отменена';

  @override
  String subNextVisit(String date) {
    return 'Следующий визит $date';
  }

  @override
  String get subPause => 'Приостановить';

  @override
  String get subResume => 'Возобновить';

  @override
  String get subCancelSub => 'Отменить подписку';

  @override
  String get subCancelConfirm =>
      'Будущие визиты будут отменены. Забронированные визиты нужно отменить отдельно.';

  @override
  String get subSkip => 'Пропустить визит';

  @override
  String get subMove => 'Перенести визит';

  @override
  String get subVisitLocked => 'Изменить нельзя начиная с дня до визита';

  @override
  String get subPausedPayment =>
      'Приостановлено из-за повторных ошибок оплаты. Смените карту и возобновите.';

  @override
  String get subStatePlanned => 'Запланирован';

  @override
  String get subStateBooked => 'Забронирован';

  @override
  String get subStateSkipped => 'Пропущен';

  @override
  String get subStateMissed => 'Не состоялся';

  @override
  String get pSubsTitle => 'Постоянные клиенты';

  @override
  String get pSubsEmpty => 'Постоянных клиентов пока нет';

  @override
  String get cSubsTitle => 'Подписки';

  @override
  String get cSubsEdit => 'Изменить за клиента';

  @override
  String get cMrr => 'Ежемесячный повторный доход (MRR)';

  @override
  String get cChurn => 'Отток';

  @override
  String get cActiveSubs => 'Активные подписки';

  @override
  String get cRecognized => 'Признанный доход за период';

  @override
  String get cSubsLoadFailed => 'Не удалось загрузить подписки';

  @override
  String get tTaxSection => 'Налоги';

  @override
  String tVatQuarter(String q) {
    return 'CSV НДС, кв. $q';
  }

  @override
  String get tVatYear => 'Год';

  @override
  String get tExportWithholding => 'CSV удержания НДФЛ';

  @override
  String get tExportTaxInvoices => 'CSV для загрузки счетов-фактур';

  @override
  String get tTaxLayoutNote =>
      'Сверьте столбцы с шаблоном 홈택스 перед загрузкой. Структура ещё не проверена.';

  @override
  String get tCashReceipts => 'Кассовые чеки';

  @override
  String get tCashIssued => 'Выдан';

  @override
  String get tCashFailed => 'Ошибка';

  @override
  String get tCashPending => 'Ожидает';

  @override
  String get tCashCancelled => 'Отменён';

  @override
  String get tReissue => 'Выдать повторно';

  @override
  String get tTaxInvoices => 'Счета-фактуры';

  @override
  String get tApprovalNumber => 'Номер одобрения';

  @override
  String get tIssuedOn => 'Дата выдачи';

  @override
  String get tMarkIssued => 'Отметить как выданный';

  @override
  String get tQueueEmpty => 'Нет ожидающих запросов';

  @override
  String get tWithholdingLabel => 'Удержание';

  @override
  String get tGrossAmount => 'Начислено';

  @override
  String get tIncomeTax => 'Подоходный налог';

  @override
  String get tLocalTax => 'Местный подоходный налог';

  @override
  String get tNetAmount => 'К выплате';

  @override
  String get tNoWithholding => 'Без удержания (зарегистрированный бизнес)';

  @override
  String get tEstWithholding => 'Ожидаемое удержание (к выплате)';

  @override
  String get tReceiptOptions => 'Параметры чека';

  @override
  String get tWantCashReceipt => 'Получить кассовый чек';

  @override
  String get tCashForIncome => 'Для вычета (номер телефона)';

  @override
  String get tCashForBusiness => 'Для расходов бизнеса (номер бизнеса)';

  @override
  String get tWantTaxInvoice => 'Получить счёт-фактуру (бизнес)';

  @override
  String get tPhoneForReceipt => 'Номер телефона';

  @override
  String get tBusinessNumber => 'Регистрационный номер бизнеса';

  @override
  String get tCompanyName => 'Название компании';

  @override
  String get tRepresentative => 'Представитель';

  @override
  String get tInvoiceEmail => 'Email для счёта-фактуры';

  @override
  String get tReceiptSave => 'Сохранить и оплатить';

  @override
  String get tReceiptSaveFailed => 'Не удалось сохранить данные чека';

  @override
  String get tTaxType => 'Тип налога';

  @override
  String get tTaxFreelancer => 'Фрилансер (с удержанием)';

  @override
  String get tTaxBusiness => 'Зарегистрированный бизнес (без удержания)';

  @override
  String get tReceiptSettings => 'Настройки чека';

  @override
  String get reviewRuleLine =>
      'Запрещены оскорбления, личные данные, ложный или рекламный контент. Отмеченные отзывы скрываются.';

  @override
  String get reportAction => 'Пожаловаться';

  @override
  String get reportSheetTitle => 'Пожаловаться на этот отзыв?';

  @override
  String get reportReasonSpam => 'Спам или реклама';

  @override
  String get reportReasonOffensive => 'Оскорбления или ненависть';

  @override
  String get reportReasonPersonal => 'Личные данные';

  @override
  String get reportReasonOther => 'Другое';

  @override
  String get reportNoteHint => 'Подробности (необязательно, до 300 символов)';

  @override
  String get reportSubmit => 'Отправить жалобу';

  @override
  String get reportThanks => 'Спасибо. Наша команда проверит жалобу.';

  @override
  String get reportAlready => 'Вы уже пожаловались на этот отзыв';

  @override
  String get reportFailed => 'Не удалось отправить жалобу. Попробуйте ещё раз.';

  @override
  String get reviewBlocked =>
      'Отзывы для этого аккаунта отключены. Свяжитесь с поддержкой.';

  @override
  String get modTitle => 'Жалобы на отзывы';

  @override
  String get modEmpty => 'Нет жалоб, ожидающих решения';

  @override
  String modReports(String count) {
    return 'Жалоб: $count';
  }

  @override
  String get modKeep => 'Оставить';

  @override
  String get modHide => 'Скрыть';

  @override
  String get modDelete => 'Удалить';

  @override
  String get modBlockAuthor => 'Ограничить автора';

  @override
  String get modUnblockAuthor => 'Снять ограничение';

  @override
  String get modDone => 'Готово';

  @override
  String get modFailed => 'Не удалось выполнить. Попробуйте ещё раз.';

  @override
  String get modHidden => 'Скрытый отзыв';

  @override
  String uUpdateBanner(String version) {
    return 'Доступна версия $version';
  }

  @override
  String get uUpdateNow => 'Обновить';

  @override
  String get uUpdateLater => 'Позже';

  @override
  String get uUpdateRequiredTitle => 'Требуется обновление';

  @override
  String get uUpdateRequiredBody =>
      'Эта версия больше не поддерживается. Обновите приложение в магазине.';

  @override
  String get uUpdateStore => 'Обновить в магазине';

  @override
  String get uUpdateStoreMissing =>
      'Ссылка для обновления ещё не готова. Попробуйте позже.';

  @override
  String uCurrentVersion(String version) {
    return 'Текущая версия $version';
  }

  @override
  String get uAppVersionTitle => 'Версии приложений';

  @override
  String get uAppVersionHint =>
      'Приложения ниже минимальной версии остановятся на экране обновления. Ниже последней версии покажется баннер. Формат: 1.2.0';

  @override
  String get uMinVersion => 'Минимальная версия';

  @override
  String get uLatestVersion => 'Последняя версия';

  @override
  String get webBookNow => 'Забронировать в браузере';

  @override
  String get webBookSub => 'Без установки приложения';

  @override
  String get apPgBrowserNote =>
      'Завершите оплату в браузере, затем вернитесь сюда и нажмите кнопку ниже.';

  @override
  String get apPgBrowserDone => 'Я оплатил';
}
