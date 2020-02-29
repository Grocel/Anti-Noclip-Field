TOOL.Category		= "Construction"
local TOOL_Class	= "anti_noclip_control"
TOOL.Name			= "#Tool."..TOOL_Class..".name"
TOOL.Command		= nil
TOOL.ConfigName		= nil

local ANCF = ANCF or {}
local cleanup = cleanup
local constraint = constraint
local debugoverlay = debugoverlay
local draw = draw
local duplicator = duplicator
local ents = ents
local gui = gui
local language = language
local math = math
local table = table
local undo = undo
local util = util
local vgui = vgui

local Angle = Angle
local Color = Color
local CreateClientConVar = CreateClientConVar
local CreateConVar = CreateConVar
local Entity = Entity
local IsUselessModel = IsUselessModel
local IsValid = IsValid
local Label = Label
local LocalPlayer = LocalPlayer
local Model = Model
local Player = Player
local UTIL_IsUselessModel = UTIL_IsUselessModel
local Vector = Vector
local pairs = pairs
local tonumber = tonumber
local tostring = tostring

local CLIENT = CLIENT
local HUD_PRINTTALK = HUD_PRINTTALK
local SERVER = SERVER

local ShapeOptionsToString = {
	[0] = "Cube",
	[1] = "Sphere",
	[2] = "Cylinder",
	[3] = "Pyramid",
	[4] = "Cone"
}

local ShapeOptionsToNumber = {}
for n, s in pairs( ShapeOptionsToString ) do
	ShapeOptionsToNumber[s] = n
end


local minsize = 64

local maxshape = #ShapeOptionsToString
local minshape = 0

cleanup.Register( TOOL_Class )

if CLIENT then
	language.Add( "Undone_"..TOOL_Class, "Undone Anti-Noclip Field" )
	language.Add( "SBoxLimit_"..TOOL_Class, "You've hit the Anti-Noclip Fields limit!" )
	language.Add( "Cleanup_"..TOOL_Class, "Anti-Noclip Fields" )
	language.Add( "Cleaned_"..TOOL_Class, "Cleaned up all Anti-Noclip Fields" )

	language.Add( "Tool."..TOOL_Class..".name", "Anti-Noclip Field" )
	language.Add( "Tool."..TOOL_Class..".desc", "Disable noclip (and other actions) for players in range!" )
	language.Add( "Tool."..TOOL_Class..".0", "Primary: Create a field, Secondary: Copy the settings of a field, Reload: Copy the model of an entity" )

	language.Add( "Tool."..TOOL_Class..".model", "Model:" )
	language.Add( "Tool."..TOOL_Class..".size", "Size:" )
	language.Add( "Tool."..TOOL_Class..".size.desc", "Define the the size of the blocking field. It acts like a radius." )
	language.Add( "Tool."..TOOL_Class..".shape", "Shape:" )
	language.Add( "Tool."..TOOL_Class..".shape.desc", "Define the the shape of the blocking field." )
	language.Add( "Tool."..TOOL_Class..".draw", "Draw Field" )
	language.Add( "Tool."..TOOL_Class..".draw.desc", "Draw the borders of the field." )
	language.Add( "Tool."..TOOL_Class..".ownercan", "Don't block the owner" )
	language.Add( "Tool."..TOOL_Class..".ownercan.desc", "You will be able to noclip in your field.\nAdmins and Superadmins can always noclip unless it is set otherwise." )
	language.Add( "Tool."..TOOL_Class..".active", "Active on spawn" )

	language.Add( "Tool."..TOOL_Class..".adminonly", "Only Admins:" )
	language.Add( "Tool."..TOOL_Class..".adminonly.desc", "These extra options are admin only by default. The ConVar 'sv_anti_noclip_field_freeforall 1' makes them usable by everyone." )
	language.Add( "Tool."..TOOL_Class..".admincan", "Don't block admins" )
	language.Add( "Tool."..TOOL_Class..".admincan.desc", "Other admins will be able to to noclip in your field. Superadmins can always noclip by default.\nThe ConVar 'sv_anti_noclip_field_blocksuperadmin 1' will enable the blocks for superadmins too." )

	for index, setting in pairs( ANCF.SettingsNames or {} ) do
		local id = "disable_"..setting.name

		language.Add( "Tool."..TOOL_Class.."."..id, setting.lang[1] )
		language.Add( "Tool."..TOOL_Class.."."..id..".desc", setting.lang[2] )
	end

	language.Add( "Tool."..TOOL_Class..".protectfromoutside", "Block actions from the outside too." )
	language.Add( "Tool."..TOOL_Class..".protectfromoutside.desc", "If not ticked, only players inside the field will be blocked.\nIf ticked, player actions from outside the proprotected area are blocked aswell." )

	language.Add( "Tool."..TOOL_Class..".clientoptions", "Client options:" )
	language.Add( "Tool."..TOOL_Class..".clientoptions.desc", "These options will affect only you and are not saved in the entity. They are applied immediately." )
	language.Add( "Tool."..TOOL_Class..".force", "Always be affected" )
	language.Add( "Tool."..TOOL_Class..".force.desc", "It will force all noclip fields to always Block you if you are in range. It overrides the settings them. It's usefull for testing." )
	language.Add( "Tool."..TOOL_Class..".hidefields", "Hide all Fields" )
	language.Add( "Tool."..TOOL_Class..".hidefields.desc", "Hide the borders of all fields." )

	CreateClientConVar( TOOL_Class.."_force", "0", true, true )
	CreateClientConVar( TOOL_Class.."_hidefields", "0", true, true )
