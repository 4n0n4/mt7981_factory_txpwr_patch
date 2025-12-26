#!/bin/sh
# MT7981 + MT7915/MT7976 TX power patcher (V2 layout, split 2/5/6)
#
# Zones (EN):
#   2.4 GHz = 4 bytes  (4 chains × 1 byte)
#   5   GHz = 20 bytes (4 chains × 5 groups)
#   6   GHz = 32 bytes (4 chains × 8 groups)
#
# Зоны (RU):
#   2.4 ГГц = 4 байта  (4 цепи по 1 байту)
#   5   ГГц = 20 байт  (4 цепи × 5 групп)
#   6   ГГц = 32 байта (4 цепи × 8 групп)
#
# Presets (EN):
#   preset_<name>_2g  = 4 bytes
#   preset_<name>_5g  = 20 bytes
#   preset_<name>_6g  = 32 bytes
#
# Пресеты (RU):
#   preset_<имя>_2g  = 4 байта
#   preset_<имя>_5g  = 20 байт
#   preset_<имя>_6g  = 32 байта

# =================== i18n / Localization ===================
# Default language is English.
TXPWR_LANG="${TXPWR_LANG:-en}"

set_lang() {
    case "$1" in
        ru|RU) TXPWR_LANG="ru" ;;
        en|EN) TXPWR_LANG="en" ;;
        *)     TXPWR_LANG="en" ;;  # fallback
    esac
}

