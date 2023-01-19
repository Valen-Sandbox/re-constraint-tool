function reconstraintAsk( nm , str ) 
	net.Start( str )
	net.WriteString( "Ask" )
	net.WriteUInt( tonumber( nm ) , 32 )
	net.SendToServer()
end