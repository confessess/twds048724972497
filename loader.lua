-- TWD Online Loader - Loads from GitHub
local baseUrl = "https://raw.githubusercontent.com/confessess/twds048724972497/main/"

-- Load main
local mainCode = game:HttpGet(baseUrl .. "main.lua")
loadstring(mainCode)()