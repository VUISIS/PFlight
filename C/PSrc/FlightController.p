event eRaiseError;

event eReqArm;
event eReqTelemetryHealth;
event eReqSystemStatus;
event eReqTakeoff;
event eReqMissionUpload;
event eReqBatteryRemaining;
event eReqReturnToLaunch;
event eReqMissionStart;
event eReqClearMission;
event eReqInAirStatus;
event eReqMissionFinished;
event eReqWaitForDisarmed;
event eReqAtTakeoffAlt;
event eReqLand;
event eReqLandingState;

event eRespArm : bool;
event eRespTelemetryHealth : bool;
event eRespSystemStatus : bool;
event eRespTakeoff : bool;
event eRespMissionUpload : bool;
event eRespBatteryRemaining : float;
event eRespHold : bool;
event eRespReturnToLaunch : bool;
event eRespMissionFinished : bool;
event eRespMissionStart : bool;
event eRespClearMission : bool;
event eRespInAirStatus : bool;
event eRespWaitForDisarmed : bool;
event eRespAtTakeoffAlt : bool;
event eRespLand : bool;
event eRespLandingState : int;

machine FlightController
{
    var mavsdk: machine;
    var drone: machine;
    start state Init 
    {
        entry (d: machine)
        {
            drone = d;
            mavsdk = new MavSDK(this);
        }
        on eLinkInitialized goto PreFlight;
        on eRaiseError do
        {
            goto Error;
        }
    }

    state PreFlight
    {
        entry
        {      
            send mavsdk, eReqBatteryRemaining;
            receive
            {
                case eBatteryRemaining: (bstate: tBatteryState)
                {
                    if(bstate == CRITICAL)
                    {
                        goto Shutdown;
                    }
                }
            }

            send mavsdk, eReqClearMission;
            receive
            {
                case eMissionCleared: (status: bool)
                {
                    if(!status)
                    {
                        goto Error;
                    }
                }
            }
            
            send mavsdk, eReqMissionUpload;
            receive
            {
                case eMissionUploaded: (payload: bool)
                {
                    if(!payload)
                    {
                        goto Error;
                    }
                }
            }
            
            send mavsdk, eReqSystemStatus;
            receive
            {
                case eSystemConnected: (connected: bool)
                {
                    if(!connected)
                    {
                        goto Error;
                    }
                }
            }
            
            send mavsdk, eReqTelemetryHealth;
            receive
            {
                case eTelemetryHealthAllOK: (health: bool)
                {
                    if(!health)
                    {
                        goto Error;
                    }
                }
            }  
            send mavsdk, eReqArm;
        }
        on eRespArm do (status: bool)
        {
            if(!status)
            {
                goto Error;
            }
            else
            {
                goto Armed;
            }
        }
    }

    state Armed
    {
        entry
        {
            send mavsdk, eReqTelemetryHealth; 
          
            send mavsdk, eReqSystemStatus;
 
            send mavsdk, eReqBatteryRemaining;

            send mavsdk, eReqTakeoff;
        }
        on eSystemConnected do (connected: bool)
        {
            if(!connected)
            {
                goto Error;
            }
        }
        on eBatteryRemaining do (status: tBatteryState)
        {
            if(status == CRITICAL)
            {
                goto Shutdown;
            }
        }
        on eTelemetryHealthAllOK do (health: bool)
        {
            if(!health)
            {
                goto Shutdown;
            }
        }
        on eRespTakeoff do (res: bool)
        {
            if(!res)
            {
                goto Error;
            }
            else
            {
                goto Takeoff;
            }
        }
    }

    state Takeoff
    {
        entry
        {            
            send mavsdk, eReqTelemetryHealth; 
          
            send mavsdk, eReqSystemStatus;

            send mavsdk, eReqBatteryRemaining;

            send mavsdk, eReqAtTakeoffAlt;
        }
        on eSystemConnected do (connected: bool)
        {
            if(!connected)
            {
                goto Error;
            }
        }
        on eBatteryRemaining do (status: tBatteryState)
        {
            if(status == CRITICAL)
            {
                GoRTL();
            }
        }
        on eTelemetryHealthAllOK do (health: bool)
        {
            if(!health)
            {
                GoRTL();
            }
        }
        on eRespAtTakeoffAlt do (status: bool)
        {
            if(status)
            {
                send mavsdk, eReqMissionStart;
            }
            else
            {
                goto Takeoff;
            }
        }
        on eMissionStarted do (res: bool) 
        {
            if(res)
            {
                goto Mission;
            }
            else
            {
                GoRTL();
            }
        }
    }

    state Mission
    {
        entry
        {
            send mavsdk, eReqTelemetryHealth; 
          
            send mavsdk, eReqSystemStatus;
 
            send mavsdk, eReqBatteryRemaining;
  
            send mavsdk, eReqMissionFinished;
        }
        on eSystemConnected do (connected: bool)
        {
            if(!connected)
            {
                goto Error;
            }
        }
        on eBatteryRemaining do (status: tBatteryState)
        {
            if(status == CRITICAL)
            {
                GoRTL();
            }
        }
        on eTelemetryHealthAllOK do (health: bool)
        {
            if(!health)
            {
                GoRTL();
            }
        }
        on eRespMissionFinished do (status: bool)
        {
            if(status)
            {
                send mavsdk, eReqLand;
            }
            else
            {
                goto Mission;
            }
        }
        on eRespLand do (status: bool)
        {
            if(!status)
            {
                GoRTL();
            }
            else
            {
                goto Land;
            }
        }
    }

    state Land
    {
        ignore eBatteryRemaining, eTelemetryHealthAllOK, eMissionStarted;
        entry
        {
            send mavsdk, eReqSystemStatus;

            send mavsdk, eReqLandingState;
        }
        on eSystemConnected do (connected: bool)
        {
            if(!connected)
            {
                goto Error;
            }
        }
        on eRespLandingState do (val: int)
        {
            if(val == 1)
            {
                send mavsdk, eReqWaitForDisarmed;
                receive
                {
                    case eRespWaitForDisarmed do (status: bool)
                    {
                        if(!status)
                        {
                            goto Land;
                        }
                        else
                        {
                            goto Shutdown;
                        }
                    }
                }
            }
            else
            { 
                goto Land;
            }
        }
    }

    state ReturnToLaunch
    {
        ignore eBatteryRemaining, eSystemConnected, eTelemetryHealthAllOK, eRespArm,
               eRespTakeoff, eRespAtTakeoffAlt, eRespMissionFinished,
               eMissionStarted, eRaiseError;
        entry
        {
            send mavsdk, eReqWaitForDisarmed;
        }
        on eRespWaitForDisarmed do (status: bool)
        {
            if(!status)
            {
                goto ReturnToLaunch;
            }
            else
            {
                send mavsdk, eReqLandingState;
            }
        }
        on eRespLandingState do (val: int)
        {
            if(val == 1)
            {
                goto Shutdown;
            }
            else
            {
                goto Error;
            }
        }
    }

    state Error
    {
        ignore eBatteryRemaining, eSystemConnected, eTelemetryHealthAllOK, eRespArm,
               eRespTakeoff, eRespAtTakeoffAlt, eRespWaitForDisarmed, eRespMissionFinished,
               eMissionStarted, eRaiseError, eRespLand, eRespLandingState, eRespReturnToLaunch;
        entry
        {
            raise halt;
        }
    }

    state Shutdown
    {
        ignore eBatteryRemaining, eSystemConnected, eTelemetryHealthAllOK, eRespArm,
               eRespTakeoff, eRespAtTakeoffAlt, eRespWaitForDisarmed, eRespMissionFinished,
               eMissionStarted, eRespReturnToLaunch;
        entry
        {
        }
    }

    fun GoRTL()
    {
        send mavsdk, eReqReturnToLaunch;
        receive
        {
            case eRespReturnToLaunch: (status: bool)
            {
                if(!status)
                {
                    goto Error;
                }
                else
                {
                    goto ReturnToLaunch;
                }
            }
        }
    }
}
