function getfield (f) -- extracted from Lua docs
  local v = _G    -- start with the table of globals
  for w in string.gmatch(f, "[%w_]+") do
    v = v[w]
  end
  return v
end
function setfield (f, v) -- extracted from Lua docs
  local t = _G    -- start with the table of globals
  for w, d in string.gmatch(f, "([%w_]+)(.?)") do
    if d == "." then      -- not last field?
      t[w] = t[w] or {}   -- create table if absent
      t = t[w]            -- get the table
    else                  -- last field
      t[w] = v            -- do the assignment
    end
  end
end
function todo()
  print("TODO REACHED")
  os.exit(1)
end
function shell(res)
  if TARGET == "WIN" then
    res = "powershell.exe " + res
  end
  print(res)
  if not os.execute(res) then
    print("Error occured. Exiting installation...")
    if TEMP_FOLDERS then
      for i,f in pairs(TEMP_FOLDERS) do
        if exists(f) then
          rm(f)
        end
      end
    end
    os.exit(1)
  end
end
function ensure_folder(path)
  if not exists(path) then
    shell("mkdir " .. path)
  end
end
function popen(fmt, ...)
  local res = string.format(fmt, ...)
  print(res)
  return io.popen(res,"r"):read()
end
function rm(path)
  assert(not path:startswith("/"), "rm (the lua function) rejects absolute paths just to be safe")
  print("×", path)
  if TARGET == "WIN" then
    os.execute("powershell.exe rm -Recurse -Force " .. path)
  elseif TARGET == "LINUX" then
    os.execute("rm -rf " .. path)
  end
end
function mv(src, dst)
  assert(not src:startswith("/"), "mv (the lua function) rejects absolute paths just to be safe")
  assert(not dst:startswith("/"), "mv (the lua function) rejects absolute paths just to be safe")
  if src == dst and isdir(dst) then
    rm(dst)
  end
  print(src, "->", dst)
  if TARGET == "WIN" then
    os.execute("powershell.exe mv -Force " .. src .. " " .. dst)
  elseif TARGET == "LINUX" then
    os.execute("mv -f " .. src .. " " .. dst)
  end
end
-- Check if a file or directory exists in this path
function exists(file)
   local ok, err, code = os.rename(file, file)
   if not ok then
      if code == 13 then
         -- Permission denied, but it exists
         return true
      end
   end
   return ok, err
end
-- returns only the name of the file without the path part
function filename(p)
  if PATH_DELIM == nil then PATH_DELIM = "/" end
  local o = p
  for word in string.gmatch(p, PATH_DELIM.."[^"..PATH_DELIM.."]*") do
    o = word
  end
  return string.sub(o,2)
end

--- Check if a directory exists in this path
function isdir(path)
   -- "/" works on both Unix and Windows
   return exists(path.."/")
end

function string:startswith(part)
  return string.sub(self, 0, string.len(part)) == part
end
function string:endswith(part)
  return string.sub(self, string.len(s) - string.len(part)) == part
end
function string:split(sep)
  if sep == nil then
    sep = "%s"
  end
  local t = {}
  for str in string.gmatch(self, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end
function string:join(T)
  return table.concat(T, self)
end

function load_os()
  TARGET = "LINUX"
  PATH_DELIM = "/"
  for _, a in pairs(arg) do
    if a:startswith("target=") then
      TARGET = string.upper(string.sub(a, string.find(a, "=")+1))
      assert(
         TARGET == "LINUX"
      or TARGET == "WIN"
      or TARGET == "IOS"
      or TARGET == "ANDROID",
        TARGET .. " is and unknown target. Expected LINUX, WIN, IOS or ANDROID."
      )
      if TARGET == "WIN" then PATH_DELIM = "\\" end
      CWD = popen("pwd")
      return TARGET
    end
  end

	-- ask LuaJIT first
	if jit then
	  print(jit.os)
		return jit.os
	end

	-- Unix, Linux variants
	local fh,err = assert(io.popen("uname -o 2>/dev/null","r"))
	if fh then
		osname = fh:read()
		TARGET = "LINUX"
    CWD = popen("pwd")
		return osname
	end

	TARGET = "WIN"
	PATH_DELIM = "\\"
  CWD = popen("pwd")
	return osname or "Windows"
end
function parse_args()
  ONLY = nil
  for _, a in pairs(arg) do
    if a:startswith("target=") then
      -- ignore. this is parsed by load_os
    else
      local f = string.find(a, "=")
      if f then
        setfield(string.sub(a,0,f-1):upper(), string.sub(a,f+1))
      end
    end
  end
end
function run_install_scripts()
  local v = _G    -- start with the table of globals
  for name,f in pairs(v) do
<<<<<<< HEAD
    if string.find(name, "inst_") == 1 then
      if name ~= nil and
        (ONLY == nil or ONLY:lower() == string.sub(name, 6))
      then
        if type(f) == "function" then
          f()
=======
    if string.gmatch(name, "^inst_[%w_]+$") then
      if ONLY == nil or ONLY:lower() == string.sub(name, 5) then
        for i,p in pairs(f) do
          print(i, p)
>>>>>>> 9ecae2e16692e401ab08d6803af2fa43e8eec825
        end
      end
    end
  end
  print("Done.")
end

