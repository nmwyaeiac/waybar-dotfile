#!/bin/bash

# Fichier de configuration temporaire
config_file="/tmp/cava_config"

# Créer le fichier de configuration
cat > "$config_file" << EOF
[general]
bars = 8
framerate = 30

[input]
method = pulse
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

# Exécuter cava et transformer directement la sortie
exec cava -p "$config_file" | sed -u 's/;/\n/g' | stdbuf -o0 tr -d "[:digit:];" | stdbuf -o0 tr '0-7' '▁▂▃▄▅▆▇█'
