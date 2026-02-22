#!/bin/sh

# Для миграции (совместимости) с предыдущих версий, если нужно изменить URL или ожидаемый статус, а их не указали в переменных окружения
HEALTH_CHECK_URL="${HEALTH_CHECK_URL:-https://www.gstatic.com/generate_204  }"
HEALTH_CHECK_EXPECTED_STATUS="${HEALTH_CHECK_EXPECTED_STATUS:-204 }"
PROVIDER_INTERVAL="${PROVIDER_INTERVAL:-3600 }" 

# Перепишем оригинальные переменные подписок для использования в stargate-chain.yaml
# на свои, чтобы не зависеть от оригинала, если там чтото поменялось внезапно
# что мы не отследили оперативно

PROVIDERS_BLOCK=""
PROVIDERS_LIST=""

# Функция для добавления подписки по HTTP (SUB1, SUB2 и т.д.), теперь с HWID
add_http_provider() {
    local name="$1"
    local url="$2"
      # HWID у нас всегда
    local header="
    header:
      x-hwid:
      - $HWID"
    PROVIDERS_BLOCK="${PROVIDERS_BLOCK}  ${name}:
    type: http
    url: \"${url}\"
    interval: ${PROVIDER_INTERVAL} 
    health-check:
      enable: true
      url: \"${HEALTH_CHECK_URL}\"
      interval: ${PROVIDER_INTERVAL}
      expected-status: ${HEALTH_CHECK_EXPECTED_STATUS}${header} 
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
    PROVIDERS_CHAIN_BLOCK="${PROVIDERS_CHAIN_BLOCK}  ${chain_name}:
    type: http
    url: \"${url}\"
    interval: ${PROVIDER_INTERVAL} 
    override:
      dialer-proxy: RU_AUTO           # Сначала идём через RU_AUTO
      exclude-filter: *exclude_ru     # Исключаем RU чтобы не ходить петлями
      exclude-type: wireguard         # Исключаем AWG/WARP — они не поддерживают цепочки
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
  esac
done << EOF
$(env)
EOF

# Восстановим оригинальные srv/awg, если они были сгенерированы ранее основным entrypoint.sh
if [ -f "$awg_file" ]; then
add_provider "AWG" "file" "$awg_file"
fi

if [ -f "$srv_file" ]; then
add_provider "SRV" "file" "$srv_file"
fi

# Экспортируем свои переменные для использования в stargate-chain.yaml, остальные переменные экспортируются внутри entrypoint.sh
export PROVIDERS_CHAIN_BLOCK
export PROVIDERS_CHAIN_LIST