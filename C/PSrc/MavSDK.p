event eLinkInitialized;

machine MavSDK
{
    var controller: machine;
    var tMonitor: machine;
    var sMonitor: machine;
    var bMonitor: machine;
    var mMonitor: machine;
    start state Init 
    {
        defer eReqMissionUpload;
        ignore eRaiseError;
        entry(cntl: machine)
        {    
            controller = cntl;
            if(CoreSetupMavSDK())
            {   
                tMonitor = new TelemetryMonitor(controller);
                sMonitor = new SystemMonitor(controller);
                bMonitor = new BatteryMonitor(controller);
                mMonitor = new MissionMonitor(controller);

                send tMonitor, eLinkInitialized;
                send sMonitor, eLinkInitialized;
                send bMonitor, eLinkInitialized;
                send mMonitor, eLinkInitialized;
                send controller, eLinkInitialized;
                goto WaitForReq;
            }
            else
            {
                send controller, eRaiseError;
            }
        }
    }

    state WaitForReq
    {
        on eReqTelemetryHealth do
        {
            var status: bool;
            status = TelemetryHealthAllOk();
            send tMonitor, eRespTelemetryHealth, status;
        }
        on eReqMissionUpload do
        {
            var success: bool;
            success = UploadMission();
            
            send mMonitor, eRespMissionUpload, success;
        }
        on eReqMissionFinished do
		{
            var status: bool;
            status = MissionFinished();
            send controller, eRespMissionFinished, status;
		}
        on eReqArm do
        {
            var armed: bool;
            armed = ArmSystem();
            
            send controller, eRespArm, armed;
        }
        on eReqTakeoff do
        {
            var takeoff: bool;
            takeoff = TakeoffSystem();
            
            send controller, eRespTakeoff, takeoff;
        }
        on eReqSystemStatus do
        {
            var status: bool;
            status = SystemStatus();
            
            send sMonitor, eRespSystemStatus, status;
        }
        on eReqBatteryRemaining do
        {
            var status: float;
            status = BatteryRemaining();
            
            send bMonitor, eRespBatteryRemaining, status;
        }
        on eReqHold do 
        {
            var status: bool;
            status = Holding();
            
            send controller, eRespHold, status;
        }
        on eReqReturnToLaunch do 
        {
            var status: bool;
            status = RTL();
            
            send controller, eRespReturnToLaunch, status;
        }
        on eReqMissionStart do
        {
            var status: bool;
            status = StartMission();
            
            send mMonitor, eRespMissionStart, status;
        }
        on eReqClearMission do
        {
            var status: bool;
            status = ClearMission();
            
            send mMonitor, eRespClearMission, status;
        }
        on eReqInAirStatus do
        {
            var status: bool;
            status = InAirStatus();
            
            send tMonitor, eRespInAirStatus, status;
        }
        on eReqAtTakeoffAlt do
        {
            var status: bool;
            status = IsAtTakeoffAlt();
            send controller, eRespAtTakeoffAlt, status;
        }
        on eReqWaitForDisarmed do
        {
            var status: bool;
            status = WaitForDisarmed();
            send controller, eRespWaitForDisarmed, status;
        }
        on eReqLand do
        {
            var status: bool;
            status = LandSystem();
            send controller, eRespLand, status;
        }
        on eReqLandingState do
        {
            var status: int;
            status = LandingState();
            send controller, eRespLandingState, status;
        }
        on eReqDisarm do
        {
            var status: bool;
            status = DisarmSystem();
            send controller, eRespDisarm, status;
        }
    }
}