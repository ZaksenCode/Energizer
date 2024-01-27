MOD_ID = "energizer"

-- Enum из типов блоков
EnergyBlockType = {
    Wire = "wire",
    Machine = "machine"
}

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

-- Создает функцию для блока с определенным id
---@param id string Идендификатор блока
---@return function func Функция для работы логики
function LoadBlockFunc(id)
    return Block_functions[id]
end

---@class Block
local Blocks = {}

---@param x integer Позиция блока по x
---@param y integer Позиция блока по y
---@param z integer Позиция блока по z
---@param is_energy boolean обладает ли блок энергическими свойствами
---@param id string Строковый ид блока
---@param connectable boolean Должен ли блок сойденятся с проводами
---@param meta table Таблица с метой
function Blocks:new(x, y, z, is_energy, id, connectable, meta)

    -- свойства
    local Block = {}
    Block.position = pos_to_tbl(x, y, z)
    Block.energy_block = is_energy
    Block.id = id
    Block.connectable = connectable
    Block.meta = meta

    -- получение позицию блока
    ---@return integer x позиция по x
    ---@return integer y позиция по y
    ---@return integer z позиция по z
    function Block:get_position()
        return tbl_to_pos(self.position)
    end

    -- получение id блока в формате [industrialization:...]
    ---@return string id ид для этого блока
    function Block:get_id()
        return MOD_ID .. ":" .. self.id
    end

    -- возвращяет true если блок работает с энергией
    ---@return boolean energy_block
    function Block:is_energy_block()
        return self.energy_block
    end

    -- возвращяет true если блок должен сойденятся
    ---@return boolean connectable
    function Block:is_connectable()
        return self.connectable
    end

    -- создает мета данные у блока
    function Block:set_meta(key, value)
        self.meta[key] = value
    end

    -- удаляет мета данные у блока
    function Block:remove_meta(key)
        self.meta[key] = nil
    end

    -- получение мета данных у блока
    function Block:get_meta(key)
        return self.meta[key]
    end

    -- получение всех мета данных у блока
    function Block:get_all_meta()
        return self.meta
    end

    -- улаление всех мета данных у блока
    function Block:remove_all_meta()
        self.meta = {}
    end

    setmetatable(Block, self)
    self.__index = pos_to_key(x, y, z)
    return Block
end

---@class Energy_block: Block
local Energy_blocks = {}

---@param x integer Позиция блока по x
---@param y integer Позиция блока по y
---@param z integer Позиция блока по z
---@param id string Строковый ид блока
---@param max_energy integer Максимальное количество энергии в блоке
---@param block_type string Тип энергитического блока
---@param meta table Таблица с метой
function Energy_blocks:new(x, y, z, id, energy, max_energy, block_type, meta)

    -- свойства
    local Block = Blocks:new(x, y, z, true, id, true, meta)
    Block.energy = energy
    Block.max_energy = max_energy
    Block.type = block_type

    -- получает количество энергии в данном блоке
    ---@return integer energy энергия в данном блоке
    function Block:get_energy()
        return self.energy
    end

    -- получает максимальное количество энергии в данном блоке
    ---@return integer energy максимальная энергия в данном блоке
    function Block:get_max_energy()
        return self.max_energy
    end

    -- возвращяет количество энергии которое может вместить из данного количества
    ---@return integer energy_in количество энергии которое может вместится из данного числа
    function Block:count_max_energy(count)
        local c_energy = self.energy + count
        if c_energy > self.max_energy then
            return self.max_energy - self.energy
        else
            return count
        end
    end

    -- вызывается когда блоку нужно добавить энергию в его хранилище
    ---@param count integer количество энергии для получения
    function Block:receive_energy(count)
        self.energy = self.energy + count
        if self.energy > self.max_energy then
            self.energy = self.max_energy
        end
    end

    -- пытается потратить опрежеленное количество энергии в блоке, взвращяет false если в блоке недостаточно энергии, в случае удачной проверки сразу тратит энергию
    ---@param count integer количество энергии для траты
    function Block:try_use_energy(count)
        if self.energy >= count then
            self.energy = self.energy - count
            return true
        end
        return false
    end

    -- вызывается когда блоку нужно отдать энергию другому блоку
    ---@param energy_block Energy_block блок которому мы должны передать энергию
    ---@param count integer количество энергии для отдачи
    function Block:give_energy(energy_block, count)
        if self.energy >= count then
            local to_give = energy_block:count_max_energy(energy)
            if self:try_use_energy(to_give) then
                energy_block:receive_energy(to_give)
            end
        end
    end

    -- возвращяет тип данного энергетического блока
    ---@return string block_type возвращяет строку из EnergyBlockType
    function Block:get_type()
        return self.block_type
    end

    setmetatable(Block, self)
    self.__index = pos_to_key(x, y, z)
    return Block
