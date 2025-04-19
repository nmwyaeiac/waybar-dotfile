#!/bin/bash

# Fonction pour échapper les caractères spéciaux
escape_xml() {
    echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g'
}

# Récupérer les infos Spotify
PLAYER="spotify"
ARTIST=$(playerctl -p $PLAYER metadata artist 2>/dev/null)
TITLE=$(playerctl -p $PLAYER metadata title 2>/dev/null)
STATUS=$(playerctl -p $PLAYER status 2>/dev/null)

# Si Spotify joue, afficher les infos
if [[ -n "$ARTIST" && -n "$TITLE" ]]; then
    ARTIST_ESCAPED=$(escape_xml "$ARTIST")
    TITLE_ESCAPED=$(escape_xml "$TITLE")
    
    # Tronquer si trop long
    [[ "${#ARTIST_ESCAPED}" -gt 20 ]] && ARTIST_ESCAPED="${ARTIST_ESCAPED:0:20}..."
    [[ "${#TITLE_ESCAPED}" -gt 20 ]] && TITLE_ESCAPED="${TITLE_ESCAPED:0:20}..."
    
    echo " $ARTIST_ESCAPED - $TITLE_ESCAPED"
else
    echo ""
fi
