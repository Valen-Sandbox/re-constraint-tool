--
-- prop_generic is the base for all other properties.
-- All the business should be done in :Setup using inline functions.
-- So when you derive from this class - you should ideally only override Setup.
--


DEFINE_BASECLASS( "DProperty_Generic" )

local PANEL = {}

function PANEL:Init()
end

--
-- Called by this control, or a derived control, to alert the row of the change
--
function PANEL:ValueChanged( newval, bForce )

	BaseClass.ValueChanged( self, newval, bForce )

	if ( isvector( self.VectorValue ) ) then
		self.VectorValue = Vector( newval )
	end

end

function PANEL:Setup( vars )

	vars = vars or {}

	BaseClass.Setup( self, vars )

	local __SetValue = self.SetValue




	-- Set the value
	self.SetValue = function( self, val )
		self.VectorValue = val

		if ( isvector( self.VectorValue ) ) then
			__SetValue( self, val )
		end
	end

end

derma.DefineControl( "DProperty_Vector", "", PANEL, "DProperty_Generic" )