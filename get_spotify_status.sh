#!/bin/bash

# Fonction pour échapper les caractères spéciaux XML/HTML
escape_xml() {
    echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g'
}

# Chemin du script
PARENT_BAR="waybar"
PARENT_BAR_PID=$(pgrep -a "waybar" | head -n 1 | awk '{print $1}')

# Vérifie si playerctl est installé
if ! command -v playerctl &>/dev/null; then
    echo "playerctl n'est pas installé"
    exit 1
fi

# Vérifie si Spotify est en cours d'exécution
if ! playerctl -l 2>/dev/null | grep -q "spotify"; then
    echo ""  # Retourne une chaîne vide si Spotify n'est pas en cours d'exécution
    exit 0
fi

# Récupère les informations de Spotify
PLAYER="spotify"
ARTIST=$(playerctl -p $PLAYER metadata artist 2>/dev/null)
TITLE=$(playerctl -p $PLAYER metadata title 2>/dev/null)
STATUS=$(playerctl -p $PLAYER status 2>/dev/null)

# Si l'artiste ou le titre est vide, quitter
if [[ -z "$ARTIST" || -z "$TITLE" ]]; then
    echo ""
    exit 0
fi

# Échapper les caractères spéciaux
ARTIST_ESCAPED=$(escape_xml "$ARTIST")
TITLE_ESCAPED=$(escape_xml "$TITLE")

# Troncature des chaînes si elles sont trop longues
if [[ "${#ARTIST_ESCAPED}" -gt 20 ]]; then
    ARTIST_ESCAPED="${ARTIST_ESCAPED:0:20}..."
fi
if [[ "${#TITLE_ESCAPED}" -gt 20 ]]; then
    TITLE_ESCAPED="${TITLE_ESCAPED:0:20}..."
fi

# Affiche les informations en fonction du statut
if [[ "$STATUS" == "Playing" ]]; then
    echo " $ARTIST_ESCAPED - $TITLE_ESCAPED"
elif [[ "$STATUS" == "Paused" ]]; then
    echo " $ARTIST_ESCAPED - $TITLE_ESCAPED"
else
    echo ""
fi
