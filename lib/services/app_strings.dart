/// Centralized i18n strings for the entire app.
/// All UI text is resolved through this class based on the active language code.
class AppStrings {
  AppStrings._();

  static String get(String key, String lang) {
    final map = _strings[key];
    if (map == null) return key;
    return map[lang] ?? map['uz_lat'] ?? key;
  }

  /// "64 variant" / "64 вариант" / "64 варианта" — o'zbekchada son bilan
  /// ot birlikda, ruschada songa qarab uch shakl.
  static String variantsPhrase(int n, String lang) {
    switch (lang) {
      case 'ru':
        final mod10 = n % 10, mod100 = n % 100;
        final word = mod10 == 1 && mod100 != 11
            ? 'вариант'
            : mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)
            ? 'варианта'
            : 'вариантов';
        return '$n $word';
      case 'uz_cyr':
        return '$n вариант';
      default:
        return '$n variant';
    }
  }

  static const Map<String, Map<String, String>> _strings = {
    // ── App-level ──
    'app_title': {
      'uz_lat': 'AvtoSmart',
      'uz_cyr': 'AvtoSmart',
      'ru': 'AvtoSmart',
    },
    // ── Bosh ekran — saytdagi matnlar (src/locales: home.*, sections.*) ──
    'home_badge': {
      'uz_lat': '2026 YHQ savollari',
      'uz_cyr': '2026 ЙҲҚ саволлари',
      'ru': 'Вопросы ПДД 2026',
    },
    'home_title': {
      'uz_lat': 'Avto test — Prava test va YHQ testlar 2026',
      'uz_cyr': 'Avto test — Права тест ва ЙҲҚ тестлар 2026',
      'ru': 'Avto test — Права и ПДД тесты 2026',
    },
    // Site: home.heroSubtitle, with the app's own variant count.
    'home_subtitle': {
      'uz_lat':
          "AvtoSmart — YHQ testlari, yo'l belgilari va {variants}. "
          'Haydovchilik guvohnomasi imtihoniga tayyorgarlik.',
      'uz_cyr':
          'AvtoSmart — ЙҲҚ тестлари, йўл белгилари ва {variants}. '
          'Ҳайдовчилик гувоҳномаси имтиҳонига тайёргарлик.',
      'ru':
          'AvtoSmart — тесты ПДД, дорожные знаки и {variants}. '
          'Подготовка к экзамену на водительские права.',
    },
    'home_btn_test': {
      'uz_lat': 'Test ishlash',
      'uz_cyr': 'Тест ишлаш',
      'ru': 'Пройти тест',
    },
    'home_btn_variants': {
      'uz_lat': 'Variantlar',
      'uz_cyr': 'Вариантлар',
      'ru': 'Варианты',
    },
    'home_btn_topics': {
      'uz_lat': 'Mavzular',
      'uz_cyr': 'Мавзулар',
      'ru': 'Темы',
    },
    'section_errors_drill': {
      'uz_lat': 'Xatolar ustida ishlash',
      'uz_cyr': 'Хатолар устида ишлаш',
      'ru': 'Работа над ошибками',
    },
    'pro_card_title': {
      'uz_lat': 'PRO obuna',
      'uz_cyr': 'PRO обуна',
      'ru': 'Подписка PRO',
    },
    // {variants} — AppStrings.variantsPhrase: "64 variant" / "64 варианта".
    'pro_card_desc': {
      'uz_lat':
          "To'liq savollar bazasi, barcha {variants} va har bir savolga izoh bir joyda.",
      'uz_cyr':
          'Тўлиқ саволлар базаси, барча {variants} ва ҳар бир саволга изоҳ бир жойда.',
      'ru':
          'Полная база вопросов, все {variants} и пояснение к каждому вопросу.',
    },
    'get_pro': {
      'uz_lat': 'Pro olish',
      'uz_cyr': 'Pro олиш',
      'ru': 'Получить Pro',
    },

    // ── Navigation ──
    'nav_home': {'uz_lat': 'Asosiy', 'uz_cyr': 'Асосий', 'ru': 'Главная'},
    'nav_topics': {
      'uz_lat': 'Mavzuli testlar',
      'uz_cyr': 'Мавзули тестлар',
      'ru': 'Тесты по темам',
    },
    'nav_sections': {
      'uz_lat': 'Bo\'limlar',
      'uz_cyr': 'Бўлимлар',
      'ru': 'Разделы',
    },
    'sections_title': {
      'uz_lat': 'Bo\'limlar',
      'uz_cyr': 'Бўлимлар',
      'ru': 'Разделы',
    },
    'saved_tests_sub': {
      'uz_lat': 'Saqlagan savollaringizni qayta ishlang',
      'uz_cyr': 'Сақлаган саволларингизни қайта ишланг',
      'ru': 'Повторите сохранённые вопросы',
    },
    'my_errors_sub': {
      'uz_lat': 'Xato javob bergan savollaringiz',
      'uz_cyr': 'Хато жавоб берган саволларингиз',
      'ru': 'Вопросы, где вы ошиблись',
    },
    'difficult_questions': {
      'uz_lat': 'Qiyin savollar',
      'uz_cyr': 'Қийин саволлар',
      'ru': 'Сложные вопросы',
    },
    'difficult_questions_sub': {
      'uz_lat': 'Chorraha, belgi, uzun va tibbiy yordam savollari ko\'proq',
      'uz_cyr': 'Чорраҳа, белги, узун ва тиббий ёрдам саволлари кўпроқ',
      'ru': 'Больше вопросов про перекрёстки, знаки, первую помощь',
    },
    'road_signs': {
      'uz_lat': 'Yo\'l belgilari',
      'uz_cyr': 'Йўл белгилари',
      'ru': 'Дорожные знаки',
    },
    'pro_title': {
      'uz_lat': 'PRO versiya',
      'uz_cyr': 'PRO версия',
      'ru': 'PRO версия',
    },
    'pro_active_title': {
      'uz_lat': 'PRO obunangiz aktiv',
      'uz_cyr': 'PRO обунангиз актив',
      'ru': 'Ваша подписка PRO активна',
    },
    'pro_active_expiry': {
      'uz_lat': 'Tugash',
      'uz_cyr': 'Тугаш',
      'ru': 'Истекает',
    },
    'pro_days_left': {
      'uz_lat': 'kun qoldi',
      'uz_cyr': 'кун қолди',
      'ru': 'дней осталось',
    },
    'pro_type_pro': {'uz_lat': 'PRO', 'uz_cyr': 'PRO', 'ru': 'PRO'},
    'pro_header_badge': {'uz_lat': 'PRO', 'uz_cyr': 'PRO', 'ru': 'PRO'},
    'pro_header_title': {
      'uz_lat': 'PRO ga obuna bo\'ling',
      'uz_cyr': 'PRO га обуна бўлинг',
      'ru': 'Оформите подписку PRO',
    },
    'pro_header_subtitle': {
      'uz_lat':
          '1250+ savol, 64 ta variant va admin yordami bilan to\'liq tayyorlaning.',
      'uz_cyr':
          '1250+ савол, 64 та вариант ва админ ёрдами билан тўлиқ тайёрланинг.',
      'ru':
          '1250+ вопросов, 64 варианта и поддержка администратора — готовьтесь полностью.',
    },
    'pro_choose_plan': {
      'uz_lat': 'Ta\'rifni tanlang',
      'uz_cyr': 'Таърифни танланг',
      'ru': 'Выберите тариф',
    },
    'pro_currency_som': {'uz_lat': 'so\'m', 'uz_cyr': 'сўм', 'ru': 'сум'},
    'plan_weekly_title': {
      'uz_lat': 'Haftalik obuna',
      'uz_cyr': 'Ҳафталик обуна',
      'ru': 'Недельная подписка',
    },
    'plan_weekly_subtitle': {
      'uz_lat': 'Tezkor tayyorgarlik uchun',
      'uz_cyr': 'Тезкор тайёргарлик учун',
      'ru': 'Для быстрой подготовки',
    },
    'plan_weekly_button': {
      'uz_lat': 'Haftalik olish',
      'uz_cyr': 'Ҳафталик олиш',
      'ru': 'Оформить на неделю',
    },
    'plan_monthly_title': {
      'uz_lat': 'Oylik obuna',
      'uz_cyr': 'Ойлик обуна',
      'ru': 'Месячная подписка',
    },
    'plan_monthly_subtitle': {
      'uz_lat': 'Eng optimal tanlov',
      'uz_cyr': 'Энг оптимал танлов',
      'ru': 'Оптимальный выбор',
    },
    'plan_monthly_button': {
      'uz_lat': 'Oylik olish',
      'uz_cyr': 'Ойлик олиш',
      'ru': 'Оформить на месяц',
    },
    'plan_monthly_badge': {
      'uz_lat': 'ENG MASHHUR',
      'uz_cyr': 'ЭНГ МАШҲУР',
      'ru': 'ПОПУЛЯРНЫЙ',
    },
    'plan_quarterly_title': {
      'uz_lat': '3 Oylik obuna',
      'uz_cyr': '3 Ойлик обуна',
      'ru': 'Подписка на 3 месяца',
    },
    'plan_quarterly_subtitle': {
      'uz_lat': '21% chegirma bilan',
      'uz_cyr': '21% чегирма билан',
      'ru': 'Со скидкой 21%',
    },
    'plan_quarterly_button': {
      'uz_lat': '3 Oylik olish',
      'uz_cyr': '3 Ойлик олиш',
      'ru': 'Оформить на 3 месяца',
    },
    'pro_features_title': {
      'uz_lat': 'PRO tarifida nimalar bor?',
      'uz_cyr': 'PRO тарифида нималар бор?',
      'ru': 'Что входит в PRO?',
    },
    'pro_perk_1': {
      'uz_lat': '1250+ ta yopiq savollar bazasi',
      'uz_cyr': '1250+ та ёпиқ саволлар базаси',
      'ru': 'База из 1250+ закрытых вопросов',
    },
    'pro_perk_2': {
      'uz_lat': '64 ta imtihon varianti',
      'uz_cyr': '64 та имтиҳон варианти',
      'ru': '64 экзаменационных варианта',
    },
    'pro_perk_3': {
      'uz_lat': 'Mavzular bo\'yicha testlar va izohlar',
      'uz_cyr': 'Мавзулар бўйича тестлар ва изоҳлар',
      'ru': 'Тесты по темам и пояснения к ответам',
    },
    'pro_perk_4': {
      'uz_lat': 'Admin ko\'magi va Premium guruh',
      'uz_cyr': 'Админ кўмаги ва Premium гуруҳ',
      'ru': 'Поддержка администратора и Premium-группа',
    },
    'pro_perk_5': {
      'uz_lat': 'Cheksiz vaqt va urinishlar',
      'uz_cyr': 'Чексиз вақт ва уринишлар',
      'ru': 'Неограниченное время и попытки',
    },
    'pro_contact_subtitle': {
      'uz_lat': 'To\'lov va savollar uchun',
      'uz_cyr': 'Тўлов ва саволлар учун',
      'ru': 'По оплате и вопросам',
    },
    'search_road_signs': {
      'uz_lat': 'Belgi qidirish...',
      'uz_cyr': 'Белги қидириш...',
      'ru': 'Поиск знака...',
    },
    'no_results': {
      'uz_lat': 'Hech narsa topilmadi',
      'uz_cyr': 'Ҳеч нарса топилмади',
      'ru': 'Ничего не найдено',
    },
    'difficulty_cat_intersections': {
      'uz_lat': 'Chorrahalar va imtiyoz huquqi',
      'uz_cyr': 'Чорраҳалар ва имтиёз ҳуқуқи',
      'ru': 'Перекрёстки и право проезда',
    },
    'difficulty_cat_signs': {
      'uz_lat': 'Yo\'l belgilari va ularning ma\'nolari',
      'uz_cyr': 'Йўл белгилари ва уларнинг маънолари',
      'ru': 'Дорожные знаки и их значения',
    },
    'difficulty_cat_first_aid': {
      'uz_lat': 'Birinchi tibbiy yordam',
      'uz_cyr': 'Биринчи тиббий ёрдам',
      'ru': 'Первая медицинская помощь',
    },
    'difficulty_cat_long': {
      'uz_lat': 'Uzun va murakkab savollar',
      'uz_cyr': 'Узун ва мураккаб саволлар',
      'ru': 'Длинные и сложные вопросы',
    },
    'road_signs_sub': {
      'uz_lat': 'Barcha yo\'l belgilari va ma\'nolari',
      'uz_cyr': 'Барча йўл белгилари ва маънолари',
      'ru': 'Все дорожные знаки и их значения',
    },
    'nav_settings': {
      'uz_lat': 'Sozlamalar',
      'uz_cyr': 'Созламалар',
      'ru': 'Настройки',
    },

    // ── Home menu cards ──
    'menu_test': {
      'uz_lat': 'Test ishlash',
      'uz_cyr': 'Тест ишлаш',
      'ru': 'Пройти тест',
    },
    'menu_test_sub': {
      'uz_lat': "Bilimingizni sinab ko'ring",
      'uz_cyr': "Билимингизни синаб кўринг",
      'ru': 'Проверьте свои знания',
    },
    'menu_topics': {
      'uz_lat': 'Mavzuli testlar',
      'uz_cyr': 'Мавзули тестлар',
      'ru': 'Тесты по темам',
    },
    'menu_topics_sub': {
      'uz_lat': 'Mavzular bo\'yicha testlar',
      'uz_cyr': 'Мавзулар бўйича тестлар',
      'ru': 'Тесты по темам и разделам',
    },
    'menu_variants': {
      'uz_lat': 'Variantlar',
      'uz_cyr': 'Вариантлар',
      'ru': 'Варианты',
    },
    'menu_variants_sub': {
      'uz_lat': 'Real imtihon variantlari',
      'uz_cyr': 'Реал имтиҳон вариантлари',
      'ru': 'Реальные экзаменационные варианты',
    },

    // ── Results section ──
    'your_results': {
      'uz_lat': 'Sizning natijalaringiz',
      'uz_cyr': 'Сизнинг натижаларингиз',
      'ru': 'Ваши результаты',
    },
    'avg_score': {
      'uz_lat': "O'rtacha ball",
      'uz_cyr': "Ўртача балл",
      'ru': 'Средний балл',
    },
    'passed_tests': {
      'uz_lat': "O'tgan testlar",
      'uz_cyr': "Ўтган тестлар",
      'ru': 'Пройдено',
    },
    'total_tests': {
      'uz_lat': 'Jami testlar',
      'uz_cyr': 'Жами тестлар',
      'ru': 'Всего тестов',
    },
    'recent_results': {
      'uz_lat': "So'nggi natijalar",
      'uz_cyr': "Сўнгги натижалар",
      'ru': 'Последние результаты',
    },

    // ── Test screen ──
    'loading': {
      'uz_lat': 'Yuklanmoqda...',
      'uz_cyr': 'Юкланмоқда...',
      'ru': 'Загрузка...',
    },
    'error_prefix': {'uz_lat': 'Xatolik', 'uz_cyr': 'Хатолик', 'ru': 'Ошибка'},
    'back': {'uz_lat': 'Orqaga', 'uz_cyr': 'Орқага', 'ru': 'Назад'},
    'no_questions': {
      'uz_lat': 'Savollar topilmadi',
      'uz_cyr': 'Саволлар топилмади',
      'ru': 'Вопросы не найдены',
    },
    'finish': {'uz_lat': 'Yakunlash', 'uz_cyr': 'Якунлаш', 'ru': 'Завершить'},
    'exit_test': {
      'uz_lat': 'Testdan chiqish',
      'uz_cyr': 'Тестдан чиқиш',
      'ru': 'Выйти из теста',
    },
    'exit_test_msg': {
      'uz_lat': "Barcha javoblaringiz o'chiriladi. Chiqishni xohlaysizmi?",
      'uz_cyr': "Барча жавобларингиз ўчирилади. Чиқишни хоҳлайсизми?",
      'ru': 'Все ответы будут удалены. Вы хотите выйти?',
    },
    'no_continue': {
      'uz_lat': "Yo'q, davom etish",
      'uz_cyr': "Йўқ, давом этиш",
      'ru': 'Нет, продолжить',
    },
    'yes_exit': {
      'uz_lat': 'Ha, chiqish',
      'uz_cyr': 'Ҳа, чиқиш',
      'ru': 'Да, выйти',
    },
    'finish_test': {
      'uz_lat': 'Testni yakunlash',
      'uz_cyr': 'Тестни якунлаш',
      'ru': 'Завершить тест',
    },
    'answered': {
      'uz_lat': 'Javob berilgan',
      'uz_cyr': 'Жавоб берилган',
      'ru': 'Отвечено',
    },
    'unanswered': {
      'uz_lat': 'Javobsiz',
      'uz_cyr': 'Жавобсиз',
      'ru': 'Без ответа',
    },
    'total': {'uz_lat': 'Jami', 'uz_cyr': 'Жами', 'ru': 'Всего'},
    'unanswered_warning': {
      'uz_lat': 'ta savol javobsiz qolgan.',
      'uz_cyr': 'та савол жавобсиз қолган.',
      'ru': 'вопрос(а/ов) без ответа.',
    },
    'cancel': {
      'uz_lat': 'Bekor qilish',
      'uz_cyr': 'Бекор қилиш',
      'ru': 'Отмена',
    },
    'yes_finish': {
      'uz_lat': 'Ha, yakunlash',
      'uz_cyr': 'Ҳа, якунлаш',
      'ru': 'Да, завершить',
    },
    'auto_advance': {
      'uz_lat': 'Avtomatik o\'tish',
      'uz_cyr': 'Автоматик ўтиш',
      'ru': 'Автопереход',
    },
    'auto_advance_on': {
      'uz_lat': "Avtomatik o'tish yoqildi",
      'uz_cyr': 'Автоматик ўтиш ёқилди',
      'ru': 'Автопереход включён',
    },
    'auto_advance_off': {
      'uz_lat': "Avtomatik o'tish o'chirildi",
      'uz_cyr': 'Автоматик ўтиш ўчирилди',
      'ru': 'Автопереход выключен',
    },
    'auto_advance_setting': {
      'uz_lat': "Keyingi savolga avtomatik o'tish",
      'uz_cyr': 'Кейинги саволга автоматик ўтиш',
      'ru': 'Автопереход к следующему вопросу',
    },
    'auto_advance_sub': {
      'uz_lat': 'Javob belgilangach 1 soniyada keyingisi ochiladi',
      'uz_cyr': 'Жавоб белгилангач 1 сонияда кейингиси очилади',
      'ru': 'Через секунду после ответа откроется следующий',
    },
    'next_question': {'uz_lat': 'Keyingi', 'uz_cyr': 'Кейинги', 'ru': 'Далее'},
    'clear_results': {
      'uz_lat': "Natijalarni o'chirish",
      'uz_cyr': 'Натижаларни ўчириш',
      'ru': 'Удалить результаты',
    },
    'clear_results_msg': {
      'uz_lat':
          "Barcha test natijalari o'chirilsinmi? Bu amalni qaytarib bo'lmaydi.",
      'uz_cyr':
          "Барча тест натижалари ўчирилсинми? Бу амални қайтариб бўлмайди.",
      'ru': 'Удалить все результаты тестов? Это действие нельзя отменить.',
    },
    'results_cleared': {
      'uz_lat': "Natijalar o'chirildi",
      'uz_cyr': 'Натижалар ўчирилди',
      'ru': 'Результаты удалены',
    },
    'local_statistics': {
      'uz_lat': 'Test ishlash natijalari',
      'uz_cyr': 'Тест ишлаш натижалари',
      'ru': 'Результаты раздела «Тесты»',
    },
    'cloud_results': {
      'uz_lat': 'Mavzuli test va variantlar',
      'uz_cyr': 'Мавзули тест ва вариантлар',
      'ru': 'Тематические тесты и варианты',
    },
    'refresh_results': {
      'uz_lat': 'Yangilash',
      'uz_cyr': 'Янгилаш',
      'ru': 'Обновить',
    },
    'sync_success': {
      'uz_lat': 'Natijalar yangilandi',
      'uz_cyr': 'Натижалар янгиланди',
      'ru': 'Результаты обновлены',
    },
    'sync_failed': {
      'uz_lat': 'Yangilash amalga oshmadi. Internetni tekshiring.',
      'uz_cyr': 'Янгилаш амалга ошмади. Интернетни текширинг.',
      'ru': 'Не удалось обновить. Проверьте интернет.',
    },
    'clear_practice_results_msg': {
      'uz_lat': "Test ishlash bo'limidagi natijalar o'chirilsinmi?",
      'uz_cyr': "Test ishlash bo'limidagi natijalar o'chirilsinmi?",
      'ru': 'Удалить результаты из раздела «Тесты»?',
    },
    'login_for_cloud_results': {
      'uz_lat': 'Mavzu va variant natijalarini ko\'rish uchun tizimga kiring',
      'uz_cyr': 'Мавзу ва вариант натижаларини кўриш учун тизимга киринг.',
      'ru': 'Войдите, чтобы видеть результаты по темам и вариантам',
    },

    // ── Result screen ──
    'congrats': {
      'uz_lat': "Tabriklaymiz! Siz o'tdingiz!",
      'uz_cyr': "Табриклаймиз! Сиз ўтдингиз!",
      'ru': 'Поздравляем! Вы сдали!',
    },
    'failed': {
      'uz_lat': "Afsuski, o'ta olmadingiz",
      'uz_cyr': "Афсуски, ўта олмадингиз",
      'ru': 'К сожалению, вы не сдали',
    },
    'passed': {'uz_lat': "O'tdi", 'uz_cyr': "Ўтди", 'ru': 'Сдал'},
    'not_passed': {'uz_lat': "O'tmadi", 'uz_cyr': "Ўтмади", 'ru': 'Не сдал'},
    'correct': {'uz_lat': "To'g'ri", 'uz_cyr': "Тўғри", 'ru': 'Правильно'},
    'incorrect': {
      'uz_lat': "Noto'g'ri",
      'uz_cyr': "Нотўғри",
      'ru': 'Неправильно',
    },
    'time_spent': {
      'uz_lat': 'Sarflangan vaqt',
      'uz_cyr': 'Сарфланган вақт',
      'ru': 'Затраченное время',
    },
    'minutes': {'uz_lat': 'daqiqa', 'uz_cyr': 'дақиқа', 'ru': 'мин'},
    'seconds': {'uz_lat': 'soniya', 'uz_cyr': 'сония', 'ru': 'сек'},
    'retake_test': {
      'uz_lat': 'Qayta ishlash',
      'uz_cyr': 'Қайта ишлаш',
      'ru': 'Пройти заново',
    },
    'go_home': {
      'uz_lat': 'Bosh sahifaga qaytish',
      'uz_cyr': 'Бош саҳифага қайтиш',
      'ru': 'На главную',
    },

    // ── Practice setup ──
    'choose_count': {
      'uz_lat': 'Savollar sonini tanlang',
      'uz_cyr': 'Саволлар сонини танланг',
      'ru': 'Выберите количество вопросов',
    },
    'random_questions': {
      'uz_lat': 'Savollar tasodifiy tanlanadi',
      'uz_cyr': 'Саволлар тасодифий танланади',
      'ru': 'Вопросы выбираются случайно',
    },
    'n_questions': {
      'uz_lat': 'ta savol',
      'uz_cyr': 'та савол',
      'ru': 'вопрос(ов)',
    },
    'version_label': {'uz_lat': 'Versiya', 'uz_cyr': 'Версия', 'ru': 'Версия'},
    'my_results': {
      'uz_lat': 'Natijalarim',
      'uz_cyr': 'Натижаларим',
      'ru': 'Мои результаты',
    },
    'my_results_sub': {
      'uz_lat': "{n} ta test · {p} tasidan o'tilgan",
      'uz_cyr': '{n} та тест · {p} тасидан ўтилган',
      'ru': 'Тестов: {n} · сдано: {p}',
    },
    'my_results_empty': {
      'uz_lat': 'Hali test ishlanmagan',
      'uz_cyr': 'Ҳали тест ишланмаган',
      'ru': 'Пока нет пройденных тестов',
    },
    // Same three cells as the site's start page (TestStartPage stats).
    'stat_minutes': {'uz_lat': 'Daqiqa', 'uz_cyr': 'Дақиқа', 'ru': 'Минуты'},
    'stat_pass': {
      'uz_lat': "O'tish bali",
      'uz_cyr': 'Ўтиш бали',
      'ru': 'Проходной балл',
    },

    // ── Topic / variant screens ──
    'topic_tests': {
      'uz_lat': 'Mavzuli testlar',
      'uz_cyr': 'Мавзули тестлар',
      'ru': 'Тесты по темам',
    },
    'variants': {
      'uz_lat': 'Variantlar',
      'uz_cyr': 'Вариантлар',
      'ru': 'Варианты',
    },
    // Capitalised: this word starts the label of a result ("Variant 27"), and
    // lower-case there read like a typo.
    'variant': {'uz_lat': 'Variant', 'uz_cyr': 'Вариант', 'ru': 'Вариант'},

    // ── Errors screen ──
    'my_errors': {
      'uz_lat': 'Xatolarim',
      'uz_cyr': 'Хатоларим',
      'ru': 'Мои ошибки',
    },
    'clear': {'uz_lat': 'Tozalash', 'uz_cyr': 'Тозалаш', 'ru': 'Очистить'},
    'clear_errors_title': {
      'uz_lat': 'Xatolarni tozalash',
      'uz_cyr': 'Хатоларни тозалаш',
      'ru': 'Очистить ошибки',
    },
    'clear_errors_msg': {
      'uz_lat': "Barcha xatolar ro'yxati o'chirilsinmi?",
      'uz_cyr': "Барча хатолар рўйхати ўчирилсинми?",
      'ru': 'Удалить все ошибки?',
    },
    'yes': {'uz_lat': 'Ha', 'uz_cyr': 'Ҳа', 'ru': 'Да'},
    'no': {'uz_lat': "Yo'q", 'uz_cyr': 'Йўқ', 'ru': 'Нет'},
    'no_errors': {
      'uz_lat': 'Xatolar topilmadi!',
      'uz_cyr': 'Хатолар топилмади!',
      'ru': 'Ошибок не найдено!',
    },
    'no_errors_sub': {
      'uz_lat': 'Siz hali xato javob bermadingiz',
      'uz_cyr': 'Сиз ҳали хато жавоб бермадингиз',
      'ru': 'Вы ещё не допускали ошибок',
    },
    'total_errors': {
      'uz_lat': 'ta xato savol',
      'uz_cyr': 'та хато савол',
      'ru': 'ошибочных вопросов',
    },
    'practice_errors': {
      'uz_lat': 'Xatolar ustida ishlash',
      'uz_cyr': 'Хатолар устида ишлаш',
      'ru': 'Работа над ошибками',
    },
    'saved_tests': {
      'uz_lat': 'Saqlangan savollar',
      'uz_cyr': 'Сақланган саволлар',
      'ru': 'Сохранённые вопросы',
    },
    'save_question': {
      'uz_lat': 'Savolni saqlash',
      'uz_cyr': 'Саволни сақлаш',
      'ru': 'Сохранить вопрос',
    },
    'unsave_question': {
      'uz_lat': 'Saqlashni bekor qilish',
      'uz_cyr': 'Сақлашни бекор қилиш',
      'ru': 'Убрать из сохранённых',
    },
    'question_saved': {
      'uz_lat': 'Savol saqlandi',
      'uz_cyr': 'Савол сақланди',
      'ru': 'Вопрос сохранён',
    },
    'question_unsaved': {
      'uz_lat': 'Saqlash bekor qilindi',
      'uz_cyr': 'Сақлаш бекор қилинди',
      'ru': 'Удалено из сохранённых',
    },
    'no_saved': {
      'uz_lat': 'Saqlangan savollar yo\'q',
      'uz_cyr': 'Сақланган саволлар йўқ',
      'ru': 'Нет сохранённых вопросов',
    },
    'no_saved_sub': {
      'uz_lat':
          'Test ishlashda X tugmasi yonidagi belgi orqali savolni saqlang',
      'uz_cyr': 'Тест ишлашда X тугмаси ёнидаги белги орқали саволни сақланг',
      'ru': 'Сохраняйте вопросы кнопкой рядом с ✕ во время теста',
    },
    'saved_count': {
      'uz_lat': 'ta saqlangan savol',
      'uz_cyr': 'та сақланган савол',
      'ru': 'сохранённых вопросов',
    },
    'run_saved_tests': {
      'uz_lat': 'Barchasini ishlash',
      'uz_cyr': 'Барчасини ишлаш',
      'ru': 'Пройти все',
    },
    'clear_saved_title': {
      'uz_lat': 'Saqlanganlarni tozalash',
      'uz_cyr': 'Сақланганларни тозалаш',
      'ru': 'Очистить сохранённые',
    },
    'clear_saved_msg': {
      'uz_lat': 'Barcha saqlangan savollar o\'chirilsinmi?',
      'uz_cyr': 'Барча сақланган саволлар ўчирилсинми?',
      'ru': 'Удалить все сохранённые вопросы?',
    },
    'saved_question': {
      'uz_lat': 'Saqlangan savol',
      'uz_cyr': 'Сақланган савол',
      'ru': 'Сохранённый вопрос',
    },
    'question': {'uz_lat': 'Savol', 'uz_cyr': 'Савол', 'ru': 'Вопрос'},
    'has_image': {
      'uz_lat': 'Rasm bor',
      'uz_cyr': 'Расм бор',
      'ru': 'Есть изображение',
    },
    'correct_answer': {
      'uz_lat': "To'g'ri javob",
      'uz_cyr': "Тўғри жавоб",
      'ru': 'Правильный ответ',
    },
    'all_options': {
      'uz_lat': 'Barcha variantlar',
      'uz_cyr': 'Барча вариантлар',
      'ru': 'Все варианты',
    },

    // ── Profile / Settings ──
    'settings': {
      'uz_lat': 'Sozlamalar',
      'uz_cyr': 'Созламалар',
      'ru': 'Настройки',
    },
    'first_name': {'uz_lat': 'Ism', 'uz_cyr': 'Исм', 'ru': 'Имя'},
    'full_name': {
      'uz_lat': 'To\'liq ism',
      'uz_cyr': 'Тўлиқ исм',
      'ru': 'Полное имя',
    },
    'last_name': {'uz_lat': 'Familiya', 'uz_cyr': 'Фамилия', 'ru': 'Фамилия'},
    'save': {'uz_lat': 'Saqlash', 'uz_cyr': 'Сақлаш', 'ru': 'Сохранить'},
    'name_saved': {
      'uz_lat': 'Ism saqlandi',
      'uz_cyr': 'Исм сақланди',
      'ru': 'Имя сохранено',
    },
    'language': {'uz_lat': 'Til', 'uz_cyr': 'Тил', 'ru': 'Язык'},
    'theme': {'uz_lat': 'Mavzu', 'uz_cyr': 'Мавзу', 'ru': 'Тема'},
    'dark_mode': {
      'uz_lat': "Qorong'u rejim",
      'uz_cyr': "Қоронғу режим",
      'ru': 'Тёмный режим',
    },
    'light_mode': {
      'uz_lat': "Yorug' rejim",
      'uz_cyr': "Ёруғ режим",
      'ru': 'Светлый режим',
    },
    'statistics': {
      'uz_lat': 'Statistika',
      'uz_cyr': 'Статистика',
      'ru': 'Статистика',
    },
    'average': {'uz_lat': "O'rtacha", 'uz_cyr': "Ўртача", 'ru': 'Среднее'},

    // ── Website screen ──
    'visit_website': {
      'uz_lat': 'Rasmiy veb-saytimizga tashrif buyuring',
      'uz_cyr': 'Расмий веб-сайтимизга ташриф буюринг',
      'ru': 'Посетите наш официальный сайт',
    },
    'rate_app': {
      'uz_lat': 'Ilovani baholash',
      'uz_cyr': 'Иловани баҳолаш',
      'ru': 'Оценить приложение',
    },
    'rate_app_sub': {
      'uz_lat': 'Play Store\'da 5 yulduz qo\'ying',
      'uz_cyr': 'Play Store\'да 5 юлдуз қўйинг',
      'ru': 'Поставьте 5 звёзд в Play Store',
    },
    'telegram_group_title': {
      'uz_lat': 'AvtoSmart Telegram guruhi',
      'uz_cyr': 'AvtoSmart Телеграм гуруҳи',
      'ru': 'Telegram-группа AvtoSmart',
    },
    'telegram_group_body': {
      'uz_lat': 'Yangiliklar, savol-javob va foydali maslahatlar shu yerda',
      'uz_cyr': 'Янгиликлар, савол-жавоб ва фойдали маслаҳатлар шу ерда',
      'ru': 'Новости, вопросы и полезные советы — здесь',
    },
    'telegram_group_join': {
      'uz_lat': 'Qo\'shilish',
      'uz_cyr': 'Қўшилиш',
      'ru': 'Вступить',
    },
    'go_to_site': {
      'uz_lat': "Saytga o'tish",
      'uz_cyr': "Сайтга ўтиш",
      'ru': 'Перейти на сайт',
    },

    // ── Misc ──
    'your_answer': {
      'uz_lat': 'Sizning javobingiz:',
      'uz_cyr': 'Сизнинг жавобингиз:',
      'ru': 'Ваш ответ:',
    },
    'n_question_test': {
      'uz_lat': 'savollik test',
      'uz_cyr': 'саволлик тест',
      'ru': 'вопросов тест',
    },
    'start_test': {
      'uz_lat': 'Testni boshlash',
      'uz_cyr': 'Тестни бошлаш',
      'ru': 'Начать тест',
    },

    // ── Auth ──
    'sign_in': {'uz_lat': 'Kirish', 'uz_cyr': 'Кириш', 'ru': 'Войти'},
    'sign_in_for_pro': {
      'uz_lat': 'Akkauntga kirish (PRO)',
      'uz_cyr': 'Аккаунтга кириш (PRO)',
      'ru': 'Войти в аккаунт (PRO)',
    },
    'pro_badge': {'uz_lat': 'PRO', 'uz_cyr': 'PRO', 'ru': 'PRO'},
    'requires_pro': {
      'uz_lat': 'PRO obuna talab qilinadi',
      'uz_cyr': 'PRO обуна талаб қилинади',
      'ru': 'Требуется подписка PRO',
    },
    'explanation_title': {
      'uz_lat': 'Izoh',
      'uz_cyr': 'Изоҳ',
      'ru': 'Пояснение',
    },
    'explanation_offline_message': {
      'uz_lat': "Izohni ko'rish uchun internetga ulaning.",
      'uz_cyr': 'Изоҳни кўриш учун интернетга уланинг.',
      'ru': 'Подключитесь к интернету, чтобы посмотреть пояснение.',
    },
    'explanation_offline_retry': {
      'uz_lat': 'Qayta tekshirish',
      'uz_cyr': 'Қайта текшириш',
      'ru': 'Проверить снова',
    },
    'explanation_pro_message': {
      'uz_lat': "Izohlarni ko'rish uchun PRO obuna kerak",
      'uz_cyr': 'Изоҳларни кўриш учун PRO обуна керак',
      'ru': 'Для пояснений нужна подписка PRO',
    },
    'connectivity_required_test': {
      'uz_lat':
          'Mavzuli testni boshlash uchun internetga ulaning va PRO obunangizni tekshiring.',
      'uz_cyr':
          'Мавзули тестни бошлаш учун интернетга уланинг ва PRO обунангизни текширинг.',
      'ru':
          'Чтобы начать тест по теме, подключитесь к интернету — статус PRO будет проверен заново.',
    },
    'sign_in_title': {
      'uz_lat': 'Akkauntga kirish',
      'uz_cyr': 'Аккаунтга кириш',
      'ru': 'Вход в аккаунт',
    },
    'email': {'uz_lat': 'Email', 'uz_cyr': 'Email', 'ru': 'Email'},
    'password': {'uz_lat': 'Parol', 'uz_cyr': 'Парол', 'ru': 'Пароль'},
    'login_required_title': {
      'uz_lat': 'Kirish talab qilinadi',
      'uz_cyr': 'Кириш талаб қилинади',
      'ru': 'Требуется вход',
    },
    'login_required_body': {
      'uz_lat':
          'Mavzuli testlar va imtihon variantlariga kirish uchun avval akkauntingizga kiring.',
      'uz_cyr':
          'Мавзули тестлар ва имтиҳон вариантларига кириш учун аввал аккаунтингизга киринг.',
      'ru':
          'Чтобы открыть тесты по темам и экзаменационные варианты, сначала войдите в аккаунт.',
    },
    'telegram_open_failed': {
      'uz_lat': 'Telegramni ochib bo\'lmadi.',
      'uz_cyr': 'Telegramни очиб бўлмади.',
      'ru': 'Не удалось открыть Telegram.',
    },
    'auth_email_required': {
      'uz_lat': 'Emailni kiriting',
      'uz_cyr': 'Emailни киритинг',
      'ru': 'Введите email',
    },
    'auth_email_invalid': {
      'uz_lat': 'Email formati noto\'g\'ri',
      'uz_cyr': 'Email формати нотўғри',
      'ru': 'Неверный формат email',
    },
    'auth_password_required': {
      'uz_lat': 'Parolni kiriting',
      'uz_cyr': 'Паролни киритинг',
      'ru': 'Введите пароль',
    },
    'auth_error_invalid': {
      'uz_lat': 'Email yoki parol noto\'g\'ri.',
      'uz_cyr': 'Email ёки парол нотўғри.',
      'ru': 'Неверный email или пароль.',
    },
    'auth_error_unconfirmed': {
      'uz_lat': 'Email tasdiqlanmagan. Admin bilan bog\'laning.',
      'uz_cyr': 'Email тасдиқланмаган. Админ билан боғланинг.',
      'ru': 'Email не подтверждён. Свяжитесь с администратором.',
    },
    'auth_error_rate_limit': {
      'uz_lat': 'Juda ko\'p urinish. Iltimos, biroz kuting.',
      'uz_cyr': 'Жуда кўп уриниш. Илтимос, бироз кутинг.',
      'ru': 'Слишком много попыток. Подождите немного.',
    },
    'auth_error_network': {
      'uz_lat': 'Tarmoq xatoligi. Internetni tekshiring.',
      'uz_cyr': 'Тармоқ хатолиги. Интернетни текширинг.',
      'ru': 'Ошибка сети. Проверьте интернет.',
    },
    'auth_error_generic': {
      'uz_lat': 'Kirish amalga oshmadi. Qayta urinib ko\'ring.',
      'uz_cyr': 'Кириш амалга ошмади. Қайта уриниб кўринг.',
      'ru': 'Не удалось войти. Попробуйте снова.',
    },
    'auth_error_offline': {
      'uz_lat':
          'Tarmoq xatoligi. Internetni tekshiring va qayta urinib ko\'ring.',
      'uz_cyr': 'Тармоқ хатолиги. Интернетни текширинг ва қайта уриниб кўринг.',
      'ru': 'Ошибка сети. Проверьте интернет и попробуйте снова.',
    },
    'auth_error_email_taken': {
      'uz_lat': 'Bu email allaqachon ro\'yxatdan o\'tgan.',
      'uz_cyr': 'Бу email аллақачон рўйхатдан ўтган.',
      'ru': 'Этот email уже зарегистрирован.',
    },
    'auth_error_weak_password': {
      'uz_lat': 'Parol juda oddiy. Kamida 6 ta belgi kiriting.',
      'uz_cyr': 'Парол жуда оддий. Камида 6 та белги киритинг.',
      'ru': 'Пароль слишком простой. Минимум 6 символов.',
    },
    'auth_signup_check_email': {
      'uz_lat': 'Ro\'yxatdan o\'tish tugallandi. Emailingizni tasdiqlang.',
      'uz_cyr': 'Рўйхатдан ўтиш тугалланди. Emailингизни тасдиқланг.',
      'ru': 'Регистрация завершена. Подтвердите email.',
    },
    'sign_up': {
      'uz_lat': 'Ro\'yxatdan o\'tish',
      'uz_cyr': 'Рўйхатдан ўтиш',
      'ru': 'Регистрация',
    },
    'sign_up_title': {
      'uz_lat': 'Yangi akkaunt yaratish',
      'uz_cyr': 'Янги аккаунт яратиш',
      'ru': 'Создать аккаунт',
    },
    'username': {
      'uz_lat': 'Foydalanuvchi nomi',
      'uz_cyr': 'Фойдаланувчи номи',
      'ru': 'Имя пользователя',
    },
    'username_optional': {
      'uz_lat': 'Foydalanuvchi nomi (ixtiyoriy)',
      'uz_cyr': 'Фойдаланувчи номи (ихтиёрий)',
      'ru': 'Имя пользователя (необязательно)',
    },
    'full_name_optional': {
      'uz_lat': 'Ism familiya (ixtiyoriy)',
      'uz_cyr': 'Исм фамилия (ихтиёрий)',
      'ru': 'Имя и фамилия (необязательно)',
    },
    'have_account_question': {
      'uz_lat': 'Akkauntingiz bormi?',
      'uz_cyr': 'Аккаунтингиз борми?',
      'ru': 'Уже есть аккаунт?',
    },
    'no_account_question': {
      'uz_lat': 'Akkauntingiz yo\'qmi?',
      'uz_cyr': 'Аккаунтингиз йўқми?',
      'ru': 'Нет аккаунта?',
    },
    'create_account_cta': {
      'uz_lat': 'Ro\'yxatdan o\'ting',
      'uz_cyr': 'Рўйхатдан ўтинг',
      'ru': 'Зарегистрируйтесь',
    },
    'account': {'uz_lat': 'Akkaunt', 'uz_cyr': 'Аккаунт', 'ru': 'Аккаунт'},
    'guest_mode': {
      'uz_lat': 'Mehmon rejimi',
      'uz_cyr': 'Меҳмон режими',
      'ru': 'Гостевой режим',
    },
    'guest_mode_hint': {
      'uz_lat':
          'Mavzuli testlar va variantlar PRO obuna bilan ochiladi. Test ishlash bepul.',
      'uz_cyr':
          'Мавзули тестлар ва вариантлар PRO обуна билан очилади. Тест ишлаш бепул.',
      'ru': 'Тесты по темам и варианты доступны с PRO. Практика бесплатна.',
    },
    'confirm': {
      'uz_lat': 'Tasdiqlash',
      'uz_cyr': 'Тасдиқлаш',
      'ru': 'Подтверждение',
    },
    'logout': {'uz_lat': 'Chiqish', 'uz_cyr': 'Чиқиш', 'ru': 'Выйти'},
    'logout_confirm': {
      'uz_lat': 'Akkauntdan chiqishni tasdiqlaysizmi?',
      'uz_cyr': 'Аккаунтдан чиқишни тасдиқлайсизми?',
      'ru': 'Подтвердите выход из аккаунта?',
    },

    // ── PRO gate / screen ──
    'pro_section_title': {
      'uz_lat': 'Bu bo\'lim PRO uchun',
      'uz_cyr': 'Бу бўлим PRO учун',
      'ru': 'Этот раздел для PRO',
    },
    'pro_section_body': {
      'uz_lat':
          '"{feature}" bo\'limidan foydalanish uchun PRO obuna kerak. Obuna sotib olib, 1250+ savol va imtihonbop testlarga ega bo\'ling.',
      'uz_cyr':
          '"{feature}" бўлимидан фойдаланиш учун PRO обуна керак. Обуна сотиб олиб, 1250+ савол ва имтиҳонбоп тестларга эга бўлинг.',
      'ru':
          'Для доступа к «{feature}» нужна подписка PRO. Оформите подписку и получите 1250+ вопросов и экзаменационные тесты.',
    },
    'pro_perk_questions': {
      'uz_lat': '1250+ ta yopiq savollar bazasi',
      'uz_cyr': '1250+ та ёпиқ саволлар базаси',
      'ru': 'База из 1250+ закрытых вопросов',
    },
    'pro_perk_exams': {
      'uz_lat': 'Imtihonbop testlar va variantlar',
      'uz_cyr': 'Имтиҳонбоп тестлар ва вариантлар',
      'ru': 'Экзаменационные тесты и варианты',
    },
    'pro_perk_videos': {
      'uz_lat': 'Maxsus videodarsliklar',
      'uz_cyr': 'Махсус видеодарсликлар',
      'ru': 'Специальные видеоуроки',
    },
    'pro_perk_unlimited': {
      'uz_lat': 'Cheksiz vaqt va urinishlar',
      'uz_cyr': 'Чексиз вақт ва уринишлар',
      'ru': 'Неограниченное время и попытки',
    },
    'subscribe_pro': {
      'uz_lat': 'PRO ga obuna bo\'lish',
      'uz_cyr': 'PRO га обуна бўлиш',
      'ru': 'Оформить PRO',
    },
    'refresh_status': {
      'uz_lat': 'Statusni yangilash',
      'uz_cyr': 'Статусни янгилаш',
      'ru': 'Обновить статус',
    },
    'retry': {'uz_lat': 'Qayta', 'uz_cyr': 'Қайта', 'ru': 'Повторить'},
    'subscription_fetch_error': {
      'uz_lat': 'Obuna ma\'lumotini olishda xatolik. Qayta urinib ko\'ring.',
      'uz_cyr': 'Обуна маълумотини олишда хатолик. Қайта уриниб кўринг.',
      'ru': 'Ошибка загрузки подписки. Попробуйте снова.',
    },

    // ── Telefon orqali ro'yxatdan o'tish / kirish ──
    'phone_number': {
      'uz_lat': '90 123 45 67',
      'uz_cyr': '90 123 45 67',
      'ru': '90 123 45 67',
    },
    'phone_or_email': {
      'uz_lat': 'Telefon raqam yoki email',
      'uz_cyr': 'Телефон рақам ёки email',
      'ru': 'Номер телефона или email',
    },
    'password_min_8': {
      'uz_lat': 'Parol (kamida 8 belgi)',
      'uz_cyr': 'Парол (камида 8 белги)',
      'ru': 'Пароль (минимум 8 символов)',
    },
    'password_repeat': {
      'uz_lat': 'Parolni takrorlang',
      'uz_cyr': 'Паролни такрорланг',
      'ru': 'Повторите пароль',
    },
    // ── Sozlamalar bo'limlari ──
    'section_subscription': {
      'uz_lat': 'Obuna',
      'uz_cyr': 'Обуна',
      'ru': 'Подписка',
    },
    'section_account': {'uz_lat': 'Hisob', 'uz_cyr': 'Ҳисоб', 'ru': 'Аккаунт'},
    'section_preferences': {
      'uz_lat': 'Ilova sozlamalari',
      'uz_cyr': 'Илова созламалари',
      'ru': 'Настройки приложения',
    },
    'section_results': {
      'uz_lat': 'Natijalar',
      'uz_cyr': 'Натижалар',
      'ru': 'Результаты',
    },
    'user_default_name': {
      'uz_lat': 'Foydalanuvchi',
      'uz_cyr': 'Фойдаланувчи',
      'ru': 'Пользователь',
    },
    'edit_name': {
      'uz_lat': 'Ismni o\'zgartirish',
      'uz_cyr': 'Исмни ўзгартириш',
      'ru': 'Изменить имя',
    },
    'have_account_sign_in': {
      'uz_lat': 'Hisobim bor — kirish',
      'uz_cyr': 'Ҳисобим бор — кириш',
      'ru': 'У меня есть аккаунт — войти',
    },
    'create_account_for_pro': {
      'uz_lat': 'Ro\'yxatdan o\'tish',
      'uz_cyr': 'Рўйхатдан ўтиш',
      'ru': 'Зарегистрироваться',
    },
    'pro_entry_subtitle': {
      'uz_lat': 'Barcha mavzular, variantlar va izohlar',
      'uz_cyr': 'Барча мавзулар, вариантлар ва изоҳлар',
      'ru': 'Все темы, варианты и пояснения',
    },
    'no_local_results': {
      'uz_lat': 'Hali test ishlamadingiz',
      'uz_cyr': 'Ҳали тест ишламадингиз',
      'ru': 'Вы ещё не проходили тесты',
    },
    'signup_phone_hint': {
      'uz_lat':
          'Hisob telefon raqamingiz orqali ochiladi. Shu raqam bilan '
          'saytga ham kira olasiz.',
      'uz_cyr':
          'Ҳисоб телефон рақамингиз орқали очилади. Шу рақам билан '
          'сайтга ҳам кира оласиз.',
      'ru':
          'Аккаунт создаётся по номеру телефона. С ним же вы войдёте и на '
          'сайт.',
    },
    'auth_phone_required': {
      'uz_lat': 'Telefon raqamni kiriting',
      'uz_cyr': 'Телефон рақамни киритинг',
      'ru': 'Введите номер телефона',
    },
    'auth_identifier_required': {
      'uz_lat': 'Telefon raqam yoki emailni kiriting',
      'uz_cyr': 'Телефон рақам ёки emailни киритинг',
      'ru': 'Введите номер телефона или email',
    },
    'auth_error_identifier_invalid': {
      'uz_lat': 'Telefon raqam yoki email noto\'g\'ri',
      'uz_cyr': 'Телефон рақам ёки email нотўғри',
      'ru': 'Неверный номер телефона или email',
    },
    'auth_error_phone_invalid': {
      'uz_lat': 'Telefon raqam noto\'g\'ri. Namuna: 90 123 45 67',
      'uz_cyr': 'Телефон рақам нотўғри. Намуна: 90 123 45 67',
      'ru': 'Неверный номер. Пример: 90 123 45 67',
    },
    'auth_error_phone_taken': {
      'uz_lat':
          'Bu raqam allaqachon ro\'yxatdan o\'tgan. "Kirish" bo\'limidan '
          'foydalaning.',
      'uz_cyr':
          'Бу рақам аллақачон рўйхатдан ўтган. "Кириш" бўлимидан '
          'фойдаланинг.',
      'ru': 'Этот номер уже зарегистрирован. Воспользуйтесь входом.',
    },
    'auth_error_password_mismatch': {
      'uz_lat': 'Parollar mos kelmadi',
      'uz_cyr': 'Пароллар мос келмади',
      'ru': 'Пароли не совпадают',
    },
    'auth_error_current_password': {
      'uz_lat': 'Joriy parol noto\'g\'ri',
      'uz_cyr': 'Жорий парол нотўғри',
      'ru': 'Текущий пароль неверный',
    },
    'or': {'uz_lat': 'yoki', 'uz_cyr': 'ёки', 'ru': 'или'},
    'google_hint': {
      'uz_lat':
          'Saytda Google bilan ro\'yxatdan o\'tgan bo\'lsangiz, shu '
          'tugmani bosing',
      'uz_cyr':
          'Сайтда Google билан рўйхатдан ўтган бўлсангиз, шу тугмани '
          'босинг',
      'ru': 'Если вы регистрировались на сайте через Google — нажмите сюда',
    },
    'identifier_is_phone': {
      'uz_lat': 'Telefon raqam sifatida kirasiz',
      'uz_cyr': 'Телефон рақам сифатида кирасиз',
      'ru': 'Вход по номеру телефона',
    },
    'identifier_is_email': {
      'uz_lat': 'Email sifatida kirasiz',
      'uz_cyr': 'Email сифатида кирасиз',
      'ru': 'Вход по email',
    },
    'identifier_unknown': {
      'uz_lat': 'To\'liq telefon raqam (90 123 45 67) yoki email kiriting',
      'uz_cyr': 'Тўлиқ телефон рақам (90 123 45 67) ёки email киритинг',
      'ru': 'Введите полный номер (90 123 45 67) или email',
    },
    'auth_error_invalid_try_google': {
      'uz_lat':
          'Email yoki parol noto\'g\'ri. Agar Google orqali ro\'yxatdan '
          'o\'tgan bo\'lsangiz, "Google bilan davom etish"ni bosing.',
      'uz_cyr':
          'Email ёки парол нотўғри. Агар Google орқали рўйхатдан ўтган '
          'бўлсангиз, "Google билан давом этиш"ни босинг.',
      'ru':
          'Неверный email или пароль. Если вы регистрировались через Google '
          '— нажмите «Продолжить с Google».',
    },
    'auth_error_reset_phone_account': {
      'uz_lat':
          'Telefon raqamli hisob uchun parolni admin tiklaydi: '
          '@avtosmart1',
      'uz_cyr':
          'Телефон рақамли ҳисоб учун паролни админ тиклайди: '
          '@avtosmart1',
      'ru':
          'Для аккаунта по номеру телефона пароль восстанавливает админ: '
          '@avtosmart1',
    },
    'reset_needs_email': {
      'uz_lat':
          'Parolni tiklash uchun avval emailingizni kiriting. Telefon '
          'raqamli hisob bo\'lsa — @avtosmart1 ga yozing.',
      'uz_cyr':
          'Паролни тиклаш учун аввал emailингизни киритинг. Телефон '
          'рақамли ҳисоб бўлса — @avtosmart1 га ёзинг.',
      'ru':
          'Чтобы восстановить пароль, введите email. Для аккаунта по номеру '
          'телефона — напишите @avtosmart1.',
    },
    'reset_email_sent': {
      'uz_lat': 'Parolni tiklash havolasi emailingizga yuborildi.',
      'uz_cyr': 'Паролни тиклаш ҳаволаси emailингизга юборилди.',
      'ru': 'Ссылка для сброса пароля отправлена на email.',
    },
    'need_help': {
      'uz_lat': 'Yordam kerakmi?',
      'uz_cyr': 'Ёрдам керакми?',
      'ru': 'Нужна помощь?',
    },
    'continue_with_google': {
      'uz_lat': 'Google bilan davom etish',
      'uz_cyr': 'Google билан давом этиш',
      'ru': 'Продолжить с Google',
    },
    'forgot_password': {
      'uz_lat': 'Parolni tiklash',
      'uz_cyr': 'Паролни тиклаш',
      'ru': 'Восстановление пароля',
    },
    // ── Hisobni o'chirish ──
    'delete_account': {
      'uz_lat': 'Hisobni o\'chirish',
      'uz_cyr': 'Ҳисобни ўчириш',
      'ru': 'Удалить аккаунт',
    },
    'delete_account_sub': {
      'uz_lat': 'Hisob va barcha ma\'lumotlar butunlay o\'chiriladi',
      'uz_cyr': 'Ҳисоб ва барча маълумотлар бутунлай ўчирилади',
      'ru': 'Аккаунт и все данные удаляются безвозвратно',
    },
    'delete_account_warning': {
      'uz_lat':
          'Hisobingiz, test natijalaringiz, xatolaringiz va saqlangan '
          'savollaringiz butunlay o\'chiriladi. Bu amalni qaytarib bo\'lmaydi.',
      'uz_cyr':
          'Ҳисобингиз, тест натижаларингиз, хатоларингиз ва сақланган '
          'саволларингиз бутунлай ўчирилади. Бу амални қайтариб бўлмайди.',
      'ru':
          'Ваш аккаунт, результаты тестов, ошибки и сохранённые вопросы будут '
          'удалены навсегда. Это действие нельзя отменить.',
    },
    'delete_account_pro_warning': {
      'uz_lat':
          'Sizda faol PRO obuna bor. U ham bekor qilinadi va puli '
          'qaytarilmaydi.',
      'uz_cyr':
          'Сизда фаол PRO обуна бор. У ҳам бекор қилинади ва пули '
          'қайтарилмайди.',
      'ru':
          'У вас активная PRO-подписка. Она также будет аннулирована без '
          'возврата средств.',
    },
    'delete_account_final_title': {
      'uz_lat': 'Aniq o\'chirilsinmi?',
      'uz_cyr': 'Аниқ ўчирилсинми?',
      'ru': 'Точно удалить?',
    },
    'delete_account_final_msg': {
      'uz_lat': 'Bu oxirgi tasdiq. Hisob o\'chirilgach tiklab bo\'lmaydi.',
      'uz_cyr': 'Бу охирги тасдиқ. Ҳисоб ўчирилгач тиклаб бўлмайди.',
      'ru': 'Это последнее подтверждение. Восстановить аккаунт будет нельзя.',
    },
    'delete_account_yes': {
      'uz_lat': 'Ha, o\'chirilsin',
      'uz_cyr': 'Ҳа, ўчирилсин',
      'ru': 'Да, удалить',
    },
    'account_deleted': {
      'uz_lat': 'Hisob o\'chirildi.',
      'uz_cyr': 'Ҳисоб ўчирилди.',
      'ru': 'Аккаунт удалён.',
    },
    'account_delete_failed': {
      'uz_lat':
          'Hisobni o\'chirib bo\'lmadi. Internetni tekshirib, qayta '
          'urinib ko\'ring yoki @avtosmart1 ga yozing.',
      'uz_cyr':
          'Ҳисобни ўчириб бўлмади. Интернетни текшириб, қайта уриниб '
          'кўринг ёки @avtosmart1 га ёзинг.',
      'ru':
          'Не удалось удалить аккаунт. Проверьте интернет и попробуйте снова '
          'или напишите @avtosmart1.',
    },
    'continue_action': {
      'uz_lat': 'Davom etish',
      'uz_cyr': 'Давом этиш',
      'ru': 'Продолжить',
    },
    'change_password': {
      'uz_lat': 'Parolni o\'zgartirish',
      'uz_cyr': 'Паролни ўзгартириш',
      'ru': 'Смена пароля',
    },
    'current_password': {
      'uz_lat': 'Joriy parol',
      'uz_cyr': 'Жорий парол',
      'ru': 'Текущий пароль',
    },
    'new_password_min_8': {
      'uz_lat': 'Yangi parol (kamida 8 belgi)',
      'uz_cyr': 'Янги парол (камида 8 белги)',
      'ru': 'Новый пароль (минимум 8 символов)',
    },
    'password_changed': {
      'uz_lat': 'Parol o\'zgartirildi',
      'uz_cyr': 'Парол ўзгартирилди',
      'ru': 'Пароль изменён',
    },

    // ── Payme to'lovi ──
    'n_days': {'uz_lat': 'kunlik', 'uz_cyr': 'кунлик', 'ru': 'дней'},
    'plans_load_failed': {
      'uz_lat': 'Tariflarni yuklab bo\'lmadi. Internetni tekshiring.',
      'uz_cyr': 'Тарифларни юклаб бўлмади. Интернетни текширинг.',
      'ru': 'Не удалось загрузить тарифы. Проверьте интернет.',
    },
    'pro_already_active': {
      'uz_lat':
          'Obunangiz faol. Muddati tugagach yangi obuna olishingiz mumkin.',
      'uz_cyr': 'Обунангиз фаол. Муддати тугагач янги обуна олишингиз мумкин.',
      'ru': 'Подписка активна. Новую можно оформить после её окончания.',
    },
    'payme_secure_note': {
      'uz_lat':
          'To\'lov Payme yoki Click orqali amalga oshiriladi. PRO obuna '
          'to\'lov tasdiqlangach avtomatik ochiladi.',
      'uz_cyr':
          'Тўлов Payme ёки Click орқали амалга оширилади. PRO обуна тўлов '
          'тасдиқлангач автоматик очилади.',
      'ru':
          'Оплата проходит через Payme или Click. PRO активируется '
          'автоматически после подтверждения платежа.',
    },
    'pay_method': {
      'uz_lat': "To'lov usuli",
      'uz_cyr': 'Тўлов усули',
      'ru': 'Способ оплаты',
    },
    'payment_link_failed': {
      'uz_lat':
          "To'lov havolasini yaratib bo'lmadi. Internetni tekshirib, qayta "
          "urinib ko'ring.",
      'uz_cyr':
          'Тўлов ҳаволасини яратиб бўлмади. Интернетни текшириб, қайта '
          'уриниб кўринг.',
      'ru':
          'Не удалось создать ссылку на оплату. Проверьте интернет и '
          'попробуйте снова.',
    },
    'payment_too_many': {
      'uz_lat':
          "Urinishlar soni ko'payib ketdi. Birozdan so'ng qayta urinib ko'ring.",
      'uz_cyr':
          'Уринишлар сони кўпайиб кетди. Бироздан сўнг қайта уриниб кўринг.',
      'ru': 'Слишком много попыток. Попробуйте чуть позже.',
    },
    'payment_verifying': {
      'uz_lat': 'To\'lov tekshirilmoqda...',
      'uz_cyr': 'Тўлов текширилмоқда...',
      'ru': 'Проверяем платёж...',
    },
    'payment_success_title': {
      'uz_lat': 'PRO obuna faollashdi',
      'uz_cyr': 'PRO обуна фаоллашди',
      'ru': 'PRO активирован',
    },
    'payment_success_msg': {
      'uz_lat': 'To\'lov qabul qilindi. Barcha PRO bo\'limlar ochildi.',
      'uz_cyr': 'Тўлов қабул қилинди. Барча PRO бўлимлар очилди.',
      'ru': 'Платёж принят. Все PRO-разделы открыты.',
    },
    'payment_pending': {
      'uz_lat':
          'To\'lov tekshirilmoqda. Bir necha daqiqadan so\'ng '
          '"Statusni yangilash"ni bosing.',
      'uz_cyr':
          'Тўлов текширилмоқда. Бир неча дақиқадан сўнг '
          '"Статусни янгилаш"ни босинг.',
      'ru': 'Платёж проверяется. Через пару минут нажмите «Обновить статус».',
    },
    'payment_cancel_title': {
      'uz_lat': 'To\'lovni bekor qilasizmi?',
      'uz_cyr': 'Тўловни бекор қиласизми?',
      'ru': 'Отменить оплату?',
    },
    'payment_cancel_msg': {
      'uz_lat': 'To\'lov yakunlanmagan. Oynani yopsangiz obuna faollashmaydi.',
      'uz_cyr': 'Тўлов якунланмаган. Ойнани ёпсангиз обуна фаоллашмайди.',
      'ru': 'Платёж не завершён. Если закрыть окно, подписка не активируется.',
    },
    'payment_open_browser': {
      'uz_lat': 'Brauzerda ochish',
      'uz_cyr': 'Браузерда очиш',
      'ru': 'Открыть в браузере',
    },
    'payment_open_failed': {
      'uz_lat': 'To\'lov sahifasini ochib bo\'lmadi.',
      'uz_cyr': 'Тўлов саҳифасини очиб бўлмади.',
      'ru': 'Не удалось открыть страницу оплаты.',
    },
    'close': {'uz_lat': 'Yopish', 'uz_cyr': 'Ёпиш', 'ru': 'Закрыть'},
    'great': {'uz_lat': 'Ajoyib', 'uz_cyr': 'Ажойиб', 'ru': 'Отлично'},

    // ── Screen reader ──
    // Spoken instead of the colour that carries these states visually.
    'a11y_answer_correct': {
      'uz_lat': 'to\'g\'ri javob',
      'uz_cyr': 'тўғри жавоб',
      'ru': 'правильный ответ',
    },
    'a11y_answer_incorrect': {
      'uz_lat': 'sizning javobingiz, noto\'g\'ri',
      'uz_cyr': 'сизнинг жавобингиз, нотўғри',
      'ru': 'ваш ответ, неправильно',
    },

    // ── Real imtihon ──
    'real_exam': {
      'uz_lat': 'Real imtihon',
      'uz_cyr': 'Реал имтиҳон',
      'ru': 'Реальный экзамен',
    },
    'real_exam_sub': {
      'uz_lat': 'Rasmiy imtihon shartlarida: 20 savol, 25 daqiqa, izohsiz',
      'uz_cyr': 'Расмий имтиҳон шартларида: 20 савол, 25 дақиқа, изоҳсиз',
      'ru':
          'В условиях официального экзамена: 20 вопросов, 25 минут, без пояснений',
    },
    'real_exam_intro': {
      'uz_lat':
          'Imtihon rasmiy dastur ko\'rinishida ochiladi. Til imtihon ichida '
          'almashtirilmaydi, izoh ko\'rsatilmaydi.',
      'uz_cyr':
          'Имтиҳон расмий дастур кўринишида очилади. Тил имтиҳон ичида '
          'алмаштирилмайди, изоҳ кўрсатилмайди.',
      'ru':
          'Экзамен открывается в виде официальной программы. Язык внутри '
          'экзамена не меняется, пояснения не показываются.',
    },
    'real_exam_start': {
      'uz_lat': 'Imtihonni boshlash',
      'uz_cyr': 'Имтиҳонни бошлаш',
      'ru': 'Начать экзамен',
    },
    'real_exam_free_pool': {
      'uz_lat': 'Bepul to\'plamdan savollar. PRO da to\'liq bazadan tanlanadi.',
      'uz_cyr': 'Бепул тўпламдан саволлар. PRO да тўлиқ базадан танланади.',
      'ru': 'Вопросы из бесплатного набора. В PRO — из полной базы.',
    },
    'real_exam_exit_title': {
      'uz_lat': 'Imtihonni yakunlaysizmi?',
      'uz_cyr': 'Имтиҳонни якунлайсизми?',
      'ru': 'Завершить экзамен?',
    },
    'real_exam_exit_msg': {
      'uz_lat': 'Javob berilmagan savollar xato deb hisoblanadi.',
      'uz_cyr': 'Жавоб берилмаган саволлар хато деб ҳисобланади.',
      'ru': 'Неотвеченные вопросы будут засчитаны как ошибки.',
    },

    // ── Yodlash kerak ──
    'memorize': {
      'uz_lat': 'Yodlash kerak',
      'uz_cyr': 'Ёдлаш керак',
      'ru': 'Надо запомнить',
    },
    'memorize_sub': {
      'uz_lat': 'Imtihonda uchraydigan raqamlar: tezlik, masofa, o\'lcham',
      'uz_cyr': 'Имтиҳонда учрайдиган рақамлар: тезлик, масофа, ўлчам',
      'ru': 'Числа с экзамена: скорость, расстояние, габариты',
    },

    // ── Avtodrom ──
    'avtodrom': {'uz_lat': 'Avtodrom', 'uz_cyr': 'Автодром', 'ru': 'Автодром'},
    'avtodrom_sub': {
      'uz_lat': 'Amaliy imtihon jarima ballari',
      'uz_cyr': 'Амалий имтиҳон жарима баллари',
      'ru': 'Штрафные баллы практического экзамена',
    },
    'avtodrom_points': {'uz_lat': 'ball', 'uz_cyr': 'балл', 'ru': 'балл.'},
    // The website shows the same caveat: only the Latin text comes from the
    // official document, the other two are this project's translation.
    'avtodrom_translation_note': {
      'uz_lat':
          'Kirill va rus tilidagi matn shu loyihada tarjima qilingan — '
          'rasmiy hujjat formulirovkasidan farq qilishi mumkin.',
      'uz_cyr':
          'Кирилл ва рус тилидаги матн шу лойиҳада таржима қилинган — '
          'расмий ҳужжат формулировкасидан фарқ қилиши мумкин.',
      'ru':
          'Текст на кириллице и русском переведён в этом проекте — он может '
          'отличаться от формулировок официального документа.',
    },

    // ── Savol qidirish ──
    'question_search': {
      'uz_lat': 'Savol qidirish',
      'uz_cyr': 'Савол қидириш',
      'ru': 'Поиск вопроса',
    },
    'question_search_sub': {
      'uz_lat': 'Butun bazadan matn bo\'yicha qidiring',
      'uz_cyr': 'Бутун базадан матн бўйича қидиринг',
      'ru': 'Поиск по тексту во всей базе',
    },
    'question_search_hint': {
      'uz_lat': 'Savol yoki javob matni…',
      'uz_cyr': 'Савол ёки жавоб матни…',
      'ru': 'Текст вопроса или ответа…',
    },
    'question_search_empty': {
      'uz_lat': 'Qidirish uchun kamida 3 ta belgi kiriting',
      'uz_cyr': 'Қидириш учун камида 3 та белги киритинг',
      'ru': 'Введите минимум 3 символа для поиска',
    },
    'question_search_count': {
      'uz_lat': 'ta natija',
      'uz_cyr': 'та натижа',
      'ru': 'результатов',
    },

    // Shown instead of a raw `question_source` string when a result cannot be
    // matched to a known test — a file name must never reach the user.
    'test_result_generic': {'uz_lat': 'Test', 'uz_cyr': 'Тест', 'ru': 'Тест'},

    // ── Ilova haqida / yangilanish ──
    'section_about': {
      'uz_lat': 'Ilova haqida',
      'uz_cyr': 'Илова ҳақида',
      'ru': 'О приложении',
    },
    'check_for_updates': {
      'uz_lat': 'Yangilanishni tekshirish',
      'uz_cyr': 'Янгиланишни текшириш',
      'ru': 'Проверить обновления',
    },
    'update_available_title': {
      'uz_lat': 'Yangi versiya chiqdi',
      'uz_cyr': 'Янги версия чиқди',
      'ru': 'Вышла новая версия',
    },
    'update_available_body': {
      'uz_lat': "Yangi savollar va tuzatishlar uchun ilovani yangilang",
      'uz_cyr': 'Янги саволлар ва тузатишлар учун иловани янгиланг',
      'ru': 'Обновите приложение — новые вопросы и исправления',
    },
    'update_ready_title': {
      'uz_lat': 'Yangilanish tayyor',
      'uz_cyr': 'Янгиланиш тайёр',
      'ru': 'Обновление готово',
    },
    'update_ready_body': {
      'uz_lat': "Ilova qayta ishga tushganda o'rnatiladi",
      'uz_cyr': 'Илова қайта ишга тушганда ўрнатилади',
      'ru': 'Установится при следующем запуске приложения',
    },
    'update_action': {
      'uz_lat': 'Yuklab olish',
      'uz_cyr': 'Юклаб олиш',
      'ru': 'Скачать',
    },
    'update_up_to_date': {
      'uz_lat': "Sizda eng so'nggi versiya o'rnatilgan",
      'uz_cyr': "Сизда энг сўнгги версия ўрнатилган",
      'ru': 'У вас установлена последняя версия',
    },

    // ── Bepul kirish ──
    'free_variants_notice': {
      'uz_lat': 'Dastlabki 5 ta variant bepul. Qolganlari PRO bilan ochiladi.',
      'uz_cyr': 'Дастлабки 5 та вариант бепул. Қолганлари PRO билан очилади.',
      'ru': 'Первые 5 вариантов бесплатны. Остальные открываются с PRO.',
    },
    'free_topics_notice': {
      'uz_lat':
          'Umumiy qoidalar va Haydovchining umumiy vazifalari bepul. '
          'Qolgan mavzular PRO bilan ochiladi.',
      'uz_cyr':
          'Умумий қоидалар ва Ҳайдовчининг умумий вазифалари бепул. '
          'Қолган мавзулар PRO билан очилади.',
      'ru':
          'Общие правила и Общие обязанности водителя бесплатны. '
          'Остальные темы открываются с PRO.',
    },

    'free_variants_short': {
      'uz_lat': '1-5 bepul, qolgani PRO',
      'uz_cyr': '1-5 бепул, қолгани PRO',
      'ru': '1-5 бесплатно, остальные PRO',
    },
    'free_topics_short': {
      'uz_lat': '2 ta mavzu bepul, qolgani PRO',
      'uz_cyr': '2 та мавзу бепул, қолгани PRO',
      'ru': '2 темы бесплатно, остальные PRO',
    },

    'pro_all_unlocked': {
      'uz_lat':
          'Obunangiz faol - barcha variantlar, mavzular va izohlar ochiq. '
          'Muddati tugagach shu yerdan yangilaysiz.',
      'uz_cyr':
          'Обунангиз фаол - барча вариантлар, мавзулар ва изоҳлар очиқ. '
          'Муддати тугагач шу ердан янгилайсиз.',
      'ru':
          'Подписка активна - все варианты, темы и пояснения открыты. '
          'Продлить можно здесь после окончания срока.',
    },

    'quick_actions': {
      'uz_lat': 'Tez kirish',
      'uz_cyr': 'Тез кириш',
      'ru': 'Быстрый доступ',
    },
    'quick_real_exam': {
      'uz_lat': '20 savol · 25 daqiqa',
      'uz_cyr': '20 савол · 25 дақиқа',
      'ru': '20 вопросов · 25 минут',
    },
    'quick_errors': {
      'uz_lat': 'Xatolaringizni takrorlang',
      'uz_cyr': 'Хатоларингизни такрорланг',
      'ru': 'Повторите свои ошибки',
    },
    'quick_saved': {
      'uz_lat': "Belgilab qo'yganlaringiz",
      'uz_cyr': 'Белгилаб қўйганларингиз',
      'ru': 'Отмеченные вопросы',
    },
    'quick_signs': {
      'uz_lat': '269 ta belgi va izohi',
      'uz_cyr': '269 та белги ва изоҳи',
      'ru': '269 знаков с пояснениями',
    },

    'zoom_image': {
      'uz_lat': 'Rasmni kattalashtirish',
      'uz_cyr': 'Расмни катталаштириш',
      'ru': 'Увеличить изображение',
    },

    'text_size': {
      'uz_lat': "Savol matni o'lchami",
      'uz_cyr': 'Савол матни ўлчами',
      'ru': 'Размер текста вопроса',
    },
    'text_size_hint': {
      'uz_lat': 'Savol va javoblar shriftini kattalashtiring',
      'uz_cyr': 'Савол ва жавоблар шрифтини катталаштиринг',
      'ru': 'Увеличьте шрифт вопросов и ответов',
    },
    'text_size_preview': {
      'uz_lat': "Chorrahaga birinchi bo'lib kim kiradi?",
      'uz_cyr': 'Чорраҳага биринчи бўлиб ким киради?',
      'ru': 'Кто первым проезжает перекрёсток?',
    },

    'topic_stats': {
      'uz_lat': "Mavzular bo'yicha natija",
      'uz_cyr': 'Мавзулар бўйича натижа',
      'ru': 'Результаты по темам',
    },
    'topic_stats_sub': {
      'uz_lat': "Qaysi mavzuda kuchsizsiz — shuni ko'ring",
      'uz_cyr': 'Қайси мавзуда кучсизсиз — шуни кўринг',
      'ru': 'Посмотрите, в каких темах вы слабее',
    },
    'topic_stats_hint': {
      'uz_lat': 'Eng past natijali mavzular yuqorida. Shulardan boshlang.',
      'uz_cyr': 'Энг паст натижали мавзулар юқорида. Шулардан бошланг.',
      'ru': 'Темы с худшим результатом сверху. Начните с них.',
    },
    'topic_stats_empty': {
      'uz_lat':
          "Hali ma'lumot yo'q. Bir nechta test ishlang — "
          "keyin qaysi mavzuda kuchsiz ekaningiz shu yerda ko'rinadi.",
      'uz_cyr':
          'Ҳали маълумот йўқ. Бир нечта тест ишланг — '
          'кейин қайси мавзуда кучсиз эканингиз шу ерда кўринади.',
      'ru':
          'Пока нет данных. Пройдите несколько тестов — '
          'и здесь появится разбор по темам.',
    },
    'topic_stats_untouched': {
      'uz_lat': 'HALI ISHLANMAGAN',
      'uz_cyr': 'ҲАЛИ ИШЛАНМАГАН',
      'ru': 'ЕЩЁ НЕ ПРОЙДЕНО',
    },

    'daily_question': {
      'uz_lat': 'Kunlik savol',
      'uz_cyr': 'Кунлик савол',
      'ru': 'Вопрос дня',
    },
    'daily_question_sub': {
      'uz_lat': 'Har kuni bitta savol bildirishnoma sifatida',
      'uz_cyr': 'Ҳар куни битта савол билдиришнома сифатида',
      'ru': 'Каждый день один вопрос в уведомлении',
    },
    'daily_question_title': {
      'uz_lat': 'Bugungi savol',
      'uz_cyr': 'Бугунги савол',
      'ru': 'Вопрос дня',
    },
    'daily_question_time': {
      'uz_lat': 'Yuborish vaqti',
      'uz_cyr': 'Юбориш вақти',
      'ru': 'Время отправки',
    },
    'daily_question_denied': {
      'uz_lat':
          'Bildirishnomaga ruxsat berilmadi. Telefon sozlamalaridan yoqishingiz mumkin.',
      'uz_cyr':
          'Билдиришномага рухсат берилмади. Телефон созламаларидан ёқишингиз мумкин.',
      'ru':
          'Разрешение на уведомления не выдано. Его можно включить в настройках телефона.',
    },

    'section_study': {
      'uz_lat': 'Mashq sozlamalari',
      'uz_cyr': 'Машқ созламалари',
      'ru': 'Настройки практики',
    },
    'auto_explanation': {
      'uz_lat': 'Xatodan keyin izoh',
      'uz_cyr': 'Хатодан кейин изоҳ',
      'ru': 'Пояснение после ошибки',
    },
    'auto_explanation_sub': {
      'uz_lat': "Xato javob bergach izoh o'zi ochiladi",
      'uz_cyr': 'Хато жавоб бергач изоҳ ўзи очилади',
      'ru': 'Пояснение открывается само после ошибки',
    },
    'reset': {'uz_lat': 'Standart', 'uz_cyr': 'Стандарт', 'ru': 'По умолчанию'},

    'section_reference': {
      'uz_lat': "O'rganish",
      'uz_cyr': 'Ўрганиш',
      'ru': 'Обучение',
    },
    'section_practice': {
      'uz_lat': 'Imtihon va takrorlash',
      'uz_cyr': 'Имтиҳон ва такрорлаш',
      'ru': 'Экзамен и повторение',
    },
  };
}
