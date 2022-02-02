// MavSDK
fun CoreSetupMavSDK() : bool;
fun TelemetryHealthAllOk() : bool;
fun ArmSystem() : bool;
fun TakeoffSystem(alt: float) : bool;
fun UploadMission() : bool;
fun SystemStatus() : bool;
fun BatteryRemaining() : float;
fun Holding() : bool;
fun RTL() : bool;
fun MissionFinished() : bool;
fun StartMission() : bool;
fun ClearMission() : bool;
fun InAirStatus() : bool;
fun WaitForDisarmed() : bool;
fun IsAtTakeoffAlt() : bool;
fun LandSystem() : bool;
fun LandingState() : int;
fun DisarmSystem() : bool;

// Timer
fun Sleep(msecs: int);