# Translation helper
T() {
    local key="$1"
    case "$TXPWR_LANG:$key" in
        # ---- Common messages RU ----
        ru:ERR_NO_FACTORY_MTD)
            echo "Не найден раздел Factory в /proc/mtd"
            ;;
        ru:ERR_NO_MTD_DEV)
            echo "MTD-устройство не найдено:"
            ;;
        ru:DUMP_FOUND_FACTORY)
            echo "Нашёл Factory:"
            ;;
        ru:DUMP_MAKING)
            echo "Делаю дамп в"
            ;;
        ru:DUMP_DONE)
            echo "Готово, дамп:"
            ;;
        ru:ERR_INVALID_PRESET_BYTE)
            echo "Некорректный байт в пресете (нужен HEX, например 24, 2A, FF):"
            ;;
        ru:ERR_UNKNOWN_BAND)
            echo "Неизвестная зона (ожидается 2g/5g/6g):"
            ;;
        ru:ERR_NO_OFFSET_LEN)
            echo "Не заданы offset/len для зоны"
            ;;
        ru:REGION_BYTES_AT)
            echo "Байты по смещению"
            ;;
        ru:IN_FILE)
            echo "в файле"
            ;;
        ru:PATCH_FILE_FOR)
            echo "Файл для патча:"
            ;;
        ru:PATCH_CURRENT_BYTES)
            echo "Текущие байты"
            ;;
        ru:PATCH_WILL_WRITE)
            echo "Будут записаны байты для"
            ;;
        ru:ERR_TMP_CREATE)
            echo "Не могу создать временный файл"
            ;;
        ru:PATCH_AFTER)
            echo "После патча"
            ;;
        ru:ERR_UNKNOWN_PRESET)
            echo "Неизвестный пресет:"
            ;;
        ru:ERR_UNKNOWN_BAND_ARG)
            echo "Неизвестный диапазон (ожидается: 2g, 5g, 6g, all):"
            ;;
        ru:ERR_NO_BANDS_FOR_PRESET)
            echo "Для этого пресета нет ни одной зоны (2g/5g/6g):"
            ;;
        ru:PATCH_CONFIRM)
            echo "Будут пропатчены зоны:"
            ;;
        ru:PATCH_ARE_YOU_SURE)
            echo "Точно патчить эти зоны? [y/N]: "
            ;;
        ru:PATCH_CANCELLED)
            echo "Отменено."
            ;;
        ru:ERR_NEED_FILE_FOR_GEN)
            echo "-g требует указания файла через -f"
            ;;
        ru:ERR_FILE_NOT_FOUND)
            echo "Файл не найден:"
            ;;
        ru:GEN_ZONE_INFO)
            echo "Зона"
            ;;
        ru:GEN_ZONE_OFFSET_LEN)
            echo "смещение, длина байт:"
            ;;
        ru:GEN_ZONE_HEX)
            echo "HEX:"
            ;;
        ru:ERR_GEN_UNKNOWN_BAND)
            echo "Неизвестная зона для генерации пресета (ожидается 2g/5g/6g/all):"
            ;;
        ru:PRESETS_HEADER)
            echo "================ ПРЕСЕТЫ (копируй-вставляй) ================"
            ;;
        ru:FILE_LABEL)
            echo "Файл:"
            ;;
        ru:ZONE_2G_LABEL)
            echo "2.4 ГГц (2g):"
            ;;
        ru:ZONE_5G_LABEL)
            echo "5 ГГц (5g):"
            ;;
        ru:ZONE_6G_LABEL)
            echo "6 ГГц (6g):"
            ;;
        ru:PATCH_USAGE_HINT)
            echo "Патч:        $0 -p <preset> [-f factory.bin] [-b 2g|5g|6g|all]"
            ;;
        ru:GEN_USAGE_HINT)
            echo "Генерация:   $0 -g -f factory.bin [-p имя] [-b 2g|5g|6g|all]"
            ;;
        ru:ERR_UNKNOWN_PARAM)
            echo "Неизвестный параметр:"
            ;;
        ru:PRESETS_LIST_HEADER)
            echo "Доступные пресеты:"
            ;;
        ru:PRESETS_LIST_NONE)
            echo "Нет доступных пресетов (нет переменных preset_<name>_2g/5g/6g)."
            ;;

        # ---- Help RU ----
        ru:USAGE_HEADER)
            echo "Использование:"
            ;;
        ru:USAGE_SHOW_ZONES)
            echo "  Показать зоны (2.4/5/6 ГГц):"
            ;;
        ru:USAGE_PATCH_ZONES)
            echo "  Патчить зоны:"
            ;;
        ru:USAGE_GEN_PRESETS)
            echo "  Генерировать пресеты из дампа:"
            ;;
        ru:USAGE_FLAGS_HEADER)
            echo "Флаги:"
            ;;
        ru:USAGE_FLAG_F)
            echo "  -f FILE    - входной файл Factory (по умолчанию: автопоиск раздела \"Factory\""
            ;;
        ru:USAGE_FLAG_F2)
            echo "               в /proc/mtd и дамп в /tmp/factory_dump.bin)"
            ;;
        ru:USAGE_FLAG_P)
            echo "  -p NAME    - имя пресета (используется как \"preset_NAME_band\")"
            ;;
        ru:USAGE_FLAG_B)
            echo "  -b BAND    - диапазон: 2g | 5g | 6g | all (по умолчанию: all)"
            ;;
        ru:USAGE_FLAG_G)
            echo "  -g         - режим генерации пресетов из файла"
            ;;
        ru:USAGE_FLAG_L)
            echo "  -L LANG    - язык интерфейса: en | ru (по умолчанию: en)"
            ;;
        ru:USAGE_FLAG_H)
            echo "  -h         - помощь"
            ;;

        # ---- Common messages EN (default) ----
        *:ERR_NO_FACTORY_MTD)
            echo "Factory partition not found in /proc/mtd"
            ;;
        *:ERR_NO_MTD_DEV)
            echo "MTD device not found:"
            ;;
        *:DUMP_FOUND_FACTORY)
            echo "Found Factory:"
            ;;
        *:DUMP_MAKING)
            echo "Dumping to"
            ;;
        *:DUMP_DONE)
            echo "Done, dump:"
            ;;
        *:ERR_INVALID_PRESET_BYTE)
            echo "Invalid byte in preset (should be HEX, e.g. 24, 2A, FF):"
            ;;
        *:ERR_UNKNOWN_BAND)
            echo "Unknown band (expected 2g/5g/6g):"
            ;;
        *:ERR_NO_OFFSET_LEN)
            echo "Offset/len not set for band"
            ;;
        *:REGION_BYTES_AT)
            echo "Bytes at offset"
            ;;
        *:IN_FILE)
            echo "in file"
            ;;
        *:PATCH_FILE_FOR)
            echo "File to patch:"
            ;;
        *:PATCH_CURRENT_BYTES)
            echo "Current bytes"
            ;;
        *:PATCH_WILL_WRITE)
            echo "Will write bytes for"
            ;;
        *:ERR_TMP_CREATE)
            echo "Cannot create temporary file"
            ;;
        *:PATCH_AFTER)
            echo "After patch"
            ;;
        *:ERR_UNKNOWN_PRESET)
            echo "Unknown preset:"
            ;;
        *:ERR_UNKNOWN_BAND_ARG)
            echo "Unknown band (expected: 2g, 5g, 6g, all):"
            ;;
        *:ERR_NO_BANDS_FOR_PRESET)
            echo "Preset has no defined bands (2g/5g/6g):"
            ;;
        *:PATCH_CONFIRM)
            echo "Bands to be patched:"
            ;;
        *:PATCH_ARE_YOU_SURE)
            echo "Are you sure to patch these bands? [y/N]: "
            ;;
        *:PATCH_CANCELLED)
            echo "Cancelled."
            ;;
        *:ERR_NEED_FILE_FOR_GEN)
            echo "-g requires a file specified via -f"
            ;;
        *:ERR_FILE_NOT_FOUND)
            echo "File not found:"
            ;;
        *:GEN_ZONE_INFO)
            echo "Band"
            ;;
        *:GEN_ZONE_OFFSET_LEN)
            echo "offset, length bytes:"
            ;;
        *:GEN_ZONE_HEX)
            echo "HEX:"
            ;;
        *:ERR_GEN_UNKNOWN_BAND)
            echo "Unknown band for preset generation (expected 2g/5g/6g/all):"
            ;;
        *:PRESETS_HEADER)
            echo "================ PRESETS (copy-paste) ======================="
            ;;
        *:FILE_LABEL)
            echo "File:"
            ;;
        *:ZONE_2G_LABEL)
            echo "2.4 GHz (2g):"
            ;;
        *:ZONE_5G_LABEL)
            echo "5 GHz (5g):"
            ;;
        *:ZONE_6G_LABEL)
            echo "6 GHz (6g):"
            ;;
        *:PATCH_USAGE_HINT)
            echo "Patch:       $0 -p <preset> [-f factory.bin] [-b 2g|5g|6g|all]"
            ;;
        *:GEN_USAGE_HINT)
            echo "Generate:    $0 -g -f factory.bin [-p name] [-b 2g|5g|6g|all]"
            ;;
        *:ERR_UNKNOWN_PARAM)
            echo "Unknown parameter:"
            ;;
        *:PRESETS_LIST_HEADER)
            echo "Available presets:"
            ;;
        *:PRESETS_LIST_NONE)
            echo "No presets found (no preset_<name>_2g/5g/6g variables)."
            ;;

        # Help EN
        *:USAGE_HEADER)
            echo "Usage:"
            ;;
        *:USAGE_SHOW_ZONES)
            echo "  Show zones (2.4/5/6 GHz):"
            ;;
        *:USAGE_PATCH_ZONES)
            echo "  Patch zones:"
            ;;
        *:USAGE_GEN_PRESETS)
            echo "  Generate presets from dump:"
            ;;
        *:USAGE_FLAGS_HEADER)
            echo "Flags:"
            ;;
        *:USAGE_FLAG_F)
            echo "  -f FILE    - Factory input file (default: auto-dump \"Factory\" partition"
            ;;
        *:USAGE_FLAG_F2)
            echo "               from /proc/mtd into /tmp/factory_dump.bin)"
            ;;
        *:USAGE_FLAG_P)
            echo "  -p NAME    - preset name (used as \"preset_NAME_band\")"
            ;;
        *:USAGE_FLAG_B)
            echo "  -b BAND    - band: 2g | 5g | 6g | all (default: all)"
            ;;
        *:USAGE_FLAG_G)
            echo "  -g         - generate presets from file"
            ;;
        *:USAGE_FLAG_L)
            echo "  -L LANG    - interface language: en | ru (default: en)"
            ;;
        *:USAGE_FLAG_H)
            echo "  -h         - help"
            ;;
    esac
}

