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
  start state Init 
  {
    entry (fm: machine) 
    {
        failMachine = fm;
        goto FailOneMonitor;
    }
  }

  state FailOneMonitor
  {
    entry 
    {
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
      }

      goto FailOneMonitor;
    }
  }
}
