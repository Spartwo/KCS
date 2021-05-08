//***********************************/
//*		   Warship Control		    */
//*				  -					*/
//*   © Sigma Technologies - 2042   */
//*        © JT Halco. - 2050       */
//***********************************/
//	Author : Spartwo  -  License : GNU GPL 3.0


if ship:type <> "Ship"
{
    print "─────────────────────────────".
    print "Incompatible Script Type".
    print "Cannot Proceed".
    print "Please Set Vessel Type to SHIP".
    print "─────────────────────────────".
    wait until ship:type = "Ship".
    CLEARSCREEN.
}


toggle AG10.
GetData().
GetBeacon().


MultiCoring().

core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
set Terminal:WIDTH to 40.
set Terminal:HEIGHT to 60.
print "╔═════════════════════════════════╗".
print "║        Warship Control          ║".
print "║             v0.01               ║".
print "║   © Sigma Technologies - 2050   ║".
print "║       © Hal Co. - 2050          ║".
print "╚═════════════════════════════════╝".
wait 2.

//***Manual Override***
set ManControl to false.
when KUniverse:ACTIVEVESSEL = Ship AND ManControl = true then { 
    unlock steering.
    unlock throttle.
    wait until KUniverse:ACTIVEVESSEL <> Ship. 
    lock steering to SteerTo.
    lock throttle to ShipThrottle.
    PRESERVE.
}

SetData().
GetTarget().
Movement().
Loop().

//************Core Process**************
function Loop {
    until Enemy:electriccharge < 1 OR Enemy:DISTANCE > MaxDis/2 {
        Readout().
        Defence().
        if beacon:type = "Station" OR beacon = ship {
            Set DriftSpeed to DriftSpeedGoal.
            when beacon:type = "Station" then { Repositon(Maxdis, Maxdis*0.8, 5, Beacon). }
            PewPew().
        } else {
            Set DriftSpeed to DriftSpeedGoal/5.
            print "─────────────────────────────".
            print "Awaiting Go Ahead from Beacon".
        }
        wait 0.1.
    }
    //Retarget and continue
    GetTarget().
    Loop().
}


 //************Readout Functions**************

function Readout {
    CLEARSCREEN.
    print "─────────────────────────────".
    print "Commanding : " + Ship:Name.
    print "─────────────────────────────".
    print "EC         : " + round(ship:electriccharge, 0).
    print "Fuel       : " + round((ship:MonoPropellant + ship:liquidfuel + ship:xenongas) / FuelCap, 2) * 100 + "%".
    set ShipTag TO VECDRAW(v(0,0,0), v(0,0,0), rgb(1,1,1), ship:name, 0.2, true, 1, true).
    if true { Debug(). }

}

