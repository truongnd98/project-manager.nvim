return require("telescope").register_extension({
	setup = function(ext_config, config)
		-- access extension config and user config
	end,
	exports = {
		find_dirs = require("project-manager").find_dirs,
		live_find_dirs = require("project-manager").live_find_dirs,
	},
})
