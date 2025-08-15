local Gio = require("lgi").require("Gio")
local awful = require("awful")
local capi = { awesome = awesome, client = client }
local Screenshot = require("service.screenshot")
local Menu = require("ui.menu")
local Launcher = require("ui.launcher")
local Powermenu = require("ui.powermenu")
local Control_panel = require("ui.control_panel")
local Day_info_panel = require("ui.day_info_panel")
local Media_panel = require("ui.media_panel")
local mod = "Mod4"
awful.mouse.snap.edge_enabled = false

awful.mouse.append_global_mousebindings {
	awful.button({}, 3, function()
		Menu.get_default():toggle_desktop_menu()
	end),
	awful.button({}, 4, awful.tag.viewprev),
	awful.button({}, 5, awful.tag.viewnext)
}

awful.keyboard.append_global_keybindings {
	awful.key({ mod }, "Tab", function()
		awful.client.focus.byidx(1)
		if capi.client.focus then
			capi.client.focus:raise()
		end
	end),
	awful.key({ mod, "Shift" }, "Tab", function()
		awful.client.focus.byidx(-1)
		if capi.client.focus then
			capi.client.focus:raise()
		end
	end),
	awful.key({ mod, "Control" }, "Tab", function()
		local restored = awful.client.restore()
		if restored then
			capi.client.focus = restored
			capi.client.focus:raise()
		end
	end),
	awful.key {
		modifiers = { mod },
		keygroup = "numrow",
		on_press = function(index)
			local screen = awful.screen.focused()
			local tag = screen.tags[index]
			if tag then
				tag:view_only()
			end
		end
	},
	awful.key {
		modifiers = { mod, "Control" },
		keygroup = "numrow",
		on_press = function(index)
			local screen = awful.screen.focused()
			local tag = screen.tags[index]
			if tag then
				awful.tag.viewtoggle(tag)
			end
		end
	},
	awful.key {
		modifiers = { mod, "Shift" },
		keygroup = "numrow",
		on_press = function(index)
			if capi.client.focus then
				local tag = capi.client.focus.screen.tags[index]
				if tag then
					capi.client.focus:move_to_tag(tag)
				end
			end
		end
	},
	awful.key {
		modifiers = { mod, "Control", "Shift" },
		keygroup = "numrow",
		on_press = function(index)
			if capi.client.focus then
				local tag = capi.client.focus.screen.tags[index]
				if tag then
					capi.client.focus:toggle_tag(tag)
				end
			end
		end
	},
	awful.key {
		modifiers = { mod },
		keygroup = "numpad",
		on_press = function(index)
			local t = awful.screen.focused().selected_tag
			if t then
				t.layout = t.layouts[index] or t.layout
			end
		end
	},
	awful.key({ mod }, "s", function()
		awful.client.swap.byidx(1)
	end),
	awful.key({ mod, "Shift" }, "s", function()
		awful.client.swap.byidx(-1)
	end),
	awful.key({ mod }, "a", function()
		awful.tag.incnmaster(1, nil, true)
	end),
	awful.key({ mod, "Shift" }, "a", function()
		awful.tag.incnmaster(-1, nil, true)
	end),
	awful.key({ mod }, "w", function()
		awful.tag.incncol(1, nil, true)
	end),
	awful.key({ mod, "Shift" }, "w", function()
		awful.tag.incncol(-1, nil, true)
	end),
	awful.key({ mod }, "e", function()
		awful.tag.incmwfact(0.05)
	end),
	awful.key({ mod, "Shift" }, "e", function()
		awful.tag.incmwfact(-0.05)
	end),
	awful.key({ mod, "Control" }, "e", function()
		awful.tag.setmwfact(0.5)
	end),
	awful.key({ mod, }, "space", function()
		awful.layout.inc(1)
	end),
	awful.key({ mod, "Shift" }, "r", function()
		capi.awesome.restart()
	end),
	awful.key({ mod }, "Return", function()
		local app = Gio.AppInfo.get_default_for_uri_scheme('terminal')
		if app then awful.spawn(app:get_executable()) end
	end),
	awful.key({ mod }, "d", function()
		Launcher.get_default():show()
	end),
	awful.key({ mod }, "f", function()
		Control_panel.get_default():toggle()
	end),
	awful.key({ mod }, "g", function()
		Day_info_panel.get_default():toggle()
	end),
	awful.key({ mod }, "h", function()
		Media_panel.get_default():toggle()
	end),
	awful.key({ mod }, "q", function()
		Powermenu.get_default():show()
	end),
	awful.key({}, "Print", function()
		Screenshot.get_default():take_full()
	end),
	awful.key({"Shift"}, "Print", function()
		Screenshot.get_default():take_select()
	end)
}

capi.client.connect_signal("request::default_mousebindings", function()
	awful.mouse.append_client_mousebindings {
		awful.button({}, 1, function(c)
			c:activate { context = "mouse_click" }
		end),
		awful.button({ mod }, 1, function(c)
			c:activate { context = "mouse_click", action = "mouse_move" }
		end),
		awful.button({ mod }, 3, function(c)
			c:activate { context = "mouse_click", action = "mouse_resize" }
		end)
	}
end)

capi.client.connect_signal("request::default_keybindings", function()
	awful.keyboard.append_client_keybindings {
		awful.key({ mod }, "z", function(c)
			c:kill()
		end),
		awful.key({ mod }, "x", function(c)
			c.maximized = not c.maximized
			c:raise()
		end),
		awful.key({ mod }, "c", function(c)
			c.minimized = true
		end),
		awful.key({ mod }, "v", function(c)
			c.fullscreen = not c.fullscreen
			c:raise()
		end),
		awful.key({ mod }, "b", function(c)
			c.ontop = not c.ontop
			c:raise()
		end),
		awful.key({ mod }, "m", function(c)
			Menu.get_default():toggle_client_menu(c)
		end),
		awful.key({ mod, "Control" }, "Return", function(c)
			c:swap(awful.client.getmaster())
		end)
	}
end)
