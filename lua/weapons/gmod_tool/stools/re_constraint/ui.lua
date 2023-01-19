local CPanel = controlpanel.Get( "re_constraint" )
include( "weapons/gmod_tool/stools/re_constraint/DPropertiesEdit.lua" )
include( "weapons/gmod_tool/stools/re_constraint/vector.lua" )
include( "weapons/gmod_tool/stools/re_constraint/float.lua" )
local Access = {}
local Dtree = {}
local Dlabel = {}
local Properties = {}
local Dbutton = {}
local Dbutton1 = {}
local PropTable = {}
Re_Constraint_Data = {}
function Dtree:Init()

local dtree = vgui.Create( "DTree", self )
dtree:Dock( FILL )
Access.dtree = dtree
end

function Dtree:PerformLayout()
	self:SetSize(270, 250)
end

function Dtree:Paint(w,h)
end

function Dlabel:Init()

local Dlabel = vgui.Create( "DLabel", self )
Dlabel:Dock( FILL )
Dlabel:SetText( "ReDupe contraption to take effect" )
Dlabel:SetTextColor( Color( 15, 15, 15, 255 ) )
end

function Dlabel:PerformLayout()
	self:SetSize(270, 22)
end

function Dlabel:Paint(w,h)
end

function Properties:Init()

local Properties =  vgui.Create( "DPropertiesEdit", self )
Properties:Dock( FILL )
Access.Properties = Properties

end

function Properties:PerformLayout()
	self:SetSize(270, 500)
end

function Properties:Paint(w,h)
end


function Dbutton:Init()

local Dbutton =  vgui.Create( "DButton", self )
Dbutton:Dock( FILL )
Access.Dbutton = Dbutton
Dbutton:SetText( "Apply" )

Dbutton.DoClick = function()

	net.Start( "re_constraint_data" )
		net.WriteString( "ReplaceCon" )
		net.WriteTable( PropTable )
	net.SendToServer()
	LocalPlayer():EmitSound("buttons/button15.wav", 100, 100)
end
	
end

function Dbutton:PerformLayout()
	self:SetSize(55, 22)
end

function Dbutton:Paint(w,h)
end


function Dbutton1:Init()

local Dbutton1 =  vgui.Create( "DButton", self )
Dbutton1:Dock( FILL )
Access.Dbutton1 = Dbutton1
Dbutton1:SetText( "Delete" )

Dbutton1.DoClick = function()

	net.Start( "re_constraint_data" )
		net.WriteString( "DeleteCon" )
		Access.Properties:Clear()
		DtreeNodes[Cur1].Nodes[Cur2]:Remove()
	net.SendToServer()
	LocalPlayer():EmitSound("buttons/button15.wav", 100, 100)
end
	
end

function Dbutton1:PerformLayout()
	self:SetSize(55, 22)
end

function Dbutton1:Paint(w,h)
end

Cur1 = 0
Cur2 = 0

CPanel:Clear()
vgui.Register("re_constraint_dlabel", Dlabel, "DPanel")
vgui.Register("re_constraint_dtree", Dtree, "DPanel")
vgui.Register("re_constraint_properties", Properties, "DPanel")
vgui.Register("re_constraint_button", Dbutton, "DPanel")
vgui.Register("re_constraint_button1", Dbutton1, "DPanel")
DtreeNodes = {}
CPanel:AddItem( vgui.Create( "re_constraint_dlabel" ) )
CPanel:AddItem( vgui.Create( "re_constraint_dtree" ) )
CPanel:AddItem( vgui.Create( "re_constraint_button" ) )
CPanel:AddItem( vgui.Create( "re_constraint_button1" ) )
CPanel:AddItem( vgui.Create( "re_constraint_properties" ) )
net.Receive( "re_constraint_data" , function() 
local Action = net.ReadString()
	if(!Action) then return end
	if(Action == "Types") then
		local Count = net.ReadUInt( 16 )
		Access.dtree:Clear()
		DtreeNodes = {}
		for i = 1 , Count do
			local Points = string.Explode( "|" , net.ReadString() )
			if(Points[1]&&Points[2])then
			if(!DtreeNodes[Points[1]]) then
				DtreeNodes[Points[1]] = Access.dtree:AddNode( Points[1] )
				DtreeNodes[Points[1]].Nodes = {}
			end
			local temp = DtreeNodes[Points[1]]:AddNode( Points[2] , "icon16/page.png" )
			DtreeNodes[Points[1]].Nodes[Points[2]] = temp
			function temp:DoClick()
				Cur1 = Points[1]
				Cur2 = Points[2]
				reconstraintAsk( Points[2] , "re_constraint_data" ) 
			end
			end
		end
	end
	
	if(Action == "properties") then
		Re_Constraint_Data = {}
		PropTable = net.ReadTable()
		Re_Constraint_Data.Ents = { PropTable["Ent1"] , PropTable["Ent2"] , PropTable["Ent4"] }
		Re_Constraint_Data.Pos = { PropTable["LPos1"] , PropTable["LPos2"] , PropTable["LPos4"] , PropTable["WPos2"] , PropTable["WPos3"] }

		local Keys = table.GetKeys( PropTable )
		
		table.sort( Keys, function( a, b )
		if ( isnumber( a ) && isnumber( b ) ) then return a < b end
			return tostring( a ) < tostring( b )
		end )
		
		Access.Properties:Clear()
		for i=1,table.Count(PropTable) do 
			k = Keys[i]
			v = PropTable[k]
			if (k != "Ent1" && k != "Ent2" && k != "Ent3" && k != "Ent4" )then 
			local Row = Access.Properties:CreateRow( "Constraint Properties", tostring(k) )
			local Type = type(v)
			Row.Type = Type
			Row.k = k
			if (Type == "number") then Type = "Generic" end
			if (Type == "boolean") then Type = "Boolean" end
			if (Type == "string") then Type = "Generic" end
			if (Type == "Entity") then Type = "Generic" end
			if (Type == "Player") then Type = "Generic" end
			Row:Setup( Type )
			Row:SetValue( v ) 
			Row.DataChanged = function( self, data )
			local T = Row.Type
			local Data = nil
			if (T == "number") then Data = tonumber(data) end
			if (T == "Vector") then Data = Vector(data) end
			if (T == "boolean") then Data = tobool(data) end
			if (T == "string") then Data = tostring(data) end
			if Data!=nil then
			PropTable[Row.k] = Data
			end
			end
			end
		end
	
	end
	
end)

