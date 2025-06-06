/*
    Fully equips a rebel infantry unit based on their class and unlocked gear

Parameters:
    0. <OBJECT> Unit to equip
    1. <NUMBER> Recruit type: 0 recruit, 1 HC squad, 2 garrison. Doesn't currently have any effect

Returns:
    Nothing

Environment:
    Scheduled, any machine
*/

#include "..\script_component.hpp"
FIX_LINE_NUMBERS()

params ["_unit", "_recruitType", ["_forceClass", ""]];

call A3A_fnc_fetchRebelGear;        // Send current version of rebelGear from server if we're out of date

// TODO: add types unitAA and unitAT(name?) when UI is ready
private _unitType = if (_forceClass != "") then {_forceClass} else {_unit getVariable "unitType"};
private _customLoadout = rebelLoadouts get _unitType;

if (!isNil "_customLoadout") exitWith {
    private _goggles = goggles _unit;
	if (randomizeRebelLoadoutUniforms) then {
		_unit setUnitLoadout _customLoadout;

		_unit forceAddUniform (selectRandom (A3A_faction_reb get "uniforms"));
		{_unit addItemToUniform _x} forEach (uniformItems _unit);

		private _headgear = headgear _unit;

		//if it isn't a helmet - randomize
		if !(_headgear in allArmoredHeadgear) then {
			_unit addHeadgear (selectRandom (A3A_faction_reb get "headgear"));
		};
	} else {
		_unit setUnitLoadout _customLoadout;
	};

    if (goggles _unit != _goggles && {randomizeRebelLoadoutUniforms}) then {
        removeGoggles _unit;
        _unit addGoggles _goggles;
    };

    _unit linkItem (selectRandom (A3A_faction_reb get "compasses"));
	_unit linkItem (selectRandom (A3A_faction_reb get "maps"));
	_unit linkItem (selectRandom (A3A_faction_reb get "watches"));
	if (haveRadio) then {_unit linkItem (selectRandom (A3A_faction_reb get "radios"))};

	if (( _unit getVariable "unitType") isEqualTo FactionGet(reb,"unitExp")) then {
		_unit enableAIFeature ["MINEDETECTION", true]; //This should prevent them from Stepping on the Mines as an "Expert" (It helps, they still step on them)
	};
};

private _fnc_addSecondaryAndMags = {
    params ["_unit", "_weapon", "_totalMagWeight"];

    _unit addWeapon _weapon;
    private _magazine = compatibleMagazines _weapon select 0;
    _unit addSecondaryWeaponItem _magazine;

    if ("Disposable" in (_weapon call A3A_fnc_equipmentClassToCategories)) exitWith {};
    private _magWeight = 20 max getNumber (configFile / "CfgMagazines" / _magazine / "mass");
    _unit addMagazines [_magazine, round (random 0.5 + _totalMagWeight / _magWeight)];

    private _compatOptics = A3A_rebelOpticsCache get _weapon;
    if (isNil "_compatOptics") then {
        private _compatItems = compatibleItems _weapon; // cached, should be fast
        _compatOptics = _compatItems arrayIntersect (A3A_rebelGear get "OpticsAll");
        A3A_rebelOpticsCache set [_weapon, _compatOptics];
    };
    if (_compatOptics isNotEqualTo []) then { _unit addSecondaryWeaponItem (selectRandom _compatOptics) };
};

private _fnc_addCharges = {
    params ["_unit", "_totalWeight"];

    private _charges = A3A_rebelGear get "ExplosiveCharges";
    if (_charges isEqualTo []) exitWith {};

    private _weight = 0;
    while { _weight < _totalWeight } do {
        private _charge = selectRandomWeighted _charges;
        _weight = _weight + getNumber (configFile / "CfgMagazines" / _charge / "mass");
        _unit addItemToBackpack _charge;
    };
};

// * Add random 
private _unitIsGuerilla = _recruitType isNotEqualTo 0 && 
    {A3A_faction_reb getOrDefault ["convertedToRebel", false] && 
    {!(A3A_faction_civ getOrDefault ["attributeLowCiv", false] || {A3A_faction_civ getOrDefault ["attributeCivNonHuman", false]})}};
