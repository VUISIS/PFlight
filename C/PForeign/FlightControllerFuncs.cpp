#include "FlightControllerFuncs.h"
#include "FlightSystem.h"

#include <tinyxml2.h>

#include <atomic>
#include <iostream>
#include <future>
#include <vector>
#include <map>
#include <memory>
#include <thread>
#include <chrono>
#include <cstdint>

auto _mavsdk = std::make_unique<mavsdk::Mavsdk>();
std::shared_ptr<mavsdk::System> _system;
std::shared_ptr<mavsdk::Telemetry> _telemetry;
std::shared_ptr<mavsdk::Action> _action;
std::shared_ptr<mavsdk::Mission> _mission;

std::atomic_bool timer_flag = true;
std::thread timer_thread;
std::vector<mavsdk::Mission::MissionItem> _missionItems;

PRT_MACHINEINST* contextM = NULL;
PRT_VALUE* PTMP_tmp1 = NULL; 
PRT_VALUE* PTMP_tmp10 = NULL;
PRT_VALUE* PTMP_tmp2_20 = NULL;

std::shared_ptr<mavsdk::System> get_system(mavsdk::Mavsdk& mavsdk)
{
    std::cout << "<PrintLog> Waiting to discover system...\n";
    auto prom = std::promise<std::shared_ptr<mavsdk::System>>{};
    auto fut = prom.get_future();

    mavsdk.subscribe_on_new_system([&mavsdk, &prom]() 
	{
        auto system = mavsdk.systems().back();

        if (system->has_autopilot()) 
		{
            std::cout << "<PrintLog> Discovered autopilot\n";

            mavsdk.subscribe_on_new_system(nullptr);
            prom.set_value(system);
        }
    });

    if (fut.wait_for(std::chrono::seconds(3)) == std::future_status::timeout) 
	{
        std::cerr << "<ErrorLog> No autopilot found.\n";
        return {};
    }

    return fut.get();
}

// Init foreign function
PRT_VALUE* P_CoreSetupMavSDK_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs)
{	
	mavsdk::ConnectionResult connection_result = _mavsdk->add_any_connection("udp://:14540");

    if (connection_result != mavsdk::ConnectionResult::Success) 
	{
        std::cerr << "<ErrorLog> Connection failed: " << connection_result << '\n';
        return PrtMkBoolValue(PRT_FALSE);
    }
	_system = get_system(*_mavsdk);
    if (!_system) 
	{
        return PrtMkBoolValue(PRT_FALSE);
    }
	
    _action = std::make_shared<mavsdk::Action>(_system);

    _mission = std::make_shared<mavsdk::Mission>(_system);

    _telemetry = std::make_shared<mavsdk::Telemetry>(_system);

	return PrtMkBoolValue(PRT_TRUE);
}

// Reply foreign functions
PRT_VALUE* P_ArmSystem_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs)
{
    mavsdk::Action::Result res = _action->arm();
    if(res == mavsdk::Action::Result::Success)
    {
        return PrtMkBoolValue(PRT_TRUE);
    }
    else
    {
        return PrtMkBoolValue(PRT_FALSE);
    }
}

PRT_VALUE* P_TakeoffSystem_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs)
{
    _action->set_takeoff_altitude_async(15.0f, [](mavsdk::Action::Result res){
        if(res == mavsdk::Action::Result::Success)
        {
            return PrtMkBoolValue(PRT_TRUE);
        }
    });

	_action->takeoff_async([](mavsdk::Action::Result res){ 
        if(res == mavsdk::Action::Result::Success)
        {
            _action->takeoff_async(nullptr);
        }
    });
    return PrtMkBoolValue(PRT_TRUE);
}

PRT_VALUE* P_TelemetryHealthAllOk_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs)
{
    auto prom = std::promise<bool>{};
    auto fut = prom.get_future();
    _telemetry->subscribe_health_all_ok([&prom](bool health)
    {
        if(health)
        {
            prom.set_value(true);
        }
    });

    if (fut.wait_for(std::chrono::seconds(30)) == std::future_status::timeout) 
	{
        return PrtMkBoolValue((PRT_BOOLEAN)false);
    }
    return PrtMkBoolValue((PRT_BOOLEAN)fut.get());
}

