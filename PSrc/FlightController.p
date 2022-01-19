event eAlwaysSendHeartbeat;
event eShutdown;
event eRaiseError;

event eReqArm;
event eReqTelemetryHealth;
event eReqSystemStatus;
event eReqTakeoff : float;
event eReqMissionUpload;
event eReqBatteryRemaining;
event eReqDisarm;
event eReqHold;
event eReqReturnToLaunch;
event eReqMissionStart;
event eReqLand;
event eReqClearMission;
event eReqLandingStatus;
event eReqMissionFinished;

event eRespArm : bool;
event eRespTelemetryHealth : bool;
event eRespSystemStatus : bool;
event eRespTakeoff : bool;
event eRespMissionUpload : bool;
event eRespBatteryRemaining : float;
event eRespDisarm : bool;
event eRespHold : bool;
event eRespReturnToLaunch : bool;
event eRespMissionFinished : bool;
event eRespMissionStart : bool;
event eRespLand : bool;
event eRespClearMission : bool;
event eRespLandingStatus : tLandedState;

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
        }
        on eLinkInitialized goto PreFlight;
    }

    state PreFlight
    {
        ignore eBatteryRemaining, eSystemConnected, eTelemetryHealthAllOK, eLandingStatus;
        entry
        {
            flights = 1;
            announce eSpec_PreFlight;
            send mavsdk, eAlwaysSendHeartbeat;
            
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
                        goto Shutdown;
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
                        goto Shutdown;
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
                        goto Shutdown;
                    }
                }
            }

            goto Arm;
        }
    }

    state Arm
    {
        ignore eBatteryRemaining, eSystemConnected, eTelemetryHealthAllOK, eLandingStatus;
        entry
        {
            announce eSpec_Arm;
            send mavsdk, eReqArm;
        }
        on eRespArm do (armed: bool)
        {
            if(armed)
            {
                goto Takeoff;
            }
            else
            {
                raise eRaiseError;
            }
        }
        on eRaiseError push Error;
    }

    state Takeoff
    {
        ignore eBatteryRemaining, eSystemConnected, eTelemetryHealthAllOK;
        entry
        {
            announce eSpec_Takingoff;
            
            send mavsdk, eReqTakeoff, 33.3;
        }
        on eRespTakeoff do (res: bool)
        {
            if(!res)
            {
                raise eRaiseError;
            }
        }
        on eLandingStatus do (res: tLandedState)
        {
            if(res == ONGROUND)
            {
                goto Hold, "Takeoff";
            }
        }
        on eRaiseError push Error;
    }

    state Hold
    {
        ignore eBatteryRemaining, eSystemConnected, eTelemetryHealthAllOK, eLandingStatus;
        entry(stateName: string)
        {
            announce eSpec_Holding;
            
            send mavsdk, eReqHold;
            receive
            {
                case eRespHold: (res: bool) 
                {
                    if(res)
                    {
                        if(stateName == "Mission")
                        {
                            goto Land;
                        }
                        else if(stateName == "Takeoff")
                        {
                            goto Mission;
                        }
                    }
                    else
                    {
                        raise eRaiseError;
                    }
                }
            }  
        }
        on eRaiseError push Error;
    }

    state Mission
    {
        ignore eBatteryRemaining, eSystemConnected, eTelemetryHealthAllOK, eLandingStatus;
        entry
        {
            announce eSpec_InAir;
            
            send mavsdk, eReqMissionStart;
        }
        on eMissionStarted do (started: bool)
        {
            if(!started)
            {
                raise eRaiseError;
            }
        }
        on eMissionFinished do
        {
            goto Hold, "Mission";
        }
        on eRaiseError push Error;
    }

    state Disarm
    {
        ignore eBatteryRemaining, eLand, eSystemConnected, eTelemetryHealthAllOK, eLandingStatus,eRespLand;
        entry
        {
            announce eSpec_Disarm;
            
            send mavsdk, eReqDisarm;
        }
        on eRespDisarm do (disarmed: bool)
        {
            if(disarmed)
            {
                
                send mavsdk, eReqClearMission;
                receive
                {
                    case eMissionCleared: (res: bool)
                    {
                        if(!res)
                        {
                            raise eRaiseError;
                        }
                    }
                }

                if(flights > numFlights)
                {
                    goto Shutdown;
                }
                else
                {
                    goto PreFlight;
                    flights = flights + 1;
                }
            }
            else
            {
                raise eRaiseError;
            }
        }
        on eRaiseError push Error;
    }

    state Land
    {
        ignore eBatteryRemaining, eSystemConnected, eTelemetryHealthAllOK;
        entry
        {
            announce eSpec_Land;
            
            send mavsdk, eReqLand;
        }
        on eLand do (res: bool)
        {
            if(!res)
            {
                raise eRaiseError;
            }
        }
        on eLandingStatus do (res: tLandedState)
        {
            if(res == ONGROUND)
            {
                goto Disarm;
            }
        }
        on eRaiseError push Error;
    }

    state Error
    {
        entry
        {
            announce eSpec_Error;
            pop;
        }
    }

    state Shutdown
    {
        ignore eBatteryRemaining, eLand, eSystemConnected, eTelemetryHealthAllOK, eLandingStatus;
        entry
        {
            announce eSpec_Shutdown;
            send mavsdk, eShutdown;
            ShutdownSystem();
        }
    }
}
