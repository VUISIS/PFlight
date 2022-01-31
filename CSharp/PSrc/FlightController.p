event eRaiseError;
event eHaltTimer;

event eReqArm;
event eReqTelemetryHealth;
event eReqSystemStatus;
event eReqTakeoff : float;
event eReqMissionUpload;
event eReqBatteryRemaining;
event eReqHold;
event eReqReturnToLaunch;
event eReqMissionStart;
event eReqClearMission;
event eReqInAirStatus;
event eReqMissionFinished;
event eReqWaitForDisarmed;
event eReqAtTakeoffAlt;
event eReqLand;
event eReqLandingState;
event eReqDisarm;

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
event eRespDisarm : bool;

machine FlightController
{
    var flights: int;
    var numFlights: int;
    var mavsdk: machine;
    var drone: machine;
    start state Init 
    {
        entry (payload: (f: int, d: machine))
        {
            flights = payload.f;
            drone = payload.d;
            mavsdk = new MavSDK(this);
            numFlights = 1;
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
            send mavsdk, eReqBatteryRemaining;
            announce eMavSDKReq, 0;
            receive
            {
                case eBatteryRemaining: (bstate: tBatteryState)
                {
                    if(bstate == CRITICAL)
                    {
                        goto Disarm;
                    }
                }
            }
            
            send mavsdk, eReqMissionUpload;
            announce eMavSDKReq, 1;
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
            announce eMavSDKReq, 2;
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
            announce eMavSDKReq, 3;
            receive
            {
                case eTelemetryHealthAllOK: (health: bool)
                {
                    if(!health)
                    {
                        goto Error;
                    }
                    else
                    {
                        goto Arm;
                    }
                }
            }  
        }
    }

    state Arm
    {
        entry
        {
            announce eArm;
            send mavsdk, eReqArm;
            announce eMavSDKReq, 4;
        }
        on eRespArm do (status: bool)
        {
            if(!status)
            {
                goto Error;
            }
            else
            {
                goto Takeoff;
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
                goto Error;
            }
        }
        on eSystemConnected do (connected: bool)
        {
            if(!connected)
            {
                goto Error;
            }
        }
    }

    state Takeoff
    {
        entry
        {   
            announce eTakeoff;         
            send mavsdk, eReqTakeoff, 33.0;
            announce eMavSDKReq, 5;
        }
        on eRespTakeoff do (res: bool)
        {
            if(!res)
            {
                goto Error;
            }
            send mavsdk, eReqAtTakeoffAlt;
            announce eMavSDKReq, 6;
        }
        on eRespAtTakeoffAlt do (status: bool)
        {
            if(status)
            {
                goto Hold;
            }
            else
            {
                send mavsdk, eReqAtTakeoffAlt;
                announce eMavSDKReq, 6;
            }
        }
        on eBatteryRemaining do (status: tBatteryState)
        {
            if(status == CRITICAL)
            {
                send mavsdk, eReqInAirStatus;
                announce eMavSDKReq, 7;
                receive
                {
                    case eInAirStatus: (status: bool)
                    {
                        if(status)
                        {
                            goto ReturnToLaunch;
                        }
                        else
                        {
                            goto Shutdown;
                        }
                    }
                }
            }
        }
        on eTelemetryHealthAllOK do (health: bool)
        {
            if(!health)
            {
                send mavsdk, eReqInAirStatus;
                announce eMavSDKReq, 7;
                receive
                {
                    case eInAirStatus: (status: bool)
                    {
                        if(status)
                        {
                            goto ReturnToLaunch;
                        }
                        else
                        {
                            goto Error;
                        }
                    }
                }
            }
        }
        on eSystemConnected do (connected: bool)
        {
            if(!connected)
            {
                goto Error;
            }
        }

    }

    state Hold
    {
        entry
        {            
            announce eHold;
            send mavsdk, eReqHold;
            announce eMavSDKReq, 8;
            receive
            {
                case eRespHold: (res: bool) 
                {
                    if(res)
                    {
                        goto Mission;
                    }
                    else
                    {
                        goto Error;
                    }
                }
            }
        }
        on eBatteryRemaining do (status: tBatteryState)
        {
            if(status == CRITICAL)
            {
                send mavsdk, eReqInAirStatus;
                announce eMavSDKReq, 7;
                receive
                {
                    case eInAirStatus: (status: bool)
                    {
                        if(status)
                        {
                            goto ReturnToLaunch;
                        }
                        else
                        {
                            goto Shutdown;
                        }
                    }
                }
            }
        }
        on eTelemetryHealthAllOK do (health: bool)
        {
            if(!health)
            {
                send mavsdk, eReqInAirStatus;
                announce eMavSDKReq, 7;
                receive
                {
                    case eInAirStatus: (status: bool)
                    {
                        if(status)
                        {
                            goto ReturnToLaunch;
                        }
                        else
                        {
                            goto Error;
                        }
                    }
                }
            }
        }
        on eSystemConnected do (connected: bool)
        {
            if(!connected)
            {
                goto Error;
            }
        }

    }

    state Mission
    {
        entry
        {
            announce eInAir;
            send mavsdk, eReqMissionStart;
            announce eMavSDKReq, 9;
        }
        on eMissionStarted do (started: bool)
        {
            if(!started)
            {
                goto Error;
            }
            else
            {
                send mavsdk, eReqMissionFinished;
                announce eMavSDKReq, 10;
            }
        }
        on eRespMissionFinished do (status: bool)
        {
            if(status)
            {
                goto Land;
            }
            else
            {
                send mavsdk, eReqMissionFinished;
                announce eMavSDKReq, 10;
            }
        }
        on eBatteryRemaining do (status: tBatteryState)
        {
            if(status == CRITICAL)
            {
                send mavsdk, eReqInAirStatus;
                announce eMavSDKReq, 7;
                receive
                {
                    case eInAirStatus: (status: bool)
                    {
                        if(status)
                        {
                            goto ReturnToLaunch;
                        }
                        else
                        {
                            goto Shutdown;
                        }
                    }
                }
            }
        }
        on eTelemetryHealthAllOK do (health: bool)
        {
            if(!health)
            {
                send mavsdk, eReqInAirStatus;
                announce eMavSDKReq, 7;
                receive
                {
                    case eInAirStatus: (status: bool)
                    {
                        if(status)
                        {
                            goto ReturnToLaunch;
                        }
                        else
                        {
                            goto Error;
                        }
                    }
                }
            }
        }
        on eSystemConnected do (connected: bool)
        {
            if(!connected)
            {
                goto Error;
            }
        }
    }

    state Land
    {
        ignore eBatteryRemaining, eTelemetryHealthAllOK, eMissionStarted;
        entry
        {
            announce eLanding;
            send mavsdk, eReqLand;
            announce eMavSDKReq, 11;
        }
        on eRespLand do (status: bool)
        {
            if(status)
            {
                send mavsdk, eReqLandingState;
                announce eMavSDKReq, 12;
            }
        }
        on eRespLandingState do (val: int)
        {
            if(val == 1)
            {
                goto Disarm;
            }
            else
            {
                send mavsdk, eReqLandingState;
                announce eMavSDKReq, 12;
            }
        }
        on eSystemConnected do (connected: bool)
        {
            if(!connected)
            {
                goto Error;
            }
        }
    }

    state Disarm
    {
        ignore eBatteryRemaining, eTelemetryHealthAllOK, eMissionStarted;
        entry
        {
            announce eDisarmed;
            send mavsdk, eReqDisarm;
            announce eMavSDKReq, 13;
        }
        on eRespDisarm do (status: bool)
        {
            if(status)
            {
                if(numFlights < flights)
                {
                    numFlights = numFlights + 1;

                    send mavsdk, eReqClearMission;
                    announce eMavSDKReq, 14;
                    receive
                    {
                        case eMissionCleared: (status: bool)
                        {
                            if(status)
                            {
                                goto PreFlight;
                            }
                            else
                            {
                                goto Error;
                            }
                        }
                    }
                }
                else
                {
                    goto Shutdown;
                }
            }
            else
            {
                goto Error;
            }
        }
        on eSystemConnected do (connected: bool)
        {
            if(!connected)
            {
                goto Error;
            }
        }
    }

    state ReturnToLaunch
    {
        ignore eBatteryRemaining, eSystemConnected, eTelemetryHealthAllOK;
        entry
        {
            announce eReturnToLaunch;
            send mavsdk, eReqReturnToLaunch;
            announce eMavSDKReq, 15;
            send mavsdk, eReqWaitForDisarmed;
            announce eMavSDKReq, 16;
        }
        on eRespReturnToLaunch do (status: bool)
        {
            if(!status)
            {
                goto Error;
            }
        }
        on eRespWaitForDisarmed do (status: bool)
        {
            if(status)
            {
                send mavsdk, eReqWaitForDisarmed;
            }
            else
            {
                goto Shutdown;
            }
        }
    }

    state Error
    {
        ignore eBatteryRemaining, eSystemConnected, eTelemetryHealthAllOK, eRespArm,
               eRespTakeoff, eRespAtTakeoffAlt, eRespWaitForDisarmed, eRespMissionFinished,
               eMissionStarted, eRaiseError;
        entry
        {
            announce eError;
            send mavsdk, eHaltTimer;
        }
    }

    state Shutdown
    {
        ignore eBatteryRemaining, eSystemConnected, eTelemetryHealthAllOK, eRespArm,
               eRespTakeoff, eRespAtTakeoffAlt, eRespWaitForDisarmed, eRespMissionFinished,
               eMissionStarted;
        entry
        {
            send mavsdk, eHaltTimer;
        }
    }
}
