#!/bin/sh
# PegasusG by ROC - LoongOS (RK3566) launcher with multi-platform support.
# Adapted from the H700 launch.sh: no managed cores, no vendor power scripts,
# RetroArch is AArch64 and launched directly.
set -u

APP_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
BIN="$APP_DIR/pegasusg_by_roc"
STATE_DIR="${PEGASUSG_STATE_DIR:-/tmp/pegasusg}"
REQUEST="$STATE_DIR/launch.request"
LOG_DIR="$STATE_DIR/logs"
LOG_FILE="$LOG_DIR/PegasusG-by-ROC.log"
RA_BIN="${PEGASUSG_RA_BIN:-/userdata/app/retroarch/retroarch}"
CORES_DIR="${PEGASUSG_CORES_DIR:-/userdata/app/retroarch/.config/cores}"
FONT="${PEGASUSG_FONT:-/userdata/app/retroarch/.config/assets/pkg/chinese-fallback-font.ttf}"
CONTENT_ROOTS="${PEGASUSG_CONTENT_ROOTS:-/mnt/sdcard/roms/GBA:/mnt/sdcard/roms/GBA hack:/mnt/sdcard/roms/GBA vib:/mnt/sdcard/roms/FC:/mnt/sdcard/roms/SFC:/mnt/sdcard/roms/MD:/mnt/sdcard/roms/SMS:/mnt/sdcard/roms/GG:/mnt/sdcard/roms/GB:/mnt/sdcard/roms/PCE:/mnt/sdcard/roms/FBNEO:/mnt/sdcard/roms/MAME}"

mkdir -p "$STATE_DIR" "$LOG_DIR"

log_line() {
  printf '%s\n' "$*" >>"$LOG_FILE"
}

trim_log() {
  if [ -f "$LOG_FILE" ] && [ "$(wc -c <"$LOG_FILE" 2>/dev/null || echo 0)" -gt 262144 ]; then
    tail -c 131072 "$LOG_FILE" >"$LOG_FILE.tmp" 2>/dev/null && mv "$LOG_FILE.tmp" "$LOG_FILE"
  fi
}

frontend_env() {
  export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/var/run}"
  export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
  export SDL_VIDEODRIVER=wayland
  export SDL_AUDIODRIVER=alsa
  export SDL_NOMOUSE=1
  export PEGASUSG_APP_DIR="$APP_DIR"
  export PEGASUSG_DEVICE=loong
  export PEGASUSG_STATE_DIR="$STATE_DIR"
  export PEGASUSG_LAUNCH_REQUEST="$REQUEST"
  export PEGASUSG_CONTENT_ROOTS="$CONTENT_ROOTS"
  export PEGASUSG_FONT="$FONT"
}

core_for_choice() {
  case "$1" in
    mgba) echo mgba_libretro.so ;;
    gpsp | gpsp_rumble) echo gpsp_libretro.so ;;
    vbam) echo vbam_libretro.so ;;
    vba_next) echo vba_next_libretro.so ;;
    fceumm) echo fceumm_libretro.so ;;
    snes9x) echo snes9x_libretro.so ;;
    snes9x2010) echo snes9x2010_libretro.so ;;
    genesis_plus_gx) echo genesis_plus_gx_libretro.so ;;
    picodrive) echo picodrive_libretro.so ;;
    gambatte) echo gambatte_libretro.so ;;
    fbneo) echo fbneo_libretro.so ;;
    fbalpha2012) echo fbalpha2012_libretro.so ;;
    mame2003_plus) echo mame2003_plus_libretro.so ;;
    mame2010) echo mame2010_libretro.so ;;
    *) echo mgba_libretro.so ;;
  esac
}

run_frontend() {
  frontend_env
  log_line "[launcher] starting frontend uptime=$(cut -d ' ' -f1 /proc/uptime 2>/dev/null || echo unknown)"
  "$BIN" "$@" >>"$LOG_FILE" 2>&1
  rc=$?
  log_line "[launcher] frontend exited rc=$rc"
  return "$rc"
}

launch_requested_game() {
  if [ ! -f "$REQUEST" ]; then
    log_line "[launcher] no launch request found"
    return 1
  fi
  rom="$(sed -n '1p' "$REQUEST")"
  core_choice="$(sed -n '2p' "$REQUEST")"
  if [ -z "$rom" ] || [ ! -f "$rom" ]; then
    log_line "[launcher] rom missing: $rom"
    rm -f "$REQUEST"
    return 1
  fi
  core_so="$(core_for_choice "$core_choice")"
  core_path="$CORES_DIR/$core_so"
  if [ ! -f "$core_path" ]; then
    log_line "[launcher] core missing: $core_path (choice=$core_choice)"
    rm -f "$REQUEST"
    return 1
  fi
  log_line "[launcher] launching rom=$rom core=$core_so"
  XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/var/run}" \
    WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}" \
    SDL_VIDEODRIVER=wayland SDL_AUDIODRIVER=alsa \
    "$RA_BIN" -L "$core_path" "$rom" >>"$LOG_FILE" 2>&1
  rc=$?
  log_line "[launcher] RetroArch exited rc=$rc"
  rm -f "$REQUEST"
  return "$rc"
}

if [ ! -x "$BIN" ]; then
  echo "PegasusG by ROC binary missing: $BIN" >&2
  exit 4
fi
if [ ! -x "$RA_BIN" ]; then
  echo "RetroArch missing: $RA_BIN" >&2
  exit 5
fi

trim_log
printf '\n===== %s =====\n' "$(date '+%F %T' 2>/dev/null || date)" >>"$LOG_FILE"
log_line "[launcher] loong launcher enter roots=$CONTENT_ROOTS"

first_frontend=1
while :; do
  if [ "$first_frontend" -eq 1 ]; then
    run_frontend "$@"
    rc=$?
    first_frontend=0
  else
    run_frontend --restore-ui
    rc=$?
  fi
  if [ "$rc" -eq 20 ]; then
    launch_requested_game || true
    continue
  fi
  # Exit codes 21..25 are H700 suspend/power flows; on LoongOS just exit.
  if [ "$rc" -ge 21 ] && [ "$rc" -le 25 ]; then
    log_line "[launcher] power flow rc=$rc unsupported on LoongOS, exiting"
  fi
  exit "$rc"
done
