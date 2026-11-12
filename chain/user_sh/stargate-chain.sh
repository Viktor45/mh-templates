#!/bin/sh

# ============================================================================
# STARGATE-CHAIN.SH
# Автоматические цепочки через российские серверы
# Источник: https://raw.githubusercontent.com/Viktor45/mh-templates/refs/heads/main/chain/stargate-chain.yaml
# Дополнение: https://raw.githubusercontent.com/Viktor45/mh-templates/refs/heads/main/chain/user_sh/stargate-chain.sh
# ============================================================================

# Запускается только если используется соответствующий конфиг, иначе пропускается
if [ "$CONFIG" = "stargate-chain.yaml" ]; then

# Для миграции (совместимости) с предыдущих версий, если нужно изменить URL или ожидаемый статус, а их не указали в переменных окружения
# Экспортируем, чтобы значения были видны через printenv в set_default_var
export HEALTH_CHECK_URL="${HEALTH_CHECK_URL:-https://www.gstatic.com/generate_204}"
export HEALTH_CHECK_EXPECTED_STATUS="${HEALTH_CHECK_EXPECTED_STATUS:-204}"
export PROVIDER_INTERVAL="${PROVIDER_INTERVAL:-3600}"

# Перепишем оригинальные переменные подписок на свои,
# чтобы не зависеть от внезапных изменений в entrypoint.sh

PROVIDERS_BLOCK=""
PROVIDERS_LIST=""

# Значение переменной с необязательным суффиксом _<имя_провайдера>
# Сначала ищем PROVIDER_<ПАРАМЕТР>_<ИМЯ>, затем общий PROVIDER_<ПАРАМЕТР>
set_default_var() {
    local name="$1"
    local var="$2"
    local value

    value="$(printenv "${var}_${name}")"
    [ -z "$value" ] && value="$(printenv "$var")"

    printf '%s' "$value"
}

# Блок health-check провайдера с возможностью точечного переопределения
build_health_check() {
    local name="$1"
    local health_check_enable="$(set_default_var "$name" "HEALTH_CHECK_ENABLE")"
    local health_check_url="$(set_default_var "$name" "HEALTH_CHECK_URL")"
    local health_check_interval="$(set_default_var "$name" "HEALTH_CHECK_INTERVAL")"
    local health_check_timeout="$(set_default_var "$name" "HEALTH_CHECK_TIMEOUT")"
    local health_check_lazy="$(set_default_var "$name" "HEALTH_CHECK_LAZY")"
    local health_check_expected_status="$(set_default_var "$name" "HEALTH_CHECK_EXPECTED_STATUS")"

    printf '%s' "    health-check:
      enable: ${health_check_enable}
      url: ${health_check_url}
      interval: ${health_check_interval}
      timeout: ${health_check_timeout}
      lazy: ${health_check_lazy}
      expected-status: ${health_check_expected_status}
"
}

# Кастомные HTTP-заголовки провайдера.
# PROVIDER_HEADER_<ИМЯ> или PROVIDER_HEADER - пары через = или :, разделены | или #
# Если пользователь передал свой x-hwid - системный HWID не добавляется
build_headers() {
    local name="$1"
    local headers_raw="$(set_default_var "$name" "PROVIDER_HEADER")"
    local custom_headers=""
    local h_key
    local h_val

    if [ -n "$headers_raw" ]; then
        headers_raw=$(printf '%s' "$headers_raw" | tr '#' '|')
        OLDIFS=$IFS; IFS='|'
        for pair in $headers_raw; do
            [ -z "$pair" ] && continue
            case "$pair" in
                *=*) h_key="${pair%%=*}"; h_val="${pair#*=}" ;;
                *:*) h_key="${pair%%:*}"; h_val="${pair#*:}" ;;
                *) continue ;;
            esac
            # Очищаем пробелы по краям (так что можно писать с пробелами вокруг |)
            h_key=$(printf '%s' "$h_key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            h_val=$(printf '%s' "$h_val" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//; s/"/\\"/g')
            [ -n "$h_key" ] && [ -n "$h_val" ] && custom_headers="${custom_headers}
      ${h_key}:
      - \"${h_val}\""
        done
        IFS=$OLDIFS
    fi

    local hwid_header=""
    if ! echo "$headers_raw" | grep -qi "x-hwid"; then
        hwid_header="
      x-hwid:
      - $HWID"
    fi

    printf '%s' "${hwid_header}${custom_headers}"
}

# Индивидуальные override-параметры провайдера.
# Только с суффиксом _<ИМЯ>: PROVIDER_UDP_<ИМЯ>, PROVIDER_TFO_<ИМЯ> и т.д.
build_override() {
    local name="$1"
    local override=""
    local value
    local param
    local var

    for param in tfo mptcp udp udp-over-tcp down up skip-cert-verify name-cert-verify dialer-proxy additional-prefix additional-suffix; do
        var="PROVIDER_$(printf '%s' "$param" | tr '[:lower:]-' '[:upper:]_')_${name}"
        value="$(printenv "$var")"
        [ -n "$value" ] || continue

        case "$param" in
            # boolean параметры без кавычек
            tfo|mptcp|udp|udp-over-tcp|skip-cert-verify)
                override="${override}"$'\n'"      ${param}: ${value}" ;;
            *)
                override="${override}"$'\n'"      ${param}: \"${value}\"" ;;
        esac
    done

    [ -n "$override" ] && printf '%s' "    override:${override}"
    return 0
}

