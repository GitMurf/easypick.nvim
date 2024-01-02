local previewers = require("telescope.previewers")
local putils = require("telescope.previewers.utils")
local from_entry = require("telescope.from_entry")
local conf = require("telescope.config").values

local function run_shell_command(cmd)
  local handle = io.popen(cmd)
  local git_result = ""
  if handle ~= nil then
    git_result = handle:read("*a")
    handle:close()
  end
  return git_result
end

local default = function(opts)
  opts = opts or {}
  return previewers.vim_buffer_cat.new(opts)
end

local branch_diff = function(opts)
  return previewers.new_buffer_previewer({
    title = "Git Branch Diff Preview",
    get_buffer_by_name = function(_, entry)
      return entry.value
    end,

    define_preview = function(self, entry, _)
      local file_name = entry.value
      local get_git_status_command = "git status -s -- " .. file_name
      local git_status = io.popen(get_git_status_command):read("*a")
      local git_status_short = string.sub(git_status, 1, 1)
      if git_status_short ~= "" then
        print("IF1")
        local p = from_entry.path(entry, true)
        if p == nil or p == "" then
          return
        end
        conf.buffer_previewer_maker(p, self.state.bufnr, {
          bufname = self.state.bufname,
          winid = self.state.winid,
        })
      else
        print("ELSE1")
        putils.job_maker(
          { "git", "--no-pager", "diff", opts.base_branch .. "..HEAD", "--", file_name },
          self.state.bufnr,
          {
            value = file_name,
            bufname = self.state.bufname,
          }
        )
        putils.regex_highlighter(self.state.bufnr, "diff")
      end
    end,
  })
end

local gm_git_diff = function(opts)
  return previewers.new_buffer_previewer({
    title = "Git Diff Preview",
    get_buffer_by_name = function(_, entry)
      return entry.value
    end,

    define_preview = function(self, entry, _)
      local file_name_entry = entry.value
      local file_name = string.sub(file_name_entry, 4)
      local get_first_three_chars = string.sub(file_name_entry, 1, 3)
      local git_status_short = string.sub(get_first_three_chars:gsub("%s+", ""), 1, 1)
      local arrow_index = string.find(file_name, "->") or "N/A"
      local old_file_name = ""
      if arrow_index ~= "N/A" then
        local file_name_left = string.sub(file_name, 1, arrow_index - 1)
        local file_name_right = string.sub(file_name, arrow_index + 3)
        file_name = file_name_right
        old_file_name = file_name_left
      end
      -- local get_git_status_command = "git status -s -- " .. file_name
      -- local git_status = io.popen(get_git_status_command):read("*a")
      -- local trimmed_git_status = git_status:gsub("%s+", "")
      -- local git_status_short = string.sub(trimmed_git_status, 1, 1)
      if git_status_short == "" then
        local p = from_entry.path(entry, true)
        if p == nil or p == "" then
          return
        end
        conf.buffer_previewer_maker(p, self.state.bufnr, {
          bufname = self.state.bufname,
          winid = self.state.winid,
        })
      else
        -- print("base_branch: " .. opts.base_branch)
        -- if git_status_short == "M" or git_status_short == "D"
        if git_status_short == "A" or git_status_short == "?" then
          -- local git_command = "git --no-pager diff --no-index /dev/null " .. file_name
          -- local git_result = run_shell_command(git_command)
          putils.job_maker({ "git", "--no-pager", "diff", "--no-index", "/dev/null", file_name }, self.state.bufnr, {
            value = file_name,
            bufname = self.state.bufname,
          })
          putils.regex_highlighter(self.state.bufnr, "diff")
        elseif git_status_short == "R" then
          -- local git_command = "git --no-pager diff HEAD -M -- " .. old_file_name .. " " .. file_name
          -- local git_result = run_shell_command(git_command)
          -- putils.job_maker(
          --   { "git", "--no-pager", "diff", "HEAD", "-M", "--", old_file_name, file_name },
          --   self.state.bufnr,
          --   {
          --     value = file_name,
          --     bufname = self.state.bufname,
          --   }
          -- )
          -- putils.regex_highlighter(self.state.bufnr, "diff")

          local p = from_entry.path(entry, true)
          conf.buffer_previewer_maker(p, self.state.bufnr, {
            bufname = self.state.bufname,
            winid = self.state.winid,
          })
        else
          -- local git_command = "git --no-pager diff HEAD -- " .. file_name
          -- local git_result = run_shell_command(git_command)
          putils.job_maker({ "git", "--no-pager", "diff", "HEAD", "--", file_name }, self.state.bufnr, {
            value = file_name,
            bufname = self.state.bufname,
          })
          putils.regex_highlighter(self.state.bufnr, "diff")
        end
      end
    end,
  })
end

local file_diff = function(opts)
  opts = opts or {}
  return previewers.git_file_diff.new(opts)
end

return {
  default = default,
  branch_diff = branch_diff,
  file_diff = file_diff,
  gm_git_diff = gm_git_diff,
}