end

if SERVER then
	CreateConVar( "sbox_max"..TOOL_Class, 20 )
end

TOOL.ClientConVar[ "model" ] = "models/props_junk/TrafficCone001a.mdl"
TOOL.ClientConVar[ "size" ] = "256"
TOOL.ClientConVar[ "shape" ] = ShapeOptionsToString[0]
TOOL.ClientConVar[ "ownercan" ] = "1"
TOOL.ClientConVar[ "active" ] = "1"
TOOL.ClientConVar[ "admincan" ] = "1"

for index, setting in pairs( ANCF.SettingsNames or {} ) do
	TOOL.ClientConVar["disable_"..setting.name] = setting.ConVar
end

TOOL.ClientConVar[ "protectfromoutside" ] = "0"
TOOL.ClientConVar[ "draw" ] = "0"

local AntiNoclipFieldModels = {
	["models/props_junk/TrafficCone001a.mdl"] = {},
	["models/props_lab/huladoll.mdl"] = {},

	["models/props_junk/PopCan01a.mdl"] = {},

	["models/props_c17/streetsign004e.mdl"] = {SpawnAng = Angle(0, 0, 90)},
	["models/props_c17/streetsign004f.mdl"] = {SpawnAng = Angle(0, 0, 90)},

	["models/props_lab/reciever01a.mdl"] = {},
	["models/props_lab/reciever01b.mdl"] = {},

	["models/props_combine/breenglobe.mdl"] = {},
	["models/props_junk/watermelon01.mdl"] = {},
	["models/props_c17/pottery03a.mdl"] = {},

	["models/hunter/blocks/cube025x025x025.mdl"] = {},
	["models/hunter/plates/plate.mdl"] = {},
	["models/XQM/Rails/gumball_1.mdl"] = {},
	["models/XQM/Rails/trackball_1.mdl"] = {}
}

local function ValidEditEntity( ent, ply )
	if ( !IsValid( ent ) ) then return false end
	if ( !IsValid( ply ) ) then return false end
	if ( ent:GetClass() ~= "sent_"..TOOL_Class ) then return false end
	if ( ent.pl ~= ply ) then return false end

	return true
end

local function CalcSpawnAngle( normal, ply_ang, model )
	local Ang = normal:Angle()
	local normalz = math.Round(normal.z, 4)

	local IsWall = false
	local modelsettings = AntiNoclipFieldModels[model or ""] or AntiNoclipFieldModels["models/props_junk/TrafficCone001a.mdl"]
	local angoffset = modelsettings.SpawnAng or Angle(0, 0, 0)
	local FlatOnWall = modelsettings.FlatOnWall

	Ang.p = ( Ang.p + 90 ) % 360
	if ( FlatOnWall and normalz == 0 ) then
		IsWall = true
	end

	if ( normalz == 1 ) then
		Ang.y = ( ply_ang.y + 180 ) % 360
		IsWall = false
	elseif ( normalz == -1 ) then
		Ang.y = ply_ang.y
		IsWall = false
	end

	if ( IsWall ) then
		Ang.p = 0
	end

	Ang:Normalize()

	Ang = Ang + angoffset
	Ang:Normalize()

	return Ang, IsWall, angoffset:Up()
