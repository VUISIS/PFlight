#include <mavsdk/mavsdk.h>
#include <mavsdk/plugins/calibration/calibration.h>
#include <mavsdk/plugins/action/action.h>
#include <mavsdk/plugins/telemetry/telemetry.h>
#include <future>
#include <iostream>

using namespace mavsdk;
using std::chrono::seconds;

static std::function<void(Calibration::Result, Calibration::ProgressData)>
create_calibration_callback(std::promise<void>&);

static void calibrate_accelerometer(Calibration&);

std::shared_ptr<System> get_system(Mavsdk& mavsdk)
{
    std::cout << "Waiting to discover system...\n";
    auto prom = std::promise<std::shared_ptr<System>>{};
    auto fut = prom.get_future();

    // We wait for new systems to be discovered, once we find one that has an
    // autopilot, we decide to use it.
    mavsdk.subscribe_on_new_system([&mavsdk, &prom]() {
        auto system = mavsdk.systems().back();

        if (system->has_autopilot()) {
            std::cout << "Discovered autopilot\n";

            // Unsubscribe again as we only want to find one system.
            mavsdk.subscribe_on_new_system(nullptr);
            prom.set_value(system);
        }
    });

    // We usually receive heartbeats at 1Hz, therefore we should find a
    // system after around 3 seconds max, surely.
    if (fut.wait_for(seconds(3)) == std::future_status::timeout) {
        std::cerr << "No autopilot found.\n";
        return {};
    }

    // Get discovered system now.
    return fut.get();
}

int main(int argc, char** argv)
{
    Mavsdk mavsdk;
    ConnectionResult connection_result = mavsdk.add_any_connection("serial:///path/to/serial/dev[:baudrate]");

    if (connection_result != ConnectionResult::Success) {
        std::cerr << "Connection failed: " << connection_result << '\n';
        return 1;
    }

    auto system = get_system(mavsdk);
    if (!system) {
        return 1;
    }

    auto telemetry = Telemetry{system};

    telemetry.subscribe_battery([](Telemetry::Battery battery) {
        std::cout << "Battery: " << battery.remaining_percent << " m\n";
    }););

    telemetry.subscribe_health_all_ok([](bool hao) {
        std::cout << "Health All Ok: " << hao << " m\n";
    }););

    auto action = Action{system};

    std::cout << "Setting actuator...\n";
    const Action::Result set_actuator_result = action.set_actuator(0, 1.0f);

    if (set_actuator_result != Action::Result::Success) {
        std::cerr << "Setting actuator failed:" << set_actuator_result << '\n';
        return 1;
    }

    // Instantiate plugin.
    auto calibration = Calibration(system);

    // Run calibrations
    calibrate_accelerometer(calibration);

    return 0;
}

void calibrate_accelerometer(Calibration& calibration)
{
    std::cout << "Calibrating accelerometer...\n";

    std::promise<void> calibration_promise;
    auto calibration_future = calibration_promise.get_future();

    calibration.calibrate_accelerometer_async(create_calibration_callback(calibration_promise));

    calibration_future.wait();
}

std::function<void(Calibration::Result, Calibration::ProgressData)>
create_calibration_callback(std::promise<void>& calibration_promise)
{
    return [&calibration_promise](
               const Calibration::Result result, const Calibration::ProgressData progress_data) {
        switch (result) {
            case Calibration::Result::Success:
                std::cout << "--- Calibration succeeded!\n";
                calibration_promise.set_value();
                break;
            case Calibration::Result::Next:
                if (progress_data.has_progress) {
                    std::cout << "    Progress: " << progress_data.progress << '\n';
                }
                if (progress_data.has_status_text) {
                    std::cout << "    Instruction: " << progress_data.status_text << '\n';
                }
                break;
            default:
                std::cout << "--- Calibration failed with message: " << result << '\n';
                calibration_promise.set_value();
                break;
        }
    };
}