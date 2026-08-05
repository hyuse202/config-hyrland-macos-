# Modus trên Ubuntu — Hướng dẫn cài đặt từ đầu

> Tài liệu này được viết dựa trên quá trình cài Modus + Hyprland v0.56.1 thành công
> trên **Ubuntu 24.04 (noble)** — build toàn bộ stack từ source vì noble quá cũ so với
> yêu cầu của Hyprland mới. Trên **Ubuntu 26.04** phần lớn bước 3 sẽ bỏ được
> (xem [GHI-CHU-26.04.md](./GHI-CHU-26.04.md)).
>
> Đi kèm: [LOI-THUONG-GAP.md](./LOI-THUONG-GAP.md) — mọi lỗi gặp phải + cách sửa.

## 1. Tổng quan phiên bản

| Thành phần | Phiên bản dùng | Ghi chú |
|---|---|---|
| Hyprland | **v0.56.1** | cần C++26 (gcc-15), Lua ≥ 5.5, wayland ≥ 1.22.91, xkbcommon ≥ 1.11, libinput ≥ 1.29 |
| hyprutils / hyprlang / hyprcursor | v0.14.0 / v0.6.8 / v0.1.13 | build trước Hyprland |
| hyprgraphics / hyprwayland-scanner / aquamarine | v0.5.1 / v0.4.6 / v0.14.0 | build trước Hyprland |
| hyprwire / hyprland-protocols | v0.3.1 / v0.7.0 | lib mới của hyprwm, build trước |
| hypridle / hyprpicker / hyprsunset / xdg-desktop-portal-hyprland | v0.1.8 / v0.4.7 / v0.4.0 / v1.4.1 | công cụ kèm |
| wayland / wayland-protocols / libxkbcommon / libinput | 1.26 / 1.49 / 1.13.2 / 1.31.3 | build từ source trên 24.04 |
| sdbus-c++ | 2.3.1 | hypridle cần API 2.x (24.04 chỉ có 1.4) |
| pipewire (client) | 1.6.8 | xdph cần ≥ 1.1.82 (24.04 có 1.0.5) |
| Lua | 5.5.1 | Hyprland cần ≥ 5.5 (24.04 chỉ có 5.4) |
| gcc/g++ | **15.2.0** (PPA ubuntu-toolchain-r/test) | 24.04 mặc định gcc-13 — quá cũ |
| cmake / meson | 4.4.2 / 1.11.2 (qua `uv tool install`) | 24.04 có cmake 3.28 (không biết C++26), meson 1.3 |
| matugen | 4.1.0 | `~/.local/bin/matugen` (binary release) |
| Modus | bản mới nhất (S4NKALP/Modus) | venv Python 3.14 qua uv |

## 2. Chuẩn bị

```bash
# (VN) apt mirror — archive.ubuntu.com bị chặn/chậm từ mạng VN
# Sửa /etc/apt/sources.list.d/ubuntu.sources → https://mirror.bizflycloud.vn/ubuntu/
sudo sed -i 's|http://archive.ubuntu.com/ubuntu|https://mirror.bizflycloud.vn/ubuntu|g' /etc/apt/sources.list.d/ubuntu.sources
sudo apt update

# Toolchain
sudo add-apt-repository ppa:ubuntu-toolchain-r/test && sudo apt update
sudo apt install -y gcc-15 g++-15 cmake ninja-build pkg-config meson bison flex \
  autoconf automake libtool xutils-dev
# cmake/meson mới hơn qua uv (quan trọng: dùng bản này, không dùng apt):
uv tool install cmake meson        # → ~/.local/bin/cmake (4.x), ~/.local/bin/meson (1.11+)
```

Layout thư mục giả định: mọi source build đặt trong `~/rice-install/`
(scripts trong `./scripts/` hardcode đường dẫn này).

## 3. Hạ tầng phải build từ source (chỉ 24.04; 26.04 có sẵn)

```bash
bash scripts/wldeps-build.sh   # wayland 1.26 + wayland-protocols 1.49 + libxkbcommon 1.13.2 + libinput 1.31.3
```

