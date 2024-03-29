local core = require("bookmarks.core")
local file = require("bookmarks.file")

local M = {}

---@class Bookmark
---@field filename string
---@field bufnr integer
---@field lnum number

---@type Bookmark[]
local bookmarks = {}

function M.update_bufnr()
    core.lua.list.each(bookmarks, function(bookmark)
        local bufnr = vim.fn.bufadd(bookmark.filename)
        bookmark.bufnr = bufnr
    end)
end

---@param bufnr integer
---@param lnum number
---@return boolean
function M.exists(bufnr, lnum)
    return core.lua.list.includes(bookmarks, function(b)
        return b.bufnr == bufnr and b.lnum == lnum
    end)
end

---@param index integer
---@return boolean
local function is_valid(index)
    local bs = M.list()
    local b = bs[index]
    local max_lnum = file.get_max_lnum(b.filename)

    return b.lnum <= max_lnum
end

---@param index integer
---@param update_index fun(): integer
---@return integer
function M.sanitize(index, update_index)
    if is_valid(index) then
        return index
    end

    local bs = M.list()
    local b = bs[index]

    M.delete(b.bufnr, b.lnum)

    index = update_index()

    if is_valid(index) then
        return index
    else
        return M.sanitize(index, update_index)
    end
end

---@return Bookmark[]
function M.list()
    M.update_bufnr()

    local filenames = core.lua.list.uniq(core.lua.list.map(bookmarks, function(bookmark)
        return bookmark.filename
    end))

    local new_bookmarks = {}
    core.lua.list.each(filenames, function(filename)
        local bs = core.lua.list.sort(
            core.lua.list.filter(bookmarks, function(bookmark)
                return bookmark.filename == filename
            end),
            function(prev, next)
                return prev.lnum > next.lnum
            end
        )
        core.lua.list.each(bs, function(bookmark)
            table.insert(new_bookmarks, bookmark)
        end)
    end)

    return new_bookmarks
end

function M.update_all(bs)
    bookmarks = bs
end

---@param bufnr integer
---@param lnum number
---@return nil
function M.add(bufnr, lnum)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    table.insert(bookmarks, { filename = filename, bufnr = bufnr, lnum = lnum })
end

---@param bufnr integer
---@param lnum number
---@return nil
function M.delete(bufnr, lnum)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    core.lua.list.each(bookmarks, function(bookmark, index)
        if bookmark.filename == filename and bookmark.lnum == lnum then
            table.remove(bookmarks, index)
        end
    end)
end

function M.remove_all()
    bookmarks = {}
end

---@return any
function M.toJson()
    return { vim.json.encode(M.list()) }
end

---@param json any[]
---@return Bookmark[]
function M.fromJson(json)
    if json == nil then
        return {}
    else
        return vim.json.decode(json[1]) or {} --[[ @as Bookmark[] ]]
    end
end

return M
