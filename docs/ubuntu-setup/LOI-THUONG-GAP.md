# Lỗi hay gặp + cách sửa (Ubuntu 24.04, build Hyprland v0.56.1 + Modus)

Mọi lỗi đã gặp trong quá trình cài, theo thứ tự xuất hiện. Format: **Triệu chứng →
Nguyên nhân → Cách sửa**.

## Toolchain / C++

### 1. `error: 'print' is not a member of 'std'` (C++23 `<print>`)
- **Nguyên nhân:** gcc-13 mặc định của noble quá cũ.
- **Sửa:** cài gcc-14: `sudo apt install gcc-14 g++-14`.

### 2. `error: no member named 'native_handle'` trong hyprutils (C++26)
- **Nguyên nhân:** hyprutils v0.14.0+ dùng `std::ofstream::native_handle()` — chuẩn **C++26**;
  gcc-14 không đủ (thực ra cần gcc-15 + cờ C++26).
- **Sửa:** cài **gcc-15/g++-15** từ PPA (noble không có gcc-15):
  ```bash
  sudo add-apt-repository ppa:ubuntu-toolchain-r/test && sudo apt update
  sudo apt install -y gcc-15 g++-15
  ```

### 3. Build vẫn lỗi native_handle dù đã g++-15
- **Nguyên nhân:** cmake 3.28 (Ubuntu) **không nhận diện chuẩn C++26** → tự truyền
  `-std=gnu++23` (xác nhận trong `build/CMakeFiles/*/flags.make`).
- **Sửa:** truyền trực tiếp `-DCMAKE_CXX_FLAGS="-std=c++26"` cho cmake. ⚠ Biến env
  `CMAKE_CXX_FLAGS` **bị cmake 3.28 bỏ qua** — chỉ `-D` mới vào flags.make.

### 4. `c++: error: unrecognized command-line option '-std=c++26'`
- **Nguyên nhân:** cmake dùng `/usr/bin/c++` (gcc-13) vì quên `export CC=gcc-15 CXX=g++-15`.
- **Sửa:** `export CC=gcc-15 CXX=g++-15` trước khi cmake configure.

### 5. `sudo cmake --install` / `sudo meson install` dùng nhầm version cũ
- **Nguyên nhân:** PATH của root không có `~/.local/bin` → sudo gọi cmake 3.28 cũ
  đọc build.dat của cmake 4.x → lỗi "references functions that don't exist".
- **Sửa:** luôn dùng đường dẫn tuyệt đối: `sudo ~/.local/bin/cmake --install build`
  (meson tương tự: `sudo ~/.local/bin/meson install -C build`).

## Dep thiếu / quá cũ

### 6. `The following required packages were not found: ...`
- **Nguyên nhân:** thiếu dep. Gặp lần lượt: tomlplusplus, xcb-util, xcb-xinerama,
  pugixml (hyprwayland-scanner), glslang (shader compiler), readline (hyprctl),
  xcb-errors, hyprland-protocols, hyprwire, sdbus-c++.
- **Sửa:**
  ```bash
  sudo apt install -y libtomlplusplus-dev libxcb-util-dev libxcb-xinerama0-dev \
    libpugixml-dev glslang-dev libreadline-dev libmuparser-dev libei-dev
  ```
  Riêng **xcb-errors**: không có gói apt → build từ source (xem README bước 3).
  Riêng **hyprland-protocols / hyprwire**: repo hyprwm build từ source (xem README).

### 7. `xkbcommon>=1.11.0`, `wayland-server>=1.22.91`, `wayland-protocols>=1.49`, `libinput>=1.29`, `libeis-1.0`, `muparser` — Hyprland v0.56.1 không configure được
- **Nguyên nhân:** noble quá cũ (xkbcommon 1.4, wayland 1.22.0, protocols 1.34,
  libinput 1.25, thiếu libeis/muparser).
- **Sửa:**
  - `libeis-dev libmuparser-dev` → có trong apt noble.
  - wayland 1.26 / wayland-protocols 1.49 / libxkbcommon 1.13.2 / libinput 1.31.3 →
    build từ source bằng `wldeps-build.sh` (đã gồm cả thứ tự: wayland trước, xkbcommon sau).

