local inspect = require("lib.inspect")

local M = {}

function M.exists(file)
	local f = io.open(file, "r")
	if f ~= nil then
		io.close(f)
		return true
	else
		return false
	end
end

function M.dump(tbl, file)
	if not file or not tbl then return end
	local inspected = assert(inspect(tbl, { indent = "\t" }))
	local wfile = assert(io.open(file, "w"))
	wfile:write("return " .. inspected)
	wfile:close()
end

return M
