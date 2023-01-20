local tonumber = tonumber
local derma_DefineControl = CLIENT and derma.DefineControl

--[[
	prop_generic is the base for all other properties.
	All the business should be done in :Setup using inline functions.
	So when you derive from this class - you should ideally only override Setup.
]]

local PANEL = {}

function PANEL:Init()
end

function PANEL:Setup( vars )
	self:Clear()
	vars = vars or {}

	self.Entry = self:Add( "DTextEntry" )
	self.Entry:SetPaintBackground( false )
	self.Entry:SetNumeric(true)

	self.Paint = function()
	end
end

function PANEL:SetValue( val )
	self.Entry:SetValue( tonumber( val ) )
end

function PANEL:IsEditing()
	return self.Entry:IsEditing()
end

derma_DefineControl( "DProperty_FloatNoSlider", "", PANEL, "DProperty_Generic" )