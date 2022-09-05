-- pet.nvim 
-- Shows a cat on the right of the screen at CursorLine, using virtualtext.
--
-- Requirements: 
-- - FixCursorHold
--
-- TODO:
--   1) Cat paces around
--   2) Different pets!
--
--  BUG:
--   1) Cats appear weirdly in Floaterm
--   2) ~                      in Telescope

local api = vim.api

local compute_line_no = function()
  local line_no = api.nvim_win_get_cursor(0)[1]
  local line_count = api.nvim_buf_line_count(0)
  if (line_count == 1) then
    -- buffer only has 1 line, we can't render the whole cat
    return -1
  elseif (line_count == line_no) then 
    -- we are on the last line of the buffer, move the cat one line up
    return line_no - 2
  elseif (line_count > line_no) then
    -- render normally
    return line_no - 1
  else 
    -- something wrong, kill cat :<
    return -2
  end
end

-- pet sprites
local afk_pet = { "  ╭──╮ ", "^.^──╯╮" }
local moved_pet = { "^.^──╮╯", "  ╰──╯ " }

local afk = function()
  if (namespace) then
    api.nvim_buf_clear_namespace(0, namespace, 0, -1)
    if (line_num == -2) then
      return
    end
    if (line_num == -1) then
      api.nvim_buf_set_extmark(0, namespace, 0, col_num, {
        virt_text = {{ afk_pet[2], "Normal" }},
        virt_text_pos = "right_align",
      })
    else 
      api.nvim_buf_set_extmark(0, namespace, line_num, col_num, {
        virt_text = {{ afk_pet[1], "Normal" }},
        virt_text_pos = "right_align",
      })
      api.nvim_buf_set_extmark(0, namespace, line_num + 1, col_num, {
        virt_text = {{ afk_pet[2], "Normal" }},
        virt_text_pos = "right_align",
      })
    end
  else
    start()
  end
end

local moved = function()
  if (namespace) then
    api.nvim_buf_clear_namespace(0, namespace, 0, -1)
    line_num = compute_line_no()
    if (line_num == -2) then
      return
    elseif (line_num == -1) then
      api.nvim_buf_set_extmark(0, namespace, 0, col_num, {
        virt_text = {{ moved_pet[1], "Normal" }},
        virt_text_pos = "right_align",
      })
    else
      api.nvim_buf_set_extmark(0, namespace, line_num, col_num, {
        virt_text = {{ moved_pet[1], "Normal" }},
        virt_text_pos = "right_align",
      })
      api.nvim_buf_set_extmark(0, namespace, line_num + 1, col_num, {
        virt_text = {{ moved_pet[2], "Normal" }},
        virt_text_pos = "right_align",
      })
    end
  else
    start()
  end
end

local start = function()
  -- TODO: does clearing all namespaces affect other plugins?
  namespace = api.nvim_create_namespace(string.format('pet%s', api.nvim_get_current_buf()))
  api.nvim_buf_clear_namespace(0, -1, 0, -1)
  line_num = compute_line_no()
  col_num = 0
  afk()
end

api.nvim_create_autocmd({ "BufEnter" }, {
  callback = start,
})
api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
  callback = moved,
})
api.nvim_create_autocmd({ "BufLeave", "CursorHold", "CursorHoldI" }, {
  callback = afk,
})