end

local function CalcSpawnPos( ent, IsWall, hitpos, hitnormal, normal )
	local min, max = ent:OBBMins(), ent:OBBMaxs()
	local rmin, rmax = ent:GetRotatedAABB( min, max )
	local size = Vector( math.abs( min.x ) + math.abs( max.x ), math.abs( min.y ) + math.abs( max.y ), math.abs( min.z ) + math.abs( max.z ) )
	local center = (rmin + rmax) / 2

	local Pos = hitpos - center
	Pos = Pos + ( size.z / 2 * normal.z + size.y / 2 * normal.y + size.x / 2 * normal.x ) * normal // Todo: Something propper

	/*debugoverlay.Cross( hitpos, 10, 0.1, Color(0,255,255), false )
	debugoverlay.Cross( Pos, 10, 0.1, Color(255,0,0), false )
	debugoverlay.Cross( Pos + rmin, 10, 0.1, Color(255,128,0), false )
	debugoverlay.Cross( Pos + rmax, 10, 0.1, Color(255,128,0), false )

	debugoverlay.Cross( Pos + min, 10, 0.1, Color(255,255,0), false )
	debugoverlay.Cross( Pos + max, 10, 0.1, Color(255,255,0), false )*/

	return Pos
end

local function advWeld( ent, traceEntity, tracePhysicsBone, DOR, collision, AllowWorldWeld )
	if ( !SERVER ) then return end
	if ( !IsValid( ent ) ) then return end
	if ( IsValid( traceEntity ) and ( traceEntity:IsNPC() or traceEntity:IsPlayer() ) ) then return end

	local phys = ent:GetPhysicsObject()
	if ( AllowWorldWeld or ( IsValid( traceEntity ) and !traceEntity:IsWorld() ) ) then
		local const = constraint.Weld( ent, traceEntity, 0, tracePhysicsBone, 0, !collision, DOR )
		// Don't disable collision if it's not attached to anything
		if ( !collision ) then
			if IsValid( phys ) then phys:EnableCollisions( false ) end
			ent.nocollide = true
		end
		return const
	else
		if IsValid( phys ) then phys:EnableMotion( false ) end
		return nil
	end
end

local function EditAntiNoclipField( ent, data )
	if !SERVER then return end

	ent:SetSizeInt( data.size )
	ent:SetShapeInt( data.shape )
	ent:SetDrawBordersBool( data.draw )

	ent:SetAffectOwnerBool( !data.ownercan )
	ent:SetAffectAdminBool( !data.admincan )

	for index, setting in pairs( ANCF.SettingsNames or {}  ) do
		local func = ent["SetDisable"..setting.funcname.."Bool"]

		if func then
			func( ent, data.disabletab[setting.name] )
		end
	end

	ent:SetOutsideProtectBool( data.outsideprotect )

	ent:PhysWake()
end

local function MakeAntiNoclipField( pl, Pos, Ang, model, data, nocollide )
	if !SERVER then return end
	if !ANCF.Installed then return end

	if IsValid( pl ) then
		if ANCF.IsAdminOnly() and !pl:IsAdmin() then return end // Fixes dupe exploit
		if !pl:CheckLimit( TOOL_Class ) then return end
	end

	local ent = ents.Create( "sent_"..TOOL_Class )
	if !IsValid( ent ) then return end

	ent:SetPos( Pos )
	ent:SetAngles( Ang )
	ent:SetModel( Model( model or "models/props_junk/TrafficCone001a.mdl" ) )
	ent:Spawn()
	ent:Activate()

	EditAntiNoclipField( ent, data )

	if IsValid( pl ) then
		ent:SetOwnerEnt( pl )
		ent:SetAdminMode( pl:IsAdmin() )
		ent:SetNoOwner( false )
	else
		ent:SetOwnerEnt( nil )
		ent:SetNoOwner( true )
		ent:SetAdminMode( true )
	end

	ent:SetDisabledBool( !data.active )

	if ( nocollide == true ) then ent:GetPhysicsObject():EnableCollisions( false ) end

	local ttable = {
		nocollide	= nocollide,
		pl			= pl,
		settings	= data,
	}
	table.Merge( ent, ttable )

	if IsValid( pl ) then
		pl:AddCount( TOOL_Class, ent )
	end

	return ent
