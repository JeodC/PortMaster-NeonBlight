#!/bin/bash

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
source $controlfolder/device_info.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

# Setup permissions
$ESUDO chmod 666 /dev/tty1
$ESUDO chmod 666 /dev/uinput
echo "Loading, please wait... (might take a while!)" > $CUR_TTY

# Variables
GAMEDIR="/$directory/ports/neonblight"

# CD and set permissions
cd $GAMEDIR
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1
$ESUDO chmod +x -R $GAMEDIR/*

# Exports
export LD_LIBRARY_PATH="/usr/lib:$GAMEDIR/lib:$GAMEDIR/libs:$LD_LIBRARY_PATH"
export PATCHER_FILE="$GAMEDIR/tools/patchscript"
export PATCHER_GAME="$(basename "${0%.*}")" # This gets the current script filename without the extension
export PATCHER_TIME="20 to 30 minutes"

# dos2unix in case we need it
dos2unix "$GAMEDIR/tools/gmKtool.py"
dos2unix "$GAMEDIR/tools/Klib/GMblob.py"
dos2unix "$GAMEDIR/tools/patchscript"

# Check if patchlog.txt to skip patching
if [ ! -f patchlog.txt ]; then
    if [ -f "$controlfolder/utils/patcher.txt" ]; then
        source "$controlfolder/utils/patcher.txt"
        $ESUDO kill -9 $(pidof gptokeyb)
    else
        echo "This port requires the latest version of PortMaster." > $CUR_TTY
    fi
else
    echo "Patching process already completed. Skipping."
fi

# Exports
export LD_LIBRARY_PATH="$GAMEDIR/libs:$GAMEDIR/tools/lib:$LD_LIBRARY_PATH"
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

# Assign gptokeyb and load the game
$GPTOKEYB "gmloadernext" -c "neon.gptk" &
./gmloadernext game.apk

# Kill processes
rm -rf $GAMEDIR/gamedata/*.txt
rm -rf "$GAMEDIR/gamedata/input.nbsav"
$ESUDO kill -9 $(pidof gptokeyb)
$ESUDO systemctl restart oga_events &
printf "\033c" > /dev/tty0
