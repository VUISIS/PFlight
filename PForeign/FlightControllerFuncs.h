#pragma once
#ifndef P_COREFUNCS_H_
#define P_COREFUNCS_H_
#include "Prt.h"

#include <chrono>
#include <cstdint>
#include <mavsdk/mavsdk.h>
#include <mavsdk/plugins/action/action.h>
#include <mavsdk/plugins/telemetry/telemetry.h>
#include <iostream>
#include <future>
#include <map>
#include <memory>
#include <thread>

#ifdef __cplusplus
extern "C" {
#endif
    
extern PRT_VALUE* P_CoreSetupMavSDK_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs);
extern PRT_VALUE* P_Shutdown_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs);
extern PRT_VALUE* P_Arm_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs);
extern PRT_VALUE* P_Takeoff_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs);
extern PRT_VALUE* P_PublishTelemetryStatus_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs);

auto _mavsdk = std::make_unique<mavsdk::Mavsdk>();
std::shared_ptr<mavsdk::System> _system;
std::shared_ptr<mavsdk::Telemetry> _telemetry;
bool _health = false;

#ifdef __cplusplus
}
#endif

#endif // P_COREFUNCS_H_