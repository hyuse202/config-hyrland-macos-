#!/bin/bash
# Build Hyprland v0.56.1 + ecosystem from release tags (gcc-15 compatible)
set -euo pipefail
export CC=gcc-15
export CXX=g++-15
# NOTE: cmake 3.28 (Ubuntu) doesn't know C++26 (hyprutils v0.14.0 requires it);
# -std=c++26 is forced via -DCMAKE_CXX_FLAGS in cmake_build() below (env var
# CMAKE_CXX_FLAGS is NOT picked up by cmake, only -D works).
CMAKE="$HOME/.local/bin/cmake"   # sudo must use the NEW cmake (4.4.2), not /usr/bin/cmake
BUILD="$HOME/rice-install/hyprwm"
mkdir -p "$BUILD"
cd "$BUILD"
NPROC=$(nproc)

clone_tag() {  # dir repo tag
  if [ ! -d "$1" ]; then
    git clone --quiet --depth 1 --branch "$3" "https://github.com/hyprwm/$2.git" "$1"
  fi
}

cmake_build() {
  local dir="$1"
  echo "== building $dir =="
  cd "$BUILD/$dir"
  rm -rf build
  $CMAKE -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_CXX_FLAGS="-std=c++26" \
        -DPython3_EXECUTABLE=/usr/bin/python3 >/dev/null
  $CMAKE --build build -j"$NPROC" >/dev/null
  sudo -n $CMAKE --install build >/dev/null
  cd "$BUILD"
}

clone_tag hyprutils hyprutils v0.14.0; cmake_build hyprutils
clone_tag hyprlang hyprlang v0.6.8; cmake_build hyprlang
clone_tag hyprcursor hyprcursor v0.1.13; cmake_build hyprcursor
clone_tag hyprgraphics hyprgraphics v0.5.1; cmake_build hyprgraphics
clone_tag hyprwayland-scanner hyprwayland-scanner v0.4.6; cmake_build hyprwayland-scanner
clone_tag aquamarine aquamarine v0.14.0; cmake_build aquamarine
clone_tag Hyprland Hyprland v0.56.1; cmake_build Hyprland
clone_tag hypridle hypridle v0.1.8; cmake_build hypridle
clone_tag hyprpicker hyprpicker v0.4.7; cmake_build hyprpicker
clone_tag hyprsunset hyprsunset v0.4.0; cmake_build hyprsunset
clone_tag xdg-desktop-portal-hyprland xdg-desktop-portal-hyprland v1.4.1; cmake_build xdg-desktop-portal-hyprland

sudo -n ldconfig
echo HYPRLAND_BUILD_DONE
