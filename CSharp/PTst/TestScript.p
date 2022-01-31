test CheckDroneState [main = Drone] : 
        assert DroneModesOfOperation, GuaranteedProgress in (union Hardware, Communication );

test NonDetCheckDroneState [main = NonDetDrone] : 
        assert DroneModesOfOperation, GuaranteedProgress in (union NonDetHardware, Communication );