local LocalPlayer = LocalPlayer
local string_Explode = string.Explode
local table_GetKeys = table.GetKeys
local table_sort = table.sort
local table_Count = table.Count

local CPanel = controlpanel.Get( "re_constraint" )
include( "weapons/gmod_tool/stools/re_constraint/DPropertiesEdit.lua" )
include( "weapons/gmod_tool/stools/re_constraint/vector.lua" )
include( "weapons/gmod_tool/stools/re_constraint/float.lua" )

local Access = {}
local Dtree = {}
local DtreeNodes = {}
local Dlabel = {}
local Properties = {}
local Dbutton = {}
local Dbutton1 = {}
local PropTable = {}
Re_Constraint_Data = {}
local Cur1 = 0
local Cur2 = 0

function Dtree:Init()
	local dtree = vgui.Create( "DTree", self )
	dtree:Dock( FILL )
	Access.dtree = dtree
	self:SetSize( 270, 250 )
end

function Dlabel:Init()
	Dlabel = vgui.Create( "DLabel", self )
	Dlabel:Dock( FILL )
	Dlabel:SetText( "Redupe contraption to take effect" )
	local Skin = self:GetSkin()
	Dlabel:SetTextColor( Skin.Colours.Label.Dark )
	self:SetSize( 270, 22 )
end

function Properties:Init()
	Properties = vgui.Create( "DPropertiesEdit", self )
	Properties:Dock( FILL )
	Access.Properties = Properties
	self:SetSize( 270, 500 )
end

function Dbutton:Init()
	Dbutton = vgui.Create( "DButton", self )
	Dbutton:Dock( FILL )
	Access.Dbutton = Dbutton
	Dbutton:SetText( "Apply" )

	Dbutton.DoClick = function()
		net.Start( "re_constraint_data" )
			net.WriteString( "ReplaceCon" )
			net.WriteTable( PropTable )
		net.SendToServer()
		LocalPlayer():EmitSound( "buttons/button15.wav", 100, 100 )
	end
end

function Dbutton1:Init()
	Dbutton1 = vgui.Create( "DButton", self )
	Dbutton1:Dock( FILL )
	Access.Dbutton1 = Dbutton1
	Dbutton1:SetText( "Delete" )

	Dbutton1.DoClick = function()
		net.Start( "re_constraint_data" )
			net.WriteString( "DeleteCon" )
			Access.Properties:Clear()

			local node = DtreeNodes[Cur1]
			local nodes = node.Nodes

			if nodes then
				if table_Count(nodes) == 1 then
					node:Remove()
				else
					nodes[Cur2]:Remove()
					nodes[Cur2] = nil
				end
			end
		net.SendToServer()
		LocalPlayer():EmitSound( "buttons/button15.wav", 100, 100 )
	end
end

CPanel:Clear()
vgui.Register( "re_constraint_dlabel", Dlabel, "DPanel" )
vgui.Register( "re_constraint_dtree", Dtree, "DPanel" )
vgui.Register( "re_constraint_properties", Properties, "DPanel" )
vgui.Register( "re_constraint_button", Dbutton, "DPanel" )
vgui.Register( "re_constraint_button1", Dbutton1, "DPanel" )

CPanel:AddItem( vgui.Create( "re_constraint_dlabel" ) )
CPanel:AddItem( vgui.Create( "re_constraint_dtree" ) )
CPanel:AddItem( vgui.Create( "re_constraint_button" ) )
CPanel:AddItem( vgui.Create( "re_constraint_button1" ) )
CPanel:AddItem( vgui.Create( "re_constraint_properties" ) )

local function reconstraintAsk( nm, str )
	net.Start( str )
	net.WriteString( "Ask" )
	net.WriteUInt( tonumber( nm ), 32 )
	net.SendToServer()
end

net.Receive( "re_constraint_data", function()
	local Action = net.ReadString()
	if not Action then return end
	if Action == "Types" then
		local Count = net.ReadUInt( 16 )
		Access.dtree:Clear()
		DtreeNodes = {}
		for _ = 1, Count do
			local Points = string_Explode( "|" , net.ReadString() )
			if Points[1] and Points[2] then
				if not DtreeNodes[Points[1]] then
					DtreeNodes[Points[1]] = Access.dtree:AddNode( Points[1] )
					DtreeNodes[Points[1]].Nodes = {}
				end
				local temp = DtreeNodes[Points[1]]:AddNode( Points[2], "icon16/page.png" )
				DtreeNodes[Points[1]].Nodes[Points[2]] = temp
				function temp:DoClick()
					Cur1 = Points[1]
					Cur2 = Points[2]
					reconstraintAsk( Points[2], "re_constraint_data" )
				end
			end
		end
	end

	if Action == "properties" then
		Re_Constraint_Data = {}
		PropTable = net.ReadTable()
		Re_Constraint_Data.Ents = { PropTable["Ent1"], PropTable["Ent2"], PropTable["Ent4"] }
		Re_Constraint_Data.Pos = { PropTable["LPos1"], PropTable["LPos2"], PropTable["LPos4"], PropTable["WPos2"], PropTable["WPos3"] }

		local Keys = table_GetKeys( PropTable )

		table_sort( Keys, function( a, b )
			if isnumber( a ) and isnumber( b ) then return a < b end
			return tostring( a ) < tostring( b )
		end )

		Access.Properties:Clear()
		for i = 1, table_Count( PropTable ) do
			local k = Keys[i]
			local v = PropTable[k]
			if k ~= "Ent1" and k ~= "Ent2" and k ~= "Ent3" and k ~= "Ent4" then
				local Row = Access.Properties:CreateRow( "Constraint Properties", tostring( k ) )
				local Type = type(v)
				Row.Type = Type
				Row.k = k
				if Type == "number" then Type = "Generic" end
				if Type == "boolean" then Type = "Boolean" end
				if Type == "string" then Type = "Generic" end
				if Type == "Entity" then Type = "Generic" end
				if Type == "Player" then Type = "Generic" end
				Row:Setup( Type )
				Row:SetValue( v )
				Row.DataChanged = function( _, data )
					local T = Row.Type
					local Data = nil
					if T == "number" then Data = tonumber(data) end
					if T == "Vector" then Data = Vector(data) end
					if T == "boolean" then Data = tobool(data) end
					if T == "string" then Data = tostring(data) end
					if Data ~= nil then
						PropTable[Row.k] = Data
					end
				end
			end
		end
	end
end )