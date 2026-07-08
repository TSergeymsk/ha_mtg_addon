#!/usr/bin/env bash

CONFIG_DIR="/config"
CONFIG_FILE="${CONFIG_DIR}/mtg.toml"
mkdir -p "${CONFIG_DIR}"

options_file="/data/options.json"

if [ ! -f "$options_file" ]; then
    echo "ERROR: options.json not found"
    exit 1
fi

# Читаем обязательные параметры
secret=$(jq -r '.secret' "$options_file")
bind_to=$(jq -r '.bind_to' "$options_file")

if [ -z "$secret" ] || [ -z "$bind_to" ]; then
    echo "ERROR: secret and bind_to are required"
    exit 1
fi

# Основные параметры с значениями по умолчанию
debug=$(jq -r '.debug // false' "$options_file")
concurrency=$(jq -r '.concurrency // 8192' "$options_file")
prefer_ip=$(jq -r '.prefer_ip // "only-ipv4"' "$options_file")
auto_update=$(jq -r '.auto_update // true' "$options_file")
tolerate_time_skewness=$(jq -r '.tolerate_time_skewness // "5s"' "$options_file")
allow_fallback=$(jq -r '.allow_fallback_on_unknown_dc // false' "$options_file")

cat > "${CONFIG_FILE}" <<EOF
debug = ${debug}
secret = "${secret}"
bind-to = "${bind_to}"
concurrency = ${concurrency}
prefer-ip = "${prefer_ip}"
auto-update = ${auto_update}
tolerate-time-skewness = "${tolerate_time_skewness}"
allow-fallback-on-unknown-dc = ${allow_fallback}
EOF

# ----- Раздел network -----
if jq -e '.network' "$options_file" > /dev/null 2>&1; then
    echo >> "${CONFIG_FILE}"
    echo "[network]" >> "${CONFIG_FILE}"
    dns=$(jq -r '.network.dns // ""' "$options_file")
    [ -n "$dns" ] && echo "dns = \"$dns\"" >> "${CONFIG_FILE}"
    
    if jq -e '.network.proxies' "$options_file" > /dev/null 2>&1; then
        proxies=$(jq -r '.network.proxies | map("\"" + . + "\"") | join(", ")' "$options_file")
        [ -n "$proxies" ] && echo "proxies = [$proxies]" >> "${CONFIG_FILE}"
    fi
    
    if jq -e '.network.timeout' "$options_file" > /dev/null 2>&1; then
        echo "[network.timeout]" >> "${CONFIG_FILE}"
        tcp=$(jq -r '.network.timeout.tcp // ""' "$options_file")
        http=$(jq -r '.network.timeout.http // ""' "$options_file")
        idle=$(jq -r '.network.timeout.idle // ""' "$options_file")
        [ -n "$tcp" ] && echo "tcp = \"$tcp\"" >> "${CONFIG_FILE}"
        [ -n "$http" ] && echo "http = \"$http\"" >> "${CONFIG_FILE}"
        [ -n "$idle" ] && echo "idle = \"$idle\"" >> "${CONFIG_FILE}"
    fi
fi

# ----- Раздел defense.doppelganger -----
if jq -e '.defense.doppelganger' "$options_file" > /dev/null 2>&1; then
    echo >> "${CONFIG_FILE}"
    echo "[defense.doppelganger]" >> "${CONFIG_FILE}"
    repeats=$(jq -r '.defense.doppelganger."repeats-per-raid" // 10' "$options_file")
    raid=$(jq -r '.defense.doppelganger."raid-each" // "6h"' "$options_file")
    drs=$(jq -r '.defense.doppelganger.drs // false' "$options_file")
    echo "repeats-per-raid = $repeats" >> "${CONFIG_FILE}"
    echo "raid-each = \"$raid\"" >> "${CONFIG_FILE}"
    echo "drs = $drs" >> "${CONFIG_FILE}"
    
    if jq -e '.defense.doppelganger.urls' "$options_file" > /dev/null 2>&1; then
        urls=$(jq -r '.defense.doppelganger.urls | map("\"" + . + "\"") | join(", ")' "$options_file")
        [ -n "$urls" ] && echo "urls = [$urls]" >> "${CONFIG_FILE}"
    fi
fi

# ----- defense.anti-replay -----
if jq -e '.defense."anti-replay"' "$options_file" > /dev/null 2>&1; then
    echo >> "${CONFIG_FILE}"
    echo "[defense.anti-replay]" >> "${CONFIG_FILE}"
    enabled=$(jq -r '.defense."anti-replay".enabled // false' "$options_file")
    max_size=$(jq -r '.defense."anti-replay"."max-size" // "1mib"' "$options_file")
    error_rate=$(jq -r '.defense."anti-replay"."error-rate" // 0.001' "$options_file")
    echo "enabled = $enabled" >> "${CONFIG_FILE}"
    echo "max-size = \"$max_size\"" >> "${CONFIG_FILE}"
    echo "error-rate = $error_rate" >> "${CONFIG_FILE}"
