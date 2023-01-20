local AddCSLuaFile = AddCSLuaFile
local language_Add = CLIENT and language.Add
local util_AddNetworkString = SERVER and util.AddNetworkString
local constraint_GetTable = SERVER and constraint.GetTable
local pairs = pairs
local net_Start = net.Start
local net_WriteString = net.WriteString
local net_WriteUInt = net.WriteUInt
local table_Count = table.Count
local tostring = tostring
local net_Send = SERVER and net.Send
local IsValid = IsValid
local util_IsValidPhysicsObject = util.IsValidPhysicsObject
local include = include
local concommand_Add = concommand.Add
local isvector = isvector
local surface_SetDrawColor = CLIENT and surface.SetDrawColor
local surface_DrawLine = CLIENT and surface.DrawLine
local surface_DrawCircle = CLIENT and surface.DrawCircle
local surface_DrawOutlinedRect = CLIENT and surface.DrawOutlinedRect
local net_WriteTable = net.WriteTable
local net_Receive = net.Receive
local net_ReadString = net.ReadString
local net_ReadUInt = net.ReadUInt
local istable = istable
local net_ReadTable = net.ReadTable
local table_Merge = table.Merge
local IsEntity = IsEntity

TOOL.Category = "Constraints"
TOOL.Name = "#Tool.re_constraint.listname"
AddCSLuaFile( "weapons/gmod_tool/stools/re_constraint/ui.lua" )
AddCSLuaFile( "weapons/gmod_tool/stools/re_constraint/DPropertiesEdit.lua" )
AddCSLuaFile( "weapons/gmod_tool/stools/re_constraint/vector.lua" )
AddCSLuaFile( "weapons/gmod_tool/stools/re_constraint/float.lua" )

if CLIENT then
	language_Add( "Tool.re_constraint.listname", "Re-Constraint" )
	language_Add( "Tool.re_constraint.name", "Re-Constraint" )
	language_Add( "Tool.re_constraint.desc", "Allows you to view/edit constraints." )
	language_Add( "Tool.re_constraint.0", "Click on a prop to view/edit constraints." )
	Re_Constraint_Data = {}
else
	util_AddNetworkString( "re_constraint_data" )
end

local function CopyOnlyConstraints( Ent )
	local Constraints = {}
	local ConTable = constraint_GetTable( Ent )
	local ConstraintTables = {}

	for key, constr in pairs( ConTable ) do
		local index = constr.Constraint:GetCreationID()
		Constraints[index] = constr
	end

	for k, v in pairs( Constraints ) do
		ConstraintTables[k] = v
	end

	return ConstraintTables
end

local function reconstraintTypes( Tab, str, ply )
	net_Start( str )
	net_WriteString( "Types" )
	net_WriteUInt( table_Count( Tab ), 16 )
	for i, k in pairs( Tab ) do
		local s = k.Type .. "|" .. tostring( i )
		net_WriteString( s )
	end
	net_Send( ply )
end

function TOOL:LeftClick( trace )
	if IsValid( trace.Entity ) and trace.Entity:IsPlayer() then return end
	if SERVER and not util_IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end
	local Ent = trace.Entity
	self:SetObject( 1, Ent, trace.HitPos, Phys, trace.PhysicsBone, trace.HitNormal )
	if CLIENT then return true end
	local ply = self:GetOwner()
	local Table = CopyOnlyConstraints( Ent )

	if Table then
		reconstraintTypes( Table, "re_constraint_data", ply )
		return true
	end
end

function TOOL.BuildCPanel( CPanel )
	include( "weapons/gmod_tool/stools/re_constraint/ui.lua" )
	local function reloadui()
		include( "weapons/gmod_tool/stools/re_constraint/ui.lua" )
	end
	concommand_Add( "re_constraint_reloadui", reloadui )
end

function TOOL:Holster()
	self:ClearObjects()
	self:SetStage( 0 )
end

function TOOL:DrawHUD()
	if not CLIENT then return end

	local Ents = Re_Constraint_Data.Ents
	local Pos = Re_Constraint_Data.Pos

	if Pos and Ents and IsValid( Ents[1] ) and IsValid( Ents[2] ) then
		local P1 = Ents[1]:GetPos():ToScreen()
		local P2 = Ents[2]:GetPos():ToScreen()
		if isvector( Pos[1] ) and isvector( Pos[2] ) then
			P1 = Ents[1]:LocalToWorld( Pos[1] ):ToScreen()
			P2 = Ents[2]:LocalToWorld( Pos[2] ):ToScreen()
		end
		surface_SetDrawColor( 255, 33, 33, 255 )
		surface_DrawLine( P1.x, P1.y, P2.x , P2.y )
		surface_DrawCircle( P1.x, P1.y, 11, 33, 33, 255, 255 )
		surface_DrawCircle( P2.x, P2.y, 11, 33, 33, 255, 255 )
		local p3 = Ents[1]:GetPos():ToScreen()
		local p4 = Ents[2]:GetPos():ToScreen()
		surface_SetDrawColor( 33, 255, 33, 255 )
		surface_DrawOutlinedRect( p3.x - 20 , p3.y - 20 , 40, 40 )
		surface_DrawOutlinedRect( p4.x - 20 , p4.y - 20 , 40, 40 )
	end
end

local function reconstraintProperties( Factory, Con, ply, str )
	net_Start( str )
	net_WriteString( "properties" )
	local Table = {}

	for i, k in pairs( Factory.Args ) do
		local Var = Con[k]
		Table[k] = Var
	end

	net_WriteTable( Table )
	net_Send( ply )
end

function TOOL:Deploy()
	net_Receive( "re_constraint_data", function( ln, ply )
		local Action = net_ReadString()
		if not Action then return end

		if Action == "Ask" then
			self:SetStage( net_ReadUInt( 32 ) )
			local Con = CopyOnlyConstraints( self:GetEnt( 1 ) )[self:GetStage()]
			if not istable( Con ) then return end

			local Factory = duplicator.ConstraintType[ Con.Type ]
			reconstraintProperties( Factory, Con, ply, "re_constraint_data" )
		end

		if Action == "ReplaceCon" then
			local Table = net_ReadTable()
			local Con = CopyOnlyConstraints( self:GetEnt( 1 ) )[self:GetStage()]
			if not istable( Con ) or not istable( Table ) then return end

			local New = table_Merge( Con, Table )
			local AllCon = New["Ent1"].Constraints
			if not istable( AllCon ) then return end

			for I, V in pairs( AllCon ) do
				if IsEntity( V ) and IsValid( V ) then
					local id = V:GetCreationID()
					if id == self:GetStage() then
						local T = V:GetTable()
						table_Merge( T, Table )

						return
					end
				end
			end
		end

		if Action == "DeleteCon" then
			local Con = CopyOnlyConstraints( self:GetEnt( 1 ) )[self:GetStage()]
			if not istable( Con ) then return end

			local AllCon = Con["Ent1"].Constraints
			for I, V in pairs( AllCon ) do
				if IsEntity( V ) and IsValid( V ) then
					local id = V:GetCreationID()
					if id == self:GetStage() then
						V:Remove()

						return
					end
				end
			end
		end
	end )
end