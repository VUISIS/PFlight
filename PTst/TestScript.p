test CheckDroneState [main = Drone] : 
        assert DroneModesOfOperation in (union Hardware, Communication );

test NonDetCheckDroneState [main = NonDetDrone] : 
        assert DroneModesOfOperation in (union NonDetHardware, Communication );