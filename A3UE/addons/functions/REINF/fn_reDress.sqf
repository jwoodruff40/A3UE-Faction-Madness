params ["_unit"];

private _faction = [A3A_faction_reb, A3A_faction_civ] select (A3A_faction_reb getOrDefault ["convertedToRebel", false]);
_unit forceAddUniform (selectRandom (_faction get "uniforms"));
_unit addItemToUniform "FirstAidKit";