/*
 * File: fn_loadFaction.sqf
 * Author: Spoffy (original), jwoodruff40 (convert to rebel faction)
 * Description:
 *    Loads a faction definition file, converts as necessary to load Occ / Inv as a rebel faction
 * Params:
 *    _filepaths - Single or array of faction definition filepath
 * Returns:
 *    Namespace containing faction information
 * Example Usage:
 */

#include "..\script_component.hpp"
params [
	["_filepaths",[],["",[]]]
];

if (_filepaths isEqualType "") then {_filepaths = [_filepaths]};
if (count _filepaths == 0) then {Error("No filepaths provided.")};

private _dataStore = createHashMap;

private _fnc_saveToTemplate = {
	params ["_name", "_data"];

	private _enemyConfigIgnore = [
		"vehiclesGunBoats",
		"vehiclesPlanesLargeCAS",
		"vehiclesPlanesLargeAA",
		"vehiclesPlanesGunship",
		"vehiclesMilitiaTrucks",
		"vehiclesMilitiaLightArmed",
		"vehiclesMilitiaCars",
		"vehiclesCargoTrucks",
		"vehiclesAmmoTrucks",
		"vehiclesRepairTrucks",
		"vehiclesFuelTrucks",
		"vehiclesMedical",
		"vehiclesTanks",
		"vehiclesHelisTransport",
		"vehiclesPolice",
		"vehiclesHelisLightAttack",
		"staticHowitzers",
		"vehicleRadar",
		"vehicleSam",
		"vehiclesPlanesCAS",
		"vehiclesPlanesAA",
		"vehiclesArtillery",
		"vehiclesLightAPCs",
		"vehiclesAPCs",
		"vehiclesIFVs",
		"vehiclesLightTanks",
		"vehiclesAirborne",
		"vehiclesMilitiaAPCs"
	];

	private _enemyToRebelConfigMap = createHashmapFromArray [
	["mortarMagazineHE", "staticMortarMagHE"],
	["mortarMagazineSmoke", "staticMortarMagSmoke"],
	["mortarMagazineFlare", "staticMortarMagFlare"],
	["ATMines", "minesAT"],
	["APMines", "minesAPERS"],
	["lightExplosives", "breachingExplosivesAPC"],
	["heavyExplosives", "breachingExplosivesTank"],
	["vehiclesTransportBoats", "vehiclesBoat"],
	["vehiclesTrucks", "vehiclesTruck"],
	["vehiclesPlanesTransport", "vehiclesPlane"]
	];

	// * Use less OP (in early game) militia vehicles instead of regular faction vehicles
	private _militiaVehicles = ["vehiclesMilitiaTrucks", "vehiclesMilitiaLightArmed", "vehiclesMilitiaCars"];
	private _OPVehicles = ["vehiclesTrucks", "vehiclesLightUnarmed", "vehiclesLightArmed"];
	//if (!allowFMOPVehicles) then {
	if (true) then {
		_enemyConfigIgnore = _enemyConfigIgnore - _militiaVehicles + _OPVehicles;
		_enemyToRebelConfigMap deleteAt "vehiclesTrucks";
		{ _enemyToRebelConfigMap set _x } forEach [["vehiclesMilitiaTrucks", "vehiclesTruck"], ["vehiclesMilitiaLightArmed", "vehiclesLightArmed"], ["vehiclesMilitiaCars", "vehiclesLightUnarmed"]];
	};
	
	if (_name in _enemyConfigIgnore) exitWith {};

	if (_name in keys _enemyToRebelConfigMap) then {
		_dataStore set [_enemyToRebelConfigMap get _name, _data]
	} else {
		if (_name == "attributesVehicles") then {
			private _attributesVehicles = [];
			{
				private _cost = (_x select 1) select 1;
				_attributesVehicles pushBack [_x select 0, ["rebCost", _cost]];
			} forEach (_data);
			_data = _attributesVehicles;
		};

		_dataStore set [_name, _data]
	};
};

private _fnc_getFromTemplate = {
	params ["_name"];

	_dataStore get _name;
};

//Keep track of loadout namespaces so we can delete them when we're done.
private _loadoutNamespaces = [];
private _fnc_createLoadoutData = {
	private _namespace = createHashMap;
	_loadoutNamespaces pushBack _namespace;
	_namespace
};

