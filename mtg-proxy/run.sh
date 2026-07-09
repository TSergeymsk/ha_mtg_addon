#!/usr/bin/env bash

CONFIG_DIR="/config"
CONFIG_FILE="${CONFIG_DIR}/mtg.toml"
mkdir -p "${CONFIG_DIR}"

options_file="/data/options.json"

if [ ! -f "$options_file" ]; then
    echo "ERROR: options.json not found"
    exit 1
fi

# --- Основные параметры ---
secret=$(jq -r '.secret' "$options_file")
bind_to=$(jq -r '.bind_to' "$options_file")

if [ -z "$secret" ] || [ -z "$bind_to" ]; then
    echo "ERROR: secret and bind_to are required"
    exit 1
fi

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

# --- network ---
network_dns=$(jq -r '.network_dns // ""' "$options_file")
if [ -n "$network_dns" ]; then
    echo >> "${CONFIG_FILE}"
    echo "[network]" >> "${CONFIG_FILE}"
    echo "dns = \"$network_dns\"" >> "${CONFIG_FILE}"
fi

network_proxies=$(jq -r '.network_proxies // [] | map("\"" + . + "\"") | join(", ")' "$options_file")
if [ -n "$network_proxies" ]; then
    # если секция [network] ещё не открыта, откроем
    if ! grep -q "^\[network\]" "${CONFIG_FILE}"; then
        echo >> "${CONFIG_FILE}"
        echo "[network]" >> "${CONFIG_FILE}"
    fi
    echo "proxies = [$network_proxies]" >> "${CONFIG_FILE}"
fi

network_timeout_tcp=$(jq -r '.network_timeout_tcp // ""' "$options_file")
network_timeout_http=$(jq -r '.network_timeout_http // ""' "$options_file")
network_timeout_idle=$(jq -r '.network_timeout_idle // ""' "$options_file")
if [ -n "$network_timeout_tcp" ] || [ -n "$network_timeout_http" ] || [ -n "$network_timeout_idle" ]; then
    if ! grep -q "^\[network\]" "${CONFIG_FILE}"; then
        echo >> "${CONFIG_FILE}"
        echo "[network]" >> "${CONFIG_FILE}"
    fi
    echo "[network.timeout]" >> "${CONFIG_FILE}"
    [ -n "$network_timeout_tcp" ] && echo "tcp = \"$network_timeout_tcp\"" >> "${CONFIG_FILE}"
    [ -n "$network_timeout_http" ] && echo "http = \"$network_timeout_http\"" >> "${CONFIG_FILE}"
    [ -n "$network_timeout_idle" ] && echo "idle = \"$network_timeout_idle\"" >> "${CONFIG_FILE}"
fi

# --- defense.doppelganger ---
if jq -e '.defense_doppelganger_repeats_per_raid' "$options_file" >/dev/null 2>&1; then
    echo >> "${CONFIG_FILE}"
    echo "[defense.doppelganger]" >> "${CONFIG_FILE}"
    repeats=$(jq -r '.defense_doppelganger_repeats_per_raid // 10' "$options_file")
    raid=$(jq -r '.defense_doppelganger_raid_each // "6h"' "$options_file")
    drs=$(jq -r '.defense_doppelganger_drs // false' "$options_file")
    echo "repeats-per-raid = $repeats" >> "${CONFIG_FILE}"
    echo "raid-each = \"$raid\"" >> "${CONFIG_FILE}"
    echo "drs = $drs" >> "${CONFIG_FILE}"
    urls=$(jq -r '.defense_doppelganger_urls // [] | map("\"" + . + "\"") | join(", ")' "$options_file")
    if [ -n "$urls" ]; then
        echo "urls = [$urls]" >> "${CONFIG_FILE}"
    fi
fi

# --- defense.anti-replay ---
if jq -e '.defense_anti_replay_enabled' "$options_file" >/dev/null 2>&1; then
    echo >> "${CONFIG_FILE}"
    echo "[defense.anti-replay]" >> "${CONFIG_FILE}"
    enabled=$(jq -r '.defense_anti_replay_enabled // false' "$options_file")
    max_size=$(jq -r '.defense_anti_replay_max_size // "1mib"' "$options_file")
    error_rate=$(jq -r '.defense_anti_replay_error_rate // 0.001' "$options_file")
    echo "enabled = $enabled" >> "${CONFIG_FILE}"
    echo "max-size = \"$max_size\"" >> "${CONFIG_FILE}"
    echo "error-rate = $error_rate" >> "${CONFIG_FILE}"
