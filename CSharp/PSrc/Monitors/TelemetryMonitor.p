event eTelemetryHealthAllOK: bool;
event eInAirStatus : bool;

machine TelemetryMonitor
{
	var flightcontroller: machine;
	start state Init 
	{
		defer eRespTelemetryHealth;
		entry (fc: machine)
        {
			flightcontroller = fc;
		}
		on eLinkInitialized goto MonitorTelemetry;
	}

	state MonitorTelemetry
    {
		on eRespTelemetryHealth do (health: bool)
		{
			send flightcontroller, eTelemetryHealthAllOK, health;
		}
		on eRespInAirStatus do (status: bool)
		{
			send flightcontroller, eInAirStatus, status;
		}
	}
}