private _fnc_copyLoadoutData = {
	params ["_sourceNamespace"];
    + _sourceNamespace //hashmaps deepcopy with +
};

private _allLoadouts = createHashMap;
_dataStore set ["loadouts", _allLoadouts];

private _fnc_saveUnitToTemplate = {
	params ["_typeName", "_loadouts", ["_traits", []], ["_unitProperties", []]];
	private _unitDefinition = [_loadouts, _traits, _unitProperties];
	_allLoadouts set [_typeName, _unitDefinition];
};

private _fnc_generateAndSaveUnitToTemplate = {
	params ["_name", "_template", "_loadoutData", ["_traits", []], ["_unitProperties", []]];
	private _loadouts = [];
	for "_i" from 1 to 5 do {
		_loadouts pushBack ([_template, _loadoutData] call A3A_fnc_loadout_builder);
	};
	[_name, _loadouts, _traits, _unitProperties] call _fnc_saveUnitToTemplate;
};

private _fnc_addStartingWeapon = {
	params ["_initialRebelEquipment", "_weapons"];

	private _minWeight = 1000;
	private ["_weapon", "_weaponMags", "_weaponAtts", "_weaponIndex"];
	{
		private _class = _x select 0;
		private _categories = _class call A3A_fnc_equipmentClassToCategories;
		private _weight = [_class, _categories] call A3A_fnc_itemArrayWeight;
		if (_weight < _minWeight) then {
			_minWeight = _weight;
			_weapon = _class;
			_weaponMags = _x select 4;
			_weaponAtts = (flatten [_x select 1, _x select 2, _x select 3, _x select 6]) select {_x isEqualType "" && {_x != ""}};
			_weaponIndex = _forEachIndex;
		};
	} forEach (_weapons select {_x isEqualType []});

	_initialRebelEquipment pushBackUnique _weapon;
	_initialRebelEquipment append _weaponMags;
	{ _initialRebelEquipment pushBackUnique [_x, [3 min minWeaps, 5] select (minWeaps < 0)]; } forEach _weaponAtts;
	_weapons deleteAt _weaponIndex;
};

