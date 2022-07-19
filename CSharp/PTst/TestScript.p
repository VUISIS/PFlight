test CheckDroneState [main = Drone] : 
        assert DroneModesOfOperation, LivenessMonitor in union { Drone }, FlightController, Communication;