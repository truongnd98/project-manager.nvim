local Job = require("plenary.job")
local Path = require("plenary.path")

local t_previewers = require("telescope.previewers")
local t_utils = require("telescope.utils")
local t_from_entry = require("telescope.from_entry")

local devicons = require("nvim-web-devicons")

local M = {}

local job_maker = function(cmd, bufnr, opts)
	opts = opts or {}
	opts.mode = opts.mode or "insert"
	-- bufname and value are optional
	-- if passed, they will be use as the cache key
	-- if any of them are missing, cache will be skipped
	if opts.bufname ~= opts.value or not opts.bufname or not opts.value then
		local command = table.remove(cmd, 1)
		local writer = (function()
			if opts.writer ~= nil then
				local wcommand = table.remove(opts.writer, 1)
				return Job:new({
					command = wcommand,
					args = opts.writer,
					env = opts.env,
					cwd = opts.cwd,
				})
			end
		end)()

		Job:new({
			command = command,
			args = cmd,
			env = opts.env,
			cwd = opts.cwd,
			writer = writer,
			on_exit = vim.schedule_wrap(function(j)
				if not vim.api.nvim_buf_is_valid(bufnr) then
					return
				end
				local data = j:result()
				local highlights = {}
				if opts.render then
					data, highlights = opts.render(bufnr, data)
				end
				if opts.mode == "append" then
					vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, data)
				elseif opts.mode == "insert" then
					vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, data)
				end

				for _, highlight in ipairs(highlights) do
					local buffer, ns_id, hl_group, line, col_start, col_end = unpack(highlight)
					vim.api.nvim_buf_add_highlight(buffer, ns_id, hl_group, line, col_start, col_end)
				end

				if opts.callback then
					opts.callback(bufnr, data)
				end
			end),
		}):start()
	else
		if opts.callback then
			opts.callback(bufnr)
		end
	end
end

M.eza = function(opts)
	opts = opts or {}

	local cwd = opts.cwd or vim.loop.cwd()

	return t_previewers.new_buffer_previewer({
		title = "Eza Preview",
		dyn_title = function(_, entry)
			return Path:new(t_from_entry.path(entry, false, false)):normalize(cwd)
		end,

		get_buffer_by_name = function(_, entry)
			return t_from_entry.path(entry, false, false)
		end,

		define_preview = function(self, entry)
			local dirname = t_from_entry.path(entry, true, false)
			if dirname == nil or dirname == "" then
				return
			end

			if not vim.fn.executable("eza") then
				t_utils.notify("project-manager.telescope.previewers.eza", {
					msg = "You need to install eza",
					level = "ERROR",
				})
				return
			end

			local cmd = {
				"eza",
				"--all",
				"--tree",
				"--icons",
				"always",
				"--level",
				"3",
			}

			if opts.__eza_exclude then
				if type(opts.__eza_exclude) == "string" then
					vim.list_extend(cmd, { "--ignore-glob", opts.__eza_exclude })
				elseif type(opts.__eza_exclude) == "table" then
					vim.list_extend(cmd, { "--ignore-glob", table.concat(opts.__eza_exclude, "|") })
				end
			end

			vim.list_extend(cmd, { t_utils.path_expand(dirname) })

			job_maker(cmd, self.state.bufnr, {
				value = entry.value,
				bufname = self.state.bufname,
				cwd = opts.cwd,
				render = function(bufnr, content)
					if not content then
						return
					end

					local patterns = {
						"├── .+$",
						"└── .+$",
					}

					local directory_icons = {
						["\u{e5ff}"] = "FOLDER", -- FOLDER        
						["\u{e5fc}"] = "FOLDER_CONFIG", -- FOLDER_CONFIG 
						["\u{e5fb}"] = "FOLDER_GIT", -- FOLDER_GIT    
						["\u{e5fd}"] = "FOLDER_GITHUB", -- FOLDER_GITHUB 
						["\u{f179e}"] = "FOLDER_HIDDEN", -- FOLDER_HIDDEN 󱞞
						["\u{f08ac}"] = "FOLDER_KEY", -- FOLDER_KEY    󰢬
						["\u{e5fa}"] = "FOLDER_NPM", -- FOLDER_NPM    
						["\u{f115}"] = "FOLDER_OPEN", -- FOLDER_OPEN   
						["\u{f1f8}"] = "Trash", -- .Trash 
						["\u{f024c}"] = "Contacts", -- Contacts 󰉌
						["\u{f108}"] = "Desktop", -- Desktop 
						["\u{f024d}"] = "Downloads", -- Downloads 󰉍
						["\u{f069d}"] = "Favorites", -- Favorites 󰚝
						["\u{f10b5}"] = "home", -- home 󱂵
						["\u{f01f0}"] = "Mail", -- Mail 󰇰
						["\u{f0fce}"] = "Movies", -- Movies 󰿎
						["\u{f1359}"] = "Music", -- Music 󱍙
						["\u{f024f}"] = "Pictures", -- Pictures 󰉏
						["\u{f03d}"] = "Videos", -- Videos 
					}

					local content_render, highlights = {}, {}

					content_render[1] = content[1]
					table.insert(
						highlights,
						{ bufnr, -1, opts.__highlight.previewer_tree_root_path.name, 0, 0, #content_render[1] }
					)

					for i = 2, #content do
						content_render[i] = content[i]
						for j = 1, #patterns do
							local pattern = patterns[j]
							local col_start, col_end = string.find(content[i], pattern)
							if col_start and col_end then
								local icon_start, icon_end = string.find(content[i], " %S+ ", col_start)

								icon_start, icon_end = icon_start + 1, icon_end - 1
								local link_start, link_end = 1, icon_start - 1
								local name_start, name_end = icon_end + 1, col_end

								local link = string.sub(content[i], link_start, link_end)
								local icon = string.sub(content[i], icon_start, icon_end)
								local name = string.sub(content[i], name_start, name_end)

								table.insert(highlights, {
									bufnr,
									-1,
									opts.__highlight.previewer_tree_indent.name,
									i - 1,
									link_start - 1,
									link_end,
								})

								local is_directory = directory_icons[icon]
								if is_directory then
									content_render[i] = content[i]

									table.insert(highlights, {
										bufnr,
										-1,
										opts.__highlight.previewer_folder_icon.name,
										i - 1,
										icon_start - 1,
										icon_end - 1,
									})
									table.insert(highlights, {
										bufnr,
										-1,
										opts.__highlight.previewer_folder_name.name,
										i - 1,
										name_start - 1,
										name_end,
									})
								else
									local lower_name = string.lower(name)
									local ext_start, ext_end = string.find(lower_name, "%..+$")
									local ext = ""

									if ext_start then
										ext = string.sub(lower_name, ext_start + 1, ext_end)
									end

									local new_icon, highlight_name =
										devicons.get_icon(lower_name, ext, { default = true })

									local new_content = link .. new_icon .. name

									local new_icon_start, new_icon_end = icon_start, icon_start + #new_icon
									name_start, name_end = new_icon_end + 1, new_icon_end + 1 + #name

									content_render[i] = new_content
									table.insert(
										highlights,
										{ bufnr, -1, highlight_name, i - 1, new_icon_start - 1, new_icon_end - 1 }
									)
									table.insert(highlights, {
										bufnr,
										-1,
										opts.__highlight.previewer_file_name.name,
										i - 1,
										name_start - 1,
										name_end - 1,
									})
								end

								break
							end
						end
					end

					return content_render, highlights
				end,
			})
		end,
	})
end

return M
