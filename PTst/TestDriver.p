machine Drone
{
    var fc: FlightController;
    start state Init 
    {
        entry 
        {
            SetDeterminism(true);
            fc = new FlightController((f = 1, d = this));
        }
    }
}

machine NonDetDrone
{
    var fc: FlightController;
    start state Init 
    {
        entry
        {
            SetDeterminism(false);
            fc = new FlightController((f = 1, d = this));
        }
    }
}