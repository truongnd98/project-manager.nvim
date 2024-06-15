local pm_t = require("project-manager.telescope")

return require("telescope").register_extension({
	setup = function(ext_config, config)
		-- access extension config and user config
	end,
	exports = {
		find_files = pm_t.find_files,
		live_grep = pm_t.live_grep,
		find_dirs = pm_t.find_dirs,
		live_find_dirs = pm_t.live_find_dirs,
		grep_string = pm_t.grep_string,
	},
})