function GetData {
    //Ship Data
    Global MaxDis is 15000.      //Range
    Global DriftSpeedGoal is 20. //Speed
    Global Withdraw is 0.        //Withdrawl
    Global DecoyInterval is 30.  //FI
    Global DecoyCluster is 1.    //FC
    local ShipSettingsParts to ship:partsnamed("SurfaceScanner").
    if (ShipSettingsParts:length > 0) {
        local settingsPart to ShipSettingsParts[0].
        for res in settingsPart:resources {
            if res:name = "KCSSpeed" {set DriftSpeedGoal to res:amount.}
            if res:name = "KCSWithdrawl" {set Withdraw to res:amount.}
            if res:name = "KCSFI" {set DecoyInterval to res:amount.}
            if res:name = "KCSFC" {set DecoyCluster to res:amount.}
        }
    }

    //Missile Info
    Global MissileMinRange is 1500. //NFR
    Global MissileMaxRange is 5000. //MFR
    Global MissileInterval is 15.   //FI
    Global MissileCluster is 1.     //FC
    Global MissileClusterInt is 0.  //CI
    local ShipSettingsParts to ship:partsnamed("sensorAccelerometer").
    if (ShipSettingsParts:length > 0) {
        local settingsPart to ShipSettingsParts[0].
        for res in settingsPart:resources {
            if res:name = "KCSNFR" {set MissileMinRange to res:amount.}
            if res:name = "KCSMFR" {set MissileMaxRange to res:amount.}
            if res:name = "KCSFI" {set MissileInterval to res:amount.}
            if res:name = "KCSFC" {set MissileCluster to res:amount.}
            if res:name = "KCSCI" {set MissileClusterInt to res:amount.}
        }
    }

    //Bombs Info
    Global BombReleaseRange is 1500. //Range
    Global BombMinRange is 1000.    //NFR
    Global BombMaxRange is 7500.    //MFR
    Global BombInterval is 10.//0.     //FI
    Global BombCluster is 2.        //FC
    Global BombVelocity is 100. //Speed
    local ShipSettingsParts to ship:partsnamed("sensorThermometer").
    if (ShipSettingsParts:length > 0) {
        local settingsPart to ShipSettingsParts[0].
        for res in settingsPart:resources {
            if res:name = "KCSRange" {set BombReleaseRange to res:amount.}
            if res:name = "KCSNFR" {set BombMinRange to res:amount.}
            if res:name = "KCSMFR" {set BombMaxRange to res:amount.}
            if res:name = "KCSFI" {set BombInterval to res:amount.}
            if res:name = "KCSFC" {set BombCluster to res:amount.}
            if res:name = "KCSSpeed" {set BombVelocity to res:amount.}
        }
    }

    //Rocket Info
    Global RocketFunctionRange is 5000. //Range
    Global RocketMinRange is 50.        //NFR
    Global RocketMaxRange is 200.       //MFR
    Global RocketInterval is 15.        //FI
    Global RocketCluster is 1.          //FC
    Global RocketClusterInt is 1.       //CI
    local ShipSettingsParts to ship:partsnamed("sensorBarometer").
    if (ShipSettingsParts:length > 0) {
        local settingsPart to ShipSettingsParts[0].

        for res in settingsPart:resources {
            if res:name = "KCSRange" {set RocketFunctionRange to res:amount.}
            if res:name = "KCSNFR" {set RocketMinRange to res:amount.}
            if res:name = "KCSMFR" {set RocketMaxRange to res:amount.}
            if res:name = "KCSFI" {set RocketInterval to res:amount.}
            if res:name = "KCSFC" {set RocketCluster to res:amount.}
            if res:name = "KCSCI" {set RocketClusterInt to res:amount.}
        }
    }

    //Mass Cannon Info
    Global CannonFunctionRange is 1000. //Range
    Global CannonMinRange is 2500.      //NFR
    Global CannonMaxRange is 5000.      //MFR
    Global CannonInterval is 5.         //FI
    Global CannonCluster is 1.          //FC
    Global CannonClusterInt is 0.5.     //CI
    local ShipSettingsParts to ship:partsnamed("sensorGravimeter").
    if (ShipSettingsParts:length > 0) {
        local settingsPart to ShipSettingsParts[0].
        for res in settingsPart:resources {
            if res:name = "KCSRange" {set CannonFunctionRange to res:amount.}
            if res:name = "KCSNFR" {set CannonMinRange to res:amount.}
            if res:name = "KCSMFR" {set CannonMaxRange to res:amount.}
            if res:name = "KCSFI" {set CannonInterval to res:amount.}
            if res:name = "KCSFC" {set CannonCluster to res:amount.}
            if res:name = "KCSCI" {set CannonClusterInt to res:amount.}
        }
    }
}

