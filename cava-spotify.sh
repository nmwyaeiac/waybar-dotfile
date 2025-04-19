#!/bin/bash

# Configuration Cava minimale
CONFIG_FILE="/tmp/cava_waybar_config"
cat > "$CONFIG_FILE" << EOF
[general]
bars = 8
framerate = 60
autosens = 1
sensitivity = 100

[input]
method = pipewire
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7

[smoothing]
noise_reduction = 0.6
EOF

# Fonction pour obtenir les barres
get_audio_bars() {
    timeout 0.5s cava -p "$CONFIG_FILE" 2>/dev/null | head -n 1 || echo "00000000"
}

# Conversion en barres Unicode
convert_to_bars() {
    echo "$1" | awk '{
        gsub(/0/, "▁");
        gsub(/1/, "▂");
        gsub(/2/, "▃");
        gsub(/3/, "▄");
        gsub(/4/, "▅");
        gsub(/5/, "▆");
        gsub(/6/, "▇");
        gsub(/7/, "█");
        print
    }'
}

# Obtenir et afficher les barres
RAW_DATA=$(get_audio_bars)
AUDIO_BARS=$(convert_to_bars "$RAW_DATA")

echo "{\"text\":\"$AUDIO_BARS\", \"class\":\"audio-bars\"}"
