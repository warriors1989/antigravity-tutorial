#!/bin/bash
set -euo pipefail

# ─── ANSI Helpers (Standard 16-color palette only) ───────────────────────────
R="\033[0m"         # Reset
B="\033[1m"         # Bold
D="\033[2m"         # Dim
I="\033[3m"         # Italic

# Foreground accents (Standard 16 colors)
FG_BLACK="\033[30m"
FG_RED="\033[31m"
FG_GREEN="\033[32m"
FG_YELLOW="\033[33m"
FG_BLUE="\033[34m"
FG_MAGENTA="\033[35m"
FG_CYAN="\033[36m"
FG_WHITE="\033[37m"

FG_GRAY="\033[90m"
FG_BRIGHT_RED="\033[91m"
FG_BRIGHT_GREEN="\033[92m"
FG_BRIGHT_YELLOW="\033[93m"
FG_BRIGHT_BLUE="\033[94m"
FG_BRIGHT_MAGENTA="\033[95m"
FG_BRIGHT_CYAN="\033[96m"
FG_BRIGHT_WHITE="\033[97m"

# Number Highlight Color
NUM_COLOR="${FG_BRIGHT_WHITE}${B}"

# ─── Parse JSON from stdin (Single jq pass for performance) ──────────────────
# Extract all fields in one pass to prevent spawning jq repeatedly.
{
  read -r STATE
  read -r USED_PCT
  read -r VCS_BRANCH
  read -r VCS_DIRTY
  read -r SANDBOX
  read -r ARTIFACTS
  read -r SUBAGENTS
  read -r BG_TASKS
  read -r MODEL
  read -r COLS
  read -r GEMINI_5H_FRAC
  read -r GEMINI_WEEKLY_FRAC
  read -r TP_5H_FRAC
  read -r TP_WEEKLY_FRAC
} <<< "$(
  jq -r '
    (.agent_state // "idle"),
    (.context_window.used_percentage // 0),
    (.vcs.branch // ""),
    (.vcs.dirty // false),
    (.sandbox.enabled // false),
    (.artifact_count // 0),
    (if .subagents | type == "array" then (.subagents | length) else 0 end),
    (.task_count // 0),
    (.model.display_name // ""),
    (.terminal_width // 80),
    ((.quota // {})["gemini-5h"].remaining_fraction // "__NA__"),
    ((.quota // {})["gemini-weekly"].remaining_fraction // "__NA__"),
    ((.quota // {})["3p-5h"].remaining_fraction // "__NA__"),
    ((.quota // {})["3p-weekly"].remaining_fraction // "__NA__")
  ' 2>/dev/null || printf "idle\n0\n\nfalse\nfalse\n0\n0\n0\n\n80\n__NA__\n__NA__\n__NA__\n__NA__\n"
)"

# ─── Computed Values ─────────────────────────────────────────────────────────
# Use LC_NUMERIC=C to prevent bash printf errors in locales that use commas for decimals
PCT_FMT=$(LC_NUMERIC=C printf "%.1f" "$USED_PCT")
PCT_INT=${USED_PCT%.*}; PCT_INT=${PCT_INT:-0}

format_quota_pct() {
  local fraction="${1:-}"
  if [ -z "$fraction" ] || [ "$fraction" = "null" ] || [ "$fraction" = "__NA__" ]; then
    printf -- "--"
  else
    LC_NUMERIC=C awk -v f="$fraction" 'BEGIN { printf "%.1f%%", f * 100 }'
  fi
}

GEMINI_5H_FMT=$(format_quota_pct "$GEMINI_5H_FRAC")
GEMINI_WEEKLY_FMT=$(format_quota_pct "$GEMINI_WEEKLY_FRAC")
TP_5H_FMT=$(format_quota_pct "$TP_5H_FRAC")
TP_WEEKLY_FMT=$(format_quota_pct "$TP_WEEKLY_FRAC")

# ─── State Indicator (No background colors) ──────────────────────────────────
case "$STATE" in
  idle)     S="${FG_BRIGHT_GREEN}${B}● READY${R}" ;;
  thinking) S="${FG_BRIGHT_YELLOW}${B}◆ THINKING${R}" ;;
  working)  S="${FG_BRIGHT_CYAN}${B}⚙ WORKING${R}" ;;
  tool_use) S="${FG_BRIGHT_MAGENTA}${B}🔧 TOOL${R}" ;;
  *)        S="${FG_WHITE}${B}⏳ $(echo "$STATE" | tr '[:lower:]' '[:upper:]')${R}" ;;
esac

# ─── VCS Branch ──────────────────────────────────────────────────────────────
V=""
if [ -n "$VCS_BRANCH" ]; then
  if [ "$VCS_DIRTY" = "true" ]; then
    V="${FG_GRAY} ╱ ${FG_BRIGHT_RED}${VCS_BRANCH}${FG_BRIGHT_YELLOW}*${R}"
  else
    V="${FG_GRAY} ╱ ${FG_BRIGHT_BLUE}${VCS_BRANCH}${R}"
  fi
fi

# ─── Model ───────────────────────────────────────────────────────────────────
M=""
if [ -n "$MODEL" ]; then
  M="${FG_GRAY} ╱ ${FG_BRIGHT_MAGENTA}${I}${MODEL}${R}"
fi

# ─── Sandbox Badge ───────────────────────────────────────────────────────────
if [ "$SANDBOX" = "true" ]; then
  SB="${FG_GRAY}sandbox ${FG_BRIGHT_GREEN}${B}ON${R}"
else
  SB="${FG_GRAY}sandbox off${R}"
fi

# ─── Context Bar (15 segments, fine-grain Unicode) ────────────────────────────
BAR_LEN=15
FILLED=$((PCT_INT * BAR_LEN / 100))
REMAINDER=$(( (PCT_INT * BAR_LEN) % 100 ))

# Pick color based on percentage
if [ "$PCT_INT" -ge 90 ]; then
  BAR_COLOR="$FG_BRIGHT_RED"
elif [ "$PCT_INT" -ge 60 ]; then
  BAR_COLOR="$FG_BRIGHT_YELLOW"
else
  BAR_COLOR="$FG_BRIGHT_WHITE"
fi

# Build bar with partial-fill last block
BAR=""
for ((i = 0; i < BAR_LEN; i++)); do
  if [ "$i" -lt "$FILLED" ]; then
    BAR="${BAR}█"
  elif [ "$i" -eq "$FILLED" ]; then
    if [ "$REMAINDER" -ge 75 ]; then
      BAR="${BAR}▓"
    elif [ "$REMAINDER" -ge 50 ]; then
      BAR="${BAR}▒"
    elif [ "$REMAINDER" -ge 25 ]; then
      BAR="${BAR}░"
    else
      BAR="${BAR}·"
    fi
  else
    BAR="${BAR}·"
  fi
done

# ─── Stats ───────────────────────────────────────────────────────────────────
CTX="${FG_GRAY}ctx ${BAR_COLOR}${BAR} ${NUM_COLOR}${PCT_FMT}%${R}"
ART_FMT="${FG_GRAY}artifacts ${NUM_COLOR}${ARTIFACTS}${R}"
SUB_FMT="${FG_GRAY}subagents ${NUM_COLOR}${SUBAGENTS}${R}"
BG_FMT="${FG_GRAY}tasks ${NUM_COLOR}${BG_TASKS}${R}"

# ─── Quota ───────────────────────────────────────────────────────────────────
GEMINI_QUOTA="${FG_GRAY}gemini ${NUM_COLOR}${GEMINI_5H_FMT}${FG_GRAY}/5h ${NUM_COLOR}${GEMINI_WEEKLY_FMT}${FG_GRAY}/w${R}"
TP_QUOTA="${FG_GRAY}3p ${NUM_COLOR}${TP_5H_FMT}${FG_GRAY}/5h ${NUM_COLOR}${TP_WEEKLY_FMT}${FG_GRAY}/w${R}"

# ─── Separators ──────────────────────────────────────────────────────────────
DOT="${FG_GRAY} · ${R}"

# ─── Output ──────────────────────────────────────────────────────────────────
LINE1="${S}${M}${V}"
LINE2=" ${GEMINI_QUOTA}${DOT}${TP_QUOTA}"
LINE3=" ${CTX}${DOT}${ART_FMT}${DOT}${SUB_FMT}${DOT}${BG_FMT}${DOT}${SB}"

if [ "$COLS" -ge 120 ]; then
  # Wide: keep the original status/stats together, add quota as the second line.
  echo -e "${LINE1}${FG_GRAY}  │  ${R}${LINE3}"
  echo -e "${FG_GRAY}   quota  ${R}${LINE2}"
elif [ "$COLS" -ge 80 ]; then
  # Medium: three-line layout with quota inserted as the second line.
  echo -e "${FG_GRAY}╭─${R} ${LINE1}"
  echo -e "${FG_GRAY}├─${R}${LINE2}"
  echo -e "${FG_GRAY}╰─${R}${LINE3}"
else
  # Narrow: compact three-line, minimal chrome.
  echo -e "${S}${M}"
  echo -e "${GEMINI_QUOTA}${DOT}${TP_QUOTA}"
  echo -e "${CTX}${DOT}${BG_FMT}"
fi
