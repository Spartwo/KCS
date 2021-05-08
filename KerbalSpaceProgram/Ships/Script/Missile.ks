//***********************************/
//*		   Combat Control		    */
//*				  -					*/
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
    if trgt:type = "Ship" AND trgt:distance < MaxDis AND trgt:NAME:STARTSWITH(SHIP:NAME:SUBSTRING(0,5)) = false
        {
            Global Enemy is trgt.
            lock steering to enemy:position.
            TargetWarn().
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

function Terminal {
    set MESSAGE to "Incoming".
    set C to Enemy:CONNECTION.
    IF C:SENDMESSAGE(MESSAGE) { print "Target Pinged at " + DetectionRange + "m". }
}

function TargetWarn {
    set MESSAGE to "Targetted".
    set C to Enemy:CONNECTION.
    IF C:SENDMESSAGE(MESSAGE) { print "Target Warned". }
}


//	Author : HatBat  -  License : GNU GPL 3.0
// All sections below are HatBat

function Guidance {

// Calculate torque of the missile.

local missileTorque to 0.

local FuelCap is (ship:MonoPropellant + ship:LiquidFuel + ship:XenonGas).

local reactionWheelModules to ship:modulesNamed("ModuleReactionWheel").

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
    set missileTorque to missileTorque + reactionWheelTorque.
}


// Calculate moment of inertia.

local missileMass to ship:mass.

local missileBounds to ship:bounds.
local missileLength to missileBounds:relMax:z - missileBounds:relMin:z.

local RMOI to 1/12 * missileMass * missileLength^2.


// Calculate rotational power and adjust PID.

local missileRotationMultiplier to missileTorque / RMOI.

print "Length: " + missileLength.
print "Mass: " + missileMass.
print "RMOI: " + RMOI.
print "Torque: " + missileTorque.
print "Multiplier: " + missileRotationMultiplier.

local pidProportional to 2.05839 * missileRotationMultiplier.
local pidIntegral to 0.01143 * missileRotationMultiplier.
local pidDerivative to 0.34306 * missileRotationMultiplier.

print "Proportional: " + pidProportional.
print "Integral: " + pidIntegral.
print "Derivative: " + pidDerivative.

set steeringManager:pitchPID:KP to pidProportional.
set steeringManager:yawPID:KP to pidProportional.
set steeringManager:pitchPID:KI to pidIntegral.
set steeringManager:yawPID:KI to pidIntegral.
set steeringManager:pitchPID:KD to pidDerivative.
set steeringManager:yawPID:KD to pidDerivative.


// Calculate correction vector to bring target prograde over target position.

local calculateCorrection to {
    parameter missile, missileTarget.

    local targetVec to missileTarget:position - missile:controlPart:position.
    local targetRelativeVelocity to missile:velocity:orbit - missileTarget:velocity:orbit.

    set drawTargetPositionTarget to targetVec.
    set drawTargetRelVelTarget to targetRelativeVelocity.

    if (vectorAngle(targetVec, targetRelativeVelocity) > 67.5) {
        if (targetRelativeVelocity:mag > 5) {
            return targetRelativeVelocity * -1.
        } else {
            return targetVec.
        }
    } else {
        local targetRelativeVelocityNrm to targetRelativeVelocity:normalized.
        local targetVecNrm to targetVec:normalized.

        local correctionRotationPlane to vcrs(targetRelativeVelocityNrm, targetVecNrm).

        set drawTargetCRSTarget to correctionRotationPlane.

        local currentAcceleration to max(missile:availableThrust / missile:mass, 20).
        local correctionRatio to max((-0.2 + (targetRelativeVelocity:mag / currentAcceleration)) * 1.333, 0).

        local correctionAngle to min(vectorAngle(targetRelativeVelocityNrm, targetVecNrm) * correctionRatio, 67.5).

        if false {
            clearScreen.
            print "currentAcceleration: " + currentAcceleration.
            print "correctionRatio: " + correctionRatio.
            print "vectorAngle: " + vectorAngle(targetRelativeVelocityNrm, targetVecNrm).
            print "correctionAngle: " + correctionAngle.
        }

        return (angleAxis(correctionAngle, correctionRotationPlane) * targetVec:direction):vector.
    }
}.

SAS off.
local aegisMissileRoll to ship:facing:topVector.
lock steering to lookDirUp(calculateCorrection(ship, enemy), aegisMissileRoll).


// Draw vectors for debugging.

if false {
    set drawSteeringTarget to vecDraw( { return ship:controlPart:position. }, { return (steering:vector)*100. }, red, "", 1.0, true, 0.2, true, true ).

    set drawTargetPositionTarget to v(0,0,0).
    set drawTargetPosition to vecDraw( { return ship:controlPart:position. }, { return drawTargetPositionTarget. }, magenta,  "", 1.0, true, 0.2, true, true ).

    set drawTargetRelVelTarget to v(0,0,0).
    set drawTargetRelVel to vecDraw( { return ship:controlPart:position. }, { return drawTargetRelVelTarget. }, green, "", 1.0, true, 0.2, true, true).

    set drawTargetCRSTarget to v(0,0,0).
    set drawTargetCRS to vecDraw( { return ship:controlPart:position. }, { return drawTargetCRSTarget. }, blue, "", 1.0, true, 0.2, true, true).
}

local missileSpeedLimit to max((enemy:bounds:extents:mag * 0.666) / 0.02, 100).

until false {
    local targetRelVel to ship:velocity:orbit - enemy:velocity:orbit.
    local targetVec to enemy:direction:vector.

    if (ship:MonoPropellant + ship:liquidfuel + ship:xenongas) = 0 {
        lock steering to enemy:position.

        wait until vectorAngle(ship:facing:vector, enemy:position) < 2.

        SAS on.
        wait until false.
    }

    local adjustThrottle to 0.

    if vectorAngle(ship:facing:vector, steering:vector) < 2.5 {

        set adjustThrottle to 1.

        if (vDot(targetRelVel:normalized, targetVec:normalized) > 0.999999) {
            if (vDot(targetRelVel, targetVec) > missileSpeedLimit)  { set adjustThrottle to 0. }
        }
        
        if (enemy:distance / targetRelVel:mag) < 3  {
        Set Clusterlist to SHIP:PARTSTAGGED("Cluster").
        if Clusterlist:Length > 0 { FOR EachPart IN Clusterlist { EachPart:GetModule("ModuleDecouple"):Doevent("decouple"). } }
        set adjustThrottle to 0.
        }
        
    }

    set MissileThrottleTarget to adjustThrottle.
    
    Set DetectionRange to Ship:mass*5 * targetRelVel:mag.
    when Enemy:Distance < DetectionRange then { 
        Terminal().
        wait 15.
        IF FuelCap/3 < (ship:MonoPropellant + ship:LiquidFuel + ship:XenonGas) { PRESERVE. }
    }
    print "Detect Range: " + DetectionRange.
}

}