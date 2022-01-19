event eSpec_Ready;
event eSpec_Error;
event eSpec_Arm;
event eSpec_Takingoff;
event eSpec_Holding;
event eSpec_InAir;
event eSpec_Land;
event eSpec_Disarm;
event eSpec_PreFlight;
event eSpec_Shutdown;

spec DroneModesOfOperation observes eSpec_PreFlight, eSpec_Ready, eSpec_Error, eSpec_Arm, eSpec_Takingoff,
                                    eSpec_Holding, eSpec_InAir, eSpec_Land, eSpec_Disarm
{
    start state Init {
        on eSpec_PreFlight goto PreFlight;
    }

    state PreFlight
    {
        ignore eSpec_Arm, eSpec_Takingoff, eSpec_Holding, eSpec_InAir,
               eSpec_Land, eSpec_Disarm;
        on eSpec_Error goto Error;
        on eSpec_Ready goto Ready;
    }

    state Ready
    {
        ignore eSpec_Ready, eSpec_Takingoff, eSpec_Holding, eSpec_InAir,
               eSpec_Land, eSpec_Disarm;
        on eSpec_Error goto Error;
        on eSpec_Arm goto Arm;
        on eSpec_Shutdown goto Shutdown;
    }

    state Arm
    {
        ignore eSpec_Arm, eSpec_Ready, eSpec_Holding, eSpec_InAir,
               eSpec_Land, eSpec_Disarm;
        on eSpec_Error goto Error;
        on eSpec_Takingoff goto Takeoff;
    }

    state Takeoff
    {
        ignore eSpec_Arm, eSpec_Takingoff, eSpec_Ready, eSpec_InAir,
               eSpec_Land, eSpec_Disarm;
        on eSpec_Error goto Error;
        on eSpec_Holding goto Hold;
    }

    state Hold
    {
        ignore eSpec_Arm, eSpec_Takingoff, eSpec_Holding, eSpec_Ready,
               eSpec_Land, eSpec_Disarm;
        on eSpec_Error goto Error;
        on eSpec_InAir goto InAir;
    }

    state InAir
    {
        ignore eSpec_Arm, eSpec_Takingoff, eSpec_Holding, eSpec_InAir,
               eSpec_Ready, eSpec_Disarm;
        on eSpec_Error goto Error;
        on eSpec_Land goto Land;
    }

    state Land
    {
        ignore eSpec_Arm, eSpec_Takingoff, eSpec_Holding, eSpec_InAir,
               eSpec_Land, eSpec_Ready;
        on eSpec_Error goto Error;
        on eSpec_Disarm goto Disarm;
    }

    state Disarm
    {
        ignore eSpec_Arm, eSpec_Takingoff, eSpec_Holding, eSpec_InAir,
               eSpec_Land, eSpec_Disarm;
        on eSpec_Error goto Error;
        on eSpec_Ready goto Ready;
        on eSpec_Shutdown goto Shutdown;
    }

    state Shutdown
    {
        entry
        {

        }
    }

    state Error
    {
        ignore eSpec_Error;
        entry
        {
            
        }
    }
}