function SetData {

    set SteerTo to -Beacon:position.
    lock steering to lookdirup(SteerTo,ship:facing:topvector).
    set ShipThrottle to 0.
    lock throttle to ShipThrottle.
    RCS on.
    SAS off.

    //***Automatically Set***
    Global FuelCap is (ship:MonoPropellant + ship:LiquidFuel + ship:XenonGas).

    Global PreviousMissile is Time-(RANDOM()*MissileInterval).
    Global PreviousRocket is Time-(RANDOM()*RocketInterval).
    Global PreviousBomb is Time-(RANDOM()*BombInterval).
    Global PreviousCannon is Time-(RANDOM()*CannonInterval).
    Global PreviousDecoy is Time-(RANDOM()*DecoyInterval).

    Global SafeDistance is Ship:BOUNDS:RELMAX:Mag*2.
    Global ColAvoidSafety is True.
    Global Enemy is SHIP. //for debugging without a target
    Global RepositionSafety is false.

    //***Parts Lists***
    Set MissileList1 to SHIP:PARTSTAGGED("Missile").
    Set MissileList2 to LIST().
    FOR EachPart IN MissileList1 { MissileList2:INSERT(0,EachPart).}

    Set RocketList1 to SHIP:PARTSTAGGED("Rocket").
    Set RocketList2 to LIST().
    FOR EachPart IN RocketList1 { RocketList2:INSERT(0,EachPart).}

    Set BombList1 to SHIP:PARTSTAGGED("Bomb").
    Set BombList2 to LIST().
    FOR EachPart IN BombList1 { BombList2:INSERT(0,EachPart).}

    Set CannonList1 to SHIP:PARTSTAGGED("Cannon").
    Set RoundList1 to SHIP:PARTSTAGGED("Round").
    Set RoundList2 to LIST().
    FOR EachPart IN RoundList1 { RoundList2:INSERT(0,EachPart).}

    Set DecoyList1 to SHIP:PARTSTAGGED("Decoy").
    Set DecoyList2 to LIST().
    FOR EachPart IN DecoyList1 { DecoyList2:INSERT(0,EachPart).}

    Set InterceptList1 to SHIP:PARTSTAGGED("Intercept").
    Set InterceptList2 to LIST().
    FOR EachPart IN InterceptList1 { InterceptList2:INSERT(0,EachPart).}

    print "Data Set".
}

function MultiCoring {
    set Primary to Core.
    List Processors in AICores.
    FOR EachPart IN AICores {
        if (EachPart:BOOTFILENAME = core:BOOTFILENAME) AND (EachPart:part:cid > Primary:part:cid) { set Primary to EachPart. }
    }
    IF Primary:part:cid <> Core:part:cid {
        wait UNTIL (Primary:part:ship <> Core:part:ship).
        PrimaryCore().
    }
}


 //************Targetting Functions**************

function GetBeacon {
    //Sets the nearest station entity as a beacon to fight around
    list targets in trgtList.
    local Beaconlist is list().
    for trgt in trgtList {
    if (trgt:type = "Station" OR trgt:type = "Base") AND trgt:distance < 30000
        {
        Beaconlist:ADD(trgt).
        Global Beacon is trgt.
        break.
        }
    }
    if Beaconlist:LENGTH < 1 {
        print "─────────────────────────────".
        print "No Beacon Provided".
        print "Anchoring to Self".
        Global Beacon is Ship.
    }
}

function GetTarget {
    CLEARSCREEN.
    list targets in trgtList.
    local scanlist is list().
    for trgt in trgtList {
    if trgt:type = "Ship" AND trgt:distance < MaxDis AND trgt:electriccharge > 0 AND trgt:NAME:STARTSWITH(SHIP:NAME:SUBSTRING(0,5)) = False
        {
        scanlist:ADD(trgt).
	    print "Scanning : " + trgt:name.
        print "Mass     : " + round(trgt:mass, 2) + "t".
        wait 0.01.
        }
    }
    //if no viable targets are found the script will enter a holding loop until one is
    if Scanlist:LENGTH = 0 {
        Set DriftSpeed to DriftSpeedGoal/10.
        Readout().
        Movement().
        if Beacon <> Ship { ZeroVelocity(Beacon).}
        print "─────────────────────────────".
        print "No Targets Provided".
        print "Holding Position around " + Beacon:Name.
        wait 0.1.
        GetTarget().
    }

    //Once a viable target is found the driftspeed is reset and data is based around
    for trgt in scanList
    {
        Global Enemy is trgt.
        Set DriftSpeed to DriftSpeedGoal.
        toggle AG9.
        EnemyMessage("Hello Enemy").
        break.
    }
}


 //************Movement Functions**************

