event eSystemConnected : bool;

machine SystemMonitor
{
	var flightcontroller: machine;
	start state Init 
	{
		defer eRespSystemStatus;
		entry (fc: machine)
        {
			flightcontroller = fc;
		}
		on eLinkInitialized goto MonitorSystem;
	}

	state MonitorSystem
    {
		on eRespSystemStatus do (connected: bool)
		{
			send flightcontroller, eSystemConnected, connected;
		}
	}
}