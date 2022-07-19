machine Drone
{
    var fc: FlightController;
    start state Init 
    {
        entry 
        {
            fc = new FlightController(this);
        }
    }
}