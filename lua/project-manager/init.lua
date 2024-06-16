local pm_state = require("project-manager.project.state")

local M = {}

local DEFAULT_OPTS = {
	icons = {
		folder = {
			default = "",
			open = "",
			empty = "",
			empty_open = "",
		},
	},
	highlights = {
		finder_folder_icon_default = {
			name = "PMFinderFolderIconDefault",
			fg = "#7AA2F7",
			bg = "",
		},
		finder_folder_icon_empty = {
			name = "PMFinderFolderIconEmpty",
			fg = "#7AA2F7",
			bg = "",
		},
		finder_folder_path = {
			name = "PMFinderFolderPath",
			fg = "",
			bg = "",
		},
		finder_filter_matching = {
			name = "PMFinderFilterMatching",
			fg = "#FF6E18",
			bg = "",
		},
		previewer_folder_icon = {
			name = "PMPreviewerFolderIcon",
			fg = "#7AA2F7",
			bg = "",
		},
		previewer_folder_name = {
			name = "PMPreviewerFolderName",
			fg = "#7AA2F7",
			bg = "",
		},
		previewer_file_name = {
			name = "PMPreviewerFileName",
			fg = "#E0AF68",
			bg = "",
		},
		previewer_tree_indent = {
			name = "PMPreviewerTreeIndent",
			fg = "#7AA2F7",
			bg = "",
		},
		previewer_tree_root_path = {
			name = "PMPreviewerTreeRootPath",
			fg = "#7AA2F7",
			bg = "",
		},
	},
	fd = {
		default_exclude = {
			"node_modules",
			".git",
		},
	},
	eza = {
		default_exclude = {
			"node_modules",
			".git",
		},
	},
	rg = {
		default_exclude = {
			"node_modules",
			".git",
		},
	},
}

local function merge_options(conf)
	return vim.tbl_deep_extend("force", DEFAULT_OPTS, conf or {})
end

local function validate_options(conf)
	return conf
end

local function setup_hl(hls)
	local set_hl = vim.api.nvim_set_hl
	for _, v in pairs(hls) do
		set_hl(0, v.name, {
			fg = v.fg,
			bg = v.bg,
			sp = v.sp,
			reverse = v.reverse,
			bold = v.bold,
			italic = v.italic,
			undercurl = v.undercurl,
			strikethrough = v.strikethrough,
		})
	end
end

M.setup = function(conf)
	validate_options(conf)

	local opts = merge_options(conf)
	M.config = opts

	setup_hl(M.config.highlights)

	-- Load project state from $HOME/.local/state/nvim/project-manager.nvim/state.json
	pm_state.load()
end

M.get_icons = function()
	return M.config.icons
end

M.get_hls = function()
	return M.config.highlights
end

M.get_config = function(key)
	return M.config[key]
end

return M
