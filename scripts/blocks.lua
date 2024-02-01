local BLOCK_DATA_SIZE = 5

---@enum BlockType типы блоков
BlockType = {
    Wire = "wire", -- Означает что блок является проводом
    Machine = "machine", -- Означает что блок является механизмом
    Block = "block" -- Означает что блок не должен обладать особыми свойствами
}

---@enum MachineType типы механизмов
MachineType = {
    Recipient = "recipient", -- Означает что блок должен получать энергию
    Sender = "sender" -- Означает что блок должен отправлять энергию
}

-- Хранит все созданые блоки
local Blocks_holder = {

}

-- Хранит функции для блоков
local Block_functions = {

}

local deserialization = {
    ["block"] = function (x, y, z, id, mod_id, meta)
    	CreateBlock(x, y, z, id, mod_id, meta)
    end,
    ["wire"] = function (x, y, z, id, mod_id, meta)
    	CreateWire(x, y, z, id, mod_id, meta)
    end,
    ["machine"] = function (x, y, z, id, mod_id, meta)
    	CreateMachine(x, y, z, id, mod_id, meta)
    end
}

-- Создает функцию для чтения определенного типа блока
---@param block_type string тип блока для которого будет выполнятся десериализация
---@param logic_function function функцтя которая будет выполнятся для десериализации, принимает 6 аргументов (x, y, z, id, mod_id, meta)
local function CreateDeserializftion(block_type, logic_function)
	deserialization[block_type] = logic_function
end

-- Создает собственый тип блоков (только тип, не класс)
---@param type string тип блока для записи, например Machine
---@param value string тип блока для чтения, например machine
---@param func function функция которая будет выполнятся для десериализации(чтения из файла), принимает 6 аргументов (x, y, z, id, mod_id, meta)
function CreateBlockType(type, value, func)
	BlockType[type] = value
	CreateDeserializftion(value, func)
end

-- Создает функцию для блока с определенным id
---@param id string Идендификатор блока
---@param func function Функция для работы логики, принимает 1 объект класса Energy_block
function CreateBlockFunc(id, func)
    Block_functions[id] = func
end

-- Загруэкает функцию для блока с определенным id
---@param id string Идендификатор блока
---@return function func Функция для работы логики
local function LoadBlockFunc(id)
    return Block_functions[id]
end

---@class Block
local Block = {}

---@param x integer Позиция блока по x
---@param y integer Позиция блока по y
---@param z integer Позиция блока по z
---@param id string Строковый ид блока
---@param mod_id string Строковый ид мода
---@param meta table Таблица с метой
---@param block_type BlockType Тип блока
function Block:new(x, y, z, id, mod_id, meta, block_type, logic_function)

    -- свойства
    local lBlock = {}
    lBlock.type = block_type
    lBlock.id = id
    lBlock.mod_id = mod_id
    lBlock.position = pos_to_tbl(x, y, z)
    lBlock.meta = meta
    lBlock.logic_function = logic_function

    -- получение позиции блока
    ---@return integer x позиция по x
    ---@return integer y позиция по y
    ---@return integer z позиция по z
    function lBlock:get_position()
        return tbl_to_pos(self.position)
    end

    -- получение id блока в формате [MOD_ID:BLOCK_ID]
    ---@return string id MOD_ID:BLOCK_ID
    function lBlock:get_id()
        return self.mod_id .. ":" .. self.id
    end

    -- создает мета данные у блока
    function lBlock:set_meta(key, value)
        self.meta[key] = value
    end

    -- удаляет мета данные у блока
    function lBlock:remove_meta(key)
        self.meta[key] = nil
    end

    -- получение мета данных у блока
    function lBlock:get_meta(key)
        return self.meta[key]
    end

    -- получение всех мета данных у блока
    function lBlock:get_all_meta()
        return self.meta
    end

    -- проверяет прогружен ли блок
    function lBlock:is_missing()
        if get_block(self:get_position()) == -1 then
        	return true
        end
        return false
    end

    -- запускает работу функции
    function lBlock:run_logic()
        if self.logic_function ~= nil then
            self.logic_function(self)
        end
    end

    -- возвращяет функция работы для данного блока
    ---@return function logic_function функция работы
    function lBlock:get_logic()
        return self.logic_function
    end

    -- вызывается каждый тик
    function lBlock:tick()
        self:run_logic()
    end

    -- возвращяет тип данного блока
    ---@return string block_type возвращяет строку(тип) из BlockType
    function lBlock:get_type()
        return self.type
    end

    setmetatable(lBlock, self)
    self.__index = pos_to_key(x, y, z)
    return lBlock