### 8. `libinput>=1.29` vẫn báo thiếu sau khi build libinput 1.31.3
- **Nguyên nhân:** thư mục `libinput/` cũ (bản 1.27.1) bị tái sử dụng — script
  `[ -d libinput ] || git clone` bỏ qua clone nên build lại đúng bản cũ.
- **Sửa:** `rm -rf libinput && git clone --depth 1 --branch 1.31.3 ...` rồi build lại.

### 9. `libinput>=1.26` (aquamarine) trong khi noble có 1.25.0
- **Nguyên nhân:** noble ship libinput 1.25.
- **Sửa:** build 1.27.1+ từ source (meson, soname `.so.10` giữ ABI tương thích).

### 10. `None of the required 'lua55;lua5.5;lua-55;lua-5.5;lua>=5.5;lua<5.6' found`
- **Nguyên nhân:** Hyprland v0.56.1 dùng Lua config API → cần **Lua ≥ 5.5**; noble chỉ có 5.4.
- **Sửa:** build Lua 5.5.1 từ source + tự viết `lua5.5.pc` (xem README bước 3;
  file pc mẫu trong `configs/lua5.5.pc`).

### 11. `fatal error: lua.hpp: No such file or directory`
- **Nguyên nhân:** Hyprland include `<lua.hpp>` (wrapper C++) — bản build tay chỉ cài
  lua.h/lualib.h/lauxlib.h.
- **Sửa:** tạo `/usr/include/lua.hpp`:
  ```bash
  printf 'extern "C" {\n#include "lua.h"\n#include "lualib.h"\n#include "lauxlib.h"\n}\n' | sudo tee /usr/include/lua.hpp
  ```

### 12. `'class sdbus::IConnection' has no member named 'processPendingEvent'` / `'ServiceName' is not a member of 'sdbus'`
- **Nguyên nhân:** hypridle v0.1.8 dùng API sdbus-c++ **2.x**; noble có 1.4.0.
- **Sửa:** build sdbus-c++ 2.3.1 từ source. ⚠ Bản ≥ 2.x dùng **CMake**, không phải meson.

### 13. `- libpipewire-0.3>=1.1.82` (xdph)
- **Nguyên nhân:** noble có pipewire 1.0.5.
- **Sửa:** build pipewire 1.6.8 client từ source (meson, xem README bước 3 —
  chú ý option bị đổi tên ở 1.6.x).

### 14. `Could not find a package configuration file provided by "QT"` (hyprland-share-picker)
- **Nguyên nhân:** thiếu Qt6.
- **Sửa:** `sudo apt install -y qt6-base-dev`.

### 15. `error: 'starts_with' is not a member of 'std::ranges'` — MiscFunctions.cpp:841
- **Nguyên nhân:** **libstdc++ của GCC 15 chưa implement** `std::ranges::starts_with`
  (P1659R3; chỉ libc++/Clang có). Test tối thiểu `g++-15 -std=c++26` cũng fail —
  không phải lỗi cờ build.
- **Sửa:** patch `Hyprland/src/helpers/MiscFunctions.cpp` — thay fold expression
  `(... || std::ranges::starts_with(str_view, prefixes))` bằng lambda so sánh từng ký tự
  (semantics giữ nguyên: case-insensitive "true/yes/on"). Xem git history của repo này.

## Cấu trúc / build system

### 16. `The source directory .../subprojects/udis86 does not contain a CMakeLists.txt`
- **Nguyên nhân:** git submodules của Hyprland chưa init (udis86, tracy).
- **Sửa:** `cd hyprwm/Hyprland && git submodule update --init --recursive`.

### 17. `SyntaxError: invalid syntax` — `type ClassMember = str` (generateLuaStubs.py)
- **Nguyên nhân:** cmake chọn **python3.11 của uv** (`~/.local/bin/python3.11`) làm
  `Python3_EXECUTABLE` — PEP 695 type-alias cần Python ≥ 3.12.
- **Sửa:** thêm `-DPython3_EXECUTABLE=/usr/bin/python3` khi cmake configure.

### 18. `ERROR: Unknown option: "enable-tests"` (libxkbcommon)
- **Nguyên nhân:** xkbcommon không có option `enable-tests` (chỉ `enable-tools`,
  `enable-docs`, `enable-x11`, `enable-wayland`, `enable-xkbregistry`, ...).
