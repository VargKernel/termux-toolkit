#!/data/data/com.termux/files/usr/bin/sh

# Const
VNC_GEOMETRY="1280x720"
VNC_DEPTH="24"
SSH_PORT="8022"
BASHRC="$HOME/.bashrc"
XSTARTUP_PATH="$HOME/.vnc/xstartup"

# Colours
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

term_width() {
    local width
    width=$(tput cols 2>/dev/null)
    [ -n "$width" ] || width=60
    printf '%s' "$width"
}

draw_line() {
    local width char
    char="${1:-=}"
    width=$(term_width)
    printf '%*s\n' "$width" '' | tr ' ' "$char"
}

center_text() {
    local text width padding
    text="$1"
    width=$(term_width)

    if [ "${#text}" -ge "$width" ]; then
        printf '%s\n' "$text"
        return
    fi

    padding=$(( (width - ${#text}) / 2 ))
    printf '%*s%s\n' "$padding" "" "$text"
}

print_status() {
    printf '%b[*] %s%b\n' "$BLUE" "$1" "$NC"
}

install_dependencies() {
    print_status "Updating packages and installing dependencies..."
    pkg update && pkg upgrade -y
    pkg install x11-repo -y
    pkg install tigervnc xfce4 openssh -y
}

configure_vnc() {
    print_status "Configuring VNC directory and xstartup..."
    mkdir -p "$HOME/.vnc"

    # Autogenerating xstartup
    cat <<EOF > "$XSTARTUP_PATH"
#!/data/data/com.termux/files/usr/bin/sh
export DISPLAY=:1
xfce4-session &
EOF

    chmod +x "$XSTARTUP_PATH"
}

manage_aliases() {
    print_status "Setting up desktop aliases and welcome message..."

    # Cleaning old entries
    sed -i '/# >>> VNC & SSH Aliases >>>/,/# <<< VNC & SSH Aliases <<</d' "$BASHRC" 2>/dev/null

    # # Cleaning old entries
    {
        printf '\n# >>> VNC & SSH Aliases >>>\n'
        printf "alias desktop-start='vncserver -kill :1 2>/dev/null; rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1; sshd -p %s; vncserver :1 -geometry %s -depth %s'\n" "$SSH_PORT" "$VNC_GEOMETRY" "$VNC_DEPTH"
        printf "alias desktop-stop='vncserver -kill :1 2>/dev/null; pkill sshd 2>/dev/null'\n"
        printf '# <<< VNC & SSH Aliases <<<\n'
    } >> "$BASHRC"
}

show_connection_info() {
    local internal_ip
    internal_ip=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -n1)

    printf '%b\n' "$YELLOW"
    draw_line "="
    center_text "CONNECTION CREDENTIALS"
    draw_line "="
    printf '%b\n' "$NC"

    printf '%b\n' "${GREEN}1. SSH SERVER (Port $SSH_PORT)${NC}"
    printf "   - Local:  ssh -p %s localhost\n" "$SSH_PORT"
    printf "   - LAN:    ssh -p %s %s\n\n" "$SSH_PORT" "$internal_ip"

    printf '%b\n' "${GREEN}2. VNC DESKTOP (Port 5901)${NC}"
    printf "   - Local:  localhost:5901\n"
    printf "   - LAN:    %s:5901\n\n" "$internal_ip"

    printf '%b\n' "${YELLOW}"
    printf "3. TIP: STATIC IP\n"
    printf "   - Your current internal IP is: %s\n" "$internal_ip"
    printf "   - If you plan to connect from other devices regularly,\n"
    printf "     reserve this IP in your Router/DHCP settings to avoid\n"
    printf "     connection drops or IP changes.\n"
    draw_line "="
    printf "   Commands: 'desktop-start' (Launch) | 'desktop-stop' (Kill)\n"
    draw_line "="
    printf '%b\n' "$NC"
}

main() {
    install_dependencies
    configure_vnc
    manage_aliases

    printf '%b------------------------------------------------%b\n' "$GREEN" "$NC"
    printf '%bInstallation complete!%b\n' "$GREEN" "$NC"
    printf "1. Run 'vncpasswd' to set your VNC password.\n"
    printf "2. Run 'passwd' to set your SSH password.\n"
    printf "3. Run 'source ~/.bashrc' to activate aliases right now, or restart Termux.\n"
    printf "4. For example: You can use Remmina, AVNC, or SSH to connect.\n"

    show_connection_info
}

main