Ngoài ra, làm tay (không nằm trong script):

**Lua 5.5.1** — Hyprland cần lua ≥ 5.5:
```bash
cd ~/rice-install && curl -sO https://www.lua.org/ftp/lua-5.5.1.tar.gz && tar xzf lua-5.5.1.tar.gz
cd lua-5.5.1 && make -j$(nproc) MYCFLAGS="-fPIC" linux
cd src && libobjs=$(ls *.o | grep -vE "^(lua|luac)\.o$")   # ⚠ bỏ lua.o/luac.o (trùng main)
gcc -shared -Wl,-soname,liblua5.5.so.0 -o liblua5.5.so.0.1 $libobjs -lm -ldl
sudo install -m755 liblua5.5.so.0.1 /usr/lib/x86_64-linux-gnu/
sudo ln -sf liblua5.5.so.0.1 /usr/lib/x86_64-linux-gnu/liblua5.5.so.0
sudo ln -sf liblua5.5.so.0.1 /usr/lib/x86_64-linux-gnu/liblua5.5.so
sudo install -m644 lua.h luaconf.h lualib.h lauxlib.h /usr/include/
printf 'extern "C" {\n#include "lua.h"\n#include "lualib.h"\n#include "lauxlib.h"\n}\n' | sudo tee /usr/include/lua.hpp   # ⚠ Hyprland include <lua.hpp>
sudo install -m755 lua /usr/bin/lua5.5 && sudo ldconfig
# file pkg-config (bản sao trong ./configs/lua5.5.pc):
sudo install -m644 configs/lua5.5.pc /usr/lib/x86_64-linux-gnu/pkgconfig/lua5.5.pc
```

**sdbus-c++ 2.3.1** — hypridle v0.1.8 dùng API 2.x (`processPendingEvent`, `sdbus::ServiceName`, ...):
```bash
cd ~/rice-install && git clone --depth 1 --branch v2.3.1 https://github.com/Kistler-Group/sdbus-cpp.git
cd sdbus-cpp && CC=gcc-15 CXX=g++-15 ~/.local/bin/cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
~/.local/bin/cmake --build build -j$(nproc) && sudo ~/.local/bin/cmake --install build && sudo ldconfig
# ⚠ sdbus-cpp ≥ 2.x dùng CMake, KHÔNG phải meson
```

**pipewire 1.6.8 (client)** — xdph cần libpipewire ≥ 1.1.82:
```bash
cd ~/rice-install && git clone --depth 1 --branch 1.6.8 https://gitlab.freedesktop.org/pipewire/pipewire.git
cd pipewire && meson setup build -Dprefix=/usr -Dexamples=disabled -Dtests=disabled \
  -Dman=disabled -Ddocs=disabled -Dsession-managers=disabled
meson compile -C build -j$(nproc) && sudo ~/.local/bin/meson install -C build && sudo ldconfig
# ⚠ không dùng các option -Dpipewire-pulse/-Dpipewire-jack/-Dpipewire-v4l2 (đã bị bỏ ở 1.6.x)
# ⚠ -Djack-devel không phải boolean (feature option) — đừng set disabled
# ⚠ bật ít option quá (vd -Dspa-plugins=disabled) → lỗi meson "Unknown variable plugin_dependencies"
```

**xcb-errors 1.0.1** — Hyprland cần `xcb-errors`; noble không có `libxcb-errors-dev`:
```bash
sudo apt install -y xcb-proto   # cần cho autogen
cd ~/rice-install && git clone --depth 1 https://gitlab.freedesktop.org/xorg/lib/libxcb-errors.git
cd libxcb-errors && git submodule update --init   # ⚠ thiếu submodule m4 → autogen fail
./autogen.sh --prefix=/usr && make -j$(nproc) && sudo make install
```

