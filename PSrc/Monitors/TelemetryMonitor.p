event eTelemetryHealthAllOK: bool;
event eLandingStatus : tLandedState;
event eLand : bool;

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
		on eRespLandingStatus do (status: tLandedState)
		{
			send flightcontroller, eLandingStatus, status;
		}
		on eRespLand do (res: bool)
		{
			send flightcontroller, eLand, res;
		}
	}
}