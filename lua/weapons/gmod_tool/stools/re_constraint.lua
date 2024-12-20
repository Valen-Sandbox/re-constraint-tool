local pairs = pairs
local table_Count = table.Count
local IsValid = IsValid
local table_Merge = table.Merge

TOOL.Category = "Constraints"
TOOL.Name = "#Tool.re_constraint.listname"
TOOL.Information = {
	{ name = "left" },
}

AddCSLuaFile( "weapons/gmod_tool/stools/re_constraint/ui.lua" )
AddCSLuaFile( "weapons/gmod_tool/stools/re_constraint/DPropertiesEdit.lua" )
AddCSLuaFile( "weapons/gmod_tool/stools/re_constraint/vector.lua" )
AddCSLuaFile( "weapons/gmod_tool/stools/re_constraint/float.lua" )

if CLIENT then
	language.Add( "Tool.re_constraint.listname", "Re-Constraint" )
	language.Add( "Tool.re_constraint.name", "Re-Constraint" )
	language.Add( "Tool.re_constraint.desc", "Allows you to view/edit constraints" )
	language.Add( "Tool.re_constraint.left", "View/edit the constraints of a prop" )
	Re_Constraint_Data = {}
else
	util.AddNetworkString( "re_constraint_data" )
end

local function CopyOnlyConstraints( Ent )
	local Constraints = {}
	local ConTable = constraint.GetTable( Ent )
	local ConstraintTables = {}

	for _, constr in pairs( ConTable ) do
		local index = constr.Constraint:GetCreationID()
		Constraints[index] = constr
	end

	for k, v in pairs( Constraints ) do
		ConstraintTables[k] = v
	end

	return ConstraintTables
end

local function reconstraintTypes( Tab, str, ply )
	net.Start( str )
	net.WriteString( "Types" )
	net.WriteUInt( table_Count( Tab ), 16 )
	for i, k in pairs( Tab ) do
		local s = k.Type .. "|" .. tostring( i )
		net.WriteString( s )
	end
	net.Send( ply )
end

function TOOL:LeftClick( trace )
	if IsValid( trace.Entity ) and trace.Entity:IsPlayer() then return end
	if SERVER and not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end
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

function TOOL.BuildCPanel()
	include( "weapons/gmod_tool/stools/re_constraint/ui.lua" )
	local function reloadui()
		include( "weapons/gmod_tool/stools/re_constraint/ui.lua" )
	end
	concommand.Add( "re_constraint_reloadui", reloadui )
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
		surface.SetDrawColor( 255, 33, 33, 255 )
		surface.DrawLine( P1.x, P1.y, P2.x , P2.y )
		surface.DrawCircle( P1.x, P1.y, 11, 33, 33, 255, 255 )
		surface.DrawCircle( P2.x, P2.y, 11, 33, 33, 255, 255 )
		local p3 = Ents[1]:GetPos():ToScreen()
		local p4 = Ents[2]:GetPos():ToScreen()
		surface.SetDrawColor( 33, 255, 33, 255 )
		surface.DrawOutlinedRect( p3.x - 20 , p3.y - 20 , 40, 40 )
		surface.DrawOutlinedRect( p4.x - 20 , p4.y - 20 , 40, 40 )
	end
end

if CLIENT then return end

local function reconstraintProperties( Factory, Con, ply, str )
	net.Start( str )
	net.WriteString( "properties" )
	local Table = {}

	for _, k in pairs( Factory.Args ) do
		local Var = Con[k]
		Table[k] = Var
	end

	net.WriteTable( Table )
	net.Send( ply )
end

function TOOL:Deploy()
	net.Receive( "re_constraint_data", function( _, ply )
		local Action = net.ReadString()
		if not Action then return end

		if Action == "Ask" then
			self:SetStage( net.ReadUInt( 32 ) )
			local Con = CopyOnlyConstraints( self:GetEnt( 1 ) )[self:GetStage()]
			if not istable( Con ) then return end

			local Factory = duplicator.ConstraintType[ Con.Type ]
			reconstraintProperties( Factory, Con, ply, "re_constraint_data" )
		end

		if Action == "ReplaceCon" then
			local Table = net.ReadTable()
			local Con = CopyOnlyConstraints( self:GetEnt( 1 ) )[self:GetStage()]
			if not istable( Con ) or not istable( Table ) then return end

			local New = table_Merge( Con, Table )
			local AllCon = New["Ent1"].Constraints
			if not istable( AllCon ) then return end

			for _, V in pairs( AllCon ) do
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
			for _, V in pairs( AllCon ) do
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