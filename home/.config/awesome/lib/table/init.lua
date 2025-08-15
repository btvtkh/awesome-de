local M = {}

function M.has_common(tbl1, tbl2)
	local cmn = {}
	for _, vl1 in pairs(tbl1) do
		for _, vl2 in pairs(tbl2) do
			if vl1 == vl2 then
				table.insert(cmn, vl1)
			end
		end
	end
	return #cmn > 0 and cmn or nil
end

return M
