-- =============================================================================
-- INI Reader / Writer-- by RoboMat---- Created: 30.01.14 - 16:59-- modified by Valrix 01.06.15 - 23:38
-- ============================================================================= 

-- -------------------------------------------------- Global Variables-- ------------------------------------------------
IniIO = {};
--

-- -------------------------------------------------- Global Functions-- ------------------------------------------------
function string.startsWith(String,Start)	
	return string.sub(String,1,string.len(Start))==Start
end

function string.trim(String)  
	return String:match'^%s*(.*%S)' or ''
end
--

-------------------------------------------------- INI READER ----------------------------------------------------- Reads a file written in .ini-format:
-- http://en.wikipedia.org/wiki/INI_file
-- @param String	_path
-- @param Boolean	_createIfNil

function IniIO.readIni(_path, _createIfNil)	
	local path = _path;	
	local useNewFile = _createIfNil or false;	
	
	-- Create new file reader.	
	local reader = getFileReader(path, useNewFile);	
		if reader then		
			local file = {};		
			local section;		
			local line;		
			
			while true do			
				line = reader:readLine(); 
				-- If no line can't be read we know that EOF is reached.
				if not line then
					reader:close();
					break;
				end
				
				-- Trim whitespace and remove uppercase letters.
				line:trim();
				
				if line:startsWith("[") then 
					--[[ We have a new section ]] --
					-- Cut out the actual section name (remove []).
						section = line:sub(2, line:len() - 1)
						-- Create a new nested table for that section.
						file[section] = {};
				elseif string.match(line, "=") then 
					--[[ We have a key && value line ]] --
					-- Make sure we have an active section to write to.
					assert(file[section], "ERROR: No global properties allowed. There has to be a section declaration first.");
					-- Split the key from the value.
					local key,value = string.gmatch(line, "(%w+)=(%S*)")();
					key = key:trim();
					value = value:trim();
					-- Use the key to index the active table and store the value.
					file[section][key] = value;
				end
			end
		return file;
	else
		print("\nERROR: Can't read file at: " .. path .. "\n");
		return;	
	end
end

-- -------------------------------------------------- INI WRITER-- ---------------------------------------------------
-- @param String	_path
-- @param Table		_ini
-- @param Boolean	_createIfNil
-- @param Boolean	_append
function IniIO.writeIni(_path, _ini, _createIfNil, _append)	
	local path = _path;	
	local ini = _ini;	
	local useNewFile = _createIfNil or true;
	local append = _append or false;
	local writer = getFileWriter(path, useNewFile, append);
	
	if writer then
		for section, values in pairs(ini) do
			writer:write("[" .. tostring(section) .. "]\n");
			for key, value in pairs(values) do
				writer:write(tostring(key) .. "=" .. tostring(value) .. "\n");
			end
		end
		
		writer:close();
	else
		print("\nERROR: Can't create file at: " .. path .. "\n");
		return;
	end
end
--