end

---@class Energy_block: Block
local Energy_block = {}

---@param x integer Позиция блока по x
---@param y integer Позиция блока по y
---@param z integer Позиция блока по z
---@param id string Строковый ид блока
---@param mod_id string Строковый ид мода
---@param block_type string Тип энергитического блока
---@param meta table Таблица с метой
function Energy_block:new(x, y, z, id, mod_id, meta, block_type, logic_function)
    -- свойства
    local lBlock = Block:new(x, y, z, id, mod_id, meta, block_type, logic_function)
    lBlock:set_meta("is_energy", "yes")

    function lBlock:get_network()
    	return self:get_meta("network")
    end

    function lBlock:set_network(index)
    	self:set_meta("network", index)
    end

    -- получает количество энергии в данном блоке
    ---@return number energy энергия в данном блоке
    function lBlock:get_energy()
        return tonumber(self:get_meta("energy"))
    end

    -- получает максимальное количество энергии в данном блоке
    ---@return number energy максимальная энергия в данном блоке
    function lBlock:get_max_energy()
        return tonumber(self:get_meta("max_energy"))
    end

    -- получает максимальное количество энергии в данном блоке
    ---@param value integer кол-во энергии
    function lBlock:set_energy(value)
        self:set_meta("energy", value)
    end

    function lBlock:is_energy_max()
    	return self:get_energy() == self:get_max_energy()
    end

    -- возвращяет количество энергии которое может вместить из данного количества
    ---@return integer energy_in количество энергии которое может вместится из данного числа
    function lBlock:count_max_energy(count)
        local c_energy = self:get_energy() + count
        if c_energy > self:get_max_energy() then
            return self:get_max_energy() - self:get_energy()
        else
            return count
        end
    end

    -- вызывается когда блоку нужно добавить энергию в его хранилище
    ---@param count integer количество энергии для получения
    function lBlock:receive_energy(count)
        self:set_meta("energy", self:get_energy() + count)
        if self:get_energy() > self:get_max_energy() then
            self:set_energy(self:get_max_energy())
        end
    end

    -- пытается потратить опрежеленное количество энергии в блоке, взвращяет false если в блоке недостаточно энергии, в случае удачной проверки сразу тратит энергию
    ---@param count integer количество энергии для траты
    function lBlock:try_use_energy(count)
        if self:get_energy() >= count then
             self:set_energy(self:get_energy() - count)
            return true
        end
        return false
    end

    -- вызывается когда блоку нужно отдать энергию другому блоку
    ---@param energy_block Energy_block блок которому мы должны передать энергию
    ---@param count integer количество энергии для отдачи
    function lBlock:give_energy(energy_block, count)
        if self:get_energy() >= count and not energy_block:is_energy_max() then
            local to_give = energy_block:count_max_energy(count)
            if self:try_use_energy(to_give) then
                energy_block:receive_energy(to_give)
            end
        end
    end

    -- вызывается когда блоку нужно отдать энергию всем соседним блокам
    ---@param count integer количество энергии для отдачи
    function lBlock:give_energy_neighboues(count)
        local nbs = GetNeigbourEnergies(self:get_position())
        local not_max_nbs = {}
        for _, nb in pairs(nbs) do
            if not nb:is_energy_max() then
            	table.insert(not_max_nbs, nb)
            end
        end
        local to_give = count / #not_max_nbs
        for _, nb in pairs(not_max_nbs) do
        	self:give_energy(nb, to_give)
        end
    end

    setmetatable(lBlock, self)
    self.__index = pos_to_key(x, y, z)
    return lBlock
