class Params
{
    class AllParams;
    class ExtenderParams;
    
    class FactionMadnessParams: ExtenderParams
    {
        title = "[A3UE] Faction Madness";
        values[] = {};
        texts[] = {};
        tooltip = $STR_A3UE_params_FM_desc;
    };
    class A3UE_FM_initialItemQuantity: ExtenderParams
    {
        title = $STR_A3UE_params_FM_initialItemQuantity;
		tooltip = $STR_A3UE_params_FM_initialItemQuantity_desc;
        values[] = {1,3,5,10,15,25,50,-1};
        texts[] = {"1", "3", "5", "10", "15", "25", "50", "Unlimited"};
        default = 3;
        lockInGame = 1;
    };
	class A3UE_FM_alwaysUseSFUniforms: ExtenderParams
    {
        title = $STR_A3UE_params_FM_alwaysUseSFUniforms;
		tooltip = $STR_A3UE_params_FM_alwaysUseSFUniforms_desc;
        values[] = {0, 1};
        texts[] = {$STR_antistasi_dialogs_generic_button_no_text, $STR_antistasi_dialogs_generic_button_yes_text};
        default = 0;
    };
    class FactionMadnessSpacer : AllParams {};
};