-- Meoowe made the original ("Noclip Field") years ago.
-- It broke after the GMod 13 Update and the author isn't reachable.
-- So I (Grocel) fixed all bugs and added some more features.
-- It also takes care of the new GMod 13 features.
-- The code has be completely overhauled from the original.

local ents = ents
local IsValid = IsValid
local CreateConVar = CreateConVar
local game = game
local math = math
local isentity = isentity
local util = util
local hook = hook
local pairs = pairs
local isfunction = isfunction
local net = net
local ipairs = ipairs
local CurTime = CurTime

local PropCore = PropCore
local PermaProps = PermaProps

local ANCF = ANCF or {}

if not ANCF.Installed then return end

local AntiNoclipFields = {}
function ANCF.Update()
	if not ANCF.Installed then
		AntiNoclipFields = {}

		return
	end

	AntiNoclipFields = ents.FindByClass( "sent_anti_noclip_control" )
end

ANCF.SettingsNames = {
	{ -- Noclip
		name 		= "noclip", -- Name of the setting
		funcname 	= "Noclip", -- Name of get and set functions in the entity
		lang 		= { "Block noclip", "Nocliping will be blocked." }, -- language data
		ConVar 		= "1", -- Default var of the ConVar
		needadmin	= false, -- Adminonly?
	},

	{ -- Spawn
		name 		= "spawn",
		funcname 	= "Spawn",
		lang 		= { "Block spawning objects", "Spawning objects will be blocked." },
		ConVar 		= "0",
		needadmin	= true,
	},

	{ -- Tools
		name 		= "tools",
		funcname 	= "Tools",
		lang 		= { "Block tools", "Using the toolgun will be blocked." },
		ConVar 		= "0",
		needadmin	= true,
	},

	{ -- Prop drive
		name 		= "drive",
		funcname 	= "Drive",
		lang 		= { "Block prop drive", "Using prop drive will be blocked." },
		ConVar 		= "0",
		needadmin	= true,
	},

	{ -- Entity property
		name 		= "property",
		funcname 	= "Property",
		lang 		= { "Block changing properties", "Changing entity properties will be blocked." },
		ConVar 		= "0",
		needadmin	= true,
	},

	{ -- Physgun
		name 		= "physgun",
		funcname 	= "Physgun",
		lang 		= { "Block physgun ", "Using the physgun will be blocked." },
		ConVar 		= "0",
		needadmin	= true,
	},

	{ -- Gravitygun
		name 		= "gravitygun",
		funcname 	= "Gravitygun",
		lang 		= { "Block gravitygun", "Using the gravitygun will be blocked." },
		ConVar 		= "0",
		needadmin	= true,
	},

	{ -- +USE pickup
		name 		= "pickup",
		funcname 	= "Pickup",
		lang 		= { "Block pickup", "Blocks picking up props by pressing the use key." },
		ConVar 		= "0",
		needadmin	= true,
	},

	{ -- Vehicle
		name 		= "vehicle",
		funcname 	= "Vehicle",
		lang 		= { "Block vehicles", "Entering and driving vehicles will be blocked. You will be kicked out." },
		ConVar 		= "0",
		needadmin	= true,
	},

	{ -- Flashlight
		name 		= "flashlight",
		funcname 	= "Flashlight",
		lang 		= { "Block flashlights", "You will not be able to use your Flashlights." },
		ConVar 		= "0",
		needadmin	= true,
	},

	{ -- Suicide
		name 		= "suicide",
		funcname 	= "Suicide",
		lang 		= { "Block suicides", "You will not be able to suicide or damage yourself." },
		ConVar 		= "0",
		needadmin	= true,
	},

	{ -- Damaging
		name 		= "damage",
		funcname 	= "Damage",
		lang 		= { "Block damage", "You will not be able to damage the entities." },
		ConVar 		= "0",
		needadmin	= true,
	},

	{ -- Godmode
		name 		= "godmode",
		funcname 	= "Godmode",
		lang 		= { "Disable godmode", "Your godmode will be disabled. You will not be able to turn it on." },
		ConVar 		= "0",
		needadmin	= true,
	},
}

