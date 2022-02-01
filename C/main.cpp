#include "FlightSystem.h"
#include "Prt.h"

//#include <iostream>
//#include <fstream>

PRT_PROCESS* MAIN_P_PROCESS;
//std::ofstream f;

void ErrorHandler(PRT_STATUS status, PRT_MACHINEINST* ptr) 
{
        if (status == PRT_STATUS_ASSERT) {
                fprintf_s(stdout, "exiting with PRT_STATUS_ASSERT (assertion failure)\n");
                exit(1);
        } else if (status == PRT_STATUS_EVENT_OVERFLOW) {
                fprintf_s(stdout, "exiting with PRT_STATUS_EVENT_OVERFLOW\n");
                exit(1);
        } else if (status == PRT_STATUS_EVENT_UNHANDLED) {
                fprintf_s(stdout, "exiting with PRT_STATUS_EVENT_UNHANDLED\n");
                exit(1);
        } else if (status == PRT_STATUS_QUEUE_OVERFLOW) {
                fprintf_s(stdout, "exiting with PRT_STATUS_QUEUE_OVERFLOW \n");
                exit(1);
        } else if (status == PRT_STATUS_ILLEGAL_SEND) {
                fprintf_s(stdout, "exiting with PRT_STATUS_ILLEGAL_SEND \n");
                exit(1);
        } else {
                fprintf_s(stdout, "unexpected PRT_STATUS in ErrorHandler: %d\n", status);
                exit(2);
        }
}

void PRT_CALL_CONV PFlightAssert(PRT_INT32 condition, PRT_CSTRING message) 
{
    if (condition != 0) {
        return;
    } else if (message == NULL) {
        fprintf_s(stderr, "ASSERT");
    } else {
        fprintf_s(stderr, "ASSERT: %s", message);
    }
    exit(1);
}

static void LogHandler(PRT_STEP step, PRT_MACHINESTATE* sender, PRT_MACHINEINST* receiver, PRT_VALUE* event, PRT_VALUE* payload) 
{        
        PrtPrintStep(step, sender, receiver, event, payload);

        //PRT_STRING step_str = PrtToStringStep(step, sender, receiver, event, payload);
        //f << step_str;
}

int main(int argc, char *argv[]) 
{
        ///f.open("log.txt");
        PRT_GUID processGuid;
        MAIN_P_PROCESS = PrtStartProcess(processGuid, &P_GEND_IMPL_DefaultImpl, ErrorHandler, LogHandler);
        //PrtSetSchedulingPolicy(MAIN_P_PROCESS, PRT_SCHEDULINGPOLICY_COOPERATIVE);
        PRT_UINT32 machineId;
        PRT_BOOLEAN foundMainMachine = PrtLookupMachineByName("Drone", &machineId);
        if (foundMainMachine == PRT_FALSE)
        {
                printf("%s\n", "FAILED TO FIND machine");
                exit(1);
        }
        PrtMkMachine(MAIN_P_PROCESS, machineId, 0);
        //PrtRunProcess(MAIN_P_PROCESS);
        PrtStopProcess(MAIN_P_PROCESS);
        //f.close();
}