function Movement {
    local lock RelativeVelocityVec to ship:velocity:orbit - Beacon:velocity:orbit.
    local lock BeaconRelCheck to VANG(ship:position - beacon:position , -RelativeVelocityVec).
    //When ship fuel is below 5% drift speed is overwritten for conservation
    WHEN ((ship:MonoPropellant + ship:LiquidFuel + ship:XenonGas) / FuelCap) < 0.05 THEN { Set DriftSpeed to DriftSpeedGoal/10. }
    //Triggers any time the craft leaves the designated beacon range
    WHEN Beacon:Distance > MaxDis/2 AND BeaconRelCheck > 45 THEN { 
        CLEARSCREEN.
        Set ColAvoidSafety to false.
        print "─────────────────────────────".
        Print "Out of Bounds".
        Print "Moving Inwards".
        Print ROUND(Beacon:Distance,0) + "m " + "/ " + MaxDis/2 + "m".
        Repositon(MaxDis*0.45, MaxDis*0.4, DriftSpeed, Beacon).
        Set ColAvoidSafety to true.
        PRESERVE.
    }
}

function Repositon {
    Parameter TargetDistanceMax.
    Parameter TargetDistanceMin.
    Parameter RelativeVelocityGoal.
    Parameter TargetEntity.

    set ColAvoidSafety to false.
    lock TargetRelVel to ship:velocity:orbit - TargetEntity:velocity:orbit.
    lock TargetRelCheck to vang(ship:position - TargetEntity:position , -TargetRelVel).
    lock TargetRelativeSpeed to TargetRelVel:mag.
    
    //Points retrograde relative to the beacon and burns until a low speed is reached
    IF TargetRelativeSpeed > max(DriftSpeed/10,15) {
        lock SteerTo to -TargetRelVel.
        wait UNTIL vang(ship:facing:forevector,SteerTo) <2 AND ship:ANGULARVEL:mag < 0.1.
        set ShipThrottle to 1.
        wait UNTIL TargetRelativeSpeed < max(DriftSpeed/10,5).
        set ShipThrottle to 0.
    }

    
        //Points directly towards the centre and burns until the drift velocity is reached
        if TargetEntity:Distance > TargetDistanceMin { 
            set SteerTo to TargetEntity:position.
        } else { 
            set SteerTo to -TargetEntity:position. 
        }
    
        UNTIL TargetEntity:distance < TargetDistanceMax AND TargetEntity:distance > TargetDistanceMin { 
            UNTIL (TargetRelativeSpeed > DriftSpeed) {
                set adjustThrottle to 0.
                IF vectorAngle(ship:facing:vector, steerto) < 5 {
                    local targetRelVel to ship:velocity:orbit - enemy:velocity:orbit.
                    local targetVec to enemy:direction:vector.
                    set adjustThrottle to 1.
                    if false {
                        IF (vDot(targetRelVel:normalized, targetVec:normalized) > 0.9) {
                            IF (targetRelVel > RelativeVelocityGoal) {
                                set adjustThrottle to 0.
                            }
                        }
                    }
                }
                set ShipThrottle to adjustThrottle.
            }
            set shipthrottle to 0.
            lock SteerTo to -TargetRelVel.
        }

    IF TargetEntity:type = "ship" {
        //Points retrograde relative to the beacon and burns until a low speed is reached
        lock SteerTo to -TargetRelVel.
        wait UNTIL vang(ship:facing:forevector,SteerTo) <2 AND ship:ANGULARVEL:mag < 0.1.
        set ShipThrottle to 1.
        wait UNTIL TargetRelativeSpeed < RelativeVelocityGoal.
        set ShipThrottle to 0.
    }
    
    set ColAvoidSafety to true.
}

