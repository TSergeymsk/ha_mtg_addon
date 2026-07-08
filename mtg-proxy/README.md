# MTProto Proxy (mtg) Add-on for Home Assistant

Этот аддон запускает легковесный MTProto-прокси [mtg](https://github.com/9seconds/mtg) внутри Home Assistant.  
Все параметры настраиваются через интерфейс аддона — никакого ручного редактирования файлов.

## Установка

1. В Home Assistant перейдите в **Настройки → Аддоны → Магазин аддонов**.
2. Нажмите на три точки → **Репозитории** → добавьте `https://github.com/TSergeymsk/ha_mtg_addon`.
3. Обновите магазин и установите аддон **MTProto Proxy (mtg)**.

## Настройка параметров (интерфейс Home Assistant)

После установки перейдите на вкладку **Конфигурация**. Все поля соответствуют параметрам `mtg`.  
**Обязательные поля:** `secret` и `bind_to` (оставьте `0.0.0.0:9443`, если не меняете порт).

### Основные параметры

| Параметр | Тип | По умолчанию | Описание |
|----------|-----|--------------|----------|
| `debug` | bool | `false` | Включить отладочный режим |
| `secret` | string | *обязательно* | Секретный ключ (генерируется для вашего домена) |
| `bind_to` | string | `0.0.0.0:9443` | Адрес:порт для прослушивания |
| `concurrency` | int | `8192` | Максимум параллельных соединений |
| `prefer_ip` | string | `"only-ipv4"` | Варианты: `prefer-ipv4`, `prefer-ipv6`, `only-ipv4`, `only-ipv6` |
| `auto_update` | bool | `true` | Автоматически обновлять правила DC |
| `tolerate_time_skewness` | string | `"5s"` | Допустимое отклонение времени |
| `allow_fallback_on_unknown_dc` | bool | `false` | Разрешить fallback при неизвестном DC |

### Сеть (network)

| Параметр | Тип | По умолчанию | Описание |
|----------|-----|--------------|----------|
| `network.dns` | string | `"https://1.1.1.1"` | DNS-резолвер (DoH) |
| `network.proxies` | list of strings | `["socks5://192.168.2.1:1122"]` | Прокси для исходящих соединений |
| `network.timeout.tcp` | string | `"5s"` | Таймаут TCP |
| `network.timeout.http` | string | `"10s"` | Таймаут HTTP |
| `network.timeout.idle` | string | `"1m"` | Таймаут простоя |

### Защита: Doppelganger (defense.doppelganger)

| Параметр | Тип | По умолчанию | Описание |
|----------|-----|--------------|----------|
| `defense.doppelganger.urls` | list of strings | `[]` | URL-адреса для подмены (доменный фронт) |
| `defense.doppelganger.repeats-per-raid` | int | `10` | Повторений в рейде |
| `defense.doppelganger.raid-each` | string | `"6h"` | Интервал между рейдами |
| `defense.doppelganger.drs` | bool | `false` | Включить DRS |

### Защита: Anti-Replay (defense.anti-replay)

| Параметр | Тип | По умолчанию | Описание |
|----------|-----|--------------|----------|
| `defense.anti-replay.enabled` | bool | `false` | Включить защиту от повторений |
| `defense.anti-replay.max-size` | string | `"1mib"` | Максимальный размер кэша |
| `defense.anti-replay.error-rate` | float | `0.001` | Допустимая доля ошибок |

### Защита: блок-лист (defense.blocklist)

| Параметр | Тип | По умолчанию | Описание |
|----------|-----|--------------|----------|
| `defense.blocklist.enabled` | bool | `false` | Включить блок-лист |
| `defense.blocklist.download-concurrency` | int | `2` | Одновременных загрузок списков |
| `defense.blocklist.urls` | list of strings | `["https://iplists.firehol.org/files/firehol_level1.netset"]` | URL-адреса списков |
| `defense.blocklist.update-each` | string | `"24h"` | Период обновления |

### Защита: вайт-лист (defense.allowlist)

| Параметр | Тип | По умолчанию | Описание |
|----------|-----|--------------|----------|
| `defense.allowlist.enabled` | bool | `false` | Включить вайт-лист |
| `defense.allowlist.download-concurrency` | int | `2` | Одновременных загрузок списков |
| `defense.allowlist.urls` | list of strings | `[]` | URL-адреса списков |
| `defense.allowlist.update-each` | string | `"24h"` | Период обновления |

### Статистика: StatsD (stats.statsd)

| Параметр | Тип | По умолчанию | Описание |
|----------|-----|--------------|----------|
| `stats.statsd.enabled` | bool | `false` | Включить отправку в StatsD |
| `stats.statsd.address` | string | `"127.0.0.1:8888"` | Адрес StatsD-сервера |
| `stats.statsd.metric-prefix` | string | `"mtg"` | Префикс метрик |
| `stats.statsd.tag-format` | string | `"datadog"` | Формат тегов (`datadog` или `influxdb`) |

### Статистика: Prometheus (stats.prometheus)

| Параметр | Тип | По умолчанию | Описание |
|----------|-----|--------------|----------|
| `stats.prometheus.enabled` | bool | `false` | Включить экспорт в Prometheus |
| `stats.prometheus.bind-to` | string | `"127.0.0.1:3129"` | Адрес:порт для сервера метрик |
| `stats.prometheus.http-path` | string | `"/"` | HTTP-путь для метрик |
| `stats.prometheus.metric-prefix` | string | `"mtg"` | Префикс метрик |

---

## Генерация секрета

Секрет нужно сгенерировать для вашего домена (или IP) командой:

```bash
docker run --rm nineseconds/mtg:2 generate-secret --hex ваш_домен
