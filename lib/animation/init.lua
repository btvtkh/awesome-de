local GLib = require("lgi").require("GLib")
local gobject = require("gears.object")
local gtable = require("gears.table")

local animation = {}

function animation:start()
	local wp = self._private

	if wp.is_runnung then
		if wp.reset_on_stop then
			self:stop()
		else
			return
		end
	end

	wp.last_elapsed = GLib.get_monotonic_time()
	wp.timeout_source_id = GLib.timeout_add(
		GLib.PRIORITY_DEFAULT,
		1000/wp.framerate,
		function()
			local time = GLib.get_monotonic_time()
			local delta = time - wp.last_elapsed
			wp.last_elapsed = time

			if wp.elapsed <= wp.duration then
				wp.elapsed = wp.elapsed + delta/1000000
				if wp.easing then
					wp.pos = math.min(wp.easing(wp.elapsed/wp.duration), 1)
				else
					wp.pos = math.min(wp.elapsed/wp.duration, 1)
				end
				self:emit_signal("updated", wp.pos)
				return true
			else
				if wp.loop then
					self:emit_signal("ended")
					wp.pos = 0
					wp.elapsed = 0
					return true
				else
					if not wp.reset_on_stop then
						self:emit_signal("ended")
						wp.pos = 0
						wp.elapsed = 0
					end
					self:stop()
				end
			end
		end
	)

	wp.is_runnung = true
	self:emit_signal("started")
end

function animation:stop()
	local wp = self._private
	if not wp.is_runnung then return end

	GLib.source_remove(wp.timeout_source_id)

	if wp.reset_on_stop then
		self:emit_signal("ended")
		wp.pos = 0
		wp.elapsed = 0
	end

	wp.is_runnung = false
	self:emit_signal("stopped")
end

local function new(args)
	args = args or {}
	local ret = gobject {}
	gtable.crush(ret, animation, true)
	ret._private = {}
	local wp = ret._private

	wp.framerate = args.framerate or 60
	wp.duration = args.duration or 1
	wp.reset_on_stop = args.reset_on_stop or false
	wp.loop = args.loop or false
	wp.easing = args.easing

	wp.is_runnung = false
	wp.last_elapsed = 0
	wp.elapsed = 0
	wp.pos = 0

	return ret
end

return setmetatable({ new = new }, { __call = function(_, ...) return new(...) end })
