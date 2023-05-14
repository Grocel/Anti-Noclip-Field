local include = include
local IsValid = IsValid
local LocalPlayer = LocalPlayer
local util = util
local Matrix = Matrix

include( 'shared.lua' )

local ANCF = ANCF or {}

function ENT:DrawTranslucent()
	if not ANCF.Installed then return end
	if not IsValid( self.ControlEnt ) then return end
	if self.ControlEnt:GetDisabledBool() then return end

	if ANCF.IsAdminOnly() and not self.ControlEnt:IsValidAdminOwner() then
		return
	end

	local ply = LocalPlayer()

	if IsValid( ply ) then
		if util.tobool( ply:GetInfo( "anti_noclip_control_hidefields" ) ) then
			return
		end
	end

	self:DrawModel()
end

function ENT:ResizeModel( ScaleVec, minpos, maxpos )
	local mat = Matrix()
	mat:Scale( ScaleVec )
	self:EnableMatrix( "RenderMultiply", mat )
	self:SetRenderBounds( minpos, maxpos )
end