function ColAvoid {
    parameter Entity.
    if defined Entity {
        set RelativePosition to (ship:position - entity:position).

        if (RelativePosition:mag > 100) AND (ColAvoidSafety = True) {
            CLEARSCREEN.
            print "─────────────────────────────".
            print "Avoiding Impact".
            Set ColAvoidSafety to False.
            local lock RelativeVelocityVec to ship:velocity:orbit - entity:velocity:orbit.
            local lock MissileRelCheck to vang(ship:position - entity:position , -RelativeVelocityVec).

            set ShipThrottle to 1.

            local avoidVector to vxcl(RelativePosition, ship:facing:vector).
            set SteerTo to avoidVector.

            Wait until entity:distance < 100 OR MissileRelCheck > 5.

            set shipthrottle to 0.
            set SteerTo to ship:facing:starVector.
            Set ColAvoidSafety to True.
        }
    }
}

function ZeroVelocity {
    parameter Entity.

    lock TargetRelativeVelocity to ship:velocity:orbit - Entity:velocity:orbit.
    IF TargetRelativeVelocity:mag > 5 { 
        set SteerTo to -TargetRelativeVelocity.
        wait UNTIL vang(ship:facing:forevector,SteerTo) <2 AND ship:ANGULARVEL:mag < 0.1.
        set ShipThrottle to 1.
        wait UNTIL TargetRelativeSpeed < max(DriftSpeed/10,5).
    }
    set steerto to entity:position.
    set ShipThrottle to 0.
    until TargetRelativeVelocity:mag < 1 { Translate(-targetRelativeVelocity). }
    Translate(v(0,0,0)).
}

function Translate {
  PARAMETER vector.
  IF vector:MAG > 1 SET vector TO vector:normalized.

  SET SHIP:CONTROL:STARBOARD  TO vector * SHIP:FACING:STARVECTOR.
  SET SHIP:CONTROL:FORE       TO vector * SHIP:FACING:FOREVECTOR.
  SET SHIP:CONTROL:TOP        TO vector * SHIP:FACING:TOPVECTOR.
}



 //************Firing Functions**************

function PewPew {
    print "─────────────────────────────".
    IF RocketList1:LENGTH > 0 { print "Rockets   : " + RocketList2:LENGTH + "/" + RocketList1:LENGTH. }
    IF MissileList1:LENGTH > 0 { print "Missiles   : " + MissileList2:LENGTH + "/" + MissileList1:LENGTH. }
    IF BombList1:LENGTH > 0 { print "Bombs   : " + BombList2:LENGTH + "/" + BombList1:LENGTH. }
    IF RoundList1:LENGTH > 0 { print "Rounds   : " + RoundList2:LENGTH + "/" + RoundList1:LENGTH. }
    IF InterceptList1:LENGTH > 0 { print "Interceptors   : " + InterceptList2:LENGTH + "/" + InterceptList1:LENGTH. }
    print "Counters   : " + DecoyList2:LENGTH + "/" + DecoyList1:LENGTH.
    print "─────────────────────────────".
    print "Targetting : " + Enemy:Name.
    print "Distance   : " + round(Enemy:Distance, 2) + "m".

    //Checks that there are viable muntions left and acts appropriately
    WeaponSelect().
}

