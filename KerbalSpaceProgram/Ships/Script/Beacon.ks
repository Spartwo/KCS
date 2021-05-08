//***********************************/
//*		   Combat Control		    */
//*				  -					*/
//*   © Sigma Technologies - 2042   */
//***********************************/
//	Author : Spartwo  -  License : GNU GPL 3.0


Global MaxDis is 15000.

//************Core Process**************
CLEARSCREEN.
if ship:type <> "Station" OR ship:type <> "Base" {
    set ship:type to "Base".
}
set ship:type to "Station".

core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
print "╔═════════════════════════════════╗".
print "║         Combat Control          ║".
print "║             v0.01               ║".
print "║   © Sigma Technologies - 2042   ║".
print "╚═════════════════════════════════╝".
wait 2.
set Terminal:WIDTH to 40.
set Terminal:HEIGHT to 60.

SetData().

until false {
on ag9 {
if ship:type = "Base" {set ship:type to "Station".}
else {set ship:type to "Base".}
preserve.
}
Readout().
GetTarget().
wait 5.
}


function Readout {
    if Ship:Type = "Base" {set Stat to "Stop".}
    if Ship:Type = "Station" {set Stat to "Go".}
    if Ship:Type <> "Base" { if Ship:Type <> "Station" {set Stat to "Invalid".} }

    CLEARSCREEN.
    print "─────────────────────────────".
    print "Status      : " + stat.
}

function GetTarget {
    scanlist:CLEAR.
    list targets in trgtList.
    for trgt in trgtList {
        if trgt:distance < MaxDis AND trgt:type = "ship" {
            scanlist:add(trgt).
            print "─────────────────────────────".
            print "Tracking    : " + trgt:name.
            print "Mass        : " + round(trgt:mass, 2) + "t".
            
            set MESSAGE to MaxDis.
            set C to trgt:CONNECTION.
            IF C:SENDMESSAGE(MESSAGE) { print "Combat Distance Relayed". }
        }
    }
    //if no viable entities are found the script will enter a holding loop until one is
    until scanlist:Length > 0 { 
        print "─────────────────────────────".
        print "No Entities Provided".
        wait 30. 
        CLEARSCREEN.
        GetTarget().
    }
    print "─────────────────────────────".
    print "Entities    : " + scanlist:length.
}

function SetData {
    set scanlist to list().
    //Set LoadDis to Max(2500,MaxDis*3).
    //SET KUNIVERSE:DEFAULTLOADDISTANCE:ORBIT:UNLOAD TO LoadDis+500.
    //SET KUNIVERSE:DEFAULTLOADDISTANCE:ORBIT:LOAD TO LoadDis.
    //WAIT 0.001.
    //SET KUNIVERSE:DEFAULTLOADDISTANCE:ORBIT:PACK TO LoadDis*1.3.
    //SET KUNIVERSE:DEFAULTLOADDISTANCE:ORBIT:UNPACK TO LoadDis*1.2.
 } 