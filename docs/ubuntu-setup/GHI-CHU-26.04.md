# Cài trên Ubuntu 26.04 — điểm khác so với 24.04

Ubuntu 26.04 (LTS, 04/2026) ship toolchain đủ mới cho Hyprland v0.56.1 — phần lớn
các bước build-tay trong README sẽ bỏ được. Checklist rút gọn:

## Bỏ được (có sẵn trong 26.04 — kiểm tra lại bằng `apt-cache policy` / `pkg-config`)

| Thứ | Trên 24.04 phải build tay | 26.04 dự kiến |
|---|---|---|
| gcc-15 | PPA ubuntu-toolchain-r/test | mặc định (gcc-15) |
| cmake ≥ 3.30 | `uv tool install cmake` | apt (≥ 3.30) |
| wayland ≥ 1.22.91 | build 1.26 | apt (1.24+) |
| wayland-protocols ≥ 1.49 | build 1.49 | apt |
| libxkbcommon ≥ 1.11 | build 1.13.2 | apt |
| libinput ≥ 1.29 | build 1.31.3 | apt |
| lua ≥ 5.5 | build 5.5.1 + tự viết .pc + lua.hpp | apt (lua5.5) |
| pipewire ≥ 1.1.82 | build 1.6.8 | apt (1.2+) |
| sdbus-c++ 2.x | build 2.3.1 | apt (kiểm tra — trixie/sid có 2.x) |
| xcb-errors | build từ source | apt (libxcb-errors-dev) |
| Qt6 | apt qt6-base-dev | apt (có sẵn) |

## Vẫn phải làm (không đổi)

1. **Mirror VN ngay sau khi cài** (archive.ubuntu.com bị chặn từ mạng VN):
   `https://mirror.bizflycloud.vn/ubuntu/` (xem README bước 2).
2. Build **hyprwm stack** từ source bằng `scripts/hypr-build.sh` — với toolchain mới
   thì ~15-20 phút, không còn lỗi C++26. Nhớ 3 điểm mấu chốt:
   `-DCMAKE_CXX_FLAGS="-std=c++26"`, `-DPython3_EXECUTABLE=/usr/bin/python3`,
   `sudo ~/.local/bin/cmake` (đường dẫn tuyệt đối).
3. `git submodule update --init --recursive` trong Hyprland.
4. Patch MiscFunctions.cpp nếu vẫn lỗi `std::ranges::starts_with`
   (chỉ cần nếu 26.04 vẫn ship libstdc++ chưa có P1659R3 — khả năng thấp,
   GCC 16+ có thể đã implement).
5. **Modus** — toàn bộ bước 6-8 trong README: uv sync, `uv add six`, app-capture,
   libmenu_button_shim.so, matugen + template patch, SF Pro Rounded, MacTahoe,
   GDM entry, configs. Modus vẫn chỉ hỗ trợ Arch chính thức → cài tay như tài liệu.

## Trước khi wipe 24.04

- Config quan trọng đều đã nằm trong repo này (`docs/ubuntu-setup/configs/`) +
  git history (patch modus.css, pyproject.toml có six).
- Nhớ cả `~/.config/Modus` này (chính repo đang chứa tài liệu) — clone/pull lại sau.
- `~/.current.wall` + ảnh wallpaper mẫu nằm trong `src/assets/wallpaper_example/` của repo.
