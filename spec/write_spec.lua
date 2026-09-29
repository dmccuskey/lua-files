--====================================================================--
-- spec/write_spec.lua
--
-- Testing for lua-files using Busted: functions that write or remove
-- files, and readConfigFile() of a whole file
--====================================================================--


package.path = './dmc_lua/?.lua;' .. package.path

local File = require 'lua_files'
local lfs = require 'lfs'


-- a new, empty folder for each test
local function makeTempDir()
	local path = os.tmpname()
	os.remove( path )
	assert( lfs.mkdir( path ) )
	return path
end

local function mode( path )
	return lfs.symlinkattributes( path, 'mode' )
end


describe( "Module Test: lua_files.lua, writing", function()

	local dir

	before_each( function()
		dir = makeTempDir()
	end)

	after_each( function()
		if dir and mode( dir ) then File.remove( dir ) end
	end)


	describe( "Tests for saveFile and the JSON files", function()

		it( "File.saveFile", function()
			local path = dir .. '/a.txt'
			File.saveFile( path, "one\ntwo\n" )
			assert.is.equal( File.readFileContents( path ), "one\ntwo\n" )

			-- replaces the contents
			File.saveFile( path, "three" )
			assert.is.equal( File.readFileContents( path ), "three" )
		end)

		it( "File.writeJSONFile and File.readJSONFile", function()
			local path = dir .. '/a.json'
			File.writeJSONFile( path, { player='ann', points={ 10, 25 } } )
			local data = File.readJSONFile( path )
			assert.is.equal( data.player, 'ann' )
			assert.is.equal( data.points[2], 25 )
		end)

		it( "File.readJSONFile of an empty file", function()
			local path = dir .. '/empty.json'
			File.saveFile( path, "" )
			assert.has.error( function() File.readJSONFile( path ) end,
				"JSON file is empty: " .. path )
		end)

		it( "File.readFile leaves its options alone", function()
			local path = dir .. '/a.txt'
			File.saveFile( path, "one\ntwo\n" )
			local options = {}
			assert.is.same( File.readFile( path, options ), { 'one', 'two' } )
			assert.is.same( options, {} )
		end)

	end)


	describe( "Tests for readConfigFile", function()

		it( "File.readConfigFile", function()
			local path = dir .. '/app.cfg'
			File.saveFile( path, [[
-- a comment
TIMEOUT:INT = 30

[SERVER2]
HOST = example.com
PORT2:INT = 8080
SECURE:BOOL = true
LOADER:PATH = lib/dmc_lua
DEFAULTS:JSON = { "retries": 3 }
Name:str = 'Space Game'
]] )
			local cfg = File.readConfigFile( path )
			assert.is.same( cfg, {
				default = { timeout = 30 },
				server2 = { host = 'example.com', port2 = 8080, secure = true,
					loader = 'lib.dmc_lua', defaults = { retries = 3 },
					name = 'Space Game' },
			} )
			assert.is_nil( rawget( _G, 'key_value' ) )
		end)

		it( "File.readConfigFile, default section name", function()
			local path = dir .. '/app.cfg'
			File.saveFile( path, "KEY = 1\n" )
			local cfg = File.readConfigFile( path, { default_section='main' } )
			assert.is.equal( cfg.main.key, '1' )
		end)

	end)


	describe( "Tests for remove", function()

		it( "removes a file", function()
			local path = dir .. '/a.txt'
			File.saveFile( path, "x" )
			File.remove( path )
			assert.is_nil( mode( path ) )
		end)

		it( "removes a folder and everything in it", function()
			assert( lfs.mkdir( dir .. '/sub' ) )
			File.saveFile( dir .. '/a.txt', "x" )
			File.saveFile( dir .. '/sub/b.txt', "x" )
			File.remove( dir )
			assert.is_nil( mode( dir ) )
		end)

		it( "empties a folder with rm_dir=false", function()
			assert( lfs.mkdir( dir .. '/sub' ) )
			File.saveFile( dir .. '/a.txt', "x" )
			File.saveFile( dir .. '/sub/b.txt', "x" )
			File.remove( dir, { rm_dir=false } )
			assert.is.equal( mode( dir ), 'directory' )
			assert.is.equal( mode( dir .. '/sub' ), 'directory' )
			assert.is_nil( mode( dir .. '/a.txt' ) )
			assert.is_nil( mode( dir .. '/sub/b.txt' ) )
		end)

		it( "removes a list of paths, skipping missing ones", function()
			File.saveFile( dir .. '/a.txt', "x" )
			File.saveFile( dir .. '/b.txt', "x" )
			File.saveFile( dir .. '/c.txt', "x" )
			File.remove( { dir .. '/a.txt', dir .. '/missing.txt', dir .. '/b.txt' } )
			assert.is_nil( mode( dir .. '/a.txt' ) )
			assert.is_nil( mode( dir .. '/b.txt' ) )
			assert.is.equal( mode( dir .. '/c.txt' ), 'file' )
		end)

		it( "removes a link, not what it points to", function()
			local other = makeTempDir()
			File.saveFile( other .. '/keep.txt', "x" )
			assert( os.execute( "ln -s '" .. other .. "' '" .. dir .. "/link'" ) == 0 )
			File.remove( dir )
			assert.is_nil( mode( dir ) )
			assert.is.equal( mode( other .. '/keep.txt' ), 'file' )
			File.remove( other )
		end)

		it( "raises when a file can't be removed", function()
			assert( lfs.mkdir( dir .. '/locked' ) )
			File.saveFile( dir .. '/locked/a.txt', "x" )
			assert( os.execute( "chmod 555 '" .. dir .. "/locked'" ) == 0 )
			assert.has.error( function() File.remove( dir .. '/locked' ) end,
				dir .. '/locked/a.txt: Permission denied' )
			assert( os.execute( "chmod 755 '" .. dir .. "/locked'" ) == 0 )
		end)

		it( "takes only a path or a list", function()
			assert.has.errors( function() File.remove( 12 ) end )
		end)

	end)

end)
