AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

ENT.WireDebugName = ENT.PrintName
local ANCF = ANCF or {}

local WireLib = WireLib
local bit = bit
local duplicator = duplicator
local ents = ents
local os = os

local AddCSLuaFile = AddCSLuaFile
local IsValid = IsValid
local Wire_CreateInputs = Wire_CreateInputs
local Wire_CreateOutputs = Wire_CreateOutputs
local Wire_Remove = Wire_Remove
local Wire_Restored = Wire_Restored
local Wire_TriggerOutput = Wire_TriggerOutput
local include = include
local pairs = pairs

local MOVETYPE_VPHYSICS = MOVETYPE_VPHYSICS
local SOLID_VPHYSICS = SOLID_VPHYSICS
local WireAddon = WireAddon

function ENT:ServerInitialize()
	if !ANCF.Installed then
		self:Remove()

		return
	end

	self:SetName( "sent_anti_noclip_control" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	local phys = self:GetPhysicsObject()
	if IsValid( phys ) then
		phys:Wake()
		phys:EnableGravity( true )
		phys:EnableDrag( true )
		phys:EnableCollisions( true )
	end

	if WireAddon then
		self.Inputs = Wire_CreateInputs( self, { "On" } )
		self.Outputs = Wire_CreateOutputs( self, { "On" } )

		Wire_TriggerOutput( self, "On", 1 )
	end

	self:CreateField()

	ANCF.Update()
end

function ENT:ServerThink()
	local maxsize = ANCF.GetMaxFieldSize()

	if self:GetSizeInt() > maxsize then
		self:SetSizeInt( maxsize )
	end

	if !WireAddon then return end
	if !self.DisabledChanged then return end

	Wire_TriggerOutput( self, "On", !self:GetDisabledBool() and 1 or 0 )
end

function ENT:CreateField()
	local ent = ents.Create( "anti_noclip_field" )
	if !IsValid( ent ) then return end

	local pos = self:GetPos()
	local min = self:OBBMins()
	pos.z = pos.z + min.z

	ent:SetPos( pos )
	ent:SetAngles( self:GetAngles() )
	ent:SetParent( self )
	ent:Spawn()
	ent:Activate()

	self:SetFieldEnt( ent )
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

function ENT:SetFlag( bitdigit, bool )
	local BIT = 2^bitdigit

	local flags = bit.tobit( self:GetFlagsInt() )

	if ( !bool ) then
		if ( self:GetFlag( bitdigit ) ) then
			flags = flags - BIT // set bit to 0
		else
			return // do nothing
		end
	else
		flags = bit.bor( flags, ( bool == true ) and BIT or 0 ) // set bit to 1
	end

	self:SetFlagsInt( bit.tobit( flags ) )
end

function ENT:SetAdminMode( bool )
	self:SetFlag( 0, bool )
end

function ENT:SetOutsideProtectBool( bool )
	self:SetFlag( 1, bool )
end

for index, setting in pairs( ANCF.SettingsNames or {} ) do
	ENT["SetDisable"..setting.funcname.."Bool"] = function( self, bool )
		self:SetFlag( index + 1, bool )
	end
end

// The wire remove, dupe and restore functions
function ENT:OnRemove()
	if !ANCF.Installed then return end

	if WireAddon then
		Wire_Remove( self )
	end

	if !self.GetFieldEnt then return end
	local Field = self:GetFieldEnt()
	if IsValid( Field ) then
		Field:Remove()
	end

	if self.InsideEntities then
		for ent, _ in pairs(self.InsideEntities) do
			if !IsValid( ent ) then
				self.InsideEntities[ent or NULL] = nil

				continue
			end

			self.OnField = nil

			if self.OnFieldLeave then
				self:OnFieldLeave( ent )
			end
		end
	end

	ANCF.Update()
end

function ENT:PermaPropSave()
	return {}
end

function ENT:PermaPropLoad(data)
	return true
end

function ENT:OnRestore()
	if !WireAddon then return end
	Wire_Restored( self )
end

function ENT:BuildDupeInfo()
	if !WireAddon then return end

	return WireLib.BuildDupeInfo( self )
end

function ENT:ApplyDupeInfo( ply, ent, info, GetEntByID )
	if !WireAddon then return end

	WireLib.ApplyDupeInfo( ply, ent, info, GetEntByID )
end

function ENT:PreEntityCopy()
	if !WireAddon then return end

	//build the DupeInfo table and save it as an entity mod
	local DupeInfo = self:BuildDupeInfo()
	if ( DupeInfo ) then
		duplicator.StoreEntityModifier( self, "WireDupeInfo", DupeInfo )
	end
end

function ENT:PostEntityPaste( Player, Ent, CreatedEntities )
	if !WireAddon then return end

	//apply the DupeInfo
	if ( Ent.EntityMods and Ent.EntityMods.WireDupeInfo ) then
		Ent:ApplyDupeInfo( Player, Ent, Ent.EntityMods.WireDupeInfo, function( id ) return CreatedEntities[id] end )
	end
end

function ENT:TriggerInput( name, value )
	if !WireAddon then return end
	if !ANCF.Installed then return end

	if ( name == "On" ) then
		self:SetDisabledBool( value <= 0 )
	end
end
