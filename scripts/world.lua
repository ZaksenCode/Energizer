-- load_script("energizer:scripts/utils.lua")
-- load_script("energizer:scripts/main.lua")
dofile("res/content/energizer/scripts/constants.lua")
dofile("res/content/energizer/scripts/utils.lua")
dofile("res/content/energizer/scripts/main.lua")

function on_world_open()
    LoadWorldData()
end

function on_world_save()
    SaveWorldData()
end