function ANCF.IsValidEntity( ent )
	if not ANCF.Installed then return false end

	if not IsValid( ent ) then return false end
	if ent:IsWorld() then return false end
	if SERVER then
		if ent:IsConstraint() then return false end
	end
	if ent:GetSolid() == SOLID_NONE then return false end
	if ent:GetMoveType() == MOVETYPE_NONE then return false end

	return true
end

local cv_adminonly 			= CreateConVar( "sv_anti_noclip_field_adminonly", 0, {FCVAR_REPLICATED, FCVAR_GAMEDLL, FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Enable/Disable Anti-Noclip Field for non-admins.\nDefault: 0" )
local cv_maxsize 			= CreateConVar( "sv_anti_noclip_field_maxsize", 512, {FCVAR_REPLICATED, FCVAR_GAMEDLL, FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Change the max size of the fields, it will also clamp already placed ones.\nDefault: 512, Range: 128-16384" )
local cv_freeforall 		= CreateConVar( "sv_anti_noclip_field_freeforall", 0, {FCVAR_REPLICATED, FCVAR_GAMEDLL, FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Enable/Disable admin only features of the Anti-Noclip Field for everyone.\nDefault: 0" )
local cv_blocksuperadmin 	= CreateConVar( "sv_anti_noclip_field_blocksuperadmin", 0, {FCVAR_REPLICATED, FCVAR_GAMEDLL, FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Enable/Disable blocking for superadmins.\nDefault: 0" )
local cv_rechecktime 		= CreateConVar( "sv_anti_noclip_field_rechecktime", 0.25, {FCVAR_REPLICATED, FCVAR_GAMEDLL, FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Set the time between field ticks in seconds. Higher values will reduce lag, lower values will make the fields more precise.\nDefault: 0.25, Range: 0.01-5" )

function ANCF.IsAdminOnly()
	if game.SinglePlayer() then return false end

	return cv_adminonly:GetBool()
end

function ANCF.GetMaxFieldSize()
	return math.Clamp( cv_maxsize:GetInt(), 128, 16384 )
end

function ANCF.IsFreeForAll()
	if game.SinglePlayer() then return true end

	return cv_freeforall:GetBool()
end

function ANCF.IsBlockingSuperAdmin()
	if game.SinglePlayer() then return true end

	return cv_blocksuperadmin:GetBool()
end

function ANCF.GetRecheckTime()
	return math.Clamp( cv_rechecktime:GetFloat(), 0.01, 5 )
end

local function RemoveInValid( i )
	if not ANCF.Installed then return false end

	if not i then
		return false
	end

	if IsValid( AntiNoclipFields[i] ) then
		if not AntiNoclipFields[i].GetDisabledBool then
			return false
		end
		if AntiNoclipFields[i]:GetDisabledBool() then
			return false
		end

		return true
	end

	AntiNoclipFields[i] = nil
	return false
end

local function IsInRange( ancf, pos )
	if not ANCF.Installed then return false end

	return ancf:IsVecInField( pos )
end

local function IsInField( ancf, ent )
	if not ANCF.Installed then return false end

	return ent:ANCF_GetInField() and IsInRange( ancf, ent:GetPos() )
end

local function GetOwner( ent )
	if not ANCF.Installed then return nil end
	if not IsValid(ent) then return nil end

	return ent:ANCF_GetOwner()
end

local function IsBlockedInside( ancf, insidePlOrEnt, funcname, allowforall )
	if not allowforall and not ancf:IsValidAdminOwner() then return false end
	if not IsValid(insidePlOrEnt) then return false end

	if insidePlOrEnt:IsPlayer() then
		if not ancf:IsPlValidRange(insidePlOrEnt) then return false end
	else
		local owner = GetOwner(insidePlOrEnt)

		if IsValid(owner) then
			if not ancf:IsPlValid(owner) then return false end
		end

		if not IsInField(ancf, insidePlOrEnt) then return false end
	end

	local func = ancf["GetDisable" .. funcname .. "Bool"]
	if not func then return false end

	return func( ancf )
end

local function IsBlockedOutside( ancf, outsidePlOrEnt, funcname, insideEntOrPos )
	if not ancf:GetOutsideProtectBool() then return false end
	if not ancf:IsValidAdminOwner() then return false end
	if not IsValid(outsidePlOrEnt) then return false end

	local outsideOwner = GetOwner(outsidePlOrEnt)

	if IsValid(outsideOwner) then
		if not ancf:IsPlValid(outsideOwner) then return false end
	end

	if isentity(insideEntOrPos) then
		if IsValid(insideEntOrPos) then
			if not IsInField(ancf, insideEntOrPos) then return false end
		end

		insideEntOrPos = nil
	end

	if insideEntOrPos then
		if not IsInRange( ancf, insideEntOrPos ) then return false end
	end

	local func = ancf["GetDisable" .. funcname .. "Bool"]
	if not func then return false end

	return func( ancf )
end

-- Block E2 too
if SERVER then
	util.AddNetworkString( "__ANCF_InField" )

	-- Block spawning PropCore props
	local PropCore_CreateProp = nil
	hook.Add( "OnEntityCreated", "AntiNoclipField_E2Block", function()
		if not WireAddon or PropCore_CreateProp then
			hook.Remove( "OnEntityCreated", "AntiNoclipField_E2Block" )
			return
		end

		if not PropCore or not PropCore.CreateProp then return end

		PropCore_CreateProp = PropCore.CreateProp

		function PropCore.CreateProp( self, model, pos, ... )
			for i, ancf in pairs( AntiNoclipFields ) do
				if not RemoveInValid( i ) then continue end

				local pl = self.player

				if IsBlockedInside( ancf, pl, "Spawn" ) then
					return nil
				end

				if IsBlockedOutside( ancf, pl, "Spawn", pos ) then
					return nil
				end
			end

			return PropCore_CreateProp( self, model, pos, ... )
		end

		hook.Remove( "OnEntityCreated", "AntiNoclipField_E2Block" )
	end )
end

local EntityMeta = FindMetaTable("Entity")

function EntityMeta:ANCF_GetGrabbedBy()
	if not ANCF.IsValidEntity( self ) then return end

	return self.__ancf_grabbedby
end

function EntityMeta:ANCF_GetGrabbed()
	if not ANCF.IsValidEntity( self ) then return end

	return self.__ancf_grabbed
end

function EntityMeta:ANCF_GetGrabbedWith()
	if not ANCF.IsValidEntity( self ) then return end

	return self.__ancf_grabbed_with
end
function EntityMeta:ANCF_Clear()
	if not ANCF.IsValidEntity( self ) then return end

	self.__ancf_grabbedby = nil
	self.__ancf_grabbed = nil
	self.__ancf_grabbed_with = nil
end

function EntityMeta:ANCF_DisableGodmode( bool )
	if not ANCF.IsValidEntity( self ) then return end
	if CLIENT then return end

	if not self:IsPlayer() then return end

	bool = bool or false
	local godmode = self:HasGodMode() or false

	if bool then
		if self.__ancf_oldgodmode == nil then
			self.__ancf_oldgodmode = godmode
		end

		self:GodDisable()
	else
		if self.__ancf_oldgodmode == nil then return end

		if self.__ancf_oldgodmode then
			self:GodEnable()
		else
			self:GodDisable()
		end

		self.__ancf_oldgodmode = nil
	end
end

function EntityMeta:ANCF_SetInField( bool )
	if not ANCF.IsValidEntity( self ) then return end

	if bool then
		self.__ancf_infield = true
	else
		self.__ancf_infield = nil
	end
end

function EntityMeta:ANCF_GetInField()
	if not ANCF.IsValidEntity( self ) then return false end

	return self.__ancf_infield or false
end

function EntityMeta:ANCF_GetOwner()
	if not ANCF.IsValidEntity( self ) then return nil end
	if self:IsPlayer() then return self end

	local realpl = nil

	if isfunction(self.CPPIGetOwner) then
		-- Some authors can't follow standards ...
		local pl, id = self:CPPIGetOwner()

		if not pl or isentity( pl ) then
			realpl = pl
		else
			if not id or isentity( id ) then
				realpl = id
			end
		end
	end

	if not IsValid(realpl) then
		realpl = self.__ancf_owner
	end

	if not IsValid(realpl) then
		realpl = self:GetOwner()
	end

	if IsValid(realpl) then
		return realpl
	end

	return nil
end

function EntityMeta:ANCF_SetOwner( ent )
	if not ANCF.IsValidEntity( self ) then return end
	if self:IsPlayer() then return end
	if not IsValid(ent) then return end

	self.__ancf_owner = ent
end

if CLIENT then
	net.Receive( "__ANCF_InField", function( length )
		local self = net.ReadEntity()
		local ent = net.ReadEntity()

		if not IsValid( self ) then return end
		if not IsValid( ent ) then return end
		local Entered = ( net.ReadBit() == 1 )

		if Entered then
			if self.OnFieldEnter then
				self:OnFieldEnter( ent )
			end
		else
			if self.OnFieldLeave then
				self:OnFieldLeave( ent )
			end
		end
	end )
end

-- Set Owner of spawned objects
local function AntiNoclipField_EntityOwner(pl, ...)
	if not IsValid(pl) then
		return
	end

	local ent =  { ...}

	for k, v in ipairs(ent) do
		if isentity(v) and IsValid(v) then
			ent = v
			break
		end
	end

	if not IsValid(ent) then
		return
	end

	ent:ANCF_SetOwner(pl)
end

hook.Add( "PlayerSpawnedEffect", "AntiNoclipField_EntityOwner", AntiNoclipField_EntityOwner )
hook.Add( "PlayerSpawnedNPC", "AntiNoclipField_EntityOwner", AntiNoclipField_EntityOwner )
hook.Add( "PlayerSpawnedObject", "AntiNoclipField_EntityOwner", AntiNoclipField_EntityOwner )
hook.Add( "PlayerSpawnedProp", "AntiNoclipField_EntityOwner", AntiNoclipField_EntityOwner )
hook.Add( "PlayerSpawnedRagdoll", "AntiNoclipField_EntityOwner", AntiNoclipField_EntityOwner )
hook.Add( "PlayerSpawnedSENT", "AntiNoclipField_EntityOwner", AntiNoclipField_EntityOwner )
hook.Add( "PlayerSpawnedSWEP", "AntiNoclipField_EntityOwner", AntiNoclipField_EntityOwner )
hook.Add( "PlayerSpawnedVehicle", "AntiNoclipField_EntityOwner", AntiNoclipField_EntityOwner )

local function OnField( ancf, ent )
	if not IsValid( ent ) then
		ancf.InsideEntities[ent or NULL] = nil

		return
	end

	if not IsInField( ancf, ent ) and ancf.InsideEntities[ent] then
		ancf.InsideEntities[ent] = nil

		if ancf.OnFieldLeave then
			ancf:OnFieldLeave( ent )
		end

		return
	end
end

local oldtime = CurTime()
local function AntiNoclipField_OnField()
	if (CurTime() - oldtime) < ANCF.GetRecheckTime() then return end

	for i, ancf in pairs( AntiNoclipFields ) do
		if not RemoveInValid( i ) then continue end
		if not ancf.InsideEntities then continue end

		for ent, _ in pairs( ancf.InsideEntities ) do
			OnField( ancf, ent )
		end
	end

	oldtime = CurTime()
end

hook.Add( "Think", "AntiNoclipField_OnField", AntiNoclipField_OnField )

-- Player Noclip Hook
-- Disable Noclip use in range
local function AntiNoclipField_PNC( pl, on )
	if not IsValid( pl ) then return end
	if not on then return end

	for i, ancf in pairs( AntiNoclipFields ) do
		if not RemoveInValid( i ) then continue end

		if IsBlockedInside( ancf, pl, "Noclip", true ) then
			return false
		end
	end
end

hook.Add( "PlayerNoClip", "AntiNoclipField_PNC", AntiNoclipField_PNC )

-- Flashlight Hook
-- Disable Flashlight use in range
local function AntiNoclipField_UFL( pl, on )
	if not IsValid( pl ) then return end
	if not on then return end

	for i, ancf in pairs( AntiNoclipFields ) do
		if not RemoveInValid( i ) then continue end

		if IsBlockedInside( ancf, pl, "Flashlight" ) then
			return false
		end
	end
end

hook.Add( "PlayerSwitchFlashlight", "AntiNoclipField_UFL", AntiNoclipField_UFL )

-- Player Spawn Hooks
-- Disable Spawning objects in range
local function AntiNoclipField_PSO( pl )
	if not IsValid( pl ) then return end

	for i, ancf in pairs( AntiNoclipFields ) do
		if not RemoveInValid( i ) then continue end

		if IsBlockedInside( ancf, pl, "Spawn" ) then
			return false
		end

		local trace = pl:GetEyeTrace()
		if trace.Hit then
			local ent = trace.Entity
			if IsValid( ent ) and IsBlockedOutside( ancf, pl, "Spawn", ent ) then
				return false
			end

			if IsBlockedOutside( ancf, pl, "Spawn", trace.HitPos ) then
				return false
			end
		end
	end
end

hook.Add( "PlayerSpawnEffect", "AntiNoclipField_PSO", AntiNoclipField_PSO )
hook.Add( "PlayerSpawnNPC", "AntiNoclipField_PSO", AntiNoclipField_PSO )
hook.Add( "PlayerSpawnObject", "AntiNoclipField_PSO", AntiNoclipField_PSO )
hook.Add( "PlayerSpawnProp", "AntiNoclipField_PSO", AntiNoclipField_PSO )
hook.Add( "PlayerSpawnRagdoll", "AntiNoclipField_PSO", AntiNoclipField_PSO )
hook.Add( "PlayerSpawnSENT", "AntiNoclipField_PSO", AntiNoclipField_PSO )
hook.Add( "PlayerSpawnSWEP", "AntiNoclipField_PSO", AntiNoclipField_PSO )
hook.Add( "PlayerGiveSWEP", "AntiNoclipField_PSO", AntiNoclipField_PSO )
hook.Add( "PlayerSpawnVehicle", "AntiNoclipField_PSO", AntiNoclipField_PSO )

-- Player Suicide Hook
-- Disable Suicide for players in range
local function AntiNoclipField_CPS( pl, _, _, speed )
	if not IsValid( pl ) then return end

	for i, ancf in pairs( AntiNoclipFields ) do
		if not RemoveInValid( i ) then continue end

		if IsBlockedInside( ancf, pl, "Suicide" ) then
			return speed ~= nil
		end
	end
end

hook.Add( "CanPlayerSuicide", "AntiNoclipField_CPS", AntiNoclipField_CPS )
hook.Add( "OnPlayerHitGround", "AntiNoclipField_CPS", AntiNoclipField_CPS )

local function IsSuicide(target, dmginfo)
	if not IsValid( target ) then return false end
	if not target:IsPlayer() then return false end

	local attacker = GetOwner(dmginfo:GetAttacker())
	local inflictor = GetOwner(dmginfo:GetInflictor())

	if IsValid(attacker) or IsValid(inflictor) then
		if attacker ~= target and inflictor ~= target then
			return false
		end
	end

	return true
end

-- Player Damage Hook
-- Disable Suicide for players in range by shooting themselves
local function AntiNoclipField_PDM( target, dmginfo )
	if not IsValid( target ) then return end

	if not IsSuicide(target, dmginfo) then
		return
	end

	for i, ancf in pairs( AntiNoclipFields ) do
		if not RemoveInValid( i ) then continue end

		if IsBlockedInside( ancf, target, "Suicide" ) then
			dmginfo:SetDamage( 0 )
			return dmginfo
		end
	end
end

hook.Add( "EntityTakeDamage", "AntiNoclipField_PDM", AntiNoclipField_PDM )

-- Player Damage Hook
-- Disable Damage for entities in range
local function AntiNoclipField_EDM( target, dmginfo )
	if not IsValid( target ) then return end

	local inflictor = GetOwner(dmginfo:GetInflictor())
	local attacker = GetOwner(dmginfo:GetAttacker())

	if IsSuicide(target, dmginfo) then
		return
	end

	if not IsValid( inflictor ) then
		inflictor = attacker
	end

	if not IsValid( inflictor ) then
		return
	end

	for i, ancf in pairs( AntiNoclipFields ) do
		if not RemoveInValid( i ) then continue end

		if IsBlockedInside( ancf, inflictor, "Damage" ) then
			dmginfo:SetDamage( 0 )
			return dmginfo
		end

		if IsValid( target ) and IsBlockedOutside( ancf, inflictor, "Damage", target ) then
			dmginfo:SetDamage( 0 )
			return dmginfo
		end
	end
end

hook.Add( "EntityTakeDamage", "AntiNoclipField_EDM", AntiNoclipField_EDM )

-- Pickup Hook
-- Disable  + USE Pickup in range
local function AntiNoclipField_APP( pl, ent )
	if not IsValid( pl ) then return end
	if IsValid( ent ) and ent:IsPlayer() then return end -- Ignore Players

	for i, ancf in pairs( AntiNoclipFields ) do
		if not RemoveInValid( i ) then continue end

		if IsBlockedInside( ancf, pl, "Pickup" ) then
			return false
		end

		if IsValid( ent ) and IsBlockedOutside( ancf, pl, "Pickup", ent ) then
			return false
		end
	end

	if IsValid( ent ) then
		ent.__ancf_grabbedby = pl
		ent.__ancf_grabbed_with = "Pickup"
	end

	pl.__ancf_grabbed = ent
end

hook.Add( "AllowPlayerPickup", "AntiNoclipField_APP", AntiNoclipField_APP )


-- Physgun Hooks
-- Disable physgun use in range
local function AntiNoclipField_PGU( pl, ent )
	if not IsValid( pl ) then return end
	if IsValid( ent ) and ent:IsPlayer() then return end -- Ignore Players

	for i, ancf in pairs( AntiNoclipFields ) do
		if not RemoveInValid( i ) then continue end

		if IsBlockedInside( ancf, pl, "Physgun" ) then
			return false
		end

		if IsValid( ent ) and IsBlockedOutside( ancf, pl, "Physgun", ent ) then
			return false
		end
	end

	if IsValid( ent ) then
		ent.__ancf_grabbedby = pl
		ent.__ancf_grabbed_with = "Physgun"
	end

	pl.__ancf_grabbed = ent
end

hook.Add( "PhysgunPickup", "AntiNoclipField_PGU", AntiNoclipField_PGU )
hook.Add( "CanPlayerUnfreeze", "AntiNoclipField_PGU", AntiNoclipField_PGU )

-- Gravitygun Hooks
-- Disable gravitygun use in range
local function AntiNoclipField_GGU( pl, ent )
	if not IsValid( pl ) then return end
	if IsValid( ent ) and ent:IsPlayer() then return end -- Ignore Players

	for i, ancf in pairs( AntiNoclipFields ) do
		if not RemoveInValid( i ) then continue end

		if IsBlockedInside( ancf, pl, "Gravitygun" ) then
			return false
		end

		if IsValid( ent ) and IsBlockedOutside( ancf, pl, "Gravitygun", ent ) then
			return false
		end
	end

	if IsValid( ent ) then
		ent.__ancf_grabbedby = pl
		ent.__ancf_grabbed_with = "Gravitygun"
	end

	pl.__ancf_grabbed = ent
end

hook.Add( "GravGunPickupAllowed", "AntiNoclipField_GGU", AntiNoclipField_GGU )
hook.Add( "GravGunPunt", "AntiNoclipField_GGU", AntiNoclipField_GGU )

-- Vehicle Hook
-- Disable vehicle use in range
local function AntiNoclipField_CEV( pl, ent )
	if not IsValid( pl ) then return end

	for i, ancf in pairs( AntiNoclipFields ) do
		if not RemoveInValid( i ) then continue end

		if IsBlockedInside( ancf, pl, "Vehicle" ) then
			return false
		end

		if IsValid( ent ) and IsBlockedOutside( ancf, pl, "Vehicle", ent ) then
			return false
		end
	end
end

hook.Add( "CanPlayerEnterVehicle", "AntiNoclipField_CEV", AntiNoclipField_CEV )

-- Tools Hook
-- Disable Tool use in range
local function AntiNoclipField_CTG( pl, trace )
	if not IsValid( pl ) then return end

	for i, ancf in pairs( AntiNoclipFields ) do
		if not RemoveInValid( i ) then continue end

		if IsBlockedInside( ancf, pl, "Tools" ) then
			return false
		end

		if trace.Hit then
			local ent = trace.Entity
			if IsValid( ent ) and IsBlockedOutside( ancf, pl, "Tools", ent ) then
				return false
			end

			if IsBlockedOutside( ancf, pl, "Tools", trace.HitPos ) then
				return false
			end
		end
	end
end
hook.Add( "CanTool", "AntiNoclipField_CTG", AntiNoclipField_CTG )

-- Drive Hook
-- Disable Driving in range
local function AntiNoclipField_CDO( pl, ent )
	if not IsValid( pl ) then return end
	if IsValid( ent ) and ent:IsPlayer() then return end -- Ignore Players

	for i, ancf in pairs( AntiNoclipFields ) do
		if not RemoveInValid( i ) then continue end

		if IsBlockedInside( ancf, pl, "Drive" ) then
			return false
		end

		if IsValid( ent ) and IsBlockedOutside( ancf, pl, "Drive", ent ) then
			return false
		end
	end

	if IsValid( ent ) then
		ent.__ancf_grabbedby = pl
		ent.__ancf_grabbed_with = "Drive"
	end

	pl.__ancf_grabbed = ent
end

hook.Add( "CanDrive", "AntiNoclipField_CDO", AntiNoclipField_CDO )

-- Property Hook
-- Disable Property in range
local function AntiNoclipField_CPO( pl, property, ent )
	if not IsValid( pl ) then return end

	for i, ancf in pairs( AntiNoclipFields ) do
		if not RemoveInValid( i ) then continue end

		if IsBlockedInside( ancf, pl, "Property" ) then
			return false
		end

		if IsValid( ent ) and IsBlockedOutside( ancf, pl, "Property", ent ) then
			return false
		end
	end
end

hook.Add( "CanProperty", "AntiNoclipField_CPO", AntiNoclipField_CPO )


local function AddPermaPropsSupport()
	if not PermaProps then
		return
	end

	if not PermaProps.SpecialENTSSpawn then
		return
	end

	if not PermaProps.SpecialENTSSave then
		return
	end

	PermaProps.SpecialENTSSpawn["sent_anti_noclip_control"] = function(ent, ...)
		return ent:PermaPropLoad( ...)
	end

	PermaProps.SpecialENTSSave["sent_anti_noclip_control"] = function(ent, ...)
		return ent:PermaPropSave( ...)
	end
end

AddPermaPropsSupport()
