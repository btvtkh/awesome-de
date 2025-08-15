local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gtable = require("gears.table")
local shape = require("lib.shape")
local wicon = require("widgets.icon")
local icons = beautiful.icons
local capi = { mouse = mouse }
local dpi = beautiful.xresources.apply_dpi

local menu = {}

local keys = {
	up = { "Up" },
	down = { "Down" },
	left = { "Left" },
	right = { "Right" },
	exec = { "Return" },
	close = { "Escape" }
}

local function update_items(self)
	local wp = self._private
	local theme = wp.theme
	local items_layout = self.widget:get_children_by_id("items-layout")[1]
	for i, item in ipairs(items_layout.children) do
		if wp.select_index and i == wp.select_index then
			item:set_bg(theme.item_hover_bg)
			item:set_fg(theme.item_hover_fg)
		else
			item:set_bg(theme.item_bg)
			item:set_fg(theme.item_fg)
		end
	end
end

local function on_enter(self, index, args, type)
	if not index or not args then return end
	local wp = self._private

	wp.select_index = index
	update_items(self)

	if args.items then
		if not wp.children[index] then
			wp.children[index] = self.new(args, self)
		end

		if wp.active_child and wp.active_child ~= wp.children[index] then
			wp.active_child:hide()
		end

		wp.active_child = wp.children[index]

		if not wp.active_child.visible then
			wp.active_child:show()
		end
	else
		if wp.active_child then
			for i = 1, #wp.children do
				wp.children[i]:destroy()
			end
			wp.active_child:destroy()
		end
	end

	if not args.items and args.exec and type == "key" then
		args.exec()
		self:get_root():hide()
	end
end

local function run_keygrabber(self)
	local wp = self._private
	wp.keygrabber = awful.keygrabber.run(function(_, key, event)
		if event ~= "press" then return end
		if gtable.hasitem(keys.up, key) then
			self:back()
			update_items(self)
		elseif gtable.hasitem(keys.down, key) then
			self:next()
			update_items(self)
		elseif gtable.hasitem(keys.left, key) then
			self:hide()
		elseif gtable.hasitem(keys.right, key) then
			on_enter(self, wp.select_index, wp.args[wp.select_index], "key")
		elseif gtable.hasitem(keys.exec, key) then
			on_enter(self, wp.select_index, wp.args[wp.select_index], "key")
		elseif gtable.hasitem(keys.close, key) then
			self:get_root():hide()
		end
	end)
end

local function entry(self, index, args)
	local wp = self._private
	local theme = wp.theme

	local ret = wibox.widget {
		widget = wibox.container.background,
		forced_width = theme.item_width,
		forced_height = theme.item_height,
		shape = theme.item_shape,
		{
			id = "item-content",
			widget = wibox.container.margin,
			margins = theme.item_margins
		}
	}

	local rp = ret._private
	local item_content = ret:get_children_by_id("item-content")[1]

	if args.items then
		local item_widget = wibox.widget {
			layout = wibox.layout.fixed.horizontal,
			fill_space = true,
			{
				widget = wibox.widget.textbox,
				font = theme.item_font,
				markup = args.label
			},
			{
				widget = wibox.container.place,
				halign = "right",
				valign = "center",
				{
					id = "submenu-icon",
					widget = wicon,
					size = dpi(14),
					icon = icons.chevron_right
				}
			}
		}

		local submenu_icon = item_widget:get_children_by_id("submenu-icon")[1]

		rp.on_entry_fg = function(_, fg)
			submenu_icon:set_color(fg)
		end

		ret:connect_signal("property::fg", rp.on_entry_fg)

		item_content:set_widget(item_widget)
	else
		item_content:set_widget({
			widget = wibox.widget.textbox,
			font = theme.item_font,
			markup = args.label
		})
	end

	rp.on_mouse_enter = function()
		on_enter(self, index, args, "mouse")
	end

	ret:connect_signal("mouse::enter", rp.on_mouse_enter)

	ret:buttons {
		awful.button({}, 1, function()
			if not args.items and args.exec then
				args.exec()
				self:get_root():hide()
			end
		end)
	}

	return ret
end