# =================== Layout (V2) ===================
#   MT_EE_TX0_POWER_2G_V2 = 0x441 (4 bytes)
#   MT_EE_TX0_POWER_5G_V2 = 0x445 (20 bytes)
#   MT_EE_TX0_POWER_6G_V2 = 0x465 (32 bytes)

band_offset_2g="441"  # 2.4 GHz block start
band_len_2g=4

band_offset_5g="445"  # 5 GHz block start
band_len_5g=20

band_offset_6g="465"  # 6 GHz block start
band_len_6g=32

# Supported bands
BANDS="2g 5g 6g"

# =================== Example presets ===================
# ax3000t
preset_ax3000t_2g="\
28 28 29 29 \
"
preset_ax3000t_5g="\
28 28 28 28 28 \
28 28 28 28 28 \
28 28 28 28 28 \
28 28 28 28 28 \
"
preset_ax3000t_6g="\
24 24 24 24 22 22 22 22 \
24 24 24 24 22 22 22 22 \
24 24 24 24 22 22 22 22 \
24 24 24 24 22 22 22 22 \
"

# wbr3000uax
preset_wbr3000uax_2g="\
27 27 29 29 \
"
preset_wbr3000uax_5g="\
26 26 26 26 26 \
26 26 26 26 26 \
26 26 26 26 26 \
29 29 29 29 29 \
"
preset_wbr3000uax_6g="\
24 24 24 24 22 22 22 22 \
24 24 24 24 22 22 22 22 \
24 24 24 24 22 22 22 22 \
24 24 24 24 22 22 22 22 \
"