function WeaponSelect {
    Set TotalLength to (RocketList2:Length+MissileList2:Length+BombList2:Length+RoundList2:Length).
    if TotalLength = 0 { WithdrawCheck(). }
    Set RandomPick to RANDOM().
    Set Generic to (RocketList2:Length+RoundList2:Length).
    Set Specialised to (MissileList2:Length+BombList2:Length).

    IF TotalLength > 0 {
        IF RandomPick > Generic/TotalLength {
            IF RandomPick < MissileList2:Length/Specialised {
                IF (PreviousMissile + MissileInterval < Time) AND (Enemy:Distance < MissileMaxRange) AND (Enemy:Distance > MissileMinRange) {
                    print "Firing Guided Missile".
                    Decouple(MissileList2,MissileClusterInt,MissileCluster).
                    Set PreviousMissile to Time.
                }
            } ELSE {
                IF (PreviousBomb + BombInterval < Time) AND (Enemy:Distance < BombMaxRange) AND (Enemy:Distance > BombMinRange) AND RepositionSafety = False {
                    print "Starting Bombing Run".
                    EnemyMessage("True").
                    BombingRun().
                    Decouple(BombList2,0,BombCluster).
                    BomberAvoid().
                    EnemyMessage("False").
                    Set PreviousBomb to Time.
                }
            }
        } ELSE {
            IF RandomPick < RocketList2:Length/Generic {
                IF (PreviousRocket + RocketInterval < Time) AND (Enemy:Distance < RocketFunctionRange) AND RepositionSafety = False {
                    print "Moving to Position".
                    EnemyMessage("True").
                    Repositon(RocketMaxRange, RocketMinRange, 5, Enemy). 
                    ZeroVelocity(Enemy).
                    RCS off.
                    wait UNTIL vang(ship:facing:forevector,SteerTo) <1 AND ship:ANGULARVEL:mag < 0.1.
                    print "Firing Rockets".
                    Decouple(RocketList2,RocketClusterInt,RocketCluster).
                    EnemyMessage("False").
                    RCS on.
                    Set PreviousRocket to Time.
                }
            } ELSE {
                IF (PreviousCannon + CannonInterval < Time) AND (Enemy:Distance < CannonFunctionRange) AND RepositionSafety = False {
                    print "Moving to Position".
                    EnemyMessage("True").
                    Repositon(CannonMaxRange, CannonMinRange, 5, Enemy).
                    ZeroVelocity(Enemy). 
                    RCS off.
                    wait UNTIL vang(ship:facing:forevector,SteerTo) <1 AND ship:ANGULARVEL:mag < 0.1.
                    print "Firing Mass Cannon".
                    FOR EachPart in CannonList1 { EachPart:Activate(). }
                    set ShipThrottle to 1.
                    Decouple(RoundList2,CannonClusterInt,CannonCluster).
                    wait 0.5.
                    set ShipThrottle to 0.
                    FOR EachPart in CannonList1 { EachPart:Shutdown(). }
                    EnemyMessage("False").
                    RCS on.
                    Set PreviousCannon to Time.
                }
            }
        }
            set RelativePosition to (ship:position - enemy:position).
            local TiltVector to vxcl(RelativePosition, ship:facing:vector).
            set SteerTo to TiltVector.
    }
}


//************Defence Functions**************

function Defence {
    WHEN NOT SHIP:MESSAGES:EMPTY THEN {
        set RECEIVED to SHIP:MESSAGES:POP.
        IF RECEIVED:CONTENT = "Incoming" {
            set Avoid to VESSEL(RECEIVED:SENDER:NAME).
            ColAvoid( Avoid ).
        } ELSE IF RECEIVED:CONTENT = "Targetted" {
            print "─────────────────────────────".
            print "Deploying Active Counters".
            Decouple(InterceptList2,0,1).
        } ELSE IF RECEIVED:CONTENT = "Hello Enemy" {
            set Enemy to VESSEL(RECEIVED:SENDER:NAME).
            toggle AG9.
        } ELSE IF RECEIVED:CONTENT = "True" {
            set RepositionSafety to True.
        } ELSE IF RECEIVED:CONTENT = "False" {
            set RepositionSafety to False.
        } ELSE {
            set MaxDis to RECEIVED:CONTENT.
        }
        Translate(v(0,0,0)).
        PRESERVE.
    }

    IF ( PreviousDecoy + DecoyInterval ) < Time AND DecoyList2:LENGTH > 0 {
        Decouple(DecoyList2,0,DecoyCluster).
        print "─────────────────────────────".
        print "Releasing Decoy".
        set PreviousDecoy to Time.
    }
}

