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

-- Разделяет строку на элементы по пробелам
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

-- Проверяет есть ли в таблице определенный элемент
---@param table table таблица с который мы смотрим
---@param element any элемент для проверки
function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
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