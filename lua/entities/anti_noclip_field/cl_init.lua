include( 'shared.lua' )

local ANCF = ANCF or {}
local util = util

local IsValid = IsValid
local LocalPlayer = LocalPlayer
local Matrix = Matrix
local Model = Model
local Player = Player
local tobool = tobool


function ENT:DrawTranslucent()
	if !ANCF.Installed then return end
	if !IsValid( self.ControlEnt ) then return end
	if self.ControlEnt:GetDisabledBool() then return end

	if ANCF.IsAdminOnly() and !self.ControlEnt:IsValidAdminOwner() then
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
