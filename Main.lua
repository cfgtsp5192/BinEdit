--[[
	Binary chunk editor made in lua (DOES NOT SUPPORT FILES YET!!)
	Written by @cfgtsp5192
	
	System notes:
	
	- If the status is 0, the editor is not active.
	- Else if the status is 1, the editor is active.
	
	- If the status gets set back from 1 to 0, the buffer is not cleared.

	- StringLen tells the reader how long of a string to read if a length argument is not passed.
	- The string reader always uses the passed length unless its not used, thus uses the StringLen value.

	- An unlimited amount of editors can be created by the ChunkEditor.new() function
]]

local ChunkEditor = {};
ChunkEditor.__index = ChunkEditor;

-- Init settings, edit if you wish to change defaults

local ErrMessage1 = "Unknown chunk!"; -- When a nil chunk is passed, throw an error with this message

local DefaultStatus = 0;
local DefaultLen = 4;

function ChunkEditor.new(Buff, Status, StringLen)
	local self = setmetatable({}, ChunkEditor);
	
	self.Buff = Buff or false;
	self.Status = Status or DefaultStatus;
	self.StringLen = StringLen or DefaultLen;
	
	if self.Buff == false then
		error(ErrMessage1);
	end
	
	return self;
end

function self:Increment(Str, Increment)
	self.Pos = self.Pos + Increment;
	
	return Str or false;
end

function ChunkEditor:ReadString(len)
	if self.Status == 1 then
		if not len then
			return self:Increment(Sub(self.Buff, self.Pos, self.Pos + self.StringLen), self.StringLen);
		end
	end
end

return ChunkEditor;
