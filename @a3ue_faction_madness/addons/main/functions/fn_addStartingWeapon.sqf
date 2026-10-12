#include "..\script_component.hpp"
FIX_LINE_NUMBERS()

waitUntil {sleep 0.1; !isNil {initVarServerCompleted}};

private _initialRebelEquipment = FactionGet(reb, "initialRebelEquipment");
private _rebelWeapons = (flatten _initialRebelEquipment) select {_x isEqualType "" && {_x in allWeapons}};

private _minWeight = 1000;
private _weapon = "";
{
	private _categories = _x call A3A_fnc_equipmentClassToCategories;
	if ((_categories arrayIntersect ["Handguns", "RocketLaunchers", "MissileLaunchers"]) isNotEqualTo []) then { continue };

	private _weight = [_x, ["PrimaryWeaponsCatchAll"]] call A3A_fnc_itemArrayWeight;
	if (_weight < _minWeight) then {
		_minWeight = _weight;
		_weapon = _x;
	};
	Debug_2("weapon %1 | weight %2", _x, _weight);
} forEach _rebelWeapons;

if (_weapon isEqualTo "") exitWith { false };

Debug_1("selected starting weapon %1", _weapon);

private _rebelMagazines = (flatten _initialRebelEquipment) select {_x isEqualType "" && {_x in allMagazines}};
private _compMagazines = compatibleMagazines _weapon;
private _rebelCompMagazines = _rebelMagazines arrayIntersect _compMagazines;
private _magazine = selectRandom ([_rebelCompMagazines, _compMagazines] select (_rebelCompMagazines isEqualTo []));

{
	private _item = _x;
	private _index = _initialRebelEquipment findIf {_x isEqualType [] && {(_x select 0) isEqualTo _item}};
	if (_index isNotEqualTo -1) then { _initialRebelEquipment deleteAt _index };
	_initialRebelEquipment pushBackUnique _item;
} forEach [_weapon, _magazine];

// * sometimes the items aren't added to IRE fast enough to get included in the initial arsenal unlock, so unlock them manually
private _arsenalHM = createHashMapFromArray ((jna_dataList select 0) + (jna_dataList select 26));
{
	if ((_x in unlockedWeapons || {_x in unlockedMagazines}) && {(_arsenalHM getOrDefault [_x, 0]) isEqualTo -1}) then { continue };
	[_x, true] call A3A_fnc_unlockEquipment
} forEach (_initialRebelEquipment select {_x isEqualType "" && {_x in (allWeapons + allMagazines)}});

//A3A_faction_reb set ["initialRebelEquipment", _initialRebelEquipment];
//publicVariable "A3A_faction_reb";

true;
