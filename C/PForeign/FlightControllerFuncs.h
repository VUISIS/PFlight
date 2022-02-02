#pragma once
#ifndef P_COREFUNCS_H_
#define P_COREFUNCS_H_
#include "Prt.h"

#include <mavsdk/mavsdk.h>
#include <mavsdk/plugins/action/action.h>
#include <mavsdk/plugins/telemetry/telemetry.h>
#include <mavsdk/plugins/mission/mission.h>

#ifdef __cplusplus
extern "C" {
#endif
    
extern PRT_VALUE* P_CoreSetupMavSDK_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs);
extern PRT_VALUE* P_ArmSystem_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs);
extern PRT_VALUE* P_TakeoffSystem_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs);
extern PRT_VALUE* P_TelemetryHealthAllOk_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs);
extern PRT_VALUE* P_UploadMission_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs);
extern PRT_VALUE* P_SystemStatus_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs);
extern PRT_VALUE* P_BatteryRemaining_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs);
extern PRT_VALUE* P_Holding_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs);
extern PRT_VALUE* P_RTL_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs);
extern PRT_VALUE* P_MissionFinished_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs);
extern PRT_VALUE* P_StartMission_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs);
extern PRT_VALUE* P_ClearMission_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs);
extern PRT_VALUE* P_InAirStatus_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs);
extern PRT_VALUE* P_WaitForDisarmed_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs);
extern PRT_VALUE* P_IsAtTakeoffAlt_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs);
extern PRT_VALUE* P_Sleep_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs);
//extern PRT_VALUE* P_StartTimer_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs);
//extern PRT_VALUE* P_CancelTimer_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs);
extern PRT_VALUE* P_LandSystem_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs);
extern PRT_VALUE* P_LandingState_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs);
extern PRT_VALUE* P_DisarmSystem_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs);

#ifdef __cplusplus
}
#endif

#endif // P_COREFUNCS_H_