- **Sửa:** dùng `-Denable-docs=false -Denable-tools=false`.

### 19. `ERROR: Unknown option: "pipewire-pulse"` / `Option "jack-devel" value disabled is not boolean` (pipewire)
- **Nguyên nhân:** pipewire 1.6.x đổi/bỏ một số option; `jack-devel` là feature option.
- **Sửa:** bỏ các option không còn tồn tại; không set `-Djack-devel=disabled`.
  Bật ít option quá (vd `-Dspa-plugins=disabled`) → lỗi `Unknown variable plugin_dependencies`
  → dùng bộ option tối thiểu trong README bước 3.

### 20. `You have uninitialized git submodules` khi autogen xcb-errors
- **Nguyên nhân:** repo cần submodule `m4`.
- **Sửa:** `git submodule update --init` trước `./autogen.sh`.

### 21. `Permission denied` khi chạy script .sh
- **Sửa:** `chmod +x script.sh` (hoặc gọi `bash script.sh`).

### 22. Lua: `multiple definition of 'main'` khi build liblua.so
- **Nguyên nhân:** `gcc -shared *.o` gồm cả `lua.o` + `luac.o` (cả hai đều có `main`).
- **Sửa:** loại 2 file đó khỏi danh sách object: `ls *.o | grep -vE "^(lua|luac)\.o$"`.

### 23. `bash: meson setup ... ERROR: Neither source directory 'build' ... contain meson.build`
- **Nguyên nhân:** tưởng sdbus-cpp dùng meson — bản 2.x dùng **CMake**.
- **Sửa:** dùng cmake (xem #12).

## Modus

### 24. Lock screen lỗi thiếu module (PAM)
- **Nguyên nhân:** python-pam 2.x không khai báo dep `six`.
- **Sửa:** `cd ~/.config/Modus && uv add six`.

### 25. `GtkSessionLock require_version('GtkSessionLock','1.0')` fail khi test import
- **Nguyên nhân:** KHÔNG phải lỗi của Modus — typelib chỉ có namespace 0.1;
  `lock.py` import trực tiếp `from gi.repository import GtkSessionLock` (không gate version) → OK.
- **Sửa:** không cần sửa; bỏ qua lỗi này trong script test thủ công.

### 26. matugen v3.x fail / palette không khớp template
- **Nguyên nhân:** template `modus.css` viết theo palette cũ (`colors.red`, `colors.green`, ...)
  nhưng matugen v4 dùng `colors.error`, `colors.tertiary`, `primary/secondary/surface`.
- **Sửa:** giữ **matugen 4.1.0** + patch template:
  - `colors.red` → `colors.error.default`
  - `colors.green` → `colors.tertiary.default`
  - biến `*-dim` thêm `| set_lightness: -10.0`
  (diff nằm trong git history của repo này).

### 27. `post_hook` của matugen fail (`fabric-cli exec modus ...`)
- **Nguyên nhân:** bình thường khi Modus chưa chạy (không có app fabric để exec).
- **Sửa:** bỏ qua — colors.css vẫn được sinh đúng.

## Môi trường / hệ thống

### 28. apt không tải được từ archive.ubuntu.com (0 B/s)
- **Nguyên nhân:** mạng VN chặn/chậm archive.ubuntu.com.
- **Sửa:** chuyển sang mirror VN: `https://mirror.bizflycloud.vn/ubuntu/`.

### 29. Build chết giữa chừng vì hết sudo timestamp
- **Sửa:** kéo dài cache sudo:
  ```bash
  echo 'Defaults timestamp_timeout=120' | sudo tee /etc/sudoers.d/zz-timestamp-timeout
  sudo chmod 440 /etc/sudoers.d/zz-timestamp-timeout
  ```

### 30. Máy reboot → mất log /tmp, mất sudo cache, PPA/cmake vẫn còn
- **Nguyên nhân:** /tmp bị xoá khi reboot (bình thường).
- **Sửa:** không cần làm gì — binaries/libs ở /usr, configs ở ~/.config đều sống sót;
  chỉ cần `sudo -v` lại và chạy lại script (các repo đã clone sẵn).
