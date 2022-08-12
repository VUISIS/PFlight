event eRaiseError;

event eReqArm;
event eReqTelemetryHealth;
event eReqSystemStatus;
event eReqTakeoff : float;
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
        ignore eBatteryRemaining, eSystemConnected, eTelemetryHealthAllOK;
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
            announce eSpec_PreFlight;
            announce eMavSDKReq, 0;
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
            announce eMavSDKReq, 14;
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
            
            announce eMavSDKReq, 1;
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
            
            announce eMavSDKReq, 2;
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
            
            announce eMavSDKReq, 3;
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
            announce eMavSDKReq, 4;
        }
        on eRespArm do (status: bool)
        {
            if(!status)
            {
                goto Error;
            }
            goto Armed;
        }
    }

    state Armed
    {
        entry
        {
            announce eArm;
            announce eMavSDKReq, 3;
            send mavsdk, eReqTelemetryHealth; 

            receive
            {
                case eTelemetryHealthAllOK: (health: bool)
                {
                    if(!health)
                    {
                        goto Shutdown;
                    }
                }
            }
       
            announce eMavSDKReq, 2;   
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
 
            announce eMavSDKReq, 0;
            send mavsdk, eReqBatteryRemaining;

            receive
            {
                case eBatteryRemaining: (status: tBatteryState)
                {
                    if(status == CRITICAL)
                    {
                        goto Shutdown;
                    }
                }
            }
  
            announce eMavSDKReq, 5;     
            send mavsdk, eReqTakeoff, 15.0;
        }
        on eRespTakeoff do (res: bool)
        {
            if(!res)
            {
                goto Error;
            }
            goto Takeoff;
        }
    }

    state Takeoff
    {
        entry
        {   
            announce eTakeoff; 
            announce eMavSDKReq, 3;
            send mavsdk, eReqTelemetryHealth; 

            receive
            {
                case eTelemetryHealthAllOK: (health: bool)
                {
                    if(!health)
                    {
                        GoRTL();
                    }
                }
            }
       
            announce eMavSDKReq, 2;   
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
 
            announce eMavSDKReq, 0;
            send mavsdk, eReqBatteryRemaining;

            receive
            {
                case eBatteryRemaining: (status: tBatteryState)
                {
                    if(status == CRITICAL)
                    {
                        GoRTL();
                    }
                }
            }

            announce eMavSDKReq, 6;
            send mavsdk, eReqAtTakeoffAlt;
        }
        on eRespAtTakeoffAlt do (status: bool)
        {
            if(status)
            {
                announce eMavSDKReq, 9;
                send mavsdk, eReqMissionStart;
            }
            goto Takeoff;
        }
        on eMissionStarted do (res: bool) 
        {
            if(res)
            {
                goto Mission;
            }
            GoRTL();
        }
    }

    state Mission
    {
        ignore eRespAtTakeoffAlt;
        entry
        {
            announce eInAir;
            announce eMavSDKReq, 3;
            send mavsdk, eReqTelemetryHealth; 

            receive
            {
                case eTelemetryHealthAllOK: (health: bool)
                {
                    if(!health)
                    {
                        GoRTL();
                    }
                }
            }
       
            announce eMavSDKReq, 2;   
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
 
            announce eMavSDKReq, 0;
            send mavsdk, eReqBatteryRemaining;

            receive
            {
                case eBatteryRemaining: (status: tBatteryState)
                {
                    if(status == CRITICAL)
                    {
                        GoRTL();
                    }
                }
            }
 
            announce eMavSDKReq, 10;
            send mavsdk, eReqMissionFinished;
        }
        on eRespMissionFinished do (status: bool)
        {
            if(status)
            {
                announce eMavSDKReq, 11;
                send mavsdk, eReqLand;
            }
            goto Mission;
        }
        on eRespLand do (status: bool)
        {
            if(!status)
            {
                GoRTL();
            }
            goto Land;
        }
    }

    state Land
    {
        ignore eBatteryRemaining, eTelemetryHealthAllOK, eMissionStarted, eRespMissionFinished;
        entry
        {
            announce eLanding;
            
            announce eMavSDKReq, 2;   
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
 
            announce eMavSDKReq, 12;
            send mavsdk, eReqLandingState;
        }
        on eRespLandingState do (val: int)
        {
            if(val == 1)
            {
                announce eMavSDKReq, 16;
                send mavsdk, eReqWaitForDisarmed;
                receive 
                {
                    case eRespWaitForDisarmed: (status: bool)
                    {
                        if(!status)
                        {
                            goto Land;
                        }
                        goto Shutdown;
                    }
                }
            }
            goto Land;
        }
    }

    state ReturnToLaunch
    {
        ignore eBatteryRemaining, eSystemConnected, eTelemetryHealthAllOK, eRespArm,
               eRespTakeoff, eRespAtTakeoffAlt, eRespMissionFinished, eRespLand,
               eMissionStarted, eRaiseError;
        entry
        {
            announce eReturnToLaunch;
            announce eMavSDKReq, 16;
            send mavsdk, eReqWaitForDisarmed;
        }
        on eRespWaitForDisarmed do (status: bool)
        {
            if(!status)
            {
                goto ReturnToLaunch;
            }
            send mavsdk, eReqLandingState;
            announce eMavSDKReq, 12;
        }
        on eRespLandingState do (val: int)
        {
            if(val == 1)
            {
                goto Shutdown;
            }
            goto Error;
        }
    }

    state Error
    {
        ignore eBatteryRemaining, eSystemConnected, eTelemetryHealthAllOK, eRespArm,
               eRespTakeoff, eRespAtTakeoffAlt, eRespWaitForDisarmed, eRespMissionFinished,
               eMissionStarted, eRaiseError, eRespLand, eRespLandingState, eRespReturnToLaunch;
        entry
        {
            announce eError;
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
            announce eShutdownSystem;
        }
    }

    fun GoRTL()
    {
        announce eMavSDKReq, 15;
        send mavsdk, eReqReturnToLaunch;
        receive
        {
            case eRespReturnToLaunch: (status: bool)
            {
                if(!status)
                {
                    goto Error;
                }
                goto ReturnToLaunch;
            }
        }
    }
}
