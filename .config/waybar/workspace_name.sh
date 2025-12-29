#!/bin/sh

# 1. Force-kill any old versions of this script to prevent "Broken pipe" or duplicates
# The 'grep -v $$' ensures it doesn't kill itself
pgrep -f "workspace_name.sh" | grep -v $$ | xargs kill -9 2>/dev/null

# 2. Get the socket path
SOCKET="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
[ ! -S "$SOCKET" ] && SOCKET="/tmp/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"


get_workspace_name() {
    # Check if a special workspace is focused on the current monitor
    # The '// ""' ensures we don't get a literal "null" string
    SPECIAL=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).specialWorkspace.name // ""')

    if [ -n "$SPECIAL" ] && [ "$SPECIAL" != "null" ]; then
        # If special workspace is active, print its name
        echo "special"
    else
        # Otherwise, print the regular active workspace name
        hyprctl activeworkspace -j | jq -r '.name'
    fi
}

# 3. Initial print
# hyprctl activeworkspace -j | jq -r '.name'
get_workspace_name

# 4. Main listener
socat -u UNIX-CONNECT:"$SOCKET" - | while read -r line; do
    case "$line" in
        workspace\>\>*|focusedmon\>\>*|activespecialv2\>\>*)
            # Get name and exit if the pipe to Waybar breaks
            # hyprctl activeworkspace -j | jq -r '.name' || exit
            get_workspace_name
            ;;
    esac
done

