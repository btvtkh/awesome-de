local utf8 = require("lua-utf8")
local lgi = require("lgi")
local Gtk = lgi.require("Gtk", "3.0")
local Gdk = lgi.require("Gdk", "3.0")
local awful = require("awful")
local textbox = require("wibox.widget.textbox")
local gtable = require("gears.table")
local gstring = require("gears.string")
local gcolor = require("gears.color")

local input = {}

local function pttostr(int)
	local str = tostring(int)
	return str:match("pt$") and str or str .. "pt"
end

local function markup(args)
	local focused = args.focused or false
	local text = args.input or ""
	local placeholder = args.placeholder or ""
	local obscure_char = args.obscure_char or "*"
	local cursor_pos = args.cursor_index or 1
	local selectall = args.selectall or false
	local obscure = args.obscure or false
	local highlighter = args.highlighter or nil

	local cursor_char, spacer, text_start, text_end

	if obscure and text ~= "" then
		text = utf8.gsub(text, "(.)", obscure_char)
	end

	if text == "" and placeholder ~= "" then
		text_start = ""
		cursor_char = gstring.xml_escape(utf8.sub(placeholder, cursor_pos, cursor_pos))
		text_end = gstring.xml_escape(utf8.sub(placeholder, 2))
		spacer = ""
	elseif selectall then
		text_start = ""
		cursor_char = text == "" and " " or gstring.xml_escape(text)
		text_end = ""
		spacer = " "
	elseif utf8.len(text) < cursor_pos then
		text_start = gstring.xml_escape(text)
		cursor_char = " "
		text_end = ""
		spacer = ""
	else
		text_start = gstring.xml_escape(utf8.sub(text, 1, cursor_pos - 1))
		cursor_char = gstring.xml_escape(utf8.sub(text, cursor_pos, cursor_pos))
		text_end = gstring.xml_escape(utf8.sub(text, cursor_pos + 1))
		spacer = " "
	end

	if text ~= "" and highlighter then
		text_start, text_end = highlighter(text_start, text_end)
	end

	local cursor_bg = gcolor.ensure_pango_color(args.cursor_bg)
	local cursor_fg = gcolor.ensure_pango_color(args.cursor_fg)
	local placeholder_fg = gcolor.ensure_pango_color(args.placeholder_fg)
	local unfocused_fg = gcolor.ensure_pango_color(args.unfocused_fg)

	local font = args.font_name and " font='" .. args.font_name .. "'" or ""
	local size = args.font_size and " size='" .. pttostr(args.font_size) .. "'" or ""
	local style = args.font_style and " style='" .. args.font_style .. "'" or ""
	local weight = args.font_weight and " weight='" .. tostring(args.font_weight) .. "'" or ""

	return "<span" .. font .. size .. style .. weight .. ">"
		.. (focused and
				(text_start
				.. "<span background='" .. cursor_bg .. "' foreground='" .. cursor_fg .. "'>" .. cursor_char .. "</span>"
				.. (text == "" and "<span foreground='" .. placeholder_fg .. "'>" .. text_end .. "</span>" or text_end)
				.. spacer)
			or
				("<span foreground='" .. unfocused_fg .. "'>" .. text_start .. cursor_char .. text_end .. spacer .. "</span>")
		)
		.. "</span>"
end

