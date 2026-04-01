#!/usr/bin/env bash
# coffee-break-vim.sh — Vim-style animated coffee break timer
# Renders a vim-like TUI (line numbers, tilde rows, statusline) directly
# in the parent terminal's TTY — no new window needed.

DURATION=${1:-300}

# Walk up the process tree to find the first real TTY
find_tty() {
  local pid=$PPID
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    local ttyval
    ttyval=$(ps -p "$pid" -o tty= 2>/dev/null | tr -d ' ')
    if [ -n "$ttyval" ] && [ "$ttyval" != "??" ] && [ -e "/dev/$ttyval" ]; then
      echo "/dev/$ttyval"
      return 0
    fi
    pid=$(ps -p "$pid" -o ppid= 2>/dev/null | tr -d ' ')
    [ -z "$pid" ] || [ "$pid" -le 1 ] && break
  done
  if [ -w /dev/tty ]; then
    echo /dev/tty
  else
    echo ""
  fi
}

TTY_DEV=$(find_tty)

# Fallback: simple line-per-second progress display to stdout
if [ -z "$TTY_DEV" ] && [ ! -t 1 ]; then
  TOTAL=$DURATION
  START=$(date +%s)
  while true; do
    NOW=$(date +%s)
    ELAPSED=$(( NOW - START ))
    REMAINING=$(( TOTAL - ELAPSED ))
    (( REMAINING < 0 )) && REMAINING=0
    MINS=$(( REMAINING / 60 ))
    SECS=$(( REMAINING % 60 ))
    FILL=$(( (ELAPSED * 20 + TOTAL - 1) / TOTAL ))
    (( FILL > 20 )) && FILL=20
    BAR=""
    for ((i=0; i<20; i++)); do (( i < FILL )) && BAR+="█" || BAR+="░"; done
    printf "☕ [%s] %02d:%02d\n" "$BAR" "$MINS" "$SECS"
    (( REMAINING <= 0 )) && break
    sleep 1
  done
  exit 0
fi

# Output helper
out() { if [ -n "$TTY_DEV" ]; then printf '%b' "$@" > "$TTY_DEV"; else printf '%b' "$@"; fi; }

# Get terminal dimensions from the TTY
get_size() {
  local sz
  if [ -n "$TTY_DEV" ]; then
    sz=$(stty size < "$TTY_DEV" 2>/dev/null)
  else
    sz=$(stty size 2>/dev/null)
  fi
  echo "${sz:-24 80}"
}

# Colors
BROWN='\033[0;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
RESET='\033[0m'

# Enter alternate screen buffer, hide cursor, clear screen
out '\033[?1049h\033[?25l\033[2J\033[H'

cleanup() {
  out '\033[?1049l\033[?25h\033[0m'
}
trap cleanup EXIT INT TERM

# Steam animation frames (6 frames × 3 rows each)
STEAM=(
  "   ) ) )   "  "  (   (   "  "   )  )   "
  "  (   (    "  "   )   )  "  "  ( ( (   "
  "   ) ( )   "  "  (  (    "  "   ) ) )  "
  "  ( (      "  "   ) ( )  "  "  (   (   "
  "   )  ) )  "  "  ( (  (  "  "   ) ( )  "
  "  ( ( (    "  "   )  ) ) "  "  ( (  (  "
)

draw_frame() {
  local f=$1 timer=$2 bar=$3 done_mode=${4:-0}
  local top="${STEAM[$((f*3))]}"
  local mid="${STEAM[$((f*3+1))]}"
  local bot="${STEAM[$((f*3+2))]}"

  local F="\033[H\033[J"
  F+="\r\n"
  F+="  ${CYAN}${top}${RESET}\r\n"
  F+="  ${CYAN}${mid}${RESET}\r\n"
  F+="  ${CYAN}${bot}${RESET}\r\n"
  F+="   ${BROWN}.---------. ${RESET}\r\n"
  F+="   ${BROWN}|  COFFEE | ${RESET}\r\n"
  F+="   ${BROWN}|  BREAK  |${CYAN}o${RESET}\r\n"
  F+="   ${BROWN}\`---------'${RESET}\r\n"
  F+="   ${BROWN} '--------'${RESET}\r\n"
  F+="\r\n"
  if (( done_mode )); then
    F+="  ${WHITE}Break complete!${RESET}\r\n"
    F+="  ${CYAN}☕  Feeling refreshed and ready!${RESET}\r\n"
    F+="\r\n"
  else
    F+="  ${WHITE}Taking a break...${RESET}\r\n"
    F+="  ${GRAY}${bar}${RESET}\r\n"
    F+="  ${CYAN}⏱  ${timer} remaining${RESET}\r\n"
  fi

  out "$F"
}

TOTAL=$DURATION
START=$(date +%s)
FRAME=0

while true; do
  NOW=$(date +%s)
  ELAPSED=$(( NOW - START ))
  REMAINING=$(( TOTAL - ELAPSED ))
  (( REMAINING <= 0 )) && break

  MINS=$(( REMAINING / 60 ))
  SECS=$(( REMAINING % 60 ))
  TIMER=$(printf "%02d:%02d" "$MINS" "$SECS")

  PCT=$(( (ELAPSED * 100) / TOTAL ))
  PROGRESS=$(( (ELAPSED * 20) / TOTAL ))
  BAR=""
  for ((i=0; i<20; i++)); do
    (( i < PROGRESS )) && BAR+="█" || BAR+="░"
  done

  draw_frame "$((FRAME % 6))" "$TIMER" "$BAR" 0
  (( FRAME++ ))
  sleep 0.25
done

BAR=$(printf '█%.0s' {1..20})
draw_frame 0 "00:00" "$BAR" 1
sleep 1
