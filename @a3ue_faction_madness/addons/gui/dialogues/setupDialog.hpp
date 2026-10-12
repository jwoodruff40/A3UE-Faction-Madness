#include "ids.inc"
#include "\x\A3A\addons\gui\dialogues\ids.inc"
#include "\x\A3A\addons\gui\dialogues\defines.hpp"
#include "\x\A3A\addons\core\ui_define.hpp"

class A3A_TabbedDialog;
/*
class A3A_ControlsGroupNoScrollbars;
class A3A_Background;
class A3A_Button;
class A3A_Text;
class A3A_ListBox;
class A3A_Tree;
*/

class A3A_SetupDialog : A3A_TabbedDialog 
{
    class Controls
    {
        class FactionsTab
        {
            class Controls
            {
                // Faction Availability Modifiers
                class ModifiersGroup
                {
                    class controls
                    {
                        delete ShowMissingCheck;
                        delete ShowMissingText;
                        class SwitchEnemyCheck;
                        class SwitchEnemyText;
                        class AnyRebelCheck : SwitchEnemyCheck
                        {
                            idc = A3A_IDC_SETUP_ANYREBELCHECK;
                            y = 16 * GRID_H;
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
