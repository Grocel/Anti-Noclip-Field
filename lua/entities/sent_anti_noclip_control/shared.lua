ENT.Type			= "anim"
ENT.Base			= "base_anim"
ENT.PrintName		= "Anti-Noclip Field Controller"
ENT.Author			= "Meoowe and Grocel"

ENT.Spawnable		= false
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_OPAQUE

local ANCF = ANCF or {}
local bit = bit
local game = game
local util = util

local CurTime = CurTime
local Entity = Entity
local IsValid = IsValid
local Player = Player
local Vector = Vector
local pairs = pairs
local tobool = tobool

local CLIENT = CLIENT
local MOVETYPE_NOCLIP = MOVETYPE_NOCLIP
local MOVETYPE_WALK = MOVETYPE_WALK
local SERVER = SERVER

local function Freeze( ent )
	local phys = ent:GetPhysicsObject()

	if !IsValid( phys ) then return end

	phys:EnableMotion( false )
end

local function UsesPhysgun( self, ply, ent )
	if !ANCF.Installed then return false end

	if !self:GetDisablePhysgunBool() then return false end

	if ent:ANCF_GetGrabbedWith() == "Physgun" then return true end
	if ent:ANCF_GetGrabbedWith() == "Pickup" then return false end
	if ent:ANCF_GetGrabbedWith() == "Gravitygun" then return false end

	local weapon = ply:GetActiveWeapon()
	if !IsValid(weapon) then return false end
	if weapon:GetClass() ~= "weapon_physgun" then return false end

	return true
end
local function UsesGravgun( self, ply, ent )
	if !ANCF.Installed then return false end

	if !self:GetDisableGravitygunBool() then return false end

	if ent:ANCF_GetGrabbedWith() == "Gravitygun" then return true end
	if ent:ANCF_GetGrabbedWith() == "Physgun" then return false end
	if ent:ANCF_GetGrabbedWith() == "Pickup" then return false end

	local weapon = ply:GetActiveWeapon()
	if !IsValid(weapon) then return false end
	if weapon:GetClass() ~= "weapon_physcannon" then return false end

	return true
end

local function UsesPickup( self, ply, ent )
	if !ANCF.Installed then return false end

	if !self:GetDisablePickupBool() then return false end

	if ent:ANCF_GetGrabbedWith() == "Pickup" then return true end
	if ent:ANCF_GetGrabbedWith() == "Physgun" then return false end
	if ent:ANCF_GetGrabbedWith() == "Gravitygun" then return false end

	local weapon = ply:GetActiveWeapon()
	if !IsValid(weapon) then return true end
	if weapon:GetClass() == "weapon_physgun" then return false end
	if weapon:GetClass() == "weapon_physcannon" then return false end

	return true
end

function ENT:Initialize()
	self.InsideEntities = {}
	self.SizeVector = Vector()

	if ( SERVER ) then
		self:ServerInitialize()
	else
		self:ClientInitialize()
	end
end

function ENT:SetupDataTables()
	//String

	//Bool
	self:NetworkVar( "Bool", 0, "DisabledBool" )
	self:NetworkVar( "Bool", 1, "AffectOwnerBool" )
	self:NetworkVar( "Bool", 2, "AffectAdminBool" )
	self:NetworkVar( "Bool", 3, "DrawBordersBool" )
	self:NetworkVar( "Bool", 4, "NoOwner" )

	//Float

	//Int
	self:NetworkVar( "Int", 0, "SizeInt" )
	self:NetworkVar( "Int", 1, "ShapeInt" )
	self:NetworkVar( "Int", 2, "FlagsInt" )
	//Vector

	//Angle

	//Entity
	self:NetworkVar( "Entity", 0, "OwnerEnt" )
	self:NetworkVar( "Entity", 1, "FieldEnt" )
end

function ENT:IsVecInField( pos )
	if !ANCF.Installed then return false end
	if self:GetDisabledBool() then return false end

	if !self.SearchRadiusSqr then return false end

	return ( pos - self:GetPos() ):LengthSqr() < self.SearchRadiusSqr
end

function ENT:OnFieldEnter( ent )
	if !ANCF.Installed then return end

	local IsNear = self:IsVecInField( ent:GetPos() )

	if IsNear then
		ent:ANCF_SetInField( true )
		self.InsideEntities[ent] = true
	else
		self:OnFieldLeave(ent)
	end