if (_unitIsGuerilla) then {
    private _items = uniformItems _unit;
    _unit forceAddUniform selectRandom (A3A_faction_civ get "uniforms");
    { _unit addItemToUniform _x } forEach _items;
    [_unit, [A3A_faction_civ, ""] call A3A_fnc_createRandomIdentity] call A3A_fnc_setIdentity;
};

private _radio = selectRandomWeighted (A3A_rebelGear get "Radios");
if (!isNil "_radio") then {_unit linkItem _radio};

private _helmet = selectRandomWeighted (A3A_rebelGear get "ArmoredHeadgear");
if (_helmet == "") then { 
    _helmet = selectRandom ([A3A_faction_reb, A3A_faction_civ] select (_unitIsGuerilla) get "headgear")
};
_unit addHeadgear _helmet;

private _vest = selectRandomWeighted (A3A_rebelGear get "ArmoredVests");
if (_vest == "") then { _vest = selectRandomWeighted (A3A_rebelGear get "CivilianVests") };
_unit addVest _vest;

private _backpack = selectRandomWeighted (A3A_rebelGear get "BackpacksCargo");
if !(isNil "_backpack") then { _unit addBackpack _backpack };

private _smokes = A3A_rebelGear get "SmokeGrenades";
if (_smokes isNotEqualTo []) then { _unit addMagazines [selectRandomWeighted _smokes, 1] };
private _grenades = A3A_rebelGear get "Grenades";
if (_grenades isNotEqualTo []) then { _unit addMagazines [selectRandomWeighted _grenades, 1] };

