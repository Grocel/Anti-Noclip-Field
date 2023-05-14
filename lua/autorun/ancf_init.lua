local AddCSLuaFile = AddCSLuaFile
local isstring = isstring
local hook = hook
local ErrorNoHalt = ErrorNoHalt
local istable = istable
local type = type
local isfunction = isfunction
local error = error
local debug = debug
local table = table
local resource = resource
local include = include
local collectgarbage = collectgarbage

AddCSLuaFile()

ANCF = {}

ANCF.Addonname = "Anti-Noclip Field:\n"
ANCF.ErrorString = nil

if ( VERSION < 200120 and VERSION > 5 ) then
	local ver = VERSIONSTR or VERSION or 0
	local vertext = "(Version: " .. ver .. ")"

	if isstring( ver ) then
		vertext = "(Date: " .. ver .. ")"
	end

	ANCF.Installed = nil
	ANCF.ErrorString = (ANCF.ErrorString or "") .. "Your GMod " .. vertext .. " is too old. Load aborted!\nUpdate your GMod!\n"

	local delay = 0
	hook.Add( "Think", "ANCF_Version_Check", function()
		if delay >= 20 then
			hook.Remove( "Think", "ANCF_Version_Check" )

			ErrorNoHalt( ANCF.Addonname .. ANCF.ErrorString )
		end

		delay = delay + 1
	end )

	return
end

local errors = {}
local errorsdelay = {}

-- Let's check for bad overrides of GMod libraries/functions
local function CheckLib( libname, funcname, datatype )
	local obj = _G[libname]
	local datatype = datatype or "function"
	local isLib = not funcname
	local isVar = funcname

	if ( isVar ) then
		if ( istable( _G[libname] ) ) then
			obj = _G[libname][funcname]
		else
			obj = nil
		end
	end

	-- Everything fine?
	if ( istable( obj ) and isLib ) then return false end
	if ( type( obj ) == datatype and isVar ) then return false end
	-- Let's kick some bad addons' ass.
	-- You don't override GMod libraries!
	local errortext = ""
	local Addonname = ANCF.Addonname or ""
	local index = libname

	if ( isVar ) then
		index = index .. "_" .. funcname
	end

	errorsdelay[index] = 0

	if ( istable( hook ) and isfunction( hook.Add ) and isfunction( hook.Remove ) ) then
		hook.Add( "Think", "ANCF_Error_" .. index, function( )
			if ( not errorsdelay[index] ) then return end

			if ( errorsdelay[index] >= 20 ) then
				hook.Remove( "Think", "ANCF_Error_" .. index )
				local errortext = errors[index]
				if ( not errortext ) then return end
				if ( errortext == "" ) then return end
				errors[index] = nil
				errorsdelay[index] = nil
				error( errortext )

				return
			end

			errorsdelay[index] = errorsdelay[index] + 1
		end )
	end

	ANCF.ErrorString = ANCF.ErrorString or ""

	-- Lib is a function
	if ( isfunction( obj ) and isLib ) then
		local tab = {}

		if ( istable( debug ) and isfunction( debug.getinfo ) ) then
			tab = debug.getinfo( obj ) or {}
		end

		_G[libname] = nil -- Let's fuck that bad addon up
		-- We don't need those
		tab.func = nil
		tab.isvararg = nil
		tab.nups = nil
		tab.nparams = nil
		tab.namewhat = nil
		tab.currentline = nil

		if ( tab ) then
			local err = "Some addon is conflicting with the GMod's '" .. libname .. "' library!\nIts datatype is 'function'! Report this!\n"
			errortext = Addonname .. err .. table.ToString( tab, "Function data of '" .. libname .. "'", true )
			ANCF.ErrorString = ANCF.ErrorString .. "\n" .. err
			errors[index] = errortext

			return true
		end
	end

	-- Lib is not a lib
	if ( not istable( obj ) and isLib ) then
		_G[libname] = nil -- Let's fuck that bad addon up
		local err = "Some addon is conflicting with the GMod's '" .. libname .. "' library!\nIts datatype is '" .. type( obj ) .. "'! Report this!\n"
		errortext = Addonname .. err
		ANCF.ErrorString = ANCF.ErrorString .. "\n" .. err
	end

	-- Lib variable is not the right type
	if ( ( type( obj ) ~= datatype ) and isVar ) then
		if ( istable( _G[libname] ) ) then
			_G[libname][funcname] = nil -- Let's fuck that bad addon up
			local err = "Some addon is conflicting with the GMod's '" .. libname .. "." .. funcname .. "' function!\nIts datatype is '" .. type( obj ) .. "'! Report this!\n"
			errortext = Addonname .. err
			ANCF.ErrorString = ANCF.ErrorString .. "\n" .. err
		else
			_G[libname] = nil -- Let's fuck that bad addon up
		end
	end

	errors[index] = errortext
	ErrorNoHalt( errortext )

	return true
end

ANCF.Installed = true

-- Do not load when something is broken
if ( CheckLib( "debug" ) ) then
	ANCF.Installed = nil
end

if ( CheckLib( "debug", "getregistry" ) ) then
	ANCF.Installed = nil
end

if ( CheckLib( "net" ) ) then
	ANCF.Installed = nil
end


if ( CheckLib( "net", "Receive" ) ) then
	ANCF.Installed = nil
end

if ( CheckLib( "table" ) ) then
	ANCF.Installed = nil
end

if ( CheckLib( "table", "Copy" ) ) then
	ANCF.Installed = nil
end

if not ANCF.Installed then return end

if SERVER then
	if resource.AddWorkshop then
		resource.AddWorkshop( "165559580" )
	else
		resource.AddFile( "materials/anti-noclip_field/border.vmt" )

		resource.AddFile( "models/anti-noclip_field/cube.mdl" )
		resource.AddFile( "models/anti-noclip_field/sphere.mdl" )
		resource.AddFile( "models/anti-noclip_field/cylinder.mdl" )
		resource.AddFile( "models/anti-noclip_field/pyramid.mdl" )
		resource.AddFile( "models/anti-noclip_field/cone.mdl" )
	end
end

AddCSLuaFile("ancf_core/init.lua")
include("ancf_core/init.lua")

collectgarbage( "collect" )