function WithdrawCheck {
    IF Withdraw = 0  {
        Set Escapelist to SHIP:PARTSTAGGED("Escape").
        FOR EachPart IN Escapelist { EachPart:GetModule("ModuleDecouple"):Doevent("decouple"). }
    } ELSE {
        CLEARSCREEN.
        print "─────────────────────────────".
        Print "Withdrawing From Battle".
        set SteerTo to -Beacon:position.
        wait UNTIL vang(ship:facing:forevector,SteerTo) <2 AND ship:angularvel:mag < 0.1.

            FOR EachPart IN DecoyList2 { 
                IF EachPart:SHIP = SHIP {
                    IF ( EachPart:getmodule("ModuleDecouple"):hasevent("decouple") = True ) { EachPart:GetModule("ModuleDecouple"):Doevent("decouple"). }
                } 
            }

            SAS on.
            set ShipThrottle to 1.
            wait 50*(Ship:Mass/Ship:AvailableThrust).
            toggle AG10.
            set ShipThrottle to 0.
            wait UNTIL false.
    }
}

 //************Helper Functions**************

function EnemyMessage {
        parameter message.

        set MESSAGE to message.
        set C to Enemy:CONNECTION.
        print "─────────────────────────────".
        IF C:SENDMESSAGE(MESSAGE) { print "Enemy Pinged at " + Enemy:Distance + "m". }
}



function Decouple {
    parameter Type.
    parameter Int.
    parameter Cluster.
    //Runs through all decouplers with the Missile tag and chooses one to decouple
    FOR i IN range(Cluster) {
        IF Type:LENGTH = 0 { BREAK. }
        IF Type = RocketList2 { FireWeapon(Type[0]). }
        IF Type[0]:SHIP = SHIP {
            IF ( Type[0]:getmodule("ModuleDecouple"):hasevent("decouple") = True ) {
                Type[0]:GetModule("ModuleDecouple"):Doevent("decouple").
            }
        }
        Type:REMOVE(0).
        wait Int.
    }
}

function FireWeapon {
    parameter ThisPart.
    set children to ThisPart:children.
    IF not children:empty {
        FOR child in children { FireWeapon(child). }
    }
    IF ThisPart:SHIP = SHIP {
        IF ThisPart:istype("Engine") { ThisPart:ACTIVATE().}
    }
}

function Debug {
	set VecVel TO VECDRAW(v(0,0,0), (ship:velocity:orbit-beacon:velocity:orbit)*5, rgb(0.5,1,0.5),"", 0.2, true, 1, true).
	set VecBea TO VECDRAW(v(0,0,0), beacon:position, rgb(0.5,0.8,0.5),"", 0.2, true, 1, true).
	set VecTar TO VECDRAW(v(0,0,0), enemy:position, rgb(0.8,0.5,0.5),"", 0.2, true, 1, true).
	set VecTV TO VECDRAW(v(0,0,0), (ship:velocity:orbit-enemy:velocity:orbit)*5, rgb(1,0.5,0.5),"", 0.2, true, 1, true).
}

//*************HatBattery*****************

