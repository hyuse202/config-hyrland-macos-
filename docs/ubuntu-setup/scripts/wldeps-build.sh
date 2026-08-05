#!/bin/bash
# Build newer wayland stack for Hyprland v0.56.1 (Ubuntu noble is too old)
set -euo pipefail
cd "$HOME/rice-install"
NPROC=$(nproc)
MESON="$HOME/.local/bin/meson"   # sudo must use the NEW meson, not /usr/bin/meson

# 1. wayland 1.26.0
[ -d wayland ] || git clone --quiet --depth 1 --branch 1.26.0 https://gitlab.freedesktop.org/wayland/wayland.git wayland
cd wayland && rm -rf build
  $MESON setup build -Dprefix=/usr -Dtests=false -Ddocumentation=false -Ddtd_validation=false >/tmp/wayland.log 2>&1
  $MESON compile -C build >>/tmp/wayland.log 2>&1
sudo -n $MESON install -C build >>/tmp/wayland.log 2>&1
cd "$HOME/rice-install"
echo "WAYLAND_OK: $(pkg-config --modversion wayland-server)"

# 2. wayland-protocols 1.49
[ -d wayland-protocols ] || git clone --quiet --depth 1 --branch 1.49 https://gitlab.freedesktop.org/wayland/wayland-protocols.git wayland-protocols
cd wayland-protocols && rm -rf build
  $MESON setup build -Dprefix=/usr >/tmp/wlproto.log 2>&1
sudo -n $MESON install -C build >>/tmp/wlproto.log 2>&1
cd "$HOME/rice-install"
echo "WLPROTO_OK: $(pkg-config --modversion wayland-protocols)"

# 3. libxkbcommon 1.13.2
[ -d libxkbcommon ] || git clone --quiet --depth 1 --branch xkbcommon-1.13.2 https://github.com/xkbcommon/libxkbcommon.git libxkbcommon
cd libxkbcommon && rm -rf build
  $MESON setup build -Dprefix=/usr -Denable-docs=false -Denable-tools=false >/tmp/xkb.log 2>&1
  $MESON compile -C build >>/tmp/xkb.log 2>&1
sudo -n $MESON install -C build >>/tmp/xkb.log 2>&1
cd "$HOME/rice-install"
echo "XKB_OK: $(pkg-config --modversion xkbcommon)"

# 4. libinput 1.31.3 (replace 1.27.1)
[ -d libinput ] || git clone --quiet --depth 1 --branch 1.31.3 https://gitlab.freedesktop.org/libinput/libinput.git libinput
cd libinput && rm -rf build
  $MESON setup build -Dprefix=/usr -Dtests=false -Ddocumentation=false -Dlibwacom=true >/tmp/libinput2.log 2>&1
  $MESON compile -C build >>/tmp/libinput2.log 2>&1
sudo -n $MESON install -C build >>/tmp/libinput2.log 2>&1
cd "$HOME/rice-install"
echo "LIBINPUT_OK: $(pkg-config --modversion libinput)"

sudo -n ldconfig
echo ALL_WLDEPS_DONE
