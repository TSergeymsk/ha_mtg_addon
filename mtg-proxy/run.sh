#!/usr/bin/env bash

CONFIG_DIR="/config"
CONFIG_FILE="${CONFIG_DIR}/mtg.toml"
mkdir -p "${CONFIG_DIR}"

options_file="/data/options.json"

if [ ! -f "$options_file" ]; then
    echo "ERROR: options.json not found"
    exit 1
fi

# --- Чтение параметров ---
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
proxies_str=$(jq -r '.proxies // ""' "$options_file")

# --- Начинаем генерировать TOML ---
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

# --- Обработка proxies (если не пусто) ---
if [ -n "$proxies_str" ]; then
    # Удаляем пробелы, разбиваем по запятой, получаем массив
    IFS=',' read -r -a proxies_array <<< "$proxies_str"
    # Формируем строку для TOML-массива
    proxies_toml=""
    for p in "${proxies_array[@]}"; do
        # Убираем лишние пробелы
        p_clean=$(echo "$p" | xargs)
        if [ -n "$p_clean" ]; then
            if [ -z "$proxies_toml" ]; then
                proxies_toml="\"$p_clean\""
            else
                proxies_toml="$proxies_toml, \"$p_clean\""
            fi
        fi
    done
    if [ -n "$proxies_toml" ]; then
        echo >> "${CONFIG_FILE}"
        echo "[network]" >> "${CONFIG_FILE}"
        echo "proxies = [$proxies_toml]" >> "${CONFIG_FILE}"
    fi
fi

echo "✅ Configuration generated at ${CONFIG_FILE}"
exec /usr/local/bin/mtg run "${CONFIG_FILE}"
