-- pet.nvim 
-- Shows a cat on the right of the screen at CursorLine, using virtualtext.
--
-- Requirements: 
-- - FixCursorHold
--
-- TODO:
--   1) Cat paces around
--   2) Different pets!
--   3) Config
--
--  BUG:
--   1) Improper rendering when folded (bottom half goes into fold)
--   2) Cats span across multiple lines when the line wraps

local api = vim.api
local pets = {}

-- @returns int
local function compute_line_num()
  local computed_line_num = api.nvim_win_get_cursor(0)[1]
  if computed_line_num - 1 == line_num then
    -- no y-axis move, no need to re-render
    return -2
  end

  local window = api.nvim_get_current_win()
  if api.nvim_win_is_valid(window) then
    window = api.nvim_win_get_config(window)
    if (window.relative ~= '' or window.external) then
      -- don't render in floats
      return -2
    end
  else
    return -2
  end

  local line_count = api.nvim_buf_line_count(0)
  if (line_count == 1) then
    -- buffer only has 1 line, we can't render the whole cat
    return -1
  elseif (line_count == computed_line_num) then 
    -- we are on the last line of the buffer, move the cat one line up
    return computed_line_num - 2
  elseif (line_count > computed_line_num) then
    -- render normally
    return computed_line_num - 1
  else 
    -- something went wrong
    return -2
  end
end

-- pet sprites
local one_line_pet = "^.^──╯╮"
local afk_pet = { "  ╭──╮ ", "^.^──╯╮" }
local moved_pet = { "^.^──╮╮", "  ╰──╯╰" }

-- @args str, int
-- @returns int
draw_pet = function(id, namespace, text, line)
  if id then
    -- update pet
    api.nvim_buf_del_extmark(0, namespace, id)
    return api.nvim_buf_set_extmark(0, namespace, line, 0, {
      virt_text = {{ text, "Normal" }},
      virt_text_pos = "right_align",
    })
  else 
    -- create pet
    return api.nvim_buf_set_extmark(0, namespace, line, 0, {
      virt_text = {{ text, "Normal" }},
      virt_text_pos = "right_align",
    })
  end
end

-- @returns list
start = function(buf)
  local namespace = api.nvim_create_namespace('pet')
  if api.nvim_buf_is_valid(buf) then
    pets[buf] = { namespace }
    line_num = compute_line_num()
    return afk(buf)
  end
end

-- @returns list 
afk = function(buf)
  if api.nvim_buf_is_valid(buf) then
    if pets[buf] and pets[buf][1] then
      local pet = { pets[buf][1] }
      if (line_num == -2) then
        return pets[buf]
      elseif (line_num == -1) then
        table.insert(pet, draw_pet(pets[buf][2], pets[buf][1], one_line_pet, 0))
      else 
        for i, text in ipairs(afk_pet) do
          table.insert(pet, draw_pet(pets[buf][i + 1], pets[buf][1], text, line_num + i - 1))
          -- table.insert(pet, draw_pet(pets[buf][i + 1], pets[buf][1], string.format("%s", buf), line_num + i - 1))
        end
      end
      return pet
    else
      return start(buf)
    end
  end
end

-- @returns list
moved = function(buf)
  if pets[buf] and pets[buf][1] then
    line_num = compute_line_num()
    local pet = { pets[buf][1] }
    if (line_num == -2) then
      return pets[buf]
    elseif (line_num == -1) then
      table.insert(pet, draw_pet(pets[buf][2], pets[buf][1], one_line_pet, 0))
    else
      for i, text in ipairs(moved_pet) do
        table.insert(pet, draw_pet(pets[buf][i + 1], pets[buf][1], text, line_num + i - 1))
        -- table.insert(pet, draw_pet(pets[buf][i + 1], pets[buf][1], string.format("%s", buf), line_num + i - 1))
      end
    end
    return pet
  else
    return start(buf)
  end
end

clear = function(buf)
  if api.nvim_buf_is_valid(buf) then
    if pets[buf] and pets[buf][1] then
      api.nvim_buf_clear_namespace(0, pets[buf][1], 0, -1)
    end
  end
end

api.nvim_create_autocmd({ "WinEnter", "VimEnter" }, 
  { 
    callback = function(args) 
      pets[args.buf] = moved(args.buf) 
    end,
  }
)

api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, 
  { 
    callback = function(args) 
      pets[args.buf] = moved(args.buf) 
    end, 
  }
)

api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, 
  { 
    callback = function(args) 
      pets[args.buf] = afk(args.buf)
    end, 
  }
)

-- api.nvim_create_autocmd({ "WinLeave" },
--   {
--     callback = function(args)
--       pets[args.buf] = afk(args.buf)
--       -- clear(args.buf)
--     end,
--   }
-- )
