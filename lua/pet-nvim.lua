-- pet.nvim 
-- Shows a cat on the right of the screen at CursorLine, using virtualtext.
--
-- Requirements: 
-- - FixCursorHold
--
-- TODO:
--   1) Cat paces around
--   2) Different pets!

local api = vim.api

local compute_line_no = function()
  local line_no = api.nvim_win_get_cursor(0)[1]
  local line_count = api.nvim_buf_line_count(0)
  if (line_count == line_no) then 
    return line_no - 2
  elseif (line_count > line_no) then
    return line_no - 1
  else 
    -- something wrong, kill cat :<
    return -1
  end
end

local namespace = api.nvim_create_namespace('pet')
local line_num = compute_line_no()
local col_num = 0

local start = function()
  if (line_num == -1) then
    return
  end
  api.nvim_buf_set_extmark(0, namespace, line_num, col_num, {
    virt_text = {{ "╭──╮ ", "Normal" }},
    virt_text_pos = "right_align",
  })
  api.nvim_buf_set_extmark(0, namespace, line_num + 1, col_num, {
    virt_text = {{ "^.^──╯╮", "Normal" }},
    virt_text_pos = "right_align",
  })
end


local moved = function()
  if (namespace) then
    api.nvim_buf_clear_namespace(0, namespace, 0, -1)
    line_num = compute_line_no()
    if (line_num == -1) then
      return
    end
    api.nvim_buf_set_extmark(0, namespace, line_num, col_num, {
      virt_text = {{ "^.^──╮╯", "Normal" }},
      virt_text_pos = "right_align",
    })
    api.nvim_buf_set_extmark(0, namespace, line_num + 1, col_num, {
      virt_text = {{ "╰──╯ ", "Normal" }},
      virt_text_pos = "right_align",
    })
  end
end

local afk = function()
  if (namespace) then
    api.nvim_buf_clear_namespace(0, namespace, 0, -1)
    start()
  end
end

start()
api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
  callback = moved,
})
api.nvim_create_autocmd({ "CursorHold" }, {
  callback = afk,
})
