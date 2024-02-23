local M = {}

---@param filename string
---@return number
function M.get_max_lnum(filename)
    local file = io.open(filename, "r")
    if file == nil then
        error("[io.get_max_lnum] file is nil")
    end
    local line_count = 0
    for _ in file:lines() do
        line_count = line_count + 1
    end
    file:close()
    return line_count
end

return M
