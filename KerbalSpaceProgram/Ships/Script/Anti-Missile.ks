//***********************************/
//*		       Combat Control	  	    */
//*	         			  -		      			*/
//*   © Sigma Technologies - 2042   */
//*        © JT Halco. - 2050       */
//***********************************/
//	Author : Spartwo  -  License : GNU GPL 3.0

SetData().

if ship:type <> "Probe"  
{ 
    print "─────────────────────────────".
    print "Incompatible Script Type".
    print "Cannot Proceed".
    print "Please Set Vessel Type to PROBE".
    print "─────────────────────────────".
    wait until ship:type = "Probe" .
}

//core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
//set Terminal:WIDTH to 30.
//set Terminal:HEIGHT to 10.
print "╔═════════════════════════════════╗".
print "║        Missile Control          ║".
print "║             v0.01               ║".
print "║   © Sigma Technologies - 2042   ║".
print "║        © JT Halco. - 2050       ║".
print "╚═════════════════════════════════╝".
wait 2.
//core:part:getmodule("kOSProcessor"):doevent("Close Terminal").

// Pulse to leave firer.
Fire().
GetTarget().

function SetData {
    local ShipSettingsParts to ship:partsnamed("sensorAccelerometer").
    Global MaxDis is 5000.
    if (ShipSettingsParts:length > 0) {
        local settingsPart to ShipSettingsParts[0].
        for res in settingsPart:resources {
            if res:name = "KCSRange" {set MaxDis to res:amount.}
        }
    }
    print "Data Set".
} 

function GetTarget {
    CLEARSCREEN.
    list targets in trgtList.
    for trgt in trgtList {
    if trgt:type = "Probe" AND trgt:distance < MaxDis AND trgt:NAME:STARTSWITH(SHIP:NAME:SUBSTRING(0,5)) = false
        {
            Global missile is trgt.
            lock steering to enemy:position.
            Guidance().
            break.  
        }
    }
}

function Fire { 
list engines in EngineList.
for EachPart in EngineList { EachPart:Activate. }
core:PART:CONTROLFROM().

SAS on.
set MissileThrottleTarget to 0.5.
lock throttle to MissileThrottleTarget.
wait 0.1.
set MissileThrottleTarget to 0.
SAS off.
RCS on.
}





//	Author : HatBat  -  License : GNU GPL 3.0
// All sections below are HatBat