**hyprland-protocols 0.7.0 + hyprwire 0.3.1**:
```bash
cd ~/rice-install/hyprwm
git clone --depth 1 https://github.com/hyprwm/hyprland-protocols.git
cd hyprland-protocols && ~/.local/bin/cmake -B build -DCMAKE_INSTALL_PREFIX=/usr \
  && ~/.local/bin/cmake --build build && sudo ~/.local/bin/cmake --install build
cd ~/rice-install/hyprwm && git clone --depth 1 --branch v0.3.1 https://github.com/hyprwm/hyprwire.git
cd hyprwire && CC=gcc-15 CXX=g++-15 ~/.local/bin/cmake -B build -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_CXX_FLAGS="-std=c++26" \
  && ~/.local/bin/cmake --build build -j$(nproc) && sudo ~/.local/bin/cmake --install build
```

**apt deps bổ sung** (noble): `libtomlplusplus-dev libxcb-util-dev libxcb-xinerama0-dev
libpugixml-dev libreadline-dev glslang-dev libsdbus-c++-dev` (bản apt chỉ là mồi —
sdbus thật thay bằng bản build 2.3.1 ở trên), `qt6-base-dev` (cho hyprland-share-picker),
`libsystemd-dev libmuparser-dev libei-dev`.

## 4. Build Hyprland stack

```bash
bash scripts/hypr-build.sh    # ~20-40 phút, build cả 11 repo theo thứ tự đúng
```

Thứ tự build (bắt buộc): hyprutils → hyprlang → hyprcursor → hyprgraphics →
hyprwayland-scanner → aquamarine → **Hyprland** → hypridle → hyprpicker →
hyprsunset → xdg-desktop-portal-hyprland.

Những điểm tối quan trọng (đều đã nằm trong script):
1. **`-DCMAKE_CXX_FLAGS="-std=c++26"`** — cmake 3.28/4.x **không nhận** biến env
   `CMAKE_CXX_FLAGS`; phải truyền qua `-D` mới vào được flags.make.
2. **`-DPython3_EXECUTABLE=/usr/bin/python3`** — nếu có python3.11 của uv trong
   `~/.local/bin`, cmake chọn nhầm nó → `generateLuaStubs.py` chết vì thiếu PEP 695
   (`type X = str`, Python ≥ 3.12).
3. **sudo phải dùng đường dẫn tuyệt đối**: `sudo ~/.local/bin/cmake --install` —
   PATH của root không có `~/.local/bin` → sudo gọi cmake 3.28 cũ đọc build.dat mới → fail.
4. Trong `hyprwm/Hyprland`: `git submodule update --init --recursive`
   (thiếu → lỗi "subprojects/udis86 does not contain a CMakeLists.txt").
5. **Patch `src/helpers/MiscFunctions.cpp`** — `std::ranges::starts_with` KHÔNG tồn tại
   trong libstdc++ của GCC 15 (P1659R3 chưa implement; chỉ libc++/Clang có).
   Đã thay bằng lambda so sánh từng ký tự (giữ nguyên semantics). Xem diff trong git history.

Verify sau build:
```bash
Hyprland --version   # Hyprland 0.56.1 ...
hyprctl version      # (chạy được dù chưa có instance — cần HYPRLAND_INSTANCE_SIGNATURE)
ls /usr/libexec/xdg-desktop-portal-hyprland /usr/share/xdg-desktop-portal/portals/hyprland.portal
```

## 5. Công cụ phụ trợ (build tay, nhanh)

- **uwsm 0.26.6** — trình khởi động session Wayland → `/usr/local/bin/uwsm`
- **awww 0.12.1** (+ `awww-daemon`) — Modus gọi cho ảnh nền → `/usr/local/bin/`
- **hyprshot** (hyprwm/hyprshot) — screenshot cho Modus
- **gtk-session-lock** (CuarzoSoftware/gtk-session-lock) — lock screen (Modus dùng GtkSessionLock)
- **swappy** — annotation ảnh chụp
- Tất cả build bằng `meson build && sudo meson install` (prefix /usr)

## 6. Cài Modus

```bash
git clone https://github.com/S4NKALP/Modus ~/.config/Modus
cd ~/.config/Modus
uv sync                       # uv tự chọn Python 3.14
uv add six                    # ⚠ python-pam 2.x thiếu dep này — lock screen lỗi nếu không có
```

