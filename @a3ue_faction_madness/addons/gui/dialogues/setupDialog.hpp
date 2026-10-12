#include "ids.inc"
#include "\x\A3A\addons\gui\dialogues\ids.inc"
#include "\x\A3A\addons\gui\dialogues\defines.hpp"
#include "\x\A3A\addons\core\ui_define.hpp"

class A3A_TabbedDialog;
class A3A_DefaultControlsGroup;
class A3A_ControlsGroupNoScrollbars;
class A3A_Checkbox;

class A3A_SetupDialog : A3A_TabbedDialog 
{
    class Controls
    {
        class FactionsTab : A3A_DefaultControlsGroup
        {
            class Controls
            {
                // Faction Availability Modifiers
                class ModifiersGroup : A3A_ControlsGroupNoScrollbars
                {
                    class controls
                    {
                        class SwitchEnemyCheck : A3A_Checkbox {
                            onCheckedChanged = QUOTE([QQUOTE(fillFactions)] call FUNC(setupFactionsTab));
                        };
                        class SwitchEnemyText;
                        class AnyEnemyCheck : SwitchEnemyCheck {
                            onCheckedChanged = QUOTE([QQUOTE(fillFactions)] call FUNC(setupFactionsTab));
                        };
                        class IgnoreCamoCheck : SwitchEnemyCheck {
                            onCheckedChanged = QUOTE([QQUOTE(fillFactions)] call FUNC(setupFactionsTab));
                        };
                        delete ShowMissingCheck;
                        delete ShowMissingText;
                        class AnyRebelCheck : SwitchEnemyCheck
                        {
                            idc = A3A_IDC_SETUP_ANYREBELCHECK;
                            y = 16 * GRID_H;
                            onCheckedChanged = QUOTE([QQUOTE(fillFactions)] call FUNC(setupFactionsTab));
                        };
                        class AnyRebelText : SwitchEnemyText
                        {
                            text = $STR_A3UE_FACTION_MADNESS_GUI_SetupDialog_faction_madness;
                            y = 16 * GRID_H;
                        };
                    };
                };
            };
        };
    };
};
