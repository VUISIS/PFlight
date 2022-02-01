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
    {   ignore eSpec_PreFlight;
        on eError goto Error;
        on eArm goto Arm;
        on eDisarmed goto Disarm;
    }

    state Arm
    {
        ignore eArm;
        on eTakeoff goto Takeoff;
        on eError goto Error;
    }

    state Takeoff
    {
        ignore eTakeoff;
        on eHold goto Hold;
        on eError goto Error;
        on eReturnToLaunch goto ReturnToLaunch;
    }

    state Hold
    {
        ignore eHold;
        on eInAir goto InAir;
        on eError goto Error;
        on eReturnToLaunch goto ReturnToLaunch;
    }

    state InAir
    {
        ignore eInAir;
        on eReturnToLaunch goto ReturnToLaunch;
        on eError goto Error;
        on eLanding goto Land;
    }

    state Land
    {
        ignore eLanding;
        on eError goto Error;
        on eDisarmed goto Disarm;
    }

    state Disarm
    {
        ignore eDisarmed;
        on eError goto Error;
        on eClearedMission goto PreFlight;
    }

    state ReturnToLaunch
    {
        ignore eReturnToLaunch;
        on eError goto Error;
    }

    state Error
    {
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
            print format("Req {0}", reqId);
        }
    }

    hot state PendingReqs
    {
        on eMavSDKResp do (id: int)
        {
            assert id in reqId, format ("Unexpected rId: {0} received, expected one of {1}", id, reqId);
            reqId -= (id);
            print format("Resp {0}", reqId);
            if(sizeof(reqId) == 0)
            {
                goto Init;
            }
        }

        on eMavSDKReq goto PendingReqs with (id: int)
        {
            reqId += (id);
            print format("Req {0}", reqId);
        }
    }
}