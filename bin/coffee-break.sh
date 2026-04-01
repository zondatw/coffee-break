#!/usr/bin/env bash
# coffee-break.sh — Animated ASCII coffee break timer
# Finds the parent terminal's TTY device and writes directly to it,
# so the animation appears in Claude Code's own terminal window.

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
  # Fallback: try /dev/tty or stdout
  if [ -w /dev/tty ]; then
    echo /dev/tty
  else
    echo /dev/stdout
  fi
}

TTY_DEV=$(find_tty)

# Colors
BROWN='\033[0;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
RESET='\033[0m'

# Enter alternate screen buffer, hide cursor, clear it
printf '\033[?1049h\033[?25l\033[2J\033[H' > "$TTY_DEV"

cleanup() {
  # Exit alternate screen (restores original terminal content), show cursor
  printf '\033[?1049l\033[?25h\033[0m' > "$TTY_DEV"
}
trap cleanup EXIT INT TERM

# Steam animation — 6 frames x 3 rows
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

  local F
  F="\033[H\033[J"
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

  printf "$F" > "$TTY_DEV"
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

  PROGRESS=$(( (ELAPSED * 30) / TOTAL ))
  BAR=""
  for ((i=0; i<30; i++)); do
    (( i < PROGRESS )) && BAR+="█" || BAR+="░"
  done

  draw_frame "$((FRAME % 6))" "$TIMER" "$BAR"
  FRAME=$(( FRAME + 1 ))
  sleep 0.25
done

BAR=$(printf '█%.0s' {1..30})
draw_frame 0 "00:00" "$BAR" 1
