-- TWD Online Loader
-- Run this to load the script

local folder = "TWDOnline"

-- Create folder if needed
if makefolder and not (isfolder and isfolder(folder)) then
    makefolder(folder)
end

-- Download and run main
local mainCode = readfile(folder .. "/main.lua")
loadstring(mainCode)()
