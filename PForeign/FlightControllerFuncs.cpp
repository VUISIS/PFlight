#include "FlightControllerFuncs.h"
#include "FlightSystem.h"

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

std::function<void (bool)> healthAllOK = [](bool health)
{
	_health = health;
};

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

	_telemetry = std::make_shared<mavsdk::Telemetry>(_system);

	_telemetry->subscribe_health_all_ok(healthAllOK);

	std::this_thread::sleep_for(std::chrono::seconds(1));

	return PrtMkBoolValue(PRT_TRUE);
}

// Reply foreign functions
PRT_VALUE* P_Arm_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs)
{
	return PrtMkNullValue();
}

PRT_VALUE* P_Takeoff_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs)
{
	return PrtMkNullValue();
}

PRT_VALUE* P_PublishTelemetryStatus_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs)
{
	PRT_MACHINEID m2Val = PrtPrimGetMachine((PRT_VALUE*)*argRefs[1]);
	PRT_MACHINEINST* machine = PrtGetMachine(context->process, PrtMkMachineValue(m2Val));
	
	PRT_VALUE* PTMP_tmp1_1 = NULL;

	PRT_VALUE** P_LVALUE_6 = &(PTMP_tmp1_1);
	PrtFreeValue(*P_LVALUE_6);
	*P_LVALUE_6 = PrtCloneValue(&P_EVENT_eRespTelemetryHealth.value);

	PrtSendInternal(context, machine, PTMP_tmp1_1, 1, PrtMkBoolValue((PRT_BOOLEAN)_health));

    return PrtMkNullValue();
}

// De-init foreign function
PRT_VALUE* P_Shutdown_IMPL(PRT_MACHINEINST* context, PRT_VALUE*** argRefs)
{				
	return PrtMkNullValue();
}