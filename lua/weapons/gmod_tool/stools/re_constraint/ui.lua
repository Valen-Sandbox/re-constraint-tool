local controlpanel_Get = CLIENT and controlpanel.Get
local include = include
local vgui_Create = CLIENT and vgui.Create
local net_Start = net.Start
local net_WriteString = net.WriteString
local net_WriteTable = net.WriteTable
local net_SendToServer = CLIENT and net.SendToServer
local LocalPlayer = LocalPlayer
local vgui_Register = CLIENT and vgui.Register
local net_WriteUInt = net.WriteUInt
local tonumber = tonumber
local net_Receive = net.Receive
local net_ReadString = net.ReadString
local net_ReadUInt = net.ReadUInt
local string_Explode = string.Explode
local net_ReadTable = net.ReadTable
local table_GetKeys = table.GetKeys
local table_sort = table.sort
local isnumber = isnumber
local tostring = tostring
local table_Count = table.Count
local type = type
local Vector = Vector
local tobool = tobool

local CPanel = controlpanel_Get( "re_constraint" )
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
	local dtree = vgui_Create( "DTree", self )
	dtree:Dock( FILL )
	Access.dtree = dtree
end

function Dtree:PerformLayout()
	self:SetSize( 270, 250 )
end

function Dtree:Paint( w, h )
end

function Dlabel:Init()
	Dlabel = vgui_Create( "DLabel", self )
	Dlabel:Dock( FILL )
	Dlabel:SetText( "Redupe contraption to take effect" )
	local Skin = self:GetSkin()
	Dlabel:SetTextColor( Skin.Colours.Label.Dark )
end

function Dlabel:PerformLayout()
	self:SetSize( 270, 22 )
end

function Dlabel:Paint( w, h )
end

function Properties:Init()
	Properties = vgui_Create( "DPropertiesEdit", self )
	Properties:Dock( FILL )
	Access.Properties = Properties
end

function Properties:PerformLayout()
	self:SetSize( 270, 500 )
end

function Properties:Paint( w, h )
end

function Dbutton:Init()
	Dbutton = vgui_Create( "DButton", self )
	Dbutton:Dock( FILL )
	Access.Dbutton = Dbutton
	Dbutton:SetText( "Apply" )

	Dbutton.DoClick = function()
		net_Start( "re_constraint_data" )
			net_WriteString( "ReplaceCon" )
			net_WriteTable( PropTable )
		net_SendToServer()
		LocalPlayer():EmitSound( "buttons/button15.wav", 100, 100 )
	end
end

function Dbutton:PerformLayout()
	self:SetSize( 55, 22 )
end

function Dbutton:Paint( w, h )
end

function Dbutton1:Init()
	Dbutton1 =  vgui_Create( "DButton", self )
	Dbutton1:Dock( FILL )
	Access.Dbutton1 = Dbutton1
	Dbutton1:SetText( "Delete" )

	Dbutton1.DoClick = function()
		net_Start( "re_constraint_data" )
			net_WriteString( "DeleteCon" )
			Access.Properties:Clear()
			DtreeNodes[Cur1].Nodes[Cur2]:Remove()
		net_SendToServer()
		LocalPlayer():EmitSound( "buttons/button15.wav", 100, 100 )
	end
end

function Dbutton1:PerformLayout()
	self:SetSize( 55, 22 )
end

function Dbutton1:Paint( w, h )
end

CPanel:Clear()
vgui_Register( "re_constraint_dlabel", Dlabel, "DPanel" )
vgui_Register( "re_constraint_dtree", Dtree, "DPanel" )
vgui_Register( "re_constraint_properties", Properties, "DPanel" )
vgui_Register( "re_constraint_button", Dbutton, "DPanel" )
vgui_Register( "re_constraint_button1", Dbutton1, "DPanel" )

CPanel:AddItem( vgui_Create( "re_constraint_dlabel" ) )
CPanel:AddItem( vgui_Create( "re_constraint_dtree" ) )
CPanel:AddItem( vgui_Create( "re_constraint_button" ) )
CPanel:AddItem( vgui_Create( "re_constraint_button1" ) )
CPanel:AddItem( vgui_Create( "re_constraint_properties" ) )

local function reconstraintAsk( nm, str )
	net_Start( str )
	net_WriteString( "Ask" )
	net_WriteUInt( tonumber( nm ), 32 )
	net_SendToServer()
end

net_Receive( "re_constraint_data", function()
	local Action = net_ReadString()
	if not Action then return end
	if Action == "Types" then
		local Count = net_ReadUInt( 16 )
		Access.dtree:Clear()
		DtreeNodes = {}
		for i = 1, Count do
			local Points = string_Explode( "|" , net_ReadString() )
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
		PropTable = net_ReadTable()
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
				Row.DataChanged = function( self, data )
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