end

if SERVER then
	duplicator.RegisterEntityClass( "sent_"..TOOL_Class, MakeAntiNoclipField, "Pos", "Ang", "Model", "settings", "nocollide" )
end

function TOOL:LeftClick( trace )
	if !trace.Hit then return false end
	if !trace.HitPos then return false end

	local ent = trace.Entity
	if IsValid( ent ) and ent:IsPlayer() then return false end

	local ply = self:GetOwner()
	if ( !IsValid( ply ) ) then return false end

	if !ANCF.Installed then
		ply:PrintMessage( HUD_PRINTTALK, ( ANCF.Addonname or "" ) .. ( ANCF.ErrorString or "" ) .. "\nAnti-Noclip Field not Loaded!" )

		return false
	end

	if ANCF.IsAdminOnly() and !ply:IsAdmin() then
		ply:PrintMessage( HUD_PRINTTALK, "The Anti-Noclip Field tool is admin only on this server." )

		return false
	end


	if CLIENT then return true end
	if ( !util.IsValidPhysicsObject( ent, trace.PhysicsBone ) ) then return false end
	if ( IsValid( ent ) and !util.IsValidPhysicsObject( ent, trace.PhysicsBone ) ) then return false end


	local data = {}
	data.size = math.Clamp( self:GetClientNumber( "size" ), minsize, ANCF.GetMaxFieldSize() )
	data.shape = math.Clamp( ShapeOptionsToNumber[self:GetClientInfo( "shape" )] or 0, minshape, maxshape )
	data.ownercan = self:GetClientNumber( "ownercan" ) ~= 0
	data.active = self:GetClientNumber( "active" ) ~= 0
	data.admincan = self:GetClientNumber( "admincan" ) ~= 0
	data.draw = self:GetClientNumber( "draw" ) ~= 0

	local disabletab = {}

	for index, setting in pairs( ANCF.SettingsNames or {} ) do
		disabletab[setting.name] = self:GetClientNumber( "disable_"..setting.name ) ~= 0
	end

	data.disabletab = disabletab
	data.outsideprotect = self:GetClientNumber( "protectfromoutside" ) ~= 0

	if ( ValidEditEntity( ent, ply ) ) then
		EditAntiNoclipField( ent, data ) // Update
		return true
	end

	// Create
	if ( !self:GetSWEP():CheckLimit( TOOL_Class ) ) then return false end

	local model = self:GetModel()
	local Ang, IsWall, Normal = CalcSpawnAngle( trace.HitNormal, ply:GetAngles(), model )

	local ent = MakeAntiNoclipField( ply, trace.HitPos, Ang, model, data, false )

	local Pos = CalcSpawnPos( ent, IsWall, trace.HitPos, trace.HitNormal, Normal )
	ent:SetPos( Pos )

	local const = advWeld( ent, trace.Entity, trace.PhysicsBone, true )

	undo.Create( TOOL_Class )
		undo.AddEntity( ent )
		if IsValid( const ) then
			undo.AddEntity( const )
		end
		undo.SetPlayer( ply )
	undo.Finish()
	ply:AddCleanup( TOOL_Class, ent )

	return true
end
function TOOL:SetClientInfo( ply, name, var )
	if !IsValid( ply ) then return end

	ply:ConCommand( TOOL_Class.."_"..name.." "..tostring( var ) )
end
function TOOL:SetClientNumber( ply, name, var )
	self:SetClientInfo( ply, name, tonumber( var ) or 0 )
end

function TOOL:SetClientBool( ply, name, var )
	self:SetClientNumber( ply, name, ( var == true ) and 1 or 0 )
end


