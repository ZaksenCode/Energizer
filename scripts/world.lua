-- load_script("energizer:scripts/utils.lua")
-- load_script("energizer:scripts/main.lua")
dofile("res/content/energizer/scripts/constants.lua")
dofile("res/content/energizer/scripts/logger.lua")
dofile("res/content/energizer/scripts/utils.lua")
dofile("res/content/energizer/scripts/main.lua")
ELogger = Logger:new("energizer", run_api_with_debug)

function on_world_open()
    LoadWorldData()
end

function on_world_save()
    SaveWorldData()
end