# wr3000p
preset_wr3000p_2g="\
29 29 29 29 \
"
preset_wr3000p_5g="\
28 28 28 28 28 \
28 28 28 28 28 \
28 28 28 28 28 \
29 29 29 29 29 \
"
preset_wr3000p_6g="\
24 24 24 24 22 22 22 22 \
24 24 24 24 22 22 22 22 \
24 24 24 24 22 22 22 22 \
24 24 24 24 22 22 22 22 \
"

# rax3000me
preset_rax3000me_2g="\
29 29 29 29 \
"
preset_rax3000me_5g="\
28 28 28 28 28 \
28 28 28 28 28 \
28 28 28 28 28 \
28 28 28 28 28 \
"
preset_rax3000me_6g="\
24 24 24 24 22 22 22 22 \
24 24 24 24 22 22 22 22 \
24 24 24 24 22 22 22 22 \
24 24 24 24 22 22 22 22 \
"

# =================== Preset listing ===================

get_available_presets() {
    # Собираем имена пресетов по всем зонам из переменных preset_*_<band>
    local names="" band var base name
    for band in $BANDS; do
        # set | grep "^preset_.*_${band}="
        for var in $(set | grep "^preset_.*_${band}=" 2>/dev/null | cut -d= -f1); do
            base="${var#preset_}"
            name="${base%_"$band"}"
            # Добавляем уникально
            case " $names " in
                *" $name "*) ;;
                *) names="$names $name" ;;
            esac
        done
    done
    # Вернём через echo (начальный пробел уберём)
    echo "$names" | sed 's/^ *//'
}

show_presets_in_help() {
    local presets
    presets="$(get_available_presets)"
    echo
    echo "$(T PRESETS_LIST_HEADER)"
    if [ -n "$presets" ]; then
        # Один на строку: ax3000t, wbr3000uax, ...
        for p in $presets; do
            echo "  $p"
        done
    else
        echo "  $(T PRESETS_LIST_NONE)"
    fi
}

# =================== HELP / USAGE ===================

show_usage() {
    cat <<EOF
$(T USAGE_HEADER)

  $(T USAGE_SHOW_ZONES)
    $0 [-f factory.bin] [-L en|ru]

  $(T USAGE_PATCH_ZONES)
    $0 -p <preset> [-f factory.bin] [-b band] [-L en|ru]

  $(T USAGE_GEN_PRESETS)
    $0 -g -f factory.bin [-p name] [-b band] [-L en|ru]

$(T USAGE_FLAGS_HEADER)
$(T USAGE_FLAG_F)
$(T USAGE_FLAG_F2)
$(T USAGE_FLAG_P)
$(T USAGE_FLAG_B)
$(T USAGE_FLAG_G)
$(T USAGE_FLAG_L)
$(T USAGE_FLAG_H)
EOF

    show_presets_in_help
}