function TOOL:RightClick( trace )
	if !trace.Hit then return false end

	local ent = trace.Entity
	local ply = self:GetOwner()
	if ( !IsValid( ply ) ) then return false end

	if !ANCF.Installed then
		ply:PrintMessage( HUD_PRINTTALK, ( ANCF.Addonname or "" ) .. ( ANCF.ErrorString or "" ) .. "\nAnti-Noclip Field not Loaded!" )

		return false
	end

	if ( !ValidEditEntity( ent, ply ) ) then return false end
	if ( CLIENT ) then return true end
	if ( !util.IsValidPhysicsObject( ent, trace.PhysicsBone ) ) then return false end

	self:SetClientNumber( ply, "size", ent:GetSizeInt() )
	self:SetClientInfo( ply, "shape", ShapeOptionsToString[ent:GetShapeInt()] or ShapeOptionsToString[0] )
	self:SetClientBool( ply, "ownercan", !ent:GetAffectOwnerBool() )
	self:SetClientBool( ply, "admincan", !ent:GetAffectAdminBool() )
	self:SetClientBool( ply, "draw", ent:GetDrawBordersBool() )

	for index, setting in pairs( ANCF.SettingsNames or {} ) do
		local func = ent["GetDisable"..setting.funcname.."Bool"]
		local var = false

		if func then
			var = func( ent )
		end

		self:SetClientBool( ply, "disable_"..setting.name, var )
	end

	self:SetClientBool( ply, "protectfromoutside", ent:GetOutsideProtectBool() )

	return true
end

function TOOL:Reload( trace )
	if !trace.Hit then return false end

	local ply = self:GetOwner()
	if ( !IsValid( ply ) ) then return false end

	if !ANCF.Installed then
		ply:PrintMessage( HUD_PRINTTALK, ( ANCF.Addonname or "" ) .. ( ANCF.ErrorString or "" ) .. "\nAnti-Noclip Field not Loaded!" )

		return false
	end

	local ent = trace.Entity

	if ( !IsValid( ent ) ) then return false end
	if ent:IsPlayer() then return false end
	if ent:IsNPC() then return false end

	if ( CLIENT ) then return true end
	if ( !util.IsValidPhysicsObject( ent, trace.PhysicsBone ) ) then return false end
	if ( ent:GetPhysicsObjectCount() > 1 ) then return false end // No ragdolls!

	local model = ent:GetModel()
	if ( UTIL_IsUselessModel( model ) ) then return false end

	self:SetClientInfo( ply, "model", model )

	return true
end


function TOOL:UpdateGhostAntiNoclipField( ent, player, model )
	if !ANCF.Installed then return end
	if !IsValid( ent ) then return end
	if !IsValid( player ) then return end

	local trace = player:GetEyeTrace()
	if !trace.Hit then return end

	local hitent = trace.Entity
	if ( ValidEditEntity( hitent, player ) ) then
		ent:SetNoDraw( true )
		return
	end

	local Ang, IsWall, Normal = CalcSpawnAngle( trace.HitNormal, player:GetAngles(), model )
	ent:SetAngles( Ang )

	local Pos = CalcSpawnPos( ent, IsWall, trace.HitPos, trace.HitNormal, Normal )
	ent:SetPos( Pos )

	ent:SetNoDraw( false )
end

local Vec_Zero = Vector()
local Ang_Zero = Angle()

function TOOL:Think()
	if !ANCF.Installed then return end

	local model = self:GetModel()

	if !IsValid( self.GhostEntity ) then
		self:MakeGhostEntity( Model( model ), Vec_Zero, Ang_Zero )
	end

	if !IsValid( self.GhostEntity ) then return end
	if self.GhostEntity:GetModel() != model then
		self.GhostEntity:SetModel( model )
		self.GhostEntity:DrawShadow( false )
	end

	self:UpdateGhostAntiNoclipField( self.GhostEntity, self:GetOwner(), model )
end

function TOOL:GetModel()
	local model = "models/props_junk/TrafficCone001a.mdl"
	local modelcheck = self:GetClientInfo( "model" )

	if util.IsValidModel( modelcheck ) and util.IsValidProp( modelcheck ) and !UTIL_IsUselessModel( modelcheck ) then
		model = modelcheck
	end

	return model
end

function TOOL:Holster()
	self:ReleaseGhostEntity()
