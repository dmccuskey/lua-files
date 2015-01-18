# lua-files

try:
	if not gSTARTED: print( gSTARTED )
except:
	MODULE = "lua-files"
	include: "../DMC-Lua-Library/snakemake/Snakefile"

module_config = {
	"name": "lua-files",
	"module": {
		"dir": "dmc_lua",
		"files": [
			"lua_files.lua"
		],
		"requires": [
			"lua-error",
			"lua-json-shim",
			"lua-objects"
		]
	},
	"tests": {
		"dir": "spec",
		"files": [],
		"requires": []
	}
}

register( "lua-files", module_config )


