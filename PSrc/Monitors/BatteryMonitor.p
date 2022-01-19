enum tBatteryState
{
    CRITICAL,
    WARNING,
    LOW,
    NORMAL
}

event eBatteryRemaining : tBatteryState;

machine BatteryMonitor
{
	var flightcontroller: machine;
	start state Init 
	{   defer eRespBatteryRemaining;
		entry (fc: machine)
        {
			flightcontroller = fc;
		}
		on eLinkInitialized goto MonitorBattery;
	}

	state MonitorBattery
    {
		on eRespBatteryRemaining do (remaining: float)
		{
            if(remaining < 0.1)
            {
                send flightcontroller, eBatteryRemaining, CRITICAL;
            }
            else
            {
                send flightcontroller, eBatteryRemaining, NORMAL;
            }
		}
	}
}