end

function TOOL:Deploy()
	--self:ReleaseGhostEntity()
end

local function AddNumSlider( panel, command, descbool )
	if !CLIENT then return end

	local w = panel:GetWide()
	local NumSlider = vgui.Create( "DNumSlider" )
	panel:AddPanel( NumSlider )

	NumSlider:SetWide( w )
	NumSlider:SetText( "#Tool."..TOOL_Class.."."..command )
	NumSlider:SetDark( true )
	NumSlider:SetConVar( TOOL_Class.."_"..command )
	if descbool then
		NumSlider:SetToolTip( "#Tool."..TOOL_Class.."."..command..".desc" )
	end

	return NumSlider
end

local function AddCheckbox( panel, command, descbool, adminonly )
	if !CLIENT then return end

	local CheckBox = panel:CheckBox( "#Tool."..TOOL_Class.."."..command, TOOL_Class.."_"..command )
	if descbool then
		CheckBox:SetToolTip( "#Tool."..TOOL_Class.."."..command..".desc" )
	end

	if !adminonly then
		return CheckBox
	end

	local ply = LocalPlayer()

	local Oldadmin = nil
	CheckBox.Think = function( panel )
		local admin = ply:IsAdmin() or ANCF.IsFreeForAll()

		if Oldadmin ~= admin then
			Oldadmin = admin

			panel:SetEnabled( admin )
			panel:SetMouseInputEnabled( admin )
			panel.Label:SetDark( admin )
		end
	end


	return CheckBox
end

local function AddLabel( panel, name, descbool )
	if !CLIENT then return end

	local w = panel:GetWide()
	local Label = vgui.Create( "DLabel" )
	panel:AddPanel( Label )

	Label:SetText( "#Tool."..TOOL_Class.."."..name )
	Label:SetDark( true )
	Label:SizeToContents()
	Label:SetWide( w )
	if descbool then
		Label:SetToolTip( "#Tool."..TOOL_Class.."."..name..".desc" )
	end

	return Label
end

local function AddComboBox( panel, command, options, descbool )
	if !CLIENT then return end

	local w = panel:GetWide()
	local textwide = 60
	local ply = LocalPlayer()

	local Panel = vgui.Create( "DPanel" )

	Panel:SetSize( w, 20 )
	Panel:SetDrawBackground( false )
	if descbool then
		Panel:SetToolTip( "#Tool."..TOOL_Class.."."..command..".desc" )
	end

	local Label = vgui.Create( "DLabel", Panel )

	Label:SetText( "#Tool."..TOOL_Class.."."..command )
	Label:SetDark( true )
	Label:SetWide( textwide )
	if descbool then
		Label:SetToolTip( "#Tool."..TOOL_Class.."."..command..".desc" )
	end

	local ComboBox = vgui.Create( "DComboBox", Panel )
	ComboBox:SetPos( textwide, 0 )
	ComboBox:SetSize( w - textwide - 25 , 20 )
	ComboBox:SetText( options[0] or "" )

	for i, data in pairs( options or {} ) do
		ComboBox:AddChoice( data, i )
	end

	local Oldchoise = nil
	ComboBox.Think = function( panel )
		local choise = ply:GetInfo( TOOL_Class.."_"..command )

		if Oldchoise ~= choise then
			Oldchoise = choise
			panel:ChooseOption( choise, 0 )
		end
	end

	ComboBox.OnSelect = function( panel, index, value )
		if Oldchoise == value then return end
		Oldchoise = value

		ply:ConCommand( TOOL_Class.."_"..command.." "..value )
	end

	local PerformLayout = Panel.PerformLayout
	function Panel.PerformLayout( ... )
		PerformLayout( ... )

		w = panel:GetWide()
		textwide = 60

		Panel:SetSize( w, 25 )
		Label:SetWide( textwide )
		ComboBox:SetPos( textwide, 0 )
		ComboBox:SetSize( w - textwide - 25 , 25 )
	end

	panel:AddPanel( Panel )
	return Panel
end