# =================== Helper functions ===================

hex_dump_region() {
    local file="$1"
    local offs_hex="$2"
    local len="$3"

    printf "%s 0x%s (+%d) %s %s:\n" "$(T REGION_BYTES_AT)" "$offs_hex" "$len" "$(T IN_FILE)" "$file"
    hexdump -Cv -s $((0x$offs_hex)) -n "$len" "$file"
}

dump_factory_if_needed() {
    local target="$1"

    if [ -n "$target" ]; then
        echo "$target"
        return 0
    fi

    local mtdline dev
    mtdline=$(grep -i '"Factory"' /proc/mtd 2>/dev/null | head -n1)
    if [ -z "$mtdline" ]; then
        echo "$(T ERR_NO_FACTORY_MTD)" >&2
        show_usage >&2
        exit 1
    fi

    dev=$(echo "$mtdline" | cut -d: -f1)
    dev="/dev/$dev"
    [ ! -e "$dev" ] && { echo "$(T ERR_NO_MTD_DEV) $dev" >&2; show_usage >&2; exit 1; }

    local out="/tmp/factory_dump.bin"
    echo "$(T DUMP_FOUND_FACTORY) $dev"
    echo "$(T DUMP_MAKING) $out ..."
    dd if="$dev" of="$out" bs=1M 2>/dev/null
    echo "$(T DUMP_DONE) $out"
    echo "$out"
}

hex_to_oct() {
    printf '%03o' "$((0x$1))"
}

append_hex_byte() {
    local hex="$1"
    local file="$2"

    case "$hex" in
        [0-9A-Fa-f][0-9A-Fa-f]) ;;
        *)
            echo "$(T ERR_INVALID_PRESET_BYTE) '$hex'" >&2
            exit 1
            ;;
    esac

    local oct
    oct=$(hex_to_oct "$hex")
    printf "\\$oct" >> "$file"
}

get_band_offset_and_len() {
    local band="$1"
    local offs len

    case "$band" in
        2g)
            offs="$band_offset_2g"
            len="$band_len_2g"
            ;;
        5g)
            offs="$band_offset_5g"
            len="$band_len_5g"
            ;;
        6g)
            offs="$band_offset_6g"
            len="$band_len_6g"
            ;;
        *)
            echo "$(T ERR_UNKNOWN_BAND) $band" >&2
            return 1
            ;;
    esac

    [ -z "$offs" ] || [ -z "$len" ] && {
        echo "$(T ERR_NO_OFFSET_LEN) $band" >&2
        return 1
    }

    echo "$offs $len"
}

# =================== Patching ===================

apply_preset_for_band() {
    local file="$1"
    local preset_name="$2"
    local band="$3"

    local info
    info=$(get_band_offset_and_len "$band") || exit 1
    local offs_hex len
    offs_hex=$(echo "$info" | awk '{print $1}')
    len=$(echo "$info"      | awk '{print $2}')

    eval "preset_data=\$preset_${preset_name}_${band}"
    [ -z "$preset_data" ] && {
        echo "$(T ERR_UNKNOWN_PRESET) '$preset_name' ($band)" >&2
        return 1
    }

    echo
    echo "--- $band ---"
    echo "$(T PATCH_FILE_FOR) $file"
    echo "$(T PATCH_CURRENT_BYTES) (0x$offs_hex – 0x$(printf '%X' $((0x$offs_hex+len-1)))):"
    hex_dump_region "$file" "$offs_hex" "$len"

    echo
    echo "$(T PATCH_WILL_WRITE) $band:"
    echo "$preset_data"
    echo

    tmp="/tmp/txpwr_${band}.$$"
    : > "$tmp" || { echo "$(T ERR_TMP_CREATE) $tmp" >&2; exit 1; }

    for b in $preset_data; do
        append_hex_byte "$b" "$tmp"
    done

    dd if="$tmp" of="$file" bs=1 seek=$((0x$offs_hex)) conv=notrunc 2>/dev/null
    rm -f "$tmp"

    echo
    echo "$(T PATCH_AFTER) ($band):"
    hex_dump_region "$file" "$offs_hex" "$len"
}