function Guidance {
// Get interceptor, incoming missile and the missile's target.

set interceptor to ship.
set missile to target.
set missileTarget to core:vessel.


// Decouple interceptor.

local interceptorCore to core:part.



wait 0.

local interceptor to core:vessel.
interceptorCore:controlFrom().


// Calculate torque of the interceptor.

local interceptorTorque to 0.

local reactionWheelModules to interceptor:modulesNamed("ModuleReactionWheel").

for reactionWheelModule in reactionWheelModules {
    local reactionWheelName to reactionWheelModule:part:name.
    local reactionWheelTorque to 0.5.
    local partNotFound to true.

    if (partNotFound) {
        if (reactionWheelName = "sasModule") {
            set reactionWheelTorque to 5.
            set partNotFound to false.
        }
    }

    if (partNotFound) {
        if ((reactionWheelName = "probeCoreHex.v2") or (reactionWheelName = "probeStackSmall")) {
            set reactionWheelTorque to 0.5.
            set partNotFound to false.
        }
    }

    if (partNotFound) {
        if (reactionWheelName = "probeCoreOcto.v2") {
            set reactionWheelTorque to 0.3.
            set partNotFound to false.
        }
    }

    if (partNotFound) {
        if (reactionWheelName = "advSasModule") {
            set reactionWheelTorque to 15.
            set partNotFound to false.
        }
    }

    if (partNotFound) {
        if (reactionWheelName = "probeStackLarge") {
            set reactionWheelTorque to 1.5.
            set partNotFound to false.
        }
    }

    if (partNotFound) {
        if (reactionWheelName = "HECS2.ProbeCore") {
            set reactionWheelTorque to 10.
            set partNotFound to false.
        }
    }

    if (partNotFound) {
        if (reactionWheelName = "asasmodule1-2") {
            set reactionWheelTorque to 30.
            set partNotFound to false.
        }
    }

    set reactionWheelTorque to reactionWheelTorque * (reactionWheelModule:getField("wheel authority") / 100).
    set interceptorTorque to interceptorTorque + reactionWheelTorque.
}


// Calculate moment of inertia.

local interceptorMass to interceptor:mass.

local interceptorBounds to interceptor:bounds.
local interceptorLength to interceptorBounds:relMax:z - interceptorBounds:relMin:z.

local RMOI to 1/12 * interceptorMass * interceptorLength^2.


// Calculate rotational power and adjust PID.

local interceptorRotationMultiplier to interceptorTorque / RMOI.

print "Length: " + interceptorLength.
print "Mass: " + interceptorMass.
print "RMOI: " + RMOI.
print "Torque: " + interceptorTorque.
print "Multiplier: " + interceptorRotationMultiplier.

local pidProportional to 2.05839 * interceptorRotationMultiplier.
local pidIntegral to 0.01143 * interceptorRotationMultiplier.
local pidDerivative to 0.34306 * interceptorRotationMultiplier.

print "Proportional: " + pidProportional.
print "Integral: " + pidIntegral.
print "Derivative: " + pidDerivative.

set steeringManager:pitchPID:KP to pidProportional.
set steeringManager:yawPID:KP to pidProportional.
set steeringManager:pitchPID:KI to pidIntegral.
set steeringManager:yawPID:KI to pidIntegral.
set steeringManager:pitchPID:KD to pidDerivative.
set steeringManager:yawPID:KD to pidDerivative.




// Draw vectors for debugging.

if true {
    clearVecDraws().

    set drawTargetPosition to vecDraw(
        { return missile:position. },
        { return missileTarget:position - missile:position. },
        red,
        "",
        1.0,
        true,
        0.2,
        true,
        true
    ).

    set drawIntercepterPosition to vecDraw(
        { return missile:position. },
        { return interceptor:position - missile:position. },
        magenta,
        "",
        1.0,
        true,
        0.2,
        true,
        true
    ).

    set drawIntercept to vecDraw(
        { return interceptor:position. },
        {
            local missileTargetPositionNrm to (missileTarget:position - missile:position):normalized.
            local interceptorPosition to interceptor:position - missile:position.
            local interceptPosition to missileTargetPositionNrm * interceptorPosition:mag.
            return interceptPosition - interceptorPosition.
        },
        blue,
        "",
        1.0,
        true,
        0.2,
        true,
        true
    ).

    set drawInterceptRvel to vecDraw(
        { return interceptor:position. },
        {
            return vectorExclude(missileTarget:position - missile:position, interceptor:velocity:orbit - missile:velocity:orbit).
        },
        green,
        "",
        1.0,
        true,
        0.2,
        true,
        true
    ).
}


// Move interceptor to intercept position.

local translateInterceptor to {
    local missileTargetPositionNrm to (missileTarget:position - missile:position):normalized.
    local interceptorPosition to interceptor:position - missile:position.
    local interceptPosition to missileTargetPositionNrm * interceptorPosition:mag.
    set interceptPosition to interceptPosition - interceptorPosition.

    local kP to 1.
    local kD to 1.

    local rVel to vectorExclude(missileTargetPositionNrm, interceptor:velocity:orbit - missile:velocity:orbit).

    if false {
        clearScreen.
        print "Starboard: " + (rVel * interceptor:facing:starVector).
        print "Fore: " + (rVel * interceptor:facing:foreVector).
        print "Top: " + (rVel * interceptor:facing:topVector).
    }

    set interceptor:control:starboard to kP * (interceptPosition * interceptor:facing:starVector) + kD * ((rVel * interceptor:facing:starVector) * -1).
    set interceptor:control:top to kP * (interceptPosition * interceptor:facing:topVector) + kD * ((rVel * interceptor:facing:topVector) * -1).

    if true {
        clearScreen.
        print "Starboard: " + interceptor:control:starboard.
        print "Top: " + interceptor:control:top.
        print "Error: " + interceptPosition:mag.
        print "rVel: " + rVel:mag.
    }
}.

local nearIntercept to {
    parameter threshhold is 0.6.

    local distanceToMissile to (interceptor:position - missile:position):mag.
    local relativeVelocity to (interceptor:velocity:orbit - missile:velocity:orbit):mag.
    return (distanceToMissile / relativeVelocity) < threshhold.
}.

until nearIntercept(1) {
    translateInterceptor().
}.

clearScreen.
print "Missile near intercept. Deploying shield.".

unlock steering.
SAS on.
lock throttle to 0.

set interceptor:control:fore to 0.
set interceptor:control:top to 0.
set interceptor:control:starboard to 0.


// Deploy 3 layers of panels from front and rear in sequence with 300 ms delay.


for i in range(3) {
    local panelTag to "Cluster" + (i + 1).

    local panelDecouplers to core:vessel:partsTaggedPattern(panelTag).
    local panelDecouplersReversed to list().
    for decoupler in panelDecouplers { panelDecouplersReversed:insert(0, decoupler). }

    when kUniverse:activeVessel <> activeVesselStart then {
        set kUniverse:activeVessel to activeVesselStart.
    }

    for decoupler in panelDecouplersReversed {
        decoupler:getModule("ModuleDecouple"):doEvent("decouple").
    }

    wait 0.3.
}


// Boost to cancel any velocity imparted on to the interceptor by the missile and avoid hitting friendly vessel.

local boosters to core:vessel:partsTaggedPattern("booster").
for thisBooster in boosters {
    thisBooster:getModule("ModuleEngines"):doEvent("activate engine").
}

}