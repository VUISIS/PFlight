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
    var count: int;
    var depleteBattery: bool;
	start state Init 
	{   defer eRespBatteryRemaining;
		entry (fc: machine)
        {
            depleteBattery = true;
            count = 0;
			flightcontroller = fc;
		}
		on eLinkInitialized goto MonitorBattery;
	}

	state MonitorBattery
    {
		on eRespBatteryRemaining do (remaining: float)
		{
            if(remaining < 0.1 || count > 125)
            {
                send flightcontroller, eBatteryRemaining, CRITICAL;
            }
            else
            {
                send flightcontroller, eBatteryRemaining, NORMAL;
            }
            if(depleteBattery)
            {
                count = count + 1;
            }
		}
	}
}