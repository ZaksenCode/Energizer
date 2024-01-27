local DATA_SIZE = 5
local was_data_loaded = false

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

local deserialization = {
    ["block"] = function (x, y, z, id, mod_id, meta)
    	CreateBlock(x, y, z, id, mod_id, meta)
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
---@param value string тип блоя для чтения, например machine
---@param func function функцтя которая будет выполнятся для десериализации(чтения из файла), принимает 6 аргументов (x, y, z, id, mod_id, meta)
function CreateBlockType(type, value, func)
	BlockType[type] = value
	CreateDeserializftion(value, func)
end

-- Хранит все созданые блоки
local Blocks_holder = {

}

-- Хранит функции для блоков
local Block_functions = {

}

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
function Block:new(x, y, z, id, mod_id, meta, block_type)

    -- свойства
    local lBlock = {}
    lBlock.type = block_type
    lBlock.id = id
    lBlock.mod_id = mod_id
    lBlock.position = pos_to_tbl(x, y, z)
    lBlock.meta = meta

    -- получение позицию блока
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

    -- возвращяет тип данного блока
    ---@return string block_type возвращяет строку(тип) из BlockType
    function lBlock:get_type()
        return self.block_type
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
function Energy_block:new(x, y, z, id, mod_id, meta, block_type)
    -- свойства
    local lBlock = Block:new(x, y, z, id, mod_id, meta, block_type)

    -- получает количество энергии в данном блоке
    ---@return integer energy энергия в данном блоке
    function lBlock:get_energy()
        return self:get_meta("energy")
    end

    -- получает максимальное количество энергии в данном блоке
    ---@return integer energy максимальная энергия в данном блоке
    function lBlock:get_max_energy()
        return self:get_meta("max_energy")
    end

    -- получает максимальное количество энергии в данном блоке
    ---@param value integer кол-во энергии
    function lBlock:set_energy(value)
        self:set_meta("energy", value)
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
        if self:get_energy() >= count then
            local to_give = energy_block:count_max_energy(count)
            if self:try_use_energy(to_give) then
                energy_block:receive_energy(to_give)
            end
        end
    end

    setmetatable(lBlock, self)
    self.__index = pos_to_key(x, y, z)
    return lBlock
end

extended(Energy_block, Block)

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
    local lBlock = Energy_block:new(x, y, z, id, mod_id, meta, BlockType.Machine)
    lBlock.logic_function = logic_function

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


function get_all_blocks()
	return Blocks_holder
end

-- Создает новый объект класса Block
---@param x integer позиция блока по x
---@param y integer позиция блока по y
---@param z integer позиция блока по z
---@param id string Строковый ид блока
---@param mod_id string Строковый ид мода
---@param meta table Таблица с данными блока({}, если данных нет)
---@return Block объект класса Block
function CreateBlock(x, y, z, id, mod_id, meta)
    local block = Block:new(x, y, z, id, mod_id, meta, BlockType.Block)
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

function on_blocks_tick(tps)
    if was_data_loaded then
    	for _, value in pairs(Blocks_holder) do
            value:run_logic()
        end
    end
end

-- Загрузка данных о блоках
function load_all_data()
    if file.exists("world:energizer_blocks.txt") then
        local data = file.read("world:energizer_blocks.txt")
        local data_func = tokens(data)
        local data_size = #data_func
        for i = 1, data_size, DATA_SIZE do
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
            deserialization[type](x, y, z, id, mod_id, meta_normalized)
        end
    end
    was_data_loaded = true
end

-- Сохранение данных о блоках
function save_add_data()
    save_blocks_tbl(Blocks_holder)
end