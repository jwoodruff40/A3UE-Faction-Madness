
class A3UE_FM_setupDialog : A3A_SetupDialog
{
    class Controls : Controls
    {
        class TitlebarText : TitlebarText {};
        class TabButtons : TabButtons {};
        class LoadgameTab : LoadgameTab {};
        class FactionsTab : FactionsTab
        {
            class Controls : Controls
            {
                class RebelsLabel : RebelsLabel {};
                class RebelsListBox : RebelsListBox {};

                class CiviliansLabel : CiviliansLabel {};
                class CiviliansListBox : CiviliansListBox {};

                class OccupantsLabel : OccupantsLabel {};
                class OccupantsListBox : OccupantsListBox {};

                class InvadersLabel : InvadersLabel {};
                class InvadersListBox : InvadersListBox {};

                class RivalsLabel : RivalsLabel {};
                class RivalsListBox : RivalsListBox {};

                // Faction Availability Modifiers
                class ModifiersGroup : ModifiersGroup
                {
                    class controls : controls
                    {
                        class Label : Label {};
                        class Background : Background {};
                        class SwitchEnemyCheck : SwitchEnemyCheck {};
                        class SwitchEnemyText : SwitchEnemyText {};
                        class AnyEnemyCheck : AnyEnemyCheck {};
                        class AnyEnemyText : AnyEnemyText {};
                        class IgnoreCamoCheck : IgnoreCamoCheck {};
                        class IgnoreCamoText : IgnoreCamoText {};
                        delete ShowMissingCheck;
                        delete ShowMissingText;
                        class AnyRebelCheck : SwitchEnemyCheck
                        {
                            idc = A3A_IDC_SETUP_ANYREBELCHECK;
                            //y = 20 * GRID_H;
                            y = 16 * GRID_H;
                        };
                        class AnyRebelText : SwitchEnemyText
                        {
                            text = $STR_A3UE_FM_dialogs_setup_override_rebel_limits;
                            //y = 20 * GRID_H;
                            y = 16 * GRID_H;
                        };
                    };
                };                
                class DLCContentGroup : DLCContentGroup {};
                class AddonContentGroup : AddonContentGroup {};
            };
        };
        class ParamsTab : ParamsTab {};
    };
};
