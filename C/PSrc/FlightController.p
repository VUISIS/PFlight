event eRaiseError;

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
                    else
                    {
                        send mavsdk, eReqArm;
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
        }
        on eRespArm do (status: bool)
        {
            if(!status)
            {
                goto Error;
            }
            else
            {
                send mavsdk, eReqTakeoff, 33.0;
                goto Takeoff;
            }
        }
    }

    state Takeoff
    {
        entry
        {            
            send mavsdk, eReqTelemetryHealth; 
            receive
            {
                case eTelemetryHealthAllOK: (health: bool)
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
                                    send mavsdk, eReqReturnToLaunch;
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
            send mavsdk, eReqBatteryRemaining;
            receive
            {
                case eBatteryRemaining: (status: tBatteryState)
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
                                    send mavsdk, eReqReturnToLaunch;
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
            }
            send mavsdk, eReqAtTakeoffAlt;
        }
        on eRespTakeoff do (res: bool)
        {
            if(!res)
            {
                goto Error;
            }
        }
        on eRespAtTakeoffAlt do (status: bool)
        {
            if(status)
            {
                send mavsdk, eReqHold;
                goto Hold;
            }
            else
            {
                
                goto Takeoff;
            }
        }
    }

    state Hold
    {
        entry
        {            
            send mavsdk, eReqTelemetryHealth; 
            receive
            {
                case eTelemetryHealthAllOK: (health: bool)
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
                                    send mavsdk, eReqReturnToLaunch;
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
            send mavsdk, eReqBatteryRemaining;
            receive
            {
                case eBatteryRemaining: (status: tBatteryState)
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
                                    send mavsdk, eReqReturnToLaunch;
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
            }
        }
        on eRespHold do (res: bool) 
        {
            if(res)
            {
                send mavsdk, eReqMissionStart;
                goto Mission;
            }
            else
            {
                goto Error;
            }
        }
    }

    state Mission
    {
        entry
        {
            send mavsdk, eReqTelemetryHealth; 
            receive
            {
                case eTelemetryHealthAllOK: (health: bool)
                {
                    if(!health)
                    {
                        send mavsdk, eReqReturnToLaunch;
                        goto ReturnToLaunch;
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
            send mavsdk, eReqBatteryRemaining;
            receive
            {
                case eBatteryRemaining: (status: tBatteryState)
                {
                    if(status == CRITICAL)
                    {
                        send mavsdk, eReqReturnToLaunch;
                        goto ReturnToLaunch;
                    }
                }
            }
            send mavsdk, eReqMissionFinished;
        }
        on eMissionStarted do (started: bool)
        {
            if(!started)
            {
                goto Error;
            }
        }
        on eRespMissionFinished do (status: bool)
        {
            if(status)
            {
                send mavsdk, eReqLand;
                goto Land;
            }
            else
            {
                goto Mission;
            }
        }
    }

    state Land
    {
        ignore eBatteryRemaining, eTelemetryHealthAllOK, eMissionStarted;
        entry
        {
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
            send mavsdk, eReqLandingState;
        }
        on eRespLand do (status: bool)
        {
            if(!status)
            {
                goto Error;
            }
        }
        on eRespLandingState do (val: int)
        {
            if(val == 1)
            {
                send mavsdk, eReqDisarm;
                goto Disarm;
            }
            else
            { 
                goto Land;
            }
        }
    }

    state Disarm
    {
        ignore eBatteryRemaining, eTelemetryHealthAllOK, eMissionStarted;
        entry
        {
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
        }
        on eRespDisarm do (status: bool)
        {
            if(status)
            {
                if(numFlights < flights)
                {
                    numFlights = numFlights + 1;

                    goto PreFlight;
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
    }

    state ReturnToLaunch
    {
        ignore eBatteryRemaining, eSystemConnected, eTelemetryHealthAllOK, eRespArm,
               eRespTakeoff, eRespAtTakeoffAlt, eRespMissionFinished,
               eMissionStarted, eRaiseError;
        entry
        {
            send mavsdk, eReqWaitForDisarmed;
            receive
            {
                case eRespWaitForDisarmed: (status: bool)
                {
                    if(!status)
                    {
                        goto ReturnToLaunch;
                    }
                    else
                    {
                        send mavsdk, eReqLandingState;
                        receive
                        {
                            case eRespLandingState: (val: int)
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
                    }
                }
            }
        }
        on eRespReturnToLaunch do (status: bool)
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

    state Error
    {
        ignore eBatteryRemaining, eSystemConnected, eTelemetryHealthAllOK, eRespArm,
               eRespTakeoff, eRespAtTakeoffAlt, eRespWaitForDisarmed, eRespMissionFinished,
               eMissionStarted, eRaiseError, eRespLand, eRespLandingState, eRespHold, eRespReturnToLaunch,
               eRespDisarm;
        entry
        {
            send mavsdk, halt;
        }
    }

    state Shutdown
    {
        ignore eBatteryRemaining, eSystemConnected, eTelemetryHealthAllOK, eRespArm,
               eRespTakeoff, eRespAtTakeoffAlt, eRespWaitForDisarmed, eRespMissionFinished,
               eMissionStarted, eRespReturnToLaunch, eRespHold;
        entry
        {
            send mavsdk, halt;
        }
    }
}
