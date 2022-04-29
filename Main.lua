--[[
	Binary chunk editor made in lua (DOES NOT SUPPORT FILES YET!!)
	Written by @cfgtsp5192
	
	THIS IS A LARGE WORK IN PROGRESS!!

	I have not tested the ChunkEditor:GrabIEEE754() yet, expect bugs.
	
	System notes:

	- This only supports little endians atm, I have not implemented big endian yet
	- If the status is 0, the editor is not active
	- Else if the status is 1, the editor is active
	- If the status gets set back from 1 to 0, the buffer is not cleared
	- StringLen tells the reader how long of a string to read if a length argument is not passed
	- The string reader always uses the passed length unless its not used, thus uses the StringLen value
	- An unlimited amount of editors can be created by the ChunkEditor.new() function
]]

local ChunkEditor = {};
ChunkEditor.__index = ChunkEditor;

local Sub = string.sub;
local Modf = math.modf;
local Floor = math.floor;

-- Init settings, edit if you wish to change defaults

local ErrMessage1 = "Unknown chunk!"; -- When a nil chunk is passed, throw an error with this message

local DefaultStatus = 0;
local DefaultLen = 4;
local DefaultSize = 8;

-- Util

local function Extract(X, Field, Width)
	X = (X % (2 ^ Width)) / (2 ^ Field);
	X = X - (X % 1);
	return X;
end

-- Main

function ChunkEditor.new(Buff, Status, StringLen, IntegerSize)
	local self = setmetatable({}, ChunkEditor);
	
	self.Buff = Buff or false;
	self.Len = (Buff and #Buff) or 0;
	self.Status = Status or DefaultStatus;
	self.StringLen = StringLen or DefaultLen;
	self.IntegerSize = IntegerSize or DefaultSize;
	
	if self.Buff == false or self.Len == 0 then
		error(ErrMessage1);
	end
	
	return self;
end

function self:ExportChunk()
	return self.Buff, self.Len;	
end

-- Functions intended to make code look more organized (Set/Increment/Decrement)

function self:Set(Val, Value)
	if type(Value) == "number" then
		self.Pos = Value;
	end
	
	return Val or false;
end

function self:Increment(Val, Increment)
	if type(Increment) == "number" then
		self.Pos = self.Pos + Increment;
	end
	
	return Val or false;
end

function self:Decrement(Val, Decrement)
	if type(Decrement) == "number" then
		self.Pos = self.Pos - Decrement;
	end
	
	return Val or false;
end

--[[

local function ReadLuaHeader(Editor, Header) -- Made this function for testing purposes
	Editor = Editor or ChunkEditor.new(Header, 1, 4, 4);
	
	local LuaSymbol = Editor:GetString(4) -- Should be "\27Lua" always
	local LuaVersion = Editor:GetBits8(); -- Should be 81/82/83 (0x51/0x52/0x53), as this is revised for those version formats
	local LuaFormat = Editor:GetBits8();
	local LuaEndianess = Editor:GetBits8();
	local LuaIntSize = Editor:GetBits8();
	local LuaSizeT = Editor:GetBits8();
	local LuaInstSize = Editor:GetBits8();
	local LuaNumSize = Editor:GetBits8();
	local LuaIntegral = Editor:GetBits8();
	
	return LuaSymbol, LuaVersion, LuaFormat, LuaEndianess, LuaIntSize, LuaSizeT, LuaInstSize, LuaNumSize, LuaIntegral;
end

local ReadLuaFunction; function ReadLuaFunction(Editor, Chunk)
	Editor = Editor or ChunkEditor.new(Header, 1, 4, 4);
	
	ReadLuaHeader(Editor); -- Skip the header
	
	local Consts = {};
	local Upvals = {};
	local Protos = {};
	local Locals = {};
	
	local ConstAmt = 0;
	local UpvalAmt = 0;
	local ProtoAmt = 0;
	local LocalAmt = 0;
	
	local IsVararg = false;
	
	local ChunkName = "";
	local FirstLine = 0;
	local LastLine = 0;
	
	ChunkName = Editor:GrabString();
	FirstLine = Editor:GrabBits8();
	LastLine = Editor:GrabBits8();
end]]

-- Reader

function ChunkEditor:GrabBits8()
	if self.Status == 1 then
		return self:Increment(Byte(self.Buff, self.Pos, self.Pos), 1);
	end
end

function ChunkEditor:GrabBits16()
	if self.Status == 1 then
		local A, B = Byte(self.Buff, self.Pos, self.Pos + 2);
		A = A + (B * 256);
		
		return self:Increment(A, 2);
	end
end

function ChunkEditor:GrabBits32()
	if self.Status == 1 then
		local A, B, C, D = Byte(self.Buff, self.Pos, self.Pos + 4);
		A = A + (B * 256);
		A = A + (C * 65536);
		A = A + (D * 16777216);
		
		return self:Increment(A, 4);
	end
end

function ChunkEditor:GrabBits64()
	if self.Status == 1 then
		local A, B, C, D, E, F, G, H = Byte(self.Buff, self.Pos, self.Pos + 8);
		A = A + E;
		
		A = A + (B * 256);
		A = A + (C * 65536);
		A = A + (D * 16777216);
		A = A + (F * 256);
		A = A + (G * 65536);
		A = A + (H * 16777216);
		
		-- A = A * (2 ^ 32)
		
		return self:Increment(A, 8);
	end
end

function ChunkEditor:GrabIEEE754()
	if self.Status == 1 then
		local Val = self:GrabBits64();
		local Value, Sign, Mantissa, Exponent;
		
		Mantissa = Extract(Val, 0, 52);
		Exponent = Extract(Val, 52, 63);
		Sign = Extract(Val, 63, 64);
		
		if Exponent == (0 / 0) then -- NaN
			Mantissa = 0;
			Exponent = 0;
		elseif Exponent == (1 / 0) then -- inf
			Mantissa = 0;
			Exponent = 2047;
		end
		
		Value = (Mantissa / (2 ^ 52)) * ((Exponent - 1023) * (2 ^ (Exponent - 1023)))
		
		if Sign == 1 then
			Value = -Value;
		end
		
		return Value;
	end
end

function ChunkEditor:ReadInteger()
	if self.Status == 1 then
		if self.IntegerSize % 4 == 0 then
			local A = 0;
			
			for i = 1, Floor(self.IntegerSize / 4) do
				A = A + self:GrabBits32();
			end
		
			return A;
		end
	end
end

function ChunkEditor:GrabString(len)
	if self.Status == 1 then
		if not len then
			return self:Increment(Sub(self.Buff, self.Pos, self.Pos + self.StringLen), self.StringLen);
		end
		
		return self:Increment(Sub(self.Buff, self.Pos, self.Pos + len), len);
	end
end

-- Writer 

function ChunkEditor:WriteString(Str)
	if self.Status == 1 then
		local Len = #Str;
		
		if Len > 0 then
			for i = 1, Len do
				self.Buff = self.Buff + Sub(Str, i, i);
				self.Len = self.Len + 1;
			end
		end
	end
end

function ChunkEditor:WriteInteger(Int)
	if self.Status == 1 then
		
	end
end

return ChunkEditor;
