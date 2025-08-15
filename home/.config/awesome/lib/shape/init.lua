local gshape = require("gears.shape")
local beautiful = require("beautiful")

local M = {}

function M.rrect(r)
	return beautiful.rounded and function(cr, w, h)
		gshape.rounded_rect(cr, w, h, r)
	end
end

function M.rbar()
	return beautiful.rounded and function(cr, w, h)
		gshape.rounded_bar(cr, w, h)
	end
end

function M.prrect(tl, tr, br, bl, r)
	return beautiful.rounded and function(cr, w, h)
		gshape.partially_rounded_rect(cr, w, h, tl, tr, br, bl, r)
	end
end

function M.crcl(r)
	return beautiful.rounded and function(cr, w, h)
		gshape.circle(cr, w, h, r)
	end
end

function M.notch_top(r)
	return function(cr, w, h)
		r = r or 10
		r = r > w/2 and w/2 or r
		r = r > h/2 and h/2 or r
		cr:move_to(0, 0)
		cr:arc(0, r, r, math.pi*3/2, math.pi*2)
		cr:arc_negative(r*2, h - r, r, math.pi, math.pi/2)
		cr:arc_negative(w - r*2, h - r, r, math.pi/2, math.pi*2)
		cr:arc(w, r, r, math.pi, math.pi*3/2)
		cr:close_path()
	end
end

function M.notch_bottom(r)
	return function(cr, w, h)
		r = r or 10
		r = r > w/2 and w/2 or r
		r = r > h/2 and h/2 or r
		cr:move_to(r, r)
		cr:arc(r*2, r, r, math.pi, math.pi*3/2)
		cr:arc(w - r*2, r, r, math.pi * 3/2, math.pi*2)
		cr:arc_negative(w, h - r, r, math.pi, math.pi/2)
		cr:arc_negative(0, h - r, r, math.pi/2, math.pi*2)
		cr:close_path()
	end
end

function M.notch_left(r)
	return function(cr, w, h)
		r = r or 10
		r = r > w/2 and w/2 or r
		r = r > h/2 and h/2 or r
		cr:move_to(0, 0)
		cr:arc_negative(r, 0, r, math.pi, math.pi/2)
		cr:arc(w - r, r*2, r, math.pi*3/2, math.pi*2)
		cr:arc(w - r, h - r*2, r, math.pi*2, math.pi/2)
		cr:arc_negative(r, h, r, math.pi*3/2, math.pi)
		cr:close_path()
	end
end

function M.notch_right(r)
	return function(cr, w, h)
		r = r or 10
		r = r > w/2 and w/2 or r
		r = r > h/2 and h/2 or r
		cr:move_to(r, r)
		cr:arc_negative(r, r*2, r, math.pi*3/2, math.pi)
		cr:arc_negative(r, h - r*2, r, math.pi, math.pi/2)
		cr:arc(w - r, h, r, math.pi*3/2, math.pi*2)
		cr:arc(w - r, 0, r, math.pi*2, math.pi/2)
		cr:close_path()
	end
end

return M
