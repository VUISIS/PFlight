using System.Threading;
using System.Xml;
using Plang.CSharpRuntime;
using Plang.CSharpRuntime.Values;

namespace PImplementation
{   
    public static partial class GlobalFunctions
    {
        private static float battery_perc;
        public static PrtBool CoreSetupMavSDK(PMachine machine)
        {
            battery_perc = 1.0f;
            return (PrtBool) true;
        }

        public static PrtBool TelemetryHealthAllOk(PMachine machine)
        {
            return (PrtBool) true;
        }

        public static PrtBool ArmSystem(PMachine machine)
        {
            
            return (PrtBool) true;
        }

        public static PrtBool TakeoffSystem(PMachine machine)
        {
            return (PrtBool) true;
        }

        public static PrtBool UploadMission(PMachine machine)
        {
            return (PrtBool) true;
        }

        public static PrtBool SystemStatus(PMachine machine)
        {
            return (PrtBool) true;
        }

        public static PrtFloat BatteryRemaining(PMachine machine)
        {
            battery_perc = battery_perc * 0.99f;
            return (PrtFloat)battery_perc;
        }

        public static PrtBool RTL(PMachine machine)
        {
            return (PrtBool) true;
        }

        public static PrtBool MissionFinished(PMachine machine)
        {
            return (PrtBool) true;
        }
        public static PrtBool StartMission(PMachine machine)
        {
            return (PrtBool) true;
        }

        public static PrtBool ClearMission(PMachine machine)
        {
            return (PrtBool) true;
        }

        public static void Sleep(PrtInt val, PMachine machine)
        {
            Thread.Sleep(val);
        }

        public static PrtBool InAirStatus(PMachine machine)
        {
            return (PrtBool) true;
        }
        public static PrtBool WaitForDisarmed(PMachine machine)
        {
            return (PrtBool) true;
        }
        public static PrtBool IsAtTakeoffAlt(PMachine machine)
        {
            return (PrtBool) true;
        }

        public static PrtBool LandSystem(PMachine machine)
        {
            return (PrtBool) true;
        }
        public static PrtInt LandingState(PMachine machine)
        {
            return (PrtInt) 1;
        }
      }
}