PRT_VALUE* P_UploadMission_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs)
{
    _missionItems.clear();

    tinyxml2::XMLDocument doc;
    const char* path = "../../Res/mission.xml";
    doc.LoadFile(path);

    tinyxml2::XMLElement* root = doc.RootElement();
    tinyxml2::XMLElement* pMI = root->FirstChildElement("MissionItem");
    while(pMI)
    {
        mavsdk::Mission::MissionItem mi{};
        pMI->FirstChildElement("Latitude")->QueryDoubleText(&mi.latitude_deg);
        pMI->FirstChildElement("Longitude")->QueryDoubleText(&mi.longitude_deg);
        pMI->FirstChildElement("RelativeAltitude")->QueryFloatText(&mi.relative_altitude_m);
        pMI->FirstChildElement("Speed")->QueryFloatText(&mi.speed_m_s);
        pMI->FirstChildElement("IsFlyThrough")->QueryBoolText(&mi.is_fly_through);
        pMI->FirstChildElement("GimbalPitch")->QueryFloatText(&mi.gimbal_pitch_deg);
        pMI->FirstChildElement("GimbalYaw")->QueryFloatText(&mi.gimbal_yaw_deg);
        mi.camera_action = mavsdk::Mission::MissionItem::CameraAction::None;
        pMI->FirstChildElement("LoiterTime")->QueryFloatText(&mi.loiter_time_s);
        pMI->FirstChildElement("CameraPhotoInterval")->QueryDoubleText(&mi.camera_photo_interval_s);
        pMI->FirstChildElement("AcceptanceRadius")->QueryFloatText(&mi.acceptance_radius_m);
        pMI->FirstChildElement("Yaw")->QueryFloatText(&mi.yaw_deg);
        pMI->FirstChildElement("CameraPhotoDistance")->QueryFloatText(&mi.camera_photo_distance_m);
        _missionItems.push_back(mi);
        pMI = pMI->NextSiblingElement("MissionItem");
    }
    mavsdk::Mission::MissionPlan mission_plan{};
    mission_plan.mission_items = _missionItems;
    const mavsdk::Mission::Result upload_result = _mission->upload_mission(mission_plan);
    if (upload_result != mavsdk::Mission::Result::Success) 
    {
        return PrtMkBoolValue((PRT_BOOLEAN)false);
    }
    return PrtMkBoolValue((PRT_BOOLEAN)true);
}

PRT_VALUE* P_SystemStatus_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs)
{
    auto prom = std::promise<bool>{};
    auto fut = prom.get_future();
    _system->subscribe_is_connected([&prom](bool connected)
    {
        if(connected)
        {
            prom.set_value(true);
        }
    });

    if (fut.wait_for(std::chrono::seconds(30)) == std::future_status::timeout) 
	{
        return PrtMkBoolValue((PRT_BOOLEAN)false);
    }
    return PrtMkBoolValue((PRT_BOOLEAN)fut.get());
}

PRT_VALUE* P_BatteryRemaining_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs)
{
    auto prom = std::promise<float>{};
    auto fut = prom.get_future();
    _telemetry->subscribe_battery([&prom](mavsdk::Battery battery)
    {
        prom.set_value(battery.remaining_percent);
    });

    if (fut.wait_for(std::chrono::seconds(30)) == std::future_status::timeout) 
	{
        return PrtMkFloatValue((PRT_FLOAT)fut.get());
    }
    return PrtMkFloatValue((PRT_FLOAT)0.0f);
}

PRT_VALUE* P_Holding_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs)
{
    auto res = _action->hold();
    if(res != mavsdk::Action::Result::Success)
    {
        return PrtMkBoolValue((PRT_BOOLEAN)false);
    }
    return PrtMkBoolValue((PRT_BOOLEAN)true);
}

PRT_VALUE* P_RTL_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs)
{
    auto res = _action->return_to_launch();
    if(res != mavsdk::Action::Result::Success)
    {
        return PrtMkBoolValue((PRT_BOOLEAN)false);
    }
    return PrtMkBoolValue((PRT_BOOLEAN)true);
}

