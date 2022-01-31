machine Drone
{
    var fc: FlightController;
    start state Init 
    {
        entry 
        {
            fc = new FlightController((f = 1, d = this));
        }
    }
}