fi

# ----- defense.blocklist -----
if jq -e '.defense.blocklist' "$options_file" > /dev/null 2>&1; then
    echo >> "${CONFIG_FILE}"
    echo "[defense.blocklist]" >> "${CONFIG_FILE}"
    enabled=$(jq -r '.defense.blocklist.enabled // false' "$options_file")
    conc=$(jq -r '.defense.blocklist."download-concurrency" // 2' "$options_file")
    update=$(jq -r '.defense.blocklist."update-each" // "24h"' "$options_file")
    echo "enabled = $enabled" >> "${CONFIG_FILE}"
    echo "download-concurrency = $conc" >> "${CONFIG_FILE}"
    echo "update-each = \"$update\"" >> "${CONFIG_FILE}"
    if jq -e '.defense.blocklist.urls' "$options_file" > /dev/null 2>&1; then
        urls=$(jq -r '.defense.blocklist.urls | map("\"" + . + "\"") | join(", ")' "$options_file")
        [ -n "$urls" ] && echo "urls = [$urls]" >> "${CONFIG_FILE}"
    fi
fi

# ----- defense.allowlist -----
if jq -e '.defense.allowlist' "$options_file" > /dev/null 2>&1; then
    echo >> "${CONFIG_FILE}"
    echo "[defense.allowlist]" >> "${CONFIG_FILE}"
    enabled=$(jq -r '.defense.allowlist.enabled // false' "$options_file")
    conc=$(jq -r '.defense.allowlist."download-concurrency" // 2' "$options_file")
    update=$(jq -r '.defense.allowlist."update-each" // "24h"' "$options_file")
    echo "enabled = $enabled" >> "${CONFIG_FILE}"
    echo "download-concurrency = $conc" >> "${CONFIG_FILE}"
    echo "update-each = \"$update\"" >> "${CONFIG_FILE}"
    if jq -e '.defense.allowlist.urls' "$options_file" > /dev/null 2>&1; then
        urls=$(jq -r '.defense.allowlist.urls | map("\"" + . + "\"") | join(", ")' "$options_file")
        [ -n "$urls" ] && echo "urls = [$urls]" >> "${CONFIG_FILE}"
    fi
fi

# ----- stats.statsd -----
if jq -e '.stats.statsd' "$options_file" > /dev/null 2>&1; then
    echo >> "${CONFIG_FILE}"
    echo "[stats.statsd]" >> "${CONFIG_FILE}"
    enabled=$(jq -r '.stats.statsd.enabled // false' "$options_file")
    address=$(jq -r '.stats.statsd.address // "127.0.0.1:8888"' "$options_file")
    prefix=$(jq -r '.stats.statsd."metric-prefix" // "mtg"' "$options_file")
    tag_format=$(jq -r '.stats.statsd."tag-format" // "datadog"' "$options_file")
    echo "enabled = $enabled" >> "${CONFIG_FILE}"
    echo "address = \"$address\"" >> "${CONFIG_FILE}"
    echo "metric-prefix = \"$prefix\"" >> "${CONFIG_FILE}"
    echo "tag-format = \"$tag_format\"" >> "${CONFIG_FILE}"
fi

# ----- stats.prometheus -----
if jq -e '.stats.prometheus' "$options_file" > /dev/null 2>&1; then
    echo >> "${CONFIG_FILE}"
    echo "[stats.prometheus]" >> "${CONFIG_FILE}"
    enabled=$(jq -r '.stats.prometheus.enabled // false' "$options_file")
    bind=$(jq -r '.stats.prometheus."bind-to" // "127.0.0.1:3129"' "$options_file")
    path=$(jq -r '.stats.prometheus."http-path" // "/"' "$options_file")
    prefix=$(jq -r '.stats.prometheus."metric-prefix" // "mtg"' "$options_file")
    echo "enabled = $enabled" >> "${CONFIG_FILE}"
    echo "bind-to = \"$bind\"" >> "${CONFIG_FILE}"
    echo "http-path = \"$path\"" >> "${CONFIG_FILE}"
    echo "metric-prefix = \"$prefix\"" >> "${CONFIG_FILE}"
fi

echo "✅ Configuration generated at ${CONFIG_FILE}"
exec /usr/local/bin/mtg run "${CONFIG_FILE}"
