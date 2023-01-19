
function CopyOnlyConstraints( Ent )

	local Constraints = {}

	local ConTable = constraint.GetTable( Ent )
	local ConstraintTables = {}

	for key, constraint in pairs( ConTable ) do

		local index = constraint.Constraint:GetCreationID()
			Constraints[ index ] = constraint
		end

	
	for k, v in pairs( Constraints ) do
		ConstraintTables[ k ] = v
	end


	return ConstraintTables


end


function reconstraintTypes( Tab , str , ply ) 
	net.Start( str )
	net.WriteString( "Types" )
	net.WriteUInt( table.Count( Tab ) , 16 )
		for i , k in pairs( Tab ) do
		local s = k.Type.."|"..tostring(i)
		net.WriteString( s )
		end
	net.Send( ply )
end

function reconstraintProperties( Factory , Con , ply , str )
	net.Start( str )
	net.WriteString("properties")
	local Table = {}
	for i , k in pairs(Factory.Args) do
		local Var = Con[k]
		Table[k] = Var
	end
	net.WriteTable( Table )
	net.Send( ply )
end