end

function ENT:OnFieldLeave( ent )
	if !ANCF.Installed then return end

	ent:ANCF_SetInField( nil )
	self.InsideEntities[ent] = nil

	ent:ANCF_DisableGodmode(false)
end

function ENT:OnField( ent )
	if !ANCF.Installed then return end
	if !self.GetFieldEnt then return end

	local InField = ent:ANCF_GetInField()
	local Field = self:GetFieldEnt()

	if !self:IsVecInField( ent:GetPos() ) then
		return
	end

	if !InField then
		if IsValid( Field ) then
			Field:StartTouch( ent )
		end

		return
	end

	if ent:IsPlayer() then // Player in Field
		local pl = ent
		if !self:IsPlValidRange( pl ) then return end

		if self:GetDisableNoclipBool() and pl:GetMoveType( MOVETYPE_NOCLIP ) then
			pl:SetMoveType( MOVETYPE_WALK )
		end

		if !self:IsValidAdminOwner() then return end

		if self:GetDisableFlashlightBool() and pl:FlashlightIsOn() then
			pl:Flashlight( false )
		end

		if self:GetDisableVehicleBool() then
			pl:ExitVehicle()
		end

		pl:ANCF_DisableGodmode(self:GetDisableGodmodeBool())

		local GrabbedEnt = pl:ANCF_GetGrabbed()
		if IsValid( GrabbedEnt ) then
			if pl:IsDrivingEntity() and self:GetDisableDriveBool() then
				pl:SetDrivingEntity()

				local GrabberPly = GrabbedEnt:ANCF_GetGrabbedBy()
				if IsValid( GrabberPly ) then
					GrabberPly:ANCF_Clear()
				end

				GrabbedEnt:ANCF_Clear()
				pl:ANCF_Clear()
			end

			if UsesPhysgun( self, pl, GrabbedEnt ) or UsesGravgun( self, pl, GrabbedEnt ) or UsesPickup( self, pl, GrabbedEnt ) then
				pl:DropObject()
				GrabbedEnt:ForcePlayerDrop()
				Freeze( GrabbedEnt )

				local GrabberPly = GrabbedEnt:ANCF_GetGrabbedBy()
				if IsValid( GrabberPly ) then
					GrabberPly:ANCF_Clear()
				end

				GrabbedEnt:ANCF_Clear()
				pl:ANCF_Clear()
			end
		end
	else // Prop in Field

		if ent:IsVehicle() and self:GetDisableVehicleBool() then
			local pl = ent:GetDriver()

			if self:IsPlValid(pl) then
				pl:ExitVehicle()
			end
		end

		local GrabberPly = ent:ANCF_GetGrabbedBy()
		if self:IsPlValid( GrabberPly ) then
			if GrabberPly:IsDrivingEntity() and self:GetDisableDriveBool() then
				GrabberPly:SetDrivingEntity()

				local GrabbedEnt = GrabberPly:ANCF_GetGrabbed()
				if IsValid( GrabbedEnt ) then
					GrabbedEnt:ANCF_Clear()
				end

				GrabberPly:ANCF_Clear()
				ent:ANCF_Clear()
			end

			if UsesPhysgun( self, GrabberPly, ent ) or UsesGravgun( self, GrabberPly, ent ) or UsesPickup( self, GrabberPly, ent ) then
				GrabberPly:DropObject()
				ent:ForcePlayerDrop()
				Freeze( ent )

				local GrabbedEnt = GrabberPly:ANCF_GetGrabbed()
				if IsValid( GrabbedEnt ) then
					GrabbedEnt:ANCF_Clear()
				end

				GrabberPly:ANCF_Clear()
				ent:ANCF_Clear()
			end
		end
	end
end

