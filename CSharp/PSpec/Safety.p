/*************************************************************************************

    PreFlight -> Arm -> Takeoff -> Hold -> InAir -> Land -> Disarm -> Shutdown

**************************************************************************************/

event eSpec_PreFlight;
event eError;
event eArm;
event eTakeoff;
event eHold;
event eInAir;
event eLanding;
event eDisarmed;
event eReturnToLaunch;
event eShutdownSystem;

spec DroneModesOfOperation observes eSpec_PreFlight, eError, eArm, eTakeoff, eHold,
                                    eInAir, eReturnToLaunch, eLanding,
                                    eDisarmed, eShutdownSystem
{
    start state Init {
        on eSpec_PreFlight goto PreFlight;
        on eError goto Error;
    }

    state PreFlight
    {   
        on eError goto Error;
        on eArm goto Arm;
        on eShutdownSystem goto Shutdown;
    }

    state Arm
    {
        on eTakeoff goto Takeoff;
        on eError goto Error;
        on eDisarmed goto Disarm;
    }

    state Takeoff
    {
        on eTakeoff goto Takeoff;
        on eHold goto Hold;
        on eError goto Error;
        on eReturnToLaunch goto ReturnToLaunch;
    }

    state Hold
    {
        on eInAir goto InAir;
        on eError goto Error;
        on eReturnToLaunch goto ReturnToLaunch;
    }

    state InAir
    {
        on eInAir goto InAir;
        on eReturnToLaunch goto ReturnToLaunch;
        on eError goto Error;
        on eLanding goto Land;
    }

    state Land
    {
        on eLanding goto Land;
        on eError goto Error;
        on eDisarmed goto Disarm;
    }

    state Disarm
    {
        on eError goto Error;
        on eShutdownSystem goto Shutdown;
    }

    state ReturnToLaunch
    {
        on eReturnToLaunch goto ReturnToLaunch;
        on eShutdownSystem goto Shutdown;
        on eError goto Error;
    }

    state Shutdown
    {
        ignore eShutdownSystem;
    }

    state Error
    {
        ignore eError;
    }  
}

event eMavSDKReq : int;
event eMavSDKResp : int;

spec LivenessMonitor observes eMavSDKReq, eMavSDKResp 
{
    var reqId: set[int];
    start state Init 
    {
        ignore eMavSDKResp;
        on eMavSDKReq goto PendingReqs with (id: int)
        {
            reqId += (id);
        }
    }

    hot state PendingReqs
    {
        on eMavSDKResp do (id: int)
        {
            assert id in reqId, format ("Unexpected rId: {0} received, expected one of {1}", id, reqId);
            reqId -= (id);
            if(sizeof(reqId) == 0)
            {
                goto Init;
            }
        }

        on eMavSDKReq goto PendingReqs with (id: int)
        {
            reqId += (id);
        }
    }
}