function calculateCorrection {
    local bombingTargetVec to enemy:position - ship:position.
    local bombingTargetRelativeVelocity to ship:velocity:orbit - enemy:velocity:orbit.

    set drawTargetPositionTarget to bombingTargetVec.
    set drawTargetRelVelTarget to bombingTargetRelativeVelocity.

    if (vectorAngle(bombingTargetVec, bombingTargetRelativeVelocity) > 67.5) {
        if (bombingTargetRelativeVelocity:mag > 5) {
            print "─────────────────────────────".
            print "Killing velocity.".

            return bombingTargetRelativeVelocity * -1.
        } else {
            print "Burning directly to target.".

            return bombingTargetVec.
        }
    } else {
        local bombingTargetRelativeVelocityNrm to bombingTargetRelativeVelocity:normalized.
        local bombingTargetVecNrm to bombingTargetVec:normalized.

        local correctionRotationPlane to vcrs(bombingTargetRelativeVelocityNrm, bombingTargetVecNrm).

        local currentAcceleration to max(ship:availableThrust / ship:mass, 20).
        local correctionRatio to max((-0.2 + (bombingTargetRelativeVelocity:mag / currentAcceleration)) * 1.5, 0).

        local correctionAngle to min(vectorAngle(bombingTargetRelativeVelocityNrm, bombingTargetVecNrm) * correctionRatio, 67.5).

        if true {
            clearScreen.
            print "─────────────────────────────".
            print "CurrentAcceleration : " + currentAcceleration.
            print "CorrectionRatio     : " + correctionRatio.
            print "VectorAngle         : " + vectorAngle(bombingTargetRelativeVelocityNrm, bombingTargetVecNrm).
            print "correctionAngle     :" + correctionAngle.
        }

        return (angleAxis(correctionAngle, correctionRotationPlane) * bombingTargetVec:direction):vector.
    }
}


//	Author : HatBat  -  License : GNU GPL 3.0
// All sections below are HatBat

function BombingRun {
    Set ColAvoidSafety to False.
    lock SteerTo to calculateCorrection().

    if true {
        set drawSteeringTarget to vecDraw( { return ship:controlPart:position. }, { return (steering:vector)*100. }, red, "", 1.0, true, 0.2, true, true).

        set drawTargetPositionTarget to v(0,0,0).
        set drawTargetPosition to vecDraw( { return ship:controlPart:position. }, { return drawTargetPositionTarget. }, magenta, "", 1.0, true, 0.2, true, true).

        set drawTargetRelVelTarget to v(0,0,0).
        set drawTargetRelVel to vecDraw( { return ship:controlPart:position. },  { return drawTargetRelVelTarget. }, green, "", 1.0, true, 0.2, true, true).
    }

    set ShipThrottle to 0.

    until (enemy:position - ship:position):mag < BombReleaseRange {
        set adjustThrottle to 0.
        

        IF vectorAngle(ship:facing:vector, steering:vector) < 5 {
            local targetRelVel to ship:velocity:orbit - enemy:velocity:orbit.
            local targetVec to enemy:direction:vector.

            set adjustThrottle to 0.5.
            IF (vDot(targetRelVel:normalized, targetVec:normalized) > 0.999) {
                IF (vDot(targetRelVel, targetVec) > BombVelocity) {
                    set adjustThrottle to 0.
                }
                IF (targetRelVel:MAG > BombVelocity+5) {
                    Translate(-targetRelVel).
                }
            }
        }
        
        set ShipThrottle to adjustThrottle.
    }
    
    set ShipThrottle to 0.
}

function BomberAvoid {
    Translate(-(ship:velocity:orbit - enemy:velocity:orbit)).
    wait 2.
    Translate(v(0,0,0)).

    local pitchUp to angleAxis(-30, ship:facing:starVector).
    local overshoot to pitchUp * ship:facing.
    set SteerTo to overshoot:vector.

    until vang((ship:velocity:orbit - enemy:velocity:orbit), enemy:direction:vector) > 15 {
        if vectorAngle(ship:facing:vector, SteerTo) < 5 { set ShipThrottle to 1. }
        else {set ShipThrottle to 0.}
    }

    set ShipThrottle to 0.
    Set ColAvoidSafety to True.
}
