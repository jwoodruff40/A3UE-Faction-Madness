class CfgFunctions 
{
    class A3A 
    {
        class Base
        {
            class initPetros { file = QPATHTOFOLDER(functions\Base\fn_initPetros.sqf); };
        };
        
        class Dialogs
        {
            class squadRecruit { file = QPATHTOFOLDER(functions\Dialogs\fn_squadRecruit.sqf); };
        };
        
        class FunctionsTemplates 
        {
            class compatibilityLoadFaction { file = QPATHTOFOLDER(functions\Templates\fn_compatibilityLoadFaction.sqf); };
        };

        class REINF
        {
            class equipRebel { file = QPATHTOFOLDER(functions\REINF\fn_equipRebel.sqf); };
            class reDress { file = QPATHTOFOLDER(functions\REINF\fn_reDress.sqf); };
        };
    };
};
