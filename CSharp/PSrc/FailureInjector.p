/* 
    Fail by sending bad statuses through eTelemetryHealthAllOK.
*/

fun UnReliableSend(target: machine, message: event, payload: any, specEvent: event, specLoad: any) 
{
  // nondeterministically drop messages
  // $: choose()
  if($) 
  {
      announce specEvent, specLoad;
      send target, message, payload;
  }
}

machine FailureInjector 
{
  var rng: int;
  var failMachine: machine;
  var tick: int;
  var tickMax: int;
  start state Init 
  {
    entry (fm: machine) 
    {
        tick = 0;
        tickMax = choose(100000);
        failMachine = fm;
        goto FailOneMonitor;
    }
  }

  state FailOneMonitor
  {
    entry 
    {
      
    }
    on eLinkInitialized do 
    {
      while(tick < tickMax)
      {
        tick = tick + 1;
      }

      if($)
      {
        rng = choose(3);
        if(rng == 0)
        {
          send failMachine, eTelemetryHealthAllOK, false;
        }
        else if(rng == 1)
        {
          send failMachine, eBatteryRemaining, CRITICAL;
        }
        else
        {
          send failMachine, eSystemConnected, false;
        }

        raise halt;
      }
      else
      {
        tick = 0;
        send this, eLinkInitialized;
      }
    }
  }
}
