-- Modus base Hyprland configuration (Ubuntu 24.04)
-- Minimal: Modus sets most settings via config/hypr/modus.lua

-- Monitors: auto-detect
hl.monitor(",preferred,auto,1")

-- Input defaults
hl.config({
	input = {
		kb_layout = "us",
		follow_mouse = 1,
	},
	misc = {
		disable_hyprland_logo = true,
	},
})

-- Modus shell (panel, dock, spotlight, lockscreen, hypridle, cliphist...)
dofile(os.getenv("HOME") .. "/.config/Modus/config/hypr/modus.lua")
