#!/bin/bash

# Fonction pour échapper les caractères spéciaux XML/HTML
escape_xml() {
    echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g'
}

# Obtenir informations Spotify
PLAYER="spotify"
ARTIST=$(playerctl -p $PLAYER metadata artist 2>/dev/null)
TITLE=$(playerctl -p $PLAYER metadata title 2>/dev/null)
STATUS=$(playerctl -p $PLAYER status 2>/dev/null)

# Échapper les caractères spéciaux
if [[ -n "$ARTIST" ]]; then
    ARTIST_ESCAPED=$(escape_xml "$ARTIST")
else
    ARTIST_ESCAPED=""
fi

if [[ -n "$TITLE" ]]; then
    TITLE_ESCAPED=$(escape_xml "$TITLE")
else
    TITLE_ESCAPED=""
fi

# Créer configuration CAVA temporaire
CONFIG_FILE="/tmp/cava_config_waybar"
cat > "$CONFIG_FILE" << EOF
[general]
bars = 12
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

[color]
foreground = 'default'

[smoothing]
monstercat = 1
waves = 0
noise_reduction = 0.77
EOF

# Fonction pour obtenir la visualisation
get_visualizer() {
    # Timeout augmenté pour permettre l'initialisation
    timeout 3s cava -p "$CONFIG_FILE" 2>/dev/null | head -n 1 | tr -d '\n' || echo "▁▁▁▁▁▁▁▁▁▁▁▁"
}

# Vérifier si Spotify fonctionne
if [[ -n "$ARTIST" && -n "$TITLE" && -n "$STATUS" ]]; then
    # Obtenir barres de visualisation
    RAW_BARS=$(get_visualizer)
    
    # Si CAVA échoue ou retourne vide, utiliser une animation de secours
    if [[ -z "$RAW_BARS" || "$RAW_BARS" == "▁▁▁▁▁▁▁▁▁▁▁▁" ]]; then
        SECOND=$(date +%S)
        MOD=$((SECOND % 8))
        case $MOD in
            0) BARS="▁▂▃▄▅▆▇█▇▆▅▄" ;;
            1) BARS="▂▃▄▅▆▇█▇▆▅▄▃" ;;
            2) BARS="▃▄▅▆▇█▇▆▅▄▃▂" ;;
            3) BARS="▄▅▆▇█▇▆▅▄▃▂▁" ;;
            4) BARS="▅▆▇█▇▆▅▄▃▂▁▂" ;;
            5) BARS="▆▇█▇▆▅▄▃▂▁▂▃" ;;
            6) BARS="▇█▇▆▅▄▃▂▁▂▃▄" ;;
            7) BARS="█▇▆▅▄▃▂▁▂▃▄▅" ;;
        esac
    else
        # Convertir les données brutes en barres visuelles
        BARS=$(echo "$RAW_BARS" | awk '{
            gsub(/0/, "▁");
            gsub(/1/, "▂");
            gsub(/2/, "▃");
            gsub(/3/, "▄");
            gsub(/4/, "▅");
            gsub(/5/, "▆");
            gsub(/6/, "▇");
            gsub(/7/, "█");
            print
        }')
    fi

    # Tronquer les textes si trop longs
    if [[ "${#ARTIST_ESCAPED}" -gt 15 ]]; then
        ARTIST_ESCAPED="${ARTIST_ESCAPED:0:15}..."
    fi
    if [[ "${#TITLE_ESCAPED}" -gt 15 ]]; then
        TITLE_ESCAPED="${TITLE_ESCAPED:0:15}..."
    fi

    # Afficher selon le statut
    if [[ "$STATUS" == "Playing" ]]; then
        echo "{\"text\":\"$BARS $ARTIST_ESCAPED - $TITLE_ESCAPED
