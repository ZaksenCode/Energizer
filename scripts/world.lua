-- load_script("energizer:scripts/utils.lua")
-- load_script("energizer:scripts/main.lua")
dofile(file.resolve("energizer:scripts/constants.lua"))
dofile(file.resolve("energizer:scripts/logger.lua"))
dofile(file.resolve("energizer:scripts/utils.lua"))
dofile(file.resolve("energizer:scripts/main.lua"))
dofile(file.resolve("energizer:scripts/blocks.lua"))
dofile(file.resolve("energizer:scripts/networks.lua"))

local run_api_with_debug = true
ELogger = Logger:new("energizer", run_api_with_debug)

function on_world_open()
    LoadWorldData()
end

function on_world_save()
    SaveWorldData()
end