local AddCSLuaFile = AddCSLuaFile
local include = include
local IsValid = IsValid
local pairs = pairs
local math = math
local Vector = Vector
local ents = ents
local CurTime = CurTime
local net = net

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

local ANCF = ANCF or {}

function ENT:BuildPhysics( shape, size, ScaleVec, minpos, maxpos )
	local customphys = true
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	if shape == 1 then -- sphere
		self:PhysicsInitSphere( size )
		customphys = false
	end

	-- if shape == 0 then -- cube
	-- 	self:PhysicsInitBox( minpos, maxpos )
	-- 	customphys = false
	-- end

	self:SetTrigger( true )
	local phys = self:GetPhysicsObject()

	if IsValid( phys ) then
		phys:EnableGravity( false )
		phys:EnableDrag( false )
		phys:EnableCollisions( false )
		phys:EnableMotion( false )

		if SERVER and customphys then -- custom
			if not self.OriginalPhysmesh then
				self.OriginalPhysmesh = phys:GetMesh()
			end

			local fiter = {}
			local index = 0
			local physmesh = {}

			for i, vertix in pairs( self.OriginalPhysmesh ) do
				local pos = vertix.pos
				local x, y, z = math.Round( pos.x ), math.Round( pos.y ), math.Round( pos.z )

				if fiter[x .. "_" .. y .. "_" .. z] then continue end
				fiter[x .. "_" .. y .. "_" .. z] = true
				index = index + 1

				physmesh[index] = Vector(
					x * ScaleVec.x,
					y * ScaleVec.y,
					z * ScaleVec.z
				 )

			end

			self:PhysicsInitConvex( physmesh )

			phys = self:GetPhysicsObject()
			if IsValid( phys ) then
				phys:EnableGravity( false )
				phys:EnableDrag( false )
				phys:EnableCollisions( false )
				phys:EnableMotion( false )
			end
		end
		self:SetNotSolid( true )
		self:EnableCustomCollisions( true )

		self.ControlEnt:PhysWake()
	end
end

function ENT:FindEnts()
	local Control = self.ControlEnt
	if not IsValid( Control ) then return end
	if not Control.SearchRadiusSqr then return end

	for _, ent in pairs( ents.FindInSphere( Control:GetPos(), Control.SearchRadiusSqr^0.5 + 50 ) ) do
		if not ANCF.IsValidEntity( ent ) then continue end

		local IsIn = Control:IsVecInField( ent:GetPos() )
		if IsIn then
			if not ent:ANCF_GetInField() then
				self:SynTouch( ent, true )
				if Control.OnField then
					Control:OnField( ent )
				end
			end
		else
			if ent:ANCF_GetInField() then
				self:SynTouch( ent, false )
			end
		end
	end
end

function ENT:Think()
	local Control = self.ControlEnt
	if not IsValid( Control ) then return end
	if Control:GetShapeInt() ~= 1 then return end -- Use Think on spheres.

	self:FindEnts()

	self:NextThink( CurTime() + ANCF.GetRecheckTime() )
	return true
end

function ENT:SynTouch( ent, Entered )
	local Control = self.ControlEnt
	if not ANCF.IsValidEntity( ent ) then return end
	if not IsValid( Control ) then return end

	net.Start( "__ANCF_InField" )
		net.WriteEntity( Control )
		net.WriteEntity( ent )
		net.WriteBit( Entered )
	net.Broadcast()

	if Entered then
		if Control.OnFieldEnter then
			Control:OnFieldEnter( ent )
		end
	else
		if Control.OnFieldLeave then
			Control:OnFieldLeave( ent )
		end
	end
end

function ENT:StartTouch( ent )
	local Control = self.ControlEnt
	if not IsValid( Control ) then return end
	if Control:GetShapeInt() == 1 then return end -- Don't use Touch on spheres.

	self:SynTouch( ent, true )
end

function ENT:EndTouch( ent )
	local Control = self.ControlEnt
	if not IsValid( Control ) then return end
	if Control:GetShapeInt() == 1 then return end -- Don't use Touch on spheres.

	self:SynTouch( ent, false )
end

function ENT:Touch( ent )
	local Control = self.ControlEnt
	if not IsValid( ent ) then return end
	if not IsValid( Control ) then return end
	if not Control.OnField then return end
	if Control:GetShapeInt() == 1 then return end -- Don't use Touch on spheres.

	Control:OnField( ent )
end
