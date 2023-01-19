TOOL.Category = "Constraints"
TOOL.Name = "#Tool.re_constraint.listname"
AddCSLuaFile( "weapons/gmod_tool/stools/re_constraint/ui.lua" )
AddCSLuaFile( "weapons/gmod_tool/stools/re_constraint/DPropertiesEdit.lua" )
AddCSLuaFile( "weapons/gmod_tool/stools/re_constraint/vector.lua" )
AddCSLuaFile( "weapons/gmod_tool/stools/re_constraint/float.lua" )

if CLIENT then
	language.Add( "Tool.re_constraint.listname", "Re-Constraint" )
	language.Add( "Tool.re_constraint.name", "Re-Constraint" )
	language.Add( "Tool.re_constraint.desc", "Allows you to view/edit constraints." )
	language.Add( "Tool.re_constraint.0", "Click on a prop to view/edit constraints." )
	Re_Constraint_Data = {}
else
	util.AddNetworkString( "re_constraint_data" )
end

--local ConstraintStorage = {}

local function Parse( tab )
	local s = ""
	for i , k in pairs( tab ) do
	local t = type( k )
	if( t != "table" )then
	s = s..string.lower(string.sub( t , 0 , 1 ))
	end
	end
end

function TOOL:LeftClick( trace )
	if ( IsValid( trace.Entity ) && trace.Entity:IsPlayer() ) then return end
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end
	local Ent = trace.Entity
	self:SetObject( 1 , Ent, trace.HitPos, Phys, trace.PhysicsBone, trace.HitNormal )
	if CLIENT then return true end
	local ply = self:GetOwner()
	local Table = CopyOnlyConstraints( Ent )
	--PrintTable( trace.Entity:GetTable().Constraints )
	if(Table) then
	--ConstraintStorage[ply] = Table
	reconstraintTypes( Table , "re_constraint_data" , ply ) 
	return true
	end
end

function TOOL.BuildCPanel( CPanel )
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
local Ents = Re_Constraint_Data.Ents
local Pos = Re_Constraint_Data.Pos

if( Pos && Ents ) then

if( Ents[1]:IsValid() && Ents[2]:IsValid() ) then
local P1 = Ents[1]:GetPos():ToScreen()
local P2 = Ents[2]:GetPos():ToScreen()
if( isvector(Pos[1]) && isvector(Pos[2]) ) then
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

end

function TOOL:Deploy()
net.Receive( "re_constraint_data" , function(ln , ply) 
	Action = net.ReadString()
	if(!Action) then return end
	if(Action == "Ask") then
		self:SetStage( net.ReadUInt( 32 ) )
		local Con = CopyOnlyConstraints( self:GetEnt( 1 ) )[ self:GetStage() ]
		if(!istable(Con)) then return end
		local Factory = duplicator.ConstraintType[ Con.Type ]
		reconstraintProperties( Factory , Con , ply , "re_constraint_data" )
	end
	if(Action == "ReplaceCon") then
		local Table = net.ReadTable()
		local Con = CopyOnlyConstraints( self:GetEnt( 1 ) )[ self:GetStage() ]
		if(!istable(Con)||!istable(Table)) then return end
		local New = table.Merge( Con , Table )
		local AllCon = New["Ent1"].Constraints
		if !istable(AllCon) then return end
		for I , V in pairs(AllCon) do
			if IsEntity(V) && V:IsValid() then
				local id = V:GetCreationID()
				if(id == self:GetStage())then
					
					local T = V:GetTable()
					table.Merge( T , Table )

					//local Factory = duplicator.ConstraintType[V.Type]
					//PrintTable(Factory)
					//local Args = {}
					//for k, Key in pairs( Factory.Args ) do
					//table.insert( Args, V[ Key ] )
					//end
					
					//local E = Factory.Func( unpack(Args) )
					//table.Merge( V:GetTable() , E:GetTable() )
					return
				end
			end
		end
		
	end

	if(Action == "DeleteCon") then
		local Con = CopyOnlyConstraints( self:GetEnt( 1 ) )[ self:GetStage() ]
		if(!istable(Con)) then return end
		local AllCon = Con["Ent1"].Constraints
		for I , V in pairs(AllCon) do
			if IsEntity(V)  && V:IsValid()then
				local id = V:GetCreationID()
				if(id == self:GetStage())then
					V:Remove()

					return
				end
			end
		end
		
	end

	
end)
end