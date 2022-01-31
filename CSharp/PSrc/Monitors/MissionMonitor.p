event eMissionUploaded : bool;
event eMissionStarted: bool;
event eMissionCleared : bool;

machine MissionMonitor
{
	var flightcontroller: machine;
	start state Init 
	{
		entry (fc: machine)
        {
			flightcontroller = fc;
		}
		on eLinkInitialized goto MonitorMission;
	}

	state MonitorMission
    {
        on eRespMissionUpload do (uploaded: bool)
        {
            send flightcontroller, eMissionUploaded, uploaded;
        }
        on eRespMissionStart do (status: bool)
        {
            send flightcontroller, eMissionStarted, status;
        }
		on eRespClearMission do (cleared: bool)
        {
            send flightcontroller, eMissionCleared, cleared;
        }
	}
}