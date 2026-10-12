/*
    Author:
        Creep'nCrunch / jwoodruff40
    
    Description:
        Overrides "fillFactions" mode of A3A_fnc_setupFactionsTab.
    
    Params:
        _params <ARRAY> <Default: None>
    
    Dependencies:
        N/A
    
    Scope:
        Server
    
    Environment:
        Unscheduled
    
    Usage:
        ["fillFactions", []] call a3ue_faction_madness_gui_fnc_setupFactionsTab;
    
    Return:
        None
*/

#include "..\dialogues\ids.inc"
#include "\x\A3A\addons\gui\dialogues\ids.inc"
#include "\x\A3A\addons\gui\dialogues\defines.hpp"
#include "\x\A3A\addons\gui\dialogues\textures.inc"
#include "..\script_component.hpp"

params ["_mode", "_params"];

Debug_1("setupFactionsTab called with mode %1",_mode);

private _display = findDisplay A3A_IDD_SETUPDIALOG;

// Input: faction config, output: true/false
private _fnc_factionLoaded = {
    getArray (_this/"requiredAddons") findIf { !(_x in A3A_setup_loadedPatches) } == -1
};
// local version: getArray (_x/"requiredAddons") findIf { !(isClass (configFile/"CfgPatches"/_x)) } != -1;

switch (_mode) do
{
    case ("fillFactions"):
    {
        private _expandLBs = [];
        
        private _fnc_fillListBox = {
            params ["_listboxIDC", "_factions", "_selected"];
            Debug_1("fillListBox called with %1 selected",_selected);
            private _listbox = _display displayCtrl _listboxIDC;
            if (_selected == "") then { _selected = _listBox lbData lbCurSel _listBox };		// remember previous faction selected
            _listBox lbSetCurSel -1;
            lbClear _listBox;
            {
                private _index = _listBox lbAdd getText(_x/"name");
                if (_x call _fnc_factionLoaded) then {
                    _listBox lbSetPicture [_index, getText(_x/"flagTexture")];
                    _listBox lbSetPictureRight [_index, getText(_x/"logo")]; // Perhaps remove this because it looks like a cluster fuck with mods loaded
                    _listBox lbSetData [_index, configName _x];
                    _listBox lbSetTooltip [_index, getText(_x/"description")];
                    if (_selected == configName _x) then { _listBox lbSetCurSel (lbSize _listBox - 1) };
                } else {
                    _listBox lbSetPicture [_index, "a3\data_f\flags\flag_white_dmg_co.paa"];
                    _listBox lbSetPictureColor [_index, [1,1,1,0.3]];
                    _listBox lbSetTooltip [_index, format[localize "STR_A3AP_setupFactionsTab_noLoaded", (getArray(_x/"requiredAddons")) joinString ", "]];
                    _listBox lbSetColor [_index, A3A_COLOR_TEXT_DARKER_SQF];
                    _listBox lbSetSelectColor [_index, A3A_COLOR_TEXT_DARKER_SQF];
                };
            } forEach _factions;
            if (lbCurSel _listBox == -1) then { _listBox lbSetCurSel 0 };				// Should always exist

            if (count _factions > 12) then { _expandLBs pushBack _listbox };
        };

        // Fetch valid factions and filter based on checkboxes
        private _factions = +(_display getVariable "validFactions");
        if (!cbChecked (_display displayCtrl A3A_IDC_SETUP_IGNORECAMOCHECK)) then {
            _factions = _factions apply { _x select { getArray (_x/"climate") isEqualTo [] or A3A_climate in getArray (_x/"climate") } };
        };
        private _missingFactions = _factions apply { _x select { !(_x call _fnc_factionLoaded) } };
        _factions = _factions apply { _x select { _x call _fnc_factionLoaded } };

        if (cbChecked (_display displayCtrl A3A_IDC_SETUP_SWITCHENEMYCHECK)) then {
            _factions = [_factions#1, _factions#0, _factions#2, _factions#3, _factions#4];
        };
        if (cbChecked (_display displayCtrl A3A_IDC_SETUP_ANYENEMYCHECK)) then {
            _factions = [_factions#0 + _factions#1, _factions#1 + _factions#0, _factions#2, _factions#3, _factions#4];
        };
        if (cbChecked (_display displayCtrl A3A_IDC_SETUP_ANYREBELCHECK)) then {
            _factions = [_factions#0, _factions#1, _factions#2 + _factions#0 + _factions#1 + _factions#4, _factions#3, _factions#4];
        };

        // Add saved factions if valid
        // configNames of the occ/inv/reb/civ factions, written by setupLoadgameTab
        (_display getVariable "savedFactions") params ["_savedFactions", "_savedAddons", "_savedDLC"];
        Debug_3("Saved factions: %1 Addons: %2 DLC: %3",_savedFactions,_savedAddons,_savedDLC);

        private _failedFactions = [];
        {
            _sfact = A3A_SETUP_CONFIGFILE/"A3A"/"Templates"/_x;
            if !(isClass _sfact) then { Info_1("Bad saved faction name %1",_x); _failedFactions pushBack _x };
            if !(_sfact call _fnc_factionLoaded) then { Info_1("Saved faction %1 not loadable",_x); _failedFactions pushBack _x };
            _factions#_forEachIndex pushBackUnique _sfact;				// does nothing if already in list
        } forEach _savedFactions;

        if (_failedFactions isNotEqualTo []) then {
            private _msg = "Couldn't load factions from save:";
            { _msg = _msg + endl + _x } forEach _failedFactions;
            ["Setup", _msg] spawn A3A_fnc_customHint;
        };

        // Add the non-loadable factions back in
        if (cbChecked (_display displayCtrl A3A_IDC_SETUP_SHOWMISSINGCHECK)) then {
            { _x append _missingFactions#_forEachIndex } forEach _factions;
        };

        if (_savedFactions isEqualTo []) then { _savedFactions = ["", "", "", "", ""] };
        [A3A_IDC_SETUP_OCCUPANTSLISTBOX, _factions#0, _savedFactions#0] call _fnc_fillListBox;
        [A3A_IDC_SETUP_INVADERSLISTBOX, _factions#1, _savedFactions#1] call _fnc_fillListBox;
        [A3A_IDC_SETUP_REBELSLISTBOX, _factions#2, _savedFactions#2] call _fnc_fillListBox;
        [A3A_IDC_SETUP_CIVILIANSLISTBOX, _factions#3, _savedFactions#3] call _fnc_fillListBox;
        [A3A_IDC_SETUP_RIVALSLISTBOX, _factions#4, _savedFactions#4] call _fnc_fillListBox;

        ["update", [_expandLBs]] call A3A_fnc_setupFactionsTab;
    };
};
