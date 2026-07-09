#!/usr/bin/env bash

CONFIG_DIR="/config"
CONFIG_FILE="${CONFIG_DIR}/mtg.toml"
mkdir -p "${CONFIG_DIR}"

options_file="/data/options.json"

if [ ! -f "$options_file" ]; then
    echo "ERROR: options.json not found"
    exit 1
fi

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

# Добавляем proxies, если они есть
proxies=$(jq -r '.proxies // [] | map("\"" + . + "\"") | join(", ")' "$options_file")
if [ -n "$proxies" ]; then
    echo >> "${CONFIG_FILE}"
    echo "[network]" >> "${CONFIG_FILE}"
    echo "proxies = [$proxies]" >> "${CONFIG_FILE}"
fi

echo "✅ Configuration generated at ${CONFIG_FILE}"
exec /usr/local/bin/mtg run "${CONFIG_FILE}"