end

extended(Energy_block, Block)

---@class Wire : Energy_block
local Wire = {}

---@param x integer Позиция блока по x
---@param y integer Позиция блока по y
---@param z integer Позиция блока по z
---@param id string Строковый ид блока
---@param mod_id string Строковый ид мода
---@param meta table Таблица с метой
function Wire:new(x, y, z, id, mod_id, meta, logic_function)

	-- свойства
    local lBlock = Energy_block:new(x, y, z, id, mod_id, meta, BlockType.Wire, logic_function)

    function lBlock:is_energy_max()
        return false
    end

    function lBlock:count_max_energy(count)
        return count
    end

    function lBlock:receive_energy(count)
        -- равномерное распределение энергии по всем механизмам
        local ntx_index = self:get_network()
        local network_recipitents = GetRecipientsIn(ntx_index)
        local not_max_nbs = {}
        for _, nb in pairs(network_recipitents) do
            if not nb:is_energy_max() then
                table.insert(not_max_nbs, nb)
            end
        end
        local to_give = count / #not_max_nbs
        for _, nb in pairs(not_max_nbs) do
            nb:receive_energy( to_give)
        end
    end

    setmetatable(lBlock, self)
    self.__index = pos_to_key(x, y, z)
    return lBlock
end

extended(Wire, Energy_block)

---@class Machine_block : Energy_block
local Machine_block = {}

---@param x integer Позиция блока по x
---@param y integer Позиция блока по y
---@param z integer Позиция блока по z
---@param id string Строковый ид блока
---@param mod_id string Строковый ид мода
---@param logic_function function Функиця работы для блока
---@param meta table Таблица с метой
function Machine_block:new(x, y, z, id, mod_id, meta, logic_function)

    -- свойства
    local lBlock = Energy_block:new(x, y, z, id, mod_id, meta, BlockType.Machine, logic_function)

    -- возвращяет тип механизма
    ---@return string machine_type возвращяет строку(тип) из MachineType
    function lBlock:get_machine_type()
        return self:get_meta("machine_type")
    end

    setmetatable(lBlock, self)
    self.__index = pos_to_key(x, y, z)
    return lBlock
end

extended(Machine_block, Energy_block)

-- Создает новый объект класса Block
---@param x integer позиция блока по x
---@param y integer позиция блока по y
---@param z integer позиция блока по z
---@param id string Строковый ид блока
---@param mod_id string Строковый ид мода
---@param meta table Таблица с данными блока({}, если данных нет)
---@return Block объект класса Block
function CreateBlock(x, y, z, id, mod_id, meta)
    local func = LoadBlockFunc(id)
    local block = Block:new(x, y, z, id, mod_id, meta, BlockType.Block, func)
    Blocks_holder[pos_to_key(x, y, z)] = block
    return block
end

-- Создает новый объект класса Wire
---@param x integer позиция блока по x
---@param y integer позиция блока по y
---@param z integer позиция блока по z
---@param id string Строковый ид блока
---@param mod_id string Строковый ид мода
---@param meta table Таблица с данными блока({}, если данных нет)
---@return Block объект класса Block
function CreateWire(x, y, z, id, mod_id, meta)
    local func = LoadBlockFunc(id)
    local block = Wire:new(x, y, z, id, mod_id, meta, func)
    Blocks_holder[pos_to_key(x, y, z)] = block
    return block
end

-- Создает новый объект класса Machine_block
---@param x integer позиция блока по x
---@param y integer позиция блока по y
---@param z integer позиция блока по z
---@param id string Строковый ид блока
---@param mod_id string Строковый ид мода
---@return Machine_block block объект класса Machine_block
function CreateMachine(x, y, z, id, mod_id, meta)
    local func = LoadBlockFunc(id)
    local block = Machine_block:new(x, y, z, id, mod_id, meta, func)
    Blocks_holder[pos_to_key(x, y, z)] = block
    return block
end