switch (true) do {
    case (_unitType isEqualTo FactionGet(reb,"unitSniper")): {
        [_unit, "SniperRifles", 50] call A3A_fnc_randomRifle;
    };
    case (_unitType isEqualTo FactionGet(reb,"unitRifle")): {
        [_unit, "Rifles", 70] call A3A_fnc_randomRifle;
        if (_grenades isNotEqualTo []) then { _unit addMagazines [selectRandomWeighted _grenades, 2] };
        if (_smokes isNotEqualTo []) then { _unit addMagazines [selectRandomWeighted _smokes, 1] };

        // increase likelihood of rifleman getting a disposable launcher by war level (10% chance * war level)
        if (random 10 < (tierWar / 2)) then {
            private _rlaunchers = A3A_rebelGear get "RocketLaunchers";
            private _launcherPool = [];
            
            {
                private _categories = _x call A3A_fnc_equipmentClassToCategories;

                if ("Disposable" in _categories) then {_launcherPool append [_x, _rlaunchers select (_rlaunchers find _x) + 1 ]};
            } forEach (_rlaunchers select {_x isEqualType ""});

            private _launcher = selectRandomWeighted _launcherPool;
            if !(isNil "_launcher") then { [_unit, _launcher, 100] call _fnc_addSecondaryAndMags };
        };
    };
    case (_unitType isEqualTo FactionGet(reb,"unitMG")): {
        [_unit, "MachineGuns", 150] call A3A_fnc_randomRifle;
    };
    case (_unitType isEqualTo FactionGet(reb,"unitGL")): {
        [_unit, "GrenadeLaunchers", 50] call A3A_fnc_randomRifle;
    };
    case (_unitType isEqualTo FactionGet(reb,"unitExp")): {
        [_unit, "Rifles", 40] call A3A_fnc_randomRifle;

        _unit enableAIFeature ["MINEDETECTION", true]; //This should prevent them from Stepping on the Mines as an "Expert" (It helps, they still step on them)

        private _mineDetector = selectRandomWeighted (A3A_rebelGear get "MineDetectors");
        if !(isNil "_mineDetector") then { _unit addItem _mineDetector };

        private _toolkit = selectRandomWeighted (A3A_rebelGear get "Toolkits");
        if !(isNil "_toolkit") then { _unit addItem _toolkit };

        [_unit, 50] call _fnc_addCharges;
    };
    case (_unitType isEqualTo FactionGet(reb,"unitEng")): {
        [_unit, "Rifles", 50] call A3A_fnc_randomRifle;

        private _toolkit = selectRandomWeighted (A3A_rebelGear get "Toolkits");
        if !(isNil "_toolkit") then { _unit addItem _toolkit };

        [_unit, 50] call _fnc_addCharges;
    };
    case (_unitType isEqualTo FactionGet(reb,"unitMedic")): {
        [_unit, "SMGs", 40] call A3A_fnc_randomRifle;
        if (_smokes isNotEqualTo []) then { _unit addMagazines [selectRandomWeighted _smokes, 2] };

        // not-so-temporary hack
        private _medItems = [];
        {
            for "_i" from 1 to (_x#1) do { _medItems pushBack (_x#0) };
        } forEach (["MEDIC",independent] call A3A_fnc_itemset_medicalSupplies);
        {
            _medItems deleteAt (_medItems find _x);
        } forEach items _unit;
        {
            _unit addItemToBackpack _x;
        } forEach _medItems;
    };
    case (_unitType isEqualTo FactionGet(reb,"unitLAT")): {
        [_unit, "Rifles", 40] call A3A_fnc_randomRifle;

        private _launcher = selectRandomWeighted (A3A_rebelGear get "RocketLaunchers");
        if !(isNil "_launcher") then { [_unit, _launcher, 100] call _fnc_addSecondaryAndMags };
    };
    case (_unitType isEqualTo FactionGet(reb,"unitAT")): {
        [_unit, "Rifles", 40] call A3A_fnc_randomRifle;

        private _launcher = selectRandomWeighted (A3A_rebelGear get "MissileLaunchersAT");
        if !(isNil "_launcher") then { [_unit, _launcher, 100] call _fnc_addSecondaryAndMags };
    };
    case (_unitType isEqualTo FactionGet(reb,"unitAA")): {
        [_unit, "Rifles", 40] call A3A_fnc_randomRifle;

        private _launcher = selectRandomWeighted (A3A_rebelGear get "MissileLaunchersAA");
        if !(isNil "_launcher") then { [_unit, _launcher, 100] call _fnc_addSecondaryAndMags };
    };
    case (_unitType isEqualTo FactionGet(reb,"unitAT")): {
        [_unit, "Rifles", 40] call A3A_fnc_randomRifle;

        private _launcher = selectRandomWeighted (A3A_rebelGear get "MissileLaunchersAT");
        if !(isNil "_launcher") then { [_unit, _launcher, 100] call _fnc_addSecondaryAndMags };
    };
    case (_unitType isEqualTo FactionGet(reb,"unitAA")): {
        [_unit, "Rifles", 40] call A3A_fnc_randomRifle;

        private _launcher = selectRandomWeighted (A3A_rebelGear get "MissileLaunchersAA");
        if !(isNil "_launcher") then { [_unit, _launcher, 100] call _fnc_addSecondaryAndMags };
    };
    case (_unitType isEqualTo FactionGet(reb,"unitSL")): {
        [_unit, "Rifles", 50] call A3A_fnc_randomRifle;
        if (_smokes isNotEqualTo []) then { _unit addMagazines [selectRandomWeighted _smokes, 2] };
    };
     case (_unitType isEqualTo FactionGet(reb,"unitCrew")): {
        [_unit, "Rifles", 50] call A3A_fnc_randomRifle;
    };
    default {
        [_unit, "SMGs", 50] call A3A_fnc_randomRifle;
        Error_1("Unknown unit class: %1", _unitType);
    };
};

private _handgun = selectRandomWeighted (A3A_rebelGear get "Handguns");
if !(isNil "_handgun") then { [_unit, "Handguns"] call A3A_fnc_randomHandgun;};

private _nvg = selectRandomWeighted (A3A_rebelGear get "NVGs");
if (_nvg != "") then { 
    _unit linkItem _nvg;
    private _weapon = primaryWeapon _unit;
    private _compatLasers = A3A_rebelLasersCache get _weapon;
    if (isNil "_compatLasers") then {
        private _compatItems = compatibleItems _weapon; // cached, should be fast
        _compatLasers = _compatItems arrayIntersect (A3A_rebelGear get "LaserAttachments");
        A3A_rebelLasersCache set [_weapon, _compatLasers];
    };
    if (_compatLasers isNotEqualTo []) then {
        private _LaserAttachment = selectRandom _compatLasers;
        _unit addPrimaryWeaponItem _LaserAttachment;		// should be used automatically by AI as necessary
    };
    private _weaponsecondary = secondaryWeapon _unit;
    private _compatSecondaryLasers = A3A_rebelLasersCache get _weaponsecondary;
    if (isNil "_compatSecondaryLasers") then {
        private _compatItems = compatibleItems _weaponsecondary; // cached, should be fast
        _compatSecondaryLasers = _compatItems arrayIntersect (A3A_rebelGear get "LaserAttachments");
        A3A_rebelLasersCache set [_weaponsecondary, _compatSecondaryLasers];
    };
    if (_compatSecondaryLasers isNotEqualTo []) then {
        private _LaserAttachment = selectRandom _compatSecondaryLasers;
        _unit addSecondaryWeaponItem _LaserAttachment;		// should be used automatically by AI as necessary
    };
    private _weaponhandgun = handgunWeapon _unit;
    private _compatHandgunLasers = A3A_rebelLasersCache get _weaponhandgun;
    if (isNil "_compatHandgunLasers") then {
        private _compatItems = compatibleItems _weaponhandgun; // cached, should be fast
        _compatHandgunLasers = _compatItems arrayIntersect (A3A_rebelGear get "LaserAttachments");
        A3A_rebelLasersCache set [_weaponhandgun, _compatHandgunLasers];
    };
    if (_compatHandgunLasers isNotEqualTo []) then {
        private _LaserAttachment = selectRandom _compatHandgunLasers;
        _unit addHandgunItem _LaserAttachment;		// should be used automatically by AI as necessary
    };
} else {
    private _weapon = primaryWeapon _unit;
    private _compatLights = A3A_rebelFlashlightsCache get _weapon;
    if (isNil "_compatLights") then {
        private _compatItems = compatibleItems _weapon; // cached, should be fast
        _compatLights = _compatItems arrayIntersect (A3A_rebelGear get "LightAttachments");
        A3A_rebelFlashlightsCache set [_weapon, _compatLights];
    };
    if (_compatLights isNotEqualTo []) then {
        private _flashlight = selectRandom _compatLights;
        _unit addPrimaryWeaponItem _flashlight;		// should be used automatically by AI as necessary
    };
    private _weaponsecondary = secondaryWeapon _unit;
    private _compatSecondaryLights = A3A_rebelFlashlightsCache get _weaponsecondary;
    if (isNil "_compatSecondaryLights") then {
        private _compatItems = compatibleItems _weaponsecondary; // cached, should be fast
        _compatSecondaryLights = _compatItems arrayIntersect (A3A_rebelGear get "LightAttachments");
        A3A_rebelFlashlightsCache set [_weaponsecondary, _compatSecondaryLights];
    };
    if (_compatSecondaryLights isNotEqualTo []) then {
        private _flashlight = selectRandom _compatSecondaryLights;
        _unit addSecondaryWeaponItem _flashlight;		// should be used automatically by AI as necessary
    };
    private _weaponhandgun = handgunWeapon _unit;
    private _compatHandgunLights = A3A_rebelFlashlightsCache get _weaponhandgun;
    if (isNil "_compatHandgunLights") then {
        private _compatItems = compatibleItems _weaponhandgun; // cached, should be fast
        _compatHandgunLights = _compatItems arrayIntersect (A3A_rebelGear get "LightAttachments");
        A3A_rebelFlashlightsCache set [_weaponhandgun, _compatHandgunLights];
    };
    if (_compatHandgunLights isNotEqualTo []) then {
        private _flashlight = selectRandom _compatHandgunLights;
        _unit addHandgunItem _flashlight;		// should be used automatically by AI as necessary
    };
};


// remove backpack if empty, otherwise squad troops will throw it on the ground
if (backpackItems _unit isEqualTo []) then { removeBackpack _unit };

Verbose_3("Class %1, type %2, loadout %3", _unitType, _recruitType, str (getUnitLoadout _unit));