# Функция для добавления подписки по HTTP (SUB1, SUB2 и т.д.), теперь с HWID
add_http_provider() {
    local name="$1"
    local url="$2"
    local filter="$(set_default_var "$name" "PROVIDER_FILTER")"
    local exclude_filter="$(set_default_var "$name" "PROVIDER_EXCLUDE_FILTER")"
    local exclude_type="$(set_default_var "$name" "PROVIDER_EXCLUDE_TYPE")"
    local provider_interval="$(set_default_var "$name" "PROVIDER_INTERVAL")"

    local sub_params="
    interval: ${provider_interval}
    header:$(build_headers "$name")"

    [ -n "$filter" ] && sub_params="${sub_params}"$'\n'"    filter: \"${filter}\""
    [ -n "$exclude_filter" ] && sub_params="${sub_params}"$'\n'"    exclude-filter: \"${exclude_filter}\""
    [ -n "$exclude_type" ] && sub_params="${sub_params}"$'\n'"    exclude-type: \"${exclude_type}\""

    local override="$(build_override "$name")"
    [ -n "$override" ] && sub_params="${sub_params}"$'\n'"${override}"

    PROVIDERS_BLOCK="${PROVIDERS_BLOCK}  ${name}:
    type: http
    url: \"${url}\"${sub_params}
$(build_health_check "$name")
"
    PROVIDERS_LIST="${PROVIDERS_LIST}      - ${name}
"
}

# Функция для создания "цепочек": иностранные серверы → через российский прокси
# Эти провайдеры автоматически перенаправляют трафик через RU_AUTO
# health-check у нас критичный для логики, поэтому его всегда используем
add_http_chain_provider() {
    local name="$1"
    local url="$2"
    local chain_name="${name}-via-ru"
    local provider_interval="$(set_default_var "$name" "PROVIDER_INTERVAL")"

    local sub_params="
    interval: ${provider_interval}
    header:$(build_headers "$name")"

    PROVIDERS_CHAIN_BLOCK="${PROVIDERS_CHAIN_BLOCK}  ${chain_name}:
    type: http
    url: \"${url}\"${sub_params}
    override:
      dialer-proxy: RU_AUTO           # Сначала идем через RU_AUTO
      exclude-filter: *exclude_ru     # Исключаем RU, чтобы не ходить петлями
      exclude-type: *exclude_wg       # WG исключен
$(build_health_check "$name")
"
    PROVIDERS_CHAIN_LIST="${PROVIDERS_CHAIN_LIST}      - ${chain_name}
"
}

# Это наши переменные блоков цепочек для шаблона stargate-chain.yaml
PROVIDERS_CHAIN_BLOCK=""
PROVIDERS_CHAIN_LIST=""

while IFS='=' read -r name value; do
  case "$name" in
    SUB[0-9]*)
        # Экранируем кавычки в URL, чтобы YAML не сломался
      value_clean=$(printf '%s' "$value" | sed 's/"/\\"/g')
        # Добавляем обычный провайдер
      add_http_provider "$name" "$value_clean"
        # Добавляем цепочку для этого же источника
      add_http_chain_provider "$name" "$value_clean"
      ;;
    SRV[0-9]*)
        # SRV с http(s)-ссылкой или deeplink-схемой (happ/v2raytun/incy) - это подписка,
        # как и SUB*, обрабатываем так же (паритет с entrypoint.sh, который
        # направляет такие SRV в HTTPVehicle и вызывает hpwnr)
      srv_scheme=$(printf '%s' "$value" | sed 's/:.*//' | tr '[:upper:]' '[:lower:]')
      case "$srv_scheme" in
        http|https|happ|v2raytun|incy)
            # Экранируем кавычки в URL, чтобы YAML не сломался
          value_clean=$(printf '%s' "$value" | sed 's/"/\\"/g')
          add_http_provider "$name" "$value_clean"
          add_http_chain_provider "$name" "$value_clean"
          ;;
      esac
      ;;
  esac
done << EOF
$(env)
EOF

# Восстановим оригинальный srv/awg/veth, если они были сгенерированы ранее основным entrypoint.sh
if [ -f "$awg_file" ]; then
add_provider "AWG" "file" "$awg_file"
fi

# -s, а не -f: entrypoint создает srv_file при любом SRV*, но подключает его
# только если там есть содержимое (http/deeplink-подписки туда не попадают)
if [ -s "$srv_file" ]; then
add_provider "SRV" "file" "$srv_file"
fi

if [ -f "$veth_file" ]; then
add_provider "VETH" "file" "$veth_file"
fi

# Экспортируем свои переменные для использования в stargate-chain.yaml, остальные переменные экспортируются внутри entrypoint.sh
export PROVIDERS_CHAIN_BLOCK
export PROVIDERS_CHAIN_LIST

fi
