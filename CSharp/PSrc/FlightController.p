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
                goto Error;
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
                goto Armed;
            }
        }
    }

    state Armed
    {
        entry
        {
            announce eArm;
            announce eMavSDKReq, 2;
            send mavsdk, eReqSystemStatus;

            send mavsdk, eReqBatteryRemaining;
            announce eMavSDKReq, 0;

            send mavsdk, eReqTelemetryHealth; 
            announce eMavSDKReq, 3; 
  
            announce eMavSDKReq, 5;     
            send mavsdk, eReqTakeoff, 33.0;
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
/******************* Operation Spec Failure ***********/
                //goto Shutdown;
                goto Disarm;
            }
        }
        on eTelemetryHealthAllOK do (health: bool)
        {
            if(!health)
            {
                goto Disarm;
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
            announce eTakeoff; 
            announce eMavSDKReq, 2;
            send mavsdk, eReqSystemStatus;

            send mavsdk, eReqBatteryRemaining;
            announce eMavSDKReq, 0;

            send mavsdk, eReqTelemetryHealth; 
            announce eMavSDKReq, 3; 

            announce eMavSDKReq, 6;
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
                announce eMavSDKReq, 8;
                send mavsdk, eReqHold;
            }
            else
            {
                goto Takeoff;
            }
        }
        on eRespHold do (res: bool) 
        {
            if(res)
            {
                goto Hold;
            }
            else
            {
                GoRTL();
            }
        }
    }

    state Hold
    {
        entry
        {            
            announce eHold;
            announce eMavSDKReq, 3;
            send mavsdk, eReqTelemetryHealth; 
        
            announce eMavSDKReq, 2;    
            send mavsdk, eReqSystemStatus;
            
            announce eMavSDKReq, 0;
            send mavsdk, eReqBatteryRemaining;

            announce eMavSDKReq, 9;
            send mavsdk, eReqMissionStart; 
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
        on eMissionStarted do (started: bool)
        {
            if(!started)
            {
                goto Error;
            }
            else
            {
                goto Mission;
            }
        }
    }

    state Mission
    {
        entry
        {
            announce eInAir;
            announce eMavSDKReq, 3;
            send mavsdk, eReqTelemetryHealth; 
       
            announce eMavSDKReq, 2;   
            send mavsdk, eReqSystemStatus;
 
            announce eMavSDKReq, 0;
            send mavsdk, eReqBatteryRemaining;
 
            send mavsdk, eReqMissionFinished;
            announce eMavSDKReq, 10;
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
                announce eMavSDKReq, 11;
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
            announce eLanding;
            
            announce eMavSDKReq, 2;
            send mavsdk, eReqSystemStatus;
 
            announce eMavSDKReq, 12;
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
        ignore eBatteryRemaining, eTelemetryHealthAllOK, eMissionStarted, eRespTakeoff;
        entry
        {
            announce eDisarmed;

            announce eMavSDKReq, 2;
            send mavsdk, eReqSystemStatus;
  
            announce eMavSDKReq, 13;
            send mavsdk, eReqDisarm;
        }
        on eRespDisarm do (status: bool)
        {
            if(status)
            {
                goto Shutdown;
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
        ignore eBatteryRemaining, eSystemConnected, eTelemetryHealthAllOK, eRespArm,
               eRespTakeoff, eRespAtTakeoffAlt, eRespMissionFinished, eRespLand,
               eMissionStarted, eRaiseError, eRespHold;
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
            else
            {
                send mavsdk, eReqLandingState;
                announce eMavSDKReq, 12;
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
               eMissionStarted, eRaiseError, eRespLand, eRespLandingState, eRespHold, eRespReturnToLaunch,
               eRespDisarm;
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
               eMissionStarted, eRespReturnToLaunch, eRespHold;
        entry
        {
            announce eShutdownSystem;
            raise halt;
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
                else
                {
                    goto ReturnToLaunch;
                }
            }
        }
    }
}
