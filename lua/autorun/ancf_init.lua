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

ANCF.Installed = true

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

