local BaseClass = BaseClass
local isvector = isvector
local Vector = Vector
local derma_DefineControl = CLIENT and derma.DefineControl

--[[
	prop_generic is the base for all other properties.
	All the business should be done in :Setup using inline functions.
	So when you derive from this class - you should ideally only override Setup.
]]

DEFINE_BASECLASS( "DProperty_Generic" )

local PANEL = {}

function PANEL:Init()
end

-- Called by this control, or a derived control, to alert the row of the change
function PANEL:ValueChanged( newval, bForce )
	BaseClass.ValueChanged( self, newval, bForce )

	if not isvector( self.VectorValue ) then return end
	self.VectorValue = Vector( newval )
end

function PANEL:Setup( vars )
	vars = vars or {}
	BaseClass.Setup( self, vars )
	local __SetValue = self.SetValue

	-- Set the value
	self.SetValue = function( pnl, val )
		pnl.VectorValue = val

		if isvector( pnl.VectorValue ) then
			__SetValue( pnl, val )
		end
	end
end

derma_DefineControl( "DProperty_Vector", "", PANEL, "DProperty_Generic" )