fi

# --- defense.blocklist ---
if jq -e '.defense_blocklist_enabled' "$options_file" >/dev/null 2>&1; then
    echo >> "${CONFIG_FILE}"
    echo "[defense.blocklist]" >> "${CONFIG_FILE}"
    enabled=$(jq -r '.defense_blocklist_enabled // false' "$options_file")
    conc=$(jq -r '.defense_blocklist_download_concurrency // 2' "$options_file")
    update=$(jq -r '.defense_blocklist_update_each // "24h"' "$options_file")
    echo "enabled = $enabled" >> "${CONFIG_FILE}"
    echo "download-concurrency = $conc" >> "${CONFIG_FILE}"
    echo "update-each = \"$update\"" >> "${CONFIG_FILE}"
    urls=$(jq -r '.defense_blocklist_urls // [] | map("\"" + . + "\"") | join(", ")' "$options_file")
    if [ -n "$urls" ]; then
        echo "urls = [$urls]" >> "${CONFIG_FILE}"
    fi
fi

# --- defense.allowlist ---
if jq -e '.defense_allowlist_enabled' "$options_file" >/dev/null 2>&1; then
    echo >> "${CONFIG_FILE}"
    echo "[defense.allowlist]" >> "${CONFIG_FILE}"
    enabled=$(jq -r '.defense_allowlist_enabled // false' "$options_file")
    conc=$(jq -r '.defense_allowlist_download_concurrency // 2' "$options_file")
    update=$(jq -r '.defense_allowlist_update_each // "24h"' "$options_file")
    echo "enabled = $enabled" >> "${CONFIG_FILE}"
    echo "download-concurrency = $conc" >> "${CONFIG_FILE}"
    echo "update-each = \"$update\"" >> "${CONFIG_FILE}"
    urls=$(jq -r '.defense_allowlist_urls // [] | map("\"" + . + "\"") | join(", ")' "$options_file")
    if [ -n "$urls" ]; then
        echo "urls = [$urls]" >> "${CONFIG_FILE}"
    fi
fi

# --- stats.statsd ---
if jq -e '.stats_statsd_enabled' "$options_file" >/dev/null 2>&1; then
    echo >> "${CONFIG_FILE}"
    echo "[stats.statsd]" >> "${CONFIG_FILE}"
    enabled=$(jq -r '.stats_statsd_enabled // false' "$options_file")
    address=$(jq -r '.stats_statsd_address // "127.0.0.1:8888"' "$options_file")
    prefix=$(jq -r '.stats_statsd_metric_prefix // "mtg"' "$options_file")
    tag_format=$(jq -r '.stats_statsd_tag_format // "datadog"' "$options_file")
    echo "enabled = $enabled" >> "${CONFIG_FILE}"
    echo "address = \"$address\"" >> "${CONFIG_FILE}"
    echo "metric-prefix = \"$prefix\"" >> "${CONFIG_FILE}"
    echo "tag-format = \"$tag_format\"" >> "${CONFIG_FILE}"
fi

# --- stats.prometheus ---
if jq -e '.stats_prometheus_enabled' "$options_file" >/dev/null 2>&1; then
    echo >> "${CONFIG_FILE}"
    echo "[stats.prometheus]" >> "${CONFIG_FILE}"
    enabled=$(jq -r '.stats_prometheus_enabled // false' "$options_file")
    bind=$(jq -r '.stats_prometheus_bind_to // "127.0.0.1:3129"' "$options_file")
    path=$(jq -r '.stats_prometheus_http_path // "/"' "$options_file")
    prefix=$(jq -r '.stats_prometheus_metric_prefix // "mtg"' "$options_file")
    echo "enabled = $enabled" >> "${CONFIG_FILE}"
    echo "bind-to = \"$bind\"" >> "${CONFIG_FILE}"
    echo "http-path = \"$path\"" >> "${CONFIG_FILE}"
    echo "metric-prefix = \"$prefix\"" >> "${CONFIG_FILE}"
fi

echo "✅ Configuration generated at ${CONFIG_FILE}"
exec /usr/local/bin/mtg run "${CONFIG_FILE}"
