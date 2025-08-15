pcall(require, "luarocks.loader")
collectgarbage("incremental", 110, 1000)
require("core")
require("ui")
