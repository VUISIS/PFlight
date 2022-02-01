test CheckDroneState [main = Drone] : 
        assert DroneModesOfOperation, LivenessMonitor in (union Hardware, Communication );

test NonDetCheckDroneState [main = NonDetDrone] : 
        assert DroneModesOfOperation, LivenessMonitor in (union NonDetHardware, Communication );