PRT_VALUE* P_MissionFinished_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs)
{
    mavsdk::Mission::MissionProgress prog = _mission->mission_progress();
    if(prog.total == prog.current)
    {
        return PrtMkBoolValue((PRT_BOOLEAN)true);
    }
    return PrtMkBoolValue((PRT_BOOLEAN)false);
}

PRT_VALUE* P_StartMission_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs)
{
    auto res = _mission->start_mission();
    if(res != mavsdk::Mission::Result::Success)
    {
        PrtMkBoolValue((PRT_BOOLEAN)false);
    }
    return PrtMkBoolValue((PRT_BOOLEAN)true);
}

PRT_VALUE* P_ClearMission_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs)
{
    auto res = _mission->clear_mission();
    if(res != mavsdk::Mission::Result::Success)
    {
        PrtMkBoolValue((PRT_BOOLEAN)false);
    }
    return PrtMkBoolValue((PRT_BOOLEAN)true);
}

PRT_VALUE* P_InAirStatus_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs)
{
    bool res = _telemetry->in_air();
    return PrtMkBoolValue((PRT_BOOLEAN)res);
}

PRT_VALUE* P_WaitForDisarmed_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs)
{
    bool armed = _telemetry->armed();
    if(armed)
    {
        return PrtMkBoolValue((PRT_BOOLEAN)false);
    }
    return PrtMkBoolValue((PRT_BOOLEAN)true);
}

PRT_VALUE* P_IsAtTakeoffAlt_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs)
{
    auto prom = std::promise<float>{};
    auto fut = prom.get_future();
    _telemetry->subscribe_position([&prom](mavsdk::Position position)
    {
        prom.set_value(position.relative_altitude_m);
    });

    if (fut.wait_for(std::chrono::seconds(30)) == std::future_status::timeout) 
	{
        return PrtMkBoolValue((PRT_BOOLEAN)false);
    }

    auto val = fut.get();
    if(abs(val - 15.0f) < 0.5f)
    {
        return PrtMkBoolValue(PRT_TRUE);
    }

    return PrtMkBoolValue(PRT_FALSE);
}

PRT_VALUE* P_Sleep_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs)
{
    PRT_VALUE* PTMP_tmp1_1 = NULL;

	PRT_VALUE** P_LVALUE_6 = &(PTMP_tmp1_1);
	PrtFreeValue(*P_LVALUE_6);
	*P_LVALUE_6 = PrtCloneValue((PRT_VALUE*)*argRefs[0]);
    std::this_thread::sleep_for(std::chrono::milliseconds(PrtPrimGetInt(PTMP_tmp1_1)));
    return PrtMkNullValue();
}

/*PRT_VALUE* P_StartTimer_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs)
{
    timer_thread = std::thread([timer_flag, context, argRefs]() {
        PRT_VALUE* PTMP_tmp10 = NULL;

        PRT_VALUE** P_LVALUE_22 = &(PTMP_tmp10);
        PrtFreeValue(*P_LVALUE_22);
        *P_LVALUE_22 = PrtCloneValue((&P_EVENT_eTimeout.value));

        while(timer_flag)
        {
            std::this_thread::sleep_for(std::chrono::milliseconds(2000));

            PrtSendInternal(context, PrtGetMachine(context->process, context->id), PTMP_tmp10, 0);
        }
    });
}

PRT_VALUE* P_CancelTimer_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs)
{
    timer_flag = false;
    timer_thread.join();
}*/

PRT_VALUE* P_LandSystem_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs)
{
    _action->land_async([](mavsdk::Action::Result res){ 
        if(res == mavsdk::Action::Result::Success)
        {
        }
     });

    return PrtMkBoolValue((PRT_BOOLEAN)true);
}

PRT_VALUE* P_LandingState_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs)
{
    mavsdk::Telemetry::LandedState ls = _telemetry->landed_state();
    if(ls == mavsdk::Telemetry::LandedState::OnGround)
    {
        return PrtMkIntValue((PRT_INT)1);
    }

    return PrtMkIntValue((PRT_INT)0);
}

PRT_VALUE* P_DisarmSystem_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs)
{
    mavsdk::Action::Result res = _action->disarm(); 
    if(res == mavsdk::Action::Result::Success)
    {
        return PrtMkBoolValue((PRT_BOOLEAN)true);
    }

    return PrtMkBoolValue((PRT_BOOLEAN)false);
}