test CheckDroneState [main = Drone] : 
        assert DroneModesOfOperation, LivenessMonitor in union { Drone }, FlightController, Communication;

test FailDroneState [main = FailureDrone] : 
        assert DroneModesOfOperation, LivenessMonitor in union { FailureDrone }, FlightController, Communication, FailureInjector;