local function set_coords(self)
	local wp = self._private
	local theme = wp.theme

	local m_coords = capi.mouse.coords()
	local m_workarea = capi.mouse.screen.workarea
	local m_workarea_hend = m_workarea.x + m_workarea.width
	local m_workarea_vend = m_workarea.y + m_workarea.height

	if not wp.parent then
		local width = theme.item_width + theme.margins * 2

		local self_items = #self.widget:get_children_by_id("items-layout")[1].children
		local self_height = theme.item_height * self_items
			+ theme.item_spacing * (self_items - 1)
			+ theme.margins * 2

		self:geometry({
			x = m_coords.x + width >= m_workarea_hend
				and m_workarea_hend - width
				or m_coords.x,
			y = m_coords.y + self_height >= m_workarea_vend
				and m_workarea_vend - self_height
				or m_coords.y
		})
	else
		local root = self:get_root()
		local parent = wp.parent
		local parent_wp = wp.parent._private
		local width = theme.item_width + theme.margins * 2

		local self_items = #self.widget:get_children_by_id("items-layout")[1].children
		local self_height = theme.item_height * self_items
			+ theme.item_spacing * (self_items - 1)
			+ theme.margins * 2

		local parent_items = #wp.parent.widget:get_children_by_id("items-layout")[1].children
		local parent_height = theme.item_height * parent_items
			+ theme.item_spacing * (parent_items - 1)
			+ theme.margins * 2

		local self_y = parent.y
			+ (parent_height - theme.margins * 2 - (parent_items - 1) * theme.item_spacing)
				/ parent_items * (parent_wp.select_index - 1)
			+ theme.item_spacing * (parent_wp.select_index - 1)

		self:geometry({
			x = root.x + width * 2 + theme.placement_margin >= m_workarea_hend
				and parent.x - width - theme.placement_margin
				or parent.x + width + theme.placement_margin,
			y = self_y + self_height >= m_workarea_vend
				and parent.y + parent_height - self_height
				or self_y
		})
	end
end

function menu:get_root()
	local wp = self._private
	return wp.parent and wp.parent:get_root() or self
end

function menu:destroy_active_children()
	local child = self._private.active_child
	while child do
		local parent = child
		child = child._private.active_child
		parent:destroy()
	end
end

function menu:destroy()
	self:hide()
	self = nil
end

function menu:next()
	local wp = self._private
	local items_layout = self.widget:get_children_by_id("items-layout")[1]
	if not wp.select_index then
		wp.select_index = 1
	elseif wp.select_index ~= #items_layout.children then
		wp.select_index = wp.select_index + 1
	else
		wp.select_index = 1
	end
end

function menu:back()
	local wp = self._private
	local items_layout = self.widget:get_children_by_id("items-layout")[1]
	if not wp.select_index then
		wp.select_index = 1
	elseif wp.select_index ~= 1 then
		wp.select_index = wp.select_index - 1
	else
		wp.select_index = #items_layout.children
	end
end

function menu:hide()
	if not self.visible then return end
	local wp = self._private
	awful.keygrabber.stop(wp.keygrabber)
	wp.select_index = nil
	self:destroy_active_children()
	self.visible = false
end

function menu:show()
	if self.visible then return end
	update_items(self)
	self.screen = capi.mouse.screen
	set_coords(self)
	run_keygrabber(self)
	self.visible = true
end

function menu:toggle()
	if not self.visible then
		self:show()
	else
		self:hide()
	end
end

function menu.new(args, parent)
	if not args then return end

	for i = 1, #args.items do
		if not args.items[i] then
			table.remove(args.items, i)
		end
	end

	local theme = setmetatable(args.theme or {}, {
		__index = {
			placement_margin = dpi(3),
			bg = beautiful.bg,
			fg = beautiful.fg,
			border_color = beautiful.border_color_normal,
			border_width = beautiful.border_width,
			shape = shape.rrect(dpi(10)),
			margins = dpi(5),
			item_bg = beautiful.bg,
			item_fg = beautiful.fg,
			item_hover_bg = beautiful.ac,
			item_hover_fg = beautiful.bg,
			item_width = dpi(150),
			item_height = dpi(25),
			item_shape = shape.rrect(dpi(6)),
			item_margins = { left = dpi(8), right = dpi(4) },
			item_spacing = dpi(2),
			item_font = beautiful.font
		}
	})

	local ret = awful.popup {
		visible = false,
		ontop = true,
		type = "popup_menu",
		bg = "#00000000",
		placement = function() return { 0, 0 } end,
		widget = {
			widget = wibox.container.background,
			bg = theme.bg,
			fg = theme.fg,
			border_color = theme.border_color,
			border_width = theme.border_width,
			shape = theme.shape,
			{
				widget = wibox.container.margin,
				margins = theme.margins,
				{
					id = "items-layout",
					layout = wibox.layout.fixed.vertical,
					spacing = theme.item_spacing
				}
			}
		}
	}

	gtable.crush(ret, menu, true)
	local wp = ret._private

	wp.args = args.items
	wp.theme = theme
	wp.parent = parent
	wp.children = {}

	local items_layout = ret.widget:get_children_by_id("items-layout")[1]
	if wp.args then
		for index, item in ipairs(wp.args) do
			item.theme = theme
			items_layout:add(entry(ret, index, item))
		end
	end

	return ret
end

return setmetatable({ new = menu.new }, { __call = function(_, ...) return menu.new(...) end })
