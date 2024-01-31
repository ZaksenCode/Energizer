local NETWORK_DATA_SIZE = 1
-- Хранит все созданые сети
local Networks = {

}

-- Создает новую сеть и возвращяет её индекс
local function CreateNetwork()
    -- Создаем новую сеть с последним индексом
    table.insert(Networks, {})
    local index = #Networks
	return index
end

-- Удаляет сеть по индексу
---@param index integer индекс сети для удаления
local function RemoveNetwork(index)
    table.remove(Networks, index)
end

-- Добавляет блок в сеть
local function addIntoNetwork(index, key, block_type)
    table.insert(Networks[index], {block_type, key})
end

-- Удалить блок из сети
local function removeFromNetwork(ntw_index, block_index)
    table.remove(Networks[ntw_index], block_index)
end

-- Присоденяет блок к сети
function AttachToNetwork(x, y, z)
	local block = GetBlock(x, y, z)
	local pos_key = pos_to_key(x, y, z)
	local block_type = block:get_type()
	local nbs = GetNeigbourEnergies(x, y, z)

	if #nbs == 0 then -- Если рядом нету блоков
	    -- Создаем новую сеть
		local index = CreateNetwork()
		block:set_network(index)
        addIntoNetwork(index, pos_key, block_type)
	elseif #nbs == 1 then -- Если рядом один блок
	    -- Подключаемся к нему в сеть
	    local index = nbs[1]:get_network()
	    block:set_network(index)
	    addIntoNetwork(index, pos_key, block_type)
	else -- Если рядом два и более блоков
        -- Проверяем в каких они сетях
        local lNetworks = {}
        for _, nb in pairs(nbs) do
            -- Проверяем если ли в локальной таблице сеть блока (во избежания дублирования)
        	if not table.contains(lNetworks, nb:get_network()) then
        		table.insert(lNetworks, nb:get_network())
        	end
        end
        -- Сортируем сети от большой к меньшей
        table.sort(lNetworks, function (a, b)
        	return a > b
        end)
        -- Получаем самую маленькую (по индексу) сеть
        local minIdx = lNetworks[#lNetworks]
        table.remove(lNetworks, #lNetworks)
        -- Сойденяем все сети в самую маленькую (по индексу)
        -- Проходимся по всем полученым сетям
        for _, net_idx in pairs(lNetworks) do
            -- Проходимся по всем блокам в сети
            for _, _block in pairs(Networks[net_idx]) do
                addIntoNetwork(minIdx, _block[2], _block[1])
                GetBlock(key_to_pos(_block[2])):set_network(minIdx)
            end
            RemoveNetwork(net_idx)
        end
        -- Добавляем в сеть наш блок
        block:set_network(minIdx)
        addIntoNetwork(minIdx, pos_key, block_type)

        ELogger:debug("Combine networks:")
        ELogger:table(lNetworks)
        ELogger:debug("Into: " .. minIdx)
	end
end

local function countNetwork(x, y, z, visited, is_main)
    visited[pos_to_key(x, y, z)] = pos_to_key(x, y, z)
	local nbs = GetNeigbourEnergies(x, y, z)
	for _, nb in pairs(nbs) do
	    local nx, ny, nz = nb:get_position()
		if visited[pos_to_key(nx, ny, nz)] == nil then
			countNetwork(nx, ny, nz, visited, false)
		end
	end
	if is_main then
		return visited
	end
end

function DetachFromNetwotk(x, y, z)
    local pos_key = pos_to_key(x, y, z)
    ELogger:debug("Pos: " .. pos_key)
    local nbs = GetNeigbourEnergies(x, y, z)
    local block_network_index
    local block_pos_index
    -- Получения индекса сети и индекса блока из его позиции
    for network_index, network in pairs(Networks) do
    	for block_index, block_data in pairs(network) do
    		if block_data[2] == pos_key then
    			block_pos_index = block_index
    			block_network_index = network_index
    		end
    	end
    end
    -- TODO пофиксить странные индексы сети при создании новых сетей
    if block_network_index ~= nil then
        if #nbs == 0 then -- Если рядом нету блоков
            -- Удаляем блок из сети
            removeFromNetwork(block_network_index, block_pos_index)
            -- Проверяем остались ли в сети блока другие блоки (такого быть не должно)
            if #Networks[block_network_index] == 0 then
                -- Удляем сеть блока
                RemoveNetwork(block_network_index)
            end
        elseif #nbs == 1 then -- Если рядом один блок
            -- Удаляем блок из сети
            removeFromNetwork(block_network_index, block_pos_index)
        else -- Если рядом два и более блоков
            -- Алгоритм для разрыва сети
            -- 0: Удаляем текущаю сеть
            -- 1: Получаем таблицы блоков для всех соседей
            -- 2: Сравниваем все таблицы друг с другом
            -- 3: Удаляем одинаковые таблицы
            -- 4: Создаем сети для оставщихся таблиц
            -- удаляем текущаю сеть
            table.remove(Networks, block_network_index)
            -- Получаем таблицы блоков для всех соседей
            local allNetworks = {}
            for _, nb in pairs(nbs) do
            	local lNetwork = {}
            	local nx, ny, nz = nb:get_position()
            	lNetwork = countNetwork(nx, ny, nz, {[pos_to_key(x, y, z)] = pos_to_key(x, y, z)}, true)
            	table.insert(allNetworks, lNetwork)
            end
            -- Сравниваем все таблицы друг с другом
            local networkIndexs = {}
            for index, lNetwork in pairs(allNetworks) do
                for index2, lNetwork2 in pairs(allNetworks) do
                    if index ~= index2 then
                        if compare_table(lNetwork, lNetwork2, true) then
                            -- Добавляем одинаковые сети в таблицу
                            if not table.contains(networkIndexs, index) and not table.contains(networkIndexs, index2) then
                                table.insert(networkIndexs, index2)
                            end
                        end
                    end
                end
            end
            table.sort(networkIndexs, function (a, b)
              return a > b
            end)
            -- Удаляем одинаковые таблицы
            for index, network in pairs(allNetworks) do
                if table.contains(networkIndexs, index) then
                	table.remove(allNetworks, index_of(allNetworks, network))
                end
            end
            -- Создаем сети для оставщихся таблиц
            for _, network in pairs(allNetworks) do
                local network_index = CreateNetwork()
            	for key, _ in pairs(network) do
            		local block = GetBlock(key_to_pos(key))
            		local type = block:get_type()
            		if key ~= pos_key then
            			addIntoNetwork(network_index, key, type)
            			block:set_network(network_index)
            		end
            	end
            end
        end
    end
end

-- Загрузка данных о сетях
function LoadNetworksData()
    if file.exists("world:energizer_networks.txt") then
        local data = file.read("world:energizer_networks.txt")
        local data_func = tokens(data)
        local data_size = #data_func
        ELogger:debug("Networks to load: " .. (data_size / NETWORK_DATA_SIZE))
        for i = 1, data_size, NETWORK_DATA_SIZE do
            local ntw_tbl = split(data_func[i], ":")[2]
            local ntw_blocks = split(ntw_tbl, ";")
            local network_idx = CreateNetwork()
            for _, key in pairs(ntw_blocks) do
            	local block_pos = split(key, ",")[1]
            	local block_type = split(key, ",")[2]
            	local block = GetBlock(key_to_pos(block_pos))
                if block ~= nil then
                    addIntoNetwork(network_idx, block_pos, block_type)
                    block:set_network(network_idx)
                end
            end
        end
        ELogger:debug("Networks was loaded!")
    end
end

-- Сохранение таблицы сетей в файл
function SaveNetworksData()
    local result = ""

    for _, network in pairs(Networks) do
        if #network > 0 then
            local data = "network:"
            for _, block in pairs(network) do
                -- network:-2_16_-36,machine;-3_16_-36,wire;
                data = data .. block[2] .. "," .. block[1] .. ";"
            end
            data = data .. "\n"
            result = result .. data
        end
    end

    file.write("world:energizer_networks.txt", result)
    ELogger:debug("Networks was saved!")
end