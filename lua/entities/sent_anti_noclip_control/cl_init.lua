include( 'shared.lua' )

local ANCF = ANCF or {}
local math = math

local CurTime = CurTime
local IsValid = IsValid
local Model = Model
local Wire_Render = Wire_Render
local Wire_UpdateRenderBounds = Wire_UpdateRenderBounds
local include = include
local pairs = pairs

local WIRE_CLIENT_INSTALLED = WIRE_CLIENT_INSTALLED

function ENT:ClientInitialize()
	if !ANCF.Installed then return end
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
	if !ANCF.Installed then return end

	if WIRE_CLIENT_INSTALLED then
		Wire_Render( self )
	end
end

function ENT:OnRemove()
	if !ANCF.Installed then return end

	for ent, _ in pairs( self.InsideEntities ) do
		if !IsValid( ent ) then
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