-- Получает уже созданый объект(блок)
---@param x integer позиция блока по x
---@param y integer позиция блока по y
---@param z integer позиция блока по z
---@return Block block блок
function GetBlock(x, y, z)
    return Blocks_holder[pos_to_key(x, y, z)]
end

-- Удаляет объект (при разрушении блока)
---@param x integer позиция блока по x
---@param y integer позиция блока по y
---@param z integer позиция блока по z
function RemoveBlock(x, y, z)
    Blocks_holder[pos_to_key(x, y, z)] = nil
end

-- Получает все ближайшие блоки
function GetBlockNeigbours(x, y, z)
	local nb = {}
	for _, dir in pairs(directions) do
		local block = GetBlock(x + dir[1], y + dir[2], z + dir[3])
		if block ~= nil then
			table.insert(nb, block)
		end
	end
	return nb
end

-- Получает все ближайшие блоки с энергией
function GetNeigbourEnergies(x, y, z)
	local energies = GetBlockNeigbours(x, y, z)
	for index, energy in pairs(energies) do
		if energy:get_meta("is_energy") ~= "yes" then
			energies:remove(index)
		end
	end
	return energies
end

-- Получает все ближайшие механизмы
function GetNeigbourMachines(x, y, z)
	local machines = GetBlockNeigbours(x, y, z)
	for index, machine in pairs(machines) do
		if machine:get_type() ~= BlockType.Machine then
			machines:remove(index)
		end
	end
	return machines
end

-- Получает все ближайшие провода
function GetNeigbourWires(x, y, z)
	local wires = GetBlockNeigbours(x, y, z)
	for index, wire in pairs(wires) do
		if wire:get_type() ~= BlockType.Wire then
			wires:remove(index)
		end
	end
	return wires
end

function on_blocks_tick(tps)
    if IsEnergizerDataLoader() then
    	for _, value in pairs(Blocks_holder) do
    	    if not value:is_missing() then
                value:tick()
            end
        end
    end
end

-- Загрузка данных о блоках
function LoadBlocksData()
    if file.exists("world:energizer_blocks.txt") then
        local data = file.read("world:energizer_blocks.txt")
        local data_func = tokens(data)
        local data_size = #data_func
        ELogger:debug("Blocks to load: " .. (data_size / BLOCK_DATA_SIZE))
        for i = 1, data_size, BLOCK_DATA_SIZE do
            local x, y, z = key_to_pos(data_func[i])
            local type = split(data_func[i+1], ":")[2]
            local meta = split(split(data_func[i+2], "-")[2], ",")
            local meta_normalized = {}
            local id = split(data_func[i+3], ":")[2]
            local mod_id = split(data_func[i+4], ":")[2]
            for _, value in pairs(meta) do
                local splitted = split(value, ":")
                if splitted ~= nil and splitted[1] ~= nil and splitted[2] ~= nil then
                    if splitted[2]:match("%D") then
                        meta_normalized[splitted[1]] = splitted[2]
                    else
                        meta_normalized[splitted[1]] = tonumber(splitted[2])
                    end
                end
            end
            local func = deserialization[type]
            if func ~= nil then
                func(x, y, z, id, mod_id, meta_normalized)
            else
                ELogger:warn("For block with type " .. type .. " load function was not found!")
            end
        end
        ELogger:debug("Blocks was loaded!")
    end
end

-- Сохранение таблицы блоков в файл
function SaveBlocksData()
    local result = ""

    for key, block in pairs(Blocks_holder) do
        local data = key .. "\n"
        data = data .. "type:" .. block.type .. "\n"
        data = data .. "meta-"
        if block:get_all_meta() ~= nil then
            for meta_key, value in pairs(block:get_all_meta()) do
                if type(value) ~= "table" then
                    data = data .. meta_key .. ":" .. value .. ","
                else
                    ELogger:warn("in that moment, energizer can't save table as meta in block!")
                end
            end
        end
        data = data .. "\n"
        data = data .. "id:" .. block.id .. "\n"
        data = data .. "mod_id:" .. block.mod_id .. "\n"
        result = result .. data
    end

    file.write("world:energizer_blocks.txt", result)
    ELogger:debug("Blocks was saved!")
end