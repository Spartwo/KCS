//***********************************/
//*		       Combat Control		      */
//*			      	  -				         	*/
//*   © Sigma Technologies - 2042   */
//***********************************/
//	Author : Spartwo  -  License : GNU GPL 3.0

core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
print "╔═════════════════════════════════╗".
print "║         Escape Control          ║".
print "║             v0.01               ║".
print "║   © Sigma Technologies - 2042   ║".
print "╚═════════════════════════════════╝".
wait 2.
set Terminal:WIDTH to 30.
set Terminal:HEIGHT to 10.

 //************Core Process**************
CLEARSCREEN.
if ship:type <> "Lander"
{ 
    print "─────────────────────────────".
    print "Incompatible Script Type".
    print "Cannot Proceed".
    print "Please Set Vessel Type to LANDER".
    print "─────────────────────────────".
    wait until ship:type = "Lander".
}

set SteerTo to ship:facing:forevector.
lock steering to lookdirup(SteerTo,ship:facing:topvector).

if SHIP:OBT:BODY:ATM:EXISTS
  { 
    lock SteerTo to Ship:Retrograde:VECTOR.
    wait until vang(ship:facing:forevector,SteerTo) <2 AND ship:ANGULARVEL:mag < 0.1.
    Fire().
    Descent().
  }
  else
  {
    lock SteerTo to Ship:Prograde:VECTOR.
    wait until vang(ship:facing:forevector,SteerTo) <2 AND ship:ANGULARVEL:mag < 0.1.
    Fire().
  }


function Descent {
  lock SteerTo TO Ship:Prograde.
  Until ship:velocity:surface:MAG < 1
  {
    print "─────────────────────────────".
    print "Commanding : " + Ship:name.
    print "Velocity   : " + round(ship:velocity:surface:MAG,0) + "m/s".
    print "Altitude   : " + round(ALT:RADAR,0) + "m".
    print "─────────────────────────────".
    wait 1.
    CLEARSCREEN.

    when ALT:RADAR < 1500 then {
      CHUTES ON.
      for mod in ship:modulesnamed("ModuleDecouple") {
        if mod:hasevent("jettison heat shield") { mod:doevent("jettison heat shield"). }
      }
    }
  }
core:part:getmodule("kOSProcessor"):doevent("Close Terminal").
}

function Fire { 
  Print "Firing to escape".
  list engines in Enginelist.
  for eng in EngineList {
    eng:ACTIVATE().
  }
  lock throttle to 1.
  wait 10.
  lock throttle to 0.
}