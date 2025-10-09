local awful = require("awful")
local gtimer = require("gears.timer")

local function new(command, interval, output_file, callback)
	local timer
	timer = gtimer {
		timeout = interval,
		call_now = true,
		autostart = true,
		single_shot = false,
		callback = function()
			awful.spawn.easy_async_with_shell("date -r " .. output_file .. " +%s", function(last_update, _, _, exitcode)
				if exitcode == 1 then
					awful.spawn.easy_async_with_shell(command .. " | tee " .. output_file, function(out)
						callback(out)
					end)
					return
				end

				local diff = os.time() - tonumber(last_update)
				if diff >= interval then
					awful.spawn.easy_async_with_shell(command .. " | tee " .. output_file, function(out)
						callback(out)
					end)
				else
					awful.spawn.easy_async_with_shell("cat " .. output_file, function(out)
						callback(out)
					end)
					timer:stop()
					gtimer.start_new(interval - diff, function()
						awful.spawn.easy_async_with_shell(command .. " | tee " .. output_file, function(out)
							callback(out)
						end)
						timer:again()
					end)
				end
			end)
		end
	}

	return timer
end

return setmetatable({ new = new }, { __call = function(_, ...) return new(...) end })
