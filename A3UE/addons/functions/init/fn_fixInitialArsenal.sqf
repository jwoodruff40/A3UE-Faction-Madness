waitUntil {!isNil "serverInitDone"};

diag_log "fixInitialArsenal called after serverInitDone";

// ~~Do~~ Fix initial arsenal filling
private _categoriesToPublish = createHashMap;
private _addedClasses = createHashMap;       // dupe proofing
{
	_x params ["_class", ["_count", -1]];
	
	private _categories = _class call A3A_fnc_equipmentClassToCategories;
	{
		missionNamespace setVariable [("unlocked" + _x), [], true];
		private _array = missionNamespace getVariable ("unlocked" + _x);
		if (_count == -1 || {minWeaps != -1 && {_count >= minWeaps}}) then { _array pushBackUnique _class };
	} forEach _categories;
	_categoriesToPublish insert [true, _categories, []];
//} foreach FactionGet(reb,"initialRebelEquipment");
} foreach (A3A_faction_reb get "initialRebelEquipment");

// Publish the unlocked categories (once each)
{ publicVariable ("unlocked" + _x) } forEach keys _categoriesToPublish;