local function run_keygrabber(self)
	local wp = self._private
	wp.keygrabber = awful.keygrabber.run(function(mods, key, event)
		local mod = {}
		for _, v in ipairs(mods) do
			mod[v] = true
		end

		if event ~= "press" then
			self:emit_signal("key-released", mod, key)
			return
		end

		self:emit_signal("key-pressed", mod, key)

		if mod.Control then
			if key == "a" then
				if wp.input ~= "" then
					wp.cursor_index = 1
					wp.selectall = true
				end
			elseif key == "c" then
				if wp.selectall then
					wp.clipboard:set_text(wp.input, -1)
					wp.cursor_index = utf8.len(wp.input) + 1
					wp.selectall = false
				end
			elseif key == "v" then
				wp.clipboard:request_text(function(_, text)
					if text then
						if wp.selectall then
							wp.input = text
							wp.selectall = false
						else
							wp.input = utf8.sub(wp.input, 1, wp.cursor_index - 1) ..
								text .. utf8.sub(wp.input, wp.cursor_index)
						end
						wp.cursor_index = wp.cursor_index + utf8.len(text)
						self:emit_signal("input-changed", wp.input)
						self:set_markup(markup(self._private))
					end
				end)
			end
		else
			if key == "Escape" then
				wp.selectall = false
				self:unfocus()
			elseif key == "Return" then
				wp.selectall = false
				self:emit_signal("executed", wp.input)
				self:unfocus()
			elseif key == "Home" then
				wp.selectall = false
				wp.cursor_index = 1
			elseif key == "End" then
				wp.selectall = false
				wp.cursor_index = utf8.len(wp.input) + 1
			elseif key == "Left" then
				wp.selectall = false
				if wp.cursor_index > 1 then
					wp.cursor_index = wp.cursor_index - 1
				end
			elseif key == "Right" then
				if wp.selectall then
					wp.selectall = false
					wp.cursor_index = utf8.len(wp.input) + 1
				elseif wp.cursor_index < utf8.len(wp.input) + 1 then
					wp.cursor_index = wp.cursor_index + 1
				end
			elseif key == "Delete" then
				if wp.selectall then
					wp.input = ""
					wp.selectall = false
					self:emit_signal("input-changed", wp.input)
				elseif wp.cursor_index < utf8.len(wp.input) + 1 then
					wp.input = utf8.sub(wp.input, 1, wp.cursor_index - 1) ..
						utf8.sub(wp.input, wp.cursor_index + 1)
					self:emit_signal("input-changed", wp.input)
				end
			elseif key == "BackSpace" then
				if wp.selectall then
					wp.input = ""
					wp.selectall = false
					self:emit_signal("input-changed", wp.input)
				elseif wp.cursor_index > 1 then
					wp.input = utf8.sub(wp.input, 1, wp.cursor_index - 2) ..
						utf8.sub(wp.input, wp.cursor_index)
					wp.cursor_index = wp.cursor_index - 1
					self:emit_signal("input-changed", wp.input)
				end
			elseif utf8.len(key) == 1 then
				if wp.selectall then
					wp.input = key
					wp.selectall = false
				else
					wp.input = utf8.sub(wp.input, 1, wp.cursor_index - 1) .. key ..
						utf8.sub(wp.input, wp.cursor_index)
					wp.cursor_index = wp.cursor_index + 1
				end
				self:emit_signal("input-changed", wp.input)
			end
		end

		self:set_markup(markup(self._private))
	end)
end

local properties = {
	"input",
	"selectall",
	"obscure",
	"unfocused_fg",
	"placeholder",
	"placeholder_fg",
	"cursor_fg",
	"cursor_bg",
	"obscure_char",
	"highlighter",
	"font_name",
	"font_size",
	"font_weight",
	"font_style"
}

for _, prop_name in ipairs(properties) do
	input["set_" .. prop_name] = function(self, value)
		local changed = self._private[prop_name] ~= value
		self._private[prop_name] = value

		if changed then
			self:set_markup(markup(self._private))
		end
	end

	input["get_" .. prop_name] = function(self)
		return self._private[prop_name] == nil
			and properties[prop_name]
			or self._private[prop_name]
	end
end

function input:get_focused()
	return self._private.focused
end

function input:focus()
	local wp = self._private
	if wp.focused then return end
	wp.focused = true
	run_keygrabber(self)
	self:set_markup(markup(self._private))
	self:emit_signal("focused")
end

function input:unfocus()
	local wp = self._private
	if not wp.focused then return end
	wp.focused = false
	awful.keygrabber.stop(wp.keygrabber)
	self:emit_signal("unfocused")
end

function input:get_cursor_index()
	return self._private.cursor_index
end

function input:set_cursor_index(index)
	local wp = self._private
	wp.cursor_index = math.max(math.min(utf8.len(wp.input), index), 1)
	self:set_markup(markup(self._private))
end

local function new(args)
	args = args or {}

	args.obscure = args.obscure or false
	args.placeholder = args.placeholder or ""
	args.obscure_char = args.obscure_char or "*"
	args.cursor_bg = args.cursor_bg or "#ffffff"
	args.cursor_fg = args.cursor_fg or "#000000"
	args.placeholder_fg = args.placeholder_fg or "#373737"
	args.unfocused_fg = args.unfocused_fg or "#373737"
	args.highlighter = args.highlighter

	local ret = textbox()
	gtable.crush(ret._private, args)
	gtable.crush(ret, input, true)

	local wp = ret._private

	wp.focused = false
	wp.input = ""
	wp.cursor_index = 1
	wp.selectall = false
	wp.clipboard = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD)

	ret:set_ellipsize("start")

	return ret
end

return setmetatable({ new = new }, { __call = function(_, ...) return new(...) end })
