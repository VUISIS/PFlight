event eLinkInitialized;
event eTakeoffReached;

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
            announce eMavSDKResp, 3;
        }
        on eReqMissionUpload do
        {
            var success: bool;
            success = UploadMission();
            send mMonitor, eRespMissionUpload, success;
            announce eMavSDKResp, 1;
        }
        on eReqMissionFinished do
		{
            var status: bool;
            status = MissionFinished();
            send controller, eRespMissionFinished, status;
            announce eMavSDKResp, 10;
		}
        on eReqArm do
        {
            var armed: bool;
            armed = ArmSystem();
            send controller, eRespArm, armed;
            announce eMavSDKResp, 4;
        }
        on eReqTakeoff do (alt: float)
        {
            var takeoff: bool;
            takeoff = TakeoffSystem(alt);
/******************* Liveness Spec Failure  ***********/
            //UnReliableSend(controller, eRespTakeoff, takeoff, eMavSDKResp, 5);
            send controller, eRespTakeoff, takeoff;
            announce eMavSDKResp, 5;
        }
        on eReqSystemStatus do
        {
            var status: bool;
            status = SystemStatus();
            send sMonitor, eRespSystemStatus, status;
            announce eMavSDKResp, 2;
        }
        on eReqBatteryRemaining do
        {
            var status: float;
            status = BatteryRemaining();
            send bMonitor, eRespBatteryRemaining, status;
            announce eMavSDKResp, 0;
        }
        on eReqHold do 
        {
            var status: bool;
            status = Holding();
            send controller, eRespHold, status;
            announce eMavSDKResp, 8;
        }
        on eReqReturnToLaunch do 
        {
            var status: bool;
            status = RTL();
            send controller, eRespReturnToLaunch, status;
            announce eMavSDKResp, 15;
        }
        on eReqMissionStart do
        {
            var status: bool;
            status = StartMission();
            send mMonitor, eRespMissionStart, status;
            announce eMavSDKResp, 9;
        }
        on eReqClearMission do
        {
            var status: bool;
            status = ClearMission();
            send mMonitor, eRespClearMission, status;
            announce eMavSDKResp, 14;
        }
        on eReqInAirStatus do
        {
            var status: bool;
            status = InAirStatus();
            send tMonitor, eRespInAirStatus, status;
            announce eMavSDKResp, 7;
        }
        on eReqAtTakeoffAlt do
        {
            var status: bool;
            status = IsAtTakeoffAlt();
            send controller, eRespAtTakeoffAlt, status;
            announce eMavSDKResp, 6;
        }
        on eReqWaitForDisarmed do
        {
            var status: bool;
            status = WaitForDisarmed();
            send controller, eRespWaitForDisarmed, status;
            announce eMavSDKResp, 16;
        }
        on eReqLand do
        {
            var status: bool;
            status = LandSystem();
            send controller, eRespLand, status;
            announce eMavSDKResp, 11;
        }
        on eReqLandingState do
        {
            var status: int;
            status = LandingState();
            send controller, eRespLandingState, status;
            announce eMavSDKResp, 12;
        }
        on eReqDisarm do
        {
            var status: bool;
            status = DisarmSystem();
            send controller, eRespDisarm, status;
            announce eMavSDKResp, 13;
        }
    }
}