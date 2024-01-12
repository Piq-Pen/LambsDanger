#include "script_component.hpp"
/*
 * Author: ThomasAngel
 * Gets all units from a group that have launchers.
 * Things like AP launchers, flares etc will not count, -
 * launcher must be capable of destroying at least some vehicle.
 *
 * Checking through the submunitions might improve mod compatibility,
 * but only if the AI actually accounts for submunitions when evaluating -
 * whether to engage or not. As of writing, this is unknown.
 *
 * Disposable launchers get mostly ignored, AI doesn't seem to even use them.
 *
 * Arguments:
 * 0: Group to search in <GROUP>
 * 1: Check through submunitions <BOOLEAN>
 *
 * Return Value:
 * Array - units with launchers
 *
 * Example:
 * [group bob] call lambs_main_fnc_getLauncherUnits;
 *
 * Public: Yes
*/

#define LIGHT_VEHICLE "128"
#define AIR_VEHICLE "256"
#define HEAVY_VEHICLE "512"

params [
    ["_group", grpNull, [grpNull]],
    ["_checkSubmunition", false, [false]],
    ["_offensiveVeh", true, [true]],
    ["_offensiveAir", true, [true]],
    ["_offensiveArmor", true, [true]]
];

private _suitableUnits = [];
{
    if ((secondaryWeapon _x) isEqualTo "") then {continue};
    private _currentUnit = _x;

    private _unitsMagazines = (magazines _x) + (secondaryWeaponMagazine _x);
    {
        private _mainAmmo = getText (configFile >> "cfgMagazines" >> _x >> "ammo");
        private _mainAmmoFlags = getText (configFile >> "cfgAmmo" >> _mainAmmo >> "aiAmmoUsageFlags");

        if (
            (_offensiveVeh && (LIGHT_VEHICLE in _mainAmmoFlags))
            || {_offensiveAir && (AIR_VEHICLE in _mainAmmoFlags)}
            || {_offensiveArmor && (HEAVY_VEHICLE in _mainAmmoFlags)}
        ) exitWith {_suitableUnits pushBackUnique _currentUnit};

        // Optionally go through submunitions. More info in header.
        if !(_checkSubmunition) then {continue}; // Invert & continue to reduce indentation

        private _submunition = getText (configFile >> "cfgAmmo" >> _mainAmmo >> "submunitionAmmo");
        if (_submunition isEqualTo "") then {continue};
        private _submunitionFlags = getText (configFile >> "cfgAmmo" >> _submunition >> "aiAmmoUsageFlags");

        if (
            (_offensiveVeh && (LIGHT_VEHICLE in _submunitionFlags))
            || {_offensiveAir && (AIR_VEHICLE in _submunitionFlags)}
            || {_offensiveArmor && (HEAVY_VEHICLE in _submunitionFlags)}
        ) exitWith {_suitableUnits pushBackUnique _currentUnit};
    } forEachReversed _unitsMagazines;
    // We iterate back to front for performance, because _unitsMagazines is structured -
    // as follows: uniform magazines -> vest magazines -> backpack magazines, and -
    // launcher ammo is usually in the backpack. This is a ~3-4x speedup.
} forEach (units _group);

_suitableUnits
