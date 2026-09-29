# lua-files

Read and write files in Lua in one call each: plain text, a file's lines, JSON, and simple config files with typed values.

lua-files was written for the DMC Solar2D (formerly Corona SDK) libraries, whose `dmc_corona.cfg` uses its config format, but it's plain Lua 5.1 and runs anywhere:

```lua
local File = require 'lua_files'

local lines = File.readFileLines( 'notes.txt' )      -- { 'one', 'two', ... }
local data = File.readJSONFile( 'scores.json' )      -- a Lua table
local cfg = File.readConfigFile( 'app.cfg' )         -- cfg.server.port is a number
```

## Features

- Read a whole file as a string, or as an array of its lines
- Write a string to a file
- Read a JSON file into a Lua table, through [lua-json-shim](https://github.com/dmccuskey/lua-json-shim) (dkjson, lua-cjson or Solar2D's `json`)
- Read a config file of `[SECTIONS]` and `KEY = value` lines, with the value cast by a type in the key (`PORT:INT = 8080`): boolean, number, JSON, module path, string
- Check whether a file exists
- Plain Lua 5.1; MIT licensed

## Quick Start

The following steps will get you up and running in about 5 minutes with Lua 5.1 on macOS or Linux. You will write a text file, a JSON file and a config file, and read each back.

Prerequisites: Lua 5.1 (`lua -v` shows `Lua 5.1.x`), LuaRocks and git.

### 1. Get the Code

In an empty folder:

```sh
git clone https://github.com/dmccuskey/lua-files.git
luarocks install dkjson
```

The module is `lua-files/dmc_lua/lua_files.lua`; the modules it needs are in the same folder. dkjson is the JSON module the shim finds; lua-cjson works too.

### 2. Use It

Create `main.lua` in the same folder:

```lua
package.path = './lua-files/dmc_lua/?.lua;' .. package.path
local File = require 'lua_files'

-- plain text
File.saveFile( 'notes.txt', "one\ntwo\nthree\n" )
print( File.fileExists( 'notes.txt' ), File.fileExists( 'missing.txt' ) )
local lines = File.readFileLines( 'notes.txt' )
print( #lines, lines[3] )

-- JSON
File.saveFile( 'scores.json', '{ "player":"ann", "points":[10,25] }' )
local scores = File.readJSONFile( 'scores.json' )
print( scores.player, scores.points[2] )

-- a config file
File.saveFile( 'app.cfg', [[
-- settings for the app
NAME = 'Space Game'
[SERVER]
HOST = example.com
PORT:INT = 8080
SECURE:BOOL = true
]] )
local cfg = File.readConfigFile( 'app.cfg' )
print( cfg.default.name, cfg.server.host, cfg.server.port + 1, cfg.server.secure )
```

Run it:

```sh
lua main.lua
```

```text
true	false
3	three
ann	25
Space Game	example.com	8081	true
```

It leaves `notes.txt`, `scores.json` and `app.cfg` in the folder. Without the `lfs` rock (LuaFileSystem) it also prints `WARNING: lua_files missing lfs module`, which is harmless: only the removal functions use it, and they don't work (see [Known Issues](#known-issues)). If it stops with `JSON library not loaded`, install dkjson.

To update, pull the repository again (`git -C lua-files pull`).

## Reference

Paths are ordinary file paths, relative to the current folder or absolute. Functions that open a file raise an error when it can't be opened, with `io.open()`'s message (`notes.txt: No such file or directory`).

### Text Files

| function | does |
|---|---|
| `readFileContents( path )` | Returns the whole file as a string. |
| `readFileLines( path )` | Returns an array of the file's lines, without their line endings. |
| `readFile( path, options )` | `readFileLines()`, or `readFileContents()` when `options.lines` is `false`. |
| `saveFile( path, data )` | Writes the string `data` to the file, replacing what it held. |
| `fileExists( path )` | `true` when the path can be opened for reading, otherwise `false`. |

### JSON Files

| function | does |
|---|---|
| `readJSONFile( path )` | Reads the file and returns it decoded (`convertJsonToLua()`). |
| `writeJSONFile( path, data )` | Broken: see [Known Issues](#known-issues). Use `saveFile( path, File.convertLuaToJson( data ) )`. |
| `convertJsonToLua( str )` | Decodes a JSON string. Errors on an empty string, and when the JSON module returns `nil` (`Error reading JSON file, probably malformed data`). |
| `convertLuaToJson( t )` | Encodes a table as a JSON string. |

The JSON module is whatever `require 'json'` loads: lua-json-shim in plain Lua, Solar2D's own `json` in Solar2D. When none loads, these functions raise `JSON library not loaded`.

### Config Files

`readConfigFile( path, options )` returns a table with one table per section, named in lowercase. This file:

```text
-- a comment: any line that doesn't start with an uppercase letter or '['
TIMEOUT:INT = 30

[SERVER]
HOST = example.com
PORT:INT = 8080
SECURE:BOOL = true
LOADER:PATH = lib/dmc_lua
DEFAULTS:JSON = { "retries": 3 }
```

reads as:

```lua
{
  default = { timeout = 30 },
  server = { host = 'example.com', port = 8080, secure = true,
             loader = 'lib.dmc_lua', defaults = { retries = 3 } },
}
```

- A line starting with `[` and an uppercase letter starts a section: `[NAME]`, uppercase letters and `_`. Keys before the first section go into `default` (`options.default_section` changes the name).
- A line starting with an uppercase letter is a key: `NAME = value` or `NAME:TYPE = value`, with the name in uppercase letters and `_`. Names become lowercase; a key given twice keeps the last value.
- The value is the rest of the line, trimmed. Matching quotes around it (`'...'` or `"..."`) are removed; unmatched ones raise `quotes must match`.
- Every other line is ignored: comments, blank lines, and lines that start with a space or a lowercase letter.

The type after the colon (any case) casts the value:

| type | value |
|---|---|
| `STRING`, `STR`, `FILE`, or none | The string as written. |
| `INTEGER`, `INT` | `tonumber()` of it: any number, not only integers. Errors when it isn't a number. |
| `BOOLEAN`, `BOOL` | `true` when the value is exactly `true`, otherwise `false`. |
| `JSON` | The value decoded as JSON (`convertJsonToLua()`). |
| `PATH` | The value with each `/` and `\` turned into `.`, as for `require`: `lib/dmc_lua` is `lib.dmc_lua`. |

An unknown type is read as a string. The pieces are exported too, for code that parses lines it reads itself: `parseFileLines( lines, options )` (it needs `options.default_section`), `getLineType( line )`, `processSectionLine( line )`, `processKeyLine( line )`, `processKeyName()`, `processKeyType()`, and the casts `castTo_boolean()` (`castTo_bool()`), `castTo_integer()` (`castTo_int()`), `castTo_json()`, `castTo_path()`, `castTo_file()`, `castTo_string()` (`castTo_str()`).

### Other Members

| member | is |
|---|---|
| `remove( items, options )`, `_removeDir()`, `_removeFile()` | Unfinished: see [Known Issues](#known-issues). |
| `DEFAULT_CONFIG_SECTION` | `'default'`: the section for keys before the first `[SECTION]`. |
| `__version` | The version, `'0.2.0'`. |
| `NAME` | `'Lua Files'`. |

Loading lua-files loads [lua-error](https://github.com/dmccuskey/lua-error), which sets the globals `try`, `catch` and `finally`.

## In Solar2D

[dmc-files](https://github.com/dmccuskey/dmc-files) is the Solar2D package of this module: it adds functions that take a file name and a Solar2D folder (`system.DocumentsDirectory`) instead of a path. The DMC Solar2D libraries load lua-files as `lib.dmc_lua.lua_files` from their `dmc_corona/lib/dmc_lua/` folder, part of [DMC-Lua-Library](https://github.com/dmccuskey/DMC-Lua-Library).

To call these functions in Solar2D, get a full path first with `system.pathForFile( name, system.DocumentsDirectory )`. The app's own folder (`system.ResourceDirectory`) is read-only on devices.

The config format is the format of `dmc_corona.cfg`: [dmc-corona-boot](https://github.com/dmccuskey/dmc-corona-boot) reads it with its own copy of these parsing functions, so the rules above, and the Known Issue on names with digits, apply to it too.

## Known Issues

- **`writeJSONFile()` errors**: it calls `writeFile()`, which doesn't exist (`attempt to call field 'writeFile' (a nil value)`). Use `saveFile( path, File.convertLuaToJson( data ) )`.
- **Names with digits break config files.** A section like `[SERVER2]` raises `key not found in line`, and a key like `PORT2 = 1` raises `bad argument #1 to 'gmatch'`, so the whole file fails to read. The same goes for any line that starts with an uppercase letter but isn't `KEY = value` (`NOTE read this`).
- **The removal functions don't work.** `_removeDir()` checks for a misspelled `lsf` and always raises `Lua File System (lfs) not loaded`; `remove()` needs Solar2D's `system` (outside Solar2D: `attempt to index global 'system'`), calls an undefined `rm_dir()` for a folder, and does nothing for a list of names. dmc-files replaces them with its own.
- A `BOOL` value is `true` only when written exactly `true`: `TRUE`, `yes` and `1` are `false`, without an error.
- An `INT` value can be any number (`1.5`), and a misspelled type (`PORT:INTT`) quietly gives a string.
- `readJSONFile()` of an empty file raises a bare `assertion failed!`.
- `fileExists()` tests whether the path can be opened for reading, so it's `true` for a folder (on macOS) and `false` for a file that exists but can't be read.
- `readFile()` writes the default `lines=true` into the `options` table it's given. The `options` of the other read functions are unused.
- `castTo_path()` returns a second value, the number of replacements (from `string.gsub()`).
- Reading a config key sets a global `key_value`, and the module uses the global `unpack`: Lua 5.1 (and LuaJIT) only.
- Loading prints `WARNING: lua_files missing lfs module` when LuaFileSystem is absent, although nothing that works needs it.

## Development

Only `dmc_lua/lua_files.lua` is written here. The other files in `dmc_lua/` are copies of the modules it needs (lua-error, lua-json-shim, lua-utils, and lua-class for lua-error), made by the Snakemake build (the `Snakefile` here registers the module and its `requires`); fix them in their own repositories. [DMC-Lua-Library](https://github.com/dmccuskey/DMC-Lua-Library) copies `lua_files.lua` into its `dmc_lua/`, and the DMC Solar2D libraries copy it from there into `dmc_corona/lib/dmc_lua/`.

The tests are in `spec/lua_files_spec.lua`, for [busted](https://lunarmodules.github.io/busted/) under Lua 5.1 with dkjson installed. From the repository's root folder:

```sh
busted spec
```

It ends with:

```text
17 successes / 0 failures / 0 errors / 0 pending : 0.00617 seconds
```

The tests cover `fileExists()`, the read functions, `convertJsonToLua()` and the config-line functions, not `readConfigFile()` as a whole, the JSON file functions, `saveFile()` or the removal functions.

## License

lua-files is released under the [MIT License](LICENSE).
