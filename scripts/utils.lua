-- Разделить строку
function split(str, splitter)
    local s = {}
    if str == nil then
        str = "%s"
    end
    for _str in string.gmatch(str, "([^"..splitter.."]+)") do
        table.insert(s, _str)
    end
    return s
end

function tokens(str)
    local s = {}
    if str == nil then
        str = "%s"
    end
    for _str in string.gmatch(str, "[^%s]+") do
        table.insert(s, _str)
    end
    return s
end


-- выводит таблицу в читаемом виде (by @Dagger)
---@param tbl table таблица которая будет выводится
function print_table(tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            print(formatting)
            print_table(v, indent+1)
        else
            print(formatting .. tostring(v) .. "(" .. type(v) .. ")")
        end
    end
end

-- Наследование от родителя
---@param child table таблица которая будет наследовать 
---@param parent table таблица которую будут наследовать 
function extended(child, parent)
    setmetatable(child, {__index = parent})
end

-- Преобразовать позицию в ключ формата [x_y_z]
function pos_to_key(x, y, z)
    return x .. "_" .. y .. "_" .. z
end

-- Преобразовать ключ формата [x_y_z] в позицию
function key_to_pos(key)
    local t = split(key, "_")
    local x = t[1]
    local y = t[2]
    local z = t[3]
    return x, y, z
end

-- Преобразование позиции в таблицу
function pos_to_tbl(x, y, z)
    return {
      tonumber(x),
      tonumber(y),
      tonumber(z)
    }
end

-- Преобразование таблицы в позицию
function tbl_to_pos(tbl)
    return tbl[1], tbl[2], tbl[3]
end

-- Преобразование таблицы в строку (Выкинит ошибку если есть функции)
---@param tbl table таблица для сериализации
---@return string string строка из таблица
function tbl_to_str(tbl)
    local result = ""

    if tbl == nil then
        return result
    end

    for key, value in pairs(tbl) do
        if type(value) == "table" then
            result = result .. tbl_to_str(value)
        else
            result = result .. key .. ":" .. value .. "\n"
        end
    end
    return result
end

-- Сохранение таблицы блоков в файл
---@param blocks_tbl table таблица блоков
function save_blocks_tbl(blocks_tbl)
    local result = ""

    for key, block in pairs(blocks_tbl) do
        local data = key .. "\n"
        data = data .. "meta-"
        if block:get_all_meta() ~= nil then
            for key, value in pairs(block:get_all_meta()) do
                data = data .. key .. ":" .. value .. ","
            end
        end
        data = data .. "\n"
        data = data .. "id:" .. block.id .. "\n"
        data = data .. "energy:" .. block:get_energy() .. "\n"
        data = data .. "max_energy:" .. block:get_max_energy() .. "\n"
        result = result .. data
    end

    file.write("world:energizer_blocks.txt", result)
end