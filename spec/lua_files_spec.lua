--====================================================================--
-- spec/lua_files_spec.lua
--
-- Testing for lua-files using Busted
--====================================================================--


package.path = './dmc_lua/?.lua;' .. package.path


--====================================================================--
--== Test: Lua Files
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"



--====================================================================--
--== Imports


local File = require 'lua_files'



--====================================================================--
--== Testing Setup
--====================================================================--


describe( "Module Test: lua_files.lua", function()


	describe( "Tests for fileExists", function()

		it( "File.fileExists", function()
			local res

			res = File.fileExists( 'spec/lua_files_spec.lua' )
			assert.is_true( res )

			res = File.fileExists( 'spec/_NO_FILE_HERE_.txt' )
			assert.is_false( res )

		end)

	end)


	describe( "Tests for read/write JSON File", function()

		it( "File.convertJsonToLua", function()
			local j
			j = File.convertJsonToLua( '{ "hello":123 }' )
			assert.is.equal( j.hello, 123 )

			--== Invalid

			assert.has.errors( function() File.convertJsonToLua( {} ) end )
			assert.has.errors( function() File.convertJsonToLua( "" ) end )

			-- double quotes
			assert.has.errors( function() File.convertJsonToLua( "{ 'hello':123 }" ) end )
			-- equals sign
			assert.has.errors( function() File.convertJsonToLua( '{ "hello"=123 }' ) end )

		end)

	end)


	describe( "Tests for readFile", function()

		describe( "readFileLines tests", function()

			it( "reads in lines", function()

				local content

				content = File.readFileLines( 'spec/file_lines.txt' )

				-- number of lines
				assert.is.equal( #content, 5 )
				assert.is.equal( content[1], 'one' )
				assert.is.equal( content[2], 'two' )
				assert.is.equal( content[3], 'three' )
				assert.is.equal( content[4], 'four' )
				assert.is.equal( content[5], 'five' )

				assert.has.errors( function() File.readFileLines( '-NO-FILE.txt' ) end )

			end)

		end)


		describe( "readFileContents tests", function()

			it( "reads in entire file", function()

				local content

				content = File.readFileContents( 'spec/file_content.txt' )

				-- length of content string
				assert.is.equal( #content, 28 )
				assert.is.equal( content, "one two\nthree four\nfive six\n" )

				assert.has.errors( function() File.readFileContents( '-NO-FILE.txt' ) end )

			end)

		end)

		describe( "readFile tests", function()

			it( "readFile as lines", function()
					local content, content2

					content = File.readFile( 'spec/file_lines.txt', {lines=true} )

					-- number of lines
					assert.is.equal( #content, 5 )
					assert.is.equal( content[1], 'one' )
					assert.is.equal( content[2], 'two' )
					assert.is.equal( content[3], 'three' )
					assert.is.equal( content[4], 'four' )
					assert.is.equal( content[5], 'five' )

					assert.has.errors( function() File.readFile( '-NO-FILE.txt', {lines=true} ) end )

					-- read default, as lines
					content2 = File.readFile( 'spec/file_lines.txt' )
					assert.is.equal( #content, #content2 )
					assert.is.equal( content[1], content2[1] )
					assert.is.equal( content[2], content2[2] )
					assert.is.equal( content[3], content2[3] )
					assert.is.equal( content[4], content2[4] )
					assert.is.equal( content[5], content2[5] )

			end)

			it( "readFile as content", function()
					local content

					content = File.readFile( 'spec/file_content.txt', {lines=false} )

					-- length of content string
					assert.is.equal( #content, 28 )
					assert.is.equal( content, "one two\nthree four\nfive six\n" )

					assert.has.errors( function() File.readFile( '-NO-FILE.txt', {lines=false} ) end )

			end)

		end)


	end)



	describe( "Tests for readingConfigFile", function()

		it( "File.getLineType", function()
			local is_section, is_key

			is_section, is_key = File.getLineType( '[SECTION]' )
			assert.is.equal( is_section, true )
			assert.is.equal( is_key, false )

			is_section, is_key = File.getLineType( 'KEY_WORD' )
			assert.is.equal( is_section, false )
			assert.is.equal( is_key, true )

			--== Invalid

			is_section, is_key = File.getLineType( '[section]' )
			assert.is.equal( is_section, false )
			assert.is.equal( is_key, false )

			is_section, is_key = File.getLineType( 'key_word' )
			assert.is.equal( is_section, false )
			assert.is.equal( is_key, false )

			is_section, is_key = File.getLineType( '' )
			assert.is.equal( is_section, false )
			assert.is.equal( is_key, false )

			is_section, is_key = File.getLineType( '-- commented line' )
			assert.is.equal( is_section, false )
			assert.is.equal( is_key, false )

		end)


		it( "File.processSectionLine", function()
			assert.is.equal( File.processSectionLine( "[KEY_LINE]" ), 'key_line' )

			assert.has.errors( function() File.processSectionLine( "[frank]" ) end )
			assert.has.errors( function() File.processSectionLine( "[KEY_LINE" ) end )
			assert.has.errors( function() File.processSectionLine( "KEY_LINE]" ) end )
		end)


		it( "File.processKeyLine", function()
			local key_name, key_value

			key_name, key_value = File.processKeyLine( "KEY_LINE:BOOL = true " )
			assert.is.equal( key_name, 'key_line' )
			assert.is.equal( key_value, true )

			key_name, key_value = File.processKeyLine( "HELLOWORLD:INT  =  45  " )
			assert.is.equal( key_name, 'helloworld' )
			assert.is.equal( key_value, 45 )

			key_name, key_value = File.processKeyLine( "THEPATH:PATH  =  '/one/two/three'  " )
			assert.is.equal( key_name, 'thepath' )
			assert.is.equal( key_value, '.one.two.three' )

			key_name, key_value = File.processKeyLine( 'THEPATH:PATH  =  "/one/two/three"  ' )
			assert.is.equal( key_value, '.one.two.three' )

			key_name, key_value = File.processKeyLine( 'THEPATH:PATH  =  /one/two/three  ' )
			assert.is.equal( key_value, '.one.two.three' )

			-- incorrect type, default to string
			key_name, key_value = File.processKeyLine( 'THE: PATH  =  "/one/two/three"  ' )
			assert.is.equal( key_value, '/one/two/three' )

			-- mismatched quotes
			assert.has.errors( function() File.processKeyLine( 'THE:PATH="/one/two\'' ) end )
		end)

		it( "File.processKeyName", function()
			assert.is.equal( File.processKeyName( 'HAROLD' ), 'harold' )
			assert.is.equal( File.processKeyName( 'LUA_PATH' ), 'lua_path' )

			assert.has.errors( function() File.processKeyName( 123 ) end )
			assert.has.errors( function() File.processKeyName( "" ) end )
			assert.has.errors( function() File.processKeyName( {} ) end )
		end)
		it( "File.processKeyType", function()
			assert.is.equal( File.processKeyType( 'STRING' ), 'string' )
			assert.is.equal( File.processKeyType( 'BOOL' ), 'bool' )
			assert.is.equal( File.processKeyType( 'INT' ), 'int' )
			assert.is.equal( File.processKeyType( nil ), nil )
		end)

		it( "File.castTo_boolean tests", function()
			assert.is.equal( File.castTo_boolean( 'true' ), true )
			assert.is.equal( File.castTo_bool( 'true' ), true )

			assert.is.equal( File.castTo_boolean( 'false' ), false )
			assert.is.equal( File.castTo_bool( 'false' ), false )

			assert.is.equal( File.castTo_boolean( 'fdsfd' ), false )
			assert.is.equal( File.castTo_bool( 'fdsfd' ), false )
		end)
		it( "File.castTo_integer tests", function()
			assert.is.equal( File.castTo_integer( '120' ), 120 )
			assert.is.equal( File.castTo_int( '120' ), 120 )

			assert.has.errors( function() File.castTo_integer( nil ) end )
			assert.has.errors( function() File.castTo_int( nil ) end )

			assert.has.errors( function() File.castTo_integer( {} ) end )
			assert.has.errors( function() File.castTo_int( {} ) end )

			assert.has.errors( function() File.castTo_integer( 'frank' ) end )
			assert.has.errors( function() File.castTo_int( 'frank' ) end )
		end)
		it( "File.castTo_json tests", function()
			local j = File.castTo_json( '{ "hello":"123"}' )
			assert.is.equal( j.hello, '123' )
			assert.is.equal( type(j), 'table' )

			assert.has.errors( function() File.castTo_json( nil ) end )
			assert.has.errors( function() File.castTo_json( {} ) end )
			assert.has.errors( function() File.castTo_json( 'frank' ) end )
		end)
		it( "File.castTo_path tests", function()
			assert.is.equal( File.castTo_path( 'lib/one/two/three' ), 'lib.one.two.three' )

			assert.has.errors( function() File.castTo_path( nil ) end )
			assert.has.errors( function() File.castTo_path( {} ) end )
			assert.has.errors( function() File.castTo_path(  ) end )
		end)
		it( "File.castTo_file tests", function()
			assert.is.equal( File.castTo_file( 'file/name.jpg' ), 'file/name.jpg' )

			assert.has.errors( function() File.castTo_file( nil ) end )
			assert.has.errors( function() File.castTo_file( {} ) end )
		end)
		it( "File.castTo_string tests", function()
			assert.is.equal( File.castTo_string( 120 ), '120' )
			assert.is.equal( File.castTo_str( 120 ), '120' )

			assert.is.equal( File.castTo_string( 'frank' ), 'frank' )
			assert.is.equal( File.castTo_str( 'frank' ), 'frank' )

			assert.has.errors( function() File.castTo_string( nil ) end )
			assert.has.errors( function() File.castTo_str( nil ) end )

			assert.has.errors( function() File.castTo_string( {} ) end )
			assert.has.errors( function() File.castTo_str( {} ) end )
		end)


	end) -- reading config file


end)
