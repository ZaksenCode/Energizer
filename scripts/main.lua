local was_data_loaded = false

function IsEnergizerDataLoader()
    return was_data_loaded
end

-- Загрузка всех данных
function LoadWorldData()
    LoadBlocksData()
    LoadNetworksData()
	was_data_loaded = true
end

-- Сохранение всех данных
function SaveWorldData()
    --if file.mkdir("world:energizer") then
    --	  ELogger:debug("Была созданая директория для energizer")
    --end
    SaveBlocksData()
    SaveNetworksData()
end