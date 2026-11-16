<!-- TOC -->
- [Шаблоны конфигурации Mihomo для MikroTik](#шаблоны-конфигурации-mihomo-для-mikrotik)
  - [Быстрый старт](#быстрый-старт)
    - [1. Загрузите файл шаблона](#1-загрузите-файл-шаблона)
    - [2. Активируйте шаблон](#2-активируйте-шаблон)
    - [3. Перезапустите контейнер](#3-перезапустите-контейнер)
    - [Обновление шаблона до новой версии](#обновление-шаблона-до-новой-версии)
    - [Диагностика проблем](#диагностика-проблем)
  - [Выбор подходящего шаблона](#выбор-подходящего-шаблона)
  - [Описание шаблонов](#описание-шаблонов)
    - [Сравнение функциональности шаблонов](#сравнение-функциональности-шаблонов)
    - [Облегченный (Lite)](#облегченный-lite)
    - [Полный (Stargate)](#полный-stargate)
    - [Минимум (Mini)](#минимум-mini)
    - [Крохотный (Nano)](#крохотный-nano)
    - [Страны (Area)](#страны-area)
    - [Цепочки (Chain)](#цепочки-chain)
  - [Управление маршрутизацией: переключатели](#управление-маршрутизацией-переключатели)
    - [Переменные шаблонов](#переменные-шаблонов)
    - [Ручные переключатели](#ручные-переключатели)
    - [Автоматические переключатели](#автоматические-переключатели)
    - [Сломалась автоматика?](#сломалась-автоматика)
    - [Технические параметры](#технические-параметры)
  - [Оптимизация подписок](#оптимизация-подписок)
    - [Очистка подписок](#очистка-подписок)
    - [Количество подписок](#количество-подписок)
    - [Кодировка](#кодировка)
    - [Ограничения памяти](#ограничения-памяти)
  - [Дополнительная справка](#дополнительная-справка)
<!-- TOC -->


# Шаблоны конфигурации Mihomo для MikroTik

Готовые шаблоны конфигураций для контейнера [Mihomo на маршрутизаторах MikroTik](https://hub.docker.com/r/wiktorbgu/mihomo-mikrotik).

Это шаблоны, а не готовые конфигурации: внутри много комментариев, переменных `$VAR` и настроек, которые могут вам не понадобиться. Правьте под себя и присылайте PR, если придумали улучшение. Лицензия [MIT](LICENSE).

## Быстрый старт

### 1. Загрузите файл шаблона

Выберите подходящий шаблон в таблице «Выбор подходящего шаблона» и скопируйте его на роутер через **SFTP** в папку:

```
/usb1/docker_configs/mihomo_mikrotik/template/
```

Шаблоны Area и Chain состоят из двух файлов: .sh-скрипт кладите в папку **user_sh**:

```
/usb1/docker_configs/mihomo_mikrotik/user_sh/
```

Пути могут отличаться, если контейнер расположен в другом хранилище.

<details>
<summary><b>Альтернатива без SFTP - скачать прямо на роутере через /tool fetch</b></summary>

Вместо SFTP файл можно скачать на роутер прямо из интернета командой `/tool fetch` (в терминале RouterOS). Параметр `dst-path` задает путь сохранения - укажите его **полностью, вместе с именем файла**:

```bash
# Шаблон Lite
/tool fetch url="https://raw.githubusercontent.com/Viktor45/mh-templates/refs/heads/main/stargate-lite.yaml" dst-path="/usb1/docker_configs/mihomo_mikrotik/template/stargate-lite.yaml"

# Шаблон Area (два файла)
/tool fetch url="https://raw.githubusercontent.com/Viktor45/mh-templates/refs/heads/main/area/stargate-area.yaml" dst-path="/usb1/docker_configs/mihomo_mikrotik/template/stargate-area.yaml"
/tool fetch url="https://raw.githubusercontent.com/Viktor45/mh-templates/refs/heads/main/area/user_sh/stargate-area.sh" dst-path="/usb1/docker_configs/mihomo_mikrotik/user_sh/stargate-area.sh"

# Шаблон Chain (два файла)
/tool fetch url="https://raw.githubusercontent.com/Viktor45/mh-templates/refs/heads/main/chain/stargate-chain.yaml" dst-path="/usb1/docker_configs/mihomo_mikrotik/template/stargate-chain.yaml"
/tool fetch url="https://raw.githubusercontent.com/Viktor45/mh-templates/refs/heads/main/chain/user_sh/stargate-chain.sh" dst-path="/usb1/docker_configs/mihomo_mikrotik/user_sh/stargate-chain.sh"
```

Остальные шаблоны качаются той же командой - ссылки в колонке «Скачать» таблицы.

</details>

### 2. Активируйте шаблон

Укажите имя шаблона в переменной `CONFIG` списка `MIHOMO`:

```bash
/container envs add list=MIHOMO key=CONFIG value="stargate-lite.yaml"
```

**Важно:** `envs add` создает **новую** переменную. Если `CONFIG` в списке `MIHOMO` уже существует (например, при смене шаблона или списка стран), сначала удалите старое значение и затем добавьте новое:

```bash
# Посмотреть существующие переменные
/container envs print

# Удалить старое значение CONFIG (номер из print)
/container envs remove numbers=0

# Добавить новое
/container envs add list=MIHOMO key=CONFIG value="новое-значение"
```

Либо отредактируйте значение переменной в Winbox: **Container → EnvLists → MIHOMO**.

### 3. Перезапустите контейнер

Перезапуск нужен для применения шаблона и любых переменных окружения.

```bash
/container stop mihomo_mikrotik
/container start mihomo_mikrotik
```

Имя контейнера (`mihomo_mikrotik`) может отличаться, если вы меняли настройки по умолчанию.

### Обновление шаблона до новой версии

1. **Перенесите свои правки в новый файл заранее** - при перезаписи файла они будут потеряны. Выбранные вручную прокси в панелях при этом сохраняются: они лежат в кеше Mihomo отдельно от шаблона (при включенном `STORE_SELECTED`).
2. Скачайте новый файл тем же способом (SFTP с заменой или `/tool fetch` с тем же `dst-path` - старый файл будет перезаписан).
3. Перезапустите контейнер:
   ```bash
   /container stop mihomo_mikrotik
   /container start mihomo_mikrotik
   ```

После запуска проверьте, что все группы появились в панели. Значения новых переменных окружения берутся из списка `MIHOMO` (см. таблицы ниже).

### Диагностика проблем

1. **Включите логирование контейнера**, чтобы вывод mihomo попадал в журнал RouterOS:
   ```bash
   /container set [find name="mihomo_mikrotik"] logging=yes
   ```
   Лог смотрите через `/log print` (или Winbox → Log).
2. **Проверьте, что CONFIG указывает на существующий файл.** При опечатке в имени в логе будет `ERROR: Config not found! Checked: ...template/имя.yaml and .../имя.yaml` - проверьте имя переменной и что файл лежит в папке `template`.
3. **Проверьте, что .sh-скрипт лежит в user_sh.** Шаблоны Area и Chain без своего скрипта не сгенерируют группы по странам/цепочки: в панели не появятся `XX_*`/`VIA_RU_*` переключатели.
4. **Ошибка парсинга шаблона** - mihomo пишет отладочный файл рядом с рабочей директорией контейнера (см. [документацию контейнера](https://hub.docker.com/r/wiktorbgu/mihomo-mikrotik)); сам файл лога удобно посмотреть через SFTP.
5. **Переменные подставляются только при старте.** После изменения любой переменной (`SG_COUNTRIES`, `SUB1`, ...) нужен перезапуск контейнера - одного обновления подписок недостаточно.
6. Распространенная причина «не работает» - BOM-кодировка файла после редактирования: сохраняйте шаблон в **UTF-8 без BOM** (см. раздел «Кодировка»).

## Выбор подходящего шаблона

| Шаблон            | Файлы                                                                                                                                                                                                                               | Скачать                                                                                                                                                                                                                             | Память            | Сложность                       | Для кого                               |
| ----------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :---------------: | :------------------------------ | :------------------------------------- |
| **Lite**          | [stargate-lite.yaml](stargate-lite.yaml)                                                                                                                                                                                            | [💾](https://raw.githubusercontent.com/Viktor45/mh-templates/refs/heads/main/stargate-lite.yaml)                                                                                                                                     | ~20 МБ            | ⭐ Низкая                        | Базовый сценарий, новички              |
| **Full**          | [stargate.yaml](stargate.yaml)                                                                                                                                                                                                      | [💾](https://raw.githubusercontent.com/Viktor45/mh-templates/refs/heads/main/stargate.yaml)                                                                                                                                          | ~40 МБ            | ⭐⭐ Средняя                      | Тонкая настройка маршрутизации         |
| **Mini**          | [stargate-mini.yaml](stargate-mini.yaml)                                                                                                                                                                                            | [💾](https://raw.githubusercontent.com/Viktor45/mh-templates/refs/heads/main/stargate-mini.yaml)                                                                                                                                     | ~15 МБ            | ⭐ Низкая                        | Только основные сервисы                |
| **Nano**          | [stargate-nano.yaml](stargate-nano.yaml)                                                                                                                                                                                            | [💾](https://raw.githubusercontent.com/Viktor45/mh-templates/refs/heads/main/stargate-nano.yaml)                                                                                                                                     | ~12 МБ            | ⭐ Низкая                        | Без сервисных групп                    |
| **Area**          | [stargate-area.yaml](area/stargate-area.yaml) + [stargate-area.sh](area/user_sh/stargate-area.sh)                                                                                                                                   | [💾](https://raw.githubusercontent.com/Viktor45/mh-templates/refs/heads/main/area/stargate-area.yaml) [💾](https://raw.githubusercontent.com/Viktor45/mh-templates/refs/heads/main/area/user_sh/stargate-area.sh)                     | ~25-50 МБ         | ⭐⭐⭐ Высокая                     | Переключатели по странам               |
| **Chain**         | [stargate-chain.yaml](chain/stargate-chain.yaml) + [stargate-chain.sh](chain/user_sh/stargate-chain.sh)                                                                                                                             | [💾](https://raw.githubusercontent.com/Viktor45/mh-templates/refs/heads/main/chain/stargate-chain.yaml) [💾](https://raw.githubusercontent.com/Viktor45/mh-templates/refs/heads/main/chain/user_sh/stargate-chain.sh)                 | ~50-90 МБ         | ⭐⭐⭐ Высокая                     | Цепочки через RU-сервер                |

## Описание шаблонов

Шаблоны можно использовать сразу, но в них есть избыточный код, который может не потребоваться. Правьте их согласно [официальному примеру](https://github.com/MetaCubeX/mihomo/blob/Meta/docs/config.yaml) и [документации](https://wiki.metacubex.one/ru/config/general/). Учтите, что это файлы ШАБЛОНОВ конфигурации, а не сами конфигурации: они содержат переменные со знаком `$` и могут не поддерживаться вашим YAML-редактором.

### Сравнение функциональности шаблонов

| Функция                                                                                 | Stargate             | Lite               | Mini               | Nano               | Area                  | Chain                 |
| --------------------------------------------------------------------------------------- | :------------------- | :----------------: | :----------------: | :----------------: | :-------------------: | :-------------------: |
| **ZKEEN геоданные** (GEOIP/GEOSITE)                                                     | ✅                    | ❌                  | ❌                  | ❌                  | ❌                     | ❌                     |
| **Автообновление геоданных**                                                            | ✅                    | ❌                  | ❌                  | ❌                  | ❌                     | ❌                     |
| **CDN провайдеры** (Fastly, Akamai, CDN77)                                              | ✅                    | ❌                  | ❌                  | ❌                  | ❌                     | ❌                     |
| **Облачные хостинги** (Amazon, Oracle, Hetzner, OVH, Vultr, DigitalOcean, MEGA)         | ✅                    | ❌                  | ❌                  | ❌                  | ❌                     | ❌                     |
| **AI сервисы** (OpenAI, Gemini, Anthropic, Perplexity, Microsoft Copilot)               | ✅                    | ✅                  | ❌                  | ❌                  | ✅                     | ✅                     |
| **Мессенджеры** (Telegram, WhatsApp)                                                    | ✅                    | ✅                  | ✅                  | ❌                  | ✅                     | ✅                     |
| **Стриминг** (YouTube, Twitch)                                                          | ✅                    | ✅                  | ✅                  | ❌                  | ✅                     | ✅                     |
| **Игры** (Steam, Discord)                                                               | ✅                    | ✅                  | ❌                  | ❌                  | ✅                     | ✅                     |
| **Torrent правила**                                                                     | ✅                    | ❌                  | ❌                  | ❌                  | ❌                     | ❌                     |
| **ECH-Refilter** (ускорение интернета)                                                  | ✅                    | ❌                  | ❌                  | ❌                  | ❌                     | ❌                     |
| **Ru-Traffic** (GEOIP России)                                                           | ✅                    | ❌                  | ❌                  | ❌                  | ❌                     | ❌                     |
| **META** (Facebook, Instagram)                                                          | ✅                    | ❌                  | ❌                  | ❌                  | ❌                     | ❌                     |
| **IPv6 поддержка**                                                                      | ✅                    | ✅                  | ✅                  | ✅                  | ✅                     | ✅                     |
| **Sniffer** (анализ трафика)                                                            | ✅                    | ✅                  | ✅                  | ❌                  | ✅                     | ✅                     |
| **AWG группы** (WireGuard/AmneziaWG)                                                    | ✅                    | ✅                  | ✅                  | ❌                  | ✅                     | ✅                     |
| **RU группы** (российские прокси)                                                       | ✅                    | ✅                  | ✅                  | ❌                  | ✅                     | ✅                     |
| **Группы по странам** (динамические)                                                    | ❌                    | ❌                  | ❌                  | ❌                  | ✅                     | ❌                     |
| **Требуется companion .sh** (два файла)                                                 | ❌                    | ❌                  | ❌                  | ❌                  | ✅                     | ✅                     |
| **Двойная маршрутизация** (цепочки через RU)                                            | ❌                    | ❌                  | ❌                  | ❌                  | ❌                     | ✅                     |
| **VIA_RU группы** (автоматические цепочки)                                              | ❌                    | ❌                  | ❌                  | ❌                  | ❌                     | ✅                     |
| **dialer-proxy override** (переопределение маршрута)                                    | ❌                    | ❌                  | ❌                  | ❌                  | ❌                     | ✅                     |
| **Исключение WireGuard из цепочек**                                                     | ❌                    | ❌                  | ❌                  | ❌                  | ❌                     | ✅                     |
| **Удвоение провайдеров** (оригинал + цепочка)                                           | ❌                    | ❌                  | ❌                  | ❌                  | ❌                     | ✅                     |

---

### Облегченный (Lite)

Файл шаблона: [stargate-lite.yaml](stargate-lite.yaml)

Базовый сценарий для большинства домашних сетей: сервисные переключатели и AI-правила без геоданных и разбиения по хостингам.

- Потребление памяти ~20 МБ - работает даже на старых маршрутизаторах
- Переключатели YouTube, Telegram, Discord, WhatsApp и AI-сервисов
- IPv6 и Sniffer (анализ трафика)
- AWG-группы для WireGuard/AmneziaWG и RU-группы для российских прокси

Берите Lite, если у вас обычный современный роутер. Нужны правила для CDN, облачных хостингов, GEOIP-маршрутизация по странам или торренты - берите Full. Памяти мало - Mini или Nano.

---

### Полный (Stargate)

Файл шаблона: [stargate.yaml](stargate.yaml)

Расширенный набор переключателей, GEOIP/GEOSITE-правила и настраиваемая автоматика.

- **ZKEEN геоданные** - автоматическая загрузка актуальных списков IP и доменов по странам (обновление каждые 24 часа)
- Отдельные группы для CDN (Fastly, Akamai, CDN77) и облачных хостингов (Amazon, Google, Cloudflare, DigitalOcean, Hetzner, MEGA, Oracle, OVH, Vultr)
- GEOIP-правила для соцсетей, мессенджеров, игр и стриминга
- AI-сервисы: OpenAI, Google Gemini, Anthropic Claude, Perplexity, Microsoft Copilot
- Torrent-правила для торрент-клиентов и трекеров
- ECH-Refilter, META и Ru-Traffic - отдельная группа для российского трафика по GEOIP
- Потребление памяти ~40 МБ

Совет: начните с Lite и переходите на Full, когда понадобится тонкая настройка.

---

### Минимум (Mini)

Файл шаблона: [stargate-mini.yaml](stargate-mini.yaml)

Минимальная настройка на очень ограниченном оборудовании **с сервисами**.

- Потребление памяти ~15 МБ
- Только самое важное: YouTube, Telegram, WhatsApp, Cloudflare
- Минимум переключателей - меньше путаницы
- IPv6 и Sniffer (анализ трафика)
- AWG- и RU-группы

Без AI-сервисов, игровых правил и GEOIP/ZKEEN геоданных. На обычном современном роутере лучше Lite.

---

### Крохотный (Nano)

Файл шаблона: [stargate-nano.yaml](stargate-nano.yaml)

Минимальная настройка на очень ограниченном оборудовании **без сервисов**.

- Потребление памяти ~12 МБ
- Только базовые группы: SELECTOR, AUTO, FASTEST, FAILOVER, LOADBALANCE, MANUAL, GLOBAL
- IPv6 (управляется переменной `IPV6`)

Без сервисных групп, AI-сервисов, геоданных, Sniffer, AWG/RU-групп и внешних наборов правил. На обычном современном роутере лучше Lite.

---

### Страны (Area)

Файлы шаблона: [stargate-area.yaml](area/stargate-area.yaml) + [stargate-area.sh](area/user_sh/stargate-area.sh)

Динамические переключатели по странам - аналог RU_* групп, но для любой страны из списка. Набор сервисных групп такой же, как у Lite.

**Как это работает**

Переменная `SG_COUNTRIES` задает список стран, скрипт создает для каждой до 5 групп:

- `XX_AUTO` - автоматический выбор (FASTEST → FAILOVER → AUTO)
- `XX_MANUAL` - ручной выбор прокси страны
- `XX_FASTEST` - самый быстрый прокси страны (url-test)
- `XX_FAILOVER` - резервный прокси страны (fallback)
- `XX_LOADBALANCE` - распределение нагрузки (loadbalance)

```bash
/container envs add list=MIHOMO key=SG_COUNTRIES value="US,NL,DE,GB,FR,JP,SG"
```

Коды стран разделяются запятыми, пробелы не важны. Страна RU (🇷🇺) присутствует всегда. Созданные группы скрипт добавляет в главный SELECTOR.

**Режим фильтрации прокси (SG_CODE)**

По умолчанию скрипт фильтрует прокси **только по флагу** страны (🇺🇸, 🇩🇪). Если в названиях ваших прокси флагов нет, но есть коды стран (US, DE, NL), установите `SG_CODE="true"` - тогда фильтр ищет по флагу **и** коду:

| Значение `SG_CODE`     | Фильтр для US | Когда использовать                                              |
| :--------------------- | :------------ | :-------------------------------------------------------------- |
| `false` (по умолчанию) | `(?i)🇺🇸`       | Прокси содержат флаг эмодзи в названии: `🇺🇸 US Server 1`         |
| `true`                 | `(?i)🇺🇸\|US`   | Прокси содержат и флаг, и код: ищет совпадение по любому из них |

```bash
/container envs add list=MIHOMO key=SG_CODE value="true"
```

**Состав групп по стране**

`SG_FASTEST`, `SG_FAILOVER` и `SG_LOADBALANCE` включают или выключают соответствующие группы для всех стран (по умолчанию включены) - это экономит память и ресурсы:

| Переменная       | Значение | Результат                          |
| :--------------- | :------- | :--------------------------------- |
| `SG_FASTEST`     | `true`   | Поиск быстрого - включен           |
| `SG_FASTEST`     | `false`  | Поиск быстрого - выключен          |
| `SG_FAILOVER`    | `true`   | Поиск доступного - включен         |
| `SG_FAILOVER`    | `false`  | Поиск доступного - выключен        |
| `SG_LOADBALANCE` | `true`   | Распределение нагрузки - включено  |
| `SG_LOADBALANCE` | `false`  | Распределение нагрузки - выключено |

```bash
# Выключить поиск быстрого по каждой стране
/container envs add list=MIHOMO key=SG_FASTEST value="false"

# Выключить поиск доступного по каждой стране
/container envs add list=MIHOMO key=SG_FAILOVER value="false"

# Выключить распределение нагрузки по каждой стране
/container envs add list=MIHOMO key=SG_LOADBALANCE value="false"
```

**Поддерживаемые страны (24 страны):**

|  Код  | Страна    | Флаг  |     |  Код  | Страна         | Флаг  |
| :---: | :-------- | :---: | --- | :---: | :------------- | :---: |
| `US`  | США       |   🇺🇸   |     | `NL`  | Нидерланды     |   🇳🇱   |
| `DE`  | Германия  |   🇩🇪   |     | `GB`  | Великобритания |   🇬🇧   |
| `FR`  | Франция   |   🇫🇷   |     | `JP`  | Япония         |   🇯🇵   |
| `SG`  | Сингапур  |   🇸🇬   |     | `CA`  | Канада         |   🇨🇦   |
| `AU`  | Австралия |   🇦🇺   |     | `KR`  | Южная Корея    |   🇰🇷   |
| `IN`  | Индия     |   🇮🇳   |     | `BR`  | Бразилия       |   🇧🇷   |
| `IT`  | Италия    |   🇮🇹   |     | `ES`  | Испания        |   🇪🇸   |
| `PL`  | Польша    |   🇵🇱   |     | `SE`  | Швеция         |   🇸🇪   |
| `FI`  | Финляндия |   🇫🇮   |     | `NO`  | Норвегия       |   🇳🇴   |
| `CH`  | Швейцария |   🇨🇭   |     | `CZ`  | Чехия          |   🇨🇿   |
| `UA`  | Украина   |   🇺🇦   |     | `TR`  | Турция         |   🇹🇷   |
| `IL`  | Израиль   |   🇮🇱   |     | `AE`  | ОАЭ            |   🇦🇪   |

**Примеры списка стран**

| Задача                            | Значение `SG_COUNTRIES`                                     |
| --------------------------------- | :---------------------------------------------------------- |
| Только США и Нидерланды           | `US,NL`                                                     |
| Все популярные (15 стран)         | `US,NL,DE,GB,FR,JP,SG,CA,AU,KR,IN,BR,IT,ES,PL`              |
| Европейские                       | `DE,NL,FR,GB,IT,ES,PL,SE,FI,NO,CH,CZ`                       |
| Азиатские                         | `JP,SG,KR,IN`                                               |

**Установка шаблона Area**

1. Загрузите оба файла на роутер: [stargate-area.yaml](area/stargate-area.yaml) → `template/`, [stargate-area.sh](area/user_sh/stargate-area.sh) → `user_sh/`.
2. Задайте список стран и, при необходимости, режим фильтрации:
   ```bash
   /container envs add list=MIHOMO key=SG_COUNTRIES value="US,NL,DE,GB,FR,JP,SG"
   /container envs add list=MIHOMO key=SG_CODE value="true"
   ```
3. Установите CONFIG на шаблон:
   ```bash
   /container envs add list=MIHOMO key=CONFIG value="stargate-area.yaml"
   ```
4. Перезапустите контейнер.

**Важно знать**

- Нужны **два файла**: без скрипта группы по странам не появятся.
- В названиях прокси должен быть флаг или код страны - иначе прокси не попадут в соответствующую группу.
- Каждая страна добавляет до 5 групп: 15 стран - это ~75 дополнительных групп и заметный расход памяти (~25-50 МБ).
- Геоданных, CDN и облачных хостингов здесь нет - набор сервисных групп такой же, как у Lite.

**Когда использовать**

- Хотите выбирать прокси по странам (работа, стриминг, игры - разные страны)
- Нужен быстрый доступ к серверам конкретной страны
- Нужен аналог RU_* групп для других стран

Не подойдет, если достаточно одного SELECTOR (берите Lite), нужны цепочки через RU (берите Chain) или роутер очень ограниченный (Mini или Nano).

---

### Цепочки (Chain)

Файлы шаблона: [stargate-chain.yaml](chain/stargate-chain.yaml) + [stargate-chain.sh](chain/user_sh/stargate-chain.sh)

Трафик идет сначала через RU-сервер, потом в нужную страну. Полезно, если у вас белые списки или нужна иная логика маршрутизации.

```
Ваш компьютер
     ↓
  Русский прокси #1
     ↓
  Иностранный прокси #2
     ↓
Целевой сервер
```

**Что делает скрипт**

- Создает дубликаты всех подписок с суффиксом `-via-ru`
- Настраивает `dialer-proxy: RU_AUTO` для маршрутизации через российские серверы
- Исключает российские прокси из цепочек (`exclude-filter: *exclude_ru`) - иначе получаются петли
- Исключает WireGuard из цепочек (`exclude-type: wireguard`) - они не поддерживают двойную маршрутизацию
- Сохраняет поддержку AWG, SRV и VETH-провайдеров и точечных настроек (`PROVIDER_FILTER`, `PROVIDER_HEADER`, `PROVIDER_UDP_<NAME>`) из основного entrypoint.sh
- Создает группы `VIA_RU_AUTO`, `VIA_RU_FASTEST` и `VIA_RU_FAILOVER` для автоматической маршрутизации через РФ

**Установка шаблона Chain**

1. Загрузите оба файла на роутер: [stargate-chain.yaml](chain/stargate-chain.yaml) → `template/`, [stargate-chain.sh](chain/user_sh/stargate-chain.sh) → `user_sh/`.
2. Установите CONFIG на шаблон:
   ```bash
   /container envs add list=MIHOMO key=CONFIG value="stargate-chain.yaml"
   ```
3. Перезапустите контейнер.
4. **Обязательно включите "Auto disconnect idle UDP"** в zashboard или подобной панели, чтобы неактивные или подвисшие соединения при переключении цепочки закрывались (например, каждые 10 минут).

**Важно знать**

- Нужны **два файла** и несколько живых RU-прокси в подписках.
- Работает только с подписками (`SUB1`, `SUB2` и т.д., включая `SRV*`-ссылки на подписки) - без них цепочки не соберутся.
- Пинг выше, чем с одним прокси: онлайн-игры могут быть медленнее.
- Количество провайдеров удваивается (оригинал + цепочка), память ~50-90 МБ.

---

## Управление маршрутизацией: переключатели

Переключатели - это группы прокси в панели: они решают, через какой прокси пойдет трафик того или иного сервиса. Одни настраиваются вручную, другие работают автоматически.

### Переменные шаблонов

Шаблоны используют переменные окружения, которые подставляются при запуске контейнера. В шаблонах могут использоваться не все переменные ниже.

**Основные переменные:**

| Переменная                        | Описание                                                      | Пример значения                                               |
| :-------------------------------- | :------------------------------------------------------------ | :------------------------------------------------------------ |
| `CONFIG`                          | Имя загруженного шаблона                                      | `stargate-lite.yaml`, `stargate.yaml`                         |
| `LOG_LEVEL`                       | Уровень логирования                                           | `info`, `debug`, `warning`, `error`, `silent`                 |
| `IPV6`                            | Включение поддержки IPv6                                      | `true` / `false`                                              |
| `IPTABLES`                        | Принудительно использовать iptables вместо nftables на Alpine | `0` / `1`                                                     |
| `FIND_PROCESS_MODE`               | Режим поиска процесса для правил Mihomo                       | `always`, `strict`, `off`                                     |
| `UNIFIED_DELAY`                   | Более естественное тестирование прокси по задержке            | `true` / `false`                                              |
| `TCP_CONCURRENT`                  | Количество параллельных TCP-соединений для одного прокси      | `1`, `2`, `3`                                                 |
| `KEEP_ALIVE_IDLE`                 | Время простоя TCP до первого keepalive                        | `60`, `120`                                                   |
| `KEEP_ALIVE_INTERVAL`             | Интервал TCP keepalive                                        | `20`, `30`                                                    |
| `STORE_SELECTED`                  | Сохранять выбор групп в веб-интерфейсе                        | `true` / `false`                                              |
| `EXTERNAL_CONTROLLER_ADDRESS`     | Адрес API контроллера                                         | `0.0.0.0`, `127.0.0.1`                                        |
| `UI_PORT`                         | Порт веб-интерфейса                                           | `9090`                                                        |
| `EXTERNAL_UI_PATH`                | Путь к UI файлам                                              | `ui`, `metacubexd`                                            |
| `EXTERNAL_UI_URL`                 | URL для загрузки UI                                           | `https://github.com/...`                                      |
| `UI_SECRET`                       | Секрет API                                                    | произвольная строка                                           |
| `DNS_ENABLE`                      | Включить встроенный DNS-резолвер                              | `true` / `false`                                              |
| `DNS_USE_SYSTEM_HOSTS`            | Использовать системный /etc/hosts                             | `true` / `false`                                              |
| `DNS_LISTEN`                      | Адрес/порт для DNS-слушателя                                  | `53`, `0.0.0.0:53`                                            |
| `DNS_CACHE_ALGORITHM`             | Алгоритм кеширования DNS-запросов                             | `arc`, `lru`, `random`, `fifo`                                |
| `DNS_PREFER_H3`                   | Предпочитать HTTP/3 для DNS-over-HTTPS                        | `true` / `false`                                              |
| `DNS_RESPECT_RULES`               | Резолвить DNS-запросы по правилам маршрутизации               | `true` / `false`                                              |
| `DNS_FAKE_IP_FILTER_MODE`         | Режим списка fake-ip-filter: `blacklist` или `whitelist`      | `blacklist`, `whitelist`                                      |
| `DNS_FAKE_IP_FILTER`              | Список доменов для fake-ip-filter через `\|`                  | `+.lan\|+.local\|+.ntp.org`                                  |
| `DNS_NAMESERVER`                  | Основные DNS-серверы через `\|`                               | `system`, `8.8.8.8\|1.1.1.1`                                 |
| `DNS_DEFAULT_NAMESERVER`          | DNS для резолва адресов из nameserver (bootstrap) через `\|`  | `system`, `8.8.8.8`                                          |
| `DNS_PROXY_SERVER_NAMESERVER`     | DNS для резолва имен прокси-серверов через `\|`               | `system`, `8.8.8.8`                                          |
| `DNS`, `DNS_BOOTSTRAP`            | Базовые значения: сразу задают `DNS_NAMESERVER`, `DNS_PROXY_SERVER_NAMESERVER` и `DNS_DEFAULT_NAMESERVER` | `system`, `udp://8.8.8.8` |
| `DNS_ENHANCED_MODE`               | Включить расширенный режим DNS                                | `true` / `false`                                              |
| `DNS_FAKE_IP_RANGE`               | Диапазон подставных IP для fake-ip                            | `198.18.0.1/16`                                               |
| `DNS_FAKE_IP_TTL`                 | Время жизни подставного fake-ip в секундах                    | `600`, `3600`                                                 |
| `GATEWAY_<IP>`, `GATEWAY_<IFACE>` | Переопределение шлюза для VETH-интерфейсов                    | `GATEWAY_192_168_1_2=192.168.1.1`, `GATEWAY_eth1=192.168.1.1` |
| `MIXED_PORT`                      | Порт mixed-прокси для приложений                              | `1080`                                                        |
| `LOADBALANCE_STRATEGY`            | Стратегия распределения нагрузки                              | `round-robin`, `consistent-hashing`, `sticky-sessions`        |
| `TOLERANCE`                       | Допуск по задержке для провайдеров                            | `0`, `50`, `100`                                              |

**Про DNS-списки:** переменные `DNS_NAMESERVER`, `DNS_DEFAULT_NAMESERVER`, `DNS_PROXY_SERVER_NAMESERVER` и `DNS_FAKE_IP_FILTER` задаются списком через `|` - entrypoint превращает его в YAML-список. Значение `system` означает системный DNS роутера. Переменные `DNS` и `DNS_BOOTSTRAP` - базовые значения: `DNS` сразу задает основные серверы, `DNS_BOOTSTRAP` - bootstrap. Эти переменные поддерживаются контейнером начиная с версии от ноября 2026 - обновите образ, прежде чем их задавать.

```bash
# Все DNS-запросы через публичные серверы
/container envs add list=MIHOMO key=DNS value="udp://8.8.8.8|udp://1.1.1.1"

# Или точечно, только для основного резолвера
/container envs add list=MIHOMO key=DNS_NAMESERVER value="system|udp://8.8.8.8"
```

В шаблонах Stargate список `fake-ip-filter` (исключение lan/captive/time/stun из fake-ip) зафиксирован в самом шаблоне и переменной `DNS_FAKE_IP_FILTER` не переопределяется - она действует в стандартном `default_config.yaml` из образа. Режим списка управляется переменной `DNS_FAKE_IP_FILTER_MODE` и в шаблонах работает.

**Переменные подписок:**

| Переменная                     | Описание                                          | Значения по умолчанию                  |
| :----------------------------- | :------------------------------------------------ | :------------------------------------- |
| `SUB1`, `SUB2`, ...            | URL подписок на прокси-серверы                    |                                        |
| `SRV0`, `SRV1`, ...            | Локальные серверы в формате YAML или URI (`vless://`, `ss://` и т.д.). Если значение - http(s)-ссылка или deeplink-подписка (`happ://`, `v2raytun://`, `incy://`), оно принимается за подписку: контейнер скачает ее сам через встроенный `hpwnr` | |
| `HEALTH_CHECK_ENABLE`          | Включить проверку здоровья прокси                 | `true` / `false`                       |
| `HEALTH_CHECK_URL`             | URL для проверки прокси                           | `https://www.gstatic.com/generate_204` |
| `HEALTH_CHECK_EXPECTED_STATUS` | Ожидаемый HTTP статус                             | `204`                                  |
| `HEALTH_CHECK_INTERVAL`        | Интервал проверки здоровья (сек)                  | `300`                                  |
| `HEALTH_CHECK_TIMEOUT`         | Таймаут ожидания ответа (мс)                      | `5000`                                 |
| `HEALTH_CHECK_LAZY`            | Отложенная проверка прокси                        | `true` / `false`                       |
| `PROVIDER_INTERVAL`            | Интервал обновления подписок (сек)                | `3600`                                 |

**Точечные настройки провайдеров:**

Все переменные ниже применяются сразу ко всем подпискам. Чтобы задать значение только для одной подписки, добавьте суффикс с ее именем через подчеркивание - например, `PROVIDER_FILTER_SUB1`.

| Переменная                                    | Описание                                                          | Пример значения             |
| :-------------------------------------------- | :---------------------------------------------------------------- | :-------------------------- |
| `PROVIDER_FILTER`                             | Регулярное выражение для отбора имен серверов в подписке          | `(?i)🇺🇸\|US`               |
| `PROVIDER_EXCLUDE_FILTER`                     | Регулярное выражение для исключения имен серверов из подписки     | `(?i)expire\|test`         |
| `PROVIDER_EXCLUDE_TYPE`                       | Исключение протоколов серверов через `\|`                         | `wireguard\|direct`        |
| `PROVIDER_HEADER`                             | Дополнительные HTTP-заголовки для запроса подписки                 | `X-Custom:value`            |
| `PROVIDER_TFO`                                | TCP Fast Open (только с суффиксом подписки)                       | `true` / `false`            |
| `PROVIDER_MPTCP`                              | MultiPath TCP (только с суффиксом подписки)                       | `true` / `false`            |
| `PROVIDER_UDP`                                | Разрешить UDP (только с суффиксом подписки)                       | `true` / `false`            |
| `PROVIDER_UDP_OVER_TCP`                       | Передавать UDP через TCP (только с суффиксом подписки)            | `true` / `false`            |
| `PROVIDER_DOWN`                               | Ограничение скорости скачивания, КБ/с (только с суффиксом)        | `10000`                     |
| `PROVIDER_UP`                                 | Ограничение скорости отправки, КБ/с (только с суффиксом)          | `5000`                      |
| `PROVIDER_SKIP_CERT_VERIFY`                   | Не проверять TLS-сертификат (только с суффиксом)                  | `true` / `false`            |
| `PROVIDER_NAME_CERT_VERIFY`                   | Проверка имени сервера в сертификате (только с суффиксом)          | `true` / `false`            |
| `PROVIDER_DIALER_PROXY`                       | Имя прокси или группы для соединений провайдера (с суффиксом)     | `RU_AUTO`                   |
| `PROVIDER_ADDITIONAL_PREFIX`                  | Фиксированный префикс к именам серверов (только с суффиксом)       | `[US] `                     |
| `PROVIDER_ADDITIONAL_SUFFIX`                  | Фиксированный суффикс к именам серверов (только с суффиксом)       | ` - premium`                |
| `PROVIDER_OVERRIDE_EXPR`                      | Выражения yq для узлов провайдера через `#`                       | `.name = "[US] " + .name`   |

`PROVIDER_TFO`, `PROVIDER_MPTCP`, `PROVIDER_UDP`, `PROVIDER_UDP_OVER_TCP`, `PROVIDER_DOWN`, `PROVIDER_UP`, `PROVIDER_SKIP_CERT_VERIFY`, `PROVIDER_NAME_CERT_VERIFY`, `PROVIDER_DIALER_PROXY`, `PROVIDER_ADDITIONAL_PREFIX` и `PROVIDER_ADDITIONAL_SUFFIX` работают только с суффиксом конкретной подписки - например, `PROVIDER_UDP_SUB1`. Переменные `PROVIDER_FILTER`, `PROVIDER_EXCLUDE_FILTER`, `PROVIDER_EXCLUDE_TYPE`, `PROVIDER_HEADER`, `PROVIDER_INTERVAL` и `PROVIDER_OVERRIDE_EXPR` работают и глобально, и точечно.

**Про override-expr:** выражения применяются к узлам провайдера последовательно, после обычных override-полей. Это подмножество синтаксиса yq v4, например `.name = "[US] " + .name` или `del(.skip-cert-verify)`. Несколько выражений разделяются символом `#` - `|` занят конвейерами внутри самих выражений. Переменная появилась в контейнере в ноябре 2026 - обновите образ, иначе она будет проигнорирована.

```bash
# Только первая подписка: оставляем серверы США и разрешаем UDP
/container envs add list=MIHOMO key=PROVIDER_FILTER_SUB1 value="(?i)🇺🇸"
/container envs add list=MIHOMO key=PROVIDER_UDP_SUB1 value="true"

# Префикс к именам всех серверов и запрет проверки сертификата
/container envs add list=MIHOMO key=PROVIDER_OVERRIDE_EXPR value='.name = "[US] " + .name#del(.skip-cert-verify)'
```

**Переменные TUN/TPROXY (генерируются автоматически):**

| Переменная                  | Описание                                                  | Варианты                    |
| :-------------------------- | :-------------------------------------------------------- | :-------------------------- |
| `TUN`                       | Принудительно включить TUN вместо TPROXY                  | `1` / `0`                   |
| `TUN_IN_AUTOCONFIG`         | Блок конфигурации TUN/TPROXY (генерируется entrypoint.sh) |                             |
| `TUN_STACK`                 | Стек TUN                                                  | `mips`, `gvisor`, `system` |
| `TUN_AUTO_DETECT_INTERFACE` | Автоопределение интерфейса                                | `true` / `false`            |
| `TUN_AUTO_ROUTE`            | Автоматическая маршрутизация                              | `true` / `false`            |
| `TUN_AUTO_REDIRECT`         | Автоматический редирект                                   | `true` / `false`            |
| `TUN_INET4_ADDRESS`         | Адрес TUN интерфейса                                      | `198.19.0.1/30`             |
| `TUN_INET6_ADDRESS`         | Адрес TUN интерфейса (IPv6)                               | `fdfe:dcba:9876::1/126`    |
| `TUN_DISABLE_ICMP_FORWARDING` | Запретить проброс ICMP через TUN                         | `true` / `false`            |
| `IP_VERSION`                | Версия IP для дополнительных VETH-интерфейсов             | `dual`, `ipv4`, `ipv6`     |

**Переменные шаблона Area (только stargate-area.sh):**

| Переменная       | Описание                                                                    | Значение по умолчанию |
| :--------------- | :-------------------------------------------------------------------------- | :-------------------- |
| `SG_COUNTRIES`   | Список стран для шаблона Area (через запятую)                               |                       |
| `SG_CODE`        | Режим фильтрации: `false` = только флаг, `true` = флаг + код                | `false`               |
| `SG_FASTEST`     | Выполнять поиск быстрого по каждой стране (только для Area шаблона)         | `true`                |
| `SG_FAILOVER`    | Выполнять поиск доступного по каждой стране (только для Area шаблона)       | `true`                |
| `SG_LOADBALANCE` | Выполнять распределение нагрузки по каждой стране (только для Area шаблона) | `true`                |

**Автоматически генерируемые:**

| Переменная              | Описание                                                                      |
| :---------------------- | :---------------------------------------------------------------------------- |
| `HWID`                  | Hardware ID (генерируется из UUID) для подписок с ограничением по устройствам |
| `PROVIDERS_BLOCK`       | Блок подписок на прокси (генерируется из `SUB*`, `SRV*`, AWG `.conf` файлов)  |
| `PROVIDERS_LIST`        | Список провайдеров для групп (генерируется автоматически)                     |
| `PROVIDERS_CHAIN_BLOCK` | Блок цепочечных провайдеров (только для Chain шаблона)                        |
| `PROVIDERS_CHAIN_LIST`  | Список цепочечных провайдеров (только для Chain шаблона)                      |
| `AREA_GROUPS_BLOCK`     | Блок групп по странам (генерируется stargate-area.sh)                         |
| `AREA_GROUPS_LIST`      | Список групп по странам для proxy_list_all (генерируется stargate-area.sh)    |
| `AREA_SELECTOR_PROXIES` | Список групп по странам для SELECTOR (генерируется stargate-area.sh)          |

---

### Ручные переключатели

Их нужно настраивать самостоятельно в панели управления. **При первом запуске обязательно выберите прокси вручную:**

| Переключатель | Назначение                                    | Что это значит                                                   |
| :------------ | :-------------------------------------------- | :--------------------------------------------------------------- |
| `SELECTOR`    | **Главный** для большинства сервисов          | Для трафика, не распределяемого по сервисам                      |
| `MANUAL`      | Дополнительный выбор иностранного прокси      | Если SELECTOR не подходит - выберите вручную здесь               |
| `RU_MANUAL`   | Дополнительный выбор российского прокси       | То же, но специально для RU-прокси                               |
| `AWG_MANUAL`  | Специальные прокси (WireGuard, WARP, Amnezia) | Для сервисов, которым нужны эти безопасные протоколы             |
| `XX_MANUAL`   | Выбор прокси конкретной страны                | Только Area шаблон (XX = US_MANUAL, DE_MANUAL, NL_MANUAL и т.д.) |

### Автоматические переключатели

Эти работают сами по себе. **Никогда их не трогайте в панели!** Если вы их измените, автоматика сломается.

**Типы Fallback** - они выбирают прокси автоматически:
- `AUTO` - сам выбирает лучший иностранный прокси
- `RU_AUTO` - сам выбирает рабочий российский прокси
- `AWG_AUTO` - сам выбирает безопасный WireGuard/WARP прокси
- `XX_AUTO` - сам выбирает лучший прокси для страны X (только Area шаблон, где XX = код страны: US, DE, NL и т.д.)
- `VIA_RU_AUTO` - сам проводит трафик через РФ в заграницу **(только Chain шаблон)**
- `FAILOVER` / `RU_FAILOVER` / `XX_FAILOVER` - если основной прокси упал, автоматически переключаются на резервный

**Типы URLTest** - они выбирают прокси по скорости:
- `FASTEST` - постоянно проверяет и использует самый быстрый иностранный прокси
- `RU_FASTEST` - самый быстрый российский прокси
- `AWG_FASTEST` - самый быстрый безопасный прокси
- `XX_FASTEST` - самый быстрый прокси для страны X (только Area шаблон)
- `VIA_RU_FASTEST` - проверяет скорость и выбирает быстрейший путь через РФ в заграницу **(только Chain шаблон)**

**Типы Load-balance** - они распределяют нагрузку:
- `LOADBALANCE` - распределяет нагрузку по иностранным серверам
- `RU_LOADBALANCE` - распределяет нагрузку по российским серверам

### Сломалась автоматика?

**Чтобы восстановить автоматику:**

1. Откройте панель управления проксями
2. Найдите сбитый переключатель (около него отображается иконка замочка)
3. Нажмите на него **правой кнопкой мыши**
4. или нажмите кнопку спидометра

### Технические параметры

**Tolerance в URLTest:** Это допуск задержки в миллисекундах - если разница между текущим и протестированным прокси меньше допуска, переключение не происходит.
- Задается переменной `TOLERANCE`; чем меньше значение, тем чаще переключается прокси
- Для групп AWG допуск фиксирован на 30 мс
- Установите небольшое значение (например, 10 мс), если хотите, чтобы прокси переключались более агрессивно (чаще)
- Оставьте 80-100 мс, если хотите большей стабильности

**Фильтрация РФ прокси:** Система ищет (регистр не важен):
- Флаг 🇷🇺 в названии
- Или текст "RU" (в названиях вида `RU Server` или `Russia` слово найдется как "RU")

Если в ваших прокси используются другие обозначения (вместо "RU"), отредактируйте фильтр `filter_ru` в шаблонах

**WireGuard/WARP прокси:** Они не могут работать в цепочках (double proxy) из-за особенностей маршрутизации внутренних адресов, разным тоннелям важно знать про маршруты друг друга, поэтому автоматически исключаются из режима Chain. Но вы все равно можете их использовать через `AWG_*` переключатели в обычных шаблонах (Lite, Full, Mini)

**Совет по свободной памяти роутера:** Если оставить панель управления открытой в браузере - она будет избыточно грузить память и ресурсы оборудования. Если закроете браузер или вкладку, когда ничего не настраиваете - сэкономите ~10 МБ ОЗУ. Не все агрессивные дашборды полезны.

---

## Оптимизация подписок

### Очистка подписок

Бесплатные подписки часто содержат рекламу, бесполезные или дырявые конфигурации, которые раскрывают заинтересованным лицам ваши методы доступа в интернет.

[Фильтр подписок](https://github.com/Viktor45/sub-filter) удаляет неработающие серверы, опасные конфигурации и мусорные данные. Если ваши подписки уже чистые (платные), фильтр необязателен.

### Количество подписок

**Совет:** Используйте несколько разных подписок через `SUB1`, `SUB2`, `SUB3`:
- Повышает надежность (если одна подписка не загрузится)
- Больше вариантов для выбора прокси
- Критично для режима **Chain** (иначе может переключиться на прямое соединение по исчерпанию доступных серверов)

### Кодировка

**Обязательно сохраняйте файлы шаблонов в UTF-8 без BOM:**
- Откройте конфиг в VS Code или другом редакторе
- Убедитесь в нижнем правом углу: `UTF-8` (не `UTF-8 with BOM`)
- BOM может помешать Mihomo распознать конфиг

### Ограничения памяти

Значения потребления памяти в таблицах получены экспериментально на 32-bit ARM с одной подпиской и ~30 прокси на ней. На другом оборудовании и с другим количеством прокси значения будут отличаться.

---

## Дополнительная справка

- **Docker-контейнер:** https://hub.docker.com/r/wiktorbgu/mihomo-mikrotik
- **Документация Mihomo:** https://wiki.metacubex.one/
- **Документация Proxy Groups:** https://wiki.metacubex.one/en/config/proxy-groups/
- **Документация Dialer Proxy:** https://wiki.metacubex.one/ru/config/proxies/dialer-proxy/
- **Фильтр подписок:** https://github.com/Viktor45/sub-filter

Все шаблоны содержат подробные комментарии - читайте их, чтобы понять каждый параметр. Если нашли ошибку, открывайте [issue](https://github.com/Viktor45/mh-templates/issues).
