#!/bin/sh

# ============================================================================
# STARGATE-AREA.SH
# Динамически генерирует переключатели по странам на основе SG_COUNTRIES
# По аналогии с RU_* переключателями в stargate-lite.yaml
# Источник: https://raw.githubusercontent.com/Viktor45/mh-templates/refs/heads/main/area/stargate-area.yaml
# Дополнение: https://raw.githubusercontent.com/Viktor45/mh-templates/refs/heads/main/area/user_sh/stargate-area.sh
# ============================================================================

# Запускаться только если используется соответствующий конфиг, иначе пропуск
if [ "$CONFIG" = "stargate-area.yaml" ]; then
  # Использование:
  #   SG_COUNTRIES="US,NL,DE,GB,FR,JP,SG,CA,AU,KR,IN,BR,IT,ES,PL"
  #   SG_CODE="false"  # false = фильтр только по FLAG, true = FLAG + CODE
  #   SG_FASTEST="true"  # true = разрешить блоки поиска быстрого
  #   SG_FAILOVER="true" # true = разрешить блоки поиска отказоустойчивого
  # Для каждой страны создаются группы:
  #   XX_AUTO     — автоматический выбор (FASTEST → FAILOVER → MANUAL → AUTO)
  #   XX_MANUAL   — ручной выбор прокси страны
  #   XX_FASTEST  — самый быстрый прокси страны (url-test) [если SG_FASTEST=true]
  #   XX_FAILOVER — резервный прокси страны (fallback) [если SG_FAILOVER=true]
  # ============================================================================
  # SG_CODE — режим фильтрации прокси по стране
  #   false (по умолчанию) — фильтр только по флагу эмодзи (🇺🇸, 🇩🇪 и т.д.)
  #   true — фильтр по флагу И коду страны (🇺🇸|US, 🇩🇪|DE и т.д.)
  # По умолчанию false если не установлен
  SG_CODE="${SG_CODE:-false}"
  SG_FASTEST="${SG_FASTEST:-true}"
  SG_FAILOVER="${SG_FAILOVER:-true}"

  # Карта флагов для кодов стран
  get_flag() {
    case "$1" in
    US) echo "🇺🇸" ;;
    NL) echo "🇳🇱" ;;
    DE) echo "🇩🇪" ;;
    GB) echo "🇬🇧" ;;
    FR) echo "🇫🇷" ;;
    JP) echo "🇯🇵" ;;
    SG) echo "🇸🇬" ;;
    CA) echo "🇨🇦" ;;
    AU) echo "🇦🇺" ;;
    KR) echo "🇰🇷" ;;
    IN) echo "🇮🇳" ;;
    BR) echo "🇧🇷" ;;
    IT) echo "🇮🇹" ;;
    ES) echo "🇪🇸" ;;
    PL) echo "🇵🇱" ;;
    SE) echo "🇸🇪" ;;
    FI) echo "🇫🇮" ;;
    NO) echo "🇳🇴" ;;
    CH) echo "🇨🇭" ;;
    CZ) echo "🇨🇿" ;;
    UA) echo "🇺🇦" ;;
    TR) echo "🇹🇷" ;;
    IL) echo "🇮🇱" ;;
    AE) echo "🇦🇪" ;;
    *) echo "" ;;
    esac
  }

  # Получить название страны для отображения
  get_country_name() {
    case "$1" in
    US) echo "США" ;;
    NL) echo "Нидерланды" ;;
    DE) echo "Германия" ;;
    GB) echo "Великобритания" ;;
    FR) echo "Франция" ;;
    JP) echo "Япония" ;;
    SG) echo "Сингапур" ;;
    CA) echo "Канада" ;;
    AU) echo "Австралия" ;;
    KR) echo "Южная Корея" ;;
    IN) echo "Индия" ;;
    BR) echo "Бразилия" ;;
    IT) echo "Италия" ;;
    ES) echo "Испания" ;;
    PL) echo "Польша" ;;
    SE) echo "Швеция" ;;
    FI) echo "Финляндия" ;;
    NO) echo "Норвегия" ;;
    CH) echo "Швейцария" ;;
    CZ) echo "Чехия" ;;
    UA) echo "Украина" ;;
    TR) echo "Турция" ;;
    IL) echo "Израиль" ;;
    AE) echo "ОАЭ" ;;
    *) echo "$1" ;;
    esac
  }

  # Если SG_COUNTRIES не задан — выходим без ошибок
  if [ -z "$SG_COUNTRIES" ]; then
    echo "stargate-area.sh: SG_COUNTRIES not set, skipping area groups generation"
    # Пустые переменные чтобы envsubst не упал
    AREA_GROUPS_BLOCK=""
    AREA_GROUPS_LIST=""
    AREA_SELECTOR_PROXIES=""
    export AREA_GROUPS_BLOCK AREA_GROUPS_LIST AREA_SELECTOR_PROXIES
    return 2>/dev/null || true
    exit 0
  fi

  # Инициализируем переменные
  AREA_GROUPS_BLOCK=""
  AREA_GROUPS_LIST=""
  AREA_SELECTOR_PROXIES=""

  # Разбиваем SG_COUNTRIES по запятой во временный файл
  echo "$SG_COUNTRIES" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' >/tmp/.area_countries.$$

  # Обрабатываем каждую страну
  while read -r CODE; do
    [ -z "$CODE" ] && continue

    # Приводим к верхнему регистру
    CODE=$(echo "$CODE" | tr '[:lower:]' '[:upper:]')
    FLAG=$(get_flag "$CODE")
    COUNTRY_NAME=$(get_country_name "$CODE")

    # Если флаг не найден — пропускаем
    if [ -z "$FLAG" ]; then
      echo "stargate-area.sh: Unknown country code '$CODE', skipping"
      continue
    fi

    echo "stargate-area.sh: Generating groups for $CODE ($COUNTRY_NAME) $FLAG"

    # --------------------------------------------------------------------------
    # Генерируем AREA_GROUPS_LIST — список групп для proxy_list_all
    # --------------------------------------------------------------------------
    AREA_GROUPS_LIST="${AREA_GROUPS_LIST}  - ${CODE}_AUTO
  - ${CODE}_MANUAL