apply_preset() {
    local file="$1"
    local preset_name="$2"
    local band="$3"

    local any=""
    for b in $BANDS; do
        eval "tmp=\$preset_${preset_name}_${b}"
        [ -n "$tmp" ] && { any=1; break; }
    done
    [ -z "$any" ] && { echo "$(T ERR_UNKNOWN_PRESET) $preset_name" >&2; exit 1; }

    local sel_bands=""
    case "$band" in
        2g|5g|6g)
            sel_bands="$band"
            ;;
        ""|all)
            for b in $BANDS; do
                eval "tmp=\$preset_${preset_name}_${b}"
                [ -n "$tmp" ] && sel_bands="$sel_bands $b"
            done
            sel_bands=$(echo "$sel_bands" | sed 's/^ *//')
            ;;
        *)
            echo "$(T ERR_UNKNOWN_BAND_ARG) $band" >&2
            exit 1
            ;;
    esac

    [ -z "$sel_bands" ] && {
        echo "$(T ERR_NO_BANDS_FOR_PRESET) '$preset_name'" >&2
        exit 1
    }

    echo "$(T PATCH_FILE_FOR) $file"
    echo "$(T PATCH_CONFIRM) $sel_bands"
    printf "%s" "$(T PATCH_ARE_YOU_SURE)"
    read ans
    [ "$ans" = "y" ] || { echo "$(T PATCH_CANCELLED)"; exit 0; }

    for b in $sel_bands; do
        apply_preset_for_band "$file" "$preset_name" "$b"
    done
}

# =================== Preset generation ===================

PRESETS_BLOCK=""

gen_one_band() {
    local file="$1"
    local name="$2"
    local band="$3"

    local info
    info=$(get_band_offset_and_len "$band") || return 1
    local offs_hex len
    offs_hex=$(echo "$info" | awk '{print $1}')
    len=$(echo "$info"      | awk '{print $2}')

    local bytes
    bytes=$(hexdump -v -s $((0x$offs_hex)) -n "$len" -e ''$len'/1 "%02X " "\n"' "$file" 2>/dev/null) \
        || { echo "Error reading file $file" >&2; return 1; }

    bytes=$(echo "$bytes" | tr -s ' ')

    echo "$(T GEN_ZONE_INFO) $band: $(T GEN_ZONE_OFFSET_LEN) 0x$offs_hex, $len"
    echo "$(T GEN_ZONE_HEX) $bytes"
    echo

    # Parse bytes into positional params
    set -- $bytes

    local preset_txt="preset_${name}_${band}=\"\\
"

    case "$band" in
        2g)
            # 4 bytes in one line
            line=""
            for b in "$@"; do
                [ -n "$line" ] && line="$line "
                line="$line$b"
            done
            preset_txt="${preset_txt}${line} \\
"
            ;;
        5g)
            # 20 bytes = 4 chains × 5 groups -> 4 lines × 5
            idx=1
            for chain in 0 1 2 3; do
                line=""
                i=0
                while [ "$i" -lt 5 ]; do
                    eval "val=\${$idx}"
                    [ -z "$val" ] && break
                    [ -n "$line" ] && line="$line "
                    line="$line$val"
                    idx=$((idx+1))
                    i=$((i+1))
                done
                [ -n "$line" ] && preset_txt="${preset_txt}${line} \\
"
            done
            ;;
        6g)
            # 32 bytes = 4 chains × 8 groups -> 4 lines × 8
            idx=1
            for chain in 0 1 2 3; do
                line=""
                i=0
                while [ "$i" -lt 8 ]; do
                    eval "val=\${$idx}"
                    [ -z "$val" ] && break
                    [ -n "$line" ] && line="$line "
                    line="$line$val"
                    idx=$((idx+1))
                    i=$((i+1))
                done
                [ -n "$line" ] && preset_txt="${preset_txt}${line} \\
