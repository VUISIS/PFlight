event eLinkInitialized;
event eRetryConnection;

machine MavSDK
{
    var timer: Timer;
    var ticks: int;
    var maxTicks: int;
    var controller: machine;
    var monitors: map[string,machine];
    var startMission: bool;
    var retries: int;
    var maxRetries: int;
    start state Init 
    {
        defer eAlwaysSendHeartbeat, eReqMissionUpload;
        entry(cntl: machine)
        {    
            maxRetries = 30;
            maxTicks = 50;
            startMission = false;
            timer = CreateTimer(this);
            controller = cntl;
        
            if(CoreSetupMavSDK())
            {   
                monitors += ("Telemetry", new TelemetryMonitor(controller));
                monitors += ("System", new SystemMonitor(controller));
                monitors += ("Battery", new BatteryMonitor(controller));
                monitors += ("Mission", new MissionMonitor(controller));

                send monitors["Telemetry"], eLinkInitialized;
                send monitors["System"], eLinkInitialized;
                send monitors["Battery"], eLinkInitialized;
                send monitors["Mission"], eLinkInitialized;
                send controller, eLinkInitialized;
                goto WaitForReq;
            }
        }
    }

    state WaitForReq
    {
        entry
        {
            StartTimer(timer);
        }
        on eTimeOut do
        {
            if(ticks > maxTicks)
            {
                send this, eReqBatteryRemaining;
                send this, eReqSystemStatus;
                send this, eReqTelemetryHealth;
                send this, eReqLandingStatus;

                if(startMission)
                {
                    send this, eReqMissionFinished;
                }
                ticks = 0;
            }

            ticks = ticks + 1;
            
            goto WaitForReq;
        }
        on eShutdown do
        {
            SetMissionFlag(false);
            CancelTimer(timer);
            send timer, halt;
        }
        on eReqTelemetryHealth do
        {
            var success: bool;
            success = GetTelemetryHealthAllOk();
            
            send monitors["Telemetry"], eRespTelemetryHealth, success;
        }
        on eAlwaysSendHeartbeat do
        {
            AlwaysSendHeartbeat();
        }
        on eReqMissionUpload do
        {
            var success: bool;
            SetMissionFlag(false);
            success = UploadMission();
            
            send monitors["Mission"], eRespMissionUpload, success;
        }
        on eReqMissionFinished do
		{
            var prog: bool;
            SetMissionFlag(true);
            prog = GetMissionFinished();
            
            send monitors["Mission"], eRespMissionFinished, prog;
		}
        on eReqArm do
        {
            var armed: bool;
            SetMissionFlag(false);
            armed = ArmSystem();
            
            send controller, eRespArm, armed;
        }
        on eReqTakeoff do (alt: float)
        {
            var takeoff: bool;
            SetMissionFlag(false);
            takeoff = TakeoffSystem(alt);
            
            send controller, eRespTakeoff, takeoff;
        }
        on eReqSystemStatus do
        {
            var status: bool;
            status = GetSystemStatus();
            
            send monitors["System"], eRespSystemStatus, status;
        }
        on eReqBatteryRemaining do
        {
            var status: float;
            status = GetBatteryRemaining();
            
            send monitors["Battery"], eRespBatteryRemaining, status;
        }
        on eReqHold do 
        {
            var status: bool;
            SetMissionFlag(false);
            status = GetHolding();
            
            send controller, eRespHold, status;
        }
        on eReqDisarm do 
        {
            var status: bool;
            SetMissionFlag(false);
            status = GetDisarmed();
            
            send controller, eRespDisarm, status;
        }
        on eReqReturnToLaunch do 
        {
            var status: bool;
            SetMissionFlag(false);
            status = GetReturnToLaunch();
            
            send controller, eRespReturnToLaunch, status;
        }
        on eReqMissionStart do
        {
            var status: bool;
            status = StartMission();
            if(status)
            {
                SetMissionFlag(true);
            }
            
            send monitors["Mission"], eRespMissionStart, status;
        }
        on eReqLand do
        {
            var status: bool;
            SetMissionFlag(false);
            status = LandSystem();
            
            send monitors["Telemetry"], eRespLand, status;
        }
        on eReqClearMission do
        {
            var status: bool;
            SetMissionFlag(false);
            status = ClearMission();
            
            send monitors["Mission"], eRespClearMission, status;
        }
        on eReqLandingStatus do
        {
            var status: tLandedState;
            status = LandingStatus();
            
            send monitors["Telemetry"], eRespLandingStatus, status;
        }
    }

    fun SetMissionFlag(flag: bool)
    {
        startMission = flag;
    }
}