"

    # --------------------------------------------------------------------------
    # Генерируем AREA_SELECTOR_PROXIES — список для SELECTOR proxies
    # --------------------------------------------------------------------------
    AREA_SELECTOR_PROXIES="${AREA_SELECTOR_PROXIES}      - ${CODE}_AUTO
      - ${CODE}_MANUAL
"

    # Определяем фильтр в зависимости от SG_CODE
    # SG_CODE=false → только флаг: "(?i)🇺🇸"
    # SG_CODE=true  → флаг + код: "(?i)🇺🇸|US"
    if [ "$SG_CODE" = "true" ]; then
      FILTER_PATTERN="${FLAG}|${CODE}"
      FILTER_COMMENT="Только серверы ${COUNTRY_NAME} (флаг или код)"
    else
      FILTER_PATTERN="(?i)${FLAG}"
      FILTER_COMMENT="Только серверы ${COUNTRY_NAME} (флаг)"
    fi

    # --------------------------------------------------------------------------
    # Генерируем AREA_GROUPS_BLOCK — блоки proxy-groups для каждой страны
    # --------------------------------------------------------------------------

    # Формируем список прокси для AUTO в зависимости от настроек FASTEST и FAILOVER
    AUTO_PROXIES_LIST=""
    if [ "$SG_FASTEST" = "true" ]; then
      AUTO_PROXIES_LIST="${AUTO_PROXIES_LIST}
      - ${CODE}_FASTEST"
    fi
    if [ "$SG_FAILOVER" = "true" ]; then
      AUTO_PROXIES_LIST="${AUTO_PROXIES_LIST}
      - ${CODE}_FAILOVER"
    fi
    AUTO_PROXIES_LIST="${AUTO_PROXIES_LIST}
      - ${CODE}_MANUAL
      - AUTO"

    AREA_GROUPS_BLOCK="${AREA_GROUPS_BLOCK}
    # --------------------------------------------------------------------------
    # ${COUNTRY_NAME} ($CODE) ПРОКСИ-ГРУППЫ $FLAG
    # --------------------------------------------------------------------------
    # ${CODE}_AUTO — полностью автоматический выбор (${COUNTRY_NAME})
  - name: ${CODE}_AUTO
    type: fallback    # Переключение при отказе
    proxies:
      ${AUTO_PROXIES_LIST}
    <<: *health_check    # Параметры проверки
    # ${CODE}_MANUAL — ручной выбор прокси (${COUNTRY_NAME})
  - name: ${CODE}_MANUAL
    type: select    # Ручной выбор
    use: *providers_list    # Использовать провайдеры
    filter: \"${FILTER_PATTERN}\"    # ${FILTER_COMMENT}
"

    # Добавляем блок FASTEST, только если он включен
    if [ "$SG_FASTEST" = "true" ]; then
      AREA_GROUPS_BLOCK="${AREA_GROUPS_BLOCK}
    # ${CODE}_FASTEST — самый быстрый прокси (${COUNTRY_NAME})
  - name: ${CODE}_FASTEST
    type: url-test    # Тестирование скорости
    use: *providers_list    # Использовать провайдеры
    filter: \"${FILTER_PATTERN}\"    # ${FILTER_COMMENT}
    exclude-type: *exclude_wg    # WG отдельно в AWG
    <<: *url_test    # Параметры тестирования
"
    fi

    # Добавляем блок FAILOVER, только если он включен
    if [ "$SG_FAILOVER" = "true" ]; then
      AREA_GROUPS_BLOCK="${AREA_GROUPS_BLOCK}
    # ${CODE}_FAILOVER — резервный прокси (${COUNTRY_NAME})
  - name: ${CODE}_FAILOVER
    type: fallback    # Переключение при отказе
    use: *providers_list    # Использовать провайдеры
    filter: \"${FILTER_PATTERN}\"    # ${FILTER_COMMENT}
    exclude-type: *exclude_wg    # WG отдельно в AWG
    <<: *health_check    # Параметры проверки
"
    fi

  done </tmp/.area_countries.$$

  # Чистим временный файл
  rm -f /tmp/.area_countries.$$

  # Экспортируем переменные для использования в шаблоне
  export AREA_GROUPS_BLOCK
  export AREA_GROUPS_LIST
  export AREA_SELECTOR_PROXIES

  echo "stargate-area.sh: Area groups generated successfully"
fi