private _fnc_generateAndSaveUnitsToTemplate = {
	// * Overwrite this function because we don't want to pointlessly generate a bunch of loadouts
	// * Instead, use the call to this function to populate faction equipment into rebel initial equipment (weapons, mostly)
	params ["_prefix", "_unitTemplates", "_loadoutData"];
	private _initialRebelEquipment = _dataStore getOrDefault ["initialRebelEquipment", [], true];
	
	// * We only want to iterate through loadoutdata once, so we only get the equipment from the highest tier (e.g. if we populate IRE from sfLoadoutData, we don't want to add equipment from eliteLoadoutData, etc)
	if (_initialRebelEquipment isNotEqualTo []) exitWith {};

	// * petros and rebel recruits need at least *some* unlimited weapon at game start. SF SMGs / shotguns not defined in all templates, and they don't use handguns (currently)
	// * YES, I know it looks ridiculous to have a full squad of level 1 rebels rocking barrets, but giving an unlimited assault rifle at start is just too OP 
	// * Need to do this before iterating through the rest of the loadoutdata so our selected weapon isn't already added as a limited weapon
	[_initialRebelEquipment, _loadoutData get "sniperRifles"] call _fnc_addStartingWeapon;

	{
		private _headgear = _dataStore getOrDefault ["headgear", [], true];
		private _items = (flatten _y) select {_x isEqualType "" && {_x != ""}}; // remove empties and weights
		_items = _items arrayIntersect _items; // remove duplicates

		private _unlimitedLoadoutItemTypes = [
			"maps",
			"watches",
			"compasses",
			"binoculars",
			"items_medical_basic",
			"items_medical_standard",
			"items_medical_medic",
			"items_miscEssentials",
			"items_engineer_extras",
			"items_marksman_extras",
			"uniforms",
			"traitorUniforms",
			"officerUniforms",
			"glasses",
			"goggles"
		];

		private _unlimitedItemTypes = [
			"antiInfantryGrenades",
			"smokeGrenades",
			"sidearms"
		];

		if (_x in _unlimitedLoadoutItemTypes) then {
			_dataStore set [_x, _items];
			_initialRebelEquipment append _items;
			continue
		} else {
			if (_x in _unlimitedItemTypes) then {
				_initialRebelEquipment append _items;
				continue
			};
		};
		
		{
			private _categories = _x call A3A_fnc_equipmentClassToCategories;

			switch true do {
				case ("Disposable" in _categories): {
					private _ammo = getArray (configFile >> "CfgWeapons" >> _x >> "Magazines") select 0;
					_initialRebelEquipment pushBackUnique [_x, [3 min minWeaps, 5] select (minWeaps < 0)];
					_initialRebelEquipment pushBackUnique [_ammo, [3 min minWeaps, 5] select (minWeaps < 0)];
				};
				case ("Weapons" in _categories): {
					// * Add a random compatible mag for this weapon to the items list if one isn't defined (and thus added to IRE) by the faction template
					private _potentialMags = _items select [_forEachIndex + 1, 4];
					private _compatMags = compatibleMagazines _x;
					if (count (_potentialMags arrayIntersect _compatMags) isEqualTo 0) then {
						_items pushBackUnique (selectRandom _compatMags)
					};

					_initialRebelEquipment pushBackUnique [_x, [3 min minWeaps, 5] select (minWeaps < 0)]
				};
				case ("Grenades" in _categories);
				case ("MagSmokeShell" in _categories);
				case ("Explosives" in _categories);
				case ("MagMissile" in _categories);
				case ("MagRocket" in _categories): { _initialRebelEquipment pushBackUnique [_x, [3 min minWeaps, 5] select (minWeaps < 0)] };
				case ("Magazines" in _categories): {
					private _magCap = getNumber (configFile >> "CfgMagazines" >> _x >> "count");
					_initialRebelEquipment pushBackUnique [_x, [20*_magCap min minWeaps*_magCap, 25*_magCap] select (minWeaps < 0)];
				};
				case ("Vests" in _categories && {!("ArmoredVests" in _categories)});
				case ("Backpacks" in _categories && {!("BackpacksCargo" in _categories)}): { _initialRebelEquipment pushBackUnique _x };
				case ("Headgear" in _categories && {!("ArmoredHeadgear" in _categories)}): { _initialRebelEquipment pushBackUnique _x; _headgear pushBackUnique _x };
				default { _initialRebelEquipment pushBackUnique [_x, [3 min minWeaps, 5] select (minWeaps < 0)] };
			};
		} forEach _items;
	} forEach _loadoutData;

	if (A3A_hasTFAR) then {_initialRebelEquipment append ["tf_microdagr","tf_anprc154"]};
	if (A3A_hasTFAR && startWithLongRangeRadio) then {_initialRebelEquipment append ["tf_anprc155","tf_anprc155_coyote"]};
	if (A3A_hasTFARBeta) then {_initialRebelEquipment append ["TFAR_microdagr","TFAR_anprc154"]};
	if (A3A_hasTFARBeta && startWithLongRangeRadio) then {_initialRebelEquipment append ["TFAR_anprc155","TFAR_anprc155_coyote"]};
	_initialRebelEquipment append ["Chemlight_blue","Chemlight_green","Chemlight_red","Chemlight_yellow"];
};

private _fnc_generateAndSaveRebelUnitsToTemplate = {
	params ["_prefix", "_unitTemplates", "_loadoutData"];
	{
		_x params ["_name", "_template", ["_traits", []], ["_unitProperties", []]];
		private _finalName = format ["%1_%2", _prefix, _name];
		[_finalName, _template, _loadoutData, _traits, _unitProperties] call _fnc_generateAndSaveUnitToTemplate;
	} forEach _unitTemplates;
};

private _fnc_saveNames = {
    params ["_names"];
    private _nameConfig = configfile >> "CfgWorlds" >> "GenericNames" >> _names;
    private _firstNames = configProperties [_nameConfig >> "FirstNames"] apply { getText(_x) };
    ["firstNames", _firstNames] call _fnc_saveToTemplate;
    private _lastNames = configProperties [_nameConfig >> "LastNames"] apply { getText(_x) };
    ["lastNames", _lastNames] call _fnc_saveToTemplate;
};