function TOOL.BuildCPanel( panel )
	AddLabel( panel, "desc" )

	if ( !ANCF.Installed ) then
		local label = vgui.Create( "DLabel" )

		label:SetDark( false )
		label:SetHighlight( true )

		label:SetText( ( ANCF.Addonname or "" ) .. ( ANCF.ErrorString or "" ) .. "\nThis tool could not be loaded." )
		label:SizeToContents()
		panel:AddPanel( label )

		return
	end


	local DefaultSettings = {}
		DefaultSettings[TOOL_Class.."_model"] = "models/props_junk/TrafficCone001a.mdl"
		DefaultSettings[TOOL_Class.."_size"] = "256"
		DefaultSettings[TOOL_Class.."_shape"] = ShapeOptionsToString[0]
		DefaultSettings[TOOL_Class.."_ownercan"] = "1"
		DefaultSettings[TOOL_Class.."_active"] = "1"
		DefaultSettings[TOOL_Class.."_admincan"] = "1"

		for index, setting in pairs( ANCF.SettingsNames or {} ) do
			DefaultSettings[TOOL_Class.."_".."disable_"..setting.name] = setting.ConVar
		end

		DefaultSettings[TOOL_Class.."_protectfromoutside"] = "0"
		DefaultSettings[TOOL_Class.."_force"] = "0"
		DefaultSettings[TOOL_Class.."_draw"] = "0"

	local CVars = {}
		CVars[0] = TOOL_Class.."_model"
		CVars[1] = TOOL_Class.."_size"
		CVars[2] = TOOL_Class.."_shape"
		CVars[3] = TOOL_Class.."_ownercan"
		CVars[4] = TOOL_Class.."_admincan"
		CVars[5] = TOOL_Class.."_active"

		local i = 6
		for index, setting in pairs( ANCF.SettingsNames or {} ) do
			CVars[i] = TOOL_Class.."_".."disable_"..setting.name
			i = i + 1
		end

		CVars[i+1] = TOOL_Class.."_protectfromoutside"
		CVars[i+2] = TOOL_Class.."_force"
		CVars[i+3] = TOOL_Class.."_draw"

	panel:AddControl( "ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = TOOL_Class,

		Options = {
			Default = DefaultSettings
		},

		CVars = CVars
	} )

	panel:AddControl( "PropSelect", {
		Label = "#Tool."..TOOL_Class..".model",
		ConVar = TOOL_Class.."_model",
		Category = TOOL_Class,
		Models = AntiNoclipFieldModels
	} )

	local NumSliderSize = AddNumSlider( panel, "size", true )
	local oldmaxsize = ANCF.GetMaxFieldSize()

	NumSliderSize:SetMin( minsize )
	NumSliderSize:SetMax( oldmaxsize )
	NumSliderSize:SetDecimals( 0 )

	NumSliderSize.Think = function( self, ... )
		local maxsize = ANCF.GetMaxFieldSize()
		local size = self:GetValue()

		if oldmaxsize == maxsize then return end
		if size > maxsize then
			size = maxsize
		end
		oldmaxsize = maxsize

		self:SetMax( maxsize )

		self:SetValue( size-1 ) // Force update
		self:SetValue( size )
	end

	AddComboBox( panel, "shape", ShapeOptionsToString, true )

	local label = vgui.Create( "DLabel" )

	label:SetDark( false )
	label:SetHighlight( true )

	label:SetText("If something seems obscure,\nplease read the tooltips of the options." )
	label:SizeToContents()
	panel:AddPanel( label )

	AddCheckbox( panel, "draw", true )
	AddCheckbox( panel, "ownercan", true )
	AddCheckbox( panel, "active" )

	for index, setting in pairs( ANCF.SettingsNames or {} ) do
		if setting.needadmin then continue end
		AddCheckbox( panel, "disable_"..setting.name, true, setting.needadmin )
	end

	AddLabel( panel, "adminonly", true )
	AddCheckbox( panel, "admincan", true, true )

	for index, setting in pairs( ANCF.SettingsNames or {} ) do
		if !setting.needadmin then continue end
		AddCheckbox( panel, "disable_"..setting.name, true, setting.needadmin )
	end

	AddCheckbox( panel, "protectfromoutside", true, true )

	AddLabel( panel, "clientoptions", true )
	AddCheckbox( panel, "force", true )
	AddCheckbox( panel, "hidefields", true )

end
