class CfgFunctions 
{
    //be careful when overwriting functions as version updates can break your extension
    class A3A 
    {
        class Dialogs
        {
            class squadRecruit { file = QPATHTOFOLDER(Dialogs\fn_squadRecruit.sqf); };
        };
        
        class FunctionsTemplates 
        {
            class compatibilityLoadFaction { file = QPATHTOFOLDER(Templates\fn_compatibilityLoadFaction.sqf); };
            class convertToRebelLoadFaction { file = QPATHTOFOLDER(Templates\fn_convertToRebelLoadFaction.sqf); };
        };

        class REINF
        {
            class equipRebel { file = QPATHTOFOLDER(REINF\fn_equipRebel.sqf); };
            class reDress { file = QPATHTOFOLDER(REINF\fn_reDress.sqf); };
        };
    };
};
