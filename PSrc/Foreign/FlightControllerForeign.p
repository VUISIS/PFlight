enum tLandedState
{
    ONGROUND,
    INAIR,
    TAKINGOFF,
    LANDING
}

// MavSDK
fun CoreSetupMavSDK() : bool;
fun GetTelemetryHealthAllOk() : bool;
fun AlwaysSendHeartbeat();
fun ArmSystem() : bool;
fun TakeoffSystem(alt: float) : bool;
fun UploadMission() : bool;
fun GetSystemStatus() : bool;
fun GetBatteryRemaining() : float;
fun GetHolding() : bool;
fun GetDisarmed() : bool;
fun GetReturnToLaunch() : bool;
fun GetMissionFinished() : bool;
fun StartMission() : bool;
fun LandSystem() : bool;
fun ClearMission() : bool;
fun LandingStatus() : tLandedState;

// FlightController
fun ShutdownSystem();

// Timer
fun Sleep(msecs: int);

fun SetDeterminism(det: bool);