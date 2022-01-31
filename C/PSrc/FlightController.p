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
                goto Takeoff;
            }
        }
        on eBatteryRemaining do (status: tBatteryState)
        {
            if(status == CRITICAL)
            {
                goto Disarm;
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
            send mavsdk, eReqTakeoff, 33.0;
        }
        on eRespTakeoff do (res: bool)
        {
            if(!res)
            {
                goto Error;
            }
            send mavsdk, eReqAtTakeoffAlt;
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
            }
        }
        on eBatteryRemaining do (status: tBatteryState)
        {
            if(status == CRITICAL)
            {
                send mavsdk, eReqInAirStatus;
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
            send mavsdk, eReqHold;
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
            send mavsdk, eReqMissionStart;
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
            }
        }
        on eBatteryRemaining do (status: tBatteryState)
        {
            if(status == CRITICAL)
            {
                send mavsdk, eReqInAirStatus;
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
            send mavsdk, eReqLand;
        }
        on eRespLand do (status: bool)
        {
            if(status)
            {
                send mavsdk, eReqLandingState;
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
            send mavsdk, eReqDisarm;
        }
        on eRespDisarm do (status: bool)
        {
            if(status)
            {
                if(numFlights < flights)
                {
                    numFlights = numFlights + 1;

                    send mavsdk, eReqClearMission;
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
            send mavsdk, eReqReturnToLaunch;
            send mavsdk, eReqWaitForDisarmed;
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