function ENT:Think()
	if !ANCF.Installed then return end
	if !self.GetSizeInt then return end
	if !self.GetFieldEnt then return end

	local Size = self:GetSizeInt()
	if self.oldsize ~= Size then
		self.SizeChanged = true
		self.oldsize = Size
	else
		self.SizeChanged = nil
	end

	local Shape = self:GetShapeInt()
	if self.oldshape ~= Shape then
		self.ShapeChanged = true
		self.oldshape = Shape
	else
		self.ShapeChanged = nil
	end

	local Draw = self:GetDrawBordersBool()
	if self.olddraw ~= Draw then
		self.DrawChanged = true
		self.olddraw = Draw
	else
		self.DrawChanged = nil
	end

	local Disabled = self:GetDisabledBool()
	if self.olddisabled ~= Disabled then
		self.DisabledChanged = true
		self.olddisabled = Disabled
	else
		self.DisabledChanged = nil
	end

	if CLIENT then
		self:ClientThink()
	else
		self:ServerThink()
	end

	local Field = self:GetFieldEnt()
	if !IsValid( Field ) then return end

	if self.ShapeChanged then
		Field.OriginalPhysmesh = nil
	end

	if self.SizeChanged or self.ShapeChanged then
		Field:UpdateShape()

		local Size = self:GetSizeInt()

		self.SizeVector.x = Size
		self.SizeVector.y = Size
		self.SizeVector.z = Size

		self.SearchRadiusSqr = self.SizeVector:LengthSqr() // cube
		local Shape = self:GetShapeInt()

		if Shape == 1 then // sphere
			self.SearchRadiusSqr = Size^2
		end

		if Shape == 2 then // cylinder
			self.SizeVector.x = 0
			self.SearchRadiusSqr = self.SizeVector:LengthSqr()
		end

		if Shape == 3 then // pyramid
			self.SizeVector.z = 0
			self.SearchRadiusSqr = self.SizeVector:LengthSqr()
		end

		if Shape == 4 then // cone
			self.SearchRadiusSqr = Size^2
		end
	end

	if self.DrawChanged then
		Field:SetNoDraw( !Draw )
	end

	Field:ANCF_SetInField( !Disabled )
	self:ANCF_SetInField( !Disabled )

	if (CLIENT) then
		self:SetNextClientThink( CurTime() + ANCF.GetRecheckTime() )
	else
		self:NextThink( CurTime() + ANCF.GetRecheckTime() )
	end
	return true
end

function ENT:IsPlValid( pl )
	if !ANCF.Installed then return false end

	if self:GetDisabledBool() then
		return false
	end

	if !IsValid( pl ) or !pl:IsPlayer() then
		return false
	end

	if util.tobool( pl:GetInfo( "anti_noclip_control_force" ) ) then
		return true
	end

	if pl:IsSuperAdmin() and !ANCF.IsBlockingSuperAdmin() then
		return false
	end

	if ANCF.IsAdminOnly() and !self:IsValidAdminOwner() then
		return false
	end

	local noowner = self:GetNoOwner()
	if noowner then return true end

	local owner = self:GetOwnerEnt()
	if IsValid( owner ) then
		if !self:GetAffectOwnerBool() and pl == owner then
			return false
		end

		if pl:IsAdmin() and ( !self:GetAffectAdminBool() or !owner:IsAdmin() ) and !ANCF.IsFreeForAll() then
			return false
		end
	end

	return true
end

function ENT:IsPlValidRange( pl )
	if !self:IsPlValid( pl ) then
		return false
	end

	if !pl:ANCF_GetInField() or !self:IsVecInField( pl:GetPos() ) then
		return false
	end

	return true
end

function ENT:GetFlag( bitdigit )
	local BIT = 2^bitdigit
	local flags = bit.tobit( self:GetFlagsInt() )

	return bit.band( flags, BIT ) == BIT
end

function ENT:GetAdminMode()
	return self:GetFlag( 0 )
end
function ENT:GetOutsideProtectBool()
	return self:GetFlag( 1 )
end

for index, setting in pairs( ANCF.SettingsNames or {} ) do
	ENT["GetDisable"..setting.funcname.."Bool"] = function( self )
		return self:GetFlag( index + 1 )
	end
end

function ENT:IsValidAdminOwner()
	if !ANCF.Installed then return false end
	if game.SinglePlayer() then return true end
	if ANCF.IsFreeForAll() then return true end

	local noowner = self:GetNoOwner()
	if noowner then return true end

	local owner = self:GetOwnerEnt()
	if !IsValid( owner ) then
		return self:GetAdminMode() // from a disconnected player
	end

	local admin = owner:IsAdmin()
	if SERVER then
		self:SetAdminMode( admin )
	end
	return admin
end