**C-extension app-capture** (switcher của Modus):
```bash
cd src/window/switcher/app-capture
meson setup builddir && meson compile -C builddir
meson install -C builddir --destdir /    # cài typelib AppCapture-1.0 vào girepository-1.0
```

**globalmenu shim** (menu bar):
```bash
cd src/window/globalmenu
gcc -shared -fPIC -O2 -o libmenu_button_shim.so libmenu_button_shim.c \
  $(pkg-config --cflags --libs gtk+-3.0) -ldl
```

**Kiểm tra import lock screen**:
```bash
uv run python3 -c "from gi.repository import GtkSessionLock; import six, pam; print('OK')"
```

## 7. matugen — sinh màu

```bash
uv tool install matugen   # hoặc copy binary release 4.1.0 vào ~/.local/bin/
# config: ~/.config/matugen/config.toml (bản sao trong ./configs/)
# ⚠ template modus.css đã được PATCH (xem git diff của repo này):
#    colors.red  → colors.error.default     (+ set_lightness: -10.0 cho biến *-dim)
#    colors.green → colors.tertiary.default
#    (palette matugen v4 dùng error/tertiary/primary/secondary/surface thay vì red/green/blue/...)
ln -sf ~/.config/Modus/src/assets/wallpaper_example/example-1.png ~/.current.wall
matugen image ~/.current.wall --source-color-index 0
# → sinh ~/.config/Modus/src/styles/colors.css + ~/.config/Modus/config/hypr/colors.lua
# (post_hook fabric-cli fail là bình thường khi Modus chưa chạy)
```

## 8. Fonts & themes

- **SF Pro Rounded** — 92 file, cài từ DMG của Apple vào `~/.local/share/fonts/`
  (CSS của Modus chỉ dùng font này).
- **MacTahoe GTK theme + icons + cursors** (vinceliuice):
  `MacTahoe-gtk-theme/install.sh`, clone `MacTahoe-icon-theme` → `~/.local/share/icons/`
- gsettings (dùng chung cả GNOME lẫn Hyprland):
```bash
gsettings set org.gnome.desktop.interface gtk-theme MacTahoe-Dark
gsettings set org.gnome.desktop.interface icon-theme MacTahoe
gsettings set org.gnome.desktop.interface cursor-theme MacTahoe-cursors
gsettings set org.gnome.desktop.interface font-name "SF Pro Rounded 11"
```

## 9. Session GDM + configs

- `/usr/share/wayland-sessions/hyprland.desktop` (bản sao trong `./configs/`):
  `Exec=/usr/local/bin/uwsm start -- Hyprland` — cơ chế GDM → desktop entry → uwsm → systemd.
- `~/.config/hypr/hyprland.lua` (bản sao trong `./configs/`) — config Lua tối thiểu,
  cuối file `dofile(os.getenv("HOME") .. "/.config/Modus/config/hypr/modus.lua")`.
- `~/.config/hypr/hypridle.conf` → **symlink** vào `~/.config/Modus/config/hypr/hypridle.conf`.
- `~/.config/environment.d/10-modus.conf` (bản sao trong `./configs/`):
  PATH + `GTK_MODULES=appmenu-gtk-module` + `UBUNTU_MENUPROXY=1` (menu bar kiểu macOS).
- `~/.config/matugen/config.toml` (bản sao trong `./configs/`).

## 10. Lần chạy đầu tiên

1. Đăng xuất GNOME → GDM → chọn session **"Hyprland"** (bánh răng góc dưới phải).
2. Vào Hyprland: bấm **Super+W** để đổi wallpaper (awww + matugen tự sinh màu).
3. Nếu Modus không tự chạy:
   ```bash
   cd ~/.config/Modus && uv run python src/main.py
   ```
4. Quay lại GNOME bất cứ lúc nào: đăng xuất → chọn session cũ.

## 11. Xử lý sự cố

→ Xem [LOI-THUONG-GAP.md](./LOI-THUONG-GAP.md) — đầy đủ mọi lỗi + cách sửa.
