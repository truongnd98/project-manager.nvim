return require("telescope").register_extension({
	setup = function(ext_config, config)
		-- access extension config and user config
	end,
	exports = {
		find_files = require("project-manager").find_files,
		live_grep = require("project-manager").live_grep,
		find_dirs = require("project-manager").find_dirs,
		live_find_dirs = require("project-manager").live_find_dirs,
		grep_string = require("project-manager").grep_string,
	},
})
