ENT.Type			= "anim"
ENT.Base			= "base_anim"
ENT.PrintName		= "Anti-Noclip Field"
ENT.Author			= "Meoowe and Grocel"

ENT.Spawnable		= false
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_TRANSLUCENT

local ANCF = ANCF or {}

local Color = Color
local IsValid = IsValid
local Model = Model
local Vector = Vector

local CLIENT = CLIENT
local SERVER = SERVER

local Models = {
	[0] = Model( "models/anti-noclip_field/cube.mdl" ),
	[1] = Model( "models/anti-noclip_field/sphere.mdl" ),
	[2] = Model( "models/anti-noclip_field/cylinder.mdl" ),
	[3] = Model( "models/anti-noclip_field/pyramid.mdl" ),
	[4] = Model( "models/anti-noclip_field/cone.mdl" ),
}

local Color_Red = Color( 200, 0, 0 )
function ENT:Initialize()
	if !ANCF.Installed then
		self:Remove()

		return
	end

	self:SetModel( Models[0] )
	self:DrawShadow( false )
	self:SetColor( Color_Red )
end

function ENT:SetupDataTables()
	//String

	//Bool

	//Float

	//Int

	//Vector

	//Angle

	//Entity
end

function ENT:UpdateShape()
	local Parent = self:GetParent()
	if SERVER then
	if !IsValid( Parent ) then
		self:Remove()

		return
	end
	end
	self.ControlEnt = Parent
	local shape = Parent:GetShapeInt()

	local model = Models[shape] or Models[0]
	self:SetModel( model )

	local size = Parent:GetSizeInt()
	local scale = size / 512
	local ScaleVec = Vector( scale, scale, scale )
	local minpos = ScaleVec * -512
	local maxpos = ScaleVec * 512

	self:SetCollisionBounds( minpos, maxpos )

	if SERVER then
		self:BuildPhysics( shape, size, ScaleVec, minpos, maxpos )
		self:FindEnts()
	end

	if CLIENT then
		self:ResizeModel( ScaleVec, minpos, maxpos )
	end
end

function ENT:OnRemove()
	if !IsValid( self.ControlEnt ) then return end
	if SERVER then
	self.ControlEnt:Remove()
	end
end
