// MavSDK
fun CoreSetupMavSDK() : bool;
fun TelemetryHealthAllOk() : bool;
fun ArmSystem() : bool;
fun SetTakeoffHeight(alt: float) : bool;
fun TakeoffSystem() : bool;
fun UploadMission() : bool;
fun SystemStatus() : bool;
fun BatteryRemaining() : float;
fun RTL() : bool;
fun MissionFinished() : bool;
fun StartMission() : bool;
fun ClearMission() : bool;
fun InAirStatus() : bool;
fun WaitForDisarmed() : bool;
fun IsAtTakeoffAlt() : bool;
fun LandSystem() : bool;
fun LandingState() : int;

// Timer
fun Sleep(msecs: int);