"
            done
            ;;
    esac

    preset_txt="${preset_txt}\""

    PRESETS_BLOCK="${PRESETS_BLOCK}${preset_txt}
"
}

gen_preset_from_file() {
    local file="$1"
    local name="$2"
    local band="$3"

    [ -z "$file" ] && { echo "$(T ERR_NEED_FILE_FOR_GEN)" >&2; exit 1; }
    [ ! -e "$file" ] && { echo "$(T ERR_FILE_NOT_FOUND) $file" >&2; exit 1; }

    [ -z "$name" ] && name="mydevice"
    [ -z "$band" ] && band="all"

    PRESETS_BLOCK=""

    case "$band" in
        2g|5g|6g)
            gen_one_band "$file" "$name" "$band"
            ;;
        all)
            for b in $BANDS; do
                gen_one_band "$file" "$name" "$b"
            done
            ;;
        *)
            echo "$(T ERR_GEN_UNKNOWN_BAND) $band" >&2
            exit 1
            ;;
    esac

    echo "$(T PRESETS_HEADER)"
    printf "%s" "$PRESETS_BLOCK"

    exit 0
}

# =================== Argument parsing ===================

FACTORY_FILE=""
PRESET_NAME=""
BAND=""
GEN_MODE=0

while [ $# -gt 0 ]; do
    case "$1" in
        -f)
            FACTORY_FILE="$2"
            shift 2
            ;;
        -p)
            PRESET_NAME="$2"
            shift 2
            ;;
        -b)
            BAND="$2"
            shift 2
            ;;
        -g)
            GEN_MODE=1
            shift
            ;;
        -L)
            set_lang "$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "$(T ERR_UNKNOWN_PARAM) $1" >&2
            show_usage >&2
            exit 1
            ;;
    esac
done

# =================== MAIN ===================

# Если вообще нет аргументов и не указаны ни -p, ни -g, ни -f — просто показать справку
if [ $# -eq 0 ] && [ -z "$PRESET_NAME" ] && [ "$GEN_MODE" -eq 0 ] && [ -z "$FACTORY_FILE" ]; then
    show_usage
    exit 0
fi

if [ "$GEN_MODE" -eq 1 ] && [ -z "$FACTORY_FILE" ]; then
    echo "$(T ERR_NEED_FILE_FOR_GEN)" >&2
    show_usage >&2
    exit 1
fi

if [ "$GEN_MODE" -eq 1 ]; then
    gen_preset_from_file "$FACTORY_FILE" "$PRESET_NAME" "$BAND"
fi

FACTORY_FILE=$(dump_factory_if_needed "$FACTORY_FILE")
[ ! -e "$FACTORY_FILE" ] && { echo "$(T ERR_FILE_NOT_FOUND) $FACTORY_FILE" >&2; exit 1; }

if [ -z "$PRESET_NAME" ]; then
    echo "$(T FILE_LABEL) $FACTORY_FILE"
    echo

    echo "$(T ZONE_2G_LABEL)"
    info=$(get_band_offset_and_len "2g") || exit 1
    hex_dump_region "$FACTORY_FILE" "$(echo "$info" | awk '{print $1}')" "$(echo "$info" | awk '{print $2}')"
    echo

    echo "$(T ZONE_5G_LABEL)"
    info=$(get_band_offset_and_len "5g") || exit 1
    hex_dump_region "$FACTORY_FILE" "$(echo "$info" | awk '{print $1}')" "$(echo "$info" | awk '{print $2}')"
    echo

    echo "$(T ZONE_6G_LABEL)"
    info=$(get_band_offset_and_len "6g") || exit 1
    hex_dump_region "$FACTORY_FILE" "$(echo "$info" | awk '{print $1}')" "$(echo "$info" | awk '{print $2}')"
    echo

    echo "$(T PATCH_USAGE_HINT)"
    echo "$(T GEN_USAGE_HINT)"
    show_presets_in_help
    exit 0
fi

apply_preset "$FACTORY_FILE" "$PRESET_NAME" "$BAND"
