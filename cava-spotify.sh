#!/bin/bash

# Obtenir informations Spotify
PLAYER="spotify"
ARTIST=$(playerctl -p $PLAYER metadata artist 2>/dev/null)
TITLE=$(playerctl -p $PLAYER metadata title 2>/dev/null)
STATUS=$(playerctl -p $PLAYER status 2>/dev/null)

# Créer configuration CAVA temporaire
CONFIG_FILE="/tmp/cava_config"
cat > "$CONFIG_FILE" << EOF
[general]
bars = 8
framerate = 30

[input]
method = pipewire
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7

[smoothing]
monstercat = 0
waves = 0
noise_reduction = 0.77
EOF

# Fonction pour obtenir la visualisation
get_visualizer() {
    # Utiliser timeout pour éviter que cava ne reste bloqué
    timeout 0.5s cava -p "$CONFIG_FILE" 2>/dev/null | sed -u 's/;/\n/g' | stdbuf -o0 tr -d "[:digit:];" | stdbuf -o0 tr '0-7' '▁▂▃▄▅▆▇█' | head -n 1 || echo "▁▂▃▄▅▆▇█"
}

# Vérifier si Spotify fonctionne
if [[ -z "$ARTIST" || -z "$TITLE" || -z "$STATUS" ]]; then
    # Si Spotify ne tourne pas, juste la visualisation
    BARS=$(get_visualizer)
    if [[ -z "$BARS" ]]; then
        BARS="▁▂▃▄▅▆▇█"
    fi
    echo "$BARS"
    exit 0
fi

# Tronquer les chaînes si trop longues
if [[ "${#ARTIST}" -gt 15 ]]; then
    ARTIST="${ARTIST:0:15}..."
fi
if [[ "${#TITLE}" -gt 15 ]]; then
    TITLE="${TITLE:0:15}..."
fi

# Obtenir barres de visualisation
BARS=$(get_visualizer)
if [[ -z "$BARS" ]]; then
    # Si CAVA échoue, utiliser une animation basée sur le temps
    SECOND=$(date +%S)
    MOD=$((SECOND % 8))
    case $MOD in
        0) BARS="▁▂▃▄▅▆▇█" ;;
        1) BARS="█▁▂▃▄▅▆▇" ;;
        2) BARS="▇█▁▂▃▄▅▆" ;;
        3) BARS="▆▇█▁▂▃▄▅" ;;
        4) BARS="▅▆▇█▁▂▃▄" ;;
        5) BARS="▄▅▆▇█▁▂▃" ;;
        6) BARS="▃▄▅▆▇█▁▂" ;;
        7) BARS="▂▃▄▅▆▇█▁" ;;
    esac
fi

# Afficher les informations selon le statut
if [[ "$STATUS" == "Playing" ]]; then
    echo "$BARS  $ARTIST - $TITLE"
elif [[ "$STATUS" == "Paused" ]]; then
    echo "$BARS  $ARTIST - $TITLE"
else
    echo "$BARS"
fi
