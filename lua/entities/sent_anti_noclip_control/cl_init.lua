local include = include
local CurTime = CurTime
local math = math
local pairs = pairs
local IsValid = IsValid

include( "shared.lua" )

local ANCF = ANCF or {}

local Wire_Render = Wire_Render
local Wire_UpdateRenderBounds = Wire_UpdateRenderBounds
local WIRE_CLIENT_INSTALLED = WIRE_CLIENT_INSTALLED

function ENT:ClientInitialize()
	if not ANCF.Installed then return end
	ANCF.Update()
end

function ENT:ClientThink()
	if WIRE_CLIENT_INSTALLED and ( CurTime() >= ( self.NextRBUpdate or 0 ) ) then
		self.NextRBUpdate = CurTime() + math.random( 30, 10 ) / 10
		Wire_UpdateRenderBounds( self )
		self.oldsize = nil
	end
end


function ENT:Draw()
	self:DrawModel()
	if not ANCF.Installed then return end

	if WIRE_CLIENT_INSTALLED then
		Wire_Render( self )
	end
end

function ENT:OnRemove()
	if not ANCF.Installed then return end

	for ent, _ in pairs( self.InsideEntities ) do
		if not IsValid( ent ) then
			self.InsideEntities[ent or NULL] = nil

			continue
		end

		self.OnField = nil

		if self.OnFieldLeave then
			self:OnFieldLeave( ent )
		end
	end

	ANCF.Update()
end