{
	call compile preprocessFileLineNumbers _x;
} forEach _filepaths;

// * overrides
// _dataStore set ["flagMarkerType", "flag_FIA"];
_dataStore set ["convertedToRebel", true];
{ _dataStore set [_x, []]; } forEach ["vehiclesCivHeli", "vehiclesCivPlane", "vehiclesCivTruck", "vehiclesCivCar", "vehiclesCivBoat", "vehiclesMedical", "vehiclesAT", "vehiclesAA"];

////////////////////////
//  Rebel Unit Types  //
///////////////////////.

private _petrosTemplate = {
	["officerUniforms"] call _fnc_setUniform;
    [selectRandomWeighted [[], 1.25, "glasses", 1, "goggles", 0.75, "facemask", 1, "balaclavas", 1, "argoFacemask", 1 , "facewearWS", 0.75, "facewearContact", 0.3, "facewearLawsOfWar", 0.5, "facewearGM", 0.3, "facewearCLSA", 0.2,"facewearSOG", 0.3,"facewearSPE", 0.2]] call _fnc_setFacewear;

    ["items_medical_standard"] call _fnc_addItemSet;
    ["items_miscEssentials"] call _fnc_addItemSet;

    ["maps"] call _fnc_addMap;
    ["watches"] call _fnc_addWatch;
    ["compasses"] call _fnc_addCompass;
    ["binoculars"] call _fnc_addBinoculars;
};

private _rebelSquadLeaderTemplate = {
    ["uniforms"] call _fnc_setUniform;
    [selectRandomWeighted [[], 1.25, "glasses", 1, "goggles", 0.75, "facemask", 1, "balaclavas", 1, "argoFacemask", 1 , "facewearWS", 0.75, "facewearContact", 0.3, "facewearLawsOfWar", 0.5, "facewearGM", 0.3, "facewearCLSA", 0.2,"facewearSOG", 0.3,"facewearSPE", 0.2]] call _fnc_setFacewear;

    ["items_medical_standard"] call _fnc_addItemSet;
    ["items_miscEssentials"] call _fnc_addItemSet;

    ["maps"] call _fnc_addMap;
    ["watches"] call _fnc_addWatch;
    ["compasses"] call _fnc_addCompass;
    ["binoculars"] call _fnc_addBinoculars;
};

private _rebelRiflemanTemplate = {
    ["uniforms"] call _fnc_setUniform;
    [selectRandomWeighted [[], 1.25, "glasses", 1, "goggles", 0.75, "facemask", 1, "balaclavas", 1, "argoFacemask", 1 , "facewearWS", 0.75, "facewearContact", 0.3, "facewearLawsOfWar", 0.5, "facewearGM", 0.3, "facewearCLSA", 0.2, "facewearSOG", 0.3,"facewearSPE", 0.2]] call _fnc_setFacewear;
    
    ["items_medical_standard"] call _fnc_addItemSet;
    ["items_miscEssentials"] call _fnc_addItemSet;

    ["maps"] call _fnc_addMap;
    ["watches"] call _fnc_addWatch;
    ["compasses"] call _fnc_addCompass;
};

private _prefix = "militia";
private _unitTypes = [
    ["Petros", _petrosTemplate],
    ["SquadLeader", _rebelSquadLeaderTemplate],
    ["Rifleman", _rebelRiflemanTemplate],
    ["staticCrew", _rebelRiflemanTemplate],
    ["Medic", _rebelRiflemanTemplate, [["medic", true]]],
    ["Engineer", _rebelRiflemanTemplate, [["engineer", true]]],
    ["ExplosivesExpert", _rebelRiflemanTemplate, [["explosiveSpecialist", true]]],
    ["Grenadier", _rebelRiflemanTemplate],
    ["LAT", _rebelRiflemanTemplate],
    ["AT", _rebelRiflemanTemplate],
    ["AA", _rebelRiflemanTemplate],
    ["MachineGunner", _rebelRiflemanTemplate],
    ["Marksman", _rebelRiflemanTemplate],
    ["Sniper", _rebelRiflemanTemplate],
    ["Unarmed", _rebelRiflemanTemplate]
];

[_prefix, _unitTypes, _dataStore] call _fnc_generateAndSaveRebelUnitsToTemplate;


_dataStore
