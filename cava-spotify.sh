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
CONFIG_FILE="/tmp/cava_config"
cat > "$CONFIG_FILE" << EOF
[general]
bars = 12
framerate = 60

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
    # Utiliser timeout pour éviter que cava ne reste bloqué
    # La modification clé est ici : nous ne prenons qu'une seule ligne mais nous conservons tous les segments
    timeout 1s cava -p "$CONFIG_FILE" 2>/dev/null | head -n 1 | tr -d '\n' || echo "▁▁▁▁▁▁▁▁▁▁▁▁"
}

# Vérifier si Spotify fonctionne
if [[ -z "$ARTIST" || -z "$TITLE" || -z "$STATUS" ]]; then
    # Si Spotify ne tourne pas, juste la visualisation de base
    BARS=$(get_visualizer | tr '0-7' '▁▂▃▄▅▆▇█')
    if [[ -z "$BARS" ]]; then
        BARS="▁▁▁▁▁▁▁▁▁▁▁▁"
    fi
    # Sortie JSON simple sans classe particulière
    echo "{\"text\":\"$BARS\", \"class\":\"\"}"
    exit 0
fi

# Tronquer les chaînes si trop longues
if [[ "${#ARTIST_ESCAPED}" -gt 15 ]]; then
    ARTIST_ESCAPED="${ARTIST_ESCAPED:0:15}..."
fi
if [[ "${#TITLE_ESCAPED}" -gt 15 ]]; then
    TITLE_ESCAPED="${TITLE_ESCAPED:0:15}..."
fi

# Obtenir barres de visualisation
RAW_BARS=$(get_visualizer)
if [[ -z "$RAW_BARS" ]]; then
    # Si CAVA échoue, utiliser une animation basée sur le temps
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
    BARS=$(echo "$RAW_BARS" | tr '0-7' '▁▂▃▄▅▆▇█')
fi

# Afficher les informations selon le statut
if [[ "$STATUS" == "Playing" ]]; then
    # Sortie JSON avec classe "playing"
    echo "{\"text\":\"$BARS  $ARTIST_ESCAPED - $TITLE_ESCAPED\", \"class\":\"playing\"}"
elif [[ "$STATUS" == "Paused" ]]; then
    # Sortie JSON avec classe "paused"
    echo "{\"text\":\"$BARS  $ARTIST_ESCAPED - $TITLE_ESCAPED\", \"class\":\"paused\"}"
else
    # Sortie JSON simple sans classe particulière
    echo "{\"text\":\"$BARS\", \"class\":\"\"}"
fi
