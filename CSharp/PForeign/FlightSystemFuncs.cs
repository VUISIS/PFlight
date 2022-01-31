using System.Threading;
using System.Xml;
using Plang.CSharpRuntime;
using Plang.CSharpRuntime.Values;

namespace PImplementation
{   
    public static partial class GlobalFunctions
    {
        private static float battery_perc;
        private static bool determinism = true;
        public static PrtBool CoreSetupMavSDK(PMachine machine)
        {
            if(determinism)
            {
                battery_perc = 1.0f;
                return (PrtBool) true;
            }
            else
            {
                battery_perc = machine.TryRandomInt(0,100)/100.0f;
                return (PrtBool) machine.TryRandomBool();
            }
        }

        public static PrtBool TelemetryHealthAllOk(PMachine machine)
        {
            if(determinism)
            {
                return (PrtBool) true;
            }
            else
            {
                return (PrtBool) machine.TryRandomBool();
            }
        }

        public static void ShutdownSystem(PMachine machine)
        {
           
        }

        public static PrtBool ArmSystem(PMachine machine)
        {
            if(determinism)
            {
                return (PrtBool) true;
            }
            else
            {
                return (PrtBool) machine.TryRandomBool();
            }
        }

        public static PrtBool TakeoffSystem(PrtFloat val, PMachine machine)
        {
            if(determinism)
            {
                return (PrtBool) true;
            }
            else
            {
                return (PrtBool) machine.TryRandomBool();
            }
        }

        public static PrtBool UploadMission(PMachine machine)
        {
            if(determinism)
            {
                return (PrtBool) true;
            }
            else
            {
                return (PrtBool) machine.TryRandomBool();
            }
        }

        public static PrtBool SystemStatus(PMachine machine)
        {
            if(determinism)
            {
                return (PrtBool) true;
            }
            else
            {
                return (PrtBool) machine.TryRandomBool();
            }
        }

        public static PrtFloat BatteryRemaining(PMachine machine)
        {
            if(determinism)
            {
                battery_perc = battery_perc * 1.0f;
            }
            else
            {
                battery_perc = battery_perc * machine.TryRandomInt(100)/100.0f;
            }
            PrtFloat perc = (PrtFloat)battery_perc;
            return perc;
        }

        public static PrtBool Holding(PMachine machine)
        {
            if(determinism)
            {
                return (PrtBool) true;
            }
            else
            {
                return (PrtBool) machine.TryRandomBool();
            }
        }

        public static PrtBool Disarmed(PMachine machine)
        {
            if(determinism)
            {
                return (PrtBool) true;
            }
            else
            {
                return (PrtBool) machine.TryRandomBool();
            }
        }

        public static PrtBool ReturnToLaunch(PMachine machine)
        {
            if(determinism)
            {
                return (PrtBool) true;
            }
            else
            {
                return (PrtBool) machine.TryRandomBool();
            }
        }

        public static PrtBool MissionFinished(PMachine machine)
        {
            if(determinism)
            {
                return (PrtBool) true;
            }
            else
            {
                return (PrtBool) machine.TryRandomBool();
            }
        }
        public static PrtBool StartMission(PMachine machine)
        {
            if(determinism)
            {
                return (PrtBool) true;
            }
            else
            {
                return (PrtBool) machine.TryRandomBool();
            }
        }

        public static PrtBool ClearMission(PMachine machine)
        {
            if(determinism)
            {
                return (PrtBool) true;
            }
            else
            {
                return (PrtBool) machine.TryRandomBool();
            }
        }

        public static void Sleep(PrtInt val, PMachine machine)
        {
            Thread.Sleep(val);
        }

        public static void SetDeterminism(PrtBool val, PMachine machine)
        {
            determinism = val;
        }

        public static PrtBool InAirStatus(PMachine machine)
        {
            if(determinism)
            {
                return (PrtBool) true;
            }
            else
            {
                return (PrtBool) machine.TryRandomBool();
            }
        }
        public static PrtBool WaitForDisarmed(PMachine machine)
        {
            if(determinism)
            {
                return (PrtBool) false;
            }
            else
            {
                return (PrtBool) machine.TryRandomBool();
            }
        }
        public static PrtBool IsAtTakeoffAlt(PMachine machine)
        {
            if(determinism)
            {
                return (PrtBool) true;
            }
            else
            {
                return (PrtBool) machine.TryRandomBool();
            }
        }

        public static PrtBool LandSystem(PMachine machine)
        {
            if(determinism)
            {
                return (PrtBool) true;
            }
            else
            {
                return (PrtBool) machine.TryRandomBool();
            }
        }
        public static PrtInt LandingState(PMachine machine)
        {
            if(determinism)
            {
                return (PrtInt) 1;
            }
            else
            {
                return (PrtInt) machine.TryRandomInt(0,4);
            }
        }
        public static PrtBool DisarmSystem(PMachine machine)
        {
            if(determinism)
            {
                return (PrtBool) true;
            }
            else
            {
                return (PrtBool) machine.TryRandomBool();
            }
        }
      }
}