---@class Logger
Logger = {}

---@param name string имя для логгера
---@param debug boolean должен ли логгер выводить Debug
function Logger:new(name, debug)

	-- свойства
    local logger = {}
    logger.name = name;
    logger.is_debug = debug;

    function logger:get_name()
    	return "[" .. self.name .. "]"
    end

    -- Выводит новое сообщение в консоль
    ---@param message string тест сообщения
    function logger:log(message)
    	print(self:get_name() .. " info: " .. message)
    end

    -- Выводит ошибку в консоль
    ---@param message string тест ошибки
    function logger:err(message)
        print(self:get_name() .. " error: " .. message)
    end

    -- Выводит предупреждение в консоль
    ---@param message string тест предупреждения
    function logger:warn(message)
    	print(self:get_name() .. " warn: " .. message)
    end

    -- Выводит сообщение отладки в консоль
    ---@param message string тест сообщение
    function logger:debug(message)
        if self.is_debug == true then
        	print(self:get_name() .. " debug: " .. message)
        end
    end

    -- Выводит таблицу в консоль
    ---@param tbl table таблица для вывода
    function logger:table(tbl, indent)
        if self.is_debug == true then
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
    end

    setmetatable(logger, self)
    self.__index = self
    return logger
end