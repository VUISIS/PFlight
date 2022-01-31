event eSpec_PreFlight;
event eError;
event eArm;
event eTakeoff;
event eHold;
event eInAir;
event eLanding;
event eDisarmed;
event eReturnToLaunch;
event eClearedMission;

spec DroneModesOfOperation observes eSpec_PreFlight, eError, eArm, eTakeoff, eHold,
                                    eInAir, eReturnToLaunch, eClearedMission, eLanding,
                                    eDisarmed
{
    start state Init {
        on eSpec_PreFlight goto PreFlight;
        on eError goto Error;
    }

    state PreFlight
    {
        on eError goto Error;
        on eArm goto Arm;
        on eDisarmed goto Disarm;
    }

    state Arm
    {
        on eTakeoff goto Takeoff;
        on eError goto Error;
    }

    state Takeoff
    {
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
        on eReturnToLaunch goto ReturnToLaunch;
        on eError goto Error;
        on eLanding goto Land;
    }

    state Land
    {
        on eError goto Error;
        on eDisarmed goto Disarm;
    }

    state Disarm
    {
        on eError goto Error;
        on eClearedMission goto PreFlight;
    }

    state ReturnToLaunch
    {
        on eError goto Error;
    }

    state Error
    {
    }  
}

event eMavSDKReq : int;
event eMavSDKResp : int;

spec GuaranteedProgress observes eMavSDKReq, eMavSDKResp 
{
    var pendingReqs: set[int];
    start state Init
    {
        on eMavSDKReq goto PendingReq with (reqId: int)
        {
            pendingReqs += (reqId);
        }
    }

    hot state PendingReq 
    {
        on eMavSDKResp do (respId: int)
        {
            assert respId in pendingReqs, format ("Unexpected rId: {0} received, expected one of {1}", respId, pendingReqs);
            pendingReqs -= (respId);
            if(sizeof(pendingReqs) == 0) 
                goto NoPendingReq;
        }
    }

    cold state NoPendingReq
    {
        on eMavSDKReq goto PendingReq with (reqId: int)
        {
            pendingReqs += (reqId);
        }
    }
}