end

extended(Energy_blocks, Blocks)

---@class Machine_block : Energy_block
local Machine_blocks = {}

---@param x integer Позиция блока по x
---@param y integer Позиция блока по y
---@param z integer Позиция блока по z
---@param id string Строковый ид блока
---@param max_energy integer Максимальное количество энергии в блоке
---@param logic_function function Функиця работы для блока
---@param meta table Таблица с метой
function Machine_blocks:new(x, y, z, id, energy, max_energy, meta, logic_function)

    -- свойства
    local Block = Energy_blocks:new(x, y, z, id, energy, max_energy, EnergyBlockType.Machine, meta)
    Block.logic_function = logic_function

    -- запускает работу функции 
    function Block:run_logic()
        if self.logic_function ~= nil then
            self.logic_function(self)
        end
    end

    -- возвращяет функция работы для данного блока
    ---@return function logic_function функция работы
    function Block:get_logic()
        return self.logic_function
    end

    setmetatable(Block, self)
    self.__index = pos_to_key(x, y, z)
    return Block
end

extended(Machine_blocks, Energy_blocks)

-- Создает новый объект класса
---@param x integer позиция блока по x
---@param y integer позиция блока по y
---@param z integer позиция блока по z
---@param id string Строковый ид блока
---@param energy integer Изначальное количество энергии (обычно равно 0)
---@param max_energy integer Максимальное количество энергии в блоке
---@return Machine_block block объект класса Machine_block
function CreateMachine(x, y, z, id, energy, max_energy, meta)
    local func = LoadBlockFunc(id)
    local block = Machine_blocks:new(x, y, z, id, energy, max_energy, meta, func)
    Blocks_holder[pos_to_key(x, y, z)] = block
    return block
end

-- Получает уже созданый объект класса
---@param x integer позиция блока по x
---@param y integer позиция блока по y
---@param z integer позиция блока по z
---@return Machine_block block объект класса Machine_block
function GetMachine(x, y, z)
    return Blocks_holder[pos_to_key(x, y, z)]
end

-- Удаляет объект (при разрушении блока)
---@param x integer позиция блока по x
---@param y integer позиция блока по y
---@param z integer позиция блока по z
function RemoveMachine(x, y, z)
    Blocks_holder[pos_to_key(x, y, z)] = nil
end

--Вызывает функцию run_logic() для всех блоков
---@diagnostic disable-next-line: lowercase-global
function on_blocks_tick(tps)
    for _, value in pairs(Blocks_holder) do
        local x, y, z = value:get_position()
        value:run_logic()
    end
end

local DATA_SIZE = 5
-- Загрузка данных о блоках
function load_all_data()
    if file.exists("world:energizer_blocks.txt") then
        local data = file.read("world:energizer_blocks.txt")
        local data_func = tokens(data)
        local data_size = #data_func
    
        for i = 1, data_size, DATA_SIZE do
            local x, y, z = key_to_pos(data_func[i])
            local meta = split(split(data_func[i+1], "-")[2], ",")
            local meta_normalized = {}
            local id = split(data_func[i+2], ":")[2]
            local energy = tonumber(split(data_func[i+3], ":")[2])
            local max_energy = tonumber(split(data_func[i+4], ":")[2])
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
            CreateMachine(x, y, z, id, energy, max_energy, meta_normalized)
        end
    end
end

-- Сохранение данных о блоках
function save_add_data()
    save_blocks_tbl(Blocks_holder)
end